"use strict";
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
exports.runMonthlyCoinAllowancesNow = exports.grantMonthlyCoinAllowances = exports.MONTHLY_COINS = void 0;
exports.periodOf = periodOf;
exports.isExcluded = isExcluded;
exports.runAllowances = runAllowances;
/**
 * Monthly coin allowance — the coins every membership tier promises in the app
 * (TierEntitlements.monthlyCoins): FREE 100, SILVER 500, GOLD 1500,
 * PLATINUM 5000 (TEST = Platinum).
 *
 * Replaces the old `grantMonthlyAllowances`, which never paid anyone: it
 * filtered users.subscriptionTier by lower-case values the server never
 * writes, wrote to the wrong collection (`coin_balances`, the app reads
 * `coinBalances`), had no FREE/PLATINUM amounts and no double-pay guard.
 *
 *  - Tier = the EFFECTIVE tier on profiles/{uid} (shared/effectiveTier.ts):
 *    an expired paid tier gets the FREE amount.
 *  - Exactly once per user per month: a ledger doc
 *    `coinAllowanceGrants/{uid}_{YYYYMM}` is CREATED before crediting; a
 *    second run for the same month finds it and skips.
 *  - Credit via shared grantCoins → `coinBalances` + `coinTransactions`
 *    (source 'allowance'), plus an in-app notification (no mass push).
 *  - Skips banned / suspended / deleted accounts.
 *  - Scales: pages profiles by document id (300 per page, 20 in parallel)
 *    under a time budget, persisting the cursor in
 *    `coin_allowance_runs/{YYYYMM}`. The schedule fires hourly on days 1-3 of
 *    each month; every run resumes where the last stopped and does nothing
 *    once the month is complete.
 *
 * HTTP twin `runMonthlyCoinAllowancesNow?token=` (COIN_ALLOWANCE_TOKEN in the
 * gitignored functions/.env) is a DRY RUN by default: it counts what the
 * current month would grant without writing. `&dryRun=0` runs it for real.
 */
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const crypto = __importStar(require("crypto"));
require("../shared/firebaseAdmin");
const grants_1 = require("../shared/grants");
const effectiveTier_1 = require("../shared/effectiveTier");
const utils_1 = require("../shared/utils");
const db = admin.firestore();
/** Must match TierEntitlements.monthlyCoins in the app. */
exports.MONTHLY_COINS = {
    FREE: 100,
    SILVER: 500,
    GOLD: 1500,
    PLATINUM: 5000,
    TEST: 5000,
};
const PAGE_SIZE = 300;
const PARALLEL = 20;
const TIME_BUDGET_MS = 480000;
function periodOf(d) {
    return `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}
/** Accounts that must not receive coins. */
function isExcluded(p) {
    const status = String(p.accountStatus || 'active').toLowerCase();
    return p.isBanned === true || ['banned', 'suspended', 'deleted'].includes(status);
}
async function grantOne(uid, data, period, now, dryRun, out) {
    var _a;
    if (isExcluded(data)) {
        out.excluded++;
        return;
    }
    const tier = (0, effectiveTier_1.effectiveTier)(data, now);
    const amount = (_a = exports.MONTHLY_COINS[tier]) !== null && _a !== void 0 ? _a : 0;
    if (amount <= 0)
        return;
    const ledger = db.collection('coinAllowanceGrants').doc(`${uid}_${period}`);
    if (dryRun) {
        if ((await ledger.get()).exists) {
            out.alreadyGranted++;
        }
        else {
            out.granted++;
            out.coins += amount;
            out.byTier[tier] = (out.byTier[tier] || 0) + 1;
        }
        return;
    }
    try {
        // create() fails if it exists → the month was already paid.
        await ledger.create({
            userId: uid,
            period,
            tier,
            amount,
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
    catch (e) {
        if ((e === null || e === void 0 ? void 0 : e.code) === 6 || /already exists/i.test(String(e === null || e === void 0 ? void 0 : e.message))) {
            out.alreadyGranted++;
            return;
        }
        throw e;
    }
    try {
        await (0, grants_1.grantCoins)(uid, amount, 'allowance', 'monthlyAllowance', { tier, period });
    }
    catch (e) {
        // Let a later run retry this user.
        await ledger.delete().catch(() => undefined);
        throw e;
    }
    await ledger.update({ status: 'granted' });
    await db.collection('notifications').add({
        userId: uid,
        type: 'coins_allowance',
        title: 'Monthly coins added',
        message: `You received ${amount} coins with your ${tier === 'FREE' ? 'free' : tier.toLowerCase()} membership this month.`,
        data: { type: 'coins_allowance', amount: String(amount), period },
        isRead: false,
        // In-app only: a push to every member each month is not wanted.
        pushSent: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    out.granted++;
    out.coins += amount;
    out.byTier[tier] = (out.byTier[tier] || 0) + 1;
}
async function runAllowances(opts) {
    var _a;
    const now = (_a = opts.now) !== null && _a !== void 0 ? _a : new Date();
    const period = periodOf(now);
    const started = Date.now();
    const stateRef = db.collection('coin_allowance_runs').doc(period);
    const out = {
        period,
        dryRun: opts.dryRun,
        scanned: 0,
        granted: 0,
        alreadyGranted: 0,
        excluded: 0,
        coins: 0,
        byTier: {},
        errors: 0,
        complete: false,
    };
    const state = opts.dryRun ? undefined : (await stateRef.get()).data();
    if (state === null || state === void 0 ? void 0 : state.complete) {
        out.complete = true;
        return out;
    }
    let cursor = opts.dryRun ? undefined : state === null || state === void 0 ? void 0 : state.cursor;
    while (Date.now() - started < TIME_BUDGET_MS) {
        let q = db
            .collection('profiles')
            .orderBy(admin.firestore.FieldPath.documentId())
            .limit(PAGE_SIZE);
        if (cursor)
            q = q.startAfter(cursor);
        const page = await q.get();
        if (page.empty) {
            out.complete = true;
            break;
        }
        for (let i = 0; i < page.docs.length; i += PARALLEL) {
            await Promise.all(page.docs.slice(i, i + PARALLEL).map((d) => grantOne(d.id, d.data(), period, now, opts.dryRun, out).catch((e) => {
                out.errors++;
                (0, utils_1.logError)(`allowance failed uid=${d.id}`, e);
            })));
        }
        out.scanned += page.size;
        cursor = page.docs[page.docs.length - 1].id;
        if (page.size < PAGE_SIZE) {
            out.complete = true;
            break;
        }
    }
    if (!opts.dryRun) {
        await stateRef.set({
            period,
            cursor: out.complete ? null : cursor !== null && cursor !== void 0 ? cursor : null,
            complete: out.complete,
            granted: admin.firestore.FieldValue.increment(out.granted),
            coins: admin.firestore.FieldValue.increment(out.coins),
            errors: admin.firestore.FieldValue.increment(out.errors),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    }
    (0, utils_1.logInfo)(`monthly allowance ${JSON.stringify(out)}`);
    return out;
}
exports.grantMonthlyCoinAllowances = (0, scheduler_1.onSchedule)({
    // Hourly on days 1-3: each run resumes the month's cursor, and once the
    // month is complete every later run is a no-op.
    schedule: '5 * 1-3 * *',
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    try {
        await runAllowances({ dryRun: false });
    }
    catch (e) {
        (0, utils_1.logError)('grantMonthlyCoinAllowances failed', e);
    }
});
function tokenOk(given) {
    const expected = process.env.COIN_ALLOWANCE_TOKEN || '';
    if (!expected || typeof given !== 'string' || given.length === 0)
        return false;
    const a = Buffer.from(given);
    const b = Buffer.from(expected);
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}
exports.runMonthlyCoinAllowancesNow = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 540 }, async (req, res) => {
    if (!process.env.COIN_ALLOWANCE_TOKEN) {
        res.status(503).json({ error: 'not configured' });
        return;
    }
    if (!tokenOk(req.query.token)) {
        res.status(403).json({ error: 'forbidden' });
        return;
    }
    const dryRun = req.query.dryRun !== '0';
    try {
        res.json(await runAllowances({ dryRun }));
    }
    catch (e) {
        res.status(500).json({ error: String((e === null || e === void 0 ? void 0 : e.message) || e) });
    }
});
//# sourceMappingURL=monthlyAllowance.js.map