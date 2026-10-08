/**
 * Ticket payments — organizer onboarding ("Get paid").
 *
 *  payment_accounts/{uid}           server-only writes; the owner reads it.
 *    stripe:      { accountId, chargesEnabled, detailsSubmitted, payoutsEnabled,
 *                   country, defaultCurrency, status, updatedAt }
 *    mercadoPago: { userId, liveMode, status, connectedAt, expiresAt, updatedAt }
 *    status: 'pending' (onboarding not finished / provider still verifying) | 'ready'
 *  payment_accounts_private/{uid}   NO client access (rules default deny).
 *    mercadoPago: { accessToken, refreshToken (AES-256-GCM sealed), userId,
 *                   publicKey, expiresAt }
 *
 * Callables: getTicketPaymentsConfig, startStripeOnboarding,
 * startMercadoPagoOnboarding, refreshPaymentAccount.
 * HTTPS: mpOAuthCallback. Schedule: refreshMercadoPagoTokens.
 */
import * as admin from 'firebase-admin';
import { HttpsError } from 'firebase-functions/v2/https';
import '../shared/firebaseAdmin';
import * as cfg from './config';
import { COL, Provider } from './config';
import {
  ProviderError,
  mpAuthorizationUrl,
  mpExchangeCode,
  mpRefresh,
  mpGetMe,
  stripeAccountLink,
  stripeAccountState,
  stripeCreateStandardAccount,
  stripeRetrieveAccount,
  ticketDeps,
  MpTokens,
} from './providers';
import { seal, signState, unseal, verifyState } from './tokens';
import { ticketKey } from './keys';
import { mpCurrencyForSite } from './currency';

const db = () => admin.firestore();
const ts = (ms: number) => admin.firestore.Timestamp.fromMillis(ms);

export function fail(code: ConstructorParameters<typeof HttpsError>[0], reason: string, extra: Record<string, unknown> = {}): never {
  throw new HttpsError(code, reason, { code: reason, ...extra });
}

export function requireConfigured(p: Provider): void {
  if (!cfg.providerConfigured(p)) fail('failed-precondition', 'payments_not_configured', { provider: p });
}

export function clientPlatform(v: unknown): 'web' | 'app' {
  return v === 'web' ? 'web' : 'app';
}

export function returnUrl(params: Record<string, string>): string {
  return `${cfg.returnBaseUrl()}?${new URLSearchParams(params).toString()}`;
}

/** What the app needs to decide whether to show paid options at all. */
export async function getTicketPaymentsConfig(): Promise<Record<string, unknown>> {
  return {
    stripe: cfg.stripeConfigured(),
    mercadoPago: cfg.mercadoPagoConfigured(),
    link: true,
    holdMinutes: cfg.HOLD_MINUTES,
    linkHoldHours: cfg.LINK_HOLD_HOURS,
    confirmWindowHours: cfg.CONFIRM_WINDOW_HOURS,
    platformFeePercent: 0,
  };
}

// ─────────────────────────────────────────────────────────── Stripe

export async function startStripeOnboarding(uid: string, data: any, email: string | null): Promise<Record<string, unknown>> {
  requireConfigured('stripe');
  const ref = db().collection(COL.accounts).doc(uid);
  const snap = await ref.get();
  let accountId: string | undefined = snap.data()?.stripe?.accountId;
  try {
    if (!accountId) {
      const acct = await stripeCreateStandardAccount(uid, email);
      accountId = acct.id;
      const st = stripeAccountState(acct);
      await ref.set({
        uid,
        stripe: { ...st, status: st.chargesEnabled && st.detailsSubmitted ? 'ready' : 'pending', updatedAt: ts(ticketDeps.now()) },
        updatedAt: ts(ticketDeps.now()),
      }, { merge: true });
    }
    const p = clientPlatform(data?.platform);
    const url = await stripeAccountLink(
      accountId,
      returnUrl({ k: 'onboarding', provider: 'stripe', r: 'refresh', p }),
      returnUrl({ k: 'onboarding', provider: 'stripe', r: 'done', p }),
    );
    return { url, accountId };
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    const msg = (e as Error)?.message ?? '';
    console.error('[tickets] stripe onboarding failed:', msg);
    // The PLATFORM has not completed Stripe Connect sign-up (dashboard.stripe.com/connect):
    // not a provider outage - tell the organizer it is not available yet.
    if (/signed up for Connect|platform profile|Connect.*not.*enabled/i.test(msg)) {
      fail('failed-precondition', 'payments_not_configured', { provider: 'stripe' });
    }
    fail('unavailable', 'provider_unavailable', { provider: 'stripe' });
  }
}

export async function syncStripeAccount(uid: string, accountId: string): Promise<Record<string, unknown>> {
  const acct = await stripeRetrieveAccount(accountId);
  return writeStripeState(uid, stripeAccountState(acct));
}

