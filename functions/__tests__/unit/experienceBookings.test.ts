/**
 * experience_bookings — policy math, state machine, payment methods, and the
 * callable / job / trigger bodies against an in-memory Firestore (no network).
 */

import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import { PathFakeFirestore } from '../utils/pathFirestoreFake';
import * as M from '../../src/experience_bookings/model';
import * as svc from '../../src/experience_bookings/service';
import * as rev from '../../src/experience_bookings/reviews';

const H = M.HOUR_MS;
const D = M.DAY_MS;
const T0 = Date.UTC(2026, 9, 1, 12, 0, 0);
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

// ─────────────────────────────────────────────────────────── pure

describe('refundFor (policy matrix)', () => {
  const start = T0 + 30 * D;
  const bookedLongAgo = T0 - 30 * D;
  const at = (before: number) => start - before;
  const cases: Array<[M.CancellationPolicy, number, number]> = [
    // [policy, time before start, expected %]
    ['flexible', 10 * D, 100], ['flexible', 25 * H, 100], ['flexible', 24 * H, 100],
    ['flexible', 24 * H - 1, 0], ['flexible', 1 * H, 0],
    ['moderate', 8 * D, 100], ['moderate', 7 * D, 100], ['moderate', 7 * D - 1, 50],
    ['moderate', 3 * D, 50], ['moderate', 24 * H, 50], ['moderate', 24 * H - 1, 0],
    ['strict', 8 * D, 100], ['strict', 7 * D, 100], ['strict', 7 * D - 1, 0], ['strict', 2 * D, 0],
  ];
  test.each(cases)('%s, %p ms before start -> %p%%', (policy, before, pct) => {
    expect(M.refundFor(policy, at(before), start, bookedLongAgo, 'guest')).toBe(pct);
  });

  test('host cancellation is always 100%', () => {
    for (const p of M.CANCELLATION_POLICIES) {
      expect(M.refundFor(p, start - 1 * H, start, bookedLongAgo, 'host')).toBe(100);
      expect(M.refundFor(p, start + 1 * H, start, bookedLongAgo, 'host')).toBe(100);
    }
  });

  test('at / after the start the guest gets 0 (late cancellation, no-show)', () => {
    for (const p of M.CANCELLATION_POLICIES) {
      expect(M.refundFor(p, start, start, bookedLongAgo, 'guest')).toBe(0);
      expect(M.refundFor(p, start + H, start, bookedLongAgo, 'guest')).toBe(0);
    }
  });

  test('24 h grace after booking when the start is > 48 h away', () => {
    const now = start - 3 * D;
    expect(M.refundFor('strict', now, start, now - 23 * H, 'guest')).toBe(100);
    expect(M.refundFor('strict', now, start, now - 25 * H, 'guest')).toBe(0); // grace over
    const near = start - 47 * H; // start not > 48 h away
    expect(M.refundFor('strict', near, start, near - H, 'guest')).toBe(0);
    expect(M.refundFor('moderate', near, start, near - H, 'guest')).toBe(50);
  });

  test('unknown policy falls back to moderate', () => {
    expect(M.refundFor('weird', start - 3 * D, start, bookedLongAgo, 'guest')).toBe(50);
    expect(M.policyOf({ cancellationPolicy: 'Free text from 2025' })).toBe('moderate');
    expect(M.policyOf({ cancellationPolicy: 'strict' })).toBe('strict');
  });
});

// Same file the app's BookingRules test reads (refund preview parity).
// eslint-disable-next-line @typescript-eslint/no-var-requires
const refundFixture = require('../fixtures/booking_refund_cases.json') as {
  refundFor: Array<{ policy: string; beforeStartMs: number; sinceBookingMs: number; by: 'guest' | 'host'; expected: number }>;
  refundDueFor: Array<{
    price: M.BookingPrice | null;
    payment: { mode: string; hostConfirmedPaid: boolean };
    percent: number;
    reason: string;
    expected: M.RefundDue | null;
  }>;
};

describe('refund parity fixture (shared with the app)', () => {
  const start = T0 + 60 * D;
  test.each(refundFixture.refundFor.map((c) => [c.policy, c.beforeStartMs, c.sinceBookingMs, c.by, c.expected] as const))(
    'refundFor %s, %p ms before, booked %p ms earlier, by %s -> %p',
    (policy, before, since, by, expected) => {
      const now = start - before;
      expect(M.refundFor(policy, now, start, now - since, by)).toBe(expected);
    },
  );
  test.each(refundFixture.refundDueFor.map((c, i) => [i, c] as const))('refundDueFor case %p', (_i, c) => {
    const payment = { mode: c.payment.mode, hostConfirmedPaidAt: c.payment.hostConfirmedPaid ? ts(T0) : null };
    expect(M.refundDueFor(c.price, payment, c.percent, c.reason)).toEqual(c.expected);
  });
});

describe('state machine', () => {
  const allowed: Array<[M.BookingStatus, M.BookingStatus]> = [
    ['requested', 'confirmed'], ['requested', 'declined'], ['requested', 'expired'],
    ['requested', 'cancelled_by_guest'], ['requested', 'cancelled_by_host'],
    ['confirmed', 'completed'], ['confirmed', 'no_show'], ['confirmed', 'disputed'],
    ['confirmed', 'cancelled_by_guest'], ['confirmed', 'cancelled_by_host'],
    ['no_show', 'disputed'], ['disputed', 'resolved'],
  ];
  test('exactly the documented transitions are allowed', () => {
    const set = new Set(allowed.map(([a, b]) => `${a}>${b}`));
    for (const from of M.BOOKING_STATUSES) {
      for (const to of M.BOOKING_STATUSES) {
        expect([from, to, M.canTransition(from, to)]).toEqual([from, to, set.has(`${from}>${to}`)]);
      }
    }
  });
  test('terminal states never move; unknown statuses never move', () => {
    for (const t of ['declined', 'expired', 'cancelled_by_guest', 'cancelled_by_host', 'completed', 'resolved'] as const) {
      for (const to of M.BOOKING_STATUSES) expect(M.canTransition(t, to)).toBe(false);
    }
    expect(M.canTransition('awaiting_payment', 'confirmed')).toBe(false);
    expect(M.canTransition('confirmed', 'refunded')).toBe(false);
    expect(M.canTransition(undefined, 'confirmed')).toBe(false);
  });
  test('seats are released only when leaving the seat-holding set', () => {
    expect(M.seatsReleased('confirmed', 'cancelled_by_guest', 3)).toBe(3);
    expect(M.seatsReleased('requested', 'declined', 2)).toBe(2);
    expect(M.seatsReleased('requested', 'expired', 2)).toBe(2);
    expect(M.seatsReleased('confirmed', 'no_show', 3)).toBe(0);
    expect(M.seatsReleased('confirmed', 'completed', 3)).toBe(0);
    expect(M.seatsReleased('disputed', 'resolved', 3)).toBe(0);
  });
});

