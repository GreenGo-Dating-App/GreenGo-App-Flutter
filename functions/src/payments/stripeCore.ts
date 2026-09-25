/**
 * Stripe core: price table, verified grant paths, webhook dispatcher.
 *
 * THIS FILE IS BYTE-IDENTICAL IN BOTH REPOS (greengo-app-flutter-web and
 * GreenGo-App-Flutter). The web repo's payments/stripeCheckout.ts (the live
 * checkout + webhook) and payments/stripeReconcile.ts (the 12-hourly
 * reconciliation job, deployable from either repo) both call into it, so the
 * webhook and the reconciler apply entitlements through ONE code path.
 *
 * Security rules this module enforces:
 *   - WHAT was paid is derived from Stripe's own objects, fetched fresh with our
 *     secret key: the subscription's product id (server-written metadata) is
 *     cross-checked against the price table (unit amount + currency + interval)
 *     and coin sessions against amount_total + currency + line items. A
 *     mismatch grants nothing and raises a flag.
 *   - WHO paid: session metadata.userId must equal client_reference_id (both
 *     bound to the authenticated uid at session creation) and the Stripe
 *     customer's metadata.firebaseUserId, when present. Subscription
 *     metadata.userId and customer metadata must agree. Client-writable
 *     profile fields (profiles.stripeCustomerId, stripeSubscriptionId, ...) are
 *     NEVER used to decide who gets an entitlement.
 *   - Only `payment_status === 'paid'` sessions and `status === 'paid'`
 *     invoices grant. Async methods (PIX) grant on
 *     checkout.session.async_payment_succeeded, not on completion.
 *   - Idempotency is transactional: stripe_events/{eventId} (per delivery),
 *     stripe_orders/{sessionId} (coins, one grant per session),
 *     stripe_invoices/{invoiceId} (membership, one grant per invoice),
 *     stripe_revocations/{kind}_{id} (refund / dispute).
 *
 * Membership period = exactly Stripe's paid period:
 *   end = the paid invoice's subscription line `period.end` + RENEWAL_GRACE_MS
 *   (1 day). The grace only covers the gap between a period ending and the
 *   renewal invoice being charged (Stripe finalises ~1h after the period
 *   rolls; the hourly expiry job would otherwise flicker the user to FREE).
 *   A cancelled subscription is trimmed back to its paid period end (no grace).
 *   Nothing ever extends by a fixed 30/365 days, and only invoice.paid extends.
 */

import { AsyncLocalStorage } from 'async_hooks';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { db as sharedDb } from '../shared/utils';
import {
  effectiveTier,
  hasActivePaidTier,
  normalizeStoredTier,
  tierDateFromValue,
  tierRank,
} from '../shared/effectiveTier';
import { downgradeTierNow } from '../shared/membershipExpiry';

// ---------------------------------------------------------------------------
// Dependencies (overridable in unit tests; production uses the defaults)
// ---------------------------------------------------------------------------

export const stripeCoreDeps = {
  db: (): FirebaseFirestore.Firestore => sharedDb,
  getUserEmail: async (uid: string): Promise<string | null> => {
    try {
      return (await admin.auth().getUser(uid)).email || null;
    } catch {
      return null;
    }
  },
  now: (): Date => new Date(),
  downgradeTierNow: (uid: string, reason: string): Promise<string | null> =>
    downgradeTierNow(uid, reason, true),
  stripe: (testMode: boolean): Stripe => createStripeClient(testMode),
  webhooks: (): Stripe.Webhooks => new Stripe('sk_webhook_verify_only', {
    apiVersion: STRIPE_API_VERSION,
  }).webhooks,
};

const fdb = () => stripeCoreDeps.db();
const nowDate = () => stripeCoreDeps.now();
const ts = (d: Date) => admin.firestore.Timestamp.fromDate(d);
const fieldDelete = () => admin.firestore.FieldValue.delete();

// ---------------------------------------------------------------------------
// Constants / price table
// ---------------------------------------------------------------------------

/**
 * Pinned to the SDK's own version so every object we FETCH has one known
 * shape (invoice.subscription, invoice.charge, charge.invoice,
 * subscription.current_period_end). Webhook payloads use the endpoint's
 * version, which is why handlers only take the object id from the event and
 * re-fetch the object.
 */
export const STRIPE_API_VERSION = '2023-10-16' as const;

export const DAY_MS = 24 * 60 * 60 * 1000;
/** Added to the paid period end on every paid invoice. See file header. */
export const RENEWAL_GRACE_MS = DAY_MS;
/** Base trial length offered at checkout (Base only, first subscription). */
export const BASE_TRIAL_DAYS = 7;

export const BASE_PRODUCT_ID = 'greengo_base_membership';

export interface PricedProduct {
  priceUsd: number;
  priceEur: number;
  priceBrl: number;
}

export const COIN_PACKAGES: Record<string, PricedProduct & { coins: number; name: string }> = {
  'greengo_coins_100':  { coins: 100,  priceUsd: 99,    priceEur: 99,    priceBrl: 590,   name: 'Starter - 100 Coins' },
  'greengo_coins_500':  { coins: 500,  priceUsd: 399,   priceEur: 399,   priceBrl: 1990,  name: 'Popular - 500 Coins' },
  'greengo_coins_1000': { coins: 1000, priceUsd: 699,   priceEur: 699,   priceBrl: 3490,  name: 'Value - 1,000 Coins' },
  'greengo_coins_5000': { coins: 5000, priceUsd: 2999,  priceEur: 2999,  priceBrl: 14990, name: 'Premium - 5,000 Coins' },
};

export type MembershipTierCode = 'BASE' | 'SILVER' | 'GOLD' | 'PLATINUM';

export const MEMBERSHIP_PRODUCTS: Record<string, PricedProduct & {
  name: string;
  interval: 'month' | 'year';
  intervalCount: number;
  tier: MembershipTierCode;
}> = {
  'greengo_base_membership':      { name: 'Base Membership',     priceUsd: 499,  priceEur: 499,  priceBrl: 2490,  interval: 'year',  intervalCount: 1, tier: 'BASE' },
  '1_month_silver':               { name: 'Silver (Monthly)',    priceUsd: 999,  priceEur: 999,  priceBrl: 4990,  interval: 'month', intervalCount: 1, tier: 'SILVER' },
  '1_month_gold':                 { name: 'Gold (Monthly)',      priceUsd: 1999, priceEur: 1999, priceBrl: 9990,  interval: 'month', intervalCount: 1, tier: 'GOLD' },
  '1_month_platinum':             { name: 'Platinum (Monthly)',  priceUsd: 2999, priceEur: 2999, priceBrl: 14990, interval: 'month', intervalCount: 1, tier: 'PLATINUM' },
  '1_year_silver':                { name: 'Silver (Yearly)',     priceUsd: 4899, priceEur: 4899, priceBrl: 24990, interval: 'year',  intervalCount: 1, tier: 'SILVER' },
  '1_year_gold':                  { name: 'Gold (Yearly)',       priceUsd: 6999, priceEur: 6999, priceBrl: 34990, interval: 'year',  intervalCount: 1, tier: 'GOLD' },
  '1_year_platinum_membership':   { name: 'Platinum (Yearly)',   priceUsd: 8999, priceEur: 8999, priceBrl: 44990, interval: 'year',  intervalCount: 1, tier: 'PLATINUM' },
};

/** Upgrade discounts (from tier -> to tier -> fraction), matching Google Play. */
export const UPGRADE_DISCOUNTS: Record<string, Record<string, number>> = {
  'SILVER': { 'GOLD': 0.10, 'PLATINUM': 0.15 },
  'GOLD':   { 'PLATINUM': 0.10 },
};

export const MEMBERSHIP_TIER_RANK: Record<string, number> = {
  BASE: 0, SILVER: 1, GOLD: 2, PLATINUM: 3,
};

/** List price in minor units for a currency, or null for an unsupported one. */
export function listPriceCents(p: PricedProduct, currency: string | null | undefined): number | null {
  switch ((currency || '').toLowerCase()) {
    case 'usd': return p.priceUsd;
    case 'eur': return p.priceEur;
    case 'brl': return p.priceBrl;
    default: return null;
  }
}

/** Every unit amount the checkout can legitimately charge for a membership. */
export function allowedMembershipAmounts(productId: string, currency: string | null | undefined): number[] {
  const mem = MEMBERSHIP_PRODUCTS[productId];
  if (!mem) return [];
  const list = listPriceCents(mem, currency);
  if (list === null) return [];
  const out = new Set<number>([list]);
  for (const to of Object.values(UPGRADE_DISCOUNTS)) {
    const d = to[mem.tier];
    if (d) out.add(Math.round(list * (1 - d)));
  }
  return [...out];
}

