"use strict";
/**
 * Shared entitlement helpers used by purchase verification and coupon redemption.
 * Centralises tier extension rules and coin granting so paid and promo flows stay in sync.
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
exports.grantCoins = exports.grantBaseMembership = exports.grantMembership = exports.computeMembershipExtension = exports.TIER_RANK = void 0;
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("./utils");
exports.TIER_RANK = {
    BASIC: 0,
    SILVER: 1,
    GOLD: 2,
    PLATINUM: 3,
};
/**
 * Pure tier-extension rule (no IO). Never downgrades an active higher tier.
 * - If user has an active membership with a higher rank than `requestedTier`,
 *   the existing tier is preserved and the end date is pushed by `durationMs`.
 * - If `requestedTier` is same or higher rank, the user moves to `requestedTier`
 *   and the end date is pushed by `durationMs` from the later of now or current end.
 * - If user has no active membership (or it has expired), start from `now`.
 */
function computeMembershipExtension(currentTier, currentEndDate, requestedTier, durationMs, now = new Date()) {
    var _a, _b;
    const isActive = currentEndDate !== null && currentEndDate > now;
    let effectiveTier = requestedTier;
    let baseDate = now;
    if (isActive) {
        const currentRank = (_a = exports.TIER_RANK[currentTier]) !== null && _a !== void 0 ? _a : 0;
        const requestedRank = (_b = exports.TIER_RANK[requestedTier]) !== null && _b !== void 0 ? _b : 0;
        effectiveTier = requestedRank >= currentRank ? requestedTier : (currentTier || requestedTier);
        baseDate = currentEndDate;
    }
    const newEndDate = new Date(baseDate.getTime() + durationMs);
    return {
        effectiveTier,
        newEndDate,
        newEndTimestamp: admin.firestore.Timestamp.fromDate(newEndDate),
    };
}
exports.computeMembershipExtension = computeMembershipExtension;
/**
 * Grants or extends a paid membership tier (SILVER / GOLD / PLATINUM).
 * Applies the never-downgrade extension rule. Updates `profiles/{uid}` and `users/{uid}`.
 * Returns the effective tier + new end date so callers can record audit data.
 */
async function grantMembership(uid, requestedTier, durationMs) {
    const profileSnap = await utils_1.db.collection('profiles').doc(uid).get();
    const profileData = profileSnap.data() || {};
    const currentTier = profileData.membershipTier || 'BASIC';
    const currentEndTimestamp = profileData.membershipEndDate;
    const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;
    const now = admin.firestore.Timestamp.now();
    const result = computeMembershipExtension(currentTier, currentEndDate, requestedTier, durationMs, now.toDate());
    await utils_1.db.collection('profiles').doc(uid).update({
        membershipTier: result.effectiveTier,
        membershipStartDate: now,
        membershipEndDate: result.newEndTimestamp,
        updatedAt: now,
    });
    await utils_1.db.collection('users').doc(uid).update({
        subscriptionTier: result.effectiveTier,
        membershipEndDate: result.newEndTimestamp,
        updatedAt: now,
    });
    (0, utils_1.logInfo)(`grantMembership uid=${uid} tier=${result.effectiveTier} endDate=${result.newEndDate.toISOString()}`);
    return result;
}
exports.grantMembership = grantMembership;
/**
 * Grants or extends the BASE membership flag (hasBaseMembership + baseMembershipEndDate).
 * Independent of the tier system — a user may have BASE active and any tier active simultaneously.
 * Extends the existing baseMembershipEndDate if still in the future, otherwise starts from now.
 */
async function grantBaseMembership(uid, durationMs) {
    const profileSnap = await utils_1.db.collection('profiles').doc(uid).get();
    const profileData = profileSnap.data() || {};
    const currentEndTimestamp = profileData.baseMembershipEndDate;
    const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;
    const now = admin.firestore.Timestamp.now();
    const nowDate = now.toDate();
    const baseDate = currentEndDate && currentEndDate > nowDate ? currentEndDate : nowDate;
    const newEndDate = new Date(baseDate.getTime() + durationMs);
    const newEndTimestamp = admin.firestore.Timestamp.fromDate(newEndDate);
    await utils_1.db.collection('profiles').doc(uid).update({
        hasBaseMembership: true,
        baseMembershipEndDate: newEndTimestamp,
        updatedAt: now,
    });
    (0, utils_1.logInfo)(`grantBaseMembership uid=${uid} endDate=${newEndDate.toISOString()}`);
    return { newEndDate, newEndTimestamp };
}
exports.grantBaseMembership = grantBaseMembership;
/**
 * Credits coins to a user's balance. Uses the embedded `coinBatches` array shape
 * that `processExpiredCoins` reads, so granted coins are subject to the normal
 * 365-day expiration rules.
 *
 * `source` is one of: 'purchase' | 'reward' | 'allowance' | 'coupon' | 'membership_bonus'
 * `reason` is a free-text reason recorded on the coinTransactions doc.
 */
async function grantCoins(uid, amount, source, reason, metadata = {}) {
    if (amount <= 0)
        return;
    const COIN_EXPIRATION_DAYS = 365;
    await utils_1.db.runTransaction(async (transaction) => {
        const balanceRef = utils_1.db.collection('coinBalances').doc(uid);
        const balanceDoc = await transaction.get(balanceRef);
        let currentBalance = 0;
        let earnedCoins = 0;
        let purchasedCoins = 0;
        let giftedCoins = 0;
        let spentCoins = 0;
        let coinBatches = [];
        if (balanceDoc.exists) {
            const data = balanceDoc.data();
            currentBalance = data.totalCoins || 0;
            earnedCoins = data.earnedCoins || 0;
            purchasedCoins = data.purchasedCoins || 0;
            giftedCoins = data.giftedCoins || 0;
            spentCoins = data.spentCoins || 0;
            coinBatches = data.coinBatches || [];
        }
        const now = admin.firestore.Timestamp.now();
        const expirationDate = new Date();
        expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);
        const batchId = utils_1.db.collection('temp').doc().id;
        coinBatches.push({
            batchId,
            initialCoins: amount,
            remainingCoins: amount,
            source,
            acquiredDate: now,
            expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
        });
        transaction.set(balanceRef, {
            userId: uid,
            totalCoins: currentBalance + amount,
            earnedCoins: source === 'reward' || source === 'allowance' ? earnedCoins + amount : earnedCoins,
            purchasedCoins: source === 'purchase' ? purchasedCoins + amount : purchasedCoins,
            giftedCoins,
            spentCoins,
            lastUpdated: now,
            coinBatches,
        }, { merge: true });
        const transactionRef = utils_1.db.collection('coinTransactions').doc();
        transaction.set(transactionRef, {
            userId: uid,
            type: 'credit',
            amount,
            balanceAfter: currentBalance + amount,
            reason,
            metadata: Object.assign({ source }, metadata),
            createdAt: now,
        });
    });
    (0, utils_1.logInfo)(`grantCoins uid=${uid} amount=${amount} source=${source} reason=${reason}`);
}
exports.grantCoins = grantCoins;
//# sourceMappingURL=grants.js.map