/**
 * Ticket payments — Cloud Function bindings (512MiB everywhere: the bundle
 * needs ~200MB RSS just to load). Logic lives in ./accounts, ./orders,
 * ./webhooks. Deploy BY NAME (see docs/payments/ticket-payments.md).
 *
 * STRIPE_SECRET_KEY is the existing Secret Manager secret (also used by the
 * web repo's coin checkout); everything else comes from functions/.env.
 */
import { onCall, onRequest, HttpsError, CallableRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { defineSecret } from 'firebase-functions/params';
import * as accounts from './accounts';
import * as orders from './orders';
import { assertPhoneVerified } from '../shared/participation';
import { handleMercadoPagoWebhook, handleStripeConnectWebhook } from './webhooks';
import * as refunds from './refunds';
import { requireAdmin, SUPER_ADMIN_ONLY } from '../shared/adminAuth';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const CALL = { memory: '512MiB' as const, timeoutSeconds: 60 };
const CALL_STRIPE = { ...CALL, secrets: [STRIPE_SECRET_KEY] };

type Impl = (uid: string, data: any, email: string | null) => Promise<Record<string, unknown>>;

function callable(
  opts: typeof CALL | typeof CALL_STRIPE,
  impl: Impl,
  requirePhone?: (data: any) => boolean,
) {
  return onCall(opts, async (req: CallableRequest<any>) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { code: 'unauthenticated' });
    // Owner rule 2026-10-17: buying tickets needs a verified phone.
    if (requirePhone && requirePhone(req.data ?? {})) await assertPhoneVerified(req.auth?.token as any, uid);
    const email = typeof req.auth?.token?.email === 'string' ? req.auth.token.email : null;
    try {
      return await impl(uid, req.data ?? {}, email);
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error('[tickets] callable failed:', (e as Error)?.message);
      throw new HttpsError('internal', 'tickets_internal_error', { code: 'internal' });
    }
  });
}

// Organizer onboarding ("Get paid").
export const getTicketPaymentsConfig = callable(CALL_STRIPE, (uid, data) => accounts.getTicketPaymentsConfig(uid, data));
export const startStripeOnboarding = callable(CALL_STRIPE, (uid, data, email) => accounts.startStripeOnboarding(uid, data, email));
export const startMercadoPagoOnboarding = callable(CALL, (uid, data) => accounts.startMercadoPagoOnboarding(uid, data));
export const refreshPaymentAccount = callable(CALL_STRIPE, (uid) => accounts.refreshPaymentAccount(uid));

// Buyer.
// Phone gate (2026-10-17) for event tickets only: kind 'experience' pays an
// EXISTING booking (the booking was the participation). Guests (no account)
// reach orders.createTicketCheckout through guestBooking, never this wrapper.
export const createTicketCheckout = callable(
  CALL_STRIPE,
  (uid, data, email) => orders.createTicketCheckout(uid, data, email),
  (data) => data?.kind !== 'experience',
);
export const syncTicketOrder = callable(CALL_STRIPE, (uid, data) => orders.syncTicketOrder(uid, data));
export const cancelTicketOrder = callable(CALL_STRIPE, (uid, data) => orders.cancelTicketOrder(uid, data));
// LEGACY link orders still open (no new link orders since 2026-10-14).
export const markTicketPaymentSent = callable(CALL, (uid, data) => orders.markTicketPaymentSent(uid, data));

// Organizer, LEGACY link orders still open (see config.ts for the cleanup).
export const confirmTicketPayment = callable(CALL, (uid, data) => orders.confirmTicketPayment(uid, data));
export const rejectTicketPayment = callable(CALL, (uid, data) => orders.rejectTicketPayment(uid, data));

// Provider callbacks.
export const stripeConnectWebhook = onRequest({ memory: '512MiB', timeoutSeconds: 60 }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).send('method'); return; }
  try {
    const r = await handleStripeConnectWebhook(req.rawBody, req.get('stripe-signature'));
    res.status(r.status).send(r.body);
  } catch (e) {
    console.error('[tickets] stripe webhook failed:', (e as Error)?.message);
    res.status(500).send('error'); // Stripe retries
  }
});

export const mercadoPagoWebhook = onRequest({ memory: '512MiB', timeoutSeconds: 60 }, async (req, res) => {
  if (req.method !== 'POST') { res.status(405).send('method'); return; }
  try {
    const r = await handleMercadoPagoWebhook(req.query as any, req.body, req.headers as any);
    res.status(r.status).send(r.body);
  } catch (e) {
    console.error('[tickets] MP webhook failed:', (e as Error)?.message);
    res.status(500).send('error'); // MP retries
  }
});