export function discountedPriceCents(list: number, discount: number): number {
  return discount > 0 ? Math.round(list * (1 - discount)) : list;
}

/** Base and paid tiers are parallel subscriptions with their own profile fields. */
export function subFields(productId: string | undefined | null) {
  const base = productId === BASE_PRODUCT_ID;
  return {
    base,
    id: base ? 'stripeBaseSubscriptionId' : 'stripeSubscriptionId',
    lastId: base ? 'stripeBaseLastSubscriptionId' : 'stripeLastSubscriptionId',
    status: base ? 'stripeBaseSubscriptionStatus' : 'stripeSubscriptionStatus',
    cancelAtPeriodEnd: base
      ? 'stripeBaseSubscriptionCancelAtPeriodEnd'
      : 'stripeSubscriptionCancelAtPeriodEnd',
  };
}

// ---------------------------------------------------------------------------
// Test-mode allowlist + Stripe clients
// ---------------------------------------------------------------------------

/**
 * Accounts allowed to transact against Stripe TEST mode in production.
 * Evaluated server-side from verified identity, never from client input.
 */
export const STRIPE_TEST_MODE_EMAILS: readonly string[] = [
  'mauro.tommasi@live.it',
];

export function isStripeTestModeEmail(email: string | null | undefined): boolean {
  if (!email) return false;
  return STRIPE_TEST_MODE_EMAILS.includes(email.trim().toLowerCase());
}

function createStripeClient(testMode: boolean): Stripe {
  const name = testMode ? 'STRIPE_TEST_SECRET_KEY' : 'STRIPE_SECRET_KEY';
  const secretKey = process.env[name] || '';
  if (!secretKey) {
    throw new Error(`${name} not configured. Set it with: firebase functions:secrets:set ${name}`);
  }
  if (testMode && !secretKey.startsWith('sk_test_')) {
    throw new Error('STRIPE_TEST_SECRET_KEY must be a sk_test_ key.');
  }
  if (!testMode && secretKey.startsWith('sk_test_')) {
    // Never let a test key stand in for the live one.
    throw new Error('STRIPE_SECRET_KEY must be a live key (got sk_test_).');
  }
  return new Stripe(secretKey, {
    apiVersion: STRIPE_API_VERSION,
    maxNetworkRetries: 2,
    timeout: 20000,
  });
}

export function getStripe(testMode = false): Stripe {
  return stripeCoreDeps.stripe(testMode);
}

// ---------------------------------------------------------------------------
// Pure helpers (shape-tolerant across API versions)
// ---------------------------------------------------------------------------

export function idOf(x: any): string | null {
  if (!x) return null;
  if (typeof x === 'string') return x;
  return typeof x.id === 'string' ? x.id : null;
}

/** Subscription id of an invoice (old `subscription`, new `parent.subscription_details`). */
export function invoiceSubscriptionId(invoice: any): string | null {
  const modern = invoice?.parent?.subscription_details?.subscription;
  if (modern) return idOf(modern);
  const legacy = invoice?.subscription;
  if (legacy) return idOf(legacy);
  const line = invoice?.lines?.data?.[0];
  const fromLine = line?.parent?.subscription_item_details?.subscription ?? line?.subscription;
  return idOf(fromLine);
}

function lineSubscriptionId(line: any): string | null {
  return idOf(line?.subscription ?? line?.parent?.subscription_item_details?.subscription);
}

function isProrationLine(line: any): boolean {
  return line?.proration === true
    || line?.parent?.subscription_item_details?.proration === true;
}

/** The (non-proration) subscription line of an invoice for `subscriptionId`. */
export function subscriptionLineOf(invoice: any, subscriptionId: string | null): any | null {
  const lines: any[] = invoice?.lines?.data || [];
  const subLines = lines.filter((l) =>
    (l?.type === 'subscription' || !!lineSubscriptionId(l)) && !isProrationLine(l));
  if (subscriptionId) {
    const exact = subLines.find((l) => lineSubscriptionId(l) === subscriptionId);
    if (exact) return exact;
  }
  return subLines[0] || null;
}

export function linePaidPeriod(line: any): { start: Date; end: Date } | null {
  const s = line?.period?.start;
  const e = line?.period?.end;
  if (typeof s !== 'number' || typeof e !== 'number' || e <= s) return null;
  return { start: new Date(s * 1000), end: new Date(e * 1000) };
}

export function lineUnitAmount(line: any): number | null {
  const unit = line?.price?.unit_amount;
  if (typeof unit === 'number') return unit;
  const decimal = line?.pricing?.unit_amount_decimal;
  if (typeof decimal === 'string' && decimal !== '') return Math.round(Number(decimal));
  if (typeof line?.amount === 'number') return Math.round(line.amount / (line.quantity || 1));
  return null;
}

/** Current period end (unix seconds) across API versions, or null. */
export function subscriptionPeriodEnd(subscription: any): number | null {
  if (subscription?.current_period_end) return subscription.current_period_end;
  const item = subscription?.items?.data?.[0];
  if (item?.current_period_end) return item.current_period_end;
  return null;
}

/**
 * Email normaliser for the payer-vs-account check: trim + lowercase; drops a
 * `+tag` on any domain; for gmail/googlemail also drops dots in the local part
 * and folds googlemail.com into gmail.com.
 */
export function normalizeEmail(e: unknown): string | null {
  if (typeof e !== 'string') return null;
  const s = e.trim().toLowerCase();
  if (!s) return null;
  const at = s.lastIndexOf('@');
  if (at <= 0) return s;
  let local = s.slice(0, at);
  let domain = s.slice(at + 1);
  const plus = local.indexOf('+');
  if (plus > 0) local = local.slice(0, plus);
  if (domain === 'googlemail.com') domain = 'gmail.com';
  if (domain === 'gmail.com') local = local.replace(/\./g, '');
  return `${local}@${domain}`;
}

/**
 * Payer emails that do not match any account email (normalised). Empty result
 * = consistent. No payer email at all = nothing to compare (empty result).
 */
export function mismatchedPayerEmails(accountEmails: unknown[], payerEmails: unknown[]): string[] {
  const account = new Set(accountEmails.map(normalizeEmail).filter((x): x is string => !!x));
  const seen = new Set<string>();
  const out: string[] = [];
  for (const p of payerEmails) {
    const n = normalizeEmail(p);
    if (!n || seen.has(n)) continue;
    seen.add(n);
    if (!account.has(n)) out.push(String(p).trim());
  }
  return out;
}

// ---------------------------------------------------------------------------
// Validation (pure)
// ---------------------------------------------------------------------------

export interface PaidInvoiceCheck {
  ok: boolean;
  reason?: string;
  productId?: string;
  tier?: MembershipTierCode;
  base?: boolean;
  period?: { start: Date; end: Date };
  unitAmount?: number | null;
  amountPaid?: number;
  currency?: string;
  trial?: boolean;
  replacesSubscriptionId?: string | null;
}

/**
 * Decides what a paid subscription invoice is worth, from Stripe's objects
 * only. `sub.metadata` is server-written at session creation; the amount,
 * currency and interval must match our own price table for that product.
 */
