"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.EVENT_LEASE_MS = exports.flagObserver = exports.STRIPE_TEST_MODE_EMAILS = exports.MEMBERSHIP_TIER_RANK = exports.UPGRADE_DISCOUNTS = exports.MEMBERSHIP_PRODUCTS = exports.COIN_PACKAGES = exports.BASE_PRODUCT_ID = exports.BASE_TRIAL_DAYS = exports.RENEWAL_GRACE_MS = exports.DAY_MS = exports.STRIPE_API_VERSION = exports.stripeCoreDeps = void 0;
exports.listPriceCents = listPriceCents;
exports.allowedMembershipAmounts = allowedMembershipAmounts;
exports.discountedPriceCents = discountedPriceCents;
exports.subFields = subFields;
exports.isStripeTestModeEmail = isStripeTestModeEmail;
exports.getStripe = getStripe;
exports.idOf = idOf;
exports.invoiceSubscriptionId = invoiceSubscriptionId;
exports.subscriptionLineOf = subscriptionLineOf;
exports.linePaidPeriod = linePaidPeriod;
exports.lineUnitAmount = lineUnitAmount;
exports.subscriptionPeriodEnd = subscriptionPeriodEnd;
exports.normalizeEmail = normalizeEmail;
exports.mismatchedPayerEmails = mismatchedPayerEmails;
exports.validatePaidInvoice = validatePaidInvoice;
exports.validateCoinSession = validateCoinSession;
exports.createPaymentFlag = createPaymentFlag;
exports.resolveStripeUid = resolveStripeUid;
exports.getOrCreateStripeCustomer = getOrCreateStripeCustomer;
exports.orderExists = orderExists;
exports.processCheckoutSession = processCheckoutSession;
exports.invoiceApplied = invoiceApplied;
exports.processPaidInvoice = processPaidInvoice;
exports.cancelReplacedSubscription = cancelReplacedSubscription;
exports.paidThroughForSubscription = paidThroughForSubscription;
exports.processSubscriptionUpdated = processSubscriptionUpdated;
exports.processSubscriptionEnded = processSubscriptionEnded;
exports.processInvoicePaymentFailed = processInvoicePaymentFailed;
exports.processChargeReversal = processChargeReversal;
exports.claimStripeEvent = claimStripeEvent;
exports.finishStripeEvent = finishStripeEvent;
exports.dispatchStripeEvent = dispatchStripeEvent;
exports.handleStripeWebhookHttp = handleStripeWebhookHttp;
const async_hooks_1 = require("async_hooks");
const admin = __importStar(require("firebase-admin"));
const stripe_1 = __importDefault(require("stripe"));
const utils_1 = require("../shared/utils");
const effectiveTier_1 = require("../shared/effectiveTier");
const membershipExpiry_1 = require("../shared/membershipExpiry");
// ---------------------------------------------------------------------------
// Dependencies (overridable in unit tests; production uses the defaults)
// ---------------------------------------------------------------------------
exports.stripeCoreDeps = {
    db: () => utils_1.db,
    getUserEmail: async (uid) => {
        try {
            return (await admin.auth().getUser(uid)).email || null;
        }
        catch (_a) {
            return null;
        }
    },
    now: () => new Date(),
    downgradeTierNow: (uid, reason) => (0, membershipExpiry_1.downgradeTierNow)(uid, reason, true),
    stripe: (testMode) => createStripeClient(testMode),
    webhooks: () => new stripe_1.default('sk_webhook_verify_only', {
        apiVersion: exports.STRIPE_API_VERSION,
    }).webhooks,
};
const fdb = () => exports.stripeCoreDeps.db();
const nowDate = () => exports.stripeCoreDeps.now();
const ts = (d) => admin.firestore.Timestamp.fromDate(d);
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
exports.STRIPE_API_VERSION = '2023-10-16';
exports.DAY_MS = 24 * 60 * 60 * 1000;
/** Added to the paid period end on every paid invoice. See file header. */
exports.RENEWAL_GRACE_MS = exports.DAY_MS;
/** Base trial length offered at checkout (Base only, first subscription). */
exports.BASE_TRIAL_DAYS = 7;
exports.BASE_PRODUCT_ID = 'greengo_base_membership';
exports.COIN_PACKAGES = {
    'greengo_coins_100': { coins: 100, priceUsd: 99, priceEur: 99, priceBrl: 590, name: 'Starter - 100 Coins' },
    'greengo_coins_500': { coins: 500, priceUsd: 399, priceEur: 399, priceBrl: 1990, name: 'Popular - 500 Coins' },
    'greengo_coins_1000': { coins: 1000, priceUsd: 699, priceEur: 699, priceBrl: 3490, name: 'Value - 1,000 Coins' },
    'greengo_coins_5000': { coins: 5000, priceUsd: 2999, priceEur: 2999, priceBrl: 14990, name: 'Premium - 5,000 Coins' },
};
exports.MEMBERSHIP_PRODUCTS = {
    'greengo_base_membership': { name: 'Base Membership', priceUsd: 499, priceEur: 499, priceBrl: 2490, interval: 'year', intervalCount: 1, tier: 'BASE' },
    '1_month_silver': { name: 'Silver (Monthly)', priceUsd: 999, priceEur: 999, priceBrl: 4990, interval: 'month', intervalCount: 1, tier: 'SILVER' },
    '1_month_gold': { name: 'Gold (Monthly)', priceUsd: 1999, priceEur: 1999, priceBrl: 9990, interval: 'month', intervalCount: 1, tier: 'GOLD' },
    '1_month_platinum': { name: 'Platinum (Monthly)', priceUsd: 2999, priceEur: 2999, priceBrl: 14990, interval: 'month', intervalCount: 1, tier: 'PLATINUM' },
    '1_year_silver': { name: 'Silver (Yearly)', priceUsd: 4899, priceEur: 4899, priceBrl: 24990, interval: 'year', intervalCount: 1, tier: 'SILVER' },
    '1_year_gold': { name: 'Gold (Yearly)', priceUsd: 6999, priceEur: 6999, priceBrl: 34990, interval: 'year', intervalCount: 1, tier: 'GOLD' },
    '1_year_platinum_membership': { name: 'Platinum (Yearly)', priceUsd: 8999, priceEur: 8999, priceBrl: 44990, interval: 'year', intervalCount: 1, tier: 'PLATINUM' },
};
/** Upgrade discounts (from tier -> to tier -> fraction), matching Google Play. */
exports.UPGRADE_DISCOUNTS = {
    'SILVER': { 'GOLD': 0.10, 'PLATINUM': 0.15 },
    'GOLD': { 'PLATINUM': 0.10 },
};
exports.MEMBERSHIP_TIER_RANK = {
    BASE: 0, SILVER: 1, GOLD: 2, PLATINUM: 3,
};
/** List price in minor units for a currency, or null for an unsupported one. */
function listPriceCents(p, currency) {
    switch ((currency || '').toLowerCase()) {
        case 'usd': return p.priceUsd;
        case 'eur': return p.priceEur;
        case 'brl': return p.priceBrl;
        default: return null;
    }
}
/** Every unit amount the checkout can legitimately charge for a membership. */
function allowedMembershipAmounts(productId, currency) {
    const mem = exports.MEMBERSHIP_PRODUCTS[productId];
    if (!mem)
        return [];
    const list = listPriceCents(mem, currency);
    if (list === null)
        return [];
    const out = new Set([list]);
    for (const to of Object.values(exports.UPGRADE_DISCOUNTS)) {
        const d = to[mem.tier];
        if (d)
            out.add(Math.round(list * (1 - d)));
    }
    return [...out];
}
function discountedPriceCents(list, discount) {
    return discount > 0 ? Math.round(list * (1 - discount)) : list;
}
/** Base and paid tiers are parallel subscriptions with their own profile fields. */
function subFields(productId) {
    const base = productId === exports.BASE_PRODUCT_ID;
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
exports.STRIPE_TEST_MODE_EMAILS = [
    'mauro.tommasi@live.it',
];
function isStripeTestModeEmail(email) {
    if (!email)
        return false;
    return exports.STRIPE_TEST_MODE_EMAILS.includes(email.trim().toLowerCase());
}
function createStripeClient(testMode) {
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
    return new stripe_1.default(secretKey, {
        apiVersion: exports.STRIPE_API_VERSION,
        maxNetworkRetries: 2,
        timeout: 20000,
    });
}
function getStripe(testMode = false) {
    return exports.stripeCoreDeps.stripe(testMode);
}
// ---------------------------------------------------------------------------
// Pure helpers (shape-tolerant across API versions)
// ---------------------------------------------------------------------------
function idOf(x) {
    if (!x)
        return null;
    if (typeof x === 'string')
        return x;
    return typeof x.id === 'string' ? x.id : null;
}
/** Subscription id of an invoice (old `subscription`, new `parent.subscription_details`). */
function invoiceSubscriptionId(invoice) {
    var _a, _b, _c, _d, _e, _f, _g;
    const modern = (_b = (_a = invoice === null || invoice === void 0 ? void 0 : invoice.parent) === null || _a === void 0 ? void 0 : _a.subscription_details) === null || _b === void 0 ? void 0 : _b.subscription;
    if (modern)
        return idOf(modern);
    const legacy = invoice === null || invoice === void 0 ? void 0 : invoice.subscription;
    if (legacy)
        return idOf(legacy);
    const line = (_d = (_c = invoice === null || invoice === void 0 ? void 0 : invoice.lines) === null || _c === void 0 ? void 0 : _c.data) === null || _d === void 0 ? void 0 : _d[0];
    const fromLine = (_g = (_f = (_e = line === null || line === void 0 ? void 0 : line.parent) === null || _e === void 0 ? void 0 : _e.subscription_item_details) === null || _f === void 0 ? void 0 : _f.subscription) !== null && _g !== void 0 ? _g : line === null || line === void 0 ? void 0 : line.subscription;
    return idOf(fromLine);
}
function lineSubscriptionId(line) {
    var _a, _b, _c;
    return idOf((_a = line === null || line === void 0 ? void 0 : line.subscription) !== null && _a !== void 0 ? _a : (_c = (_b = line === null || line === void 0 ? void 0 : line.parent) === null || _b === void 0 ? void 0 : _b.subscription_item_details) === null || _c === void 0 ? void 0 : _c.subscription);
}
function isProrationLine(line) {
    var _a, _b;
    return (line === null || line === void 0 ? void 0 : line.proration) === true
        || ((_b = (_a = line === null || line === void 0 ? void 0 : line.parent) === null || _a === void 0 ? void 0 : _a.subscription_item_details) === null || _b === void 0 ? void 0 : _b.proration) === true;
}
/** The (non-proration) subscription line of an invoice for `subscriptionId`. */
function subscriptionLineOf(invoice, subscriptionId) {
    var _a;
    const lines = ((_a = invoice === null || invoice === void 0 ? void 0 : invoice.lines) === null || _a === void 0 ? void 0 : _a.data) || [];
    const subLines = lines.filter((l) => ((l === null || l === void 0 ? void 0 : l.type) === 'subscription' || !!lineSubscriptionId(l)) && !isProrationLine(l));
    if (subscriptionId) {
        const exact = subLines.find((l) => lineSubscriptionId(l) === subscriptionId);
        if (exact)
            return exact;
    }
    return subLines[0] || null;
}
function linePaidPeriod(line) {
    var _a, _b;
    const s = (_a = line === null || line === void 0 ? void 0 : line.period) === null || _a === void 0 ? void 0 : _a.start;
    const e = (_b = line === null || line === void 0 ? void 0 : line.period) === null || _b === void 0 ? void 0 : _b.end;
    if (typeof s !== 'number' || typeof e !== 'number' || e <= s)
        return null;
    return { start: new Date(s * 1000), end: new Date(e * 1000) };
}
function lineUnitAmount(line) {
    var _a, _b;
    const unit = (_a = line === null || line === void 0 ? void 0 : line.price) === null || _a === void 0 ? void 0 : _a.unit_amount;
    if (typeof unit === 'number')
        return unit;
    const decimal = (_b = line === null || line === void 0 ? void 0 : line.pricing) === null || _b === void 0 ? void 0 : _b.unit_amount_decimal;
    if (typeof decimal === 'string' && decimal !== '')
        return Math.round(Number(decimal));
    if (typeof (line === null || line === void 0 ? void 0 : line.amount) === 'number')
        return Math.round(line.amount / (line.quantity || 1));
    return null;
}
/** Current period end (unix seconds) across API versions, or null. */
function subscriptionPeriodEnd(subscription) {
    var _a, _b;
    if (subscription === null || subscription === void 0 ? void 0 : subscription.current_period_end)
        return subscription.current_period_end;
    const item = (_b = (_a = subscription === null || subscription === void 0 ? void 0 : subscription.items) === null || _a === void 0 ? void 0 : _a.data) === null || _b === void 0 ? void 0 : _b[0];
    if (item === null || item === void 0 ? void 0 : item.current_period_end)
        return item.current_period_end;
    return null;
}
/**
 * Email normaliser for the payer-vs-account check: trim + lowercase; drops a
 * `+tag` on any domain; for gmail/googlemail also drops dots in the local part
 * and folds googlemail.com into gmail.com.
 */
function normalizeEmail(e) {
    if (typeof e !== 'string')
        return null;
    const s = e.trim().toLowerCase();
    if (!s)
        return null;
    const at = s.lastIndexOf('@');
    if (at <= 0)
        return s;
    let local = s.slice(0, at);
    let domain = s.slice(at + 1);
    const plus = local.indexOf('+');
    if (plus > 0)
        local = local.slice(0, plus);
    if (domain === 'googlemail.com')
        domain = 'gmail.com';
    if (domain === 'gmail.com')
        local = local.replace(/\./g, '');
    return `${local}@${domain}`;
}
/**
 * Payer emails that do not match any account email (normalised). Empty result
 * = consistent. No payer email at all = nothing to compare (empty result).
 */
function mismatchedPayerEmails(accountEmails, payerEmails) {
    const account = new Set(accountEmails.map(normalizeEmail).filter((x) => !!x));
    const seen = new Set();
    const out = [];
    for (const p of payerEmails) {
        const n = normalizeEmail(p);
        if (!n || seen.has(n))
            continue;
        seen.add(n);
        if (!account.has(n))
            out.push(String(p).trim());
    }
    return out;
}
/**
 * Decides what a paid subscription invoice is worth, from Stripe's objects
 * only. `sub.metadata` is server-written at session creation; the amount,
 * currency and interval must match our own price table for that product.
 */
function validatePaidInvoice(invoice, sub) {
    var _a, _b, _c, _d, _e, _f;
    if (!invoice || invoice.status !== 'paid')
        return { ok: false, reason: 'invoice_not_paid' };
    const productId = String(((_a = sub === null || sub === void 0 ? void 0 : sub.metadata) === null || _a === void 0 ? void 0 : _a.productId) || '');
    const mem = exports.MEMBERSHIP_PRODUCTS[productId];
    if (!mem)
        return { ok: false, reason: 'unknown_product', productId };
    const metaTier = String(((_b = sub === null || sub === void 0 ? void 0 : sub.metadata) === null || _b === void 0 ? void 0 : _b.tier) || '').toUpperCase();
    if (metaTier && metaTier !== mem.tier) {
        return { ok: false, reason: 'tier_metadata_mismatch', productId };
    }
    const line = subscriptionLineOf(invoice, idOf(sub));
    if (!line)
        return { ok: false, reason: 'no_subscription_line', productId };
    const period = linePaidPeriod(line);
    if (!period)
        return { ok: false, reason: 'no_paid_period', productId };
    const currency = String(invoice.currency || '').toLowerCase();
    const unitAmount = lineUnitAmount(line);
    const quantity = typeof line.quantity === 'number' ? line.quantity : 1;
    if (quantity !== 1)
        return { ok: false, reason: 'quantity_mismatch', productId, currency };
    if (unitAmount === null || !allowedMembershipAmounts(productId, currency).includes(unitAmount)) {
        return { ok: false, reason: 'amount_mismatch', productId, currency, unitAmount };
    }
    const interval = (_d = (_c = line === null || line === void 0 ? void 0 : line.price) === null || _c === void 0 ? void 0 : _c.recurring) === null || _d === void 0 ? void 0 : _d.interval;
    if (interval && interval !== mem.interval) {
        return { ok: false, reason: 'interval_mismatch', productId, currency, unitAmount };
    }
    const amountPaid = typeof invoice.amount_paid === 'number' ? invoice.amount_paid : 0;
    const periodMs = period.end.getTime() - period.start.getTime();
    const trialEndMs = typeof (sub === null || sub === void 0 ? void 0 : sub.trial_end) === 'number' ? sub.trial_end * 1000 : 0;
    const trial = amountPaid === 0
        && productId === exports.BASE_PRODUCT_ID
        && invoice.billing_reason === 'subscription_create'
        && trialEndMs > 0
        && period.end.getTime() <= trialEndMs + 60000
        && periodMs <= (exports.BASE_TRIAL_DAYS + 1) * exports.DAY_MS;
    // Paid entirely from the customer's credit balance (e.g. upgrade proration
    // credit): total > 0 but nothing charged to a card.
    const paidFromCredit = amountPaid === 0
        && typeof invoice.total === 'number' && invoice.total > 0
        && typeof invoice.starting_balance === 'number' && invoice.starting_balance < 0
        && ((_e = invoice.amount_remaining) !== null && _e !== void 0 ? _e : 0) === 0;
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
        base: productId === exports.BASE_PRODUCT_ID,
        period,
        unitAmount,
        amountPaid,
        currency,
        trial,
        replacesSubscriptionId: ((_f = sub === null || sub === void 0 ? void 0 : sub.metadata) === null || _f === void 0 ? void 0 : _f.replacesSubscriptionId) || null,
    };
}
/** Coins: amount_total + currency + the single line item must match the table. */
function validateCoinSession(session) {
    var _a, _b;
    const productId = String(((_a = session === null || session === void 0 ? void 0 : session.metadata) === null || _a === void 0 ? void 0 : _a.productId) || '');
    const pkg = exports.COIN_PACKAGES[productId];
    if (!pkg)
        return { ok: false, reason: 'unknown_product', productId };
    const currency = String(session.currency || '').toLowerCase();
    const expected = listPriceCents(pkg, currency);
    if (expected === null || session.amount_total !== expected) {
        return { ok: false, reason: 'amount_mismatch', productId, currency, amount: session.amount_total };
    }
    const items = (_b = session === null || session === void 0 ? void 0 : session.line_items) === null || _b === void 0 ? void 0 : _b.data;
    if (items) {
        const total = items.reduce((s, i) => { var _a; return s + ((_a = i.amount_total) !== null && _a !== void 0 ? _a : 0); }, 0);
        const qty = items.reduce((s, i) => { var _a; return s + ((_a = i.quantity) !== null && _a !== void 0 ? _a : 0); }, 0);
        if (items.length !== 1 || qty !== 1 || total !== expected) {
            return { ok: false, reason: 'line_items_mismatch', productId, currency, amount: session.amount_total };
        }
    }
    return { ok: true, productId, coins: pkg.coins, amount: expected, currency };
}
/**
 * Per-run observer (the reconciler collects every flag raised inside the
 * shared paths it calls). AsyncLocalStorage keeps concurrent runs apart.
 */