describe('price math (minor units)', () => {
  test('BRL / EUR / USD and zero-decimal currencies', () => {
    expect(M.computeBookingPrice({ price: 49.9, currency: 'BRL' }, 2)).toEqual({
      ok: true, free: false, price: { unitAmount: 4990, currency: 'brl', totalAmount: 9980 },
    });
    expect(M.computeBookingPrice({ price: 19.99, currency: 'eur' }, 3)).toEqual({
      ok: true, free: false, price: { unitAmount: 1999, currency: 'eur', totalAmount: 5997 },
    });
    expect(M.computeBookingPrice({ price: 10, currency: 'USD' }, 1)).toEqual({
      ok: true, free: false, price: { unitAmount: 1000, currency: 'usd', totalAmount: 1000 },
    });
    expect(M.toMinorUnits(1500, 'jpy')).toBe(1500);
    expect(M.toMinorUnits(1.234, 'kwd')).toBe(1234);
    expect(M.toMinorUnits(0.1 + 0.2, 'usd')).toBe(30);
  });
  test('currency symbols stored by the app editor map to ISO codes', () => {
    expect(M.normalizeCurrency('R$')).toBe('brl');
    expect(M.normalizeCurrency('€')).toBe('eur');
    expect(M.normalizeCurrency('£')).toBe('gbp');
    expect(M.normalizeCurrency('$')).toBe('usd');
    expect(M.normalizeCurrency('¥')).toBe('jpy');
    expect(M.normalizeCurrency('EUR')).toBe('eur');
    expect(M.normalizeCurrency('₿')).toBeNull();
    expect(M.computeBookingPrice({ price: 50, currency: 'R$' }, 2)).toEqual({
      ok: true, free: false, price: { unitAmount: 5000, currency: 'brl', totalAmount: 10000 },
    });
  });
  test('free, missing currency, invalid price', () => {
    expect(M.computeBookingPrice({ isFree: true, price: 99 }, 4)).toEqual({
      ok: true, free: true, price: { unitAmount: 0, currency: null, totalAmount: 0 },
    });
    expect(M.computeBookingPrice({ price: 10 }, 1)).toEqual({ ok: false, reason: 'currency_missing' });
    expect(M.computeBookingPrice({ price: -1, currency: 'usd' }, 1)).toEqual({ ok: false, reason: 'invalid_price' });
    expect(M.computeBookingPrice({ price: 'ten', currency: 'usd' }, 1)).toEqual({ ok: false, reason: 'invalid_price' });
  });
});

describe('payment methods + refund obligation', () => {
  const link = { type: 'pix', value: 'chave@pix.com' };
  test('accepted methods (new field, legacy link-only docs)', () => {
    expect(M.acceptedPaymentMethods({ paymentMethods: ['cash', 'link'], paymentLink: link })).toEqual(['cash', 'link']);
    expect(M.acceptedPaymentMethods({ paymentMethods: ['cash'] })).toEqual(['cash']);
    expect(M.acceptedPaymentMethods({ paymentLink: link })).toEqual(['link']);
    expect(M.acceptedPaymentMethods({ paymentMethods: ['link'] })).toEqual([]); // link without a link
    expect(M.acceptedPaymentMethods({ paymentMethods: ['bitcoin'] })).toEqual([]);
  });
  test('guest choice is validated server-side', () => {
    const both = { paymentMethods: ['cash', 'link'], paymentLink: link };
    expect(M.choosePaymentMethod(both, undefined)).toEqual({ ok: false, reason: 'payment_method_required' });
    expect(M.choosePaymentMethod(both, 'cash')).toEqual({ ok: true, method: 'cash' });
    expect(M.choosePaymentMethod(both, 'stripe')).toEqual({ ok: false, reason: 'payment_method_not_accepted' });
    expect(M.choosePaymentMethod({ paymentMethods: ['cash'] }, undefined)).toEqual({ ok: true, method: 'cash' });
    expect(M.choosePaymentMethod({ paymentMethods: ['cash'] }, 'link')).toEqual({ ok: false, reason: 'payment_method_not_accepted' });
    expect(M.choosePaymentMethod({}, 'cash')).toEqual({ ok: false, reason: 'no_payment_method' });
  });
  test('refundDueFor: link owes the policy share; unpaid cash owes 0; free -> null', () => {
    const price = { unitAmount: 1999, currency: 'eur', totalAmount: 5997 };
    // Nobody marked the link payment as made: still owed, but only if paid.
    expect(M.refundDueFor(price, { mode: 'link' }, 50, 'guest_cancelled')).toEqual({
      percent: 50, policyPercent: 50, amount: 2999, currency: 'eur',
      reason: 'guest_cancelled_link_unconfirmed',
    });
    expect(M.refundDueFor(price, { mode: 'link', guestMarkedPaidAt: ts(T0) }, 50, 'guest_cancelled')).toEqual({
      percent: 50, policyPercent: 50, amount: 2999, currency: 'eur', reason: 'guest_cancelled',
    });
    expect(M.refundDueFor(price, { mode: 'cash', hostConfirmedPaidAt: null }, 100, 'host_cancelled')).toEqual({
      percent: 0, policyPercent: 100, amount: 0, currency: 'eur', reason: 'host_cancelled_cash_unpaid',
    });
    expect(M.refundDueFor(price, { mode: 'cash', hostConfirmedPaidAt: ts(T0) }, 100, 'dispute_resolution')).toEqual({
      percent: 100, policyPercent: 100, amount: 5997, currency: 'eur', reason: 'dispute_resolution',
    });
    expect(M.refundDueFor({ unitAmount: 0, currency: null, totalAmount: 0 }, { mode: 'free' }, 100, 'x')).toBeNull();
  });
});