export async function writeStripeState(uid: string, st: ReturnType<typeof stripeAccountState>): Promise<Record<string, unknown>> {
  const stripe = { ...st, status: st.chargesEnabled && st.detailsSubmitted ? 'ready' : 'pending', updatedAt: ts(ticketDeps.now()) };
  await db().collection(COL.accounts).doc(uid).set({ uid, stripe, updatedAt: ts(ticketDeps.now()) }, { merge: true });
  return stripe;
}

// ─────────────────────────────────────────────────────────── Mercado Pago

export async function startMercadoPagoOnboarding(uid: string, data: any): Promise<Record<string, unknown>> {
  requireConfigured('mercadopago');
  const state = signState(await ticketKey(), uid, ticketDeps.now());
  const p = clientPlatform(data?.platform);
  // The platform rides along in a short-lived server doc keyed by the state nonce.
  await db().collection(COL.accountsPrivate).doc(uid).set({
    oauthPending: { platform: p, createdAt: ts(ticketDeps.now()) },
  }, { merge: true });
  return { url: mpAuthorizationUrl(state) };
}

async function sealTok(v: string): Promise<string> {
  return seal(v, cfg.tokenEncryptionKey(), await ticketKey());
}
async function unsealTok(v: string): Promise<string> {
  return unseal(v, cfg.tokenEncryptionKey(), await ticketKey());
}

export async function storeMpTokens(uid: string, t: MpTokens): Promise<void> {
  const now = ticketDeps.now();
  // MP charges only in the account's site currency: remember it.
  let siteId: string | null = null;
  try { siteId = (await mpGetMe(t.accessToken)).siteId; } catch (e) {
    console.error('[tickets] MP users/me failed:', (e as Error)?.message);
  }
  const access = await sealTok(t.accessToken);
  const refresh = t.refreshToken ? await sealTok(t.refreshToken) : null;
  const batch = db().batch();
  batch.set(db().collection(COL.accountsPrivate).doc(uid), {
    mercadoPago: {
      accessToken: access,
      refreshToken: refresh,
      userId: t.userId,
      publicKey: t.publicKey,
      expiresAt: ts(t.expiresAtMs),
      updatedAt: ts(now),
    },
    mpExpiresAt: ts(t.expiresAtMs),
    oauthPending: admin.firestore.FieldValue.delete(),
  }, { merge: true });
  batch.set(db().collection(COL.accounts).doc(uid), {
    uid,
    mercadoPago: {
      userId: t.userId,
      liveMode: t.liveMode,
      siteId,
      currency: mpCurrencyForSite(siteId),
      status: 'ready',
      connectedAt: ts(now),
      expiresAt: ts(t.expiresAtMs),
      updatedAt: ts(now),
    },
    updatedAt: ts(now),
  }, { merge: true });
  await batch.commit();
}

/** The organizer's MP access token, refreshed when close to expiry. */
export async function mpAccessTokenFor(uid: string): Promise<string> {
  const ref = db().collection(COL.accountsPrivate).doc(uid);
  const mp = (await ref.get()).data()?.mercadoPago;
  if (!mp?.accessToken) throw new ProviderError('mp_not_connected');
  const exp = (mp.expiresAt as admin.firestore.Timestamp | undefined)?.toMillis?.() ?? 0;
  if (exp - ticketDeps.now() > cfg.MP_REFRESH_BEFORE_MS || !mp.refreshToken) {
    return await unsealTok(mp.accessToken);
  }
  return refreshMpFor(uid, mp);
}

async function refreshMpFor(uid: string, mp: Record<string, any>): Promise<string> {
  try {
    const t = await mpRefresh(await unsealTok(mp.refreshToken));
    await storeMpTokens(uid, t);
    return t.accessToken;
  } catch (e) {
    console.error(`[tickets] MP token refresh for ${uid} failed:`, (e as Error)?.message);
    await db().collection(COL.accounts).doc(uid).set({
      mercadoPago: { status: 'needs_reconnect', updatedAt: ts(ticketDeps.now()) },
    }, { merge: true });
    // An unexpired token still works; an expired one cannot be used.
    const exp = (mp.expiresAt as admin.firestore.Timestamp | undefined)?.toMillis?.() ?? 0;
    if (exp > ticketDeps.now()) return await unsealTok(mp.accessToken);
    throw new ProviderError('mp_not_connected');
  }
}

/** Scheduled: refresh tokens that expire within MP_REFRESH_BEFORE_MS (bounded batch). */
export async function refreshDueMpTokens(limit = 200): Promise<number> {
  const due = await db().collection(COL.accountsPrivate)
    .where('mpExpiresAt', '<=', ts(ticketDeps.now() + cfg.MP_REFRESH_BEFORE_MS))
    .orderBy('mpExpiresAt')
    .limit(limit)
    .get();
  let n = 0;
  for (const d of due.docs) {
    const mp = d.data().mercadoPago;
    if (!mp?.refreshToken) continue;
    try { await refreshMpFor(d.id, mp); n++; } catch { /* logged */ }
  }
  return n;
}

