"use strict";
/**
 * ONE-OFF membership tier migration (HTTP, token-guarded, DRY RUN by default).
 *
 *   GET  .../runMembershipTierMigrationNow?token=<MEMBERSHIP_MIGRATION_TOKEN>            → dry run (counts only)
 *   GET  .../runMembershipTierMigrationNow?token=<...>&dryRun=0                          → apply
 *   optional &startAfter=<uid> to resume a scan that hit the time budget (see `nextCursor`).
 *
 * The token is NOT committed: it is read from MEMBERSHIP_MIGRATION_TOKEN in the
 * gitignored functions/.env (baked in at deploy). Unset → 503, nothing runs.
 *
 * Buckets:
 *   (a) basicToFree         membershipTier 'BASIC' (legacy; the client reads it as SILVER) → 'FREE'.
 *       (a2) baseRepaired   …of which the legacy end date is still running and the Base fields are
 *                           missing (with a store Base purchase on record) or shorter → Base set to
 *                           that end date (never shortened; a past Base end = refund/expiry, untouched).
 *   (b) expiredPaidToFree   SILVER/GOLD/PLATINUM with membershipEndDate < now → 'FREE'
 *                           (same writes as the hourly handleExpiredMemberships job).
 *   (c) paidNullEndDate     SILVER/GOLD/PLATINUM with NO membershipEndDate (not admin/TEST) — REPORT ONLY.
 *   (d) baseWronglyCleared  hasBaseMembership == false but baseMembershipEndDate still in the future
 *                           (the old expiry job cleared Base when the TIER expired) → restored.
 *   skipped: admins / TEST.
 *
 * Idempotent: a second real run finds nothing left to change.
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
exports.runMembershipTierMigrationNow = void 0;
const crypto = __importStar(require("crypto"));
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const effectiveTier_1 = require("../shared/effectiveTier");
const membershipExpiry_1 = require("../shared/membershipExpiry");
const PAGE_SIZE = 300;
const TIME_BUDGET_MS = 480000;
const SAMPLE_MAX = 20;
function bucket() {
    return { count: 0, sample: [] };
}
function add(b, uid) {
    b.count++;
    if (b.sample.length < SAMPLE_MAX)
        b.sample.push(uid);
}
function tokenOk(given) {
    const expected = process.env.MEMBERSHIP_MIGRATION_TOKEN || '';
    if (!expected || typeof given !== 'string' || given.length === 0)
        return false;
    const a = Buffer.from(given);
    const b = Buffer.from(expected);
    return a.length === b.length && crypto.timingSafeEqual(a, b);
}
/**
 * Store evidence that this user bought the Base membership (legacy
 * verifyPurchase wrote `subscriptions` + `purchases` rows with the Base
 * productId). Profile fields are not evidence: they are what we repair.
 */
