/**
 * Stripe reconciliation (every 12 hours) + token-guarded HTTP twin.
 *
 * THIS FILE IS BYTE-IDENTICAL IN BOTH REPOS. Deployable from either; it only
 * uses ./stripeCore.ts (also identical) and the live STRIPE_SECRET_KEY.
 *
 * What it reads from Stripe (live mode only):
 *   subscriptions  status=all; every non-ended one + anything canceled /
 *                  incomplete_expired in the last 45 days (expand customer,
 *                  latest_invoice.charge)
 *   invoices       created in the last 14 days (paid -> applied?)
 *   checkout sessions (coins) created in the last 14 days (granted?)
 *   charges        created in the last 14 days (payer email, uid, amount)
 *   refunds / disputes created in the last 14 days (revoked?)
 *
 * What it corrects (through the SAME idempotent functions the webhook uses):
 *   missed invoice.paid (grant), membership shorter than Stripe's paid period,
 *   missed coin grant, missed subscription end, stale subscription status,
 *   missed refund / dispute revocation, un-cancelled replaced subscription
 *   after an upgrade. Never shortens a membership on its own: over-entitlement
 *   is FLAGGED.
 *
 * What it flags (stripe_payment_flags, FLAG ONLY, owner reviews):
 *   payer email != account email (doc id = charge id), a Stripe customer tied
 *   to several GreenGo uids, payments with no resolvable uid, amount /
 *   currency not matching the price table, over-entitlement, partial refunds.
 *
 * Output: stripe_reconciliation_runs/{runId}; admins notified (in-app
 * notifications to admin_users + Resend email when configured) when a run
 * created flags or corrections or hit errors.
 *
 * Bounded: page size 100, per-phase caps, 480s time budget; the cursor is
 * persisted in stripe_reconcile_state/cursor and the next run resumes there.
 * Never throws out of the handler.
 *
 * HTTP:  GET .../runStripeReconcileNow?token=<STRIPE_RECONCILE_TOKEN>          -> DRY RUN (default)
 *        GET .../runStripeReconcileNow?token=<...>&dryRun=0                    -> real run
 * Token from STRIPE_RECONCILE_TOKEN in the gitignored functions/.env; unset -> 503.
 */

import * as crypto from 'crypto';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onRequest } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import {
  COIN_PACKAGES,
  DAY_MS,
  FlagResult,
  MEMBERSHIP_PRODUCTS,
  RENEWAL_GRACE_MS,
  StripeOutcome,
  allowedMembershipAmounts,
  cancelReplacedSubscription,
  createPaymentFlag,
  flagObserver,
  getStripe,
  idOf,
  invoiceApplied,
  invoiceSubscriptionId,
  linePaidPeriod,
  listPriceCents,
  mismatchedPayerEmails,
  orderExists,
  processChargeReversal,
  processCheckoutSession,
  processPaidInvoice,
  processSubscriptionEnded,
  resolveStripeUid,
  stripeCoreDeps,
  subFields,
  subscriptionLineOf,
} from './stripeCore';
import {
  effectiveTier,
  hasActivePaidTier,
  normalizeStoredTier,
  tierDateFromValue,
  tierRank,
} from '../shared/effectiveTier';

export const RECONCILE_CONFIG = {
  subscriptionWindowDays: 45,
  paymentWindowDays: 14,
  pageSize: 100,
  budgetMs: 480_000,
  lockLeaseMs: 600_000,
  cursorMaxAgeMs: 3 * DAY_MS,
  caps: {
    subscriptions: 5000,
    invoices: 5000,
    sessions: 5000,
    charges: 5000,
    refunds: 2000,
    disputes: 2000,
  } as Record<Phase, number>,
  maxReportItems: 300,
};

export type Phase = 'subscriptions' | 'invoices' | 'sessions' | 'charges' | 'refunds' | 'disputes';
export const PHASES: Phase[] = ['subscriptions', 'invoices', 'sessions', 'charges', 'refunds', 'disputes'];

export interface Correction {
  type: string;
  uid?: string | null;
  objectId: string;
  result: string;
  detail?: Record<string, any>;
}

export interface ReconcileReport {
  runId: string;
  trigger: string;
  dryRun: boolean;
  startedAt: string;
  finishedAt?: string;
  complete: boolean;
  resumedFrom: { phase: Phase; startingAfter: string | null } | null;
  nextCursor: { phase: Phase; startingAfter: string | null } | null;
  window: { paymentsSince: string; endedSubscriptionsSince: string };
  scanned: Record<Phase, number>;
  capped: Phase[];
  corrections: Correction[];
  correctionsCount: number;
  flags: { id: string; type: string; result: FlagResult }[];
  flagsCreated: number;
  flagsWouldCreate: number;
  errors: string[];
  errorsCount: number;
  skipped?: string;
}

