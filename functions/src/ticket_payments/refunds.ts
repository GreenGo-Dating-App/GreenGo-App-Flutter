/**
 * Ticket refund engine (compliance gaps #1 + #2, owner approval 2026-10-21).
 *
 * When the SELLER cancels (Terms 11.1 "cancelling it in good time", 12.2 /
 * 12.5 c "if the Host removes a booked time or cancels a booking, GreenGo
 * starts a full refund to the Guest through the Host's own Stripe or Mercado
 * Pago account"), every paid order of that listing is refunded IN FULL,
 * automatically:
 *
 *   - Stripe: direct charge on the connected account -> refunds.create ON THE
 *     CONNECTED ACCOUNT (stripeAccount) for the whole charge, with
 *     refund_application_fee: true (Terms 11.6 f: "if a ticket or booking is
 *     refunded in full, the fee is returned to the seller"). Idempotency key
 *     gg_refund_{orderId} (providers.stripeRefund).
 *   - Mercado Pago: POST /v1/payments/{id}/refunds with the SELLER's token
 *     (MP returns the marketplace fee with a full refund), X-Idempotency-Key
 *     gg_refund_{orderId}.
 *   - Legacy link orders (paid outside GreenGo): `refund_owed`, the seller is
 *     told to pay the buyer back (nothing GreenGo can move).
 *   - Orders still open (checkout not paid): closed as 'cancelled' (holds
 *     released, Stripe session expired) - nothing to refund. A late payment
 *     of such an order is caught by refundIfListingCancelled (orders.ts).
 *
 * Who pays what on a refund: the buyer gets 100 % of what they paid; the
 * refund is debited from the SELLER's Stripe / MP balance; GreenGo's
 * application / marketplace fee goes back to the seller (full refund).
 * Stripe / MP do not return their own processing fees (their terms, Terms
 * 11.6 g). GreenGo never pays a refund from its own funds (Terms 12.5 c).
 *
 * Outbox: `ticket_refunds/{orderId}` (server-only; ONE doc per order = no
 * double refund, whatever re-triggers):
 *   { orderId, kind, listingId, bookingId, organizerId, buyerId, isGuest,
 *     provider, amount, currency, title, reason, batchId, status, attempts,
 *     nextAttemptAt, leaseUntil, providerRefundId, lastError, failure,
 *     createdAt, updatedAt, completedAt, proof?, review? }
 *   status: pending -> processing -> refunded | refund_owed | not_needed
 *                                  | retry (backoff) -> ... | refund_failed
 *           refund_failed -> manual_refund_pending_review (seller uploaded a
 *           proof) -> refunded_manually (admin approved) | refund_failed
 * The order mirrors it in `ticket_orders.refund { status, reason, at, ... }`
 * (buyer + organizer can read orders; the outbox is server-only).
 *
 * Processing: processTicketRefund (onDocumentCreated, bounded concurrency)
 * and sweepTicketRefunds (every 10 min: retries + stale leases). A
 * transactional lease keeps the two from refunding the same doc twice; the
 * provider idempotency key covers a crash between the provider call and the
 * Firestore write.
 *
 * Failures: permanent (seller account disconnected / no permission,
 * insufficient balance, dispute, missing payment reference, MP 4xx) or
 * retries exhausted -> `refund_failed`: admin_alerts/ticket_refund_failed_{orderId},
 * the buyer is told support will contact them, the seller is told to refund
 * manually and upload a proof (submitManualRefundProof -> admin review).
 */
import * as admin from 'firebase-admin';
import '../shared/firebaseAdmin';
import { HttpsError } from 'firebase-functions/v2/https';
import * as cfg from './config';
import { COL } from './config';
import { ProviderError, mpRefund, stripeExpireSession, stripeRefund } from './providers';
import { mpAccessTokenFor } from './accounts';
import { OPEN_STATUSES, closeOrder, isPaidEvent, markOrderReversed, msOf } from './orders';
import { emitNotification } from '../notifications/notifyHelpers';
import { LText, lt, t, I18nKey } from '../shared/i18n';
import { resolveLocale } from '../shared/i18n/recipientLocale';
import { isGuestKey } from '../shared/guestIdentity';
import { authEmailOf, escapeHtml, sendEmailOnce } from '../emails/sendEmail';
import { emailFrame } from '../emails/emailFormat';

export const REFUNDS = 'ticket_refunds';
export const REFUND_BATCHES = 'ticket_refund_batches';
export const ADMIN_ALERTS = 'admin_alerts';
export const MAX_ATTEMPTS = 6;
export const LEASE_MS = 5 * 60 * 1000;
export const SWEEP_BATCH = 100;
/** Proof of a manual refund: refund_proofs/{orderId}/{file} (storage.rules). */
export const PROOF_PREFIX = 'refund_proofs';