async function hadStoreBasePurchase(uid) {
    const [subs, purchases] = await Promise.all([
        utils_1.db.collection('subscriptions').where('userId', '==', uid)
            .where('productId', 'in', [...effectiveTier_1.BASE_PRODUCT_IDS]).limit(1).get(),
        utils_1.db.collection('purchases').where('userId', '==', uid)
            .where('productId', 'in', [...effectiveTier_1.BASE_PRODUCT_IDS]).limit(1).get(),
    ]);
    return !subs.empty || !purchases.empty;
}
exports.runMembershipTierMigrationNow = (0, https_1.onRequest)({ memory: '512MiB', timeoutSeconds: 540 }, async (req, res) => {
    var _a;
    if (!process.env.MEMBERSHIP_MIGRATION_TOKEN) {
        res.status(503).json({ error: 'MEMBERSHIP_MIGRATION_TOKEN not configured' });
        return;
    }
    if (!tokenOk(req.query.token)) {
        res.status(403).send('forbidden');
        return;
    }
    const dryRunParam = String((_a = req.query.dryRun) !== null && _a !== void 0 ? _a : '1').toLowerCase();
    const dryRun = !(dryRunParam === '0' || dryRunParam === 'false' || dryRunParam === 'no');
    const startAfter = typeof req.query.startAfter === 'string' ? req.query.startAfter : undefined;
    const started = Date.now();
    const now = admin.firestore.Timestamp.now();
    const nowDate = now.toDate();
    const queue = new membershipExpiry_1.WriteQueue();
    const out = {
        dryRun,
        basicToFree: bucket(),
        baseRepaired: bucket(),
        expiredPaidToFree: bucket(),
        paidNullEndDate: bucket(),
        baseWronglyCleared: bucket(),
        skippedAdminOrTest: bucket(),
        errors: bucket(),
        scannedTierProfiles: 0,
        scannedBaseProfiles: 0,
        writesCommitted: 0,
        nextCursor: null,
        complete: false,
    };
    try {
        // ── Pass 1: every profile whose stored tier is BASIC or paid (by doc id) ──
        let cursor = startAfter;
        let timedOut = false;
        // eslint-disable-next-line no-constant-condition
        while (true) {
            if (Date.now() - started > TIME_BUDGET_MS) {
                timedOut = true;
                break;
            }
            let q = utils_1.db
                .collection('profiles')
                .where('membershipTier', 'in', [...effectiveTier_1.LEGACY_BASIC_STORED_VALUES, ...effectiveTier_1.PAID_TIER_STORED_VALUES])
                .orderBy(admin.firestore.FieldPath.documentId())
                .limit(PAGE_SIZE);
            if (cursor)
                q = q.startAfter(cursor);
            const snap = await q.get();
            if (snap.empty)
                break;
            cursor = snap.docs[snap.docs.length - 1].id;
            for (const doc of snap.docs) {
                out.scannedTierProfiles++;
                const uid = doc.id;
                const p = doc.data();
                try {
                    const stored = (0, effectiveTier_1.normalizeStoredTier)(p.membershipTier);
                    if ((0, effectiveTier_1.isProfileAdmin)(p) || stored === 'TEST') {
                        add(out.skippedAdminOrTest, uid);
                        continue;
                    }
                    const end = (0, effectiveTier_1.tierDateFromValue)(p.membershipEndDate);
                    if (stored === 'BASIC') {
                        add(out.basicToFree, uid);
                        // A legacy Base purchase wrote tier 'BASIC' + the Base end date
                        // into membershipEndDate. Make sure the Base fields carry at
                        // least that period — never shorten them.
                        //   - Base end missing + store evidence of a Base purchase → set it.
                        //   - Base end still running but shorter than the legacy end → extend.
                        //   - Base end in the PAST → leave it: that is a refund/revoke
                        //     (which stamps the end to "now") or a real expiry.
                        const baseEnd = (0, effectiveTier_1.tierDateFromValue)(p.baseMembershipEndDate);
                        let baseFix = null;
                        if (end && end > nowDate) {
                            const repair = !baseEnd
                                ? await hadStoreBasePurchase(uid)
                                : baseEnd > nowDate && baseEnd < end;
                            if (repair) {
                                baseFix = {
                                    hasBaseMembership: true,
                                    baseMembershipEndDate: admin.firestore.Timestamp.fromDate(end),
                                    baseMembershipSource: p.baseMembershipSource || 'purchase',
                                };
                                add(out.baseRepaired, uid);
                            }
                        }
                        if (!dryRun) {
                            await queue.set(doc.ref, Object.assign({ membershipTier: 'FREE', previousMembershipTier: String(p.membershipTier), membershipMigratedAt: now, updatedAt: now }, (baseFix || {})));
                            const userRef = utils_1.db.collection('users').doc(uid);
                            if ((await userRef.get()).exists) {
                                await queue.set(userRef, { subscriptionTier: effectiveTier_1.USERS_FREE_TIER, updatedAt: now });
                            }
                        }
                        continue;
                    }
                    // Paid tier.
                    if (!end) {
                        add(out.paidNullEndDate, uid); // report only
                        continue;
                    }
                    if (end.getTime() <= nowDate.getTime()) {
                        add(out.expiredPaidToFree, uid);
                        if (!dryRun) {
                            await (0, membershipExpiry_1.planTierExpiry)(doc, queue, { reason: 'migration', now });
                        }
                    }
                }
                catch (e) {
                    add(out.errors, uid);
                    (0, utils_1.logError)(`runMembershipTierMigrationNow: ${uid}`, e);
                }
            }
            if (!dryRun)
                await queue.flush();
            if (snap.size < PAGE_SIZE)
                break;
        }
        if (timedOut) {
            out.nextCursor = cursor !== null && cursor !== void 0 ? cursor : null;
        }
        else {
            // ── Pass 2: Base wrongly cleared by the old tier-expiry job ──
            // Index: profiles (hasBaseMembership ASC, baseMembershipEndDate ASC).
            let baseCursor;
            // eslint-disable-next-line no-constant-condition
            while (true) {
                if (Date.now() - started > TIME_BUDGET_MS) {
                    timedOut = true;
                    break;
                }
                let q = utils_1.db
                    .collection('profiles')
                    .where('hasBaseMembership', '==', false)
                    .where('baseMembershipEndDate', '>', now)
                    .orderBy('baseMembershipEndDate', 'asc')
                    .limit(PAGE_SIZE);
                if (baseCursor)
                    q = q.startAfter(baseCursor);
                const snap = await q.get();
                if (snap.empty)
                    break;
                baseCursor = snap.docs[snap.docs.length - 1];
                for (const doc of snap.docs) {
                    out.scannedBaseProfiles++;
                    add(out.baseWronglyCleared, doc.id);
                    if (!dryRun) {
                        await queue.set(doc.ref, {
                            hasBaseMembership: true,
                            baseMembershipRestoredAt: now,
                            updatedAt: now,
                        });
                    }
                }
                if (!dryRun)
                    await queue.flush();
                if (snap.size < PAGE_SIZE)
                    break;
            }
            // Pass 2 is cheap and idempotent: if it timed out, re-running with
            // `startAfter` = the pass-1 end is not needed — just run again.
            out.complete = !timedOut;
        }
        if (!dryRun)
            await queue.flush();
        out.writesCommitted = queue.committedOps;
        (0, utils_1.logInfo)(`runMembershipTierMigrationNow ${dryRun ? 'DRY RUN' : 'APPLIED'}: ${JSON.stringify({
            basicToFree: out.basicToFree.count,
            baseRepaired: out.baseRepaired.count,
            expiredPaidToFree: out.expiredPaidToFree.count,
            paidNullEndDate: out.paidNullEndDate.count,
            baseWronglyCleared: out.baseWronglyCleared.count,
            skippedAdminOrTest: out.skippedAdminOrTest.count,
            errors: out.errors.count,
            writes: out.writesCommitted,
        })}`);
        res.status(200).json(out);
    }
    catch (e) {
        (0, utils_1.logError)('runMembershipTierMigrationNow failed', e);
        try {
            await queue.flush();
        }
        catch (_b) {
            // already logged
        }
        out.writesCommitted = queue.committedOps;
        res.status(500).json({ error: (e === null || e === void 0 ? void 0 : e.message) || String(e), partial: out });
    }
});
//# sourceMappingURL=membershipMigration.js.map