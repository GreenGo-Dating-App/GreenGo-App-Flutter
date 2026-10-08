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

// ─────────────────────────────────────────────────────────── money helpers

const ZERO_DECIMAL = new Set(['bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf',
  'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf']);
export function exponentOf(currency: string): number { return ZERO_DECIMAL.has(currency.toLowerCase()) ? 0 : 2; }
export function toMinor(major: number, currency: string): number {
  const f = 10 ** exponentOf(currency);
  return Math.round(Number((major * f).toFixed(6)));
}
export function toMajor(minor: number, currency: string): number {
  return minor / 10 ** exponentOf(currency);
}

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

export interface CheckoutInput {
  orderId: string;
  title: string;
  unitAmount: number;
  quantity: number;
  currency: string;
  successUrl: string;
  cancelUrl: string;
  expiresAtMs: number;
  buyerEmail?: string | null;
}

/** Direct charge on the connected account. Cards + Apple Pay / Google Pay (wallets ride on `card`). */
export async function stripeCreateCheckout(accountId: string, i: CheckoutInput): Promise<{ id: string; url: string }> {
  const s = await ticketDeps.stripe().checkout.sessions.create({
    mode: 'payment',
    payment_method_types: ['card'],
    line_items: [{
      quantity: i.quantity,
      price_data: {
        currency: i.currency,
        unit_amount: i.unitAmount,
        product_data: { name: i.title.slice(0, 250) || 'Ticket' },
      },
    }],
    client_reference_id: i.orderId,
    metadata: { orderId: i.orderId, greengo: 'ticket' },
    payment_intent_data: { metadata: { orderId: i.orderId, greengo: 'ticket' } },
    success_url: i.successUrl,
    cancel_url: i.cancelUrl,
    expires_at: Math.floor(i.expiresAtMs / 1000),
    ...(i.buyerEmail ? { customer_email: i.buyerEmail } : {}),
  }, { stripeAccount: accountId, idempotencyKey: `gg_tco_${i.orderId}` });
  if (!s.url) throw new ProviderError('provider_no_url');
  return { id: s.id, url: s.url };
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
export async function mpCreatePreference(token: string, i: CheckoutInput & { notificationUrl: string; pendingUrl: string }): Promise<{ id: string; url: string }> {
  const body = {
    items: [{
      id: i.orderId,
      title: i.title.slice(0, 250) || 'Ticket',
      quantity: i.quantity,
      unit_price: toMajor(i.unitAmount, i.currency),
      currency_id: i.currency.toUpperCase(),
      category_id: 'tickets',
    }],
    external_reference: i.orderId,
    metadata: { order_id: i.orderId, greengo: 'ticket' },
    notification_url: i.notificationUrl,
    back_urls: { success: i.successUrl, failure: i.cancelUrl, pending: i.pendingUrl },
    auto_return: 'approved',
    expires: true,
    expiration_date_from: new Date(ticketDeps.now() - 60000).toISOString(),
    expiration_date_to: new Date(i.expiresAtMs).toISOString(),
    date_of_expiration: new Date(i.expiresAtMs).toISOString(),
    payment_methods: {
      excluded_payment_types: [{ id: 'ticket' }, { id: 'atm' }],
    },
    ...(i.buyerEmail ? { payer: { email: i.buyerEmail } } : {}),
  };
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

export async function mpSearchPayments(token: string, orderId: string): Promise<MpPayment[]> {
  const q = new URLSearchParams({ external_reference: orderId, sort: 'date_created', criteria: 'desc', limit: '10' });
  const r = await mpJson(`/v1/payments/search?${q.toString()}`, { method: 'GET', token });
  return Array.isArray(r?.results) ? r.results.map(mpPaymentFrom) : [];
}