// Overridable in tests.
export const stripeReconcileDeps = {
  notifyAdmins: (report: ReconcileReport): Promise<void> => notifyAdminsDefault(report),
};

const fdb = () => stripeCoreDeps.db();
const ts = (d: Date) => admin.firestore.Timestamp.fromDate(d);

// ---------------------------------------------------------------------------
// Pure: what Stripe says the entitlement should be, and how the profile drifts
// ---------------------------------------------------------------------------

export interface ExpectedEntitlement {
  known: boolean;
  productId: string;
  tier: string;
  base: boolean;
  shouldBeActive: boolean;
  paidThrough: Date | null;
  invoiceId: string | null;
  reversed: boolean;
}

const LIVE_SUB_STATUSES = ['active', 'trialing', 'past_due'];
const TERMINAL_SUB_STATUSES = ['canceled', 'incomplete_expired'];

/** From a subscription with `latest_invoice` (and its `charge`) expanded. */
export function expectedEntitlement(sub: any, now: Date): ExpectedEntitlement {
  const productId = String(sub?.metadata?.productId || '');
  const mem = MEMBERSHIP_PRODUCTS[productId];
  const inv = sub?.latest_invoice && typeof sub.latest_invoice === 'object' ? sub.latest_invoice : null;
  const charge = inv?.charge && typeof inv.charge === 'object' ? inv.charge : null;
  const paid = inv?.status === 'paid';
  const reversed = !!charge && (charge.refunded === true || charge.disputed === true);
  const period = paid ? linePaidPeriod(subscriptionLineOf(inv, sub.id)) : null;
  const paidThrough = paid && !reversed && period ? period.end : null;
  return {
    known: !!mem,
    productId,
    tier: mem?.tier || '',
    base: productId === 'greengo_base_membership',
    shouldBeActive: !!mem && LIVE_SUB_STATUSES.includes(sub.status) && !!paidThrough && paidThrough > now,
    paidThrough,
    invoiceId: inv?.id || null,
    reversed,
  };
}

export interface Drift {
  type: 'missing_grant' | 'ended_not_applied' | 'status_mismatch' | 'over_entitlement';
  detail?: Record<string, any>;
}

function liveClass(status: unknown): boolean {
  return status === 'active' || status === 'trialing';
}

/** Compares a profile with Stripe truth for ONE subscription. */
export function entitlementDrift(
  profile: Record<string, any>,
  sub: any,
  exp: ExpectedEntitlement,
  now: Date,
): Drift[] {
  if (!exp.known) return [];
  const out: Drift[] = [];
  const f = subFields(exp.productId);
  const onFile = profile[f.id] === sub.id;
  const terminal = TERMINAL_SUB_STATUSES.includes(sub.status);
  const overLimit = (exp.paidThrough ? exp.paidThrough.getTime() : now.getTime()) + RENEWAL_GRACE_MS + 2 * DAY_MS;

  if (exp.base) {
    const end = tierDateFromValue(profile.baseMembershipEndDate);
    if (exp.shouldBeActive) {
      const ok = profile.hasBaseMembership === true && !!end && end >= (exp.paidThrough as Date);
      if (!ok || !onFile) out.push({ type: 'missing_grant', detail: { hasBase: profile.hasBaseMembership === true, end: end?.toISOString() ?? null } });
    }
    if (onFile && profile.hasBaseMembership === true && end && end.getTime() > overLimit) {
      out.push({ type: 'over_entitlement', detail: { end: end.toISOString(), paidThrough: exp.paidThrough?.toISOString() ?? null } });
    }
  } else {
    const end = tierDateFromValue(profile.membershipEndDate);
    const stored = normalizeStoredTier(profile.membershipTier);
    const eff = effectiveTier(profile, now);
    const higherElsewhere = hasActivePaidTier(profile, now) && tierRank(eff) > tierRank(exp.tier);
    if (exp.shouldBeActive) {
      const ok = higherElsewhere || (stored === exp.tier && !!end && end >= (exp.paidThrough as Date) && onFile);
      if (!ok) out.push({ type: 'missing_grant', detail: { tier: stored, end: end?.toISOString() ?? null, onFile } });
    }
    if (onFile && !higherElsewhere && stored === exp.tier && profile.membershipSource === 'stripe'
      && end && end.getTime() > overLimit) {
      out.push({ type: 'over_entitlement', detail: { end: end.toISOString(), paidThrough: exp.paidThrough?.toISOString() ?? null } });
    }
  }

  if (onFile && terminal) {
    out.push({ type: 'ended_not_applied', detail: { status: sub.status } });
  } else if (onFile && liveClass(profile[f.status]) !== liveClass(sub.status)) {
    out.push({ type: 'status_mismatch', detail: { profile: profile[f.status] ?? null, stripe: sub.status } });
  }
  return out;
}

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------

