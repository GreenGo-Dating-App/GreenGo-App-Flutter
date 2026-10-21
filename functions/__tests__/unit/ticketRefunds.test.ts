/**
 * ticket_payments/refunds.ts - seller-cancelled refunds (events cancelled /
 * deleted, host-cancelled bookings), the manual-refund proof review, and
 * auth/deletionBlockers.ts. In-memory Firestore, mocked Stripe / Mercado
 * Pago (no network, no real provider call).
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as R from '../../src/ticket_payments/refunds';
import { ProviderError } from '../../src/ticket_payments/providers';
import * as svc from '../../src/experience_bookings/service';
import { computeDeletionBlockers, assertNoDeletionBlockers, DeletionBlockedError } from '../../src/auth/deletionBlockers';

const T0 = Date.UTC(2026, 9, 21, 12, 0, 0);
const H = 3600 * 1000;
const D = 24 * H;
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);
const GUEST_KEY = `guest_${'a'.repeat(40)}`;

let db: PathFakeFirestore;
let now: number;
let stripeCalls: Array<{ acct: string; pi: string; orderId: string }>;
let mpCalls: Array<{ org: string; pay: string; orderId: string }>;
let stripeImpl: (acct: string, pi: string, orderId: string) => Promise<string>;
let pushes: R.RefundNotice[];
let emails: Array<{ kind: string; orderId: string; to: string }>;
let deps: R.RefundDeps;

function stripeErr(code: string, type = 'StripeInvalidRequestError') {
  const e: any = new Error(code);
  e.code = code;
  e.type = type;
  return e;
}

beforeEach(() => {
  db = new PathFakeFirestore();
  now = T0;
  stripeCalls = [];
  mpCalls = [];
  pushes = [];
  emails = [];
  stripeImpl = async (acct, pi, orderId) => `re_${orderId}`;
  deps = {
    db: () => db as any,
    now: () => now,
    stripeRefund: async (acct, pi, orderId) => { stripeCalls.push({ acct, pi, orderId }); return stripeImpl(acct, pi, orderId); },
    mpRefund: async (org, pay, orderId) => { mpCalls.push({ org, pay, orderId }); return `mpr_${orderId}`; },
    closeOpenOrder: async (orderId, reason) => {
      const o = db.get(`ticket_orders/${orderId}`);
      if (!o || !['creating', 'pending', 'pending_payment', 'awaiting_confirmation'].includes(o.status)) return false;
      db.seed(`ticket_orders/${orderId}`, { ...o, status: 'cancelled', cancelReason: reason, seatHeld: false });
      return true;
    },
    expireStripeSession: async () => undefined,
    markRefunded: async (orderId, ref) => {
      const o = db.get(`ticket_orders/${orderId}`);
      if (!o || o.status !== 'paid') return false;
      db.seed(`ticket_orders/${orderId}`, { ...o, status: 'refunded', reversalRef: ref });
      return true;
    },
    notify: async (p) => { pushes.push(p); },
    email: async (kind, orderId, to) => { emails.push({ kind, orderId, to }); },
  };
  Object.assign(R.refundDeps, deps); // engine calls made by experience_bookings use the defaults
});

function order(id: string, over: Record<string, any> = {}) {
  db.seed(`ticket_orders/${id}`, {
    kind: 'event', listingId: 'ev1', organizerId: 'org1', buyerId: `buyer_${id}`, status: 'paid',
    provider: 'stripe', providerRef: { stripeAccountId: 'acct_org', stripeSessionId: `cs_${id}` },
    stripePaymentIntentId: `pi_${id}`, totalAmount: 5000, currency: 'brl', title: 'Rooftop Samba',
    startsAt: ts(T0 + 5 * D), ...over,
  });
}
function paidEvent(over: Record<string, any> = {}) {
  db.seed('events/ev1', {
    organizerId: 'org1', title: 'Rooftop Samba', price: 50, ticketProvider: 'stripe', status: 'published',
    startDate: ts(T0 + 5 * D), endDate: ts(T0 + 5 * D + 4 * H), paidOrderCount: 3, ...over,
  });
}
const refund = (id: string) => db.get(`ticket_refunds/${id}`) as Record<string, any>;

// ─────────────────────────────────────────────────────────── pure

describe('pure helpers', () => {
  test('classifyRefundError', () => {
    expect(R.classifyRefundError(stripeErr('balance_insufficient')).kind).toBe('permanent');
    expect(R.classifyRefundError(stripeErr('account_invalid')).kind).toBe('permanent');
    expect(R.classifyRefundError(stripeErr('', 'StripePermissionError')).kind).toBe('permanent');
    expect(R.classifyRefundError(stripeErr('charge_already_refunded')).kind).toBe('already_refunded');
    expect(R.classifyRefundError(stripeErr('', 'StripeConnectionError')).kind).toBe('retry');
    expect(R.classifyRefundError(stripeErr('rate_limit', 'StripeRateLimitError')).kind).toBe('retry');
    expect(R.classifyRefundError(new ProviderError('mp_http_500')).kind).toBe('retry');
    expect(R.classifyRefundError(new ProviderError('mp_http_429')).kind).toBe('retry');
    expect(R.classifyRefundError(new ProviderError('mp_http_400')).kind).toBe('permanent');
    expect(R.classifyRefundError(new ProviderError('mp_not_connected')).kind).toBe('permanent');
    expect(R.classifyRefundError(new Error('socket hang up')).kind).toBe('retry');
  });

  test('retryDelayMs grows and is capped', () => {
    expect(R.retryDelayMs(1)).toBe(2 * 60 * 1000);
    expect(R.retryDelayMs(2)).toBe(8 * 60 * 1000);
    expect(R.retryDelayMs(30)).toBe(6 * H);
  });

  test('eventRefundAction: only a paid, not-ended event that becomes cancelled / is deleted', () => {
    const ev = { price: 50, ticketProvider: 'stripe', status: 'published', endDate: ts(T0 + D) };
    expect(R.eventRefundAction(ev, { ...ev, status: 'cancelled' }, T0)).toBe('event_cancelled');
    expect(R.eventRefundAction(ev, undefined, T0)).toBe('event_deleted');
    expect(R.eventRefundAction(ev, { ...ev, title: 'x' }, T0)).toBeNull(); // unrelated edit
    expect(R.eventRefundAction({ ...ev, status: 'cancelled' }, { ...ev, status: 'cancelled' }, T0)).toBeNull();
    expect(R.eventRefundAction(ev, { ...ev, status: 'cancelled' }, T0 + 2 * D)).toBeNull(); // already took place
    const free = { price: 0, status: 'published', endDate: ts(T0 + D) };
    expect(R.eventRefundAction(free, { ...free, status: 'cancelled' }, T0)).toBeNull();
    expect(R.eventRefundAction(undefined, ev, T0)).toBeNull(); // create
  });

  test('bookingNeedsRefund: host cancellation of an online booking with an order only', () => {
    const b = { status: 'confirmed', payment: { mode: 'online', orderId: 'o1' } };
    expect(R.bookingNeedsRefund(b, { ...b, status: 'cancelled_by_host' })).toBe(true);
    expect(R.bookingNeedsRefund(b, { ...b, status: 'cancelled_by_guest' })).toBe(false);
    expect(R.bookingNeedsRefund({ ...b, status: 'cancelled_by_host' }, { ...b, status: 'cancelled_by_host' })).toBe(false);
    expect(R.bookingNeedsRefund(b, { status: 'cancelled_by_host', payment: { mode: 'link' } })).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────── event cancelled

describe('enqueueEventRefunds', () => {
  test('every paid order (Stripe, MP, guest) gets one refund row; open orders are closed; others untouched', async () => {
    paidEvent({ status: 'cancelled' });
    order('s1');
    order('m1', { provider: 'mercadopago', mpPaymentId: '123456', providerRef: {}, stripePaymentIntentId: null });
    order('g1', { buyerId: GUEST_KEY, isGuest: true });
    order('open1', { status: 'pending' });
    order('done1', { status: 'refunded' });
    order('exp1', { kind: 'experience', listingId: 'ev1' }); // same id, other kind
    order('other', { listingId: 'ev2' });

    const r = await R.enqueueEventRefunds('ev1', db.get('events/ev1'), 'event_cancelled', deps);
    expect(r).toEqual({ paid: 3, enqueued: 3, closedOpen: 1 });
    for (const id of ['s1', 'm1', 'g1']) {
      expect(refund(id)).toMatchObject({ status: 'pending', reason: 'event_cancelled', batchId: 'event_ev1', organizerId: 'org1' });
      expect(db.get(`ticket_orders/${id}`).refund.status).toBe('pending');
    }
    expect(refund('g1').isGuest).toBe(true);
    expect(db.get('ticket_orders/open1').status).toBe('cancelled');
    for (const id of ['open1', 'done1', 'exp1', 'other']) expect(refund(id)).toBeUndefined();
    expect(db.get('ticket_refund_batches/event_ev1')).toMatchObject({ total: 3, organizerId: 'org1' });
    expect(db.get('events/ev1').ticketRefundsAt).toBeTruthy();

    // Re-trigger (at-least-once delivery): nothing new, no double refund row.
    const again = await R.enqueueEventRefunds('ev1', db.get('events/ev1'), 'event_cancelled', deps);
    expect(again).toEqual({ paid: 3, enqueued: 0, closedOpen: 0 });
  });
});

// ─────────────────────────────────────────────────────────── processing

describe('processRefund', () => {
  async function enqueued(id: string, over: Record<string, any> = {}) {
    paidEvent({ status: 'cancelled' });
    order(id, over);
    await R.enqueueOrderRefund(id, { reason: 'event_cancelled', batchId: 'event_ev1' }, deps);
  }

  test('Stripe: full refund on the connected account, tickets invalidated, buyer told (push + e-mail)', async () => {
    await enqueued('s1');
    expect(await R.processRefund('s1', deps)).toBe('refunded');
    expect(stripeCalls).toEqual([{ acct: 'acct_org', pi: 'pi_s1', orderId: 's1' }]);
    expect(refund('s1')).toMatchObject({ status: 'refunded', providerRefundId: 're_s1', attempts: 1 });
    expect(db.get('ticket_orders/s1')).toMatchObject({ status: 'refunded', refund: { status: 'requested', providerRefundId: 're_s1' } });
    expect(pushes.find((p) => p.type === 'ticket_refund_started')?.recipientId).toBe('buyer_s1');
    expect(emails).toEqual([{ kind: 'started', orderId: 's1', to: 'buyer_s1' }]);
    // Not due any more: a second run / re-trigger never refunds twice.
    expect(await R.processRefund('s1', deps)).toBe('skipped');
    expect(await R.sweepDueRefunds(deps)).toBe(0);
    expect(stripeCalls).toHaveLength(1);
  });

  test('two workers at once (trigger + sweep): one provider call', async () => {
    await enqueued('s1');
    const [a, b] = await Promise.all([R.processRefund('s1', deps), R.processRefund('s1', deps)]);
    expect([a, b].sort()).toEqual(['refunded', 'skipped']);
    expect(stripeCalls).toHaveLength(1);
  });

  test('Mercado Pago: refund with the seller token', async () => {
    await enqueued('m1', { provider: 'mercadopago', mpPaymentId: '987654', providerRef: {} });
    expect(await R.processRefund('m1', deps)).toBe('refunded');
    expect(mpCalls).toEqual([{ org: 'org1', pay: '987654', orderId: 'm1' }]);
    expect(stripeCalls).toHaveLength(0);
  });

  test('guest order: no push, no engine e-mail (the order trigger mails guests)', async () => {
    await enqueued('g1', { buyerId: GUEST_KEY, isGuest: true });
    expect(await R.processRefund('g1', deps)).toBe('refunded');
    expect(pushes.filter((p) => p.recipientId === GUEST_KEY)).toHaveLength(0);
    expect(emails).toHaveLength(0);
  });

  test('transient error: retried with backoff by the sweep, then refunded', async () => {
    await enqueued('s1');
    stripeImpl = async () => { throw stripeErr('', 'StripeConnectionError'); };
    expect(await R.processRefund('s1', deps)).toBe('retry');
    expect(refund('s1')).toMatchObject({ status: 'retry', attempts: 1 });
    expect(refund('s1').nextAttemptAt.toMillis()).toBe(T0 + R.retryDelayMs(1));
    expect(await R.sweepDueRefunds(deps)).toBe(0); // not due yet
    stripeImpl = async (_a, _p, id) => `re_${id}`;
    now = T0 + R.retryDelayMs(1) + 1;
    expect(await R.sweepDueRefunds(deps)).toBe(1);
    expect(refund('s1')).toMatchObject({ status: 'refunded', attempts: 2 });
    expect(stripeCalls).toHaveLength(2); // same idempotency key gg_refund_s1 at Stripe
  });

  test('permanent error (insufficient balance): refund_failed, admin alert, buyer + seller told', async () => {
    await enqueued('s1');
    stripeImpl = async () => { throw stripeErr('balance_insufficient'); };
    expect(await R.processRefund('s1', deps)).toBe('refund_failed');
    expect(refund('s1')).toMatchObject({ status: 'refund_failed', failure: 'balance_insufficient' });
    expect(db.get('ticket_orders/s1')).toMatchObject({ status: 'paid', refund: { status: 'refund_failed' } });
    expect(db.get('admin_alerts/ticket_refund_failed_s1')).toMatchObject({ type: 'ticket_refund_failed', status: 'open', orderId: 's1' });
    expect(pushes.map((p) => `${p.recipientId}:${p.type}`)).toEqual(expect.arrayContaining([
      'buyer_s1:ticket_refund_failed', 'org1:ticket_refund_failed_seller',
    ]));
    expect(emails).toEqual([{ kind: 'failed', orderId: 's1', to: 'buyer_s1' }]);
    expect(await R.sweepDueRefunds(deps)).toBe(0); // final: no more automatic attempts
  });

  test('guest buyer with a failed refund gets the e-mail', async () => {
    await enqueued('g1', { buyerId: GUEST_KEY, isGuest: true });
    stripeImpl = async () => { throw stripeErr('account_invalid'); };
    expect(await R.processRefund('g1', deps)).toBe('refund_failed');
    expect(emails).toEqual([{ kind: 'failed', orderId: 'g1', to: GUEST_KEY }]);
  });

  test('retries exhausted -> refund_failed', async () => {
    await enqueued('s1');
    stripeImpl = async () => { throw new Error('ETIMEDOUT'); };
    let last: string = '';
    for (let i = 0; i < R.MAX_ATTEMPTS; i++) {
      last = await R.processRefund('s1', deps);
      now += 7 * H;
    }
    expect(last).toBe('refund_failed');
    expect(refund('s1').attempts).toBe(R.MAX_ATTEMPTS);
    expect(db.get('admin_alerts/ticket_refund_failed_s1')).toBeTruthy();
  });

  test('already refunded at Stripe: treated as refunded', async () => {
    await enqueued('s1');
    stripeImpl = async () => { throw stripeErr('charge_already_refunded'); };
    expect(await R.processRefund('s1', deps)).toBe('refunded');
    expect(db.get('ticket_orders/s1').status).toBe('refunded');
  });

  test('missing payment reference is permanent (no blind retries)', async () => {
    await enqueued('s1', { stripePaymentIntentId: null });
    expect(await R.processRefund('s1', deps)).toBe('refund_failed');
    expect(stripeCalls).toHaveLength(0);
  });

  test('legacy link order -> refund_owed, seller told to pay back', async () => {
    await enqueued('l1', { provider: 'link', stripePaymentIntentId: null, providerRef: {} });
    expect(await R.processRefund('l1', deps)).toBe('refund_owed');
    expect(pushes.some((p) => p.recipientId === 'org1' && p.type === 'ticket_refund_owed')).toBe(true);
    expect(stripeCalls).toHaveLength(0);
  });

  test('order refunded by the seller in the meantime: no provider call', async () => {
    await enqueued('s1');
    db.seed('ticket_orders/s1', { ...db.get('ticket_orders/s1'), status: 'refunded' });
    expect(await R.processRefund('s1', deps)).toBe('refunded');
    expect(stripeCalls).toHaveLength(0);
  });

  test('the organiser gets ONE summary when every row of the event is done', async () => {
    paidEvent({ status: 'cancelled' });
    order('s1');
    order('s2');
    await R.enqueueEventRefunds('ev1', db.get('events/ev1'), 'event_cancelled', deps);
    stripeImpl = async (_a, _p, id) => { if (id === 's2') throw stripeErr('account_invalid'); return `re_${id}`; };
    await R.processRefund('s1', deps);
    expect(pushes.filter((p) => p.type === 'ticket_refund_summary')).toHaveLength(0);
    await R.processRefund('s2', deps);
    const sums = pushes.filter((p) => p.type === 'ticket_refund_summary');
    expect(sums).toHaveLength(1);
    expect(sums[0]).toMatchObject({ recipientId: 'org1', body: { key: 'srvRefundSummaryBody', params: { refunded: 1, failed: 1 } } });
    expect(await R.maybeSendSummary('event_ev1', deps)).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────── late payment

describe('refundIfListingCancelled', () => {
  test('a payment that lands after the event was cancelled is refunded', async () => {
    paidEvent({ status: 'cancelled' });
    order('late1');
    expect(await R.refundIfListingCancelled('late1', db.get('ticket_orders/late1'), deps)).toBe('enqueued');
    expect(refund('late1').status).toBe('pending');
  });
  test('active listing: nothing', async () => {
    paidEvent();
    order('ok1');
    expect(await R.refundIfListingCancelled('ok1', db.get('ticket_orders/ok1'), deps)).toBe('listing_active');
    expect(refund('ok1')).toBeUndefined();
  });
});

// ─────────────────────────────────────────────────────────── manual proof

describe('manual refund proof + admin review', () => {
  async function failed(id = 's1') {
    paidEvent({ status: 'cancelled' });
    order(id);
    await R.enqueueOrderRefund(id, { reason: 'event_cancelled' }, deps);
    stripeImpl = async () => { throw stripeErr('account_invalid'); };
    await R.processRefund(id, deps);
  }
  const code = async (p: Promise<unknown>) => {
    try { await p; } catch (e) { expect(e).toBeInstanceOf(HttpsError); return (e as any).details?.code; }
    throw new Error('expected a refusal');
  };

  test('only the seller, only for a failed refund, only its own proof path', async () => {
    await failed();
    expect(await code(R.submitManualRefundProof('someone', { orderId: 's1', proofPath: 'refund_proofs/s1/p.pdf' }, deps))).toBe('not_seller');
    expect(await code(R.submitManualRefundProof('org1', { orderId: 's1', proofPath: 'refund_proofs/OTHER/p.pdf' }, deps))).toBe('invalid_proof_path');
    expect(await code(R.submitManualRefundProof('org1', { orderId: 's1', proofPath: 'refund_proofs/s1/../x' }, deps))).toBe('invalid_proof_path');
    const r = await R.submitManualRefundProof('org1', { orderId: 's1', proofPath: 'refund_proofs/s1/p.pdf', note: 'paid by PIX' }, deps);
    expect(r.status).toBe('manual_refund_pending_review');
    expect(refund('s1').proof).toMatchObject({ path: 'refund_proofs/s1/p.pdf', uploadedBy: 'org1' });
    expect(db.get('ticket_orders/s1').refund.status).toBe('manual_refund_pending_review');
  });

  test('refused before the refund failed', async () => {
    paidEvent({ status: 'cancelled' });
    order('s1');
    await R.enqueueOrderRefund('s1', { reason: 'event_cancelled' }, deps);
    expect(await code(R.submitManualRefundProof('org1', { orderId: 's1', proofPath: 'refund_proofs/s1/p.pdf' }, deps))).toBe('refund_not_failed');
  });

  test('admin approves -> refunded_manually (order refunded, seller + buyer told)', async () => {
    await failed();
    await R.submitManualRefundProof('org1', { orderId: 's1', proofPath: 'refund_proofs/s1/p.jpg' }, deps);
    const r = await R.reviewManualRefund('admin1', { orderId: 's1', approve: true }, deps);
    expect(r.status).toBe('refunded_manually');
    expect(refund('s1')).toMatchObject({ status: 'refunded_manually', review: { by: 'admin1', approved: true } });
    expect(db.get('ticket_orders/s1')).toMatchObject({ status: 'refunded', refund: { status: 'refunded_manually' } });
    expect(pushes.some((p) => p.recipientId === 'org1' && p.type === 'ticket_manual_refund_approved')).toBe(true);
    expect(db.get('admin_alerts/ticket_refund_failed_s1').status).toBe('resolved');
  });

  test('admin rejects (reason required) -> back to refund_failed, seller told why', async () => {
    await failed();
    await R.submitManualRefundProof('org1', { orderId: 's1', proofPath: 'refund_proofs/s1/p.jpg' }, deps);
    expect(await code(R.reviewManualRefund('admin1', { orderId: 's1', approve: false }, deps))).toBe('reason_required');
    await R.reviewManualRefund('admin1', { orderId: 's1', approve: false, reason: 'Amount does not match' }, deps);
    expect(refund('s1')).toMatchObject({ status: 'refund_failed', review: { approved: false, reason: 'Amount does not match' } });
    expect(db.get('ticket_orders/s1').status).toBe('paid');
    const p = pushes.find((x) => x.type === 'ticket_manual_refund_rejected')!;
    expect(p).toMatchObject({ recipientId: 'org1', body: { params: { reason: 'Amount does not match' } } });
    expect(await code(R.reviewManualRefund('admin1', { orderId: 's1', approve: true }, deps))).toBe('not_pending_review');
  });
});

// ─────────────────────────────────────────────────────────── host-cancelled bookings

describe('experience bookings: host cancellation = full refund, guest cancellation = policy', () => {
  const HOST = 'host1';
  const GUEST = 'guest1';
  const EXP = 'exp1';
  const SLOT = 'slot1';
  const saved = { ...svc.bookingDeps };
  let reqN = 0;
  beforeEach(() => {
    Object.assign(svc.bookingDeps, {
      db: () => db as any,
      now: () => new Date(now),
      notify: async () => undefined,
      actor: async (uid: string) => ({ id: uid, name: uid }),
    });
    svc.resetCachedSecret();
    db.seed(`profiles/${HOST}`, { isBusiness: true, membershipTier: 'PLATINUM', membershipEndDate: new Date('2100-01-01T00:00:00Z'), isAgeVerified: true });
    for (const g of [GUEST, 'guest2']) {
      db.seed(`profiles/${g}`, { hasBaseMembership: true, baseMembershipEndDate: new Date('2100-01-01T00:00:00Z'), isAgeVerified: true });
    }
    db.seed(`user_experiences/${EXP}`, {
      hostId: HOST, status: 'published', title: 'Samba night', price: 19.99, currency: 'EUR', isFree: false,
      maxGroupSize: 10, cancellationPolicy: 'strict', paymentMethods: ['online'], paymentProvider: 'stripe', durationMinutes: 60,
    });
    db.seed(`user_experiences/${EXP}/slots/${SLOT}`, {
      start: ts(T0 + 10 * D), end: ts(T0 + 10 * D + 3 * H), capacity: 4, bookedCount: 0, status: 'open',
    });
  });
  afterAll(() => Object.assign(svc.bookingDeps, saved));

  async function paidBooking(guest: string, orderId: string): Promise<string> {
    const r: any = await svc.createBooking(guest, {
      experienceId: EXP, slotId: SLOT, guests: 1, requestId: `req_${String(++reqN).padStart(6, '0')}`,
      consentVersion: 'v1', paymentMethod: 'online',
    });
    await svc.respondToBookingRequest(HOST, { bookingId: r.bookingId, accept: true });
    const b = db.get(`bookings/${r.bookingId}`);
    db.seed(`bookings/${r.bookingId}`, { ...b, payment: { ...(b.payment || {}), mode: 'online', orderId, status: 'paid' } });
    order(orderId, { kind: 'experience', listingId: EXP, bookingId: r.bookingId, organizerId: HOST, buyerId: guest });
    return r.bookingId;
  }

  test('host cancels a paid booking -> refund row (host_cancelled) -> refunded', async () => {
    const id = await paidBooking(GUEST, 'ob1');
    await svc.cancelBooking(HOST, { bookingId: id });
    expect(refund('ob1')).toMatchObject({ status: 'pending', reason: 'host_cancelled', organizerId: HOST, kind: 'experience' });
    expect(await R.processRefund('ob1', deps)).toBe('refunded');
    expect(stripeCalls).toEqual([{ acct: 'acct_org', pi: 'pi_ob1', orderId: 'ob1' }]);
  });

  test('guest cancels: no automatic refund (the policy refundDue stays)', async () => {
    const id = await paidBooking(GUEST, 'ob2');
    const c: any = await svc.cancelBooking(GUEST, { bookingId: id });
    expect(c.status).toBe('cancelled_by_guest');
    expect(refund('ob2')).toBeUndefined();
  });

  test('host cancels the whole slot -> every paid booking refunded once', async () => {
    await paidBooking(GUEST, 'ob3');
    await paidBooking('guest2', 'ob4');
    await svc.cancelSlot(HOST, { experienceId: EXP, slotId: SLOT, reason: 'rain' });
    expect(refund('ob3')).toMatchObject({ reason: 'slot_cancelled' });
    expect(refund('ob4')).toMatchObject({ reason: 'slot_cancelled' });
    // The bookings-trigger backstop re-enqueues: still one row each.
    const b = (await db.collection('bookings').where('experienceId', '==', EXP).get()).docs;
    for (const d of b) expect(await R.enqueueBookingRefund(d.id, d.data(), 'host_cancelled', deps)).toBe('exists');
  });
});

// ─────────────────────────────────────────────────────────── deletion blockers

describe('computeDeletionBlockers', () => {
  const bd = () => ({ db: () => db as any, now: () => now });

  test('upcoming paid event blocks; past / refunded / free do not', async () => {
    paidEvent();
    order('up1');
    order('up2');
    db.seed('events/past', { organizerId: 'org1', title: 'Old', price: 10, status: 'published', startDate: ts(T0 - 10 * D), endDate: ts(T0 - 10 * D + H) });
    order('past1', { listingId: 'past', startsAt: ts(T0 - 10 * D) });
    order('ref1', { status: 'refunded' });
    const b = await computeDeletionBlockers('org1', bd());
    expect(b).toHaveLength(1);
    expect(b[0]).toMatchObject({ kind: 'event', listingId: 'ev1', title: 'Rooftop Samba', paidOrders: 2 });
    await expect(assertNoDeletionBlockers('org1', bd())).rejects.toBeInstanceOf(DeletionBlockedError);
    expect(await computeDeletionBlockers('someone_else', bd())).toEqual([]);
  });

  test('ongoing event (started, not ended) still blocks', async () => {
    paidEvent({ startDate: ts(T0 - H), endDate: ts(T0 + 3 * H) });
    order('on1', { startsAt: ts(T0 - H) });
    expect(await computeDeletionBlockers('org1', bd())).toHaveLength(1);
  });

  test('a failed refund blocks even for a past event, with the order to act on', async () => {
    db.seed('events/past', { organizerId: 'org1', title: 'Old', price: 10, status: 'cancelled', startDate: ts(T0 - 10 * D), endDate: ts(T0 - 10 * D + H) });
    order('f1', { listingId: 'past', startsAt: ts(T0 - 10 * D) });
    db.seed('ticket_refunds/f1', { orderId: 'f1', organizerId: 'org1', kind: 'event', listingId: 'past', title: 'Old', status: 'refund_failed' });
    db.seed('ticket_refunds/f2', { orderId: 'f2', organizerId: 'org1', kind: 'event', listingId: 'past', title: 'Old', status: 'refunded' });
    const b = await computeDeletionBlockers('org1', bd());
    expect(b).toHaveLength(1);
    expect(b[0]).toMatchObject({ listingId: 'past', failedRefunds: 1, paidOrders: 1, actionOrders: [{ orderId: 'f1', status: 'refund_failed' }] });
  });

  test('paid upcoming experience booking blocks with its booking id; a completed one does not', async () => {
    db.seed('bookings/bk1', { status: 'confirmed', slotEnd: ts(T0 + 2 * D), experienceTitle: 'Samba night' });
    order('x1', { kind: 'experience', listingId: 'exp1', bookingId: 'bk1', startsAt: ts(T0 + 2 * D - 3 * H) });
    db.seed('bookings/bk2', { status: 'completed', slotEnd: ts(T0 - H) });
    order('x2', { kind: 'experience', listingId: 'exp2', bookingId: 'bk2', startsAt: ts(T0 - 4 * H) });
    const b = await computeDeletionBlockers('org1', bd());
    expect(b).toHaveLength(1);
    expect(b[0]).toMatchObject({ kind: 'experience', listingId: 'exp1', bookingIds: ['bk1'], paidOrders: 1 });
  });
});