describe('check-in code + host cancellation counting', () => {
  test('HMAC code is deterministic, case-insensitive, booking-bound', () => {
    const c = M.checkInCode('secret-1', 'bk_1');
    expect(c).toMatch(/^[A-Z0-9]{8}$/);
    expect(M.checkInCode('secret-1', 'bk_1')).toBe(c);
    expect(M.verifyCheckInCode('secret-1', 'bk_1', c.toLowerCase())).toBe(true);
    expect(M.verifyCheckInCode('secret-1', 'bk_2', c)).toBe(false);
    expect(M.verifyCheckInCode('secret-2', 'bk_1', c)).toBe(false);
    expect(M.verifyCheckInCode('secret-1', 'bk_1', 'short')).toBe(false);
    expect(M.verifyCheckInCode('secret-1', 'bk_1', 42)).toBe(false);
  });
  test('3 host cancellations within 90 days flag once per window', () => {
    const cfg = M.DEFAULT_CONFIG;
    const old = T0 - 100 * D;
    let r = M.pruneCancellations([old, T0 - 10 * D], T0, cfg);
    expect(r).toEqual([T0 - 10 * D, T0]);
    expect(M.shouldFlagHost(r, null, T0, cfg)).toBe(false);
    r = M.pruneCancellations(r, T0 + H, cfg);
    expect(M.shouldFlagHost(r, null, T0 + H, cfg)).toBe(true);
    expect(M.shouldFlagHost(r, T0 - 5 * D, T0 + H, cfg)).toBe(false);
    expect(M.shouldFlagHost(r, T0 - 91 * D, T0 + H, cfg)).toBe(true);
  });
  test('ID state reads only rule-protected fields (self-set idVerified is ignored)', () => {
    expect(M.idDocumentStateOf({ idVerified: true })).toBe('none');
    expect(M.idDocumentStateOf({ isAgeVerified: true })).toBe('approved');
    expect(M.idDocumentStateOf({ ageVerification: { status: 'verified' } })).toBe('approved');
    expect(M.idDocumentStateOf({ ageVerification: { status: 'pending' } })).toBe('uploaded');
    expect(M.idDocumentStateOf({ ageVerification: { status: 'rejected' } })).toBe('none');
    expect(M.idDocumentStateOf(null)).toBe('none');
  });

  test('config overrides are bounded', () => {
    const c = M.resolveConfig({ requestTtlHours: 12, hostCancelLimit: -4, disputeWindowHours: 'x' });
    expect(c.requestTtlHours).toBe(12);
    expect(c.hostCancelLimit).toBe(3);
    expect(c.disputeWindowHours).toBe(24);
  });
});

// ─────────────────────────────────────────────────────────── integration

let db: PathFakeFirestore;
let now: number;
let sent: Array<{ recipientId: string; type: string; body: string }>;
const saved = { ...svc.bookingDeps };

const HOST = 'host1';
const GUEST = 'guest1';
const GUEST2 = 'guest2';
const ADMIN = 'admin1';
const EXP = 'exp1';
const SLOT = 'slot1';
let reqN = 0;
const rid = () => `req_${String(++reqN).padStart(6, '0')}`;

function seedWorld(opts: { exp?: Record<string, any>; slot?: Record<string, any> } = {}) {
  db.seed(`profiles/${HOST}`, { isAgeVerified: true, displayName: 'Host' });
  db.seed(`profiles/${GUEST}`, { ageVerification: { status: 'pending' } });
  db.seed(`profiles/${GUEST2}`, { isAgeVerified: true });
  db.seed(`admin_users/${ADMIN}`, { role: 'admin' });
  db.seed(`user_experiences/${EXP}`, {
    hostId: HOST, status: 'published', title: 'Samba night', price: 19.99, currency: 'EUR',
    isFree: false, maxGroupSize: 10, cancellationPolicy: 'moderate',
    paymentMethods: ['cash', 'link'], paymentLink: { type: 'paypal', value: 'https://paypal.me/host' },
    ...(opts.exp || {}),
  });
  db.seed(`user_experiences/${EXP}/slots/${SLOT}`, {
    start: ts(T0 + 10 * D), end: ts(T0 + 10 * D + 3 * H), capacity: 4, bookedCount: 0, status: 'open',
    ...(opts.slot || {}),
  });
}

const slot = () => db.get(`user_experiences/${EXP}/slots/${SLOT}`) as Record<string, any>;
const booking = (id: string) => db.get(`bookings/${id}`) as Record<string, any>;

async function expectCode(p: Promise<unknown>, reason: string) {
  await expect(p).rejects.toBeInstanceOf(HttpsError);
  await p.catch((e: HttpsError) => expect((e.details as any)?.code).toBe(reason));
}

/** A booking REQUEST (request to book is mandatory). */
async function request(uid = GUEST, extra: Record<string, any> = {}) {
  return svc.createBooking(uid, {
    experienceId: EXP, slotId: SLOT, guests: 1, requestId: rid(), consentVersion: 'v1',
    paymentMethod: 'link', ...extra,
  }) as Promise<any>;
}

/** A request the host accepted: a confirmed booking. */
async function book(uid = GUEST, extra: Record<string, any> = {}) {
  const r: any = await request(uid, extra);
  const a: any = await svc.respondToBookingRequest(HOST, { bookingId: r.bookingId, accept: true });
  return { ...r, ...a, bookingId: r.bookingId } as any;
}

beforeEach(() => {
  db = new PathFakeFirestore();
  now = T0;
  sent = [];
  svc.resetCachedSecret();
  Object.assign(svc.bookingDeps, {
    db: () => db as any,
    now: () => new Date(now),
    notify: async (p: any) => { sent.push({ recipientId: p.recipientId, type: p.type, body: p.body }); },
    actor: async (uid: string) => ({ id: uid, name: uid }),
  });
});

afterAll(() => Object.assign(svc.bookingDeps, saved));

