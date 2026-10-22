/**
 * Scheduled account deletion (Apple guideline 5.1.1(v), owner decision
 * 2026-10-22).
 *
 * Before: deletion was REFUSED while the user, as a seller, had paid,
 * unrefunded sales (./deletionBlockers.ts). Now the user can ALWAYS request
 * deletion in the app (or on the website). When blockers exist the request is
 * accepted and recorded here instead of being refused:
 *
 *   scheduled_account_deletions/{uid}   (server-only; the owner may read it)
 *     status        'waiting_refunds' -> 'deleting' -> (doc removed)
 *                   'waiting_refunds' | 'failed' -> 'cancelled' (by the user)
 *                   'deleting' x MAX_DELETE_ATTEMPTS -> 'failed' (+ admin alert)
 *     requestedAt, updatedAt, source, analyticsAppInstanceId
 *     nextCheckAt   when the sweep looks again (absent = nothing to do)
 *     leaseUntil    a run owns the doc until then
 *     blockers      snapshot of what still blocks (minimal, max 50)
 *     cancelledEvents / cancelledBookings   totals of what the request cancelled
 *     notifiedProofOrders  failed refunds the user was told about (once each)
 *
 * On request (scheduleAccountDeletion):
 *   1. the record is written (idempotent: a second request keeps requestedAt);
 *   2. the profile is hidden: profiles/{uid}.accountStatus = 'deletion_pending'
 *      (every people surface hides non-active accounts) and the previous
 *      value is kept for a cancel;
 *   3. the seller's upcoming / ongoing PAID events are set to 'cancelled' (the
 *      existing path: refundTicketsOnEventCancelled refunds every buyer in full
 *      and e-mails them) and every upcoming paid / requested experience
 *      booking is cancelled by the host through the existing cancelBooking
 *      (full refund through the refund engine, guest notified);
 *   4. the user gets an e-mail saying what happens and how to cancel.
 *   While the record waits, the seller can't sell: createTicketCheckout,
 *   createBooking and createUserExperience (paid) refuse, and the rules refuse
 *   a new / re-opened paid event (sellerClosing()).
 *
 * Then (processScheduledDeletion): the sweep (every 30 min) and a trigger on
 * every settled ticket_refunds row re-check the blockers (re-queried from the
 * source every time, never a saved count). While something blocks: cancels
 * whatever new appeared, re-hides the profile, tells the user once per failed
 * refund that a manual refund proof is needed (push + e-mail). When nothing
 * blocks: deleteAccountCompletely (the normal path, Auth user LAST), then the
 * record goes and the user gets a "deleted" e-mail (captured before the
 * deletion: the account is gone afterwards).
 *
 * Cancel (cancelScheduledDeletion): status 'cancelled', profile visible
 * again. Cancelled events / bookings STAY cancelled and refunds already
 * started still run (the app says so before the user confirms).
 *
 * Bounded: events (organizerId, endDate) limit 300, bookings (hostId, status,
 * slotStart) limit 300 per pass (existing composite indexes); the sweep takes
 * 50 due records per run inside a time budget. Every step is idempotent.
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import {
  DELETION_PENDING_STATUS,
  DeletionBlocker,
  DeletionBlockedError,
  SCHEDULED_DELETIONS,
  computeDeletionBlockers,
  isClosingRecord,
} from './deletionBlockers';
import { FINAL, eventStillRefundable } from '../ticket_payments/refunds';
import { isPaidEvent, msOf } from '../ticket_payments/orders';
import { LText, lt, t, I18nKey } from '../shared/i18n';

export { SCHEDULED_DELETIONS, isClosingRecord } from './deletionBlockers';

export const CHECK_INTERVAL_MS = 30 * 60 * 1000;
export const LEASE_MS = 10 * 60 * 1000;
export const MAX_DELETE_ATTEMPTS = 5;
export const SWEEP_BATCH = 50;
export const SWEEP_BUDGET_MS = 420 * 1000;
const LISTING_LIMIT = 300;
const NOTIFIED_CAP = 200;
const ACTIVE_BOOKING = ['requested', 'confirmed'];

export type ScheduledStatus = 'waiting_refunds' | 'deleting' | 'cancelled' | 'failed';

export interface ScheduleOpts {
  source: 'app_callable' | 'web_id_token' | 'web_email_link';
  analyticsAppInstanceId?: string | null;
}

export interface OutgoingMail {
  to: string;
  subject: string;
  html: string;
  text: string;
}

export interface ScheduledDeletionDeps {
  db(): FirebaseFirestore.Firestore;
  now(): number;
  blockers(uid: string): Promise<DeletionBlocker[]>;
  /** The normal deletion (deleteAccountCompletely); throws when not done. */
  deleteAccount(uid: string, opts: { analyticsAppInstanceId?: string | null }): Promise<void>;
  /** Host cancels one booking through the existing path (full refund). */
  cancelBooking(hostId: string, bookingId: string): Promise<void>;
  /** false when the Auth user no longer exists (deleted elsewhere). */
  userExists(uid: string): Promise<boolean>;
  authEmail(uid: string): Promise<string | null>;
  locale(uid: string): Promise<string>;
  /** Sends at most once per key (email_dispatch claim). */
  sendMailOnce(key: string, mail: OutgoingMail): Promise<void>;
  notify(p: { recipientId: string; type: string; title: LText; body: LText; data: Record<string, string> }): Promise<void>;
}