interface RunCtx {
  stripe: Stripe;
  dryRun: boolean;
  now: Date;
  report: ReconcileReport;
  customerUids: Map<string, Set<string>>;
  subCache: Map<string, any>;
  sessionByPi: Map<string, any>;
  refundedCharges: Set<string>;
}

function pushCorrection(ctx: RunCtx, c: Correction): void {
  ctx.report.correctionsCount++;
  if (ctx.report.corrections.length < RECONCILE_CONFIG.maxReportItems) ctx.report.corrections.push(c);
}

function pushError(ctx: RunCtx, msg: string): void {
  ctx.report.errorsCount++;
  console.error(`[stripeReconcile] ${msg}`);
  if (ctx.report.errors.length < RECONCILE_CONFIG.maxReportItems) ctx.report.errors.push(msg.slice(0, 500));
}

function noteCustomerUid(ctx: RunCtx, customerId: string | null, uids: string[]): void {
  if (!customerId) return;
  const set = ctx.customerUids.get(customerId) || new Set<string>();
  uids.forEach((u) => set.add(u));
  ctx.customerUids.set(customerId, set);
}

async function flag(ctx: RunCtx, id: string, data: Record<string, any>): Promise<void> {
  await createPaymentFlag(id, { ...data, source: 'reconcile' }, ctx.dryRun);
}

const APPLIED_ACTIONS = ['granted', 'updated', 'would_grant', 'ended', 'would_end', 'revoked', 'would_revoke', 'flagged'];

async function handleSubscription(ctx: RunCtx, sub: any): Promise<void> {
  const exp = expectedEntitlement(sub, ctx.now);
  const customerId = idOf(sub.customer);
  if (!exp.known) {
    if (LIVE_SUB_STATUSES.includes(sub.status)) {
      await flag(ctx, `unknown_product_sub_${sub.id}`, {
        type: 'unknown_product', subscriptionId: sub.id, customerId, product: exp.productId || null,
      });
    }
    return;
  }
  const who = await resolveStripeUid(ctx.stripe, {
    customer: sub.customer, claimedUid: sub.metadata?.userId || null, livemode: sub.livemode,
  });
  noteCustomerUid(ctx, customerId, who.candidates);
  if (!who.uid) {
    if (LIVE_SUB_STATUSES.includes(sub.status) || exp.paidThrough) {
      await flag(ctx, who.reason === 'conflict' ? `customer_multiple_uids_${customerId}` : `unresolved_sub_${sub.id}`, {
        type: who.reason === 'conflict' ? 'customer_multiple_uids' : 'unresolved_uid',
        reason: who.reason, subscriptionId: sub.id, customerId, candidates: who.candidates, product: exp.productId,
      });
    }
    return;
  }
  const uid = who.uid;
  const profile = (await fdb().collection('profiles').doc(uid).get()).data() || {};
  const drifts = entitlementDrift(profile, sub, exp, ctx.now);

  for (const d of drifts) {
    if (d.type === 'missing_grant' && exp.invoiceId) {
      const r = await processPaidInvoice(ctx.stripe, exp.invoiceId, { source: 'reconcile', force: true, dryRun: ctx.dryRun });
      if (APPLIED_ACTIONS.includes(r.action)) {
        pushCorrection(ctx, { type: 'missing_grant', uid, objectId: sub.id, result: r.action, detail: { invoiceId: exp.invoiceId, before: d.detail, after: r.detail } });
      }
    } else if (d.type === 'ended_not_applied') {
      const r = await processSubscriptionEnded(ctx.stripe, sub.id, { dryRun: ctx.dryRun });
      if (APPLIED_ACTIONS.includes(r.action)) {
        pushCorrection(ctx, { type: 'subscription_end', uid, objectId: sub.id, result: r.action, detail: r.detail });
      }
    } else if (d.type === 'status_mismatch') {
      const f = subFields(exp.productId);
      if (!ctx.dryRun) {
        await fdb().collection('profiles').doc(uid).set({ [f.status]: sub.status, updatedAt: ts(ctx.now) }, { merge: true });
      }
      pushCorrection(ctx, { type: 'status_sync', uid, objectId: sub.id, result: ctx.dryRun ? 'would_update' : 'updated', detail: d.detail });
    } else if (d.type === 'over_entitlement') {
      await flag(ctx, `over_entitlement_${sub.id}`, {
        type: 'over_entitlement', uid, subscriptionId: sub.id, product: exp.productId, ...d.detail,
      });
    }
  }

  // Upgrade whose old subscription was never cancelled (e.g. the cancel call
  // failed after the new first invoice was paid).
  const replaces = sub.metadata?.replacesSubscriptionId;
  if (replaces && exp.shouldBeActive) {
    const r = await cancelReplacedSubscription(ctx.stripe, sub, replaces, ctx.dryRun);
    if (r === 'cancelled' || r === 'would_cancel') {
      pushCorrection(ctx, { type: 'replaced_subscription_cancel', uid, objectId: replaces, result: r, detail: { newSubscription: sub.id } });
    } else if (r.startsWith('error:')) {
      pushError(ctx, `cancel replaced ${replaces}: ${r}`);
    }
  }
}

