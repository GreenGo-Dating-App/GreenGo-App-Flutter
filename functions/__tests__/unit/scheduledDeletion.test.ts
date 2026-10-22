/**
 * auth/scheduledDeletion.ts (Apple 5.1.1(v), 2026-10-22): a deletion request
 * with paid, unrefunded sales is ACCEPTED and scheduled: the seller's paid
 * listings are cancelled through the existing paths (event status ->
 * 'cancelled' = refund trigger; host cancelBooking), the profile is hidden,
 * the sweep deletes the account once nothing blocks, the user can withdraw.
 * No network: path-based Firestore fake, fake deletion / e-mail / push.
 */

import * as admin from 'firebase-admin';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as S from '../../src/auth/scheduledDeletion';
import { DeletionBlocker, DeletionBlockedError } from '../../src/auth/deletionBlockers';

const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const HOUR = 3600 * 1000;
const NOW = Date.UTC(2026, 9, 22, 12, 0, 0);
const ORG = 'org1';

function blocker(over: Partial<DeletionBlocker> = {}): DeletionBlocker {
  return {
    kind: 'event', listingId: 'ePaid', title: 'Rooftop Samba', startsAt: new Date(NOW + 24 * HOUR).toISOString(),
    paidOrders: 2, refundsInProgress: 0, failedRefunds: 0, pendingReview: 0, bookingIds: [], actionOrders: [], ...over,
  };
}

let db: PathFakeFirestore;
let now: number;
let current: DeletionBlocker[];
let deleted: Array<{ uid: string; opts: any }>;
let deleteError: Error | null;
let cancelledBookings: string[];
let mails: Array<{ key: string; to: string; subject: string; text: string }>;
let pushes: any[];
let userExists: boolean;
let deps: S.ScheduledDeletionDeps;

beforeEach(() => {
  db = new PathFakeFirestore();
  now = NOW;
  current = [blocker()];
  deleted = [];
  deleteError = null;
  cancelledBookings = [];
  mails = [];
  pushes = [];
  userExists = true;
  const sentKeys = new Set<string>();
  deps = {
    db: () => db as any,
    now: () => now,
    blockers: async () => current,
    deleteAccount: async (uid, opts) => {
      if (deleteError) throw deleteError;
      deleted.push({ uid, opts });
    },
    cancelBooking: async (hostId, bookingId) => {
      const b = db.get(`bookings/${bookingId}`)!;
      if (b.hostId !== hostId) throw new Error('not_a_party');
      cancelledBookings.push(bookingId);
      db.seed(`bookings/${bookingId}`, { ...b, status: 'cancelled_by_host' });
    },
    userExists: async () => userExists,
    authEmail: async () => 'org@example.com',
    locale: async () => 'en',
    sendMailOnce: async (key, m) => {
      if (sentKeys.has(key)) return;
      sentKeys.add(key);
      mails.push({ key, to: m.to, subject: m.subject, text: m.text });
    },
    notify: async (p) => { pushes.push(p); },
  };

  db.seed(`profiles/${ORG}`, { displayName: 'Org', accountStatus: 'active' });
  // Paid upcoming (cancelled), free upcoming (kept), paid past (kept),
  // paid draft (kept), someone else's paid event (kept).
  const ev = (start: number, over: Record<string, any> = {}) => ({
    organizerId: ORG, title: 'Ev', price: 20, ticketProvider: 'stripe', status: 'published',
    startDate: ts(start), endDate: ts(start + 4 * HOUR), ...over,
  });
  db.seed('events/ePaid', ev(NOW + 24 * HOUR, { title: 'Rooftop Samba' }));
  db.seed('events/eFree', ev(NOW + 24 * HOUR, { price: 0, ticketProvider: null }));
  db.seed('events/ePast', ev(NOW - 48 * HOUR));
  db.seed('events/eDraft', ev(NOW + 48 * HOUR, { status: 'draft' }));
  db.seed('events/eOther', ev(NOW + 24 * HOUR, { organizerId: 'someoneElse' }));
  // Experience bookings: paid confirmed + requested upcoming (cancelled),
  // free confirmed (kept), paid past (kept).
  const bk = (start: number, over: Record<string, any> = {}) => ({
    hostId: ORG, guestId: 'g1', experienceId: 'x1', status: 'confirmed',
    payment: { mode: 'online', orderId: 'o1' }, slotStart: ts(start), slotEnd: ts(start + HOUR), ...over,
  });
  db.seed('bookings/bPaid', bk(NOW + 24 * HOUR));
  db.seed('bookings/bReq', bk(NOW + 30 * HOUR, { status: 'requested', payment: { mode: 'online' } }));
  db.seed('bookings/bFree', bk(NOW + 24 * HOUR, { payment: { mode: 'free' } }));
  db.seed('bookings/bPast', bk(NOW - 24 * HOUR));
});