describe('createBooking', () => {
  test('every booking is a request; accepted -> confirmed, seats held, price from the experience, idempotent retry', async () => {
    seedWorld();
    const requestId = 'req_retry_0001';
    const input = { experienceId: EXP, slotId: SLOT, guests: 2, requestId, consentVersion: 'v1', paymentMethod: 'link', price: 1 };
    const r1: any = await svc.createBooking(GUEST, input);
    expect(r1.status).toBe('requested');
    expect(slot().bookedCount).toBe(2);
    await svc.respondToBookingRequest(HOST, { bookingId: r1.bookingId, accept: true });
    expect(r1.price).toEqual({ unitAmount: 1999, currency: 'eur', totalAmount: 3998 });
    expect(r1.payment.mode).toBe('link');
    expect(r1.payment.link).toEqual({ type: 'paypal', value: 'https://paypal.me/host' });
    expect(slot().bookedCount).toBe(2);
    const b = booking(r1.bookingId);
    expect(b.policy).toBe('moderate');
    expect(b.reminderAt.toMillis()).toBe(T0 + 10 * D - 24 * H);
    expect(b.completeAt.toMillis()).toBe(T0 + 10 * D + 3 * H + 24 * H);
    const r2: any = await svc.createBooking(GUEST, input);
    expect(r2.bookingId).toBe(r1.bookingId);
    expect(r2.alreadyExisted).toBe(true);
    expect(slot().bookedCount).toBe(2);
    expect(sent.map((s) => s.type).sort()).toEqual(['booking_accepted', 'booking_request']);
  });

  test('cash chosen; both methods require an explicit choice', async () => {
    seedWorld();
    const r: any = await book(GUEST, { paymentMethod: 'cash' });
    expect(r.payment).toMatchObject({ mode: 'cash', link: null });
    await expectCode(book(GUEST2, { paymentMethod: undefined }), 'payment_method_required');
    await expectCode(book(GUEST2, { paymentMethod: 'stripe' }), 'payment_method_not_accepted');
  });

  test('free experience: mode free, no host ID approval needed', async () => {
    seedWorld({ exp: { isFree: true, price: 0, currency: null, paymentMethods: null, paymentLink: null } });
    db.seed(`profiles/${HOST}`, { ageVerification: { status: 'pending' } });
    const r: any = await book(GUEST, { paymentMethod: 'cash' });
    expect(r.status).toBe('confirmed');
    expect(r.payment.mode).toBe('free');
    expect(r.price.totalAmount).toBe(0);
  });

  test('validation: party size, duplicate, own listing, ID, host verification, block, status', async () => {
    seedWorld({ exp: { maxGroupSize: 2 } });
    await expectCode(book(GUEST, { guests: 3 }), 'too_many_guests');
    await expectCode(book(GUEST, { guests: 0 }), 'invalid_guests');
    await expectCode(book(HOST), 'own_experience');
    await book(GUEST);
    await expectCode(book(GUEST), 'already_booked');

    db.seed(`profiles/${GUEST2}`, {});
    db.seed(`user_experiences/${EXP}/slots/${SLOT}`, { start: ts(T0 + D * 10), end: ts(T0 + D * 10 + H), capacity: 9, bookedCount: 0, status: 'open' });
    await expectCode(book(GUEST2), 'id_document_required');

    db.seed(`profiles/${GUEST2}`, { isAgeVerified: true });
    db.seed(`profiles/${HOST}`, { ageVerification: { status: 'pending' } });
    await expectCode(book(GUEST2), 'host_not_verified');
    db.seed(`profiles/${HOST}`, { isAgeVerified: true });

    db.seed('blockedUsers/x', { blockerId: HOST, blockedUserId: GUEST2 });
    await expectCode(book(GUEST2), 'not_available');
    db.remove('blockedUsers/x');

    db.seed(`host_suspensions/${HOST}`, { active: true });
    await expectCode(book(GUEST2), 'host_unavailable');
    db.remove(`host_suspensions/${HOST}`);

    db.seed(`user_experiences/${EXP}`, { ...db.get(`user_experiences/${EXP}`), status: 'draft' });
    await expectCode(book(GUEST2), 'experience_not_bookable');
  });

  test('consent: explicit (string / int) or from booking_consents, else refused', async () => {
    seedWorld({ exp: { durationMinutes: 60 } });
    await expectCode(book(GUEST, { consentVersion: undefined }), 'consent_required');
    db.seed(`user_experiences/${EXP}/booking_consents/${GUEST}`, { experienceId: EXP, version: 3, policy: 'moderate' });
    const r: any = await book(GUEST, { consentVersion: undefined });
    expect(booking(r.bookingId).consentVersion).toBe('3');
    const r2: any = await book(GUEST2, { consentVersion: 2 });
    expect(booking(r2.bookingId).consentVersion).toBe('2');
  });

  test('slot in the past / closed', async () => {
    seedWorld({ slot: { start: ts(T0 - H), end: ts(T0 + H) } });
    await expectCode(book(), 'slot_started');
    seedWorld({ slot: { status: 'cancelled' } });
    await expectCode(book(), 'slot_closed');
  });
});

describe('grace window', () => {
  test('the 24 h grace counts from the host confirming, not from the request', async () => {
    // Strict listing 5 days out: without the grace, a guest cancelling now
    // gets nothing back.
    seedWorld({ exp: { cancellationPolicy: 'strict' }, slot: { start: ts(T0 + 5 * D), end: ts(T0 + 5 * D + 3 * H) } });
    const r: any = await request(GUEST);
    now = T0 + 30 * H; // the host accepts 30 h after the request
    await svc.respondToBookingRequest(HOST, { bookingId: r.bookingId, accept: true });
    now = T0 + 31 * H; // 1 h after confirmation, start still > 48 h away
    await svc.cancelBooking(GUEST, { bookingId: r.bookingId });
    expect(booking(r.bookingId).refundDue.policyPercent).toBe(100);

    // Same, but cancelling 25 h after confirmation: strict applies (< 7 days).
    seedWorld({ exp: { cancellationPolicy: 'strict' }, slot: { start: ts(T0 + 5 * D), end: ts(T0 + 5 * D + 3 * H), bookedCount: 0 } });
    now = T0;
    const r2: any = await request(GUEST2);
    now = T0 + 2 * H;
    await svc.respondToBookingRequest(HOST, { bookingId: r2.bookingId, accept: true });
    now = T0 + 27 * H;
    await svc.cancelBooking(GUEST2, { bookingId: r2.bookingId });
    expect(booking(r2.bookingId).refundDue.policyPercent).toBe(0);
  });
});