async function handleInvoice(ctx: RunCtx, inv: any): Promise<void> {
  const subId = invoiceSubscriptionId(inv);
  if (!subId || inv.status !== 'paid') return;
  if (await invoiceApplied(inv.id)) return;
  const r = await processPaidInvoice(ctx.stripe, inv.id, { source: 'reconcile', dryRun: ctx.dryRun });
  if (APPLIED_ACTIONS.includes(r.action)) {
    pushCorrection(ctx, { type: 'missed_invoice_paid', uid: r.uid, objectId: inv.id, result: r.action, detail: r.detail });
  }
}

async function handleSession(ctx: RunCtx, s: any): Promise<void> {
  if (s.status !== 'complete' || s.mode !== 'payment' || s.payment_status !== 'paid') return;
  if (s.payment_intent) ctx.sessionByPi.set(idOf(s.payment_intent) as string, s);
  if (await orderExists(s.id)) return;
  const r = await processCheckoutSession(ctx.stripe, s.id, { source: 'reconcile', dryRun: ctx.dryRun });
  if (APPLIED_ACTIONS.includes(r.action)) {
    pushCorrection(ctx, { type: 'missed_coin_grant', uid: r.uid, objectId: s.id, result: r.action, detail: r.detail });
  }
}

async function subscriptionFor(ctx: RunCtx, subId: string): Promise<any | null> {
  if (ctx.subCache.has(subId)) return ctx.subCache.get(subId);
  let sub: any = null;
  try {
    sub = await ctx.stripe.subscriptions.retrieve(subId);
  } catch {
    sub = null;
  }
  ctx.subCache.set(subId, sub);
  return sub;
}

async function sessionForPaymentIntent(ctx: RunCtx, pi: string | null): Promise<any | null> {
  if (!pi) return null;
  if (ctx.sessionByPi.has(pi)) return ctx.sessionByPi.get(pi);
  let s: any = null;
  try {
    const list: any = await ctx.stripe.checkout.sessions.list({ payment_intent: pi, limit: 1 });
    s = list.data?.[0] || null;
  } catch {
    s = null;
  }
  ctx.sessionByPi.set(pi, s);
  return s;
}