export function validatePaidInvoice(invoice: any, sub: any): PaidInvoiceCheck {
  if (!invoice || invoice.status !== 'paid') return { ok: false, reason: 'invoice_not_paid' };
  const productId = String(sub?.metadata?.productId || '');
  const mem = MEMBERSHIP_PRODUCTS[productId];
  if (!mem) return { ok: false, reason: 'unknown_product', productId };
  const metaTier = String(sub?.metadata?.tier || '').toUpperCase();
  if (metaTier && metaTier !== mem.tier) {
    return { ok: false, reason: 'tier_metadata_mismatch', productId };
  }
  const line = subscriptionLineOf(invoice, idOf(sub));
  if (!line) return { ok: false, reason: 'no_subscription_line', productId };
  const period = linePaidPeriod(line);
  if (!period) return { ok: false, reason: 'no_paid_period', productId };
  const currency = String(invoice.currency || '').toLowerCase();
  const unitAmount = lineUnitAmount(line);
  const quantity = typeof line.quantity === 'number' ? line.quantity : 1;
  if (quantity !== 1) return { ok: false, reason: 'quantity_mismatch', productId, currency };
  if (unitAmount === null || !allowedMembershipAmounts(productId, currency).includes(unitAmount)) {
    return { ok: false, reason: 'amount_mismatch', productId, currency, unitAmount };
  }
  const interval = line?.price?.recurring?.interval;
  if (interval && interval !== mem.interval) {
    return { ok: false, reason: 'interval_mismatch', productId, currency, unitAmount };
  }
  const amountPaid = typeof invoice.amount_paid === 'number' ? invoice.amount_paid : 0;
  const periodMs = period.end.getTime() - period.start.getTime();
  const trialEndMs = typeof sub?.trial_end === 'number' ? sub.trial_end * 1000 : 0;
  const trial = amountPaid === 0
    && productId === BASE_PRODUCT_ID
    && invoice.billing_reason === 'subscription_create'
    && trialEndMs > 0
    && period.end.getTime() <= trialEndMs + 60_000
    && periodMs <= (BASE_TRIAL_DAYS + 1) * DAY_MS;
  // Paid entirely from the customer's credit balance (e.g. upgrade proration
  // credit): total > 0 but nothing charged to a card.
  const paidFromCredit = amountPaid === 0
    && typeof invoice.total === 'number' && invoice.total > 0
    && typeof invoice.starting_balance === 'number' && invoice.starting_balance < 0
    && (invoice.amount_remaining ?? 0) === 0;
  if (amountPaid <= 0 && !trial && !paidFromCredit) {
    return { ok: false, reason: 'zero_amount', productId, currency, unitAmount };
  }
  if (amountPaid > unitAmount) {
    return { ok: false, reason: 'amount_paid_exceeds_price', productId, currency, unitAmount };
  }
  return {
    ok: true,
    productId,
    tier: mem.tier,
    base: productId === BASE_PRODUCT_ID,
    period,
    unitAmount,
    amountPaid,
    currency,
    trial,
    replacesSubscriptionId: sub?.metadata?.replacesSubscriptionId || null,
  };
}

export interface CoinSessionCheck {
  ok: boolean;
  reason?: string;
  productId?: string;
  coins?: number;
  amount?: number;
  currency?: string;
}

/** Coins: amount_total + currency + the single line item must match the table. */
export function validateCoinSession(session: any): CoinSessionCheck {
  const productId = String(session?.metadata?.productId || '');
  const pkg = COIN_PACKAGES[productId];
  if (!pkg) return { ok: false, reason: 'unknown_product', productId };
  const currency = String(session.currency || '').toLowerCase();
  const expected = listPriceCents(pkg, currency);
  if (expected === null || session.amount_total !== expected) {
    return { ok: false, reason: 'amount_mismatch', productId, currency, amount: session.amount_total };
  }
  const items: any[] | undefined = session?.line_items?.data;
  if (items) {
    const total = items.reduce((s, i) => s + (i.amount_total ?? 0), 0);
    const qty = items.reduce((s, i) => s + (i.quantity ?? 0), 0);
    if (items.length !== 1 || qty !== 1 || total !== expected) {
      return { ok: false, reason: 'line_items_mismatch', productId, currency, amount: session.amount_total };
    }
  }
  return { ok: true, productId, coins: pkg.coins, amount: expected, currency };
}

// ---------------------------------------------------------------------------
// Flags (owner review). Create-if-absent: the owner's status edits survive.
// ---------------------------------------------------------------------------

export type FlagResult = 'created' | 'exists' | 'would_create';

/**
 * Per-run observer (the reconciler collects every flag raised inside the
 * shared paths it calls). AsyncLocalStorage keeps concurrent runs apart.
 */
export const flagObserver = new AsyncLocalStorage<
  (flagId: string, data: Record<string, any>, result: FlagResult) => void
>();

export async function createPaymentFlag(
  flagId: string,
  data: Record<string, any>,
  dryRun = false,
): Promise<FlagResult> {
  const id = flagId.replace(/\//g, '_');
  const ref = fdb().collection('stripe_payment_flags').doc(id);
  let result: FlagResult;
  if (dryRun) {
    const snap = await ref.get();
    result = snap.exists ? 'exists' : 'would_create';
  } else {
    result = await fdb().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return 'exists' as FlagResult;
      tx.create(ref, { status: 'open', ...data, createdAt: ts(nowDate()) });
      return 'created' as FlagResult;
    });
  }
  try {
    flagObserver.getStore()?.(id, data, result);
  } catch {
    // observer errors never break a payment path
  }
  return result;
}

// ---------------------------------------------------------------------------
// Identity
// ---------------------------------------------------------------------------

export interface UidResolution {
  uid: string | null;
  reason?: 'unresolved' | 'conflict' | 'profile_missing';
  candidates: string[];
  customerEmail?: string | null;
}

/**
 * The GreenGo uid behind a Stripe payment. Sources, all server-written:
 *   claimedUid (subscription / session metadata), the customer's
 *   metadata.firebaseUserId, and the server-only stripe_customers mapping.
 * They must agree. Client-writable profile fields are NOT a source.
 */
export async function resolveStripeUid(
  stripe: Stripe,
  opts: { customer: any; claimedUid?: string | null; livemode?: boolean },
): Promise<UidResolution> {
  const customerId = idOf(opts.customer);
  const candidates = new Set<string>();
  if (opts.claimedUid) candidates.add(String(opts.claimedUid));
  let customerEmail: string | null = null;
  if (customerId) {
    let cust: any = typeof opts.customer === 'object' ? opts.customer : null;
    if (!cust || cust.metadata === undefined) {
      try {
        cust = await stripe.customers.retrieve(customerId);
      } catch {
        cust = null;
      }
    }
    if (cust && !cust.deleted) {
      customerEmail = cust.email || null;
      const metaUid = cust.metadata?.firebaseUserId;
      if (metaUid) candidates.add(String(metaUid));
    }
    const field = opts.livemode === false ? 'testCustomerId' : 'customerId';
    const mapped = await fdb().collection('stripe_customers')
      .where(field, '==', customerId).limit(2).get();
    if (mapped.size === 1) candidates.add(mapped.docs[0].id);
    if (mapped.size > 1) mapped.docs.forEach((d) => candidates.add(d.id));
  }
  const list = [...candidates];
  if (list.length === 0) return { uid: null, reason: 'unresolved', candidates: list, customerEmail };
  if (list.length > 1) return { uid: null, reason: 'conflict', candidates: list, customerEmail };
  const profile = await fdb().collection('profiles').doc(list[0]).get();
  if (!profile.exists) return { uid: null, reason: 'profile_missing', candidates: list, customerEmail };
  return { uid: list[0], candidates: list, customerEmail };
}

/** Test-mode objects only ever grant to the allow-listed accounts. */
async function testModeAllowed(uid: string, livemode: boolean | undefined): Promise<boolean> {
  if (livemode !== false) return true;
  return isStripeTestModeEmail(await stripeCoreDeps.getUserEmail(uid));
}

/**
 * Get or create THIS user's Stripe customer. The uid->customer mapping lives
 * in the server-only stripe_customers/{uid}; a candidate id (including the
 * legacy client-writable profiles.stripeCustomerId) is only reused when the
 * customer's own metadata.firebaseUserId says it belongs to this uid.
 */
export async function getOrCreateStripeCustomer(
  stripe: Stripe,
  uid: string,
  opts: { testMode?: boolean; email?: string | null; name?: string | null } = {},
): Promise<string> {
  const testMode = opts.testMode === true;
  const mapField = testMode ? 'testCustomerId' : 'customerId';
  const profileField = testMode ? 'stripeTestCustomerId' : 'stripeCustomerId';
  const mapRef = fdb().collection('stripe_customers').doc(uid);
  const profileRef = fdb().collection('profiles').doc(uid);
  const [mapSnap, profileSnap] = await Promise.all([mapRef.get(), profileRef.get()]);
  const candidates = [mapSnap.data()?.[mapField], profileSnap.data()?.[profileField]]
    .filter((x, i, a): x is string => typeof x === 'string' && x.length > 0 && a.indexOf(x) === i);

  for (const candidate of candidates) {
    try {
      const c: any = await stripe.customers.retrieve(candidate);
      if (!c.deleted && c.metadata?.firebaseUserId === uid) {
        if (mapSnap.data()?.[mapField] !== candidate) {
          await mapRef.set({ uid, [mapField]: candidate, updatedAt: ts(nowDate()) }, { merge: true });
        }
        return candidate;
      }
      console.warn(`[stripe] customer ${candidate} does not belong to ${uid}; not reusing it`);
    } catch {
      // deleted / unknown: fall through and create
    }
  }

  const customer = await stripe.customers.create({
    metadata: { firebaseUserId: uid },
    ...(opts.email ? { email: opts.email } : {}),
    ...(opts.name ? { name: opts.name } : {}),
  });
  await mapRef.set({ uid, [mapField]: customer.id, updatedAt: ts(nowDate()) }, { merge: true });
  // Informational mirror only (client-writable, never trusted).
  await profileRef.set({ [profileField]: customer.id }, { merge: true });
  return customer.id;
}

