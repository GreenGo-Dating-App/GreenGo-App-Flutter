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
import { defineSecret } from 'firebase-functions/params';
import * as accounts from './accounts';
import * as orders from './orders';
import { handleMercadoPagoWebhook, handleStripeConnectWebhook } from './webhooks';

const STRIPE_SECRET_KEY = defineSecret('STRIPE_SECRET_KEY');
const CALL = { memory: '512MiB' as const, timeoutSeconds: 60 };
const CALL_STRIPE = { ...CALL, secrets: [STRIPE_SECRET_KEY] };

type Impl = (uid: string, data: any, email: string | null) => Promise<Record<string, unknown>>;

function callable(opts: typeof CALL | typeof CALL_STRIPE, impl: Impl) {
  return onCall(opts, async (req: CallableRequest<any>) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'unauthenticated', { code: 'unauthenticated' });
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
export const getTicketPaymentsConfig = callable(CALL_STRIPE, () => accounts.getTicketPaymentsConfig());
export const startStripeOnboarding = callable(CALL_STRIPE, (uid, data, email) => accounts.startStripeOnboarding(uid, data, email));
export const startMercadoPagoOnboarding = callable(CALL, (uid, data) => accounts.startMercadoPagoOnboarding(uid, data));
export const refreshPaymentAccount = callable(CALL_STRIPE, (uid) => accounts.refreshPaymentAccount(uid));

// Buyer.
export const createTicketCheckout = callable(CALL_STRIPE, (uid, data, email) => orders.createTicketCheckout(uid, data, email));
export const syncTicketOrder = callable(CALL_STRIPE, (uid, data) => orders.syncTicketOrder(uid, data));
export const cancelTicketOrder = callable(CALL_STRIPE, (uid, data) => orders.cancelTicketOrder(uid, data));
export const markTicketPaymentSent = callable(CALL, (uid, data) => orders.markTicketPaymentSent(uid, data));

// Organizer, link mode.
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