/** Payer email / uid / amount checks for one paid charge. Flags only. */
async function handleCharge(ctx: RunCtx, ch: any): Promise<void> {
  if (ch.status !== 'succeeded' || ch.paid !== true) return;
  const inv = ch.invoice && typeof ch.invoice === 'object' ? ch.invoice : null;
  const subId = inv ? invoiceSubscriptionId(inv) : null;
  let claimedUid: string | null = null;
  let product: string | null = null;
  if (subId) {
    const meta = inv?.subscription_details?.metadata || (await subscriptionFor(ctx, subId))?.metadata || {};
    claimedUid = meta.userId || null;
    product = meta.productId || null;
  } else {
    const s = await sessionForPaymentIntent(ctx, idOf(ch.payment_intent));
    claimedUid = s?.metadata?.userId || ch.metadata?.userId || null;
    product = s?.metadata?.productId || ch.metadata?.productId || null;
  }
  const customer = ch.customer && typeof ch.customer === 'object' ? ch.customer : null;
  const customerId = idOf(ch.customer);
  const who = await resolveStripeUid(ctx.stripe, { customer: ch.customer, claimedUid, livemode: ch.livemode });
  noteCustomerUid(ctx, customerId, who.candidates);
  const base = {
    chargeId: ch.id, customerId, amount: ch.amount ?? null, currency: ch.currency ?? null,
    product, livemode: ch.livemode === true, chargeCreated: ch.created ? new Date(ch.created * 1000).toISOString() : null,
  };

  // Amount / currency vs the price table.
  const currency = String(ch.currency || '').toLowerCase();
  if (!product || (!COIN_PACKAGES[product] && !MEMBERSHIP_PRODUCTS[product])) {
    await flag(ctx, `unknown_product_${ch.id}`, { type: 'unknown_product', uid: who.uid, ...base });
  } else if (COIN_PACKAGES[product]) {
    if (listPriceCents(COIN_PACKAGES[product], currency) !== ch.amount) {
      await flag(ctx, `amount_mismatch_${ch.id}`, { type: 'amount_mismatch', uid: who.uid, expected: listPriceCents(COIN_PACKAGES[product], currency), ...base });
    }
  } else {
    const allowed = allowedMembershipAmounts(product, currency);
    // A membership charge can be lower than the price (credit balance), never higher.
    if (allowed.length === 0 || ch.amount <= 0 || ch.amount > Math.max(...allowed)) {
      await flag(ctx, `amount_mismatch_${ch.id}`, { type: 'amount_mismatch', uid: who.uid, expected: allowed, ...base });
    }
  }

  if (!who.uid) {
    const conflict = who.reason === 'conflict';
    await flag(ctx, conflict ? `customer_multiple_uids_${customerId}` : `unresolved_${ch.id}`, {
      type: conflict ? 'customer_multiple_uids' : 'unresolved_payment', reason: who.reason, candidates: who.candidates, ...base,
    });
    return;
  }

  // EMAIL CHECK: payer vs GreenGo account.
  const uid = who.uid;
  const [authEmail, profileSnap] = await Promise.all([
    stripeCoreDeps.getUserEmail(uid),
    fdb().collection('profiles').doc(uid).get(),
  ]);
  const profileEmail = profileSnap.data()?.email || null;
  const payerEmails = [ch.billing_details?.email, ch.receipt_email, customer?.email ?? who.customerEmail, inv?.customer_email]
    .filter((e) => typeof e === 'string' && e.trim() !== '');
  const mismatched = mismatchedPayerEmails([authEmail, profileEmail], payerEmails);
  if (mismatched.length > 0) {
    await flag(ctx, ch.id, {
      type: 'email_mismatch', uid, accountEmail: authEmail, profileEmail,
      payerEmails: [...new Set(payerEmails.map((e) => String(e).trim()))], mismatched, ...base,
    });
  }
}

async function handleRefund(ctx: RunCtx, r: any): Promise<void> {
  const chargeId = idOf(r.charge);
  if (!chargeId || r.status !== 'succeeded' || ctx.refundedCharges.has(chargeId)) return;
  ctx.refundedCharges.add(chargeId);
  if ((await fdb().collection('stripe_revocations').doc(`refund_${chargeId}`).get()).exists) return;
  const out: StripeOutcome = await processChargeReversal(ctx.stripe, { kind: 'refund', chargeId }, { dryRun: ctx.dryRun, source: 'reconcile' });
  if (out.reason === 'partial_refund') {
    await flag(ctx, `partial_refund_${chargeId}`, { type: 'partial_refund', chargeId, refundId: r.id, amount: r.amount ?? null, currency: r.currency ?? null });
  } else if (APPLIED_ACTIONS.includes(out.action)) {
    pushCorrection(ctx, { type: 'missed_refund', uid: out.uid, objectId: chargeId, result: out.action, detail: out.detail });
  }
}

async function handleDispute(ctx: RunCtx, d: any): Promise<void> {
  const chargeId = idOf(d.charge);
  if (!chargeId) return;
  if ((await fdb().collection('stripe_revocations').doc(`dispute_${d.id}`).get()).exists) return;
  const out = await processChargeReversal(ctx.stripe, { kind: 'dispute', chargeId, disputeId: d.id }, { dryRun: ctx.dryRun, source: 'reconcile' });
  if (APPLIED_ACTIONS.includes(out.action)) {
    pushCorrection(ctx, { type: 'missed_dispute', uid: out.uid, objectId: d.id, result: out.action, detail: out.detail });
  }
}