// ---------------------------------------------------------------------------
// Result type
// ---------------------------------------------------------------------------

export interface StripeOutcome {
  action:
    | 'granted' | 'already' | 'rejected' | 'ignored' | 'updated'
    | 'revoked' | 'ended' | 'flagged'
    | 'would_grant' | 'would_update' | 'would_revoke' | 'would_end';
  reason?: string;
  uid?: string | null;
  detail?: Record<string, any>;
}

// ---------------------------------------------------------------------------
// Coins
// ---------------------------------------------------------------------------

export async function orderExists(sessionId: string): Promise<boolean> {
  const [byId, legacy] = await Promise.all([
    fdb().collection('stripe_orders').doc(sessionId).get(),
    fdb().collection('stripe_orders').where('sessionId', '==', sessionId).limit(1).get(),
  ]);
  return byId.exists || !legacy.empty;
}

/**
 * checkout.session.completed / async_payment_succeeded, and the reconciler's
 * missed-session fix. Coins: one transactional grant per paid session.
 * Memberships: applies the subscription's paid first invoice (same path as
 * invoice.paid, idempotent) and records the order the client polls for.
 */
export async function processCheckoutSession(
  stripe: Stripe,
  sessionId: string,
  opts: { source: 'webhook' | 'reconcile'; dryRun?: boolean } = { source: 'webhook' },
): Promise<StripeOutcome> {
  const s: any = await stripe.checkout.sessions.retrieve(sessionId, { expand: ['line_items'] });
  if (s.status !== 'complete') return { action: 'ignored', reason: `session_${s.status}` };

  const uidClaim = s.metadata?.userId || null;
  if (!uidClaim || s.client_reference_id !== uidClaim) {
    await createPaymentFlag(`session_uid_${s.id}`, {
      type: 'session_uid_mismatch', sessionId: s.id,
      metadataUid: uidClaim, clientReferenceId: s.client_reference_id || null,
      amount: s.amount_total ?? null, currency: s.currency ?? null, livemode: s.livemode,
    }, opts.dryRun);
    return { action: 'rejected', reason: 'session_uid_mismatch' };
  }

  if (s.mode === 'payment') {
    if (s.payment_status !== 'paid') return { action: 'ignored', reason: 'awaiting_payment', uid: uidClaim };
    if (s.metadata?.type !== 'coins') return { action: 'rejected', reason: 'unexpected_session_type' };
    const check = validateCoinSession(s);
    const who = await resolveStripeUid(stripe, { customer: s.customer, claimedUid: uidClaim, livemode: s.livemode });
    if (!check.ok || !who.uid) {
      const reason = !check.ok ? check.reason : `uid_${who.reason}`;
      await createPaymentFlag(`session_${reason}_${s.id}`, {
        type: !check.ok ? 'amount_mismatch' : (who.reason === 'conflict' ? 'customer_multiple_uids' : 'unresolved_uid'),
        reason, sessionId: s.id, uid: who.uid ?? uidClaim, candidates: who.candidates,
        product: check.productId || s.metadata?.productId || null,
        amount: s.amount_total ?? null, currency: s.currency ?? null, livemode: s.livemode,
      }, opts.dryRun);
      return { action: 'rejected', reason, uid: uidClaim };
    }
    const uid = who.uid;
    if (!(await testModeAllowed(uid, s.livemode))) return { action: 'rejected', reason: 'test_mode_not_allowed', uid };
    if (opts.dryRun) {
      return (await orderExists(s.id))
        ? { action: 'already', uid }
        : { action: 'would_grant', uid, detail: { coins: check.coins, sessionId: s.id } };
    }
    return grantCoinsForSession(uid, s, check);
  }

  if (s.mode === 'subscription') {
    if (s.payment_status !== 'paid' && s.payment_status !== 'no_payment_required') {
      return { action: 'ignored', reason: 'awaiting_payment', uid: uidClaim };
    }
    const subId = idOf(s.subscription);
    if (!subId) return { action: 'ignored', reason: 'no_subscription' };
    const sub: any = await stripe.subscriptions.retrieve(subId, { expand: ['latest_invoice'] });
    const inv = sub.latest_invoice;
    let outcome: StripeOutcome = { action: 'ignored', reason: 'first_invoice_not_paid', uid: uidClaim };
    if (inv && inv.status === 'paid') {
      outcome = await processPaidInvoice(stripe, idOf(inv) as string, opts);
    }
    const entitled = outcome.action === 'granted' || outcome.action === 'already';
    if (!opts.dryRun && entitled) {
      const orderRef = fdb().collection('stripe_orders').doc(s.id);
      await fdb().runTransaction(async (tx) => {
        const snap = await tx.get(orderRef);
        if (snap.exists) return;
        tx.create(orderRef, {
          sessionId: s.id, userId: uidClaim, productId: s.metadata?.productId || null,
          type: 'membership', amount: s.amount_total ?? null, currency: s.currency ?? null,
          stripeCustomerId: idOf(s.customer), stripeSubscriptionId: subId,
          status: 'completed', livemode: s.livemode === true, createdAt: ts(nowDate()),
        });
      });
    }
    return outcome;
  }
  return { action: 'ignored', reason: `mode_${s.mode}` };
}

async function grantCoinsForSession(uid: string, s: any, check: CoinSessionCheck): Promise<StripeOutcome> {
  const db = fdb();
  const orderRef = db.collection('stripe_orders').doc(s.id);
  const legacyQ = db.collection('stripe_orders').where('sessionId', '==', s.id).limit(1);
  const balanceRef = db.collection('coinBalances').doc(uid);
  const txRef = db.collection('coinTransactions').doc(`stripe_${s.id}`);
  const coins = check.coins as number;

  const applied = await db.runTransaction(async (tx) => {
    const [order, legacy, balance] = await Promise.all([
      tx.get(orderRef), tx.get(legacyQ), tx.get(balanceRef),
    ]);
    if (order.exists || !legacy.empty) return false;
    const now = ts(nowDate());
    const batchEntry = {
      batchId: `stripe_${s.id}`,
      initialCoins: coins,
      remainingCoins: coins,
      source: 'purchase',
      acquiredDate: now,
      expirationDate: ts(new Date(nowDate().getTime() + 365 * DAY_MS)),
    };
    const b = balance.exists ? (balance.data() as any) : null;
    if (b) {
      tx.set(balanceRef, {
        totalCoins: (b.totalCoins || 0) + coins,
        purchasedCoins: (b.purchasedCoins || 0) + coins,
        lastUpdated: now,
        coinBatches: [...(Array.isArray(b.coinBatches) ? b.coinBatches : []), batchEntry],
      }, { merge: true });
    } else {
      tx.set(balanceRef, {
        userId: uid, totalCoins: coins, purchasedCoins: coins, earnedCoins: 0,
        giftedCoins: 0, spentCoins: 0, lastUpdated: now, coinBatches: [batchEntry],
      });
    }
    tx.set(txRef, {
      userId: uid, type: 'credit', amount: coins, reason: 'coinPurchase',
      description: `Purchased ${coins} coins via Stripe`, createdAt: now,
      metadata: { productId: check.productId, platform: 'web', stripeSessionId: s.id },
    });
    tx.create(orderRef, {
      sessionId: s.id, userId: uid, productId: check.productId, type: 'coins', coins,
      amount: s.amount_total, currency: s.currency, stripeCustomerId: idOf(s.customer),
      paymentIntentId: idOf(s.payment_intent), status: 'completed',
      livemode: s.livemode === true, createdAt: now,
    });
    return true;
  });
  if (applied) console.log(`[stripe] credited ${coins} coins to ${uid} (session ${s.id})`);
  return applied
    ? { action: 'granted', uid, detail: { coins, sessionId: s.id } }
    : { action: 'already', uid, detail: { sessionId: s.id } };
}

// ---------------------------------------------------------------------------
// Membership: paid invoice -> entitlement
// ---------------------------------------------------------------------------

export async function invoiceApplied(invoiceId: string): Promise<boolean> {
  const [byId, legacy] = await Promise.all([
    fdb().collection('stripe_invoices').doc(invoiceId).get(),
    fdb().collection('stripe_invoices').where('invoiceId', '==', invoiceId).limit(1).get(),
  ]);
  return byId.exists || !legacy.empty;
}