exports.flagObserver = new async_hooks_1.AsyncLocalStorage();
async function createPaymentFlag(flagId, data, dryRun = false) {
    var _a;
    const id = flagId.replace(/\//g, '_');
    const ref = fdb().collection('stripe_payment_flags').doc(id);
    let result;
    if (dryRun) {
        const snap = await ref.get();
        result = snap.exists ? 'exists' : 'would_create';
    }
    else {
        result = await fdb().runTransaction(async (tx) => {
            const snap = await tx.get(ref);
            if (snap.exists)
                return 'exists';
            tx.create(ref, Object.assign(Object.assign({ status: 'open' }, data), { createdAt: ts(nowDate()) }));
            return 'created';
        });
    }
    try {
        (_a = exports.flagObserver.getStore()) === null || _a === void 0 ? void 0 : _a(id, data, result);
    }
    catch (_b) {
        // observer errors never break a payment path
    }
    return result;
}
/**
 * The GreenGo uid behind a Stripe payment. Sources, all server-written:
 *   claimedUid (subscription / session metadata), the customer's
 *   metadata.firebaseUserId, and the server-only stripe_customers mapping.
 * They must agree. Client-writable profile fields are NOT a source.
 */
async function resolveStripeUid(stripe, opts) {
    var _a;
    const customerId = idOf(opts.customer);
    const candidates = new Set();
    if (opts.claimedUid)
        candidates.add(String(opts.claimedUid));
    let customerEmail = null;
    if (customerId) {
        let cust = typeof opts.customer === 'object' ? opts.customer : null;
        if (!cust || cust.metadata === undefined) {
            try {
                cust = await stripe.customers.retrieve(customerId);
            }
            catch (_b) {
                cust = null;
            }
        }
        if (cust && !cust.deleted) {
            customerEmail = cust.email || null;
            const metaUid = (_a = cust.metadata) === null || _a === void 0 ? void 0 : _a.firebaseUserId;
            if (metaUid)
                candidates.add(String(metaUid));
        }
        const field = opts.livemode === false ? 'testCustomerId' : 'customerId';
        const mapped = await fdb().collection('stripe_customers')
            .where(field, '==', customerId).limit(2).get();
        if (mapped.size === 1)
            candidates.add(mapped.docs[0].id);
        if (mapped.size > 1)
            mapped.docs.forEach((d) => candidates.add(d.id));
    }
    const list = [...candidates];
    if (list.length === 0)
        return { uid: null, reason: 'unresolved', candidates: list, customerEmail };
    if (list.length > 1)
        return { uid: null, reason: 'conflict', candidates: list, customerEmail };
    const profile = await fdb().collection('profiles').doc(list[0]).get();
    if (!profile.exists)
        return { uid: null, reason: 'profile_missing', candidates: list, customerEmail };
    return { uid: list[0], candidates: list, customerEmail };
}
/** Test-mode objects only ever grant to the allow-listed accounts. */
async function testModeAllowed(uid, livemode) {
    if (livemode !== false)
        return true;
    return isStripeTestModeEmail(await exports.stripeCoreDeps.getUserEmail(uid));
}
/**
 * Get or create THIS user's Stripe customer. The uid->customer mapping lives
 * in the server-only stripe_customers/{uid}; a candidate id (including the
 * legacy client-writable profiles.stripeCustomerId) is only reused when the
 * customer's own metadata.firebaseUserId says it belongs to this uid.
 */
async function getOrCreateStripeCustomer(stripe, uid, opts = {}) {
    var _a, _b, _c, _d;
    const testMode = opts.testMode === true;
    const mapField = testMode ? 'testCustomerId' : 'customerId';
    const profileField = testMode ? 'stripeTestCustomerId' : 'stripeCustomerId';
    const mapRef = fdb().collection('stripe_customers').doc(uid);
    const profileRef = fdb().collection('profiles').doc(uid);
    const [mapSnap, profileSnap] = await Promise.all([mapRef.get(), profileRef.get()]);
    const candidates = [(_a = mapSnap.data()) === null || _a === void 0 ? void 0 : _a[mapField], (_b = profileSnap.data()) === null || _b === void 0 ? void 0 : _b[profileField]]
        .filter((x, i, a) => typeof x === 'string' && x.length > 0 && a.indexOf(x) === i);
    for (const candidate of candidates) {
        try {
            const c = await stripe.customers.retrieve(candidate);
            if (!c.deleted && ((_c = c.metadata) === null || _c === void 0 ? void 0 : _c.firebaseUserId) === uid) {
                if (((_d = mapSnap.data()) === null || _d === void 0 ? void 0 : _d[mapField]) !== candidate) {
                    await mapRef.set({ uid, [mapField]: candidate, updatedAt: ts(nowDate()) }, { merge: true });
                }
                return candidate;
            }
            console.warn(`[stripe] customer ${candidate} does not belong to ${uid}; not reusing it`);
        }
        catch (_e) {
            // deleted / unknown: fall through and create
        }
    }
    const customer = await stripe.customers.create(Object.assign(Object.assign({ metadata: { firebaseUserId: uid } }, (opts.email ? { email: opts.email } : {})), (opts.name ? { name: opts.name } : {})));
    await mapRef.set({ uid, [mapField]: customer.id, updatedAt: ts(nowDate()) }, { merge: true });
    // Informational mirror only (client-writable, never trusted).
    await profileRef.set({ [profileField]: customer.id }, { merge: true });
    return customer.id;
}
// ---------------------------------------------------------------------------
// Coins
// ---------------------------------------------------------------------------
async function orderExists(sessionId) {
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
async function processCheckoutSession(stripe, sessionId, opts = { source: 'webhook' }) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const s = await stripe.checkout.sessions.retrieve(sessionId, { expand: ['line_items'] });
    if (s.status !== 'complete')
        return { action: 'ignored', reason: `session_${s.status}` };
    const uidClaim = ((_a = s.metadata) === null || _a === void 0 ? void 0 : _a.userId) || null;
    if (!uidClaim || s.client_reference_id !== uidClaim) {
        await createPaymentFlag(`session_uid_${s.id}`, {
            type: 'session_uid_mismatch', sessionId: s.id,
            metadataUid: uidClaim, clientReferenceId: s.client_reference_id || null,
            amount: (_b = s.amount_total) !== null && _b !== void 0 ? _b : null, currency: (_c = s.currency) !== null && _c !== void 0 ? _c : null, livemode: s.livemode,
        }, opts.dryRun);
        return { action: 'rejected', reason: 'session_uid_mismatch' };
    }
    if (s.mode === 'payment') {
        if (s.payment_status !== 'paid')
            return { action: 'ignored', reason: 'awaiting_payment', uid: uidClaim };
        if (((_d = s.metadata) === null || _d === void 0 ? void 0 : _d.type) !== 'coins')
            return { action: 'rejected', reason: 'unexpected_session_type' };
        const check = validateCoinSession(s);
        const who = await resolveStripeUid(stripe, { customer: s.customer, claimedUid: uidClaim, livemode: s.livemode });
        if (!check.ok || !who.uid) {
            const reason = !check.ok ? check.reason : `uid_${who.reason}`;
            await createPaymentFlag(`session_${reason}_${s.id}`, {
                type: !check.ok ? 'amount_mismatch' : (who.reason === 'conflict' ? 'customer_multiple_uids' : 'unresolved_uid'),
                reason, sessionId: s.id, uid: (_e = who.uid) !== null && _e !== void 0 ? _e : uidClaim, candidates: who.candidates,
                product: check.productId || ((_f = s.metadata) === null || _f === void 0 ? void 0 : _f.productId) || null,
                amount: (_g = s.amount_total) !== null && _g !== void 0 ? _g : null, currency: (_h = s.currency) !== null && _h !== void 0 ? _h : null, livemode: s.livemode,
            }, opts.dryRun);
            return { action: 'rejected', reason, uid: uidClaim };
        }
        const uid = who.uid;
        if (!(await testModeAllowed(uid, s.livemode)))
            return { action: 'rejected', reason: 'test_mode_not_allowed', uid };
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
        if (!subId)
            return { action: 'ignored', reason: 'no_subscription' };
        const sub = await stripe.subscriptions.retrieve(subId, { expand: ['latest_invoice'] });
        const inv = sub.latest_invoice;
        let outcome = { action: 'ignored', reason: 'first_invoice_not_paid', uid: uidClaim };
        if (inv && inv.status === 'paid') {
            outcome = await processPaidInvoice(stripe, idOf(inv), opts);
        }
        const entitled = outcome.action === 'granted' || outcome.action === 'already';
        if (!opts.dryRun && entitled) {
            const orderRef = fdb().collection('stripe_orders').doc(s.id);
            await fdb().runTransaction(async (tx) => {
                var _a, _b, _c;
                const snap = await tx.get(orderRef);
                if (snap.exists)
                    return;
                tx.create(orderRef, {
                    sessionId: s.id, userId: uidClaim, productId: ((_a = s.metadata) === null || _a === void 0 ? void 0 : _a.productId) || null,
                    type: 'membership', amount: (_b = s.amount_total) !== null && _b !== void 0 ? _b : null, currency: (_c = s.currency) !== null && _c !== void 0 ? _c : null,
                    stripeCustomerId: idOf(s.customer), stripeSubscriptionId: subId,
                    status: 'completed', livemode: s.livemode === true, createdAt: ts(nowDate()),
                });
            });
        }
        return outcome;
    }
    return { action: 'ignored', reason: `mode_${s.mode}` };
}
async function grantCoinsForSession(uid, s, check) {
    const db = fdb();
    const orderRef = db.collection('stripe_orders').doc(s.id);
    const legacyQ = db.collection('stripe_orders').where('sessionId', '==', s.id).limit(1);
    const balanceRef = db.collection('coinBalances').doc(uid);
    const txRef = db.collection('coinTransactions').doc(`stripe_${s.id}`);
    const coins = check.coins;
    const applied = await db.runTransaction(async (tx) => {
        const [order, legacy, balance] = await Promise.all([
            tx.get(orderRef), tx.get(legacyQ), tx.get(balanceRef),
        ]);
        if (order.exists || !legacy.empty)
            return false;
        const now = ts(nowDate());
        const batchEntry = {
            batchId: `stripe_${s.id}`,
            initialCoins: coins,
            remainingCoins: coins,
            source: 'purchase',
            acquiredDate: now,
            expirationDate: ts(new Date(nowDate().getTime() + 365 * exports.DAY_MS)),
        };
        const b = balance.exists ? balance.data() : null;
        if (b) {
            tx.set(balanceRef, {
                totalCoins: (b.totalCoins || 0) + coins,
                purchasedCoins: (b.purchasedCoins || 0) + coins,
                lastUpdated: now,
                coinBatches: [...(Array.isArray(b.coinBatches) ? b.coinBatches : []), batchEntry],
            }, { merge: true });
        }
        else {
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
    if (applied)
        console.log(`[stripe] credited ${coins} coins to ${uid} (session ${s.id})`);
    return applied
        ? { action: 'granted', uid, detail: { coins, sessionId: s.id } }
        : { action: 'already', uid, detail: { sessionId: s.id } };
}
// ---------------------------------------------------------------------------
// Membership: paid invoice -> entitlement
// ---------------------------------------------------------------------------
async function invoiceApplied(invoiceId) {
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
async function processPaidInvoice(stripe, invoiceId, opts = { source: 'webhook' }) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const inv = await stripe.invoices.retrieve(invoiceId, { expand: ['charge'] });
    const subId = invoiceSubscriptionId(inv);
    if (!subId)
        return { action: 'ignored', reason: 'not_subscription_invoice' };
    if (inv.status !== 'paid')
        return { action: 'ignored', reason: `invoice_${inv.status}` };
    const sub = await stripe.subscriptions.retrieve(subId);
    const check = validatePaidInvoice(inv, sub);
    const who = await resolveStripeUid(stripe, {
        customer: inv.customer, claimedUid: ((_a = sub.metadata) === null || _a === void 0 ? void 0 : _a.userId) || null, livemode: inv.livemode,
    });
    if (!check.ok || !who.uid) {
        const reason = !check.ok ? check.reason : `uid_${who.reason}`;
        await createPaymentFlag(`invoice_${reason}_${inv.id}`, {
            type: !check.ok ? 'amount_mismatch' : (who.reason === 'conflict' ? 'customer_multiple_uids' : 'unresolved_uid'),
            reason, invoiceId: inv.id, subscriptionId: subId, customerId: idOf(inv.customer),
            uid: (_d = (_b = who.uid) !== null && _b !== void 0 ? _b : (_c = sub.metadata) === null || _c === void 0 ? void 0 : _c.userId) !== null && _d !== void 0 ? _d : null, candidates: who.candidates,
            product: check.productId || ((_e = sub.metadata) === null || _e === void 0 ? void 0 : _e.productId) || null,
            amount: (_f = inv.amount_paid) !== null && _f !== void 0 ? _f : null, currency: (_g = inv.currency) !== null && _g !== void 0 ? _g : null, livemode: inv.livemode,
        }, opts.dryRun);
        return { action: 'rejected', reason, uid: who.uid };
    }
    const uid = who.uid;
    const charge = inv.charge && typeof inv.charge === 'object' ? inv.charge : null;
    if (charge && (charge.refunded === true || charge.disputed === true)) {
        return { action: 'rejected', reason: 'charge_reversed', uid };
    }
    if (!(await testModeAllowed(uid, inv.livemode)))
        return { action: 'rejected', reason: 'test_mode_not_allowed', uid };
    if (opts.dryRun) {
        const applied = await invoiceApplied(inv.id);
        return applied && !opts.force
            ? { action: 'already', uid }
            : { action: 'would_grant', uid, detail: { invoiceId: inv.id, tier: check.tier, paidThrough: (_h = check.period) === null || _h === void 0 ? void 0 : _h.end.toISOString() } };
    }
    const res = await writeMembershipGrant(uid, inv, sub, check, opts);
    if (res.action === 'granted' && check.replacesSubscriptionId && inv.billing_reason === 'subscription_create') {
        const cancelled = await cancelReplacedSubscription(stripe, sub, check.replacesSubscriptionId);
        res.detail = Object.assign(Object.assign({}, (res.detail || {})), { replacedSubscription: cancelled });
    }
    return res;
}
/** The transactional entitlement write for one paid invoice. */
async function writeMembershipGrant(uid, inv, sub, check, opts) {
    var _a, _b;
    const db = fdb();
    const invRef = db.collection('stripe_invoices').doc(inv.id);
    const legacyQ = db.collection('stripe_invoices').where('invoiceId', '==', inv.id).limit(1);
    const profileRef = db.collection('profiles').doc(uid);
    const userRef = db.collection('users').doc(uid);
    const mapRef = db.collection('stripe_customers').doc(uid);
    const purchaseRef = db.collection('membership_purchases').doc(`stripe_${inv.id}`);
    const priorBaseQ = db.collection('membership_purchases')
        .where('userId', '==', uid).where('productId', '==', exports.BASE_PRODUCT_ID).limit(10);
    const balanceRef = db.collection('coinBalances').doc(uid);
    const period = check.period;
    const paidEndWithGrace = new Date(period.end.getTime() + exports.RENEWAL_GRACE_MS);
    const f = subFields(check.productId);
    const result = await db.runTransaction(async (tx) => {
        var _a, _b;
        const [marker, legacy, profileSnap, userSnap, mapSnap, priorBase, balance] = await Promise.all([
            tx.get(invRef), tx.get(legacyQ), tx.get(profileRef), tx.get(userRef), tx.get(mapRef),
            tx.get(priorBaseQ), tx.get(balanceRef),
        ]);
        const alreadyApplied = marker.exists || !legacy.empty;
        if (alreadyApplied && !opts.force)
            return { action: 'already' };
        const now = nowDate();
        const nowTs = ts(now);
        const profile = profileSnap.data() || {};
        const update = {
            [f.id]: sub.id,
            [f.lastId]: sub.id,
            [f.status]: sub.status === 'trialing' ? 'trialing' : 'active',
            [f.cancelAtPeriodEnd]: sub.cancel_at_period_end === true,
            updatedAt: nowTs,
        };
        let grantedEnd;
        let grantedTier;
        let bonus = 0;
        const mapUpdate = {};
        if (f.base) {
            const curBaseEnd = (0, effectiveTier_1.tierDateFromValue)(profile.baseMembershipEndDate);
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
            if ((check.amountPaid || 0) > 0 && !((_a = mapSnap.data()) === null || _a === void 0 ? void 0 : _a.baseBonusGrantedAt) && !hadPaidBase) {
                bonus = 500;
            }
            if (((_b = mapSnap.data()) === null || _b === void 0 ? void 0 : _b.baseTrialUsed) !== true)
                mapUpdate.baseTrialUsed = true;
        }
        else {
            const wanted = String(check.tier);
            const stored = (0, effectiveTier_1.normalizeStoredTier)(profile.membershipTier);
            const curEnd = (0, effectiveTier_1.tierDateFromValue)(profile.membershipEndDate);
            const active = (0, effectiveTier_1.hasActivePaidTier)(profile, now);
            const current = (0, effectiveTier_1.effectiveTier)(profile, now);
            // A subscription only ever sells its own tier, so an active HIGHER tier
            // always comes from somewhere else.
            if (active && (0, effectiveTier_1.tierRank)(current) > (0, effectiveTier_1.tierRank)(wanted)) {
                // A HIGHER tier from another source (store / coupon / admin) is
                // running. It is never downgraded, and this paid period runs
                // concurrently with it (no free upgrade by queuing). Recorded so the
                // reconciler grants the Stripe tier if the higher one ends first.
                grantedTier = current;
                grantedEnd = curEnd;
                update.stripePendingTier = wanted;
                update.stripeSubscriptionPaidThrough = ts(period.end);
                update.stripeSubscriptionProductId = check.productId;
                update.stripeSubscriptionTier = wanted;
            }
            else {
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
        }
        else {
            tx.set(invRef, { lastReappliedAt: nowTs, lastReappliedBy: opts.source }, { merge: true });
        }
        if (bonus > 0) {
            const b = balance.exists ? balance.data() : null;
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
        if (Object.keys(mapUpdate).length > 0)
            tx.set(mapRef, Object.assign({ uid }, mapUpdate), { merge: true });
        return {
            action: (alreadyApplied ? 'updated' : 'granted'),
            grantedEnd, grantedTier, bonus,
        };
    });
    if (result.action === 'already')
        return { action: 'already', uid, detail: { invoiceId: inv.id } };
    console.log(`[stripe] invoice ${inv.id} -> ${result.grantedTier} for ${uid} until ${(_a = result.grantedEnd) === null || _a === void 0 ? void 0 : _a.toISOString()}`);
    return {
        action: result.action,
        uid,
        detail: {
            invoiceId: inv.id, tier: result.grantedTier,
            endDate: (_b = result.grantedEnd) === null || _b === void 0 ? void 0 : _b.toISOString(), bonusCoins: result.bonus,
        },
    };
}
/**
 * Upgrade: after the NEW subscription's first invoice is paid, cancel the one
 * it replaces (same customer, same family) with proration credit. Until then
 * the user keeps the old tier and the old subscription keeps running.
 */
async function cancelReplacedSubscription(stripe, newSub, oldSubId, dryRun = false) {
    var _a, _b;
    if (!oldSubId || oldSubId === newSub.id)
        return 'skipped';
    try {
        const old = await stripe.subscriptions.retrieve(oldSubId);
        if (idOf(old.customer) !== idOf(newSub.customer))
            return 'customer_mismatch';
        const sameFamily = (((_a = old.metadata) === null || _a === void 0 ? void 0 : _a.productId) === exports.BASE_PRODUCT_ID) === (((_b = newSub.metadata) === null || _b === void 0 ? void 0 : _b.productId) === exports.BASE_PRODUCT_ID);
        if (!sameFamily)
            return 'family_mismatch';
        if (!['active', 'trialing', 'past_due', 'unpaid'].includes(old.status))
            return `already_${old.status}`;
        if (dryRun)
            return 'would_cancel';
        await stripe.subscriptions.cancel(oldSubId, { prorate: true, invoice_now: true });
        console.log(`[stripe] upgrade: cancelled ${oldSubId} (replaced by ${newSub.id})`);
        return 'cancelled';
    }
    catch (e) {
        console.error(`[stripe] could not cancel replaced subscription ${oldSubId}:`, e === null || e === void 0 ? void 0 : e.message);
        return `error:${(e === null || e === void 0 ? void 0 : e.message) || e}`;
    }
}
/** End of the latest PAID, non-reversed period of a subscription, or null. */
async function paidThroughForSubscription(stripe, subId) {
    const list = await stripe.invoices.list({ subscription: subId, status: 'paid', limit: 5, expand: ['data.charge'] });
    let best = null;
    for (const inv of list.data || []) {
        const ch = inv.charge && typeof inv.charge === 'object' ? inv.charge : null;
        if (ch && (ch.refunded === true || ch.disputed === true))
            continue;
        const p = linePaidPeriod(subscriptionLineOf(inv, subId));
        if (p && (!best || p.end > best))
            best = p.end;
    }
    return best;
}
// ---------------------------------------------------------------------------
// Subscription status / end
// ---------------------------------------------------------------------------
/** customer.subscription.updated: status fields only. NEVER extends. */
async function processSubscriptionUpdated(stripe, subId) {
    var _a, _b;
    const sub = await stripe.subscriptions.retrieve(subId);
    const who = await resolveStripeUid(stripe, { customer: sub.customer, claimedUid: (_a = sub.metadata) === null || _a === void 0 ? void 0 : _a.userId, livemode: sub.livemode });
    if (!who.uid)
        return { action: 'ignored', reason: `uid_${who.reason}` };
    const f = subFields((_b = sub.metadata) === null || _b === void 0 ? void 0 : _b.productId);
    const ref = fdb().collection('profiles').doc(who.uid);
    return fdb().runTransaction(async (tx) => {
        const p = (await tx.get(ref)).data() || {};
        if (p[f.id] !== sub.id) {
            return { action: 'ignored', reason: 'not_on_file', uid: who.uid };
        }
        tx.set(ref, {
            [f.status]: sub.status,
            [f.cancelAtPeriodEnd]: sub.cancel_at_period_end === true,
            updatedAt: ts(nowDate()),
        }, { merge: true });
        return { action: 'updated', uid: who.uid, detail: { status: sub.status } };
    });
}
/**
 * customer.subscription.deleted (and the reconciler's missed-deletion fix).
 * Access runs to the end of the last PAID period (no grace after a deliberate
 * cancel); an end date that reaches beyond that came from another source and
 * is left alone. A subscription that never paid granted nothing.
 */
async function processSubscriptionEnded(stripe, subId, opts = {}) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const sub = await stripe.subscriptions.retrieve(subId);
    if (!['canceled', 'incomplete_expired'].includes(sub.status)) {
        return { action: 'ignored', reason: `status_${sub.status}` };
    }
    const who = await resolveStripeUid(stripe, { customer: sub.customer, claimedUid: (_a = sub.metadata) === null || _a === void 0 ? void 0 : _a.userId, livemode: sub.livemode });
    if (!who.uid)
        return { action: 'ignored', reason: `uid_${who.reason}` };
    const uid = who.uid;
    const f = subFields((_b = sub.metadata) === null || _b === void 0 ? void 0 : _b.productId);
    const subTier = ((_d = exports.MEMBERSHIP_PRODUCTS[(_c = sub.metadata) === null || _c === void 0 ? void 0 : _c.productId]) === null || _d === void 0 ? void 0 : _d.tier) || String(((_e = sub.metadata) === null || _e === void 0 ? void 0 : _e.tier) || '').toUpperCase();
    const paidThrough = await paidThroughForSubscription(stripe, sub.id);
    const ref = fdb().collection('profiles').doc(uid);
    const plan = await fdb().runTransaction(async (tx) => {
        const p = (await tx.get(ref)).data() || {};
        if (p[f.id] !== sub.id)
            return { kind: 'not_on_file' };
        const now = nowDate();
        const limit = new Date(Math.max(now.getTime(), paidThrough ? paidThrough.getTime() : 0));
        const ownershipSlack = exports.RENEWAL_GRACE_MS + 60 * 60 * 1000;
        const update = {
            [f.id]: fieldDelete(),
            [f.lastId]: sub.id,
            [f.status]: 'cancelled',
            [f.cancelAtPeriodEnd]: fieldDelete(),
            updatedAt: ts(now),
        };
        let endNow = false;
        let newEnd = null;
        if (f.base) {
            const cur = (0, effectiveTier_1.tierDateFromValue)(p.baseMembershipEndDate);
            const ours = !cur || !paidThrough || cur.getTime() <= paidThrough.getTime() + ownershipSlack;
            if (p.hasBaseMembership === true && cur && ours && cur > limit) {
                newEnd = limit;
                if (limit.getTime() <= now.getTime()) {
                    Object.assign(update, { hasBaseMembership: false, baseMembershipEndDate: ts(now), baseMembershipExpiredAt: ts(now) });
                    endNow = true;
                }
                else {
                    update.baseMembershipEndDate = ts(limit);
                }
            }
        }
        else {
            update.stripeSubscriptionProductId = fieldDelete();
            update.stripeSubscriptionTier = fieldDelete();
            update.stripePendingTier = fieldDelete();
            const cur = (0, effectiveTier_1.tierDateFromValue)(p.membershipEndDate);
            const stored = (0, effectiveTier_1.normalizeStoredTier)(p.membershipTier);
            const ours = stored === subTier
                && (!cur || !paidThrough || cur.getTime() <= paidThrough.getTime() + ownershipSlack);
            if (ours && (0, effectiveTier_1.hasActivePaidTier)(p, now) && cur && cur > limit) {
                newEnd = limit;
                if (limit.getTime() <= now.getTime()) {
                    update.membershipEndDate = ts(now);
                    endNow = true;
                }
                else {
                    update.membershipEndDate = ts(limit);
                }
            }
        }
        if (opts.dryRun)
            return { kind: 'planned', endNow, newEnd };
        tx.set(ref, update, { merge: true });
        return { kind: 'planned', endNow, newEnd };
    });
    if (plan.kind === 'not_on_file')
        return { action: 'ignored', reason: 'not_on_file', uid };
    const detail = { endNow: plan.endNow, newEnd: (_g = (_f = plan.newEnd) === null || _f === void 0 ? void 0 : _f.toISOString()) !== null && _g !== void 0 ? _g : null, paidThrough: (_h = paidThrough === null || paidThrough === void 0 ? void 0 : paidThrough.toISOString()) !== null && _h !== void 0 ? _h : null };
    if (opts.dryRun)
        return { action: 'would_end', uid, detail };
    if (plan.endNow && !f.base)
        await exports.stripeCoreDeps.downgradeTierNow(uid, 'stripe_subscription_ended');
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
async function processInvoicePaymentFailed(stripe, invoiceId) {
    var _a, _b;
    const inv = await stripe.invoices.retrieve(invoiceId);
    const subId = invoiceSubscriptionId(inv);
    if (!subId)
        return { action: 'ignored', reason: 'not_subscription_invoice' };
    const sub = await stripe.subscriptions.retrieve(subId);
    const who = await resolveStripeUid(stripe, { customer: inv.customer, claimedUid: (_a = sub.metadata) === null || _a === void 0 ? void 0 : _a.userId, livemode: inv.livemode });
    if (!who.uid)
        return { action: 'ignored', reason: `uid_${who.reason}` };
    const f = subFields((_b = sub.metadata) === null || _b === void 0 ? void 0 : _b.productId);
    const ref = fdb().collection('profiles').doc(who.uid);
    const p = (await ref.get()).data() || {};
    if (p[f.id] !== subId)
        return { action: 'ignored', reason: 'not_on_file', uid: who.uid };
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
async function processChargeReversal(stripe, args, opts = {}) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p;
    const ch = await stripe.charges.retrieve(args.chargeId, { expand: ['invoice'] });
    const markerId = args.kind === 'dispute' ? `dispute_${args.disputeId || ch.id}` : `refund_${ch.id}`;
    const markerRef = fdb().collection('stripe_revocations').doc(markerId);
    if ((await markerRef.get()).exists)
        return { action: 'already', reason: markerId };
    if (args.kind === 'refund') {
        const full = ch.refunded === true || ((_a = ch.amount_refunded) !== null && _a !== void 0 ? _a : 0) >= ((_b = ch.amount) !== null && _b !== void 0 ? _b : Infinity);
        if (!full) {
            if (!opts.dryRun) {
                await markerRef.set({ kind: 'refund', chargeId: ch.id, action: 'none', reason: 'partial_refund', amountRefunded: (_c = ch.amount_refunded) !== null && _c !== void 0 ? _c : null, createdAt: ts(nowDate()) });
            }
            return { action: 'ignored', reason: 'partial_refund' };
        }
    }
    const inv = ch.invoice && typeof ch.invoice === 'object' ? ch.invoice : null;
    const subId = inv ? invoiceSubscriptionId(inv) : null;
    const record = {
        kind: args.kind, chargeId: ch.id, disputeId: args.disputeId || null,
        invoiceId: (inv === null || inv === void 0 ? void 0 : inv.id) || null, subscriptionId: subId, amount: (_d = ch.amount) !== null && _d !== void 0 ? _d : null,
        currency: (_e = ch.currency) !== null && _e !== void 0 ? _e : null, livemode: ch.livemode === true, source: opts.source || 'webhook',
    };
    if (!subId) {
        // Coin purchase (or other one-off payment).
        let sessionId = null;
        let uid = null;
        let product = null;
        const pi = idOf(ch.payment_intent);
        if (pi) {
            const sessions = await stripe.checkout.sessions.list({ payment_intent: pi, limit: 1 });
            const s = (_f = sessions.data) === null || _f === void 0 ? void 0 : _f[0];
            if (s) {
                sessionId = s.id;
                uid = ((_g = s.metadata) === null || _g === void 0 ? void 0 : _g.userId) || null;
                product = ((_h = s.metadata) === null || _h === void 0 ? void 0 : _h.productId) || null;
            }
        }
        const flag = await createPaymentFlag(`coin_${args.kind}_${ch.id}`, {
            type: `coin_${args.kind}`, chargeId: ch.id, sessionId, uid, product,
            amount: (_j = ch.amount) !== null && _j !== void 0 ? _j : null, currency: (_k = ch.currency) !== null && _k !== void 0 ? _k : null, livemode: ch.livemode === true,
        }, opts.dryRun);
        if (!opts.dryRun) {
            await markerRef.set(Object.assign(Object.assign({}, record), { sessionId, uid, product, action: 'flagged', flag, createdAt: ts(nowDate()) }));
        }
        return { action: 'flagged', uid, reason: `coin_${args.kind}`, detail: { flag } };
    }
    const sub = await stripe.subscriptions.retrieve(subId);
    const who = await resolveStripeUid(stripe, { customer: ch.customer, claimedUid: (_l = sub.metadata) === null || _l === void 0 ? void 0 : _l.userId, livemode: ch.livemode });
    const f = subFields((_m = sub.metadata) === null || _m === void 0 ? void 0 : _m.productId);
    const period = linePaidPeriod(subscriptionLineOf(inv, subId));
    const now = nowDate();
    let cancelled = null;
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
        if (!opts.dryRun)
            await markerRef.set(Object.assign(Object.assign({}, record), { uid, action: 'none', reason: 'past_period', createdAt: ts(now) }));
        return { action: 'ignored', reason: 'past_period', uid };
    }
    if (opts.dryRun)
        return { action: 'would_revoke', uid, detail: { family: f.base ? 'base' : 'tier', subscriptionId: subId } };
    const ref = fdb().collection('profiles').doc(uid);
    const subTier = ((_p = exports.MEMBERSHIP_PRODUCTS[(_o = sub.metadata) === null || _o === void 0 ? void 0 : _o.productId]) === null || _p === void 0 ? void 0 : _p.tier) || '';
    const endTier = await fdb().runTransaction(async (tx) => {
        const [marker, snap] = await Promise.all([tx.get(markerRef), tx.get(ref)]);
        if (marker.exists)
            return 'already';
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
            }
            else if ((0, effectiveTier_1.normalizeStoredTier)(p.membershipTier) === subTier) {
                tx.set(ref, {
                    membershipEndDate: nowTs,
                    [f.status]: args.kind === 'refund' ? 'refunded' : 'disputed', stripeRevokedReason: args.kind, updatedAt: nowTs,
                }, { merge: true });
                action = 'tier_ended';
            }
            else {
                tx.set(ref, { [f.status]: args.kind === 'refund' ? 'refunded' : 'disputed', updatedAt: nowTs }, { merge: true });
                action = 'other_source_untouched';
            }
        }
        tx.create(markerRef, Object.assign(Object.assign({}, record), { uid, action, createdAt: nowTs }));
        return action;
    });
    if (endTier === 'already')
        return { action: 'already', uid };
    if (endTier === 'tier_ended')
        await exports.stripeCoreDeps.downgradeTierNow(uid, `stripe_${args.kind}`);
    if (args.kind === 'dispute' && ['active', 'trialing', 'past_due', 'unpaid'].includes(sub.status)) {
        try {
            await stripe.subscriptions.cancel(subId, { prorate: false });
            cancelled = 'cancelled';
        }
        catch (e) {
            cancelled = `error:${(e === null || e === void 0 ? void 0 : e.message) || e}`;
        }
        await markerRef.set({ subscriptionCancelled: cancelled }, { merge: true });
    }
    return { action: 'revoked', uid, detail: { result: endTier, subscriptionCancelled: cancelled } };
}
// ---------------------------------------------------------------------------
// Webhook
// ---------------------------------------------------------------------------
/** Webhook event lease: a crashed delivery can be retried after this. */
exports.EVENT_LEASE_MS = 5 * 60 * 1000;
/**
 * Transactional create-if-absent on stripe_events/{eventId}.
 *   'claimed'      -> this delivery processes the event
 *   'duplicate'    -> already processed successfully
 *   'in_progress'  -> another delivery holds a live lease
 * A 'failed' event, or one whose lease expired, is re-claimable.
 */
async function claimStripeEvent(eventId, type, livemode) {
    const ref = fdb().collection('stripe_events').doc(eventId);
    return fdb().runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const now = nowDate();
        const lease = ts(new Date(now.getTime() + exports.EVENT_LEASE_MS));
        if (snap.exists) {
            const d = snap.data() || {};
            if (d.status === 'done')
                return 'duplicate';
            const leaseUntil = (0, effectiveTier_1.tierDateFromValue)(d.leaseUntil);
            if (d.status === 'processing' && leaseUntil && leaseUntil > now)
                return 'in_progress';
            tx.set(ref, { status: 'processing', attempts: (d.attempts || 0) + 1, leaseUntil: lease, updatedAt: ts(now) }, { merge: true });
            return 'claimed';
        }
        tx.create(ref, {
            eventId, type, livemode, status: 'processing', attempts: 1, leaseUntil: lease, receivedAt: ts(now),
        });
        return 'claimed';
    });
}
async function finishStripeEvent(eventId, status, outcome) {
    await fdb().collection('stripe_events').doc(eventId).set({
        status, outcome, finishedAt: ts(nowDate()), leaseUntil: fieldDelete(),
    }, { merge: true });
}
/** Routes one verified event. Throws on transient failure (-> Stripe retries). */
async function dispatchStripeEvent(event) {
    var _a, _b, _c;
    const stripe = getStripe(event.livemode === false);
    const obj = ((_a = event.data) === null || _a === void 0 ? void 0 : _a.object) || {};
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
            return processChargeReversal(stripe, { kind: 'dispute', chargeId: idOf(obj.charge), disputeId: obj.id });
        case 'charge.dispute.closed': {
            const flag = await createPaymentFlag(`dispute_closed_${obj.id}`, {
                type: 'dispute_closed', disputeId: obj.id, chargeId: idOf(obj.charge),
                disputeStatus: obj.status || null, amount: (_b = obj.amount) !== null && _b !== void 0 ? _b : null, currency: (_c = obj.currency) !== null && _c !== void 0 ? _c : null,
            });
            return { action: 'flagged', reason: `dispute_${obj.status}`, detail: { flag } };
        }
        default:
            return { action: 'ignored', reason: `unhandled_${event.type}` };
    }
}
function splitSecrets(v) {
    return (v || '').split(',').map((s) => s.trim()).filter(Boolean);
}
/**
 * The HTTP webhook. STRIPE_WEBHOOK_SECRET may hold several comma-separated
 * live signing secrets (e.g. two endpoints during a migration);
 * STRIPE_TEST_WEBHOOK_SECRET verifies the test-mode endpoint.
 */