const TS = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const DEL = () => admin.firestore.FieldValue.delete();

function escapeHtml(s: unknown): string {
  return String(s ?? '').replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', '\'': '&#39;' }[c] as string));
}

function frame(inner: string): string {
  return '<div style="font-family:Arial,Helvetica,sans-serif;font-size:15px;line-height:1.5;color:#111;max-width:560px;margin:0 auto">'
    + '<div style="padding:16px 0;border-bottom:3px solid #0F9D58;font-size:20px;font-weight:bold;color:#0F9D58">GreenGo</div>'
    + `<div style="padding:16px 0">${inner}</div></div>`;
}

export function mail(to: string, locale: string, subjectKey: I18nKey, bodyKey: I18nKey, params: Record<string, string> = {}): OutgoingMail {
  const subject = t(locale, subjectKey, params);
  const body = t(locale, bodyKey, params);
  return {
    to, subject, text: `${subject}\n\n${body}`,
    html: frame(`<h2 style="margin:0 0 8px">${escapeHtml(subject)}</h2><p>${escapeHtml(body)}</p>`),
  };
}

/** Minimal blockers snapshot stored on the record (no buyer data). */
export function blockerSnapshot(blockers: DeletionBlocker[]): Array<Record<string, unknown>> {
  return blockers.slice(0, 50).map((b) => ({
    kind: b.kind, listingId: b.listingId, title: b.title, startsAt: b.startsAt,
    paidOrders: b.paidOrders, refundsInProgress: b.refundsInProgress,
    failedRefunds: b.failedRefunds, pendingReview: b.pendingReview,
  }));
}

/** Refund row update that finished the automatic work (trigger filter, pure). */
export function refundJustSettled(before: Record<string, any> | undefined, after: Record<string, any> | undefined): boolean {
  if (!after || !FINAL.has(String(after.status))) return false;
  return !before || before.status !== after.status;
}

/** For sale guards: does the seller's account have a deletion pending? */
export async function sellerClosing(uid: string, db: FirebaseFirestore.Firestore = admin.firestore()): Promise<boolean> {
  if (!uid) return false;
  return isClosingRecord((await db.collection(SCHEDULED_DELETIONS).doc(uid).get()).data());
}

// ─────────────────────────────────────────────────────────── listings

/**
 * Cancels the seller's upcoming / ongoing paid events (status -> 'cancelled':
 * refundTicketsOnEventCancelled refunds every buyer) and their upcoming paid
 * or requested experience bookings (host cancelBooking: full refund). Events
 * named by [blockers] are included even without an endDate. Idempotent.
 */