export const mpOAuthCallback = onRequest({ memory: '512MiB', timeoutSeconds: 60 }, async (req, res) => {
  const r = await accounts.handleMpOAuthCallback(req.query as any);
  if (r.redirect) { res.redirect(302, r.redirect); return; }
  res.status(r.status).set('Content-Type', 'text/html; charset=utf-8').send(r.html);
});

export const ticketCheckoutReturn = onRequest({ memory: '512MiB', timeoutSeconds: 30 }, async (req, res) => {
  const r = accounts.returnPage(req.query as any);
  if (r.redirect) { res.redirect(302, r.redirect); return; }
  res.status(r.status).set('Content-Type', 'text/html; charset=utf-8').send(r.html);
});

// Schedules.
export const expireTicketOrders = onSchedule(
  { schedule: 'every 5 minutes', memory: '512MiB', timeoutSeconds: 300, secrets: [STRIPE_SECRET_KEY] },
  async () => { await orders.expireDueOrders(); },
);
export const remindTicketConfirmations = onSchedule(
  { schedule: 'every 60 minutes', memory: '512MiB', timeoutSeconds: 300 },
  async () => { await orders.remindDueConfirmations(); },
);
export const refreshMercadoPagoTokens = onSchedule(
  { schedule: 'every 24 hours', memory: '512MiB', timeoutSeconds: 300 },
  async () => { await accounts.refreshDueMpTokens(); },
);

// ─────────────────────────────────────────────────────────── seller-cancelled refunds (refunds.ts)

/**
 * Organiser cancelled (status -> 'cancelled') or hard-deleted a PAID event that
 * has not ended: enqueue a full refund of every paid order and close the open
 * ones. Early exit for every other write (free events, viewCount bumps...):
 * one cheap invocation, no reads. Enqueue only (no provider call here).
 */
export const refundTicketsOnEventCancelled = onDocumentWritten(
  { document: 'events/{eventId}', memory: '512MiB', timeoutSeconds: 540, secrets: [STRIPE_SECRET_KEY] },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    const action = refunds.eventRefundAction(before, after, Date.now());
    if (!action) return;
    const r = await refunds.enqueueEventRefunds(event.params.eventId, (after ?? before)!, action);
    console.log(`[refunds] event ${event.params.eventId} ${action}: ${r.paid} paid order(s), ${r.closedOpen} open closed`);
  },
);

/** Backstop for every host-initiated booking cancellation (idempotent enqueue). */
export const refundOnHostCancelledBooking = onDocumentUpdated(
  { document: 'bookings/{bookingId}', memory: '512MiB', timeoutSeconds: 60, secrets: [STRIPE_SECRET_KEY] },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!refunds.bookingNeedsRefund(before, after)) return;
    const reason = String(after?.cancellation?.reason || '');
    await refunds.enqueueBookingRefund(event.params.bookingId, after!,
      reason === 'host_removed_time' || reason === 'experience_deleted' ? reason : 'host_cancelled');
  },
);

/** One outbox row -> one provider refund. Bounded concurrency (Stripe / MP rate limits). */
export const processTicketRefund = onDocumentCreated(
  { document: `${refunds.REFUNDS}/{orderId}`, memory: '512MiB', timeoutSeconds: 120, maxInstances: 10, secrets: [STRIPE_SECRET_KEY] },
  async (event) => { await refunds.processRefund(event.params.orderId); },
);

/** Retries with backoff, stale leases, rows the trigger missed. */
export const sweepTicketRefunds = onSchedule(
  { schedule: 'every 10 minutes', memory: '512MiB', timeoutSeconds: 540, secrets: [STRIPE_SECRET_KEY] },
  async () => {
    const n = await refunds.sweepDueRefunds();
    if (n) console.log(`[refunds] sweep processed ${n} row(s)`);
  },
);

/** Seller: proof of a manual refund for a refund_failed order. */
export const submitManualRefundProof = callable(CALL, (uid, data) => refunds.submitManualRefundProof(uid, data));

/**
 * Admin: approve / reject a manual-refund proof (docs/payments/refunds.md).
 * superAdmin only (a money decision), with the fresh admin 2FA that
 * shared/adminAuth requires for superAdmin-only actions when enforced.
 */
export const adminReviewManualRefund = onCall(CALL, async (req: CallableRequest<any>) => {
  const who = await requireAdmin(req.auth as any, SUPER_ADMIN_ONLY);
  try {
    return await refunds.reviewManualRefund(who.uid, req.data ?? {});
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error('[refunds] review failed:', (e as Error)?.message);
    throw new HttpsError('internal', 'tickets_internal_error', { code: 'internal' });
  }
});