const rec = () => db.get(`scheduled_account_deletions/${ORG}`) as Record<string, any> | undefined;

describe('scheduleAccountDeletion', () => {
  test('no blockers: nothing recorded (the caller deletes at once)', async () => {
    current = [];
    const r = await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    expect(r.status).toBe('none');
    expect(rec()).toBeUndefined();
    expect(db.get('events/ePaid')!.status).toBe('published');
    expect(mails).toHaveLength(0);
  });

  test('blockers: request recorded, profile hidden, paid listings cancelled, e-mail sent', async () => {
    const r = await S.scheduleAccountDeletion(ORG, { source: 'app_callable', analyticsAppInstanceId: 'appinst123' }, deps);
    expect(r).toMatchObject({ status: 'scheduled', cancelledEvents: 1, cancelledBookings: 2 });
    expect(r.requestedAt).toBe(new Date(NOW).toISOString());

    const d = rec()!;
    expect(d).toMatchObject({ status: 'waiting_refunds', source: 'app_callable', analyticsAppInstanceId: 'appinst123', cancelledEvents: 1, cancelledBookings: 2 });
    expect(d.nextCheckAt.toMillis()).toBe(NOW + S.CHECK_INTERVAL_MS);
    expect(d.blockers).toEqual([expect.objectContaining({ kind: 'event', listingId: 'ePaid', paidOrders: 2 })]);

    // Hidden everywhere (accountStatus), previous value kept for a cancel.
    expect(db.get(`profiles/${ORG}`)).toMatchObject({ accountStatus: 'deletion_pending', preDeletionAccountStatus: 'active' });

    // Existing cancel path: the status write (refundTicketsOnEventCancelled refunds).
    expect(db.get('events/ePaid')).toMatchObject({ status: 'cancelled', cancelledReason: 'account_deletion' });
    for (const id of ['eFree', 'ePast', 'eOther']) expect(db.get(`events/${id}`)!.status).toBe('published');
    expect(db.get('events/eDraft')!.status).toBe('draft');
    // Host cancelBooking for the paid + requested upcoming bookings only.
    expect(cancelledBookings.sort()).toEqual(['bPaid', 'bReq']);
    expect(db.get('bookings/bFree')!.status).toBe('confirmed');
    expect(db.get('bookings/bPast')!.status).toBe('confirmed');

    expect(mails).toHaveLength(1);
    expect(mails[0]).toMatchObject({ to: 'org@example.com', subject: 'Your GreenGo account deletion is scheduled' });
    expect(mails[0].text).toContain('cancel the request in the app');
  });

  test('idempotent: a second request keeps the date, cancels nothing twice, no second e-mail', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    now = NOW + HOUR;
    const r = await S.scheduleAccountDeletion(ORG, { source: 'web_id_token' }, deps);
    expect(r.requestedAt).toBe(new Date(NOW).toISOString());
    expect(r).toMatchObject({ cancelledEvents: 1, cancelledBookings: 2 });
    expect(cancelledBookings).toHaveLength(2);
    expect(mails).toHaveLength(1);
    expect(db.get(`profiles/${ORG}`)!.preDeletionAccountStatus).toBe('active');
  });
});