export type RefundReason =
  | 'event_cancelled' | 'event_deleted'
  | 'host_cancelled' | 'slot_cancelled' | 'host_removed_time' | 'experience_deleted'
  | 'late_payment_cancelled_listing';

export type RefundStatus =
  | 'pending' | 'processing' | 'retry'
  | 'refunded' | 'refund_owed' | 'not_needed' | 'refund_failed'
  | 'manual_refund_pending_review' | 'refunded_manually';

/** No further automatic work. */
export const FINAL: ReadonlySet<string> = new Set([
  'refunded', 'refund_owed', 'not_needed', 'refund_failed', 'manual_refund_pending_review', 'refunded_manually',
]);
/** Still costs the buyer money: blocks the seller's account deletion. */
export const UNSETTLED: readonly RefundStatus[] = [
  'pending', 'processing', 'retry', 'refund_failed', 'manual_refund_pending_review',
];

const OPEN = new Set<string>(OPEN_STATUSES);

export interface RefundNotice {
  recipientId: string;
  type: string;
  title: LText;
  body: LText;
  data: Record<string, string>;
}

export interface RefundDeps {
  db(): FirebaseFirestore.Firestore;
  now(): number;
  stripeRefund(accountId: string, paymentIntentId: string, orderId: string): Promise<string>;
  mpRefund(organizerId: string, paymentId: string, orderId: string): Promise<string>;
  closeOpenOrder(orderId: string, reason: string): Promise<boolean>;
  expireStripeSession(accountId: string, sessionId: string): Promise<void>;
  /** Paid order -> refunded: tickets invalid, seats / phases / allowance released (silent). */
  markRefunded(orderId: string, ref: Record<string, unknown>): Promise<boolean>;
  notify(p: RefundNotice): Promise<void>;
  /** One e-mail per (kind, order): 'started' | 'failed' | 'owed'. */
  email(kind: 'started' | 'failed' | 'owed', orderId: string, recipientId: string, title: string): Promise<void>;
}

const TS = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

async function defaultEmail(kind: 'started' | 'failed' | 'owed', orderId: string, recipientId: string, title: string): Promise<void> {
  await sendEmailOnce(`ticket_refund_${kind}_${orderId}`, async () => {
    const to = await authEmailOf(recipientId);
    if (!to) return null;
    const locale = await resolveLocale(recipientId);
    const subjectKey: I18nKey = kind === 'failed' ? 'emailRefundDelayedSubject' : 'emailRefundStartedSubject';
    const bodyKey: I18nKey = kind === 'failed' ? 'srvRefundFailedBody' : (kind === 'owed' ? 'srvRefundOwedBody' : 'srvRefundStartedBody');
    const body = t(locale, bodyKey, { title });
    return {
      to: [to],
      subject: t(locale, subjectKey, { title }),
      html: emailFrame(`<h2 style="margin:0 0 8px">${escapeHtml(title)}</h2><p>${escapeHtml(body)}</p>`),
      text: `${title}\n\n${body}`,
    };
  }, { type: `ticket_refund_${kind}`, orderId });
}

export const refundDeps: RefundDeps = {
  db: () => admin.firestore(),
  now: () => Date.now(),
  stripeRefund: (a, pi, id) => stripeRefund(a, pi, id),
  mpRefund: async (org, pay, id) => mpRefund(await mpAccessTokenFor(org), pay, id),
  closeOpenOrder: (id, reason) => closeOrder(id, 'cancelled', { cancelReason: reason }),
  expireStripeSession: (a, s) => (cfg.stripeConfigured() ? stripeExpireSession(a, s) : Promise.resolve()),
  markRefunded: (id, ref) => markOrderReversed(id, 'refunded', ref, { silent: true }),
  notify: (p) => emitNotification(p),
  email: defaultEmail,
};

/** Backoff: 2 min, 8 min, 32 min, ... capped at 6 h. */
export function retryDelayMs(attempts: number): number {
  return Math.min(2 * 60 * 1000 * Math.pow(4, Math.max(0, attempts - 1)), 6 * 3600 * 1000);
}

/** True when the outbox doc should be (re)processed now. */
export function isDue(d: Record<string, any> | undefined, now: number): boolean {
  if (!d) return false;
  if (d.status === 'pending') return true;
  if (d.status === 'retry') return (msOf(d.nextAttemptAt) ?? 0) <= now;
  if (d.status === 'processing') return (msOf(d.leaseUntil) ?? 0) <= now;
  return false;
}

export type Classified = { kind: 'retry' | 'permanent' | 'already_refunded'; reason: string };

