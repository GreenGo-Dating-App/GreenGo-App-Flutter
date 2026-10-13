/**
 * Server-owned usage counters behind the membership caps (audit 2026-10-11,
 * P-H1 / P-H4 / H5 / M1).
 *
 * `entitlement_usage/{uid}` is readable by its owner and written ONLY here and
 * by spendCoins (Admin SDK). The Firestore rules read it to refuse a create
 * that is over the cap, so an old or patched app gets the same limits as the
 * current one:
 *
 *   connectDayStartMs / connectCount   new 1:1 conversations started today (UTC)
 *   boostMonth / boostsUsed            free profile boosts used this month (spendCoins)
 *   eventActiveEnds                    end time (ms) of every ONGOING event slot,
 *                                      ascending; a recurring series is one slot
 *   eventActiveSeries                  {seriesId: occurrences} of ongoing series
 *   eventExtraCredits / eventExtraUsed extra events paid with coins (spendCoins
 *                                      'extra_event') / spent on an over-cap slot
 *   eventExtraSlots                    {slotKey: true} slots that used a credit
 *   groupsCreated                      groups this user created that still exist
 *
 * The triggers below are also the backstop for what rules cannot see: several
 * creates committed in ONE batch are all checked against the counter as it was
 * before the batch. A create that is over the cap once counted is deleted again.
 *
 * Scale: one small doc per user; every recount is an indexed per-user query
 * (`events` organizerId+endDate, a count() on `groups` createdBy). No scans.
 */
import * as admin from 'firebase-admin';
import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import '../shared/firebaseAdmin';
import { monitored } from '../shared/monitoring';
import { effectiveTier, hasBaseAccess } from '../shared/effectiveTier';
import { MAX_DAILY_CONNECTS, MAX_EVENTS, MAX_GROUPS, USAGE_COLLECTION, utcDayStartMs } from '../shared/tierLimits';
import { logInfo } from '../shared/utils';

const db = admin.firestore();

export { USAGE_COLLECTION };
const TRIGGER_OPTS = { memory: '512MiB' as const, retry: false };

/** Max occurrences of one recurring series that count as a single slot. */
export const MAX_SERIES_OCCURRENCES = 120;

// ---------------------------------------------------------------------------
// Pure helpers (unit-tested)

/** A support ticket opened in the chat inbox: never a "new connection". */
export function isSupportConversation(c: Record<string, any> | undefined): boolean {
  if (!c) return false;
  return c.conversationType === 'support' || c.userId2 === 'support_system' || c.matchId === 'support';
}

/** Today's connect count stored in `usage` (0 when it is from an earlier day). */
export function connectsToday(usage: Record<string, any> | undefined, nowMs: number): number {
  if (!usage) return 0;
  const start = utcDayStartMs(nowMs);
  return usage.connectDayStartMs === start && typeof usage.connectCount === 'number' ? usage.connectCount : 0;
}

export function millisOf(v: any): number | null {
  if (v === null || v === undefined) return null;
  if (typeof v.toMillis === 'function') return v.toMillis();
  if (v instanceof Date) return v.getTime();
  if (typeof v === 'number') return v;
  return null;
}

export interface EventLite {
  id: string;
  endMs: number | null;
  seriesId?: string | null;
  status?: string | null;
}

/** Still running: ends in the future and not cancelled / completed. */
export function isOngoingEvent(e: EventLite, nowMs: number): boolean {
  if (e.endMs === null || e.endMs <= nowMs) return false;
  return e.status !== 'cancelled' && e.status !== 'completed';
}

/** Slot key: a recurring series is ONE event for the cap. */
export function slotKeyOf(e: Pick<EventLite, 'id' | 'seriesId'>): string {
  return typeof e.seriesId === 'string' && e.seriesId.length > 0 ? `s:${e.seriesId}` : `e:${e.id}`;
}

export interface EventSlots {
  /** slotKey -> latest end (ms) of that slot */
  slots: Map<string, number>;
  /** seriesId -> ongoing occurrences */
  series: Record<string, number>;
}

