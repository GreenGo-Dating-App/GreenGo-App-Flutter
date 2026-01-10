"use strict";
/**
 * Coin Service
 * 6 Cloud Functions for managing virtual currency system
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
exports.claimReward = exports.sendExpirationWarnings = exports.processExpiredCoins = exports.grantMonthlyAllowances = exports.verifyAppStoreCoinPurchase = exports.verifyGooglePlayCoinPurchase = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
// Coin packages
const COIN_PACKAGES = {
    starter: { coins: 100, price: 0.99 },
    popular: { coins: 500, price: 4.99 },
    value: { coins: 1000, price: 8.99 },
    premium: { coins: 5000, price: 39.99 },
};
// Monthly allowances by tier
const MONTHLY_ALLOWANCES = {
    [types_1.SubscriptionTier.BASIC]: 0,
    [types_1.SubscriptionTier.SILVER]: 100,
    [types_1.SubscriptionTier.GOLD]: 250,
};
// Rewards
const REWARDS = {
    first_match: 50,
    complete_profile: 100,
    daily_login: 10,
    week_streak: 50,
    month_streak: 200,
    photo_verification: 75,
    refer_friend: 100,
};
exports.verifyGooglePlayCoinPurchase = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { purchaseToken, productId, packageType } = request.data;
        if (!purchaseToken || !productId || !packageType) {
            throw new https_1.HttpsError('invalid-argument', 'purchaseToken, productId, and packageType are required');
        }
        (0, utils_1.logInfo)(`Verifying Google Play purchase for user ${uid}: ${packageType}`);
        // In production, verify with Google Play Billing API
        // const { data } = await googlePlayBilling.purchases.products.get({
        //   packageName: 'com.greengo.app',
        //   productId,
        //   token: purchaseToken,
        // });
        // For now, simulate successful verification
        const coinPackage = COIN_PACKAGES[packageType];
        if (!coinPackage) {
            throw new https_1.HttpsError('invalid-argument', 'Invalid package type');
        }
        // Check if purchase already processed
        const existingPurchase = await utils_1.db
            .collection('coin_transactions')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (!existingPurchase.empty) {
            throw new https_1.HttpsError('already-exists', 'Purchase already processed');
        }
        // Get current coin balance
        const balanceRef = utils_1.db.collection('coin_balances').doc(uid);
        const balanceDoc = await balanceRef.get();
        const currentBalance = ((_a = balanceDoc.data()) === null || _a === void 0 ? void 0 : _a.totalCoins) || 0;
        // Create coin batch
        const batchId = `batch_${Date.now()}`;
        const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 365 days
        await utils_1.db.runTransaction(async (transaction) => {
            var _a;
            const balanceSnapshot = await transaction.get(balanceRef);
            const batches = ((_a = balanceSnapshot.data()) === null || _a === void 0 ? void 0 : _a.batches) || [];
            batches.push({
                id: batchId,
                amount: coinPackage.coins,
                source: types_1.CoinSource.PURCHASED,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                remainingAmount: coinPackage.coins,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transaction.set(balanceRef, {
                totalCoins: admin.firestore.FieldValue.increment(coinPackage.coins),
                batches,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            // Record transaction
            const transactionRef = utils_1.db.collection('coin_transactions').doc();
            transaction.set(transactionRef, {
                userId: uid,
                amount: coinPackage.coins,
                type: 'credit',
                source: types_1.CoinSource.PURCHASED,
                description: `Purchased ${packageType} package`,
                purchaseToken,
                productId,
                platform: 'android',
                batchId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                balanceAfter: currentBalance + coinPackage.coins,
            });
        });
        return {
            success: true,
            coinsAdded: coinPackage.coins,
            newBalance: currentBalance + coinPackage.coins,
            expiresAt: expiresAt.toISOString(),
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 2. VERIFY APP STORE COIN PURCHASE (HTTP Callable) ==========
exports.verifyAppStoreCoinPurchase = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { purchaseToken, productId, packageType } = request.data;
        if (!purchaseToken || !productId || !packageType) {
            throw new https_1.HttpsError('invalid-argument', 'purchaseToken, productId, and packageType are required');
        }
        (0, utils_1.logInfo)(`Verifying App Store purchase for user ${uid}: ${packageType}`);
        // In production, verify with App Store Server API
        // Similar implementation to Google Play verification
        const coinPackage = COIN_PACKAGES[packageType];
        if (!coinPackage) {
            throw new https_1.HttpsError('invalid-argument', 'Invalid package type');
        }
        // Check for duplicate
        const existingPurchase = await utils_1.db
            .collection('coin_transactions')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (!existingPurchase.empty) {
            throw new https_1.HttpsError('already-exists', 'Purchase already processed');
        }
        const balanceRef = utils_1.db.collection('coin_balances').doc(uid);
        const balanceDoc = await balanceRef.get();
        const currentBalance = ((_a = balanceDoc.data()) === null || _a === void 0 ? void 0 : _a.totalCoins) || 0;
        const batchId = `batch_${Date.now()}`;
        const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
        await utils_1.db.runTransaction(async (transaction) => {
            var _a;
            const balanceSnapshot = await transaction.get(balanceRef);
            const batches = ((_a = balanceSnapshot.data()) === null || _a === void 0 ? void 0 : _a.batches) || [];
            batches.push({
                id: batchId,
                amount: coinPackage.coins,
                source: types_1.CoinSource.PURCHASED,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                remainingAmount: coinPackage.coins,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transaction.set(balanceRef, {
                totalCoins: admin.firestore.FieldValue.increment(coinPackage.coins),
                batches,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            const transactionRef = utils_1.db.collection('coin_transactions').doc();
            transaction.set(transactionRef, {
                userId: uid,
                amount: coinPackage.coins,
                type: 'credit',
                source: types_1.CoinSource.PURCHASED,
                description: `Purchased ${packageType} package`,
                purchaseToken,
                productId,
                platform: 'ios',
                batchId,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                balanceAfter: currentBalance + coinPackage.coins,
            });
        });
        return {
            success: true,
            coinsAdded: coinPackage.coins,
            newBalance: currentBalance + coinPackage.coins,
            expiresAt: expiresAt.toISOString(),
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 3. GRANT MONTHLY ALLOWANCES (Scheduled - Monthly 1st) ==========
exports.grantMonthlyAllowances = (0, scheduler_1.onSchedule)({
    schedule: '0 0 1 * *', // 1st of every month at midnight UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    (0, utils_1.logInfo)('Granting monthly coin allowances');
    try {
        // Get all users with active subscriptions
        const usersSnapshot = await utils_1.db
            .collection('users')
            .where('subscriptionTier', 'in', [types_1.SubscriptionTier.SILVER, types_1.SubscriptionTier.GOLD])
            .get();
        (0, utils_1.logInfo)(`Found ${usersSnapshot.size} eligible users for allowances`);
        let grantedCount = 0;
        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const userId = userDoc.id;
            const tier = userData.subscriptionTier;
            const allowance = MONTHLY_ALLOWANCES[tier];
            if (!allowance)
                continue;
            try {
                const balanceRef = utils_1.db.collection('coin_balances').doc(userId);
                const batchId = `allowance_${Date.now()}_${userId}`;
                const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
                await utils_1.db.runTransaction(async (transaction) => {
                    var _a, _b;
                    const balanceSnapshot = await transaction.get(balanceRef);
                    const batches = ((_a = balanceSnapshot.data()) === null || _a === void 0 ? void 0 : _a.batches) || [];
                    batches.push({
                        id: batchId,
                        amount: allowance,
                        source: types_1.CoinSource.ALLOWANCE,
                        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                        remainingAmount: allowance,
                        createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                    transaction.set(balanceRef, {
                        totalCoins: admin.firestore.FieldValue.increment(allowance),
                        batches,
                        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                    }, { merge: true });
                    const transactionRef = utils_1.db.collection('coin_transactions').doc();
                    transaction.set(transactionRef, {
                        userId,
                        amount: allowance,
                        type: 'credit',
                        source: types_1.CoinSource.ALLOWANCE,
                        description: `Monthly ${tier} allowance`,
                        batchId,
                        timestamp: admin.firestore.FieldValue.serverTimestamp(),
                        balanceAfter: (((_b = balanceSnapshot.data()) === null || _b === void 0 ? void 0 : _b.totalCoins) || 0) + allowance,
                    });
                });
                // Send notification
                await utils_1.db.collection('notifications').add({
                    userId,
                    type: 'coins_credited',
                    title: 'Monthly Coins Added!',
                    body: `You received ${allowance} coins as part of your ${tier} subscription`,
                    read: false,
                    sent: false,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                grantedCount++;
            }
            catch (error) {
                (0, utils_1.logError)(`Error granting allowance to user ${userId}:`, error);
            }
        }
        (0, utils_1.logInfo)(`Monthly allowances granted to ${grantedCount} users`);
    }
    catch (error) {
        (0, utils_1.logError)('Error granting monthly allowances:', error);
        throw error;
    }
});
// ========== 4. PROCESS EXPIRED COINS (Scheduled - Daily 2am) ==========
exports.processExpiredCoins = (0, scheduler_1.onSchedule)({
    schedule: '0 2 * * *', // Daily at 2 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Processing expired coins');
    try {
        const now = admin.firestore.Timestamp.now();
        // Get all balances with batches
        const balancesSnapshot = await utils_1.db.collection('coin_balances').get();
        let processedCount = 0;
        let totalExpiredCoins = 0;
        for (const balanceDoc of balancesSnapshot.docs) {
            const data = balanceDoc.data();
            const userId = balanceDoc.id;
            const batches = data.batches || [];
            // Find expired batches
            const expiredBatches = batches.filter((batch) => batch.expiresAt.toMillis() < now.toMillis() && batch.remainingAmount > 0);
            if (expiredBatches.length === 0)
                continue;
            const expiredCoins = expiredBatches.reduce((sum, batch) => sum + batch.remainingAmount, 0);
            // Remove expired batches
            const activeBatches = batches.filter((batch) => batch.expiresAt.toMillis() >= now.toMillis() || batch.remainingAmount === 0);
            await balanceDoc.ref.update({
                batches: activeBatches,
                totalCoins: admin.firestore.FieldValue.increment(-expiredCoins),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Record expiration
            await utils_1.db.collection('coin_transactions').add({
                userId,
                amount: expiredCoins,
                type: 'debit',
                source: types_1.CoinSource.PURCHASED,
                description: 'Coins expired (365 days)',
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                balanceAfter: data.totalCoins - expiredCoins,
            });
            processedCount++;
            totalExpiredCoins += expiredCoins;
        }
        (0, utils_1.logInfo)(`Processed ${processedCount} users, ${totalExpiredCoins} coins expired`);
    }
    catch (error) {
        (0, utils_1.logError)('Error processing expired coins:', error);
        throw error;
    }
});
// ========== 5. SEND EXPIRATION WARNINGS (Scheduled - Daily 10am) ==========
exports.sendExpirationWarnings = (0, scheduler_1.onSchedule)({
    schedule: '0 10 * * *', // Daily at 10 AM UTC
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Sending coin expiration warnings');
    try {
        const thirtyDaysFromNow = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
        const balancesSnapshot = await utils_1.db.collection('coin_balances').get();
        let warningsSent = 0;
        for (const balanceDoc of balancesSnapshot.docs) {
            const data = balanceDoc.data();
            const userId = balanceDoc.id;
            const batches = data.batches || [];
            // Find batches expiring soon
            const expiringBatches = batches.filter((batch) => {
                const expiryDate = batch.expiresAt.toDate();
                return (expiryDate <= thirtyDaysFromNow &&
                    expiryDate > new Date() &&
                    batch.remainingAmount > 0);
            });
            if (expiringBatches.length === 0)
                continue;
            const expiringCoins = expiringBatches.reduce((sum, batch) => sum + batch.remainingAmount, 0);
            const earliestExpiry = Math.min(...expiringBatches.map((b) => b.expiresAt.toMillis()));
            const daysUntilExpiry = Math.ceil((earliestExpiry - Date.now()) / (24 * 60 * 60 * 1000));
            // Send warning notification
            await utils_1.db.collection('notifications').add({
                userId,
                type: 'coins_expiring',
                title: 'Coins Expiring Soon!',
                body: `${expiringCoins} coins will expire in ${daysUntilExpiry} days. Use them before they're gone!`,
                data: {
                    expiringCoins,
                    daysUntilExpiry,
                },
                read: false,
                sent: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            warningsSent++;
        }
        (0, utils_1.logInfo)(`Sent ${warningsSent} expiration warnings`);
    }
    catch (error) {
        (0, utils_1.logError)('Error sending expiration warnings:', error);
        throw error;
    }
});
exports.claimReward = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { rewardType, metadata } = request.data;
        if (!rewardType || !REWARDS[rewardType]) {
            throw new https_1.HttpsError('invalid-argument', 'Invalid reward type');
        }
        (0, utils_1.logInfo)(`User ${uid} claiming reward: ${rewardType}`);
        const rewardCoins = REWARDS[rewardType];
        // Check if reward already claimed (for one-time rewards)
        const oneTimeRewards = ['first_match', 'complete_profile', 'photo_verification'];
        if (oneTimeRewards.includes(rewardType)) {
            const existingClaim = await utils_1.db
                .collection('coin_transactions')
                .where('userId', '==', uid)
                .where('source', '==', types_1.CoinSource.EARNED)
                .where('description', '==', `Reward: ${rewardType}`)
                .limit(1)
                .get();
            if (!existingClaim.empty) {
                throw new https_1.HttpsError('already-exists', 'Reward already claimed');
            }
        }
        const balanceRef = utils_1.db.collection('coin_balances').doc(uid);
        const balanceDoc = await balanceRef.get();
        const currentBalance = ((_a = balanceDoc.data()) === null || _a === void 0 ? void 0 : _a.totalCoins) || 0;
        const batchId = `reward_${rewardType}_${Date.now()}`;
        const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
        await utils_1.db.runTransaction(async (transaction) => {
            var _a;
            const balanceSnapshot = await transaction.get(balanceRef);
            const batches = ((_a = balanceSnapshot.data()) === null || _a === void 0 ? void 0 : _a.batches) || [];
            batches.push({
                id: batchId,
                amount: rewardCoins,
                source: types_1.CoinSource.EARNED,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                remainingAmount: rewardCoins,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            transaction.set(balanceRef, {
                totalCoins: admin.firestore.FieldValue.increment(rewardCoins),
                batches,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            const transactionRef = utils_1.db.collection('coin_transactions').doc();
            transaction.set(transactionRef, {
                userId: uid,
                amount: rewardCoins,
                type: 'credit',
                source: types_1.CoinSource.EARNED,
                description: `Reward: ${rewardType}`,
                batchId,
                metadata,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                balanceAfter: currentBalance + rewardCoins,
            });
        });
        return {
            success: true,
            coinsEarned: rewardCoins,
            newBalance: currentBalance + rewardCoins,
            rewardType,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map