/**
 * Provider error -> what to do. Permanent = retrying cannot help (the seller
 * must act): disconnected / revoked account, no permission, insufficient
 * balance, a dispute, a bad payment reference, MP 4xx. Everything else
 * (network, 5xx, rate limit, lock timeout) is retried with backoff.
 */
export function classifyRefundError(e: any): Classified {
  if (e instanceof ProviderError || e?.name === 'ProviderError') {
    const r = String(e.reason || '');
    if (r === 'mp_not_connected' || r === 'mp_bad_payment_id' || r === 'missing_payment_reference') return { kind: 'permanent', reason: r };
    const m = /^mp_http_(\d{3})$/.exec(r);
    if (m) {
      const s = Number(m[1]);
      if (s === 429 || s >= 500) return { kind: 'retry', reason: r };
      return { kind: 'permanent', reason: r };
    }
    return { kind: 'retry', reason: r || 'provider_error' };
  }
  const code = String(e?.code || e?.raw?.code || '');
  const type = String(e?.type || e?.rawType || '');
  if (code === 'charge_already_refunded') return { kind: 'already_refunded', reason: code };
  const permanentCodes = new Set([
    'account_invalid', 'balance_insufficient', 'insufficient_funds', 'charge_disputed', 'refund_disputed_payment',
    'resource_missing', 'payment_intent_unexpected_state', 'platform_api_key_expired', 'account_closed',
  ]);
  if (permanentCodes.has(code)) return { kind: 'permanent', reason: code };
  if (type === 'StripePermissionError' || type === 'StripeAuthenticationError' || type === 'StripeInvalidRequestError') {
    return { kind: 'permanent', reason: code || type };
  }
  return { kind: 'retry', reason: code || type || String(e?.message || 'error').slice(0, 80) };
}

function isAlreadyExists(e: any): boolean {
  return e?.code === 6 || e?.code === 'already-exists' || /ALREADY_EXISTS|already exists/i.test(String(e?.message || ''));
}

// ─────────────────────────────────────────────────────────── enqueue

export interface EnqueueOpts {
  reason: RefundReason;
  batchId?: string | null;
}

/** Outbox row for a PAID order (pure). */
export function refundDocFor(orderId: string, o: Record<string, any>, opts: EnqueueOpts, now: number): Record<string, unknown> {
  return {
    orderId,
    kind: o.kind ?? null,
    listingId: o.listingId ?? null,
    bookingId: o.bookingId ?? null,
    organizerId: o.organizerId ?? null,
    buyerId: o.buyerId ?? null,
    isGuest: o.isGuest === true || isGuestKey(o.buyerId),
    provider: o.provider ?? null,
    amount: Number(o.totalAmount) || 0,
    currency: o.currency ?? null,
    title: String(o.title || '').slice(0, 200),
    reason: opts.reason,
    batchId: opts.batchId ?? null,
    status: 'pending',
    attempts: 0,
    nextAttemptAt: null,
    leaseUntil: null,
    providerRefundId: null,
    lastError: null,
    failure: null,
    createdAt: TS(now),
    updatedAt: TS(now),
    completedAt: null,
  };
}

/**
 * Refund one order (idempotent: one outbox doc per order, created once).
 * Open orders are closed right here (nothing was paid). Returns what happened.
 */
export async function enqueueOrderRefund(
  orderId: string,
  opts: EnqueueOpts,
  deps: RefundDeps = refundDeps,
): Promise<'enqueued' | 'exists' | 'closed_open' | 'not_paid' | 'not_found'> {
  const db = deps.db();
  const o = (await db.collection(COL.orders).doc(orderId).get()).data();
  if (!o) return 'not_found';
  if (OPEN.has(o.status)) {
    await deps.closeOpenOrder(orderId, opts.reason).catch((e) => console.error(`[refunds] close ${orderId}:`, e?.message));
    if (o.provider === 'stripe' && o.providerRef?.stripeAccountId && o.providerRef?.stripeSessionId) {
      await deps.expireStripeSession(o.providerRef.stripeAccountId, o.providerRef.stripeSessionId).catch(() => undefined);
    }
    // Was it paid in the meantime? Then it needs a refund after all.
    const again = (await db.collection(COL.orders).doc(orderId).get()).data();
    if (again?.status !== 'paid') return 'closed_open';
  } else if (o.status !== 'paid') {
    return 'not_paid';
  }
  const fresh = (await db.collection(COL.orders).doc(orderId).get()).data() || o;
  try {
    await db.collection(REFUNDS).doc(orderId).create(refundDocFor(orderId, fresh, opts, deps.now()));
  } catch (e) {
    if (isAlreadyExists(e)) return 'exists';
    throw e;
  }
  await db.collection(COL.orders).doc(orderId).set({
    refund: { status: 'pending', reason: opts.reason, at: TS(deps.now()) },
    updatedAt: TS(deps.now()),
  }, { merge: true });
  return 'enqueued';
}

