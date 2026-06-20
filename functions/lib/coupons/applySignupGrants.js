"use strict";
/**
 * Auto-grants memberships/coins at signup based on the email allowlist.
 *
 * Fires when a new `users/{uid}` doc is created (client writes it on signup;
 * `onUserCreatedSendWelcome` in brevoEmailService.ts uses the same trigger).
 *
 * For every coupon whose `allowedEmail` matches the new user AND
 * `autoGrantOnSignup === true`, this:
 *   1. Atomically redeems the coupon (no double-grant, no over-redemption).
 *   2. For membership coupons, ADDITIONALLY grants a base membership of the
 *      same duration as a free bonus (per product decision).
 *   3. Records the grant in `profiles/{uid}.signupGrantsApplied[]` so the
 *      client can render a one-time welcome banner.
 *
 * Idempotency: `profiles/{uid}.signupGrantsAppliedAt` short-circuits the
 * trigger on re-fires (Firestore guarantees at-least-once delivery).
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
exports.applySignupGrants = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const grants_1 = require("../shared/grants");
const couponEmails_1 = require("../notifications/couponEmails");
const grants_2 = require("./grants");
const COIN_EXPIRATION_DAYS = 365;
exports.applySignupGrants = (0, firestore_1.onDocumentCreated)({
    document: 'users/{userId}',
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b;
    const uid = event.params.userId;
    const userData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!(userData === null || userData === void 0 ? void 0 : userData.email)) {
        (0, utils_1.logInfo)(`applySignupGrants: no email on users/${uid}, skipping`);
        return;
    }
    const email = String(userData.email).toLowerCase().trim();
    const profileRef = utils_1.db.collection('profiles').doc(uid);
    // ── Idempotency: short-circuit if we've already applied grants ──
    const profileSnap = await profileRef.get();
    if (profileSnap.exists && ((_b = profileSnap.data()) === null || _b === void 0 ? void 0 : _b.signupGrantsAppliedAt)) {
        (0, utils_1.logInfo)(`applySignupGrants: already applied for ${uid}, skipping`);
        return;
    }
    // ── Find matching allowlist coupons ──
    const couponsSnap = await utils_1.db
        .collection('coupons')
        .where('allowedEmail', '==', email)
        .where('disabled', '==', false)
        .where('autoGrantOnSignup', '==', true)
        .get();
    if (couponsSnap.empty) {
        (0, utils_1.logInfo)(`applySignupGrants: no allowlist coupons for ${email}`);
        // Still mark as processed so we don't keep querying on every doc update.
        // Transactional to avoid racing with a concurrent invocation that
        // also processed an (empty) grant list.
        await markProcessedIfFresh(profileRef, []);
        return;
    }
    const applied = [];
    for (const couponDoc of couponsSnap.docs) {
        try {
            const grant = await applyOneCoupon(uid, email, couponDoc);
            if (grant)
                applied.push(grant);
        }
        catch (err) {
            (0, utils_1.logError)(`applySignupGrants: failed to apply coupon ${couponDoc.id} for ${uid}`, err);
        }
    }
    // ── Record the applied grants so the client can show a welcome banner ──
    // Wrapped in a transaction that re-checks signupGrantsAppliedAt — under
    // at-least-once trigger delivery two invocations can both pass the
    // out-of-tx idempotency check above, but only one of them has the
    // populated `applied` list (the other's per-coupon redemption-doc checks
    // all bail out, leaving `applied` empty). Without this guard the loser
    // would clobber the winner's banner data.
    const wrote = await markProcessedIfFresh(profileRef, applied);
    if (!wrote) {
        (0, utils_1.logInfo)(`applySignupGrants: another invocation already wrote grants for ${uid}, skipping notify`);
        return;
    }
    // ── Best-effort email per grant (already non-fatal inside the helper) ──
    for (const g of applied) {
        await (0, couponEmails_1.sendCouponRedeemedEmail)(uid, {
            couponCode: g.couponCode,
            grantSummary: g.grantSummary,
        });
    }
    (0, utils_1.logInfo)(`applySignupGrants: applied ${applied.length} grant(s) for ${uid} (${email})`);
});
/**
 * Writes `signupGrantsApplied` + `signupGrantsAppliedAt` to the profile only
 * if no prior invocation already wrote `signupGrantsAppliedAt`. Returns true
 * if this call did the write (so the caller can do follow-up side effects
 * like sending the welcome email).
 */