async function listPage(ctx: RunCtx, phase: Phase, startingAfter: string | null, since: number): Promise<{ data: any[]; has_more: boolean }> {
  const common: any = { limit: RECONCILE_CONFIG.pageSize, ...(startingAfter ? { starting_after: startingAfter } : {}) };
  const created = { gte: since };
  const s = ctx.stripe;
  switch (phase) {
    case 'subscriptions':
      return s.subscriptions.list({ ...common, status: 'all', expand: ['data.customer', 'data.latest_invoice.charge'] }) as any;
    case 'invoices':
      return s.invoices.list({ ...common, created }) as any;
    case 'sessions':
      return s.checkout.sessions.list({ ...common, created }) as any;
    case 'charges':
      return s.charges.list({ ...common, created, expand: ['data.customer', 'data.invoice'] }) as any;
    case 'refunds':
      return s.refunds.list({ ...common, created }) as any;
    case 'disputes':
      return s.disputes.list({ ...common, created }) as any;
  }
}

async function handle(ctx: RunCtx, phase: Phase, obj: any, subSince: number): Promise<void> {
  switch (phase) {
    case 'subscriptions': {
      if (TERMINAL_SUB_STATUSES.includes(obj.status)) {
        const endedAt = obj.ended_at || obj.canceled_at || obj.created || 0;
        if (endedAt < subSince) return;
      }
      return handleSubscription(ctx, obj);
    }
    case 'invoices': return handleInvoice(ctx, obj);
    case 'sessions': return handleSession(ctx, obj);
    case 'charges': return handleCharge(ctx, obj);
    case 'refunds': return handleRefund(ctx, obj);
    case 'disputes': return handleDispute(ctx, obj);
  }
}

function newRunId(now: Date): string {
  return `${now.toISOString().replace(/[-:.]/g, '').slice(0, 15)}_${crypto.randomBytes(3).toString('hex')}`;
}

async function acquireLock(runId: string, now: Date): Promise<boolean> {
  const ref = fdb().collection('stripe_reconcile_state').doc('lock');
  return fdb().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    const lease = tierDateFromValue(d?.leaseUntil);
    if (d?.runId && lease && lease > now) return false;
    tx.set(ref, { runId, leaseUntil: ts(new Date(now.getTime() + RECONCILE_CONFIG.lockLeaseMs)), acquiredAt: ts(now) });
    return true;
  });
}

async function releaseLock(runId: string): Promise<void> {
  const ref = fdb().collection('stripe_reconcile_state').doc('lock');
  await fdb().runTransaction(async (tx) => {
    const d = (await tx.get(ref)).data();
    if (d?.runId === runId) tx.set(ref, { runId: null, leaseUntil: null, releasedAt: ts(stripeCoreDeps.now()) });
  });
}

export interface RunOptions {
  dryRun: boolean;
  trigger: string;
  stripe?: Stripe;
  budgetMs?: number;
}