/**
 * invoice.paid (initial + every renewal) and the reconciler's fix for a
 * missed one. `force` re-applies the entitlement even when the invoice marker
 * exists (drift repair); the write is idempotent (never shortens).
 */
export async function processPaidInvoice(
  stripe: Stripe,
  invoiceId: string,
  opts: { source: 'webhook' | 'reconcile'; dryRun?: boolean; force?: boolean } = { source: 'webhook' },
): Promise<StripeOutcome> {
  const inv: any = await stripe.invoices.retrieve(invoiceId, { expand: ['charge'] });
  const subId = invoiceSubscriptionId(inv);
  if (!subId) return { action: 'ignored', reason: 'not_subscription_invoice' };
  if (inv.status !== 'paid') return { action: 'ignored', reason: `invoice_${inv.status}` };
  const sub: any = await stripe.subscriptions.retrieve(subId);

  const check = validatePaidInvoice(inv, sub);
  const who = await resolveStripeUid(stripe, {
    customer: inv.customer, claimedUid: sub.metadata?.userId || null, livemode: inv.livemode,
  });
  if (!check.ok || !who.uid) {
    const reason = !check.ok ? check.reason : `uid_${who.reason}`;
    await createPaymentFlag(`invoice_${reason}_${inv.id}`, {
      type: !check.ok ? 'amount_mismatch' : (who.reason === 'conflict' ? 'customer_multiple_uids' : 'unresolved_uid'),
      reason, invoiceId: inv.id, subscriptionId: subId, customerId: idOf(inv.customer),
      uid: who.uid ?? sub.metadata?.userId ?? null, candidates: who.candidates,
      product: check.productId || sub.metadata?.productId || null,
      amount: inv.amount_paid ?? null, currency: inv.currency ?? null, livemode: inv.livemode,
    }, opts.dryRun);
    return { action: 'rejected', reason, uid: who.uid };
  }
  const uid = who.uid;
  const charge = inv.charge && typeof inv.charge === 'object' ? inv.charge : null;
  if (charge && (charge.refunded === true || charge.disputed === true)) {
    return { action: 'rejected', reason: 'charge_reversed', uid };
  }
  if (!(await testModeAllowed(uid, inv.livemode))) return { action: 'rejected', reason: 'test_mode_not_allowed', uid };

  if (opts.dryRun) {
    const applied = await invoiceApplied(inv.id);
    return applied && !opts.force
      ? { action: 'already', uid }
      : { action: 'would_grant', uid, detail: { invoiceId: inv.id, tier: check.tier, paidThrough: check.period?.end.toISOString() } };
  }

  const res = await writeMembershipGrant(uid, inv, sub, check, opts);
  if (res.action === 'granted' && check.replacesSubscriptionId && inv.billing_reason === 'subscription_create') {
    const cancelled = await cancelReplacedSubscription(stripe, sub, check.replacesSubscriptionId);
    res.detail = { ...(res.detail || {}), replacedSubscription: cancelled };
  }
  return res;
}

/** The transactional entitlement write for one paid invoice. */
async function writeMembershipGrant(
  uid: string,
  inv: any,
  sub: any,
  check: PaidInvoiceCheck,
  opts: { source: string; force?: boolean },
): Promise<StripeOutcome> {
  const db = fdb();
  const invRef = db.collection('stripe_invoices').doc(inv.id);
  const legacyQ = db.collection('stripe_invoices').where('invoiceId', '==', inv.id).limit(1);
  const profileRef = db.collection('profiles').doc(uid);
  const userRef = db.collection('users').doc(uid);
  const mapRef = db.collection('stripe_customers').doc(uid);
  const purchaseRef = db.collection('membership_purchases').doc(`stripe_${inv.id}`);
  const priorBaseQ = db.collection('membership_purchases')
    .where('userId', '==', uid).where('productId', '==', BASE_PRODUCT_ID).limit(10);
  const balanceRef = db.collection('coinBalances').doc(uid);

  const period = check.period as { start: Date; end: Date };
  const paidEndWithGrace = new Date(period.end.getTime() + RENEWAL_GRACE_MS);
  const f = subFields(check.productId);

  const result = await db.runTransaction(async (tx) => {
    const [marker, legacy, profileSnap, userSnap, mapSnap, priorBase, balance] = await Promise.all([
      tx.get(invRef), tx.get(legacyQ), tx.get(profileRef), tx.get(userRef), tx.get(mapRef),
      tx.get(priorBaseQ), tx.get(balanceRef),
    ]);
    const alreadyApplied = marker.exists || !legacy.empty;
    if (alreadyApplied && !opts.force) return { action: 'already' as const };

    const now = nowDate();
    const nowTs = ts(now);
    const profile = profileSnap.data() || {};
    const update: Record<string, any> = {
      [f.id]: sub.id,
      [f.lastId]: sub.id,
      [f.status]: sub.status === 'trialing' ? 'trialing' : 'active',
      [f.cancelAtPeriodEnd]: sub.cancel_at_period_end === true,
      updatedAt: nowTs,
    };
    let grantedEnd: Date;
    let grantedTier: string;
    let bonus = 0;
    const mapUpdate: Record<string, any> = {};

    if (f.base) {
      const curBaseEnd = tierDateFromValue(profile.baseMembershipEndDate);
      const baseActive = profile.hasBaseMembership === true && !!curBaseEnd && curBaseEnd > now;
      grantedEnd = baseActive && curBaseEnd && curBaseEnd > paidEndWithGrace ? curBaseEnd : paidEndWithGrace;
      grantedTier = 'BASE';
      Object.assign(update, {
        hasBaseMembership: true,
        baseMembershipEndDate: ts(grantedEnd),
        stripeBaseTrialUsed: true,
        stripeBasePaidThrough: ts(period.end),
      });
      // 500 bonus coins once per account, on the first REAL payment (a $0
      // trial invoice does not count, or every new account farms coins).
      const hadPaidBase = priorBase.docs.some((d) => {
        const x = d.data();
        return !x.stripeInvoiceId || (x.amountPaid || 0) > 0;
      });
      if ((check.amountPaid || 0) > 0 && !mapSnap.data()?.baseBonusGrantedAt && !hadPaidBase) {
        bonus = 500;
      }
      if (mapSnap.data()?.baseTrialUsed !== true) mapUpdate.baseTrialUsed = true;
    } else {
      const wanted = String(check.tier);
      const stored = normalizeStoredTier(profile.membershipTier);
      const curEnd = tierDateFromValue(profile.membershipEndDate);
      const active = hasActivePaidTier(profile, now);
      const current = effectiveTier(profile, now);
      // A subscription only ever sells its own tier, so an active HIGHER tier
      // always comes from somewhere else.
      if (active && tierRank(current) > tierRank(wanted)) {
        // A HIGHER tier from another source (store / coupon / admin) is
        // running. It is never downgraded, and this paid period runs
        // concurrently with it (no free upgrade by queuing). Recorded so the
        // reconciler grants the Stripe tier if the higher one ends first.
        grantedTier = current;
        grantedEnd = curEnd as Date;
        update.stripePendingTier = wanted;
        update.stripeSubscriptionPaidThrough = ts(period.end);
        update.stripeSubscriptionProductId = check.productId;
        update.stripeSubscriptionTier = wanted;
      } else {
        grantedTier = wanted;
        grantedEnd = active && stored === wanted && curEnd && curEnd > paidEndWithGrace
          ? curEnd // never shorten remaining time
          : paidEndWithGrace;
        Object.assign(update, {
          membershipTier: wanted,
          membershipEndDate: ts(grantedEnd),
          membershipSource: 'stripe',
          membershipProductId: check.productId,
          stripeSubscriptionProductId: check.productId,
          stripeSubscriptionTier: wanted,
          stripeSubscriptionPaidThrough: ts(period.end),
          stripePendingTier: fieldDelete(),
        });
        if (stored !== wanted || !active || inv.billing_reason === 'subscription_create') {
          update.membershipStartDate = nowTs;
        }
        if (userSnap.exists) {
          tx.set(userRef, { subscriptionTier: wanted, membershipEndDate: ts(grantedEnd), updatedAt: nowTs }, { merge: true });
        }
      }
    }
    tx.set(profileRef, update, { merge: true });

    if (!alreadyApplied) {
      tx.set(invRef, {
        invoiceId: inv.id, subscriptionId: sub.id, userId: uid, productId: check.productId,
        tier: check.tier, family: f.base ? 'base' : 'tier',
        amount: check.amountPaid, currency: check.currency, unitAmount: check.unitAmount,
        trial: check.trial === true, billingReason: inv.billing_reason || null,
        periodStart: ts(period.start), periodEnd: ts(period.end), grantedEnd: ts(grantedEnd),
        grantedTier, livemode: inv.livemode === true, status: 'applied', source: opts.source,
        createdAt: nowTs,
      });
      tx.set(purchaseRef, {
        userId: uid, productId: check.productId, tier: check.tier, subscriptionId: sub.id,
        stripeInvoiceId: inv.id, amountPaid: check.amountPaid, currency: check.currency,
        trial: check.trial === true, platform: 'web', purchasedAt: nowTs,
        periodEnd: ts(period.end), endDate: ts(grantedEnd),
      });
    } else {
      tx.set(invRef, { lastReappliedAt: nowTs, lastReappliedBy: opts.source }, { merge: true });
    }

    if (bonus > 0) {
      const b = balance.exists ? (balance.data() as any) : null;
      const entry = {
        batchId: `membership_bonus_${inv.id}`, initialCoins: bonus, remainingCoins: bonus,
        source: 'reward', acquiredDate: nowTs, expirationDate: ts(grantedEnd),
      };
      tx.set(balanceRef, b
        ? {
          totalCoins: (b.totalCoins || 0) + bonus,
          earnedCoins: (b.earnedCoins || 0) + bonus,
          lastUpdated: nowTs,
          coinBatches: [...(Array.isArray(b.coinBatches) ? b.coinBatches : []), entry],
        }
        : {
          userId: uid, totalCoins: bonus, earnedCoins: bonus, purchasedCoins: 0,
          giftedCoins: 0, spentCoins: 0, lastUpdated: nowTs, coinBatches: [entry],
        }, { merge: true });
      tx.set(db.collection('coinTransactions').doc(`stripe_base_bonus_${uid}`), {
        userId: uid, type: 'credit', amount: bonus, reason: 'membershipBonus',
        description: 'Base membership bonus coins', createdAt: nowTs,
        metadata: { platform: 'web', stripeInvoiceId: inv.id },
      });
      mapUpdate.baseBonusGrantedAt = nowTs;
    }
    if (Object.keys(mapUpdate).length > 0) tx.set(mapRef, { uid, ...mapUpdate }, { merge: true });
    return {
      action: (alreadyApplied ? 'updated' : 'granted') as 'updated' | 'granted',
      grantedEnd, grantedTier, bonus,
    };
  });

  if (result.action === 'already') return { action: 'already', uid, detail: { invoiceId: inv.id } };
  console.log(`[stripe] invoice ${inv.id} -> ${result.grantedTier} for ${uid} until ${result.grantedEnd?.toISOString()}`);
  return {
    action: result.action,
    uid,
    detail: {
      invoiceId: inv.id, tier: result.grantedTier,
      endDate: result.grantedEnd?.toISOString(), bonusCoins: result.bonus,
    },
  };
}

