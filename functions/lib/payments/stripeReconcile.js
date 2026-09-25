"use strict";
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
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.runStripeReconcileNow = exports.reconcileStripeMemberships = exports.stripeReconcileDeps = exports.PHASES = exports.RECONCILE_CONFIG = void 0;
exports.expectedEntitlement = expectedEntitlement;
exports.entitlementDrift = entitlementDrift;
exports.runStripeReconciliation = runStripeReconciliation;
const crypto = __importStar(require("crypto"));
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const stripeCore_1 = require("./stripeCore");
const effectiveTier_1 = require("../shared/effectiveTier");
exports.RECONCILE_CONFIG = {
    subscriptionWindowDays: 45,
    paymentWindowDays: 14,
    pageSize: 100,
    budgetMs: 480000,
    lockLeaseMs: 600000,
    cursorMaxAgeMs: 3 * stripeCore_1.DAY_MS,
    caps: {
        subscriptions: 5000,
        invoices: 5000,
        sessions: 5000,
        charges: 5000,
        refunds: 2000,
        disputes: 2000,
    },
    maxReportItems: 300,
};
exports.PHASES = ['subscriptions', 'invoices', 'sessions', 'charges', 'refunds', 'disputes'];
// Overridable in tests.
exports.stripeReconcileDeps = {
    notifyAdmins: (report) => notifyAdminsDefault(report),
};
const fdb = () => stripeCore_1.stripeCoreDeps.db();
const ts = (d) => admin.firestore.Timestamp.fromDate(d);
const LIVE_SUB_STATUSES = ['active', 'trialing', 'past_due'];
const TERMINAL_SUB_STATUSES = ['canceled', 'incomplete_expired'];
/** From a subscription with `latest_invoice` (and its `charge`) expanded. */
function expectedEntitlement(sub, now) {
    var _a;
    const productId = String(((_a = sub === null || sub === void 0 ? void 0 : sub.metadata) === null || _a === void 0 ? void 0 : _a.productId) || '');
    const mem = stripeCore_1.MEMBERSHIP_PRODUCTS[productId];
    const inv = (sub === null || sub === void 0 ? void 0 : sub.latest_invoice) && typeof sub.latest_invoice === 'object' ? sub.latest_invoice : null;
    const charge = (inv === null || inv === void 0 ? void 0 : inv.charge) && typeof inv.charge === 'object' ? inv.charge : null;
    const paid = (inv === null || inv === void 0 ? void 0 : inv.status) === 'paid';
    const reversed = !!charge && (charge.refunded === true || charge.disputed === true);
    const period = paid ? (0, stripeCore_1.linePaidPeriod)((0, stripeCore_1.subscriptionLineOf)(inv, sub.id)) : null;
    const paidThrough = paid && !reversed && period ? period.end : null;
    return {
        known: !!mem,
        productId,
        tier: (mem === null || mem === void 0 ? void 0 : mem.tier) || '',
        base: productId === 'greengo_base_membership',
        shouldBeActive: !!mem && LIVE_SUB_STATUSES.includes(sub.status) && !!paidThrough && paidThrough > now,
        paidThrough,
        invoiceId: (inv === null || inv === void 0 ? void 0 : inv.id) || null,
        reversed,
    };
}
function liveClass(status) {
    return status === 'active' || status === 'trialing';
}
/** Compares a profile with Stripe truth for ONE subscription. */
function entitlementDrift(profile, sub, exp, now) {
    var _a, _b, _c, _d, _e, _f, _g;
    if (!exp.known)
        return [];
    const out = [];
    const f = (0, stripeCore_1.subFields)(exp.productId);
    const onFile = profile[f.id] === sub.id;
    const terminal = TERMINAL_SUB_STATUSES.includes(sub.status);
    const overLimit = (exp.paidThrough ? exp.paidThrough.getTime() : now.getTime()) + stripeCore_1.RENEWAL_GRACE_MS + 2 * stripeCore_1.DAY_MS;
    if (exp.base) {
        const end = (0, effectiveTier_1.tierDateFromValue)(profile.baseMembershipEndDate);
        if (exp.shouldBeActive) {
            const ok = profile.hasBaseMembership === true && !!end && end >= exp.paidThrough;
            if (!ok || !onFile)
                out.push({ type: 'missing_grant', detail: { hasBase: profile.hasBaseMembership === true, end: (_a = end === null || end === void 0 ? void 0 : end.toISOString()) !== null && _a !== void 0 ? _a : null } });
        }
        if (onFile && profile.hasBaseMembership === true && end && end.getTime() > overLimit) {
            out.push({ type: 'over_entitlement', detail: { end: end.toISOString(), paidThrough: (_c = (_b = exp.paidThrough) === null || _b === void 0 ? void 0 : _b.toISOString()) !== null && _c !== void 0 ? _c : null } });
        }
    }
    else {
        const end = (0, effectiveTier_1.tierDateFromValue)(profile.membershipEndDate);
        const stored = (0, effectiveTier_1.normalizeStoredTier)(profile.membershipTier);
        const eff = (0, effectiveTier_1.effectiveTier)(profile, now);
        const higherElsewhere = (0, effectiveTier_1.hasActivePaidTier)(profile, now) && (0, effectiveTier_1.tierRank)(eff) > (0, effectiveTier_1.tierRank)(exp.tier);
        if (exp.shouldBeActive) {
            const ok = higherElsewhere || (stored === exp.tier && !!end && end >= exp.paidThrough && onFile);
            if (!ok)
                out.push({ type: 'missing_grant', detail: { tier: stored, end: (_d = end === null || end === void 0 ? void 0 : end.toISOString()) !== null && _d !== void 0 ? _d : null, onFile } });
        }
        if (onFile && !higherElsewhere && stored === exp.tier && profile.membershipSource === 'stripe'
            && end && end.getTime() > overLimit) {
            out.push({ type: 'over_entitlement', detail: { end: end.toISOString(), paidThrough: (_f = (_e = exp.paidThrough) === null || _e === void 0 ? void 0 : _e.toISOString()) !== null && _f !== void 0 ? _f : null } });
        }
    }
    if (onFile && terminal) {
        out.push({ type: 'ended_not_applied', detail: { status: sub.status } });
    }
    else if (onFile && liveClass(profile[f.status]) !== liveClass(sub.status)) {
        out.push({ type: 'status_mismatch', detail: { profile: (_g = profile[f.status]) !== null && _g !== void 0 ? _g : null, stripe: sub.status } });
    }
    return out;
}
function pushCorrection(ctx, c) {
    ctx.report.correctionsCount++;
    if (ctx.report.corrections.length < exports.RECONCILE_CONFIG.maxReportItems)
        ctx.report.corrections.push(c);
}
function pushError(ctx, msg) {
    ctx.report.errorsCount++;
    console.error(`[stripeReconcile] ${msg}`);
    if (ctx.report.errors.length < exports.RECONCILE_CONFIG.maxReportItems)
        ctx.report.errors.push(msg.slice(0, 500));
}
function noteCustomerUid(ctx, customerId, uids) {
    if (!customerId)
        return;
    const set = ctx.customerUids.get(customerId) || new Set();
    uids.forEach((u) => set.add(u));
    ctx.customerUids.set(customerId, set);
}
async function flag(ctx, id, data) {
    await (0, stripeCore_1.createPaymentFlag)(id, Object.assign(Object.assign({}, data), { source: 'reconcile' }), ctx.dryRun);
}
const APPLIED_ACTIONS = ['granted', 'updated', 'would_grant', 'ended', 'would_end', 'revoked', 'would_revoke', 'flagged'];
async function handleSubscription(ctx, sub) {
    var _a, _b;
    const exp = expectedEntitlement(sub, ctx.now);
    const customerId = (0, stripeCore_1.idOf)(sub.customer);
    if (!exp.known) {
        if (LIVE_SUB_STATUSES.includes(sub.status)) {
            await flag(ctx, `unknown_product_sub_${sub.id}`, {
                type: 'unknown_product', subscriptionId: sub.id, customerId, product: exp.productId || null,
            });
        }
        return;
    }
    const who = await (0, stripeCore_1.resolveStripeUid)(ctx.stripe, {
        customer: sub.customer, claimedUid: ((_a = sub.metadata) === null || _a === void 0 ? void 0 : _a.userId) || null, livemode: sub.livemode,
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
            const r = await (0, stripeCore_1.processPaidInvoice)(ctx.stripe, exp.invoiceId, { source: 'reconcile', force: true, dryRun: ctx.dryRun });
            if (APPLIED_ACTIONS.includes(r.action)) {
                pushCorrection(ctx, { type: 'missing_grant', uid, objectId: sub.id, result: r.action, detail: { invoiceId: exp.invoiceId, before: d.detail, after: r.detail } });
            }
        }
        else if (d.type === 'ended_not_applied') {
            const r = await (0, stripeCore_1.processSubscriptionEnded)(ctx.stripe, sub.id, { dryRun: ctx.dryRun });
            if (APPLIED_ACTIONS.includes(r.action)) {
                pushCorrection(ctx, { type: 'subscription_end', uid, objectId: sub.id, result: r.action, detail: r.detail });
            }
        }
        else if (d.type === 'status_mismatch') {
            const f = (0, stripeCore_1.subFields)(exp.productId);
            if (!ctx.dryRun) {
                await fdb().collection('profiles').doc(uid).set({ [f.status]: sub.status, updatedAt: ts(ctx.now) }, { merge: true });
            }
            pushCorrection(ctx, { type: 'status_sync', uid, objectId: sub.id, result: ctx.dryRun ? 'would_update' : 'updated', detail: d.detail });
        }
        else if (d.type === 'over_entitlement') {
            await flag(ctx, `over_entitlement_${sub.id}`, Object.assign({ type: 'over_entitlement', uid, subscriptionId: sub.id, product: exp.productId }, d.detail));
        }
    }
    // Upgrade whose old subscription was never cancelled (e.g. the cancel call
    // failed after the new first invoice was paid).
    const replaces = (_b = sub.metadata) === null || _b === void 0 ? void 0 : _b.replacesSubscriptionId;
    if (replaces && exp.shouldBeActive) {
        const r = await (0, stripeCore_1.cancelReplacedSubscription)(ctx.stripe, sub, replaces, ctx.dryRun);
        if (r === 'cancelled' || r === 'would_cancel') {
            pushCorrection(ctx, { type: 'replaced_subscription_cancel', uid, objectId: replaces, result: r, detail: { newSubscription: sub.id } });
        }
        else if (r.startsWith('error:')) {
            pushError(ctx, `cancel replaced ${replaces}: ${r}`);
        }
    }
}
async function handleInvoice(ctx, inv) {
    const subId = (0, stripeCore_1.invoiceSubscriptionId)(inv);
    if (!subId || inv.status !== 'paid')
        return;
    if (await (0, stripeCore_1.invoiceApplied)(inv.id))
        return;
    const r = await (0, stripeCore_1.processPaidInvoice)(ctx.stripe, inv.id, { source: 'reconcile', dryRun: ctx.dryRun });
    if (APPLIED_ACTIONS.includes(r.action)) {
        pushCorrection(ctx, { type: 'missed_invoice_paid', uid: r.uid, objectId: inv.id, result: r.action, detail: r.detail });
    }
}
async function handleSession(ctx, s) {
    if (s.status !== 'complete' || s.mode !== 'payment' || s.payment_status !== 'paid')
        return;
    if (s.payment_intent)
        ctx.sessionByPi.set((0, stripeCore_1.idOf)(s.payment_intent), s);
    if (await (0, stripeCore_1.orderExists)(s.id))
        return;
    const r = await (0, stripeCore_1.processCheckoutSession)(ctx.stripe, s.id, { source: 'reconcile', dryRun: ctx.dryRun });
    if (APPLIED_ACTIONS.includes(r.action)) {
        pushCorrection(ctx, { type: 'missed_coin_grant', uid: r.uid, objectId: s.id, result: r.action, detail: r.detail });
    }
}
async function subscriptionFor(ctx, subId) {
    if (ctx.subCache.has(subId))
        return ctx.subCache.get(subId);
    let sub = null;
    try {
        sub = await ctx.stripe.subscriptions.retrieve(subId);
    }
    catch (_a) {
        sub = null;
    }
    ctx.subCache.set(subId, sub);
    return sub;
}
async function sessionForPaymentIntent(ctx, pi) {
    var _a;
    if (!pi)
        return null;
    if (ctx.sessionByPi.has(pi))
        return ctx.sessionByPi.get(pi);
    let s = null;
    try {
        const list = await ctx.stripe.checkout.sessions.list({ payment_intent: pi, limit: 1 });
        s = ((_a = list.data) === null || _a === void 0 ? void 0 : _a[0]) || null;
    }
    catch (_b) {
        s = null;
    }
    ctx.sessionByPi.set(pi, s);
    return s;
}
/** Payer email / uid / amount checks for one paid charge. Flags only. */
async function handleCharge(ctx, ch) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
    if (ch.status !== 'succeeded' || ch.paid !== true)
        return;
    const inv = ch.invoice && typeof ch.invoice === 'object' ? ch.invoice : null;
    const subId = inv ? (0, stripeCore_1.invoiceSubscriptionId)(inv) : null;
    let claimedUid = null;
    let product = null;
    if (subId) {
        const meta = ((_a = inv === null || inv === void 0 ? void 0 : inv.subscription_details) === null || _a === void 0 ? void 0 : _a.metadata) || ((_b = (await subscriptionFor(ctx, subId))) === null || _b === void 0 ? void 0 : _b.metadata) || {};
        claimedUid = meta.userId || null;
        product = meta.productId || null;
    }
    else {
        const s = await sessionForPaymentIntent(ctx, (0, stripeCore_1.idOf)(ch.payment_intent));
        claimedUid = ((_c = s === null || s === void 0 ? void 0 : s.metadata) === null || _c === void 0 ? void 0 : _c.userId) || ((_d = ch.metadata) === null || _d === void 0 ? void 0 : _d.userId) || null;
        product = ((_e = s === null || s === void 0 ? void 0 : s.metadata) === null || _e === void 0 ? void 0 : _e.productId) || ((_f = ch.metadata) === null || _f === void 0 ? void 0 : _f.productId) || null;
    }
    const customer = ch.customer && typeof ch.customer === 'object' ? ch.customer : null;
    const customerId = (0, stripeCore_1.idOf)(ch.customer);
    const who = await (0, stripeCore_1.resolveStripeUid)(ctx.stripe, { customer: ch.customer, claimedUid, livemode: ch.livemode });
    noteCustomerUid(ctx, customerId, who.candidates);
    const base = {
        chargeId: ch.id, customerId, amount: (_g = ch.amount) !== null && _g !== void 0 ? _g : null, currency: (_h = ch.currency) !== null && _h !== void 0 ? _h : null,
        product, livemode: ch.livemode === true, chargeCreated: ch.created ? new Date(ch.created * 1000).toISOString() : null,
    };
    // Amount / currency vs the price table.
    const currency = String(ch.currency || '').toLowerCase();
    if (!product || (!stripeCore_1.COIN_PACKAGES[product] && !stripeCore_1.MEMBERSHIP_PRODUCTS[product])) {
        await flag(ctx, `unknown_product_${ch.id}`, Object.assign({ type: 'unknown_product', uid: who.uid }, base));
    }
    else if (stripeCore_1.COIN_PACKAGES[product]) {
        if ((0, stripeCore_1.listPriceCents)(stripeCore_1.COIN_PACKAGES[product], currency) !== ch.amount) {
            await flag(ctx, `amount_mismatch_${ch.id}`, Object.assign({ type: 'amount_mismatch', uid: who.uid, expected: (0, stripeCore_1.listPriceCents)(stripeCore_1.COIN_PACKAGES[product], currency) }, base));
        }
    }
    else {
        const allowed = (0, stripeCore_1.allowedMembershipAmounts)(product, currency);
        // A membership charge can be lower than the price (credit balance), never higher.
        if (allowed.length === 0 || ch.amount <= 0 || ch.amount > Math.max(...allowed)) {
            await flag(ctx, `amount_mismatch_${ch.id}`, Object.assign({ type: 'amount_mismatch', uid: who.uid, expected: allowed }, base));
        }
    }
    if (!who.uid) {
        const conflict = who.reason === 'conflict';
        await flag(ctx, conflict ? `customer_multiple_uids_${customerId}` : `unresolved_${ch.id}`, Object.assign({ type: conflict ? 'customer_multiple_uids' : 'unresolved_payment', reason: who.reason, candidates: who.candidates }, base));
        return;
    }
    // EMAIL CHECK: payer vs GreenGo account.
    const uid = who.uid;
    const [authEmail, profileSnap] = await Promise.all([
        stripeCore_1.stripeCoreDeps.getUserEmail(uid),
        fdb().collection('profiles').doc(uid).get(),
    ]);
    const profileEmail = ((_j = profileSnap.data()) === null || _j === void 0 ? void 0 : _j.email) || null;
    const payerEmails = [(_k = ch.billing_details) === null || _k === void 0 ? void 0 : _k.email, ch.receipt_email, (_l = customer === null || customer === void 0 ? void 0 : customer.email) !== null && _l !== void 0 ? _l : who.customerEmail, inv === null || inv === void 0 ? void 0 : inv.customer_email]
        .filter((e) => typeof e === 'string' && e.trim() !== '');
    const mismatched = (0, stripeCore_1.mismatchedPayerEmails)([authEmail, profileEmail], payerEmails);
    if (mismatched.length > 0) {
        await flag(ctx, ch.id, Object.assign({ type: 'email_mismatch', uid, accountEmail: authEmail, profileEmail, payerEmails: [...new Set(payerEmails.map((e) => String(e).trim()))], mismatched }, base));
    }
}
async function handleRefund(ctx, r) {
    var _a, _b;
    const chargeId = (0, stripeCore_1.idOf)(r.charge);
    if (!chargeId || r.status !== 'succeeded' || ctx.refundedCharges.has(chargeId))
        return;
    ctx.refundedCharges.add(chargeId);
    if ((await fdb().collection('stripe_revocations').doc(`refund_${chargeId}`).get()).exists)
        return;
    const out = await (0, stripeCore_1.processChargeReversal)(ctx.stripe, { kind: 'refund', chargeId }, { dryRun: ctx.dryRun, source: 'reconcile' });
    if (out.reason === 'partial_refund') {
        await flag(ctx, `partial_refund_${chargeId}`, { type: 'partial_refund', chargeId, refundId: r.id, amount: (_a = r.amount) !== null && _a !== void 0 ? _a : null, currency: (_b = r.currency) !== null && _b !== void 0 ? _b : null });
    }
    else if (APPLIED_ACTIONS.includes(out.action)) {
        pushCorrection(ctx, { type: 'missed_refund', uid: out.uid, objectId: chargeId, result: out.action, detail: out.detail });
    }
}
async function handleDispute(ctx, d) {
    const chargeId = (0, stripeCore_1.idOf)(d.charge);
    if (!chargeId)
        return;
    if ((await fdb().collection('stripe_revocations').doc(`dispute_${d.id}`).get()).exists)
        return;
    const out = await (0, stripeCore_1.processChargeReversal)(ctx.stripe, { kind: 'dispute', chargeId, disputeId: d.id }, { dryRun: ctx.dryRun, source: 'reconcile' });
    if (APPLIED_ACTIONS.includes(out.action)) {
        pushCorrection(ctx, { type: 'missed_dispute', uid: out.uid, objectId: d.id, result: out.action, detail: out.detail });
    }
}
async function listPage(ctx, phase, startingAfter, since) {
    const common = Object.assign({ limit: exports.RECONCILE_CONFIG.pageSize }, (startingAfter ? { starting_after: startingAfter } : {}));
    const created = { gte: since };
    const s = ctx.stripe;
    switch (phase) {
        case 'subscriptions':
            return s.subscriptions.list(Object.assign(Object.assign({}, common), { status: 'all', expand: ['data.customer', 'data.latest_invoice.charge'] }));
        case 'invoices':
            return s.invoices.list(Object.assign(Object.assign({}, common), { created }));
        case 'sessions':
            return s.checkout.sessions.list(Object.assign(Object.assign({}, common), { created }));
        case 'charges':
            return s.charges.list(Object.assign(Object.assign({}, common), { created, expand: ['data.customer', 'data.invoice'] }));
        case 'refunds':
            return s.refunds.list(Object.assign(Object.assign({}, common), { created }));
        case 'disputes':
            return s.disputes.list(Object.assign(Object.assign({}, common), { created }));
    }
}
async function handle(ctx, phase, obj, subSince) {
    switch (phase) {
        case 'subscriptions': {
            if (TERMINAL_SUB_STATUSES.includes(obj.status)) {
                const endedAt = obj.ended_at || obj.canceled_at || obj.created || 0;
                if (endedAt < subSince)
                    return;
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
function newRunId(now) {
    return `${now.toISOString().replace(/[-:.]/g, '').slice(0, 15)}_${crypto.randomBytes(3).toString('hex')}`;
}
async function acquireLock(runId, now) {
    const ref = fdb().collection('stripe_reconcile_state').doc('lock');
    return fdb().runTransaction(async (tx) => {
        const d = (await tx.get(ref)).data();
        const lease = (0, effectiveTier_1.tierDateFromValue)(d === null || d === void 0 ? void 0 : d.leaseUntil);
        if ((d === null || d === void 0 ? void 0 : d.runId) && lease && lease > now)
            return false;
        tx.set(ref, { runId, leaseUntil: ts(new Date(now.getTime() + exports.RECONCILE_CONFIG.lockLeaseMs)), acquiredAt: ts(now) });
        return true;
    });
}
async function releaseLock(runId) {
    const ref = fdb().collection('stripe_reconcile_state').doc('lock');
    await fdb().runTransaction(async (tx) => {
        const d = (await tx.get(ref)).data();
        if ((d === null || d === void 0 ? void 0 : d.runId) === runId)
            tx.set(ref, { runId: null, leaseUntil: null, releasedAt: ts(stripeCore_1.stripeCoreDeps.now()) });
    });
}
/** One reconciliation pass. Never throws. */
async function runStripeReconciliation(opts) {
    var _a, _b;
    const started = Date.now();
    const now = stripeCore_1.stripeCoreDeps.now();
    const budget = (_a = opts.budgetMs) !== null && _a !== void 0 ? _a : exports.RECONCILE_CONFIG.budgetMs;
    const runId = newRunId(now);
    const report = {
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
                report.finishedAt = stripeCore_1.stripeCoreDeps.now().toISOString();
                return report;
            }
        }
        const stripe = (_b = opts.stripe) !== null && _b !== void 0 ? _b : (0, stripeCore_1.getStripe)(false);
        const ctx = {
            stripe, dryRun: opts.dryRun, now, report,
            customerUids: new Map(), subCache: new Map(), sessionByPi: new Map(), refundedCharges: new Set(),
        };
        // Resume point (real runs only; a dry run always scans from the top).
        const cursorRef = fdb().collection('stripe_reconcile_state').doc('cursor');
        let paySince = Math.floor((now.getTime() - exports.RECONCILE_CONFIG.paymentWindowDays * stripeCore_1.DAY_MS) / 1000);
        let subSince = Math.floor((now.getTime() - exports.RECONCILE_CONFIG.subscriptionWindowDays * stripeCore_1.DAY_MS) / 1000);
        let startPhase = exports.PHASES[0];
        let startAfter = null;
        if (!opts.dryRun) {
            const c = (await cursorRef.get()).data();
            const savedAt = (0, effectiveTier_1.tierDateFromValue)(c === null || c === void 0 ? void 0 : c.savedAt);
            if ((c === null || c === void 0 ? void 0 : c.phase) && exports.PHASES.includes(c.phase) && savedAt && now.getTime() - savedAt.getTime() < exports.RECONCILE_CONFIG.cursorMaxAgeMs) {
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
        const observer = (id, data, result) => {
            if (result === 'created')
                report.flagsCreated++;
            if (result === 'would_create')
                report.flagsWouldCreate++;
            if (result !== 'exists' && report.flags.length < exports.RECONCILE_CONFIG.maxReportItems) {
                report.flags.push({ id, type: String(data.type || 'unknown'), result });
            }
        };
        await stripeCore_1.flagObserver.run(observer, async () => {
            var _a;
            let outOfTime = false;
            for (let pi = exports.PHASES.indexOf(startPhase); pi < exports.PHASES.length && !outOfTime; pi++) {
                const phase = exports.PHASES[pi];
                let cursor = phase === startPhase ? startAfter : null;
                let count = 0;
                // eslint-disable-next-line no-constant-condition
                while (true) {
                    if (Date.now() - started > budget) {
                        outOfTime = true;
                        report.nextCursor = { phase, startingAfter: cursor };
                        break;
                    }
                    let page;
                    try {
                        page = await listPage(ctx, phase, cursor, paySince);
                    }
                    catch (e) {
                        pushError(ctx, `${phase} list failed: ${(e === null || e === void 0 ? void 0 : e.message) || e}`);
                        break; // next phase
                    }
                    let capped = false;
                    for (const obj of page.data || []) {
                        if (count >= exports.RECONCILE_CONFIG.caps[phase]) {
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
                        }
                        catch (e) {
                            pushError(ctx, `${phase} ${obj === null || obj === void 0 ? void 0 : obj.id}: ${(e === null || e === void 0 ? void 0 : e.message) || e}`);
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
                    if (!page.has_more || !((_a = page.data) === null || _a === void 0 ? void 0 : _a.length))
                        break;
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
                await cursorRef.set(Object.assign(Object.assign({}, report.nextCursor), { paySince, subSince, savedAt: ts(stripeCore_1.stripeCoreDeps.now()), runId }));
            }
            else {
                await cursorRef.set({ phase: null, startingAfter: null, savedAt: ts(stripeCore_1.stripeCoreDeps.now()), runId, completedAt: ts(stripeCore_1.stripeCoreDeps.now()) });
            }
        }
    }
    catch (e) {
        report.errorsCount++;
        report.errors.push(`run failed: ${(e === null || e === void 0 ? void 0 : e.message) || e}`.slice(0, 500));
        console.error('[stripeReconcile] run failed', e);
    }
    report.finishedAt = stripeCore_1.stripeCoreDeps.now().toISOString();
    if (!opts.dryRun && locked) {
        try {
            await fdb().collection('stripe_reconciliation_runs').doc(runId).set(Object.assign(Object.assign({}, report), { startedAt: ts(new Date(report.startedAt)), finishedAt: ts(new Date(report.finishedAt)) }));
        }
        catch (e) {
            console.error('[stripeReconcile] could not write the run report', e);
        }
        if (report.flagsCreated > 0 || report.correctionsCount > 0 || report.errorsCount > 0) {
            try {
                await exports.stripeReconcileDeps.notifyAdmins(report);
            }
            catch (e) {
                console.error('[stripeReconcile] admin notification failed', e);
            }
        }
        try {
            await releaseLock(runId);
        }
        catch (_c) {
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
async function notifyAdminsDefault(report) {
    var _a;
    const db = fdb();
    const admins = await db.collection('admin_users')
        .where('role', 'in', ['super_admin', 'superAdmin', 'admin']).limit(50).get();
    const summary = `Stripe reconciliation ${report.runId}: ${report.correctionsCount} correction(s), ` +
        `${report.flagsCreated} new flag(s), ${report.errorsCount} error(s).`;
    const emails = [];
    for (const a of admins.docs) {
        const email = (_a = a.data()) === null || _a === void 0 ? void 0 : _a.email;
        if (typeof email === 'string' && email.includes('@'))
            emails.push(email);
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
    if (!(cfg === null || cfg === void 0 ? void 0 : cfg.apiKey) || emails.length === 0)
        return;
    const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
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
    if (!resp.ok)
        console.error(`[stripeReconcile] Resend ${resp.status}: ${await resp.text()}`);
}
// ---------------------------------------------------------------------------
// Functions
// ---------------------------------------------------------------------------
exports.reconcileStripeMemberships = (0, scheduler_1.onSchedule)({
    schedule: 'every 12 hours',
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
    secrets: ['STRIPE_SECRET_KEY'],
}, async () => {
    try {
        await runStripeReconciliation({ dryRun: false, trigger: 'schedule' });
    }
    catch (e) {
        console.error('[stripeReconcile] scheduled run failed', e);
    }
});
function tokenOk(given) {
    const expected = process.env.STRIPE_RECONCILE_TOKEN || '';
    if (!expected || typeof given !== 'string' || given.length === 0)
        return false;
    const a = Buffer.from(given);
    const b = Buffer.from(expected);
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}
exports.runStripeReconcileNow = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 540, secrets: ['STRIPE_SECRET_KEY'] }, async (req, res) => {
    var _a;
    if (!process.env.STRIPE_RECONCILE_TOKEN) {
        res.status(503).json({ error: 'STRIPE_RECONCILE_TOKEN not configured' });
        return;
    }
    if (!tokenOk(req.query.token)) {
        res.status(403).send('forbidden');
        return;
    }
    const dryRunParam = String((_a = req.query.dryRun) !== null && _a !== void 0 ? _a : '1').toLowerCase();
    const dryRun = !(dryRunParam === '0' || dryRunParam === 'false' || dryRunParam === 'no');
    try {
        const report = await runStripeReconciliation({ dryRun, trigger: 'http' });
        res.status(200).json(report);
    }
    catch (e) {
        res.status(500).json({ error: String((e === null || e === void 0 ? void 0 : e.message) || e) });
    }
});
//# sourceMappingURL=stripeReconcile.js.map