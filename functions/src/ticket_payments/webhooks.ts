/**
 * Ticket payments — provider webhooks (pure handlers; bound in ./index.ts).
 *
 * stripeConnectWebhook  NEW endpoint, "Events on Connected accounts", own secret
 *   (STRIPE_CONNECT_WEBHOOK_SECRET). Never the coin endpoint.
 * mercadoPagoWebhook    x-signature HMAC (MP_WEBHOOK_SECRET) + the payment is
 *   ALWAYS re-fetched from the MP API with the organizer's token; the
 *   notification body is never trusted for status / amount / reference.
 *
 * Idempotency: payment_events/{provider}_{eventKey} is written after a
 * successful run; a redelivery of a recorded event is acknowledged without
 * work. Every state change below is idempotent on its own as well.
 */
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import '../shared/firebaseAdmin';
import * as cfg from './config';
import { COL } from './config';
import { mpAccessTokenFor, writeStripeState } from './accounts';
import { closeOrder, markOrderPaid, markOrderReversed } from './orders';
import { STRIPE_API_VERSION, mpGetPayment, stripeAccountState, ticketDeps, toMinor } from './providers';
import { verifyMpSignature } from './tokens';

const db = () => admin.firestore();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

/** Signature verification only (no API calls are made with this key). */
const verifier = new Stripe('sk_verify_only', { apiVersion: STRIPE_API_VERSION });
export function stripeVerifier(): Stripe { return verifier; }

export interface HookResult { status: number; body: string }

async function seen(key: string): Promise<boolean> {
  return (await db().collection(COL.events).doc(key).get()).exists;
}
async function record(key: string, extra: Record<string, unknown>): Promise<void> {
  await db().collection(COL.events).doc(key).set({ ...extra, processedAt: ts(ticketDeps.now()) });
}

async function orderByPaymentIntent(pi: string | null, account: string | null): Promise<string | null> {
  if (!pi) return null;
  const q = await db().collection(COL.orders).where('stripePaymentIntentId', '==', pi).limit(1).get();
  const d = q.docs[0];
  if (!d) return null;
  if (account && d.data().providerRef?.stripeAccountId !== account) return null;
  return d.id;
}

async function ticketOrderFor(session: Stripe.Checkout.Session, account: string | null): Promise<Record<string, any> | null> {
  if (session.metadata?.greengo !== 'ticket') return null;
  const orderId = session.metadata?.orderId;
  if (!orderId) return null;
  const o = (await db().collection(COL.orders).doc(orderId).get()).data();
  if (!o || o.provider !== 'stripe') return null;
  // The session must live on the organizer account this order was created on.
  if (!account || o.providerRef?.stripeAccountId !== account) return null;
  if (o.providerRef?.stripeSessionId && o.providerRef.stripeSessionId !== session.id) return null;
  return { id: orderId, ...o };
}