describe('request to book', () => {
  test('requested holds seats; decline releases them; expiry job; accept confirms', async () => {
    seedWorld();
    const r: any = await request(GUEST, { guests: 2 });
    expect(r.status).toBe('requested');
    expect(slot().bookedCount).toBe(2);
    expect(booking(r.bookingId).requestExpiresAt.toMillis()).toBe(T0 + 48 * H);
    await expectCode(svc.respondToBookingRequest(GUEST, { bookingId: r.bookingId, accept: true }), 'not_host');
    const d: any = await svc.respondToBookingRequest(HOST, { bookingId: r.bookingId, accept: false });
    expect(d.status).toBe('declined');
    expect(slot().bookedCount).toBe(0);
    // decline is idempotent
    await svc.respondToBookingRequest(HOST, { bookingId: r.bookingId, accept: false });
    expect(slot().bookedCount).toBe(0);

    const r2: any = await request(GUEST2);
    now = T0 + 49 * H;
    await expectCode(svc.respondToBookingRequest(HOST, { bookingId: r2.bookingId, accept: true }), 'request_expired');
    expect(await svc.expireDueRequests()).toBe(1);
    expect(booking(r2.bookingId).status).toBe('expired');
    expect(slot().bookedCount).toBe(0);
    expect(sent.some((s) => s.type === 'booking_expired')).toBe(true);

    now = T0;
    const r3: any = await request(GUEST, { guests: 1 });
    const a: any = await svc.respondToBookingRequest(HOST, { bookingId: r3.bookingId, accept: true });
    expect(a.status).toBe('confirmed');
    expect(booking(r3.bookingId).reminderAt).toBeDefined();
    expect(booking(r3.bookingId).requestExpiresAt).toBeUndefined();
  });
});

describe('cancelBooking', () => {
  test('guest cancels 3 days before (moderate): 50% owed via link; seats released', async () => {
    seedWorld();
    const r: any = await book(GUEST, { guests: 3 });
    now = T0 + 7 * D; // start is T0 + 10 d
    const c: any = await svc.cancelBooking(GUEST, { bookingId: r.bookingId, reason: 'sick' });
    expect(c.status).toBe('cancelled_by_guest');
    expect(c.refundDue).toMatchObject({ percent: 50, amount: 2999, currency: 'eur' });
    expect(slot().bookedCount).toBe(0);
    expect(sent.some((s) => s.recipientId === HOST && s.type === 'booking_cancelled')).toBe(true);
    // repeat = no-op, not an error
    await svc.cancelBooking(GUEST, { bookingId: r.bookingId });
    await expectCode(svc.cancelBooking(HOST, { bookingId: r.bookingId }), 'not_cancellable');
  });

  test('cash not yet paid: obligation is 0 even when the host cancels', async () => {
    seedWorld();
    const r: any = await book(GUEST, { paymentMethod: 'cash' });
    const c: any = await svc.cancelBooking(HOST, { bookingId: r.bookingId });
    expect(c.refundDue).toMatchObject({ percent: 0, policyPercent: 100, amount: 0 });
  });

  test('outsiders and after-start cancels are refused', async () => {
    seedWorld();
    const r: any = await book();
    await expectCode(svc.cancelBooking(GUEST2, { bookingId: r.bookingId }), 'not_a_party');
    now = T0 + 10 * D + 1;
    await expectCode(svc.cancelBooking(GUEST, { bookingId: r.bookingId }), 'already_started');
  });

  test('3 host cancellations in 90 days -> host_flags + admins notified', async () => {
    seedWorld({ slot: { capacity: 10 } });
    for (const g of ['ga', 'gb', 'gc']) {
      db.seed(`profiles/${g}`, { isAgeVerified: true });
      const r: any = await book(g);
      await svc.cancelBooking(HOST, { bookingId: r.bookingId });
    }
    const stats = db.get(`host_cancellation_stats/${HOST}`) as any;
    expect(stats.count).toBe(3);
    expect(db.get(`host_flags/${HOST}`)).toMatchObject({ type: 'excess_host_cancellations', status: 'open', count: 3 });
    expect(sent.filter((s) => s.recipientId === ADMIN && s.type === 'admin_host_cancellations')).toHaveLength(1);
  });

  test('cancelExperienceSlot cancels every active booking and the slot', async () => {
    seedWorld({ exp: { durationMinutes: 60 } });
    await book(GUEST, { guests: 2 });
    await book(GUEST2, { guests: 3 });
    await expectCode(svc.cancelSlot(GUEST, { experienceId: EXP, slotId: SLOT }), 'not_host');
    const r: any = await svc.cancelSlot(HOST, { experienceId: EXP, slotId: SLOT, reason: 'rain' });
    expect(r.cancelledBookings).toBe(2);
    expect(slot()).toMatchObject({ status: 'cancelled', bookedCount: 0 });
    expect((db.get(`host_cancellation_stats/${HOST}`) as any).count).toBe(1);
  });
});

describe('private time slots (one user per time, host never double-booked)', () => {
  const W = T0 + 10 * D; // window 3h: starts at W, W+1h, W+2h for 60 min

  test('each user gets a different time; a taken time is refused', async () => {
    seedWorld({ exp: { durationMinutes: 60 } });
    const a: any = await request(GUEST, { startAt: W + H });
    expect(booking(a.bookingId)).toMatchObject({ slotStart: ts(W + H), slotEnd: ts(W + 2 * H) });
    await expectCode(request(GUEST2, { startAt: W + H }), 'time_taken');
    await expectCode(request(GUEST2, { startAt: W + 30 * 60 * 1000 }), 'invalid_start');
    const b: any = await request(GUEST2, { startAt: W });
    expect(booking(b.bookingId).slotEnd).toEqual(ts(W + H));
    // no start sent (older app): first free time
    db.seed(`profiles/guest3`, { isAgeVerified: true });
    const c: any = await request('guest3');
    expect(booking(c.bookingId).slotStart).toEqual(ts(W + 2 * H));
    db.seed(`profiles/guest4`, { isAgeVerified: true });
    await expectCode(request('guest4'), 'time_taken');
  });

  test('the host is never double-booked across their experiences', async () => {
    seedWorld({ exp: { durationMinutes: 60 } });
    db.seed(`user_experiences/exp2`, { ...(db.get(`user_experiences/${EXP}`) as any), title: 'Other', durationMinutes: 90 });
    db.seed(`user_experiences/exp2/slots/s2`, {
      start: ts(W), end: ts(W + 3 * H), capacity: 4, bookedCount: 0, status: 'open',
    });
    await request(GUEST, { startAt: W + H }); // exp1 11:00-12:00
    // exp2 starts on a 90-min grid: W (10:00-11:30) overlaps 11:00 -> taken
    await expectCode(svc.createBooking(GUEST2, {
      experienceId: 'exp2', slotId: 's2', guests: 1, requestId: rid(), consentVersion: 'v1',
      paymentMethod: 'link', startAt: W,
    }), 'time_taken');
    const av: any = await svc.getSlotAvailability(GUEST2, { experienceId: 'exp2', slotId: 's2' });
    expect(av.lengthMinutes).toBe(90);
    // 10:00-11:30 and 11:30-13:00 both overlap the 11:00-12:00 booking
    expect(av.starts.map((x: any) => x.free)).toEqual([false, false]);
  });

  test('availability marks taken and past times; declining frees a time', async () => {
    seedWorld({ exp: { durationMinutes: 60 } });
    const a: any = await request(GUEST, { startAt: W });
    let av: any = await svc.getSlotAvailability(GUEST2, { experienceId: EXP, slotId: SLOT });
    expect(av.starts.map((x: any) => x.free)).toEqual([false, true, true]);
    await svc.respondToBookingRequest(HOST, { bookingId: a.bookingId, accept: false });
    av = await svc.getSlotAvailability(GUEST2, { experienceId: EXP, slotId: SLOT });
    expect(av.starts.map((x: any) => x.free)).toEqual([true, true, true]);
  });

  test('no duration / longer than the window: the booking takes the whole window', async () => {
    seedWorld({ exp: { durationMinutes: 600 } });
    const a: any = await request(GUEST);
    expect(booking(a.bookingId)).toMatchObject({ slotStart: ts(W), slotEnd: ts(W + 3 * H) });
    await expectCode(request(GUEST2), 'time_taken');
  });

  test('a host cannot accept a pre-existing request that overlaps a confirmed booking', async () => {
    seedWorld({ exp: { durationMinutes: 60 } });
    const a: any = await request(GUEST, { startAt: W });
    // legacy overlapping request (created before private slots existed)
    db.seed('bookings/legacy1', {
      ...(booking(a.bookingId) as any), guestId: GUEST2, requestId: 'legacy',
    });
    await svc.respondToBookingRequest(HOST, { bookingId: a.bookingId, accept: true });
    await expectCode(svc.respondToBookingRequest(HOST, { bookingId: 'legacy1', accept: true }), 'time_taken');
  });
});