export async function cancelSellerListings(
  uid: string,
  blockers: DeletionBlocker[],
  deps: ScheduledDeletionDeps,
): Promise<{ events: number; bookings: number; failed: number }> {
  const db = deps.db();
  const now = deps.now();
  const out = { events: 0, bookings: 0, failed: 0 };

  const evs = new Map<string, Record<string, any>>();
  const upcoming = await db.collection('events')
    .where('organizerId', '==', uid)
    .where('endDate', '>=', TS(now))
    .limit(LISTING_LIMIT)
    .get();
  for (const d of upcoming.docs) evs.set(d.id, d.data());
  for (const b of blockers) {
    if (b.kind !== 'event' || evs.has(b.listingId) || !b.listingId) continue;
    const s = await db.collection('events').doc(b.listingId).get();
    if (s.exists && s.data()?.organizerId === uid) evs.set(s.id, s.data()!);
  }
  for (const [id, ev] of evs) {
    if (!isPaidEvent(ev)) continue;
    if (ev.status === 'cancelled' || ev.status === 'completed' || ev.status === 'draft') continue;
    if (!eventStillRefundable(ev, now)) continue;
    try {
      await db.collection('events').doc(id).update({
        status: 'cancelled',
        cancelledReason: 'account_deletion',
        cancelledAt: TS(now),
        updatedAt: TS(now),
      });
      out.events++;
    } catch (e) {
      out.failed++;
      console.error(`[scheduledDeletion] cancel event ${id} failed:`, (e as Error)?.message);
    }
  }

  const bookings = await db.collection('bookings')
    .where('hostId', '==', uid)
    .where('status', 'in', ACTIVE_BOOKING)
    .where('slotStart', '>', TS(now))
    .limit(LISTING_LIMIT)
    .get();
  for (const d of bookings.docs) {
    const b = d.data();
    const mode = b.payment?.mode;
    // Paid (online / legacy link / cash) or a request still waiting for the
    // host. Confirmed FREE bookings are left alone (no money involved).
    if (b.status === 'confirmed' && (!mode || mode === 'free')) continue;
    try {
      await deps.cancelBooking(uid, d.id);
      out.bookings++;
    } catch (e) {
      out.failed++;
      console.error(`[scheduledDeletion] cancel booking ${d.id} failed:`, (e as Error)?.message);
    }
  }
  return out;
}

async function hideProfile(uid: string, deps: ScheduledDeletionDeps): Promise<void> {
  const ref = deps.db().collection('profiles').doc(uid);
  await deps.db().runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (!s.exists) return;
    const cur = s.data()?.accountStatus;
    if (cur === DELETION_PENDING_STATUS) return;
    tx.update(ref, {
      accountStatus: DELETION_PENDING_STATUS,
      preDeletionAccountStatus: typeof cur === 'string' ? cur : 'active',
      deletionPendingSince: TS(deps.now()),
    });
  });
}

async function unhideProfile(uid: string, deps: ScheduledDeletionDeps): Promise<void> {
  const ref = deps.db().collection('profiles').doc(uid);
  await deps.db().runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (!s.exists) return;
    const d = s.data() || {};
    const patch: Record<string, unknown> = { preDeletionAccountStatus: DEL(), deletionPendingSince: DEL() };
    // Only undo our own change (a moderation status set meanwhile stays).
    if (d.accountStatus === DELETION_PENDING_STATUS) {
      const prev = d.preDeletionAccountStatus;
      patch.accountStatus = typeof prev === 'string' && prev !== DELETION_PENDING_STATUS ? prev : 'active';
    }
    tx.update(ref, patch);
  });
}

/** Adds what a pass cancelled to the record's running totals. */
async function addCancelledCounts(
  ref: FirebaseFirestore.DocumentReference,
  c: { events: number; bookings: number },
  deps: ScheduledDeletionDeps,
): Promise<void> {
  if (!c.events && !c.bookings) return;
  await deps.db().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    if (!d) return;
    tx.set(ref, {
      cancelledEvents: (Number(d.cancelledEvents) || 0) + c.events,
      cancelledBookings: (Number(d.cancelledBookings) || 0) + c.bookings,
      updatedAt: TS(deps.now()),
    }, { merge: true });
  });
}

// ─────────────────────────────────────────────────────────── request

export interface ScheduleResult {
  status: 'none' | 'scheduled';
  requestedAt?: string;
  blockers: DeletionBlocker[];
  cancelledEvents: number;
  cancelledBookings: number;
}

/**
 * Records a deletion request for [uid] when blockers exist (status 'none'
 * and nothing written when they don't: the caller deletes immediately).
 */
