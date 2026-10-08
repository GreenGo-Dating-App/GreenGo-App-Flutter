/**
 * Ticket payments — provider adapters (Stripe Connect Standard + Mercado Pago
 * REST). Everything that talks to a provider goes through `ticketDeps`, so the
 * emulator tests replace the network with fakes.
 *
 * NO PLATFORM FEE: Stripe sessions are direct charges on the organizer's
 * account WITHOUT application_fee_amount; MP preferences are created with the
 * organizer's own token WITHOUT marketplace_fee.
 */
import Stripe from 'stripe';
import * as cfg from './config';

export const STRIPE_API_VERSION = '2023-10-16' as const;

let cachedStripe: Stripe | null = null;
function realStripe(): Stripe {
  if (!cachedStripe) cachedStripe = new Stripe(cfg.stripeSecretKey(), { apiVersion: STRIPE_API_VERSION });
  return cachedStripe;
}

/** Overridable in tests. */
export const ticketDeps = {
  stripe: (): Stripe => realStripe(),
  fetch: (url: string, init?: RequestInit): Promise<Response> => fetch(url, init),
  now: (): number => Date.now(),
};

export class ProviderError extends Error {
  constructor(public readonly reason: string, message?: string) {
    super(message || reason);
  }
}

// Money helpers live in ./currency (pure, unit-tested).
export { exponentOf, toMinor, toMajor } from './currency';

// ─────────────────────────────────────────────────────────── Stripe

export interface StripeAccountState {
  accountId: string;
  chargesEnabled: boolean;
  detailsSubmitted: boolean;
  payoutsEnabled: boolean;
  country: string | null;
  defaultCurrency: string | null;
}

export function stripeAccountState(a: Stripe.Account): StripeAccountState {
  return {
    accountId: a.id,
    chargesEnabled: a.charges_enabled === true,
    detailsSubmitted: a.details_submitted === true,
    payoutsEnabled: a.payouts_enabled === true,
    country: a.country ?? null,
    defaultCurrency: a.default_currency ?? null,
  };
}

export async function stripeCreateStandardAccount(uid: string, email: string | null): Promise<Stripe.Account> {
  return ticketDeps.stripe().accounts.create({
    type: 'standard',
    ...(email ? { email } : {}),
    metadata: { greengoUid: uid, purpose: 'greengo_tickets' },
  }, { idempotencyKey: `gg_acct_${uid}` });
}

export async function stripeAccountLink(accountId: string, refreshUrl: string, returnUrl: string): Promise<string> {
  const link = await ticketDeps.stripe().accountLinks.create({
    account: accountId,
    type: 'account_onboarding',
    refresh_url: refreshUrl,
    return_url: returnUrl,
  });
  return link.url;
}

export async function stripeRetrieveAccount(accountId: string): Promise<Stripe.Account> {
  return ticketDeps.stripe().accounts.retrieve(accountId);
}

export type { CheckoutInput } from './checkoutPayload';
import { CheckoutInput, mpPreferenceBody, stripeSessionParams } from './checkoutPayload';

/** Direct charge on the connected account. Cards + Apple Pay / Google Pay (wallets ride on `card`). */
export async function stripeCreateCheckout(accountId: string, i: CheckoutInput): Promise<{ id: string; url: string }> {
  const types = i.paymentMethodTypes && i.paymentMethodTypes.length ? i.paymentMethodTypes : ['card'];
  try {
    return await stripeSession(accountId, i, types);
  } catch (e) {
    // Pix not activated on this connected account: cards + wallets only.
    if (types.includes('pix')) return stripeSession(accountId, { ...i, orderId: i.orderId }, ['card'], '_card');
    throw e;
  }
}

async function stripeSession(accountId: string, i: CheckoutInput, types: string[], keySuffix = ''): Promise<{ id: string; url: string }> {
  const s = await ticketDeps.stripe().checkout.sessions.create(stripeSessionParams(i, types) as any,
 { stripeAccount: accountId, idempotencyKey: `gg_tco_${i.orderId}${keySuffix}` });
  if (!s.url) throw new ProviderError('provider_no_url');
  return { id: s.id, url: s.url };
}

/** Full refund of a direct charge, ON the connected account (idempotent per order). */
export async function stripeRefund(accountId: string, paymentIntentId: string, orderId: string): Promise<string> {
  const r = await ticketDeps.stripe().refunds.create({
    payment_intent: paymentIntentId,
    reason: 'requested_by_customer',
    metadata: { orderId, greengo: 'ticket' },
  }, { stripeAccount: accountId, idempotencyKey: `gg_refund_${orderId}` });
  return r.id;
}

export async function stripeRetrieveSession(accountId: string, sessionId: string): Promise<Stripe.Checkout.Session> {
  return ticketDeps.stripe().checkout.sessions.retrieve(sessionId, {}, { stripeAccount: accountId });
}

export async function stripeExpireSession(accountId: string, sessionId: string): Promise<void> {
  await ticketDeps.stripe().checkout.sessions.expire(sessionId, {}, { stripeAccount: accountId });
}

// ─────────────────────────────────────────────────────────── Mercado Pago

const MP_API = 'https://api.mercadopago.com';