describe('check-in, cash, no-show, disputes', () => {
  async function confirmed(extra: Record<string, any> = {}) {
    seedWorld();
    return (await book(GUEST, extra)).bookingId as string;
  }

  test('check-in needs the guest HMAC code; unlocks the review; cash receipt', async () => {
    const id = await confirmed({ paymentMethod: 'cash' });
    const { code, qrPayload }: any = await svc.getBookingCheckInCode(GUEST, { bookingId: id });
    expect(qrPayload).toBe(`greengo:checkin:${id}:${code}`);
    await expectCode(svc.getBookingCheckInCode(HOST, { bookingId: id }), 'not_guest');
    now = T0 + 10 * D - 30 * 60 * 1000;
    await expectCode(svc.checkInBooking(HOST, { bookingId: id, code: 'AAAAAAAA' }), 'invalid_code');
    await expectCode(svc.checkInBooking(GUEST, { bookingId: id, code }), 'not_host');
    // cash cannot be confirmed before the meeting, and never by the guest
    now = T0;
    await expectCode(svc.confirmCashReceived(HOST, { bookingId: id }), 'cash_before_meeting');
    await expectCode(svc.markBookingPaid(GUEST, { bookingId: id }), 'host_confirms_cash');
    now = T0 + 10 * D - 30 * 60 * 1000;
    const r: any = await svc.checkInBooking(HOST, { bookingId: id, code, cashReceived: true });
    expect(r.checkedInAt).not.toBeNull();
    expect(r.payment.hostConfirmedPaidAt).not.toBeNull();
    expect(db.get(`user_experiences/${EXP}/review_eligibility/${GUEST}`)).toMatchObject({ bookingId: id });
    const again: any = await svc.checkInBooking(HOST, { bookingId: id, code });
    expect(again.alreadyCheckedIn).toBe(true);
  });

  test('helpers at the door, wrong experience, forged codes, met in person', async () => {
    const id = await confirmed({ paymentMethod: 'cash' });
    const { code }: any = await svc.getBookingCheckInCode(GUEST, { bookingId: id });
    now = T0 + 10 * D - 30 * 60 * 1000;
    // not authorised yet
    await expectCode(svc.checkInBooking(GUEST2, { bookingId: id, code }), 'not_host');
    db.seed(`user_experiences/${EXP}`, { ...(db.get(`user_experiences/${EXP}`) as any), allowedScannerIds: [GUEST2] });
    // a valid code for ANOTHER experience is refused at this door
    await expectCode(svc.checkInBooking(GUEST2, { bookingId: id, code, experienceId: 'other' }), 'wrong_experience');
    // a helper cannot confirm cash, but can open the door
    const r: any = await svc.checkInBooking(GUEST2, { bookingId: id, code, experienceId: EXP, cashReceived: true });
    expect(r.checkedInAt).not.toBeNull();
    expect(r.payment?.hostConfirmedPaidAt ?? null).toBeNull();
    expect(r.guestName).toBe('');
    // host and guest met in person — recorded once
    const pair = [HOST, GUEST].sort().join('_');
    expect(db.get(`met_in_person/${pair}`)).toMatchObject({ users: [HOST, GUEST].sort() });
    expect(db.get(`met_in_person/${pair}/encounters/experience_${id}`)).toMatchObject({ verified: true, byUid: GUEST2 });
    // a forged code learns nothing, not even "already checked in"
    await expectCode(svc.checkInBooking(HOST, { bookingId: id, code: 'AAAAAAAA' }), 'invalid_code');
    const again: any = await svc.checkInBooking(HOST, { bookingId: id, code });
    expect(again.alreadyCheckedIn).toBe(true);
  });

  test('check-in outside the window is refused', async () => {
    const id = await confirmed({ paymentMethod: 'cash' });
    const { code }: any = await svc.getBookingCheckInCode(GUEST, { bookingId: id });
    now = T0 + 5 * D;
    await expectCode(svc.checkInBooking(HOST, { bookingId: id, code }), 'outside_checkin_window');
  });

  test('link payment: no check-in QR until the host confirmed the payment', async () => {
    const id = await confirmed();
    await expectCode(svc.getBookingCheckInCode(GUEST, { bookingId: id }), 'not_paid');
    await svc.markBookingPaid(GUEST, { bookingId: id });
    await expectCode(svc.getBookingCheckInCode(GUEST, { bookingId: id }), 'not_paid');
    await svc.markBookingPaid(HOST, { bookingId: id });
    const { qrPayload }: any = await svc.getBookingCheckInCode(GUEST, { bookingId: id });
    expect(qrPayload).toMatch(/^greengo:checkin:/);
  });

  test('link payment marks: guest says paid, host confirms', async () => {
    const id = await confirmed();
    const g: any = await svc.markBookingPaid(GUEST, { bookingId: id });
    expect(g.payment.guestMarkedPaidAt).not.toBeNull();
    const h: any = await svc.markBookingPaid(HOST, { bookingId: id });
    expect(h.payment.hostConfirmedPaidAt).not.toBeNull();
    await expectCode(svc.confirmCashReceived(HOST, { bookingId: id }), 'not_cash_payment');
  });

  test('no-show only after start + 30 min without check-in; seats stay; 0% owed', async () => {
    const id = await confirmed();
    now = T0 + 10 * D + 10 * 60 * 1000;
    await expectCode(svc.markNoShow(HOST, { bookingId: id }), 'too_early');
    now = T0 + 10 * D + 31 * 60 * 1000;
    await expectCode(svc.markNoShow(GUEST, { bookingId: id }), 'not_host');
    const r: any = await svc.markNoShow(HOST, { bookingId: id });
    expect(r.status).toBe('no_show');
    expect(r.refundDue).toMatchObject({ percent: 0, amount: 0 });
    expect(slot().bookedCount).toBe(1);
  });

  test('dispute: window, removes review eligibility, admin-only resolution + host action', async () => {
    const id = await confirmed();
    await svc.markBookingPaid(HOST, { bookingId: id }); // link payment received -> QR
    const { code }: any = await svc.getBookingCheckInCode(GUEST, { bookingId: id });
    now = T0 + 10 * D;
    await expectCode(svc.openBookingDispute(GUEST, { bookingId: id, reason: 'short' }), 'reason_required');
    await svc.checkInBooking(HOST, { bookingId: id, code });
    expect(db.get(`user_experiences/${EXP}/review_eligibility/${GUEST}`)).toBeDefined();
    now = T0 + 10 * D + 3 * H + 25 * H; // end + 25 h
    await expectCode(svc.openBookingDispute(GUEST, { bookingId: id, reason: 'host never showed up' }), 'outside_dispute_window');
    now = T0 + 10 * D + 3 * H + 2 * H;
    const d: any = await svc.openBookingDispute(GUEST, { bookingId: id, reason: 'host never showed up' });
    expect(d.status).toBe('disputed');
    expect(db.get(`user_experiences/${EXP}/review_eligibility/${GUEST}`)).toBeUndefined();
    expect(sent.some((s) => s.recipientId === ADMIN && s.type === 'admin_booking_dispute')).toBe(true);

    // completion job must not complete a disputed booking
    now = T0 + 30 * D;
    expect(await svc.completeDueBookings()).toBe(0);

    await expectCode(svc.resolveBookingDispute(GUEST, { bookingId: id, refundPercent: 100 }), 'admin_only');
    await expectCode(svc.resolveBookingDispute(ADMIN, { bookingId: id, refundPercent: 101 }), 'invalid_refund_percent');
    const r: any = await svc.resolveBookingDispute(ADMIN, {
      bookingId: id, refundPercent: 100, hostAction: 'hide_listing', note: 'confirmed by chat logs',
    });
    expect(r.status).toBe('resolved');
    expect(r.refundDue).toMatchObject({ percent: 100, amount: 1999 });
    expect(r.dispute.resolution).toMatchObject({ refundPercent: 100, hostAction: 'hide_listing' });
    expect(db.get(`user_experiences/${EXP}`)).toMatchObject({ status: 'hidden', moderation: { reason: 'booking_dispute' } });
    await svc.resolveBookingDispute(ADMIN, { bookingId: id, refundPercent: 0 }); // no-op
    expect(booking(id).dispute.resolution.refundPercent).toBe(100);
  });

  test('suspend_hosting blocks new bookings of that host', async () => {
    const id = await confirmed();
    now = T0 + 10 * D + H;
    await svc.openBookingDispute(GUEST, { bookingId: id, reason: 'not as described at all' });
    await svc.resolveBookingDispute(ADMIN, { bookingId: id, refundPercent: 0, hostAction: 'suspend_hosting' });
    now = T0;
    await expectCode(book(GUEST2), 'host_unavailable');
  });

  test('a no-show can be contested', async () => {
    const id = await confirmed();
    now = T0 + 10 * D + H;
    await svc.markNoShow(HOST, { bookingId: id });
    const d: any = await svc.openBookingDispute(GUEST, { bookingId: id, reason: 'I was there, he ignored me' });
    expect(d.status).toBe('disputed');
    expect(booking(id).dispute.fromStatus).toBe('no_show');
  });
});