/** Event end (endDate, else start + 6 h), or null when unknown. */
export function eventEndMs(ev: Record<string, any> | undefined | null): number | null {
  const end = msOf(ev?.endDate);
  if (end !== null) return end;
  const start = msOf(ev?.startDate);
  return start !== null ? start + 6 * 3600 * 1000 : null;
}

/** Cancelling / deleting an event that already took place never refunds anyone. */
export function eventStillRefundable(ev: Record<string, any> | undefined | null, now: number): boolean {
  if (!ev) return false;
  if (ev.status === 'completed') return false;
  const end = eventEndMs(ev);
  return end === null || end > now;
}

/**
 * The organiser cancelled (or hard-deleted) a paid event: refund every paid
 * order, close every open one. Paged (documentId order) over the
 * single-field `listingId` index; one outbox row per paid order; the batch
 * doc tells the organiser the result once every row is done.
 */
export async function enqueueEventRefunds(
  eventId: string,
  ev: Record<string, any>,
  reason: 'event_cancelled' | 'event_deleted',
  deps: RefundDeps = refundDeps,
): Promise<{ paid: number; enqueued: number; closedOpen: number }> {
  const db = deps.db();
  const batchId = `event_${eventId}`;
  const out = { paid: 0, enqueued: 0, closedOpen: 0 };
  const PAGE = 300;
  let last: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  for (let guard = 0; guard < 200; guard++) {
    let q = db.collection(COL.orders).where('listingId', '==', eventId)
      .orderBy(admin.firestore.FieldPath.documentId()).limit(PAGE);
    if (last) q = q.startAfter(last);
    const page = await q.get();
    for (const d of page.docs) {
      const o = d.data();
      if (o.kind !== 'event') continue;
      if (o.status !== 'paid' && !OPEN.has(o.status)) continue;
      const r = await enqueueOrderRefund(d.id, { reason, batchId }, deps);
      if (r === 'enqueued' || r === 'exists') out.paid++;
      if (r === 'enqueued') out.enqueued++;
      if (r === 'closed_open') out.closedOpen++;
    }
    if (page.size < PAGE) break;
    last = page.docs[page.docs.length - 1];
  }
  const t0 = deps.now();
  await db.collection(REFUND_BATCHES).doc(batchId).set({
    kind: 'event', listingId: eventId, organizerId: ev.organizerId ?? null,
    title: String(ev.title || '').slice(0, 200), reason, total: out.paid, updatedAt: TS(t0),
  }, { merge: true });
  if (out.paid > 0 || out.closedOpen > 0) {
    // Server stamp: the rules then keep the event cancelled (no re-opening
    // an event whose buyers were refunded). Not possible after a hard delete.
    const evRef = db.collection('events').doc(eventId);
    if ((await evRef.get()).exists) await evRef.set({ ticketRefundsAt: TS(t0) }, { merge: true });
  }
  await maybeSendSummary(batchId, deps);
  return out;
}

/** Event trigger decision (pure): what the write means for refunds. */
export function eventRefundAction(
  before: Record<string, any> | undefined,
  after: Record<string, any> | undefined,
  now: number,
): 'event_cancelled' | 'event_deleted' | null {
  if (!before) return null;
  if (!isPaidEvent(before) && !isPaidEvent(after)) return null;
  if (after) {
    if (before.status === 'cancelled' || after.status !== 'cancelled') return null;
    return eventStillRefundable(before, now) ? 'event_cancelled' : null;
  }
  return eventStillRefundable(before, now) ? 'event_deleted' : null;
}

/** Host-initiated booking cancellation decision (pure). */
export function bookingNeedsRefund(before: Record<string, any> | undefined, after: Record<string, any> | undefined): boolean {
  if (!after || after.status !== 'cancelled_by_host') return false;
  if (before?.status === 'cancelled_by_host') return false;
  return after.payment?.mode === 'online' && typeof after.payment?.orderId === 'string' && after.payment.orderId.length > 0;
}

/** Host cancelled a booking (any host path): full refund of its order. */
export async function enqueueBookingRefund(
  bookingId: string,
  b: Record<string, any>,
  reason: RefundReason,
  deps: RefundDeps = refundDeps,
): Promise<string> {
  if (b?.payment?.mode !== 'online' || !b?.payment?.orderId) return 'no_order';
  try {
    return await enqueueOrderRefund(String(b.payment.orderId), { reason }, deps);
  } catch (e) {
    // The bookings trigger (refundOnHostCancelledBooking) and the sweep retry.
    console.error(`[refunds] enqueue booking ${bookingId} failed:`, (e as Error)?.message);
    return 'error';
  }
}