/** One reconciliation pass. Never throws. */
export async function runStripeReconciliation(opts: RunOptions): Promise<ReconcileReport> {
  const started = Date.now();
  const now = stripeCoreDeps.now();
  const budget = opts.budgetMs ?? RECONCILE_CONFIG.budgetMs;
  const runId = newRunId(now);
  const report: ReconcileReport = {
    runId, trigger: opts.trigger, dryRun: opts.dryRun, startedAt: now.toISOString(), complete: false,
    resumedFrom: null, nextCursor: null,
    window: { paymentsSince: '', endedSubscriptionsSince: '' },
    scanned: { subscriptions: 0, invoices: 0, sessions: 0, charges: 0, refunds: 0, disputes: 0 },
    capped: [], corrections: [], correctionsCount: 0, flags: [], flagsCreated: 0, flagsWouldCreate: 0,
    errors: [], errorsCount: 0,
  };

  let locked = false;
  try {
    if (!opts.dryRun) {
      locked = await acquireLock(runId, now);
      if (!locked) {
        report.skipped = 'another run holds the lock';
        report.finishedAt = stripeCoreDeps.now().toISOString();
        return report;
      }
    }

    const stripe = opts.stripe ?? getStripe(false);
    const ctx: RunCtx = {
      stripe, dryRun: opts.dryRun, now, report,
      customerUids: new Map(), subCache: new Map(), sessionByPi: new Map(), refundedCharges: new Set(),
    };

    // Resume point (real runs only; a dry run always scans from the top).
    const cursorRef = fdb().collection('stripe_reconcile_state').doc('cursor');
    let paySince = Math.floor((now.getTime() - RECONCILE_CONFIG.paymentWindowDays * DAY_MS) / 1000);
    let subSince = Math.floor((now.getTime() - RECONCILE_CONFIG.subscriptionWindowDays * DAY_MS) / 1000);
    let startPhase: Phase = PHASES[0];
    let startAfter: string | null = null;
    if (!opts.dryRun) {
      const c = (await cursorRef.get()).data();
      const savedAt = tierDateFromValue(c?.savedAt);
      if (c?.phase && PHASES.includes(c.phase) && savedAt && now.getTime() - savedAt.getTime() < RECONCILE_CONFIG.cursorMaxAgeMs) {
        startPhase = c.phase;
        startAfter = c.startingAfter || null;
        paySince = c.paySince || paySince;
        subSince = c.subSince || subSince;
        report.resumedFrom = { phase: startPhase, startingAfter: startAfter };
      }
    }
    report.window = {
      paymentsSince: new Date(paySince * 1000).toISOString(),
      endedSubscriptionsSince: new Date(subSince * 1000).toISOString(),
    };

    const observer = (id: string, data: Record<string, any>, result: FlagResult) => {
      if (result === 'created') report.flagsCreated++;
      if (result === 'would_create') report.flagsWouldCreate++;
      if (result !== 'exists' && report.flags.length < RECONCILE_CONFIG.maxReportItems) {
        report.flags.push({ id, type: String(data.type || 'unknown'), result });
      }
    };

    await flagObserver.run(observer, async () => {
      let outOfTime = false;
      for (let pi = PHASES.indexOf(startPhase); pi < PHASES.length && !outOfTime; pi++) {
        const phase = PHASES[pi];
        let cursor: string | null = phase === startPhase ? startAfter : null;
        let count = 0;
        // eslint-disable-next-line no-constant-condition
        while (true) {
          if (Date.now() - started > budget) {
            outOfTime = true;
            report.nextCursor = { phase, startingAfter: cursor };
            break;
          }
          let page: { data: any[]; has_more: boolean };
          try {
            page = await listPage(ctx, phase, cursor, paySince);
          } catch (e: any) {
            pushError(ctx, `${phase} list failed: ${e?.message || e}`);
            break; // next phase
          }
          let capped = false;
          for (const obj of page.data || []) {
            if (count >= RECONCILE_CONFIG.caps[phase]) {
              capped = true;
              break;
            }
            if (Date.now() - started > budget) {
              outOfTime = true;
              break;
            }
            count++;
            report.scanned[phase]++;
            try {
              await handle(ctx, phase, obj, subSince);
            } catch (e: any) {
              pushError(ctx, `${phase} ${obj?.id}: ${e?.message || e}`);
            }
            cursor = obj.id;
          }
          if (outOfTime) {
            report.nextCursor = { phase, startingAfter: cursor };
            break;
          }
          if (capped) {
            report.capped.push(phase);
            break;
          }
          if (!page.has_more || !page.data?.length) break;
        }
      }

      // A Stripe customer paying for several GreenGo uids.
      for (const [customerId, uids] of ctx.customerUids) {
        if (uids.size > 1) {
          await flag(ctx, `customer_multiple_uids_${customerId}`, {
            type: 'customer_multiple_uids', customerId, candidates: [...uids],
          });
        }
      }
    });

    report.complete = report.nextCursor === null;
    if (!opts.dryRun) {
      if (report.nextCursor) {
        await cursorRef.set({ ...report.nextCursor, paySince, subSince, savedAt: ts(stripeCoreDeps.now()), runId });
      } else {
        await cursorRef.set({ phase: null, startingAfter: null, savedAt: ts(stripeCoreDeps.now()), runId, completedAt: ts(stripeCoreDeps.now()) });
      }
    }
  } catch (e: any) {
    report.errorsCount++;
    report.errors.push(`run failed: ${e?.message || e}`.slice(0, 500));
    console.error('[stripeReconcile] run failed', e);
  }

  report.finishedAt = stripeCoreDeps.now().toISOString();
  if (!opts.dryRun && locked) {
    try {
      await fdb().collection('stripe_reconciliation_runs').doc(runId).set({
        ...report,
        startedAt: ts(new Date(report.startedAt)),
        finishedAt: ts(new Date(report.finishedAt)),
      });
    } catch (e: any) {
      console.error('[stripeReconcile] could not write the run report', e);
    }
    if (report.flagsCreated > 0 || report.correctionsCount > 0 || report.errorsCount > 0) {
      try {
        await stripeReconcileDeps.notifyAdmins(report);
      } catch (e: any) {
        console.error('[stripeReconcile] admin notification failed', e);
      }
    }
    try {
      await releaseLock(runId);
    } catch {
      // the lease expires on its own
    }
  }
  console.log(`[stripeReconcile] ${runId} dryRun=${opts.dryRun} complete=${report.complete} ` +
    `scanned=${JSON.stringify(report.scanned)} corrections=${report.correctionsCount} ` +
    `flagsCreated=${report.flagsCreated} errors=${report.errorsCount}`);
  return report;
}