describe('jobs', () => {
  test('reminders are sent once, 24 h before', async () => {
    seedWorld();
    await book();
    now = T0 + 9 * D - H;
    expect(await svc.sendDueReminders()).toBe(0);
    now = T0 + 9 * D + H;
    expect(await svc.sendDueReminders()).toBe(1);
    expect(await svc.sendDueReminders()).toBe(0);
    expect(sent.filter((s) => s.type === 'booking_reminder')).toHaveLength(1);
    expect(sent.filter((s) => s.type === 'booking_reminder_host')).toHaveLength(1);
  });

  test('completion after end + 24 h unlocks reviews and prompts both sides', async () => {
    seedWorld();
    const r: any = await book();
    now = T0 + 10 * D + 3 * H + 23 * H;
    expect(await svc.completeDueBookings()).toBe(0);
    now = T0 + 10 * D + 3 * H + 24 * H;
    expect(await svc.completeDueBookings()).toBe(1);
    expect(booking(r.bookingId).status).toBe('completed');
    expect(db.get(`user_experiences/${EXP}/review_eligibility/${GUEST}`)).toMatchObject({ bookingId: r.bookingId });
    expect(sent.some((s) => s.type === 'booking_review_prompt')).toBe(true);
    expect(slot().bookedCount).toBe(1);
  });

  test('experience deleted: future bookings cancelled by host, subtree cleaned', async () => {
    seedWorld();
    const r: any = await book();
    db.remove(`user_experiences/${EXP}`);
    expect(await svc.onExperienceDeleted(EXP, HOST)).toBe(1);
    expect(booking(r.bookingId)).toMatchObject({ status: 'cancelled_by_host' });
    expect(db.get(`user_experiences/${EXP}/slots/${SLOT}`)).toBeUndefined();
  });

  test('invalid transitions are refused by the state machine', async () => {
    seedWorld();
    const r: any = await book();
    now = T0 + 12 * D;
    await svc.completeDueBookings();
    await expectCode(svc.markNoShow(HOST, { bookingId: r.bookingId }), 'not_confirmed');
    await expectCode(svc.transition(r.bookingId, () => ({ to: 'confirmed' }), M.DEFAULT_CONFIG), 'invalid_transition');
  });
});