async function markProcessedIfFresh(profileRef, applied) {
    return utils_1.db.runTransaction(async (tx) => {
        var _a;
        const snap = await tx.get(profileRef);
        if (snap.exists && ((_a = snap.data()) === null || _a === void 0 ? void 0 : _a.signupGrantsAppliedAt)) {
            return false;
        }
        const now = admin.firestore.Timestamp.now();
        tx.set(profileRef, {
            signupGrantsApplied: applied,
            signupGrantsAppliedAt: now,
            updatedAt: now,
        }, { merge: true });
        return true;
    });
}
/**
 * Redeems a single coupon for a new user inside a transaction.
 * Returns the AppliedGrant entry to record, or null if skipped (expired, etc).
 */
async function applyOneCoupon(uid, userEmail, couponDoc) {
    const couponRef = couponDoc.ref;
    return utils_1.db.runTransaction(async (tx) => {
        var _a, _b, _c, _d, _e, _f, _g;
        // Re-fetch the coupon inside the tx for atomic check.
        const snap = await tx.get(couponRef);
        if (!snap.exists)
            return null;
        const c = snap.data();
        if (c.disabled)
            return null;
        const now = admin.firestore.Timestamp.now();
        if (c.expiresAt && c.expiresAt.toDate() <= now.toDate()) {
            return null;
        }
        if (c.maxRedemptions != null &&
            (c.redemptionsCount || 0) >= c.maxRedemptions) {
            return null;
        }
        const redemptionRef = couponRef.collection('redemptions').doc(uid);
        const profileRef = utils_1.db.collection('profiles').doc(uid);
        const userRef = utils_1.db.collection('users').doc(uid);
        const balanceRef = utils_1.db.collection('coinBalances').doc(uid);
        const grants = (0, grants_2.effectiveGrants)(c);
        if (grants.length === 0)
            return null;
        // ── All reads up-front (Firestore tx rule) ──
        const needsBalance = grants.some((g) => g.kind === 'coins');
        // Profile is needed for both membership and base_membership; also for the
        // implicit bonus rule when grants include a membership without an
        // explicit base grant.
        const couponHasBaseGrant = (0, grants_2.hasBaseGrant)(c);
        const needsProfile = grants.some((g) => g.kind === 'membership' || g.kind === 'base_membership');
        const existing = await tx.get(redemptionRef);
        if (existing.exists)
            return null;
        const profSnap = needsProfile ? await tx.get(profileRef) : null;
        const balanceSnap = needsBalance ? await tx.get(balanceRef) : null;
        // ── Accumulate updates ──
        const profileUpdate = {};
        const userUpdate = {};
        let runningTier = ((_a = profSnap === null || profSnap === void 0 ? void 0 : profSnap.data()) === null || _a === void 0 ? void 0 : _a.membershipTier) || 'BASIC';
        let runningTierEnd = (_d = (_c = (_b = profSnap === null || profSnap === void 0 ? void 0 : profSnap.data()) === null || _b === void 0 ? void 0 : _b.membershipEndDate) === null || _c === void 0 ? void 0 : _c.toDate()) !== null && _d !== void 0 ? _d : null;
        let runningBaseEnd = (_g = (_f = (_e = profSnap === null || profSnap === void 0 ? void 0 : profSnap.data()) === null || _e === void 0 ? void 0 : _e.baseMembershipEndDate) === null || _f === void 0 ? void 0 : _f.toDate()) !== null && _g !== void 0 ? _g : null;
        const balanceData = (balanceSnap === null || balanceSnap === void 0 ? void 0 : balanceSnap.exists) ? balanceSnap.data() : {};
        let runningBalance = (balanceData === null || balanceData === void 0 ? void 0 : balanceData.totalCoins) || 0;
        const coinBatches = (balanceData === null || balanceData === void 0 ? void 0 : balanceData.coinBatches) || [];
        let totalCoinsGranted = 0;
        // Track whether any membership grant was applied so we know whether to
        // append the implicit base-membership bonus.
        let membershipGrantApplied = false;
        let largestMembershipDurationMs = 0;
        for (const g of grants) {
            if (g.kind === 'membership' && g.tier && g.durationDays) {
                const durationMs = g.durationDays * 24 * 60 * 60 * 1000;
                const ext = (0, grants_1.computeMembershipExtension)(runningTier, runningTierEnd, g.tier, durationMs, now.toDate());
                runningTier = ext.effectiveTier;
                runningTierEnd = ext.newEndDate;
                profileUpdate.membershipTier = ext.effectiveTier;
                profileUpdate.membershipStartDate = now;
                profileUpdate.membershipEndDate = ext.newEndTimestamp;
                userUpdate.subscriptionTier = ext.effectiveTier;
                userUpdate.membershipEndDate = ext.newEndTimestamp;
                membershipGrantApplied = true;
                if (durationMs > largestMembershipDurationMs) {
                    largestMembershipDurationMs = durationMs;
                }
            }
            else if (g.kind === 'base_membership' && g.durationDays) {
                const durationMs = g.durationDays * 24 * 60 * 60 * 1000;
                const baseStart = runningBaseEnd && runningBaseEnd > now.toDate() ? runningBaseEnd : now.toDate();
                const newBaseEnd = new Date(baseStart.getTime() + durationMs);
                runningBaseEnd = newBaseEnd;
                profileUpdate.hasBaseMembership = true;
                profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
            }
            else if (g.kind === 'coins' && g.coinAmount && g.coinAmount > 0) {
                const amount = g.coinAmount;
                const expirationDate = new Date();
                expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);
                coinBatches.push({
                    batchId: utils_1.db.collection('temp').doc().id,
                    initialCoins: amount,
                    remainingCoins: amount,
                    source: 'coupon',
                    acquiredDate: now,
                    expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
                });
                runningBalance += amount;
                totalCoinsGranted += amount;
            }
        }
        // ── Implicit bonus rule: signup membership grants get a same-duration ──
        // base membership for free, UNLESS the coupon already includes a base
        // grant in its bundle (no double-stack).
        let bonusApplied = false;
        if (membershipGrantApplied && !couponHasBaseGrant && largestMembershipDurationMs > 0) {
            const baseStart = runningBaseEnd && runningBaseEnd > now.toDate() ? runningBaseEnd : now.toDate();
            const newBaseEnd = new Date(baseStart.getTime() + largestMembershipDurationMs);
            runningBaseEnd = newBaseEnd;
            profileUpdate.hasBaseMembership = true;
            profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
            bonusApplied = true;
        }
        // ── Writes ──
        if (Object.keys(profileUpdate).length > 0) {
            profileUpdate.updatedAt = now;
            tx.set(profileRef, profileUpdate, { merge: true });
        }
        if (Object.keys(userUpdate).length > 0) {
            userUpdate.updatedAt = now;
            tx.set(userRef, userUpdate, { merge: true });
        }
        if (totalCoinsGranted > 0) {
            tx.set(balanceRef, {
                userId: uid,
                totalCoins: runningBalance,
                lastUpdated: now,
                coinBatches,
            }, { merge: true });
            const txnRef = utils_1.db.collection('coinTransactions').doc();
            tx.set(txnRef, {
                userId: uid,
                type: 'credit',
                amount: totalCoinsGranted,
                balanceAfter: runningBalance,
                reason: 'coupon',
                metadata: { couponId: couponRef.id, couponCode: c.code, source: 'signup_grant' },
                createdAt: now,
            });
        }
        // Build the summary — append " + BASE +Nd" if the implicit bonus fired.
        let grantSummary = (0, grants_2.summariseGrants)(grants);
        if (bonusApplied) {
            const bonusDays = Math.round(largestMembershipDurationMs / (24 * 60 * 60 * 1000));
            grantSummary = `${grantSummary} · BASE +${bonusDays}d`;
        }
        // Mark redemption + bump counter (one per coupon, not one per grant —
        // preserves maxRedemptions semantics).
        tx.set(redemptionRef, {
            redeemedAt: now,
            userEmail,
            grantSummary,
            couponCode: c.code,
            source: 'signup_grant',
        });
        tx.update(couponRef, {
            redemptionsCount: admin.firestore.FieldValue.increment(1),
            lastRedeemedAt: now,
        });
        return {
            couponId: couponRef.id,
            couponCode: c.code,
            grantSummary,
            dismissed: false,
        };
    });
}
//# sourceMappingURL=applySignupGrants.js.map