export async function scheduleAccountDeletion(
  uid: string,
  opts: ScheduleOpts,
  deps: ScheduledDeletionDeps = scheduledDeletionDeps,
  known?: DeletionBlocker[],
): Promise<ScheduleResult> {
  const db = deps.db();
  const blockers = known ?? await deps.blockers(uid);
  if (!blockers.length) return { status: 'none', blockers, cancelledEvents: 0, cancelledBookings: 0 };
  const ref = db.collection(SCHEDULED_DELETIONS).doc(uid);
  const now = deps.now();

  const { fresh, requestedMs } = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const d = s.data();
    const waiting = isClosingRecord(d);
    const reqMs = waiting ? (msOf(d!.requestedAt) ?? now) : now;
    if (waiting && d!.status === 'deleting') return { fresh: false, requestedMs: reqMs };
    tx.set(ref, {
      uid,
      status: 'waiting_refunds',
      source: opts.source,
      requestedAt: TS(reqMs),
      updatedAt: TS(now),
      nextCheckAt: TS(now + CHECK_INTERVAL_MS),
      attempts: 0,
      analyticsAppInstanceId: opts.analyticsAppInstanceId ?? (waiting ? d!.analyticsAppInstanceId ?? null : null),
      blockers: blockerSnapshot(blockers),
      cancelledEvents: waiting ? Number(d!.cancelledEvents) || 0 : 0,
      cancelledBookings: waiting ? Number(d!.cancelledBookings) || 0 : 0,
      notifiedProofOrders: waiting && Array.isArray(d!.notifiedProofOrders) ? d!.notifiedProofOrders : [],
      leaseUntil: DEL(),
      cancelledAt: DEL(),
      lastError: DEL(),
    }, { merge: true });
    return { fresh: !waiting, requestedMs: reqMs };
  });

  await hideProfile(uid, deps).catch((e) => console.error(`[scheduledDeletion] hide ${uid} failed:`, e?.message));
  const c = await cancelSellerListings(uid, blockers, deps);
  await addCancelledCounts(ref, c, deps);
  if (fresh) {
    try {
      const to = await deps.authEmail(uid);
      if (to) {
        const loc = await deps.locale(uid);
        await deps.sendMailOnce(`account_deletion_scheduled_${uid}_${requestedMs}`,
          mail(to, loc, 'emailAccountDeletionScheduledSubject', 'srvAccountDeletionScheduledBody'));
      }
    } catch (e) {
      console.error(`[scheduledDeletion] scheduled e-mail ${uid} failed:`, (e as Error)?.message);
    }
  }
  const after = (await ref.get()).data() || {};
  console.log(`[scheduledDeletion] ${uid} scheduled via ${opts.source}: ${blockers.length} blocker(s), `
    + `${c.events} event(s) + ${c.bookings} booking(s) cancelled`);
  return {
    status: 'scheduled',
    requestedAt: new Date(requestedMs).toISOString(),
    blockers,
    cancelledEvents: Number(after.cancelledEvents) || 0,
    cancelledBookings: Number(after.cancelledBookings) || 0,
  };
}

// ─────────────────────────────────────────────────────────── process

export type ProcessOutcome = 'skipped' | 'waiting' | 'deleted' | 'gone' | 'retry' | 'failed';

async function claim(uid: string, deps: ScheduledDeletionDeps): Promise<Record<string, any> | null> {
  const db = deps.db();
  const ref = db.collection(SCHEDULED_DELETIONS).doc(uid);
  const now = deps.now();
  return db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const d = s.data();
    if (!d || (d.status !== 'waiting_refunds' && d.status !== 'deleting')) return null;
    if ((msOf(d.leaseUntil) ?? 0) > now) return null;
    tx.update(ref, {
      leaseUntil: TS(now + LEASE_MS),
      lastCheckedAt: TS(now),
      checks: (Number(d.checks) || 0) + 1,
    });
    return d as Record<string, any>;
  });
}