export function eventSlots(events: EventLite[], nowMs: number, excludeSlot?: string): EventSlots {
  const slots = new Map<string, number>();
  const series: Record<string, number> = {};
  for (const e of events) {
    if (!isOngoingEvent(e, nowMs)) continue;
    const key = slotKeyOf(e);
    if (key === excludeSlot) continue;
    slots.set(key, Math.max(slots.get(key) ?? 0, e.endMs!));
    if (typeof e.seriesId === 'string' && e.seriesId) series[e.seriesId] = (series[e.seriesId] ?? 0) + 1;
  }
  return { slots, series };
}

/** Ascending end times: what the rules index into. */
export function sortedEnds(slots: Map<string, number>): number[] {
  return [...slots.values()].sort((a, b) => a - b);
}

// ---------------------------------------------------------------------------
// P-H1: daily new connections

/**
 * Counts every new one-to-one conversation against its creator (`userId1`;
 * the rules only let the creator be userId1). A create that exceeds today's
 * cap - possible only by committing several in one batch, or by two taps in
 * the same instant - is deleted again.
 */
export const onConversationCreatedCountConnect = onDocumentCreated(
  { document: 'conversations/{conversationId}', ...TRIGGER_OPTS },
  monitored('onConversationCreatedCountConnect', async (event: any) => {
    const snap = event.data;
    if (!snap) return;
    const c = snap.data() as Record<string, any>;
    if (isSupportConversation(c)) return;
    const uid = c.userId1;
    if (typeof uid !== 'string' || !uid || uid.includes('/')) return;
    const usageRef = db.collection(USAGE_COLLECTION).doc(uid);
    const profileRef = db.collection('profiles').doc(uid);
    let overCap = false;
    await db.runTransaction(async (tx) => {
      const [u, p] = await Promise.all([tx.get(usageRef), tx.get(profileRef)]);
      const nowMs = Date.now();
      const cap = MAX_DAILY_CONNECTS[effectiveTier(p.data(), new Date(nowMs))];
      const today = connectsToday(u.data(), nowMs);
      if (cap !== null && today >= cap) {
        overCap = true;
        return;
      }
      tx.set(usageRef, {
        connectDayStartMs: utcDayStartMs(nowMs),
        connectCount: today + 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    });
    if (overCap) {
      await snap.ref.delete();
      logInfo(`connect cap: deleted over-cap conversation ${snap.id} of ${uid}`);
    }
  }),
);

// ---------------------------------------------------------------------------
// P-H4 / M1: ongoing events

function eventLite(id: string, d: Record<string, any>): EventLite {
  return {
    id,
    endMs: millisOf(d.endDate),
    seriesId: typeof d.seriesId === 'string' ? d.seriesId : null,
    status: typeof d.status === 'string' ? d.status : null,
  };
}

/**
 * Recounts `uid`'s ongoing event slots. When `created` is a NEW ongoing event
 * of a capped tier and the OTHER slots already fill the cap, it spends one
 * paid extra-event credit, or - with no credit - deletes the event.
 */
export async function recountEvents(uid: string, created?: { id: string; data: Record<string, any> }): Promise<'ok' | 'credit' | 'deleted'> {
  const usageRef = db.collection(USAGE_COLLECTION).doc(uid);
  const profileRef = db.collection('profiles').doc(uid);
  let outcome: 'ok' | 'credit' | 'deleted' = 'ok';
  await db.runTransaction(async (tx) => {
    outcome = 'ok';
    const nowMs = Date.now();
    const [u, p, q] = await Promise.all([
      tx.get(usageRef),
      tx.get(profileRef),
      tx.get(db.collection('events')
        .where('organizerId', '==', uid)
        .where('endDate', '>', admin.firestore.Timestamp.fromMillis(nowMs))
        .orderBy('endDate')
        .limit(500)),
    ]);
    const usage = u.data() || {};
    let events = q.docs.map((d) => eventLite(d.id, d.data()));
    const update: Record<string, any> = {};

    if (created && !hasBaseAccess(p.data(), new Date(nowMs))) {
      // Owner rule 2026-10-13: no plan, no event creation (the rules refuse
      // it; this catches anything that slipped past them).
      outcome = 'deleted';
      tx.delete(db.collection('events').doc(created.id));
      events = events.filter((e) => e.id !== created.id);
    } else if (created) {
      const ev = eventLite(created.id, created.data);
      const cap = MAX_EVENTS[effectiveTier(p.data(), new Date(nowMs))];
      const key = slotKeyOf(ev);
      const extraSlots: Record<string, boolean> = usage.eventExtraSlots || {};
      if (cap !== null && isOngoingEvent(ev, nowMs) && !extraSlots[key]) {
        const others = eventSlots(events, nowMs, key).slots.size;
        if (others >= cap) {
          const credits = Number(usage.eventExtraCredits || 0);
          const used = Number(usage.eventExtraUsed || 0);
          if (credits > used) {
            outcome = 'credit';
            update.eventExtraUsed = used + 1;
            update.eventExtraSlots = { ...extraSlots, [key]: true };
          } else {
            outcome = 'deleted';
            tx.delete(db.collection('events').doc(created.id));
            events = events.filter((e) => e.id !== created.id);
          }
        }
      }
    }

    const { slots, series } = eventSlots(events, nowMs);
    tx.set(usageRef, {
      ...update,
      eventActiveEnds: sortedEnds(slots),
      eventActiveSeries: series,
      eventActiveCount: slots.size,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
  return outcome;
}

function eventChangedForCap(b: Record<string, any> | undefined, a: Record<string, any> | undefined): boolean {
  if (!b || !a) return true;
  return b.organizerId !== a.organizerId
    || millisOf(b.endDate) !== millisOf(a.endDate)
    || b.status !== a.status
    || (b.seriesId ?? null) !== (a.seriesId ?? null);
}

export const onEventWrittenUsage = onDocumentWritten(
  { document: 'events/{eventId}', ...TRIGGER_OPTS },
  monitored('onEventWrittenUsage', async (event: any) => {
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    if (!eventChangedForCap(before, after)) return;
    const eventId = event.params.eventId as string;
    const owners = new Set<string>();
    for (const d of [before, after]) {
      if (d && typeof d.organizerId === 'string' && d.organizerId && !d.organizerId.includes('/')) owners.add(d.organizerId);
    }
    for (const uid of owners) {
      const isCreate = !before && !!after && after.organizerId === uid;
      const outcome = await recountEvents(uid, isCreate ? { id: eventId, data: after! } : undefined);
      if (outcome === 'deleted') logInfo(`event cap: deleted over-cap event ${eventId} of ${uid}`);
    }
  }),
);

// ---------------------------------------------------------------------------
// H5 / P-H4: groups

export const onGroupWrittenUsage = onDocumentWritten(
  { document: 'groups/{groupId}', ...TRIGGER_OPTS },
  monitored('onGroupWrittenUsage', async (event: any) => {
    const before = event.data?.before?.exists ? event.data.before.data() : undefined;
    const after = event.data?.after?.exists ? event.data.after.data() : undefined;
    if (before && after) return; // only creates and deletes change the count
    const doc = (after || before) as Record<string, any>;
    const uid = doc?.createdBy;
    if (typeof uid !== 'string' || !uid || uid.includes('/')) return;
    const groupId = event.params.groupId as string;
    const usageRef = db.collection(USAGE_COLLECTION).doc(uid);
    const countNow = async () =>
      (await db.collection('groups').where('createdBy', '==', uid).count().get()).data().count;

    let count = await countNow();
    if (after) {
      const profile = (await db.collection('profiles').doc(uid).get()).data();
      const cap = MAX_GROUPS[effectiveTier(profile)];
      if (cap !== null && count > cap) {
        await db.collection('groups').doc(groupId).delete();
        logInfo(`group cap: deleted over-cap group ${groupId} of ${uid}`);
        count = await countNow();
      }
    }
    await usageRef.set({
      groupsCreated: count,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }),
);
