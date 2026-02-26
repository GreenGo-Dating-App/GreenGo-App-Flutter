"use strict";
/**
 * Membership Service (One-Time Purchases)
 * Cloud Functions for managing one-time membership purchases
 * No recurring billing — users buy consumable products to extend membership duration
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
exports.handleExpiredMemberships = exports.checkExpiringSubscriptions = exports.verifyPurchase = void 0;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
const purchase_verification_1 = require("../shared/purchase_verification");
// Product ID → tier and duration mapping
const PRODUCT_CONFIG = {
    'greengo_base_membership': { tier: 'BASIC', durationDays: 365, price: 9.99 },
    '1_month_silver': { tier: 'SILVER', durationDays: 30, price: 9.99 },
    '1_year_silver': { tier: 'SILVER', durationDays: 365, price: 99.90 },
    '1_month_gold': { tier: 'GOLD', durationDays: 30, price: 19.99 },
    '1_year_gold': { tier: 'GOLD', durationDays: 365, price: 199.90 },
    '1_month_platinum': { tier: 'PLATINUM', durationDays: 30, price: 29.99 },
    '1_year_platinum_membership': { tier: 'PLATINUM', durationDays: 365, price: 299.90 },
};
// Tier hierarchy for upgrade logic
const TIER_RANK = {
    'BASIC': 0,
    'SILVER': 1,
    'GOLD': 2,
    'PLATINUM': 3,
};
// ========== 0. VERIFY PURCHASE (Callable) ==========
exports.verifyPurchase = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    var _a;
    // Verify user is authenticated
    if (!request.auth) {
        throw new https_1.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, platform, productId, purchaseToken, verificationData, transactionDate } = request.data;
    // Validate required fields
    if (!userId || !platform || !productId || !purchaseToken) {
        throw new https_1.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Ensure the authenticated user matches the userId
    if (request.auth.uid !== userId) {
        throw new https_1.HttpsError('permission-denied', 'User ID mismatch');
    }
    const userEmail = request.auth.token.email || null;
    try {
        (0, utils_1.logInfo)(`Verifying membership purchase for user ${userId} (${userEmail}), product ${productId}, platform ${platform}`);
        // Look up product configuration
        const config = PRODUCT_CONFIG[productId];
        if (!config) {
            throw new https_1.HttpsError('invalid-argument', `Unknown product ID: ${productId}`);
        }
        const tier = config.tier;
        const durationDays = config.durationDays;
        const durationMs = durationDays * 24 * 60 * 60 * 1000;
        // Verify purchase with the respective store
        let verified = false;
        if (platform === 'android') {
            // verificationData = Google Play purchase token (from serverVerificationData)
            if (!verificationData) {
                throw new https_1.HttpsError('invalid-argument', 'Missing verificationData for Android purchase');
            }
            const result = await (0, purchase_verification_1.verifyGooglePlayPurchase)(productId, verificationData);
            verified = result.verified;
            if (!verified) {
                (0, utils_1.logError)(`Google Play verification failed for ${productId}: ${result.error}`);
            }
        }
        else if (platform === 'ios') {
            // verificationData = JWS signed transaction from StoreKit 2
            if (!verificationData) {
                throw new https_1.HttpsError('invalid-argument', 'Missing verificationData for iOS purchase');
            }
            const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
            const result = await (0, purchase_verification_1.verifyAppStorePurchase)(verificationData, productId, appAppleId);
            verified = result.verified;
            if (!verified) {
                (0, utils_1.logError)(`App Store verification failed for ${productId}: ${result.error}`);
            }
        }
        else {
            (0, utils_1.logError)(`Unknown platform: ${platform}`);
            throw new https_1.HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
        }
        if (!verified) {
            throw new https_1.HttpsError('failed-precondition', 'Purchase verification failed');
        }
        // CRITICAL: Prevent shared billing account abuse.
        const tokenSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (!tokenSnapshot.empty) {
            const existingOwner = tokenSnapshot.docs[0].data().userId;
            if (existingOwner !== userId) {
                (0, utils_1.logInfo)(`Purchase token already belongs to user ${existingOwner}, rejecting for user ${userId}`);
                throw new https_1.HttpsError('already-exists', 'This purchase is already linked to a different account.');
            }
        }
        const purchaseTokenCheck = await utils_1.db
            .collection('purchases')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (!purchaseTokenCheck.empty) {
            const purchaseOwner = purchaseTokenCheck.docs[0].data().userId;
            if (purchaseOwner !== userId) {
                throw new https_1.HttpsError('already-exists', 'This purchase is already linked to a different account.');
            }
        }
        const now = admin.firestore.Timestamp.now();
        const nowDate = now.toDate();
        // ── Compute new end date with extension/upgrade logic ──
        const profileDoc = await utils_1.db.collection('profiles').doc(userId).get();
        const profileData = profileDoc.data() || {};
        const currentTier = profileData.membershipTier || 'BASIC';
        const currentEndTimestamp = profileData.membershipEndDate;
        const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;
        let newEndDate;
        let effectiveTier = tier;
        if (currentEndDate && currentEndDate > nowDate) {
            // User has active membership
            const purchasedRank = TIER_RANK[tier] || 0;
            const currentRank = TIER_RANK[currentTier] || 0;
            if (purchasedRank >= currentRank) {
                // Same or higher tier: user gets higher tier immediately, end date extends from current end
                newEndDate = new Date(currentEndDate.getTime() + durationMs);
                effectiveTier = tier;
            }
            else {
                // Lower tier: keep higher tier, extend end date from current end
                newEndDate = new Date(currentEndDate.getTime() + durationMs);
                effectiveTier = currentTier;
            }
        }
        else {
            // No active membership or expired — start from now
            newEndDate = new Date(nowDate.getTime() + durationMs);
        }
        const endTimestamp = admin.firestore.Timestamp.fromDate(newEndDate);
        // ── Create subscription record ──
        await utils_1.db.collection('subscriptions').add({
            userId: userId,
            userEmail: userEmail,
            tier: effectiveTier,
            status: types_1.SubscriptionStatus.ACTIVE,
            startDate: now,
            endDate: endTimestamp,
            durationDays: durationDays,
            platform: platform,
            purchaseToken: purchaseToken,
            transactionId: purchaseToken,
            orderId: purchaseToken,
            productId: productId,
            price: config.price,
            currency: 'USD',
            createdAt: now,
        });
        // ── Create purchase record ──
        await utils_1.db.collection('purchases').add({
            userId: userId,
            userEmail: userEmail,
            type: 'membership',
            status: 'completed',
            productId: productId,
            tier: effectiveTier,
            price: config.price,
            currency: 'USD',
            platform: platform,
            purchaseToken: purchaseToken,
            transactionId: purchaseToken,
            durationDays: durationDays,
            purchaseDate: now,
            verifiedAt: now,
            verificationMethod: 'cloud_function',
        });
        // ── Update profile with membership info ──
        const profileUpdate = {
            membershipTier: effectiveTier,
            membershipEndDate: endTimestamp,
            membershipStartDate: now,
            updatedAt: now,
        };
        // For base membership, also set the baseMembership fields used by app gates
        if (productId === 'greengo_base_membership') {
            profileUpdate.hasBaseMembership = true;
            profileUpdate.baseMembershipEndDate = endTimestamp;
        }
        await utils_1.db.collection('profiles').doc(userId).update(profileUpdate);
        await utils_1.db.collection('users').doc(userId).update({
            subscriptionTier: effectiveTier,
            membershipEndDate: endTimestamp,
            updatedAt: now,
        });
        // ── Grant 500 coins for base membership ──
        let coinsGranted = 0;
        if (productId === 'greengo_base_membership') {
            const balanceRef = utils_1.db.collection('coinBalances').doc(userId);
            const balanceDoc = await balanceRef.get();
            if (balanceDoc.exists) {
                const currentTotal = ((_a = balanceDoc.data()) === null || _a === void 0 ? void 0 : _a.totalCoins) || 0;
                await balanceRef.update({ totalCoins: currentTotal + 500 });
            }
            else {
                await balanceRef.set({
                    userId: userId,
                    totalCoins: 500,
                    spentCoins: 0,
                    lastUpdated: now,
                });
            }
            await balanceRef.collection('coinBatches').add({
                amount: 500,
                remainingCoins: 500,
                source: 'membership_bonus',
                reason: 'Base membership welcome bonus',
                createdAt: now,
                expiresAt: endTimestamp,
            });
            coinsGranted = 500;
            (0, utils_1.logInfo)(`Granted 500 bonus coins to user ${userId}`);
        }
        (0, utils_1.logInfo)(`Membership purchase verified for user ${userId}: tier=${effectiveTier}, endDate=${newEndDate.toISOString()}, coins=${coinsGranted}`);
        return {
            verified: true,
            tier: effectiveTier,
            endDate: newEndDate.toISOString(),
            coinsGranted: coinsGranted,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error verifying purchase:', error);
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError('internal', 'Failed to verify purchase');
    }
});
// ========== 1. CHECK EXPIRING MEMBERSHIPS (Scheduled - Daily 9am) ==========
exports.checkExpiringSubscriptions = (0, scheduler_1.onSchedule)({
    schedule: '0 9 * * *', // Daily at 9 AM UTC
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    var _a;
    (0, utils_1.logInfo)('Checking for expiring memberships');
    try {
        const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
        // Find profiles with membership ending within 3 days
        const snapshot = await utils_1.db
            .collection('profiles')
            .where('membershipEndDate', '<', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
            .where('membershipEndDate', '>', admin.firestore.Timestamp.now())
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} memberships expiring soon`);
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const endDate = (_a = data.membershipEndDate) === null || _a === void 0 ? void 0 : _a.toDate();
            if (!endDate)
                continue;
            const daysUntilExpiry = Math.ceil((endDate.getTime() - Date.now()) / (24 * 60 * 60 * 1000));
            await utils_1.db.collection('notifications').add({
                userId: doc.id,
                type: 'membership_expiring',
                title: 'Membership Expiring Soon',
                body: `Your ${data.membershipTier || 'membership'} expires in ${daysUntilExpiry} day${daysUntilExpiry !== 1 ? 's' : ''}. Extend now to keep your premium features!`,
                data: {
                    tier: data.membershipTier,
                    expiresAt: endDate.toISOString(),
                },
                read: false,
                sent: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            (0, utils_1.logInfo)(`Sent expiry reminder to user ${doc.id}`);
        }
        (0, utils_1.logInfo)('Expiring memberships check completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error checking expiring memberships:', error);
        throw error;
    }
});
// ========== 2. HANDLE EXPIRED MEMBERSHIPS (Scheduled - Hourly) ==========
exports.handleExpiredMemberships = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async () => {
    (0, utils_1.logInfo)('Checking for expired memberships');
    try {
        const now = admin.firestore.Timestamp.now();
        // Find profiles with expired membership end dates
        const snapshot = await utils_1.db
            .collection('profiles')
            .where('membershipEndDate', '<', now)
            .where('membershipTier', '!=', 'BASIC')
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} expired memberships`);
        for (const doc of snapshot.docs) {
            const data = doc.data();
            // Downgrade to basic/free and clear base membership
            await doc.ref.update({
                membershipTier: 'BASIC',
                hasBaseMembership: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Also update users collection
            try {
                await utils_1.db.collection('users').doc(doc.id).update({
                    subscriptionTier: types_1.SubscriptionTier.BASIC,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            catch (e) {
                (0, utils_1.logError)(`Failed to update users collection for ${doc.id}:`, e);
            }
            // Mark any active subscriptions as expired
            const activeSubs = await utils_1.db
                .collection('subscriptions')
                .where('userId', '==', doc.id)
                .where('status', '==', types_1.SubscriptionStatus.ACTIVE)
                .get();
            for (const subDoc of activeSubs.docs) {
                await subDoc.ref.update({
                    status: types_1.SubscriptionStatus.EXPIRED,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
            // Send notification
            await utils_1.db.collection('notifications').add({
                userId: doc.id,
                type: 'membership_expired',
                title: 'Membership Expired',
                body: 'Your membership has expired. Purchase a new membership to restore premium features.',
                read: false,
                sent: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            (0, utils_1.logInfo)(`Downgraded user ${doc.id} from ${data.membershipTier} to BASIC`);
        }
        (0, utils_1.logInfo)(`Processed ${snapshot.size} expired memberships`);
    }
    catch (error) {
        (0, utils_1.logError)('Error handling expired memberships:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map