/** Re-checks one request; deletes the account when nothing blocks. Never throws. */
export async function processScheduledDeletion(
  uid: string,
  deps: ScheduledDeletionDeps = scheduledDeletionDeps,
): Promise<ProcessOutcome> {
  const db = deps.db();
  const ref = db.collection(SCHEDULED_DELETIONS).doc(uid);
  let d: Record<string, any> | null;
  try {
    d = await claim(uid, deps);
  } catch (e) {
    console.error(`[scheduledDeletion] claim ${uid} failed:`, (e as Error)?.message);
    return 'skipped';
  }
  if (!d) return 'skipped';
  const release = (patch: Record<string, unknown>) =>
    ref.set({ ...patch, leaseUntil: DEL(), updatedAt: TS(deps.now()) }, { merge: true }).catch(() => undefined);

  try {
    if (!(await deps.userExists(uid))) {
      // Deleted by another path (console / admin / the user deleting again
      // with nothing left to block): nothing left to do.
      await ref.delete();
      return 'gone';
    }
    const blockers = await deps.blockers(uid);
    if (blockers.length) {
      await hideProfile(uid, deps).catch(() => undefined);
      const c = await cancelSellerListings(uid, blockers, deps);
      const notified = new Set<string>(Array.isArray(d.notifiedProofOrders) ? d.notifiedProofOrders : []);
      const newly: Array<{ orderId: string; title: string }> = [];
      for (const b of blockers) {
        for (const a of b.actionOrders) {
          if (a.status === 'refund_failed' && !notified.has(a.orderId)) newly.push({ orderId: a.orderId, title: b.title || b.listingId });
        }
      }
      if (newly.length) {
        const to = await deps.authEmail(uid).catch(() => null);
        const loc = await deps.locale(uid).catch(() => 'en');
        for (const n of newly) {
          await deps.notify({
            recipientId: uid, type: 'account_deletion_refund_proof_needed',
            title: lt('srvAccountDeletionProofNeededTitle'),
            body: lt('srvAccountDeletionProofNeededBody', { title: n.title }),
            data: { orderId: n.orderId, screen: 'delete_account' },
          }).catch((e) => console.error('[scheduledDeletion] push failed:', e?.message));
          if (to) {
            await deps.sendMailOnce(`account_deletion_proof_needed_${n.orderId}`,
              mail(to, loc, 'emailAccountDeletionProofNeededSubject', 'srvAccountDeletionProofNeededBody', { title: n.title }))
              .catch((e) => console.error('[scheduledDeletion] proof e-mail failed:', e?.message));
          }
          notified.add(n.orderId);
        }
      }
      await addCancelledCounts(ref, c, deps);
      await release({
        status: 'waiting_refunds',
        blockers: blockerSnapshot(blockers),
        nextCheckAt: TS(deps.now() + CHECK_INTERVAL_MS),
        notifiedProofOrders: [...notified].slice(-NOTIFIED_CAP),
      });
      return 'waiting';
    }

    // Nothing blocks: the normal deletion. The e-mail and language are read
    // first - the account is gone afterwards.
    await ref.set({ status: 'deleting', blockers: [], updatedAt: TS(deps.now()) }, { merge: true });
    const to = await deps.authEmail(uid).catch(() => null);
    const loc = await deps.locale(uid).catch(() => 'en');
    try {
      await deps.deleteAccount(uid, { analyticsAppInstanceId: d.analyticsAppInstanceId ?? null });
    } catch (e) {
      if (e instanceof DeletionBlockedError) {
        // Something new was sold in between: wait again.
        await release({ status: 'waiting_refunds', blockers: blockerSnapshot(e.blockers), nextCheckAt: TS(deps.now()) });
        return 'waiting';
      }
      const attempts = (Number(d.attempts) || 0) + 1;
      const failed = attempts >= MAX_DELETE_ATTEMPTS;
      const err = String((e as Error)?.message || e).slice(0, 300);
      await release({
        status: failed ? 'failed' : 'deleting',
        attempts,
        lastError: err,
        nextCheckAt: failed ? DEL() : TS(deps.now() + CHECK_INTERVAL_MS * Math.pow(2, attempts - 1)),
      });
      if (failed) {
        await db.collection('admin_alerts').doc(`scheduled_deletion_failed_${uid}`).set({
          type: 'scheduled_deletion_failed', uid, attempts, lastError: err, status: 'open', createdAt: TS(deps.now()),
        }, { merge: true }).catch(() => undefined);
      }
      console.error(`[scheduledDeletion] deletion of ${uid} failed (attempt ${attempts}):`, err);
      return failed ? 'failed' : 'retry';
    }
    await ref.delete().catch(() => undefined);
    if (to) {
      await deps.sendMailOnce(`account_deletion_completed_${uid}`,
        mail(to, loc, 'email.account_deleted', 'srvAccountDeletionCompletedBody'))
        .catch((e) => console.error('[scheduledDeletion] completed e-mail failed:', e?.message));
    }
    console.log(`[scheduledDeletion] ${uid} deleted (scheduled request)`);
    return 'deleted';
  } catch (e) {
    console.error(`[scheduledDeletion] process ${uid} failed:`, (e as Error)?.message || e);
    await release({ nextCheckAt: TS(deps.now() + CHECK_INTERVAL_MS) });
    return 'retry';
  }
}

