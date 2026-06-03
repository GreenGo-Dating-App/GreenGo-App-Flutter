"use strict";
/**
 * Secure server-side coupon redemption.
 *
 * Atomically:
 *  - Looks up the coupon by code.
 *  - Validates: not disabled, not expired, redemptions left, email gate (if any),
 *    not already redeemed by this user.
 *  - Applies every grant in the coupon (a coupon can carry coins + base +
 *    a tier as a bundle) using the never-downgrade extension rule per grant.
 *  - Writes the redemption record and increments the per-coupon counter
 *    (once per redemption, regardless of how many grants are in the bundle).
 *
 * All in a single Firestore transaction so concurrent attempts can't over-
 * redeem a capped coupon or double-grant the same user.
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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.redeemCoupon = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const grants_1 = require("../shared/grants");
const grants_2 = require("./grants");
const COIN_EXPIRATION_DAYS = 365;
exports.redeemCoupon = (0, https_1.onCall)({ memory: '512MiB', timeoutSeconds: 30 }, async (request) => {
    var _a;
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'You must be signed in to redeem a coupon');
    }
    const uid = request.auth.uid;
    const userEmail = request.auth.token.email
        ? String(request.auth.token.email).toLowerCase()
        : null;
    const raw = (_a = request.data) === null || _a === void 0 ? void 0 : _a.code;
    if (typeof raw !== 'string' || raw.trim().length === 0) {
        throw new https_1.HttpsError('invalid-argument', 'Coupon code is required');
    }
    const code = raw.trim().toUpperCase();
    try {
        const result = await utils_1.db.runTransaction(async (tx) => {
            var _a, _b, _c, _d, _e, _f, _g;
            // ── Look up coupon by code (case-insensitive — stored uppercase) ──
            const couponQuery = await tx.get(utils_1.db.collection('coupons').where('code', '==', code).limit(1));
            if (couponQuery.empty) {
                throw new https_1.HttpsError('not-found', 'Coupon code not found');
            }
            const couponRef = couponQuery.docs[0].ref;
            const coupon = couponQuery.docs[0].data();
            // ── Validate coupon state ──
            if (coupon.disabled) {
                throw new https_1.HttpsError('failed-precondition', 'This coupon is no longer active');
            }
            const now = admin.firestore.Timestamp.now();
            if (coupon.expiresAt && coupon.expiresAt.toDate() <= now.toDate()) {
                throw new https_1.HttpsError('failed-precondition', 'This coupon has expired');
            }
            if (coupon.maxRedemptions !== null &&
                coupon.maxRedemptions !== undefined &&
                (coupon.redemptionsCount || 0) >= coupon.maxRedemptions) {
                throw new https_1.HttpsError('failed-precondition', 'This coupon has reached its redemption limit');
            }
            if (coupon.allowedEmail) {
                const allowed = String(coupon.allowedEmail).toLowerCase();
                if (!userEmail || userEmail !== allowed) {
                    throw new https_1.HttpsError('permission-denied', 'This coupon is restricted to a different account');
                }
            }
            const grants = (0, grants_2.effectiveGrants)(coupon);
            if (grants.length === 0) {
                throw new https_1.HttpsError('failed-precondition', 'Coupon is misconfigured: no grants');
            }
            // ── Reject if this user already redeemed this coupon ──
            const redemptionRef = couponRef.collection('redemptions').doc(uid);
            const profileRef = utils_1.db.collection('profiles').doc(uid);
            const userRef = utils_1.db.collection('users').doc(uid);
            const balanceRef = utils_1.db.collection('coinBalances').doc(uid);
            // ── All reads up-front (Firestore tx rule) ──
            const needsProfile = grants.some((g) => g.kind === 'membership' || g.kind === 'base_membership');
            const needsBalance = grants.some((g) => g.kind === 'coins');
            const existingRedemption = await tx.get(redemptionRef);
            if (existingRedemption.exists) {
                throw new https_1.HttpsError('already-exists', 'You have already redeemed this coupon');
            }
            const profileSnap = needsProfile ? await tx.get(profileRef) : null;
            const balanceSnap = needsBalance ? await tx.get(balanceRef) : null;
            // ── Accumulate updates across the grant list ──
            const profileUpdate = {};
            const userUpdate = {};
            let runningTier = ((_a = profileSnap === null || profileSnap === void 0 ? void 0 : profileSnap.data()) === null || _a === void 0 ? void 0 : _a.membershipTier) || 'BASIC';
            let runningTierEnd = (_d = (_c = (_b = profileSnap === null || profileSnap === void 0 ? void 0 : profileSnap.data()) === null || _b === void 0 ? void 0 : _b.membershipEndDate) === null || _c === void 0 ? void 0 : _c.toDate()) !== null && _d !== void 0 ? _d : null;
            let runningBaseEnd = (_g = (_f = (_e = profileSnap === null || profileSnap === void 0 ? void 0 : profileSnap.data()) === null || _e === void 0 ? void 0 : _e.baseMembershipEndDate) === null || _f === void 0 ? void 0 : _f.toDate()) !== null && _g !== void 0 ? _g : null;
            const balanceData = (balanceSnap === null || balanceSnap === void 0 ? void 0 : balanceSnap.exists) ? balanceSnap.data() : {};
            let runningBalance = (balanceData === null || balanceData === void 0 ? void 0 : balanceData.totalCoins) || 0;
            const coinBatches = (balanceData === null || balanceData === void 0 ? void 0 : balanceData.coinBatches) || [];
            let totalCoinsGranted = 0;
            let firstMembershipExt = null;
            let firstCoinAmount;
            let firstDurationDays;
            let firstTier;
            for (const g of grants) {
                if (g.kind === 'membership' && g.tier && g.durationDays) {
                    const ext = (0, grants_1.computeMembershipExtension)(runningTier, runningTierEnd, g.tier, g.durationDays * 24 * 60 * 60 * 1000, now.toDate());
                    runningTier = ext.effectiveTier;
                    runningTierEnd = ext.newEndDate;
                    profileUpdate.membershipTier = ext.effectiveTier;
                    profileUpdate.membershipStartDate = now;
                    profileUpdate.membershipEndDate = ext.newEndTimestamp;
                    userUpdate.subscriptionTier = ext.effectiveTier;
                    userUpdate.membershipEndDate = ext.newEndTimestamp;
                    if (!firstMembershipExt) {
                        firstMembershipExt = { effectiveTier: ext.effectiveTier, newEndDate: ext.newEndDate };
                        firstTier = g.tier;
                        firstDurationDays !== null && firstDurationDays !== void 0 ? firstDurationDays : (firstDurationDays = g.durationDays);
                    }
                }
                else if (g.kind === 'base_membership' && g.durationDays) {
                    const baseStart = runningBaseEnd && runningBaseEnd > now.toDate() ? runningBaseEnd : now.toDate();
                    const newBaseEnd = new Date(baseStart.getTime() + g.durationDays * 24 * 60 * 60 * 1000);
                    runningBaseEnd = newBaseEnd;
                    profileUpdate.hasBaseMembership = true;
                    profileUpdate.baseMembershipEndDate = admin.firestore.Timestamp.fromDate(newBaseEnd);
                    firstDurationDays !== null && firstDurationDays !== void 0 ? firstDurationDays : (firstDurationDays = g.durationDays);
                }
                else if (g.kind === 'coins' && g.coinAmount) {
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
                    firstCoinAmount !== null && firstCoinAmount !== void 0 ? firstCoinAmount : (firstCoinAmount = amount);
                }
                else {
                    throw new https_1.HttpsError('failed-precondition', `Coupon is misconfigured: invalid grant ${JSON.stringify(g)}`);
                }
            }
            // ── Write profile + user (single set per ref) ──
            if (Object.keys(profileUpdate).length > 0) {
                profileUpdate.updatedAt = now;
                tx.set(profileRef, profileUpdate, { merge: true });
            }
            if (Object.keys(userUpdate).length > 0) {
                userUpdate.updatedAt = now;
                tx.set(userRef, userUpdate, { merge: true });
            }
            // ── Write coin balance + a single aggregate transaction record ──
            if (totalCoinsGranted > 0) {
                tx.set(balanceRef, {
                    userId: uid,
                    totalCoins: runningBalance,
                    earnedCoins: (balanceData === null || balanceData === void 0 ? void 0 : balanceData.earnedCoins) || 0,
                    purchasedCoins: (balanceData === null || balanceData === void 0 ? void 0 : balanceData.purchasedCoins) || 0,
                    giftedCoins: (balanceData === null || balanceData === void 0 ? void 0 : balanceData.giftedCoins) || 0,
                    spentCoins: (balanceData === null || balanceData === void 0 ? void 0 : balanceData.spentCoins) || 0,
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
                    metadata: { couponId: couponRef.id, couponCode: coupon.code, source: 'coupon' },
                    createdAt: now,
                });
            }
            const grantSummary = (0, grants_2.summariseGrants)(grants);
            // ── Write redemption record + bump counter (one per coupon redemption) ──
            tx.set(redemptionRef, {
                redeemedAt: now,
                userEmail,
                grantSummary,
                couponCode: coupon.code,
            });
            tx.update(couponRef, {
                redemptionsCount: admin.firestore.FieldValue.increment(1),
                lastRedeemedAt: now,
            });
            // ── Build backward-compatible response ──
            const response = {
                ok: true,
                type: coupon.type || grants[0].kind,
                durationDays: firstDurationDays !== null && firstDurationDays !== void 0 ? firstDurationDays : 0,
                grantSummary,
                grants,
            };
            if (firstTier)
                response.tier = firstTier;
            if (firstCoinAmount !== undefined)
                response.coinAmount = firstCoinAmount;
            if (firstMembershipExt) {
                response.effectiveTier = firstMembershipExt.effectiveTier;
                response.newEndDate = firstMembershipExt.newEndDate.toISOString();
            }
            (0, utils_1.logInfo)(`redeemCoupon uid=${uid} couponId=${couponRef.id} code=${coupon.code} grant=${grantSummary}`);
            return response;
        });
        // Best-effort post-commit email — non-fatal.
        try {
            const { sendCouponRedeemedEmail } = await Promise.resolve().then(() => __importStar(require('../notifications/couponEmails')));
            await sendCouponRedeemedEmail(uid, {
                couponCode: code,
                grantSummary: result.grantSummary,
                newEndDate: result.newEndDate,
            });
        }
        catch (emailErr) {
            (0, utils_1.logError)(`redeemCoupon: email notify failed for uid=${uid}`, emailErr);
        }
        return result;
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        (0, utils_1.logError)(`redeemCoupon failed uid=${uid}`, err);
        throw new https_1.HttpsError('internal', 'Failed to redeem coupon');
    }
});
//# sourceMappingURL=redeemCoupon.js.map