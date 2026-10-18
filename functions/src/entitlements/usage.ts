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
 *   eventActiveEnds                    end time (ms) of every ACTIVE event slot,
 *                                      ascending; a recurring series is one slot
 *   eventActiveSeries                  {seriesId: occurrences} of active series
 *   groupsCreated                      groups this user created that still exist
 *
 * Events are capped ACTIVE AT A TIME (owner rule 2026-10-14): Base 1, Silver
 * 5, Gold 10, Platinum unlimited. An event that ended, was cancelled, deleted
 * or hidden by a plan downgrade (`hiddenByDowngrade`, entitlements/downgrade.ts)
 * frees its slot. The paid "extra event for 50 coins" credit is retired (the
 * old eventExtra* fields are ignored).
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
import type { EventLite } from './eventSlots';
import { eventSlots, isOngoingEvent, millisOf, slotKeyOf, sortedEnds } from './eventSlots';

export * from './eventSlots';

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

/**
 * A buyer <-> organizer conversation created by openListingChat (Admin SDK)
 * for a verified ticket holder / booked guest: never counted against the
 * daily cap. Clients cannot write `context.buyer == true` (firestore rules).
 */
export function isBuyerChatConversation(c: Record<string, any> | undefined): boolean {
  return !!c && !!c.context && typeof c.context === 'object' && c.context.buyer === true;
}

/** Today's connect count stored in `usage` (0 when it is from an earlier day). */
export function connectsToday(usage: Record<string, any> | undefined, nowMs: number): number {
  if (!usage) return 0;
  const start = utcDayStartMs(nowMs);
  return usage.connectDayStartMs === start && typeof usage.connectCount === 'number' ? usage.connectCount : 0;
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
    if (isSupportConversation(c) || isBuyerChatConversation(c)) return;
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
// P-H4 / M1: active events (at a time)

function eventLite(id: string, d: Record<string, any>): EventLite {
  return {
    id,
    endMs: millisOf(d.endDate),
    seriesId: typeof d.seriesId === 'string' ? d.seriesId : null,
    status: typeof d.status === 'string' ? d.status : null,
    hidden: d.hiddenByDowngrade === true,
  };
}

/**
 * Recounts `uid`'s active event slots. When `created` is a NEW ongoing event
 * of a capped tier and the OTHER slots already fill the cap, the event is
 * deleted again (backstop for creates the rules could not see, e.g. several
 * in one batch).
 */
export async function recountEvents(uid: string, created?: { id: string; data: Record<string, any> }): Promise<'ok' | 'deleted'> {
  const usageRef = db.collection(USAGE_COLLECTION).doc(uid);
  const profileRef = db.collection('profiles').doc(uid);
  let outcome: 'ok' | 'deleted' = 'ok';
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
    let events = q.docs.map((d) => eventLite(d.id, d.data()));

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
      if (cap !== null && isOngoingEvent(ev, nowMs)) {
        const others = eventSlots(events, nowMs, key).slots.size;
        if (others >= cap) {
          outcome = 'deleted';
          tx.delete(db.collection('events').doc(created.id));
          events = events.filter((e) => e.id !== created.id);
        }
      }
    }

    const { slots, series } = eventSlots(events, nowMs);
    tx.set(usageRef, {
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
    || (b.hiddenByDowngrade === true) !== (a.hiddenByDowngrade === true)
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