/** Due records (nextCheckAt <= now; single-field index), bounded + time budget. */
export async function sweepScheduledDeletions(deps: ScheduledDeletionDeps = scheduledDeletionDeps): Promise<number> {
  const started = deps.now();
  const due = await deps.db().collection(SCHEDULED_DELETIONS)
    .where('nextCheckAt', '<=', TS(started))
    .orderBy('nextCheckAt')
    .limit(SWEEP_BATCH)
    .get();
  let n = 0;
  for (const d of due.docs) {
    if (deps.now() - started > SWEEP_BUDGET_MS) break;
    const r = await processScheduledDeletion(d.id, deps);
    if (r !== 'skipped') n++;
  }
  return n;
}

// ─────────────────────────────────────────────────────────── cancel / status

/** The user keeps the account. Cancelled listings stay cancelled. */
export async function cancelScheduledDeletion(
  uid: string,
  deps: ScheduledDeletionDeps = scheduledDeletionDeps,
): Promise<{ status: 'cancelled' | 'none' | 'deleting' }> {
  const db = deps.db();
  const ref = db.collection(SCHEDULED_DELETIONS).doc(uid);
  const now = deps.now();
  const r = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const d = s.data();
    if (!isClosingRecord(d)) return 'none' as const;
    // The deletion itself is running right now: too late to stop it.
    if (d!.status === 'deleting' && (msOf(d!.leaseUntil) ?? 0) > now) return 'deleting' as const;
    tx.set(ref, {
      status: 'cancelled', cancelledAt: TS(now), updatedAt: TS(now),
      nextCheckAt: DEL(), leaseUntil: DEL(), blockers: [],
    }, { merge: true });
    return 'cancelled' as const;
  });
  if (r === 'cancelled') await unhideProfile(uid, deps).catch((e) => console.error(`[scheduledDeletion] unhide ${uid} failed:`, e?.message));
  return { status: r };
}

export interface ScheduledView {
  status: ScheduledStatus;
  requestedAt: string | null;
  cancelledEvents: number;
  cancelledBookings: number;
}

/** What the app shows on the pending screen (null = no live request). */
export async function scheduledDeletionView(uid: string, db: FirebaseFirestore.Firestore = admin.firestore()): Promise<ScheduledView | null> {
  const d = (await db.collection(SCHEDULED_DELETIONS).doc(uid).get()).data();
  if (!isClosingRecord(d)) return null;
  const ms = msOf(d!.requestedAt);
  return {
    status: d!.status,
    requestedAt: ms === null ? null : new Date(ms).toISOString(),
    cancelledEvents: Number(d!.cancelledEvents) || 0,
    cancelledBookings: Number(d!.cancelledBookings) || 0,
  };
}

// ─────────────────────────────────────────────────────────── production deps

export const scheduledDeletionDeps: ScheduledDeletionDeps = {
  db: () => admin.firestore(),
  now: () => Date.now(),
  blockers: (uid) => computeDeletionBlockers(uid),
  deleteAccount: async (uid, opts) => {
    const { deleteAccountCompletely } = await import('./accountDeletion');
    await deleteAccountCompletely(uid, { source: 'scheduled', analyticsAppInstanceId: opts.analyticsAppInstanceId ?? null });
  },
  cancelBooking: async (hostId, bookingId) => {
    const svc = await import('../experience_bookings/service');
    await svc.cancelBooking(hostId, { bookingId, reason: 'account_deletion' });
  },
  userExists: async (uid) => {
    try {
      await admin.auth().getUser(uid);
      return true;
    } catch (e: any) {
      if (e?.code === 'auth/user-not-found') return false;
      throw e;
    }
  },
  authEmail: async (uid) => (await import('../emails/sendEmail')).authEmailOf(uid),
  locale: async (uid) => (await import('../shared/i18n/recipientLocale')).resolveLocale(uid),
  sendMailOnce: async (key, m) => {
    const { sendEmailOnce } = await import('../emails/sendEmail');
    await sendEmailOnce(key, async () => ({ to: [m.to], subject: m.subject, html: m.html, text: m.text }),
      { type: 'account_deletion' });
  },
  notify: async (p) => (await import('../notifications/notifyHelpers')).emitNotification(p),
};