describe('processScheduledDeletion', () => {
  test('still blocked: waits, tells the user ONCE per failed refund (push + e-mail)', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    current = [blocker({ failedRefunds: 1, actionOrders: [{ orderId: 'ord9', status: 'refund_failed' }] })];
    now = NOW + S.CHECK_INTERVAL_MS;
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('waiting');
    expect(pushes).toEqual([expect.objectContaining({ recipientId: ORG, type: 'account_deletion_refund_proof_needed', data: { orderId: 'ord9', screen: 'delete_account' } })]);
    expect(mails.map((m) => m.key)).toContain('account_deletion_proof_needed_ord9');
    expect(rec()).toMatchObject({ status: 'waiting_refunds', notifiedProofOrders: ['ord9'] });
    expect(rec()!.leaseUntil).toBeUndefined();
    expect(rec()!.nextCheckAt.toMillis()).toBe(now + S.CHECK_INTERVAL_MS);
    expect(deleted).toHaveLength(0);

    now += S.CHECK_INTERVAL_MS;
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('waiting');
    expect(pushes).toHaveLength(1);
  });

  test('nothing blocks: the normal deletion runs, record removed, "deleted" e-mail', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable', analyticsAppInstanceId: 'appinst123' }, deps);
    current = [];
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('deleted');
    expect(deleted).toEqual([{ uid: ORG, opts: { analyticsAppInstanceId: 'appinst123' } }]);
    expect(rec()).toBeUndefined();
    const m = mails.find((x) => x.key === `account_deletion_completed_${ORG}`)!;
    expect(m).toMatchObject({ to: 'org@example.com', subject: 'Your GreenGo account has been deleted' });
    // Re-run (trigger + sweep racing): nothing left, nothing deleted twice.
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('skipped');
    expect(deleted).toHaveLength(1);
  });

  test('a live lease keeps a second run out', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    db.seed(`scheduled_account_deletions/${ORG}`, { ...rec()!, leaseUntil: ts(NOW + 60_000) });
    current = [];
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('skipped');
    expect(deleted).toHaveLength(0);
  });

  test('something new was sold in between: back to waiting', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    current = [];
    deleteError = new DeletionBlockedError([blocker({ listingId: 'eNew' })]);
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('waiting');
    expect(rec()).toMatchObject({ status: 'waiting_refunds' });
    expect(rec()!.blockers[0].listingId).toBe('eNew');
  });

  test('deletion keeps failing: retried with backoff, then failed + admin alert', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    current = [];
    deleteError = new Error('storage down');
    for (let i = 1; i < S.MAX_DELETE_ATTEMPTS; i++) {
      expect(await S.processScheduledDeletion(ORG, deps)).toBe('retry');
      expect(rec()).toMatchObject({ status: 'deleting', attempts: i });
      now = rec()!.nextCheckAt.toMillis();
    }
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('failed');
    expect(rec()).toMatchObject({ status: 'failed', attempts: S.MAX_DELETE_ATTEMPTS });
    expect(rec()!.nextCheckAt).toBeUndefined();
    expect(db.get(`admin_alerts/scheduled_deletion_failed_${ORG}`)).toMatchObject({ type: 'scheduled_deletion_failed', uid: ORG, status: 'open' });
  });

  test('account already deleted elsewhere: the record goes', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    userExists = false;
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('gone');
    expect(rec()).toBeUndefined();
  });
});

describe('sweepScheduledDeletions', () => {
  test('re-checks only due requests (re-queried each run)', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    db.seed('scheduled_account_deletions/other', { uid: 'other', status: 'waiting_refunds', nextCheckAt: ts(NOW + 10 * HOUR) });
    db.seed('scheduled_account_deletions/gone', { uid: 'gone', status: 'cancelled' });
    current = [];
    expect(await S.sweepScheduledDeletions(deps)).toBe(0); // not due yet
    now = NOW + S.CHECK_INTERVAL_MS;
    expect(await S.sweepScheduledDeletions(deps)).toBe(1);
    expect(deleted.map((x) => x.uid)).toEqual([ORG]);
    expect(db.get('scheduled_account_deletions/other')).toBeTruthy();
  });
});