// ---------------------------------------------------------------------------
// Admin notification (existing mechanisms: notifications to admin_users, and
// Resend via app_config/resend_settings when configured)
// ---------------------------------------------------------------------------

async function notifyAdminsDefault(report: ReconcileReport): Promise<void> {
  const db = fdb();
  const admins = await db.collection('admin_users')
    .where('role', 'in', ['super_admin', 'superAdmin', 'admin']).limit(50).get();
  const summary = `Stripe reconciliation ${report.runId}: ${report.correctionsCount} correction(s), ` +
    `${report.flagsCreated} new flag(s), ${report.errorsCount} error(s).`;
  const emails: string[] = [];
  for (const a of admins.docs) {
    const email = a.data()?.email;
    if (typeof email === 'string' && email.includes('@')) emails.push(email);
    await db.collection('notifications').doc(`stripe_reconcile_${report.runId}_${a.id}`).set({
      userId: a.id,
      type: 'stripe_reconciliation',
      title: 'Stripe reconciliation needs review',
      message: summary,
      body: summary,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      read: false,
      priority: report.errorsCount > 0 || report.flagsCreated > 0 ? 'warning' : 'info',
      data: { runId: report.runId, flagsCreated: report.flagsCreated, corrections: report.correctionsCount, errors: report.errorsCount },
    });
  }

  const cfg = (await db.doc('app_config/resend_settings').get()).data();
  if (!cfg?.apiKey || emails.length === 0) return;
  const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c] as string));
  const flagLines = report.flags.slice(0, 50).map((f) => `<li>${esc(f.type)} - ${esc(f.id)}</li>`).join('');
  const corrLines = report.corrections.slice(0, 50)
    .map((c) => `<li>${esc(c.type)} - ${esc(c.objectId)} (${esc(String(c.uid || ''))}) -> ${esc(c.result)}</li>`).join('');
  const errLines = report.errors.slice(0, 20).map((e) => `<li>${esc(e)}</li>`).join('');
  const html = `<p>${esc(summary)}</p>` +
    (flagLines ? `<h3>Flags (collection stripe_payment_flags)</h3><ul>${flagLines}</ul>` : '') +
    (corrLines ? `<h3>Corrections</h3><ul>${corrLines}</ul>` : '') +
    (errLines ? `<h3>Errors</h3><ul>${errLines}</ul>` : '') +
    `<p>Full report: Firestore stripe_reconciliation_runs/${esc(report.runId)}</p>`;
  const resp = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${cfg.apiKey}` },
    body: JSON.stringify({
      from: `${cfg.senderName || 'GreenGo Admin'} <${cfg.senderEmail || 'onboarding@resend.dev'}>`,
      to: [...new Set(emails)],
      subject: `GreenGo - Stripe reconciliation: ${report.flagsCreated} flag(s), ${report.correctionsCount} correction(s)`,
      html,
    }),
  });
  if (!resp.ok) console.error(`[stripeReconcile] Resend ${resp.status}: ${await resp.text()}`);
}

// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------

export const reconcileStripeMemberships = onSchedule(
  {
    schedule: 'every 12 hours',
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
    secrets: ['STRIPE_SECRET_KEY'],
  },
  async () => {
    try {
      await runStripeReconciliation({ dryRun: false, trigger: 'schedule' });
    } catch (e) {
      console.error('[stripeReconcile] scheduled run failed', e);
    }
  },
);

function tokenOk(given: unknown): boolean {
  const expected = process.env.STRIPE_RECONCILE_TOKEN || '';
  if (!expected || typeof given !== 'string' || given.length === 0) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

export const runStripeReconcileNow = onRequest(
  { memory: '512MiB', timeoutSeconds: 540, secrets: ['STRIPE_SECRET_KEY'] },
  async (req, res) => {
    if (!process.env.STRIPE_RECONCILE_TOKEN) {
      res.status(503).json({ error: 'STRIPE_RECONCILE_TOKEN not configured' });
      return;
    }
    if (!tokenOk(req.query.token)) {
      res.status(403).send('forbidden');
      return;
    }
    const dryRunParam = String(req.query.dryRun ?? '1').toLowerCase();
    const dryRun = !(dryRunParam === '0' || dryRunParam === 'false' || dryRunParam === 'no');
    try {
      const report = await runStripeReconciliation({ dryRun, trigger: 'http' });
      res.status(200).json(report);
    } catch (e: any) {
      res.status(500).json({ error: String(e?.message || e) });
    }
  },
);