// ─────────────────────────────────────────────────────────── process

async function claim(ref: FirebaseFirestore.DocumentReference, deps: RefundDeps): Promise<Record<string, any> | null> {
  const now = deps.now();
  return deps.db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const d = snap.data();
    if (!snap.exists || !isDue(d, now)) return null;
    tx.update(ref, { status: 'processing', leaseUntil: TS(now + LEASE_MS), updatedAt: TS(now) });
    return d as Record<string, any>;
  });
}

interface Outcome {
  status: RefundStatus | 'retry';
  providerRefundId?: string | null;
  note?: string;
  error?: string;
}

async function attempt(orderId: string, d: Record<string, any>, deps: RefundDeps): Promise<Outcome> {
  const db = deps.db();
  const o = (await db.collection(COL.orders).doc(orderId).get()).data();
  if (!o) return { status: 'not_needed', note: 'order_missing' };
  if (OPEN.has(o.status)) {
    await deps.closeOpenOrder(orderId, String(d.reason));
    const again = (await db.collection(COL.orders).doc(orderId).get()).data();
    if (again?.status !== 'paid') return { status: 'not_needed', note: 'unpaid_order_cancelled' };
    return attempt(orderId, d, deps);
  }
  if (o.status === 'refunded') return { status: 'refunded', providerRefundId: o.refund?.providerRefundId ?? null, note: 'already_refunded' };
  if (o.status === 'disputed') return { status: 'not_needed', note: 'disputed' };
  if (o.status !== 'paid') return { status: 'not_needed', note: `order_${o.status}` };

  let refundId: string | null = null;
  if (o.refund?.status === 'requested' && o.refund?.providerRefundId) {
    refundId = String(o.refund.providerRefundId); // an earlier call already succeeded
  } else if (o.provider === 'stripe') {
    const acct = o.providerRef?.stripeAccountId;
    const pi = o.stripePaymentIntentId || o.providerRef?.stripePaymentIntentId;
    if (!acct || !pi) throw new ProviderError('missing_payment_reference');
    refundId = await deps.stripeRefund(String(acct), String(pi), orderId);
  } else if (o.provider === 'mercadopago') {
    const pay = o.mpPaymentId || o.providerRef?.mpPaymentId;
    if (!pay) throw new ProviderError('missing_payment_reference');
    refundId = await deps.mpRefund(String(o.organizerId), String(pay), orderId);
  } else {
    return { status: 'refund_owed', note: 'paid_outside_greengo' };
  }
  await deps.markRefunded(orderId, { refundEngine: true, providerRefundId: refundId, reason: d.reason });
  return { status: 'refunded', providerRefundId: refundId };
}

/** Processes one outbox doc. Never throws. */
export async function processRefund(orderId: string, deps: RefundDeps = refundDeps): Promise<RefundStatus | 'skipped'> {
  const db = deps.db();
  const ref = db.collection(REFUNDS).doc(orderId);
  let d: Record<string, any> | null;
  try {
    d = await claim(ref, deps);
  } catch (e) {
    console.error(`[refunds] claim ${orderId} failed:`, (e as Error)?.message);
    return 'skipped';
  }
  if (!d) return 'skipped';
  const attempts = Number(d.attempts || 0) + 1;
  let out: Outcome;
  try {
    out = await attempt(orderId, d, deps);
  } catch (e: any) {
    const c = classifyRefundError(e);
    if (c.kind === 'already_refunded') {
      await deps.markRefunded(orderId, { refundEngine: true, reason: d.reason, note: 'already_refunded_at_provider' })
        .catch(() => undefined);
      out = { status: 'refunded', note: 'already_refunded_at_provider' };
    } else if (c.kind === 'permanent' || attempts >= MAX_ATTEMPTS) {
      out = { status: 'refund_failed', error: c.reason };
    } else {
      out = { status: 'retry', error: c.reason };
    }
    console.error(`[refunds] ${orderId} attempt ${attempts}: ${c.kind} ${c.reason}`);
  }
  return finalize(orderId, d, attempts, out, deps);
}