export async function handleStripeConnectWebhook(rawBody: Buffer | string | undefined, signature: unknown): Promise<HookResult> {
  const secrets = cfg.stripeConnectWebhookSecrets();
  if (!secrets.length) return { status: 503, body: 'not configured' };
  if (!rawBody || typeof signature !== 'string') return { status: 400, body: 'missing signature' };
  let event: Stripe.Event | null = null;
  for (const s of secrets) {
    try { event = verifier.webhooks.constructEvent(rawBody, signature, s); break; } catch { /* next */ }
  }
  if (!event) return { status: 400, body: 'bad signature' };
  const key = `stripe_${event.id}`;
  if (await seen(key)) return { status: 200, body: 'duplicate' };
  const account = (event as any).account ?? null;
  const obj: any = event.data.object;

  switch (event.type) {
    case 'account.updated': {
      const uid = obj?.metadata?.greengoUid;
      if (typeof uid === 'string' && uid) {
        const cur = (await db().collection(COL.accounts).doc(uid).get()).data();
        if (cur?.stripe?.accountId === obj.id) await writeStripeState(uid, stripeAccountState(obj));
      }
      break;
    }
    case 'checkout.session.completed':
    case 'checkout.session.async_payment_succeeded': {
      const o = await ticketOrderFor(obj, account);
      if (o && obj.payment_status === 'paid') {
        const r = await markOrderPaid(o.id, {
          provider: 'stripe',
          amount: Number(obj.amount_total),
          currency: String(obj.currency || '').toLowerCase(),
          ref: { stripePaymentIntentId: typeof obj.payment_intent === 'string' ? obj.payment_intent : obj.payment_intent?.id ?? null },
          source: 'webhook',
        });
        if (r === 'mismatch') { await record(key, { type: event.type, result: 'mismatch' }); return { status: 200, body: 'mismatch' }; }
      }
      break;
    }
    case 'checkout.session.async_payment_failed': {
      const o = await ticketOrderFor(obj, account);
      if (o) await closeOrder(o.id, 'failed', { failReason: 'async_payment_failed' });
      break;
    }
    case 'checkout.session.expired': {
      const o = await ticketOrderFor(obj, account);
      if (o) await closeOrder(o.id, 'expired');
      break;
    }
    case 'charge.refunded': {
      const orderId = await orderByPaymentIntent(typeof obj.payment_intent === 'string' ? obj.payment_intent : null, account);
      if (orderId) {
        if (obj.refunded === true || Number(obj.amount_refunded) >= Number(obj.amount)) {
          await markOrderReversed(orderId, 'refunded', { stripeChargeId: obj.id });
        } else {
          await db().collection(COL.orders).doc(orderId).set({ partialRefundAmount: Number(obj.amount_refunded) || 0, updatedAt: ts(ticketDeps.now()) }, { merge: true });
        }
      }
      break;
    }
    case 'charge.dispute.created': {
      const orderId = await orderByPaymentIntent(typeof obj.payment_intent === 'string' ? obj.payment_intent : null, account);
      if (orderId) await markOrderReversed(orderId, 'disputed', { stripeDisputeId: obj.id });
      break;
    }
    default:
      break;
  }
  await record(key, { type: event.type, account });
  return { status: 200, body: 'ok' };
}

/**
 * MP notification: query `?o={orderId}&data.id={paymentId}&type=payment`
 * (`o` is our own notification_url parameter; it only selects whose token to
 * use: the payment's external_reference must equal it).
 */
export async function handleMercadoPagoWebhook(
  query: Record<string, any>,
  body: any,
  headers: Record<string, any>,
): Promise<HookResult> {
  const secret = cfg.mpWebhookSecret();
  if (!secret || !cfg.mercadoPagoConfigured()) return { status: 503, body: 'not configured' };
  const dataId = query['data.id'] ?? query.id ?? body?.data?.id;
  if (!verifyMpSignature(secret, headers['x-signature'], headers['x-request-id'], dataId)) {
    return { status: 401, body: 'bad signature' };
  }
  const type = String(query.type ?? query.topic ?? body?.type ?? '');
  if (type !== 'payment') return { status: 200, body: 'ignored' };
  const paymentId = String(dataId ?? '');
  const orderId = String(query.o ?? '');
  if (!/^[0-9]{1,30}$/.test(paymentId) || !/^[A-Za-z0-9_-]{1,128}$/.test(orderId)) return { status: 200, body: 'ignored' };
  const o = (await db().collection(COL.orders).doc(orderId).get()).data();
  if (!o || o.provider !== 'mercadopago') return { status: 200, body: 'unknown order' };

  const token = await mpAccessTokenFor(o.organizerId);
  const p = await mpGetPayment(token, paymentId);
  if (p.externalReference !== orderId) {
    console.error(`[tickets] MP payment ${paymentId} external_reference mismatch for ${orderId}`);
    return { status: 200, body: 'reference mismatch' };
  }
  const key = `mp_${paymentId}_${p.status}`;
  if (await seen(key)) return { status: 200, body: 'duplicate' };

  let result = 'ok';
  if (p.status === 'approved') {
    const r = await markOrderPaid(orderId, {
      provider: 'mercadopago',
      amount: toMinor(p.amount, p.currency || String(o.currency)),
      currency: p.currency,
      ref: { mpPaymentId: p.id },
      source: 'webhook',
    });
    result = r;
  } else if (p.status === 'refunded' || p.status === 'charged_back') {
    const full = p.status === 'charged_back' || p.refundedAmount >= p.amount;
    if (full) await markOrderReversed(orderId, p.status === 'charged_back' ? 'disputed' : 'refunded', { mpPaymentId: p.id });
  } else if (p.status === 'in_mediation') {
    await markOrderReversed(orderId, 'disputed', { mpPaymentId: p.id });
  }
  // rejected / cancelled / pending / in_process: the buyer may still pay until the hold ends.
  await record(key, { orderId, status: p.status, result });
  return { status: 200, body: result };
}