describe('two-way double-blind reviews', () => {
  async function completedBooking() {
    seedWorld();
    const r: any = await book();
    now = T0 + 12 * D;
    await svc.completeDueBookings();
    return r.bookingId as string;
  }

  /** Simulates the onGuestReviewWritten trigger: one call per write event. */
  async function guestReviewEvents(id: string, eventPrefix: string) {
    let prev: any = null;
    let n = 0;
    return async () => {
      const cur = db.get(`guest_reviews/${id}`) ?? null;
      await rev.handleGuestReviewWrite(`${eventPrefix}_${++n}`, id, prev, cur);
      prev = cur;
    };
  }

  test('both sides submitted -> both revealed; guest aggregate applied once', async () => {
    const id = await completedBooking();
    db.seed(`profiles/${GUEST}`, { ...db.get(`profiles/${GUEST}`) });
    // host reviews the guest
    db.seed(`guest_reviews/${id}`, { hostId: HOST, guestId: GUEST, experienceId: EXP, rating: 4, comment: 'Lovely guest', createdAt: ts(now) });
    const fire = await guestReviewEvents(id, 'ev');
    await fire(); // create -> held
    expect(db.get(`guest_reviews/${id}`)).toMatchObject({ status: 'held' });
    await fire(); // status write: no delta while held
    expect(db.get(`profiles/${GUEST}`)?.guestRatingCount).toBeUndefined();
    expect(sent.some((s) => s.recipientId === GUEST && s.type === 'guest_review_waiting')).toBe(true);

    // guest submits the blind experience review
    db.seed(`user_experiences/${EXP}/pending_reviews/${GUEST}`, {
      authorId: GUEST, bookingId: id, rating: 5, comment: 'Great night', createdAt: ts(now), updatedAt: ts(now),
    });
    await rev.handlePendingReviewCreated(EXP, GUEST, db.get(`user_experiences/${EXP}/pending_reviews/${GUEST}`)!);
    expect(db.get(`user_experiences/${EXP}/reviews/${GUEST}`)).toMatchObject({ authorId: GUEST, rating: 5, bookingId: id });
    expect(db.get(`user_experiences/${EXP}/pending_reviews/${GUEST}`)).toBeUndefined();
    expect(db.get(`user_experiences/${EXP}/review_eligibility/${GUEST}`)).toBeUndefined();
    expect(db.get(`guest_reviews/${id}`)).toMatchObject({ status: 'visible' });

    const before = { ...(db.get(`guest_reviews/${id}`) as any), status: 'held' };
    const after = db.get(`guest_reviews/${id}`);
    await rev.handleGuestReviewWrite('ev_vis', id, before, after);
    await rev.handleGuestReviewWrite('ev_vis', id, before, after); // duplicate delivery
    expect(db.get(`profiles/${GUEST}`)).toMatchObject({ guestRatingSum: 4, guestRatingCount: 1, guestRatingAvg: 4 });
    expect(sent.some((s) => s.recipientId === GUEST && s.type === 'guest_review_published')).toBe(true);
  });

  test('one side only -> revealed after the blind period by the job', async () => {
    const id = await completedBooking();
    db.seed(`user_experiences/${EXP}/pending_reviews/${GUEST}`, {
      authorId: GUEST, bookingId: id, rating: 3, comment: 'ok', createdAt: ts(now), updatedAt: ts(now),
    });
    await rev.handlePendingReviewCreated(EXP, GUEST, db.get(`user_experiences/${EXP}/pending_reviews/${GUEST}`)!);
    expect(db.get(`user_experiences/${EXP}/reviews/${GUEST}`)).toBeUndefined();
    expect(sent.some((s) => s.recipientId === HOST && s.type === 'booking_review_waiting')).toBe(true);
    now += 13 * D;
    expect(await rev.revealDueReviews()).toBe(0);
    now += 2 * D;
    expect(await rev.revealDueReviews()).toBe(1);
    expect(db.get(`user_experiences/${EXP}/reviews/${GUEST}`)).toMatchObject({ rating: 3, bookingId: id });

    // the host reviews later: guest already revealed -> visible immediately
    db.seed(`guest_reviews/${id}`, { hostId: HOST, guestId: GUEST, experienceId: EXP, rating: 5, comment: 'Welcome back', createdAt: ts(now) });
    await rev.handleGuestReviewWrite('late_1', id, null, db.get(`guest_reviews/${id}`)!);
    expect(db.get(`guest_reviews/${id}`)).toMatchObject({ status: 'visible' });
  });

  test('prohibited text in a host review is rejected and never aggregated', async () => {
    const id = await completedBooking();
    db.seed(`guest_reviews/${id}`, { hostId: HOST, guestId: GUEST, experienceId: EXP, rating: 1, comment: 'what a bitch', createdAt: ts(now) });
    await rev.handleGuestReviewWrite('rj_1', id, null, db.get(`guest_reviews/${id}`)!);
    expect(db.get(`guest_reviews/${id}`)).toMatchObject({ status: 'rejected' });
    const d = M.guestRatingDelta(null, db.get(`guest_reviews/${id}`));
    expect(d).toEqual({ sum: 0, count: 0 });
  });

  test('reviewability and aggregate math', () => {
    expect(M.bookingReviewable({ status: 'completed' }, 'guest')).toBe(true);
    expect(M.bookingReviewable({ status: 'confirmed', checkIn: { at: 1 } }, 'guest')).toBe(true);
    expect(M.bookingReviewable({ status: 'confirmed', checkIn: null }, 'guest')).toBe(false);
    expect(M.bookingReviewable({ status: 'no_show' }, 'host')).toBe(true);
    expect(M.bookingReviewable({ status: 'no_show' }, 'guest')).toBe(false);
    expect(M.bookingReviewable({ status: 'disputed' }, 'host')).toBe(false);
    expect(M.applyGuestRatingDelta({ guestRatingSum: 9, guestRatingCount: 2 }, { sum: 3, count: 1 }))
      .toEqual({ guestRatingSum: 12, guestRatingCount: 3, guestRatingAvg: 4 });
    expect(M.applyGuestRatingDelta({ guestRatingSum: 1, guestRatingCount: 0 }, { sum: -5, count: -1 }))
      .toEqual({ guestRatingSum: 0, guestRatingCount: 0, guestRatingAvg: 0 });
  });
});