/**
 * Upgrade: after the NEW subscription's first invoice is paid, cancel the one
 * it replaces (same customer, same family) with proration credit. Until then
 * the user keeps the old tier and the old subscription keeps running.
 */
export async function cancelReplacedSubscription(
  stripe: Stripe,
  newSub: any,
  oldSubId: string,
  dryRun = false,
): Promise<string> {
  if (!oldSubId || oldSubId === newSub.id) return 'skipped';
  try {
    const old: any = await stripe.subscriptions.retrieve(oldSubId);
    if (idOf(old.customer) !== idOf(newSub.customer)) return 'customer_mismatch';
    const sameFamily = (old.metadata?.productId === BASE_PRODUCT_ID) === (newSub.metadata?.productId === BASE_PRODUCT_ID);
    if (!sameFamily) return 'family_mismatch';
    if (!['active', 'trialing', 'past_due', 'unpaid'].includes(old.status)) return `already_${old.status}`;
    if (dryRun) return 'would_cancel';
    await stripe.subscriptions.cancel(oldSubId, { prorate: true, invoice_now: true });
    console.log(`[stripe] upgrade: cancelled ${oldSubId} (replaced by ${newSub.id})`);
    return 'cancelled';
  } catch (e: any) {
    console.error(`[stripe] could not cancel replaced subscription ${oldSubId}:`, e?.message);
    return `error:${e?.message || e}`;
  }
}

/** End of the latest PAID, non-reversed period of a subscription, or null. */
export async function paidThroughForSubscription(stripe: Stripe, subId: string): Promise<Date | null> {
  const list: any = await stripe.invoices.list({ subscription: subId, status: 'paid', limit: 5, expand: ['data.charge'] });
  let best: Date | null = null;
  for (const inv of list.data || []) {
    const ch = inv.charge && typeof inv.charge === 'object' ? inv.charge : null;
    if (ch && (ch.refunded === true || ch.disputed === true)) continue;
    const p = linePaidPeriod(subscriptionLineOf(inv, subId));
    if (p && (!best || p.end > best)) best = p.end;
  }
  return best;
}

// ---------------------------------------------------------------------------
// Subscription status / end
// ---------------------------------------------------------------------------

/** customer.subscription.updated: status fields only. NEVER extends. */
export async function processSubscriptionUpdated(stripe: Stripe, subId: string): Promise<StripeOutcome> {
  const sub: any = await stripe.subscriptions.retrieve(subId);
  const who = await resolveStripeUid(stripe, { customer: sub.customer, claimedUid: sub.metadata?.userId, livemode: sub.livemode });
  if (!who.uid) return { action: 'ignored', reason: `uid_${who.reason}` };
  const f = subFields(sub.metadata?.productId);
  const ref = fdb().collection('profiles').doc(who.uid);
  return fdb().runTransaction(async (tx) => {
    const p = (await tx.get(ref)).data() || {};
    if (p[f.id] !== sub.id) {
      return { action: 'ignored' as const, reason: 'not_on_file', uid: who.uid };
    }
    tx.set(ref, {
      [f.status]: sub.status,
      [f.cancelAtPeriodEnd]: sub.cancel_at_period_end === true,
      updatedAt: ts(nowDate()),
    }, { merge: true });
    return { action: 'updated' as const, uid: who.uid, detail: { status: sub.status } };
  });
}

/**
 * customer.subscription.deleted (and the reconciler's missed-deletion fix).
 * Access runs to the end of the last PAID period (no grace after a deliberate
 * cancel); an end date that reaches beyond that came from another source and
 * is left alone. A subscription that never paid granted nothing.
 */
export async function processSubscriptionEnded(
  stripe: Stripe,
  subId: string,
  opts: { dryRun?: boolean } = {},
): Promise<StripeOutcome> {
  const sub: any = await stripe.subscriptions.retrieve(subId);
  if (!['canceled', 'incomplete_expired'].includes(sub.status)) {
    return { action: 'ignored', reason: `status_${sub.status}` };
  }
  const who = await resolveStripeUid(stripe, { customer: sub.customer, claimedUid: sub.metadata?.userId, livemode: sub.livemode });
  if (!who.uid) return { action: 'ignored', reason: `uid_${who.reason}` };
  const uid = who.uid;
  const f = subFields(sub.metadata?.productId);
  const subTier = MEMBERSHIP_PRODUCTS[sub.metadata?.productId]?.tier || String(sub.metadata?.tier || '').toUpperCase();
  const paidThrough = await paidThroughForSubscription(stripe, sub.id);
  const ref = fdb().collection('profiles').doc(uid);

  const plan = await fdb().runTransaction(async (tx) => {
    const p = (await tx.get(ref)).data() || {};
    if (p[f.id] !== sub.id) return { kind: 'not_on_file' as const };
    const now = nowDate();
    const limit = new Date(Math.max(now.getTime(), paidThrough ? paidThrough.getTime() : 0));
    const ownershipSlack = RENEWAL_GRACE_MS + 60 * 60 * 1000;
    const update: Record<string, any> = {
      [f.id]: fieldDelete(),
      [f.lastId]: sub.id,
      [f.status]: 'cancelled',
      [f.cancelAtPeriodEnd]: fieldDelete(),
      updatedAt: ts(now),
    };
    let endNow = false;
    let newEnd: Date | null = null;
    if (f.base) {
      const cur = tierDateFromValue(p.baseMembershipEndDate);
      const ours = !cur || !paidThrough || cur.getTime() <= paidThrough.getTime() + ownershipSlack;
      if (p.hasBaseMembership === true && cur && ours && cur > limit) {
        newEnd = limit;
        if (limit.getTime() <= now.getTime()) {
          Object.assign(update, { hasBaseMembership: false, baseMembershipEndDate: ts(now), baseMembershipExpiredAt: ts(now) });
          endNow = true;
        } else {
          update.baseMembershipEndDate = ts(limit);
        }
      }
    } else {
      update.stripeSubscriptionProductId = fieldDelete();
      update.stripeSubscriptionTier = fieldDelete();
      update.stripePendingTier = fieldDelete();
      const cur = tierDateFromValue(p.membershipEndDate);
      const stored = normalizeStoredTier(p.membershipTier);
      const ours = stored === subTier
        && (!cur || !paidThrough || cur.getTime() <= paidThrough.getTime() + ownershipSlack);
      if (ours && hasActivePaidTier(p, now) && cur && cur > limit) {
        newEnd = limit;
        if (limit.getTime() <= now.getTime()) {
          update.membershipEndDate = ts(now);
          endNow = true;
        } else {
          update.membershipEndDate = ts(limit);
        }
      }
    }
    if (opts.dryRun) return { kind: 'planned' as const, endNow, newEnd };
    tx.set(ref, update, { merge: true });
    return { kind: 'planned' as const, endNow, newEnd };
  });

  if (plan.kind === 'not_on_file') return { action: 'ignored', reason: 'not_on_file', uid };
  const detail = { endNow: plan.endNow, newEnd: plan.newEnd?.toISOString() ?? null, paidThrough: paidThrough?.toISOString() ?? null };
  if (opts.dryRun) return { action: 'would_end', uid, detail };
  if (plan.endNow && !f.base) await stripeCoreDeps.downgradeTierNow(uid, 'stripe_subscription_ended');
  if (plan.endNow) {
    await fdb().collection('notifications').doc(`stripe_sub_ended_${sub.id}`).set({
      userId: uid, type: 'subscription_cancelled', title: 'Subscription Cancelled',
      body: 'Your membership has ended. You can resubscribe anytime from the Shop.',
      read: false, createdAt: ts(nowDate()),
    });
  }
  return { action: 'ended', uid, detail };
}