function htmlPage(title: string, body: string, appLink: string | null, webLink: string): string {
  const esc = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
  const btn = appLink
    ? `<p><a class="b" href="${esc(appLink)}">Open GreenGo</a></p><script>setTimeout(function(){location.href=${JSON.stringify(appLink)}},300)</script>`
    : '';
  return `<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)}</title><style>body{font-family:system-ui,sans-serif;background:#0b0b0b;color:#f2f2f2;text-align:center;padding:48px 20px}
.b{display:inline-block;background:#d4af37;color:#111;padding:14px 22px;border-radius:12px;text-decoration:none;font-weight:700}
small{color:#999}</style></head><body><h2>${esc(title)}</h2><p>${esc(body)}</p>${btn}
<p><small>You can close this window and return to the app.</small></p><p><small><a style="color:#999" href="${esc(webLink)}">GreenGo web</a></small></p></body></html>`;
}

/** Return page used by Stripe / MP after checkout or onboarding. */
export function returnPage(q: Record<string, unknown>): { status: number; html?: string; redirect?: string } {
  const kind = String(q.k || 'order');
  const p = clientPlatform(q.p);
  const web = 'https://greengo-chat.web.app';
  if (kind === 'onboarding') {
    const target = '/pay/connected';
    if (p === 'web') return { status: 302, redirect: `${web}/?link=${encodeURIComponent(target)}` };
    return { status: 200, html: htmlPage('Payment account updated', 'Return to GreenGo to see your status.', 'greengo://pay/connected', web) };
  }
  const orderId = String(q.o || '');
  if (!/^[A-Za-z0-9_-]{1,128}$/.test(orderId)) return { status: 400, html: htmlPage('GreenGo', 'Unknown order.', null, web) };
  const target = `/t/${orderId}`;
  if (p === 'web') return { status: 302, redirect: `${web}/?link=${encodeURIComponent(target)}` };
  const r = String(q.r || '');
  const title = r === 'cancel' ? 'Payment not completed' : 'Thanks! Confirming your payment';
  return { status: 200, html: htmlPage(title, 'Your ticket appears in GreenGo as soon as the payment is confirmed.', `greengo://t/${orderId}`, web) };
}

/** HTTPS: Mercado Pago OAuth redirect. */
export async function handleMpOAuthCallback(q: Record<string, unknown>): Promise<{ status: number; html?: string; redirect?: string }> {
  const uid = verifyState(await ticketKey(), q.state, ticketDeps.now());
  const code = typeof q.code === 'string' ? q.code : '';
  if (!uid || !code || !cfg.mercadoPagoConfigured()) {
    return { status: 400, html: htmlPage('Connection failed', 'The Mercado Pago link expired or is invalid. Try again from GreenGo.', 'greengo://pay/connected', 'https://greengo-chat.web.app') };
  }
  const pending = (await db().collection(COL.accountsPrivate).doc(uid).get()).data()?.oauthPending;
  try {
    await storeMpTokens(uid, await mpExchangeCode(code));
  } catch (e) {
    console.error('[tickets] MP OAuth exchange failed:', (e as Error)?.message);
    return { status: 502, html: htmlPage('Connection failed', 'Mercado Pago did not confirm the connection. Try again.', 'greengo://pay/connected', 'https://greengo-chat.web.app') };
  }
  return returnPage({ k: 'onboarding', p: pending?.platform === 'web' ? 'web' : 'app' });
}

/** Re-reads the provider state (Stripe account) and returns the public account doc. */
export async function refreshPaymentAccount(uid: string): Promise<Record<string, unknown>> {
  const ref = db().collection(COL.accounts).doc(uid);
  const d = (await ref.get()).data() || {};
  if (d.stripe?.accountId && cfg.stripeConfigured()) {
    try { await syncStripeAccount(uid, d.stripe.accountId); } catch (e) {
      console.error('[tickets] stripe refresh failed:', (e as Error)?.message);
    }
  }
  if (d.mercadoPago && cfg.mercadoPagoConfigured()) {
    try { await mpAccessTokenFor(uid); } catch { /* status already written */ }
  }
  const fresh = (await ref.get()).data() || {};
  return {
    stripe: fresh.stripe ? { status: fresh.stripe.status, chargesEnabled: !!fresh.stripe.chargesEnabled, country: fresh.stripe.country ?? null } : null,
    mercadoPago: fresh.mercadoPago
      ? { status: fresh.mercadoPago.status, liveMode: !!fresh.mercadoPago.liveMode, currency: fresh.mercadoPago.currency ?? null }
      : null,
  };
}

/** True when [uid] can receive money through [p] right now. */
export function accountReady(acct: Record<string, any> | undefined, p: Provider): boolean {
  if (!acct) return false;
  if (p === 'stripe') return !!acct.stripe?.accountId && acct.stripe.chargesEnabled === true && acct.stripe.detailsSubmitted === true;
  return acct.mercadoPago?.status === 'ready';
}