async function finalize(orderId: string, d: Record<string, any>, attempts: number, out: Outcome, deps: RefundDeps): Promise<RefundStatus> {
  const db = deps.db();
  const now = deps.now();
  const ref = db.collection(REFUNDS).doc(orderId);
  const del = admin.firestore.FieldValue.delete();
  if (out.status === 'retry') {
    await ref.update({
      status: 'retry', attempts, lastError: out.error ?? null, leaseUntil: null,
      nextAttemptAt: TS(now + retryDelayMs(attempts)), updatedAt: TS(now),
    });
    return 'retry';
  }
  const status = out.status as RefundStatus;
  await ref.update({
    status, attempts, leaseUntil: null, nextAttemptAt: null, updatedAt: TS(now), completedAt: TS(now),
    providerRefundId: out.providerRefundId ?? null, note: out.note ?? del,
    lastError: out.error ?? null, failure: status === 'refund_failed' ? (out.error ?? 'unknown') : null,
  });
  const orderRefund: Record<string, unknown> = {
    status: status === 'refunded' ? 'requested' : status,
    reason: d.reason, at: TS(now),
    ...(out.providerRefundId ? { providerRefundId: out.providerRefundId } : {}),
    ...(out.error ? { error: out.error } : {}),
  };
  if (status !== 'not_needed') {
    await db.collection(COL.orders).doc(orderId).set({ refund: orderRefund, updatedAt: TS(now) }, { merge: true })
      .catch((e) => console.error(`[refunds] order mirror ${orderId}:`, e?.message));
  }
  if (status === 'refund_failed') {
    await db.collection(ADMIN_ALERTS).doc(`ticket_refund_failed_${orderId}`).set({
      type: 'ticket_refund_failed', orderId, kind: d.kind ?? null, listingId: d.listingId ?? null,
      bookingId: d.bookingId ?? null, organizerId: d.organizerId ?? null, buyerId: d.buyerId ?? null,
      isGuest: d.isGuest === true, provider: d.provider ?? null, amount: d.amount ?? null, currency: d.currency ?? null,
      reason: d.reason ?? null, error: out.error ?? null, attempts, status: 'open', createdAt: TS(now),
    }, { merge: true }).catch((e) => console.error('[refunds] admin alert failed', e?.message));
  }
  await notifyOutcome(orderId, d, status, deps);
  if (d.batchId) await countInBatch(String(d.batchId), status, deps);
  return status;
}

async function safe(p: Promise<unknown>, what: string): Promise<void> {
  try { await p; } catch (e) { console.error(`[refunds] ${what} failed:`, (e as Error)?.message); }
}

async function notifyOutcome(orderId: string, d: Record<string, any>, status: RefundStatus, deps: RefundDeps): Promise<void> {
  const title = String(d.title || '');
  const buyer = String(d.buyerId || '');
  const org = String(d.organizerId || '');
  const data = { action: 'ticket', orderId, kind: String(d.kind || ''), listingId: String(d.listingId || '') };
  const guest = d.isGuest === true || isGuestKey(buyer);
  if (status === 'refunded') {
    if (!guest) {
      await safe(deps.notify({ recipientId: buyer, type: 'ticket_refund_started', title: lt('srvRefundStartedTitle'), body: lt('srvRefundStartedBody', { title }), data }), 'notify buyer');
      // Guests get the existing "refunded" e-mail from the order trigger (guestEmails.ts).
      await safe(deps.email('started', orderId, buyer, title), 'email buyer');
    }
  } else if (status === 'refund_owed') {
    await safe(deps.notify({ recipientId: buyer, type: 'ticket_refund_owed', title: lt('srvRefundStartedTitle'), body: lt('srvRefundOwedBody', { title }), data }), 'notify buyer');
    await safe(deps.email('owed', orderId, buyer, title), 'email buyer');
    await safe(deps.notify({ recipientId: org, type: 'ticket_refund_owed', title: lt('notifServerRefundToPayBack'), body: lt('srvRefundOwedOrganizerBody', { title }), data: { action: 'ticket_confirm', orderId } }), 'notify organizer');
  } else if (status === 'refund_failed') {
    await safe(deps.notify({ recipientId: buyer, type: 'ticket_refund_failed', title: lt('srvRefundFailedTitle'), body: lt('srvRefundFailedBody', { title }), data }), 'notify buyer');
    await safe(deps.email('failed', orderId, buyer, title), 'email buyer');
    await safe(deps.notify({ recipientId: org, type: 'ticket_refund_failed_seller', title: lt('srvRefundFailedSellerTitle'), body: lt('srvRefundFailedSellerBody', { title }), data: { action: 'refund_action', orderId } }), 'notify organizer');
  }
}