describe('cancelScheduledDeletion', () => {
  test('withdrawn: profile visible again, cancelled listings stay cancelled, never deleted', async () => {
    db.seed(`profiles/${ORG}`, { displayName: 'Org' }); // no accountStatus = active
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    expect(await S.cancelScheduledDeletion(ORG, deps)).toEqual({ status: 'cancelled' });
    expect(rec()).toMatchObject({ status: 'cancelled', blockers: [] });
    expect(rec()!.nextCheckAt).toBeUndefined();
    const p = db.get(`profiles/${ORG}`)!;
    expect(p.accountStatus).toBe('active');
    expect(p.preDeletionAccountStatus).toBeUndefined();
    expect(db.get('events/ePaid')!.status).toBe('cancelled');
    expect(db.get('bookings/bPaid')!.status).toBe('cancelled_by_host');
    // The sweep never picks it up again; a cancelled record does not block sales.
    current = [];
    now = NOW + 10 * HOUR;
    expect(await S.sweepScheduledDeletions(deps)).toBe(0);
    expect(await S.processScheduledDeletion(ORG, deps)).toBe('skipped');
    expect(deleted).toHaveLength(0);
    expect(S.isClosingRecord(rec())).toBe(false);
    // Nothing to cancel twice.
    expect(await S.cancelScheduledDeletion(ORG, deps)).toEqual({ status: 'none' });
  });

  test('a moderation status set meanwhile is not overwritten', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    db.seed(`profiles/${ORG}`, { ...db.get(`profiles/${ORG}`), accountStatus: 'suspended' });
    await S.cancelScheduledDeletion(ORG, deps);
    expect(db.get(`profiles/${ORG}`)!.accountStatus).toBe('suspended');
  });

  test('too late while the deletion itself runs', async () => {
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    db.seed(`scheduled_account_deletions/${ORG}`, { ...rec()!, status: 'deleting', leaseUntil: ts(NOW + 60_000) });
    expect(await S.cancelScheduledDeletion(ORG, deps)).toEqual({ status: 'deleting' });
    expect(rec()!.status).toBe('deleting');
  });
});

describe('pure helpers', () => {
  test('isClosingRecord', () => {
    expect(S.isClosingRecord(undefined)).toBe(false);
    expect(S.isClosingRecord({ status: 'cancelled' })).toBe(false);
    for (const s of ['waiting_refunds', 'deleting', 'failed']) expect(S.isClosingRecord({ status: s })).toBe(true);
  });

  test('refundJustSettled: only a transition into a final status', () => {
    expect(S.refundJustSettled({ status: 'processing' }, { status: 'refunded' })).toBe(true);
    expect(S.refundJustSettled({ status: 'processing' }, { status: 'refund_failed' })).toBe(true);
    expect(S.refundJustSettled({ status: 'refunded' }, { status: 'refunded' })).toBe(false);
    expect(S.refundJustSettled({ status: 'pending' }, { status: 'processing' })).toBe(false);
    expect(S.refundJustSettled({ status: 'retry' }, undefined)).toBe(false);
  });

  test('scheduledDeletionView: null unless a live request', async () => {
    expect(await S.scheduledDeletionView(ORG, db as any)).toBeNull();
    await S.scheduleAccountDeletion(ORG, { source: 'app_callable' }, deps);
    expect(await S.scheduledDeletionView(ORG, db as any)).toEqual({
      status: 'waiting_refunds', requestedAt: new Date(NOW).toISOString(), cancelledEvents: 1, cancelledBookings: 2,
    });
    await S.cancelScheduledDeletion(ORG, deps);
    expect(await S.scheduledDeletionView(ORG, db as any)).toBeNull();
  });
});