/** invoice.payment_failed: flags the status and tells the user. Never extends. */
export async function processInvoicePaymentFailed(stripe: Stripe, invoiceId: string): Promise<StripeOutcome> {
  const inv: any = await stripe.invoices.retrieve(invoiceId);
  const subId = invoiceSubscriptionId(inv);
  if (!subId) return { action: 'ignored', reason: 'not_subscription_invoice' };
  const sub: any = await stripe.subscriptions.retrieve(subId);
  const who = await resolveStripeUid(stripe, { customer: inv.customer, claimedUid: sub.metadata?.userId, livemode: inv.livemode });
  if (!who.uid) return { action: 'ignored', reason: `uid_${who.reason}` };
  const f = subFields(sub.metadata?.productId);
  const ref = fdb().collection('profiles').doc(who.uid);
  const p = (await ref.get()).data() || {};
  if (p[f.id] !== subId) return { action: 'ignored', reason: 'not_on_file', uid: who.uid };
  const now = ts(nowDate());
  await ref.set({ [f.status]: 'past_due', stripePaymentFailedAt: now }, { merge: true });
  await fdb().collection('notifications').doc(`stripe_payment_failed_${inv.id}`).set({
    userId: who.uid, type: 'payment_failed', title: 'Payment Failed',
    body: 'Your subscription payment failed. Please update your payment method to keep your membership active.',
    read: false, createdAt: now,
  });
  return { action: 'updated', uid: who.uid, detail: { status: 'past_due' } };
}

// ---------------------------------------------------------------------------
// Refunds / disputes
// ---------------------------------------------------------------------------

/**
 * charge.refunded (full refund) and charge.dispute.created.
 *   Membership charge -> the entitlement from that subscription ends NOW
 *     (refund: only when the refunded period is still running; a refund of a
 *     long-past period changes nothing). Dispute -> also cancels the Stripe
 *     subscription so the disputed card is not charged again.
 *   Coin charge -> flagged for owner review (spent coins cannot be clawed
 *     back reliably).
 * Marker stripe_revocations/{kind}_{id} makes it idempotent.
 */
export async function processChargeReversal(
  stripe: Stripe,
  args: { kind: 'refund' | 'dispute'; chargeId: string; disputeId?: string | null },
  opts: { dryRun?: boolean; source?: string } = {},
): Promise<StripeOutcome> {
  const ch: any = await stripe.charges.retrieve(args.chargeId, { expand: ['invoice'] });
  const markerId = args.kind === 'dispute' ? `dispute_${args.disputeId || ch.id}` : `refund_${ch.id}`;
  const markerRef = fdb().collection('stripe_revocations').doc(markerId);
  if ((await markerRef.get()).exists) return { action: 'already', reason: markerId };

  if (args.kind === 'refund') {
    const full = ch.refunded === true || (ch.amount_refunded ?? 0) >= (ch.amount ?? Infinity);
    if (!full) {
      if (!opts.dryRun) {
        await markerRef.set({ kind: 'refund', chargeId: ch.id, action: 'none', reason: 'partial_refund', amountRefunded: ch.amount_refunded ?? null, createdAt: ts(nowDate()) });
      }
      return { action: 'ignored', reason: 'partial_refund' };
    }
  }

  const inv: any = ch.invoice && typeof ch.invoice === 'object' ? ch.invoice : null;
  const subId = inv ? invoiceSubscriptionId(inv) : null;
  const record: Record<string, any> = {
    kind: args.kind, chargeId: ch.id, disputeId: args.disputeId || null,
    invoiceId: inv?.id || null, subscriptionId: subId, amount: ch.amount ?? null,
    currency: ch.currency ?? null, livemode: ch.livemode === true, source: opts.source || 'webhook',
  };

  if (!subId) {
    // Coin purchase (or other one-off payment).
    let sessionId: string | null = null;
    let uid: string | null = null;
    let product: string | null = null;
    const pi = idOf(ch.payment_intent);
    if (pi) {
      const sessions: any = await stripe.checkout.sessions.list({ payment_intent: pi, limit: 1 });
      const s = sessions.data?.[0];
      if (s) {
        sessionId = s.id; uid = s.metadata?.userId || null; product = s.metadata?.productId || null;
      }
    }
    const flag = await createPaymentFlag(`coin_${args.kind}_${ch.id}`, {
      type: `coin_${args.kind}`, chargeId: ch.id, sessionId, uid, product,
      amount: ch.amount ?? null, currency: ch.currency ?? null, livemode: ch.livemode === true,
    }, opts.dryRun);
    if (!opts.dryRun) {
      await markerRef.set({ ...record, sessionId, uid, product, action: 'flagged', flag, createdAt: ts(nowDate()) });
    }
    return { action: 'flagged', uid, reason: `coin_${args.kind}`, detail: { flag } };
  }

  const sub: any = await stripe.subscriptions.retrieve(subId);
  const who = await resolveStripeUid(stripe, { customer: ch.customer, claimedUid: sub.metadata?.userId, livemode: ch.livemode });
  const f = subFields(sub.metadata?.productId);
  const period = linePaidPeriod(subscriptionLineOf(inv, subId));
  const now = nowDate();
  let cancelled: string | null = null;

  if (!who.uid) {
    await createPaymentFlag(`${args.kind}_unresolved_${ch.id}`, {
      type: 'unresolved_uid', reason: `${args.kind}_uid_${who.reason}`, chargeId: ch.id,
      subscriptionId: subId, candidates: who.candidates, amount: ch.amount, currency: ch.currency,
    }, opts.dryRun);
    return { action: 'rejected', reason: `uid_${who.reason}` };
  }
  const uid = who.uid;
  // A refund of a period that already ended takes nothing away.
  if (args.kind === 'refund' && period && period.end.getTime() <= now.getTime()) {
    if (!opts.dryRun) await markerRef.set({ ...record, uid, action: 'none', reason: 'past_period', createdAt: ts(now) });
    return { action: 'ignored', reason: 'past_period', uid };
  }
  if (opts.dryRun) return { action: 'would_revoke', uid, detail: { family: f.base ? 'base' : 'tier', subscriptionId: subId } };

  const ref = fdb().collection('profiles').doc(uid);
  const subTier = MEMBERSHIP_PRODUCTS[sub.metadata?.productId]?.tier || '';
  const endTier = await fdb().runTransaction(async (tx) => {
    const [marker, snap] = await Promise.all([tx.get(markerRef), tx.get(ref)]);
    if (marker.exists) return 'already' as const;
    const p = snap.data() || {};
    const onFile = p[f.id] === subId || p[f.lastId] === subId;
    const nowTs = ts(now);
    let action = 'none';
    if (onFile) {
      if (f.base) {
        tx.set(ref, {
          hasBaseMembership: false, baseMembershipEndDate: nowTs, baseMembershipExpiredAt: nowTs,
          [f.status]: args.kind === 'refund' ? 'refunded' : 'disputed', stripeRevokedReason: args.kind, updatedAt: nowTs,
        }, { merge: true });
        action = 'base_ended';
      } else if (normalizeStoredTier(p.membershipTier) === subTier) {
        tx.set(ref, {
          membershipEndDate: nowTs,
          [f.status]: args.kind === 'refund' ? 'refunded' : 'disputed', stripeRevokedReason: args.kind, updatedAt: nowTs,
        }, { merge: true });
        action = 'tier_ended';
      } else {
        tx.set(ref, { [f.status]: args.kind === 'refund' ? 'refunded' : 'disputed', updatedAt: nowTs }, { merge: true });
        action = 'other_source_untouched';
      }
    }
    tx.create(markerRef, { ...record, uid, action, createdAt: nowTs });
    return action;
  });
  if (endTier === 'already') return { action: 'already', uid };
  if (endTier === 'tier_ended') await stripeCoreDeps.downgradeTierNow(uid, `stripe_${args.kind}`);
  if (args.kind === 'dispute' && ['active', 'trialing', 'past_due', 'unpaid'].includes(sub.status)) {
    try {
      await stripe.subscriptions.cancel(subId, { prorate: false });
      cancelled = 'cancelled';
    } catch (e: any) {
      cancelled = `error:${e?.message || e}`;
    }
    await markerRef.set({ subscriptionCancelled: cancelled }, { merge: true });
  }
  return { action: 'revoked', uid, detail: { result: endTier, subscriptionCancelled: cancelled } };
}