async function countInBatch(batchId: string, status: RefundStatus, deps: RefundDeps): Promise<void> {
  const db = deps.db();
  const field = status === 'refunded' ? 'refunded' : (status === 'refund_failed' ? 'failed' : (status === 'refund_owed' ? 'owed' : 'other'));
  await db.runTransaction(async (tx) => {
    const ref = db.collection(REFUND_BATCHES).doc(batchId);
    const s = await tx.get(ref);
    const b = s.data() || {};
    tx.set(ref, { [field]: (Number(b[field]) || 0) + 1, processed: (Number(b.processed) || 0) + 1, updatedAt: TS(deps.now()) }, { merge: true });
  });
  await maybeSendSummary(batchId, deps);
}

/** Once every row of a batch is done: one summary push to the organiser. */
export async function maybeSendSummary(batchId: string, deps: RefundDeps = refundDeps): Promise<boolean> {
  const db = deps.db();
  const ref = db.collection(REFUND_BATCHES).doc(batchId);
  const b = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const x = s.data();
    if (!x || typeof x.total !== 'number' || x.total <= 0 || x.summarySentAt) return null;
    if ((Number(x.processed) || 0) < x.total) return null;
    tx.update(ref, { summarySentAt: TS(deps.now()) });
    return x;
  });
  if (!b || !b.organizerId) return false;
  await safe(deps.notify({
    recipientId: String(b.organizerId), type: 'ticket_refund_summary', title: lt('srvRefundSummaryTitle'),
    body: lt('srvRefundSummaryBody', {
      title: String(b.title || ''), refunded: Number(b.refunded) || 0,
      failed: (Number(b.failed) || 0) + (Number(b.owed) || 0),
    }),
    data: { action: 'event', eventId: String(b.listingId || ''), listingId: String(b.listingId || '') },
  }), 'summary');
  return true;
}

/** Scheduler body: pending rows the trigger missed, due retries, stale leases. */
export async function sweepDueRefunds(deps: RefundDeps = refundDeps): Promise<number> {
  const now = deps.now();
  let n = 0;
  for (const status of ['pending', 'retry', 'processing'] as const) {
    const snap = await deps.db().collection(REFUNDS).where('status', '==', status).limit(SWEEP_BATCH).get();
    for (const doc of snap.docs) {
      if (!isDue(doc.data(), now)) continue;
      // A fresh 'pending' row is the trigger's job; take it only after a minute.
      if (status === 'pending' && (msOf(doc.data().createdAt) ?? 0) > now - 60 * 1000) continue;
      await processRefund(doc.id, deps);
      n++;
    }
  }
  return n;
}

/**
 * A payment that arrives AFTER the listing was cancelled (the buyer was still
 * on the checkout page): refund it at once. Called by markOrderPaid.
 */
export async function refundIfListingCancelled(orderId: string, o: Record<string, any>, deps: RefundDeps = refundDeps): Promise<string> {
  const db = deps.db();
  let cancelled = false;
  if (o.kind === 'event') {
    const ev = (await db.collection('events').doc(String(o.listingId)).get()).data();
    cancelled = !ev || ev.status === 'cancelled';
  } else if (o.bookingId) {
    const b = (await db.collection('bookings').doc(String(o.bookingId)).get()).data();
    cancelled = b?.status === 'cancelled_by_host';
  }
  if (!cancelled) return 'listing_active';
  const existing = (await db.collection(REFUNDS).doc(orderId).get()).data();
  if (existing) {
    // Closed while unpaid (not_needed) and now paid: refund after all.
    if (existing.status === 'not_needed') {
      await db.collection(REFUNDS).doc(orderId).update({ status: 'pending', note: 'late_payment', updatedAt: TS(deps.now()) });
      return 'requeued';
    }
    return 'exists';
  }
  return enqueueOrderRefund(orderId, { reason: 'late_payment_cancelled_listing' }, deps);
}

// ─────────────────────────────────────────────────────────── manual refund proof

const PROOF_RE = /^refund_proofs\/[A-Za-z0-9_-]{1,128}\/[A-Za-z0-9._-]{1,100}$/;

function fail(code: 'invalid-argument' | 'not-found' | 'permission-denied' | 'failed-precondition', reason: string): never {
  throw new HttpsError(code, reason, { code: reason });
}

/**
 * Seller: "I refunded this buyer myself" + the proof uploaded to
 * refund_proofs/{orderId}/{file} (storage.rules: the seller only, once,
 * image / PDF <= 10 MB; seller + staff read). refund_failed ->
 * manual_refund_pending_review. data { orderId, proofPath, note? }.
 */