async function mpJson(path: string, init: RequestInit & { token?: string }): Promise<any> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json', Accept: 'application/json' };
  if (init.token) headers.Authorization = `Bearer ${init.token}`;
  const res = await ticketDeps.fetch(`${MP_API}${path}`, { ...init, headers: { ...headers, ...(init.headers as any || {}) } });
  const text = await res.text();
  let body: any = null;
  try { body = text ? JSON.parse(text) : null; } catch { body = null; }
  if (!res.ok) {
    throw new ProviderError(`mp_http_${res.status}`, `Mercado Pago ${path} -> ${res.status}`);
  }
  return body;
}

export function mpAuthorizationUrl(state: string): string {
  const q = new URLSearchParams({
    client_id: cfg.mpClientId(),
    response_type: 'code',
    platform_id: 'mp',
    state,
    redirect_uri: cfg.mpRedirectUri(),
  });
  return `https://auth.mercadopago.com/authorization?${q.toString()}`;
}

export interface MpTokens {
  accessToken: string;
  refreshToken: string;
  userId: string;
  publicKey: string | null;
  liveMode: boolean;
  expiresAtMs: number;
}

function mpTokensFrom(b: any): MpTokens {
  if (!b || typeof b.access_token !== 'string' || !b.access_token) throw new ProviderError('mp_bad_token_response');
  return {
    accessToken: b.access_token,
    refreshToken: String(b.refresh_token || ''),
    userId: String(b.user_id ?? ''),
    publicKey: typeof b.public_key === 'string' ? b.public_key : null,
    liveMode: b.live_mode === true,
    expiresAtMs: ticketDeps.now() + (Number(b.expires_in) || 15552000) * 1000,
  };
}

export async function mpExchangeCode(code: string): Promise<MpTokens> {
  return mpTokensFrom(await mpJson('/oauth/token', {
    method: 'POST',
    body: JSON.stringify({
      client_id: cfg.mpClientId(),
      client_secret: cfg.mpClientSecret(),
      grant_type: 'authorization_code',
      code,
      redirect_uri: cfg.mpRedirectUri(),
    }),
  }));
}

export async function mpRefresh(refreshToken: string): Promise<MpTokens> {
  return mpTokensFrom(await mpJson('/oauth/token', {
    method: 'POST',
    body: JSON.stringify({
      client_id: cfg.mpClientId(),
      client_secret: cfg.mpClientSecret(),
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
    }),
  }));
}

/** Checkout Pro preference on the organizer's account. Pix + cards + MP balance; no boleto / ATM. */
export async function mpCreatePreference(token: string, i: CheckoutInput): Promise<{ id: string; url: string }> {
  const body = mpPreferenceBody(i);
  const r = await mpJson('/checkout/preferences', {
    method: 'POST',
    token,
    body: JSON.stringify(body),
    headers: { 'X-Idempotency-Key': `gg_pref_${i.orderId}` } as any,
  });
  const url = cfg.mpUseSandbox() ? (r?.sandbox_init_point || r?.init_point) : r?.init_point;
  if (!r?.id || !url) throw new ProviderError('provider_no_url');
  return { id: String(r.id), url: String(url) };
}

/** The organizer's MP account (site => the only currency it charges in). */
export async function mpGetMe(token: string): Promise<{ siteId: string | null; countryId: string | null }> {
  const r = await mpJson('/users/me', { method: 'GET', token });
  return {
    siteId: typeof r?.site_id === 'string' ? r.site_id : null,
    countryId: typeof r?.country_id === 'string' ? r.country_id : null,
  };
}

export interface MpPayment {
  id: string;
  status: string;
  statusDetail: string | null;
  externalReference: string | null;
  amount: number;
  currency: string;
  refundedAmount: number;
}

function mpPaymentFrom(p: any): MpPayment {
  return {
    id: String(p?.id ?? ''),
    status: String(p?.status ?? ''),
    statusDetail: p?.status_detail ?? null,
    externalReference: p?.external_reference ? String(p.external_reference) : null,
    amount: Number(p?.transaction_amount ?? NaN),
    currency: String(p?.currency_id ?? '').toLowerCase(),
    refundedAmount: Number(p?.transaction_amount_refunded ?? 0),
  };
}

export async function mpGetPayment(token: string, paymentId: string): Promise<MpPayment> {
  if (!/^[0-9]{1,30}$/.test(paymentId)) throw new ProviderError('mp_bad_payment_id');
  return mpPaymentFrom(await mpJson(`/v1/payments/${paymentId}`, { method: 'GET', token }));
}

/** Full refund through the organizer's token (idempotent per order). */
export async function mpRefund(token: string, paymentId: string, orderId: string): Promise<string> {
  if (!/^[0-9]{1,30}$/.test(paymentId)) throw new ProviderError('mp_bad_payment_id');
  const r = await mpJson(`/v1/payments/${paymentId}/refunds`, {
    method: 'POST',
    token,
    body: JSON.stringify({}),
    headers: { 'X-Idempotency-Key': `gg_refund_${orderId}` } as any,
  });
  return String(r?.id ?? '');
}

export async function mpSearchPayments(token: string, orderId: string): Promise<MpPayment[]> {
  const q = new URLSearchParams({ external_reference: orderId, sort: 'date_created', criteria: 'desc', limit: '10' });
  const r = await mpJson(`/v1/payments/search?${q.toString()}`, { method: 'GET', token });
  return Array.isArray(r?.results) ? r.results.map(mpPaymentFrom) : [];
}