// ---------------------------------------------------------------------------
// Webhook
// ---------------------------------------------------------------------------

/** Webhook event lease: a crashed delivery can be retried after this. */
export const EVENT_LEASE_MS = 5 * 60 * 1000;

/**
 * Transactional create-if-absent on stripe_events/{eventId}.
 *   'claimed'      -> this delivery processes the event
 *   'duplicate'    -> already processed successfully
 *   'in_progress'  -> another delivery holds a live lease
 * A 'failed' event, or one whose lease expired, is re-claimable.
 */
export async function claimStripeEvent(
  eventId: string,
  type: string,
  livemode: boolean,
): Promise<'claimed' | 'duplicate' | 'in_progress'> {
  const ref = fdb().collection('stripe_events').doc(eventId);
  return fdb().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = nowDate();
    const lease = ts(new Date(now.getTime() + EVENT_LEASE_MS));
    if (snap.exists) {
      const d = snap.data() || {};
      if (d.status === 'done') return 'duplicate' as const;
      const leaseUntil = tierDateFromValue(d.leaseUntil);
      if (d.status === 'processing' && leaseUntil && leaseUntil > now) return 'in_progress' as const;
      tx.set(ref, { status: 'processing', attempts: (d.attempts || 0) + 1, leaseUntil: lease, updatedAt: ts(now) }, { merge: true });
      return 'claimed' as const;
    }
    tx.create(ref, {
      eventId, type, livemode, status: 'processing', attempts: 1, leaseUntil: lease, receivedAt: ts(now),
    });
    return 'claimed' as const;
  });
}

export async function finishStripeEvent(
  eventId: string,
  status: 'done' | 'failed',
  outcome: Record<string, any>,
): Promise<void> {
  await fdb().collection('stripe_events').doc(eventId).set({
    status, outcome, finishedAt: ts(nowDate()), leaseUntil: fieldDelete(),
  }, { merge: true });
}

/** Routes one verified event. Throws on transient failure (-> Stripe retries). */
export async function dispatchStripeEvent(event: any): Promise<StripeOutcome> {
  const stripe = getStripe(event.livemode === false);
  const obj = event.data?.object || {};
  switch (event.type) {
    case 'checkout.session.completed':
    case 'checkout.session.async_payment_succeeded':
      return processCheckoutSession(stripe, obj.id, { source: 'webhook' });
    case 'checkout.session.async_payment_failed':
      return { action: 'ignored', reason: 'async_payment_failed' };
    case 'invoice.paid':
      return processPaidInvoice(stripe, obj.id, { source: 'webhook' });
    case 'invoice.payment_failed':
      return processInvoicePaymentFailed(stripe, obj.id);
    case 'customer.subscription.updated':
      return processSubscriptionUpdated(stripe, obj.id);
    case 'customer.subscription.deleted':
      return processSubscriptionEnded(stripe, obj.id);
    case 'charge.refunded':
      return processChargeReversal(stripe, { kind: 'refund', chargeId: obj.id });
    case 'charge.dispute.created':
      return processChargeReversal(stripe, { kind: 'dispute', chargeId: idOf(obj.charge) as string, disputeId: obj.id });
    case 'charge.dispute.closed': {
      const flag = await createPaymentFlag(`dispute_closed_${obj.id}`, {
        type: 'dispute_closed', disputeId: obj.id, chargeId: idOf(obj.charge),
        disputeStatus: obj.status || null, amount: obj.amount ?? null, currency: obj.currency ?? null,
      });
      return { action: 'flagged', reason: `dispute_${obj.status}`, detail: { flag } };
    }
    default:
      return { action: 'ignored', reason: `unhandled_${event.type}` };
  }
}

function splitSecrets(v: string | undefined): string[] {
  return (v || '').split(',').map((s) => s.trim()).filter(Boolean);
}

/**
 * The HTTP webhook. STRIPE_WEBHOOK_SECRET may hold several comma-separated
 * live signing secrets (e.g. two endpoints during a migration);
 * STRIPE_TEST_WEBHOOK_SECRET verifies the test-mode endpoint.
 */
export async function handleStripeWebhookHttp(req: any, res: any): Promise<void> {
  if (req.method !== 'POST') {
    res.status(405).send('Method not allowed');
    return;
  }
  const liveSecrets = splitSecrets(process.env.STRIPE_WEBHOOK_SECRET);
  const testSecrets = splitSecrets(process.env.STRIPE_TEST_WEBHOOK_SECRET);
  if (liveSecrets.length === 0) {
    // Fail closed: never process an unsigned body.
    console.error('[stripe] STRIPE_WEBHOOK_SECRET not configured - rejecting');
    res.status(500).send('Webhook not configured');
    return;
  }
  const signature = req.headers?.['stripe-signature'];
  if (typeof signature !== 'string' || !signature || !req.rawBody) {
    res.status(400).send('Missing signature');
    return;
  }

  let event: any = null;
  let signedAsLive = false;
  const webhooks = stripeCoreDeps.webhooks();
  for (const [secrets, live] of [[liveSecrets, true], [testSecrets, false]] as const) {
    for (const secret of secrets) {
      try {
        event = webhooks.constructEvent(req.rawBody, signature, secret);
        signedAsLive = live;
        break;
      } catch {
        // try the next secret
      }
    }
    if (event) break;
  }
  if (!event) {
    console.error('[stripe] webhook signature verification failed');
    res.status(400).send('Invalid signature');
    return;
  }
  if ((event.livemode === true) !== signedAsLive) {
    console.error(`[stripe] livemode mismatch on ${event.id}; ignored`);
    res.status(200).json({ received: true, ignored: 'livemode_mismatch' });
    return;
  }

  let claim: 'claimed' | 'duplicate' | 'in_progress';
  try {
    claim = await claimStripeEvent(event.id, event.type, event.livemode === true);
  } catch (e: any) {
    console.error(`[stripe] could not claim ${event.id}:`, e?.message);
    res.status(500).send('Retry');
    return;
  }
  if (claim === 'duplicate') {
    res.status(200).json({ received: true, duplicate: true });
    return;
  }
  if (claim === 'in_progress') {
    res.status(409).send('In progress');
    return;
  }

  try {
    const outcome = await dispatchStripeEvent(event);
    await finishStripeEvent(event.id, 'done', { ...outcome });
    console.log(`[stripe] ${event.type} ${event.id}: ${outcome.action}${outcome.reason ? ` (${outcome.reason})` : ''}`);
    res.status(200).json({ received: true });
  } catch (e: any) {
    console.error(`[stripe] error handling ${event.type} ${event.id}:`, e);
    try {
      await finishStripeEvent(event.id, 'failed', { error: String(e?.message || e) });
    } catch {
      // the lease expires on its own
    }
    // Non-2xx: Stripe retries, and the failed marker lets the retry run.
    res.status(500).send('Processing failed');
  }
}