async function handleStripeWebhookHttp(req, res) {
    var _a;
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
    const signature = (_a = req.headers) === null || _a === void 0 ? void 0 : _a['stripe-signature'];
    if (typeof signature !== 'string' || !signature || !req.rawBody) {
        res.status(400).send('Missing signature');
        return;
    }
    let event = null;
    let signedAsLive = false;
    const webhooks = exports.stripeCoreDeps.webhooks();
    for (const [secrets, live] of [[liveSecrets, true], [testSecrets, false]]) {
        for (const secret of secrets) {
            try {
                event = webhooks.constructEvent(req.rawBody, signature, secret);
                signedAsLive = live;
                break;
            }
            catch (_b) {
                // try the next secret
            }
        }
        if (event)
            break;
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
    let claim;
    try {
        claim = await claimStripeEvent(event.id, event.type, event.livemode === true);
    }
    catch (e) {
        console.error(`[stripe] could not claim ${event.id}:`, e === null || e === void 0 ? void 0 : e.message);
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
        await finishStripeEvent(event.id, 'done', Object.assign({}, outcome));
        console.log(`[stripe] ${event.type} ${event.id}: ${outcome.action}${outcome.reason ? ` (${outcome.reason})` : ''}`);
        res.status(200).json({ received: true });
    }
    catch (e) {
        console.error(`[stripe] error handling ${event.type} ${event.id}:`, e);
        try {
            await finishStripeEvent(event.id, 'failed', { error: String((e === null || e === void 0 ? void 0 : e.message) || e) });
        }
        catch (_c) {
            // the lease expires on its own
        }
        // Non-2xx: Stripe retries, and the failed marker lets the retry run.
        res.status(500).send('Processing failed');
    }
}
//# sourceMappingURL=stripeCore.js.map