export async function submitManualRefundProof(uid: string, data: any, deps: RefundDeps = refundDeps): Promise<Record<string, unknown>> {
  const orderId = typeof data?.orderId === 'string' ? data.orderId : '';
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(orderId)) fail('invalid-argument', 'invalid_order_id');
  const proofPath = typeof data?.proofPath === 'string' ? data.proofPath : '';
  if (!PROOF_RE.test(proofPath) || !proofPath.startsWith(`${PROOF_PREFIX}/${orderId}/`)) fail('invalid-argument', 'invalid_proof_path');
  const note = typeof data?.note === 'string' ? data.note.trim().slice(0, 500) : '';
  const db = deps.db();
  const ref = db.collection(REFUNDS).doc(orderId);
  const now = deps.now();
  await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const d = s.data();
    if (!d) fail('not-found', 'refund_not_found');
    if (d.organizerId !== uid) fail('permission-denied', 'not_seller');
    if (d.status === 'manual_refund_pending_review') return;
    if (d.status !== 'refund_failed') fail('failed-precondition', 'refund_not_failed');
    tx.update(ref, {
      status: 'manual_refund_pending_review',
      proof: { path: proofPath, note: note || null, uploadedBy: uid, uploadedAt: TS(now) },
      updatedAt: TS(now),
    });
  });
  await db.collection(COL.orders).doc(orderId).set({
    refund: { status: 'manual_refund_pending_review', at: TS(now) }, updatedAt: TS(now),
  }, { merge: true });
  await db.collection(ADMIN_ALERTS).doc(`ticket_refund_failed_${orderId}`).set({
    status: 'proof_submitted', proofPath, proofSubmittedAt: TS(now),
  }, { merge: true }).catch(() => undefined);
  return { orderId, status: 'manual_refund_pending_review' };
}

/**
 * Admin: approve / reject a seller's manual-refund proof.
 * data { orderId, approve: boolean, reason? (required to reject) }.
 * Approve -> refunded_manually (counts as refunded: the order becomes
 * 'refunded', tickets invalid, seats released); reject -> refund_failed with
 * the reason. The seller is notified either way.
 */
export async function reviewManualRefund(adminUid: string, data: any, deps: RefundDeps = refundDeps): Promise<Record<string, unknown>> {
  const orderId = typeof data?.orderId === 'string' ? data.orderId : '';
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(orderId)) fail('invalid-argument', 'invalid_order_id');
  if (typeof data?.approve !== 'boolean') fail('invalid-argument', 'invalid_decision');
  const approve = data.approve === true;
  const reason = typeof data?.reason === 'string' ? data.reason.trim().slice(0, 500) : '';
  if (!approve && !reason) fail('invalid-argument', 'reason_required');
  const db = deps.db();
  const ref = db.collection(REFUNDS).doc(orderId);
  const now = deps.now();
  const d = await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    const x = s.data();
    if (!x) fail('not-found', 'refund_not_found');
    if (x.status !== 'manual_refund_pending_review') fail('failed-precondition', 'not_pending_review');
    tx.update(ref, {
      status: approve ? 'refunded_manually' : 'refund_failed',
      review: { by: adminUid, at: TS(now), approved: approve, reason: reason || null },
      updatedAt: TS(now),
      ...(approve ? { completedAt: TS(now) } : {}),
    });
    return x;
  });
  if (approve) {
    await deps.markRefunded(orderId, { manualRefund: true, reviewedBy: adminUid, proofPath: d.proof?.path ?? null });
  }
  await db.collection(COL.orders).doc(orderId).set({
    refund: { status: approve ? 'refunded_manually' : 'refund_failed', at: TS(now), ...(approve ? {} : { reviewReason: reason }) },
    updatedAt: TS(now),
  }, { merge: true });
  await db.collection(ADMIN_ALERTS).doc(`ticket_refund_failed_${orderId}`).set({
    status: approve ? 'resolved' : 'open', reviewedBy: adminUid, reviewedAt: TS(now),
  }, { merge: true }).catch(() => undefined);
  const title = String(d.title || '');
  await safe(deps.notify({
    recipientId: String(d.organizerId || ''),
    type: approve ? 'ticket_manual_refund_approved' : 'ticket_manual_refund_rejected',
    title: approve ? lt('srvManualRefundApprovedTitle') : lt('srvManualRefundRejectedTitle'),
    body: approve ? lt('srvManualRefundApprovedBody', { title }) : lt('srvManualRefundRejectedBody', { title, reason }),
    data: { action: 'refund_action', orderId },
  }), 'notify seller');
  if (approve && d.isGuest !== true) {
    await safe(deps.notify({
      recipientId: String(d.buyerId || ''), type: 'ticket_refund_started', title: lt('srvRefundStartedTitle'),
      body: lt('srvRefundManualBuyerBody', { title }), data: { action: 'ticket', orderId },
    }), 'notify buyer');
  }
  return { orderId, status: approve ? 'refunded_manually' : 'refund_failed' };
}
