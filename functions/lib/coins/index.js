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
exports.declineGift = exports.giftCoins = exports.claimReward = exports.sendExpirationWarnings = exports.processExpiredCoins = exports.grantMonthlyAllowances = exports.verifyAppStoreCoinPurchase = exports.verifyGooglePlayCoinPurchase = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
const purchase_verification_1 = require("../shared/purchase_verification");
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
        const { purchaseToken, productId, packageType, verificationData } = request.data;
        if (!purchaseToken || !productId || !packageType) {
            throw new https_1.HttpsError('invalid-argument', 'purchaseToken, productId, and packageType are required');
        }
        (0, utils_1.logInfo)(`Verifying Google Play purchase for user ${uid}: ${packageType}`);
        // Verify with Google Play Developer API
        const gpToken = verificationData || purchaseToken;
        const verificationResult = await (0, purchase_verification_1.verifyGooglePlayPurchase)(productId, gpToken);
        if (!verificationResult.verified) {
            (0, utils_1.logError)(`Google Play coin purchase verification failed: ${verificationResult.error}`);
            throw new https_1.HttpsError('failed-precondition', 'Purchase verification failed');
        }
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
        const { purchaseToken, productId, packageType, verificationData } = request.data;
        if (!purchaseToken || !productId || !packageType) {
            throw new https_1.HttpsError('invalid-argument', 'purchaseToken, productId, and packageType are required');
        }
        (0, utils_1.logInfo)(`Verifying App Store purchase for user ${uid}: ${packageType}`);
        // Verify with App Store Server API (StoreKit 2 JWS)
        const jws = verificationData || purchaseToken;
        const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
        const verificationResult = await (0, purchase_verification_1.verifyAppStorePurchase)(jws, productId, appAppleId);
        if (!verificationResult.verified) {
            (0, utils_1.logError)(`App Store coin purchase verification failed: ${verificationResult.error}`);
            throw new https_1.HttpsError('failed-precondition', 'Purchase verification failed');
        }
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
/**
 * P2P coin gift. Atomically debits the sender's `coinBalances` and credits the
 * receiver's, plus writes a ledger entry for each. This MUST be server-side:
 * Firestore rules only let a user write their OWN balance doc, so the client
 * (which tried to write the receiver's balance directly) was always denied and
 * gifting failed. The Admin SDK bypasses those rules.
 */
exports.giftCoins = (0, https_1.onCall)({ memory: '256MiB', timeoutSeconds: 60 }, async (request) => {
    try {
        const senderId = await (0, utils_1.verifyAuth)(request.auth);
        const { receiverId, amount, message } = request.data;
        if (!receiverId || typeof receiverId !== 'string') {
            throw new https_1.HttpsError('invalid-argument', 'receiverId is required');
        }
        if (receiverId === senderId) {
            throw new https_1.HttpsError('invalid-argument', 'Cannot gift coins to yourself');
        }
        if (!Number.isInteger(amount) || amount <= 0 || amount > 100000) {
            throw new https_1.HttpsError('invalid-argument', 'amount must be a positive integer up to 100000');
        }
        // Recipient must exist.
        const receiverProfile = await utils_1.db.collection('profiles').doc(receiverId).get();
        if (!receiverProfile.exists) {
            throw new https_1.HttpsError('not-found', 'Recipient not found');
        }
        const senderRef = utils_1.db.collection('coinBalances').doc(senderId);
        const receiverRef = utils_1.db.collection('coinBalances').doc(receiverId);
        let senderNewTotal = 0;
        let receiverNewTotal = 0;
        await utils_1.db.runTransaction(async (transaction) => {
            var _a, _b;
            const senderDoc = await transaction.get(senderRef);
            const receiverDoc = await transaction.get(receiverRef);
            const senderTotal = ((_a = senderDoc.data()) === null || _a === void 0 ? void 0 : _a.totalCoins) || 0;
            if (senderTotal < amount) {
                throw new https_1.HttpsError('failed-precondition', 'Insufficient coins');
            }
            const receiverTotal = ((_b = receiverDoc.data()) === null || _b === void 0 ? void 0 : _b.totalCoins) || 0;
            senderNewTotal = senderTotal - amount;
            receiverNewTotal = receiverTotal + amount;
            const now = admin.firestore.FieldValue.serverTimestamp();
            const inc = admin.firestore.FieldValue.increment;
            transaction.set(senderRef, {
                userId: senderId,
                totalCoins: inc(-amount),
                spentCoins: inc(amount),
                lastUpdated: now,
            }, { merge: true });
            transaction.set(receiverRef, {
                userId: receiverId,
                totalCoins: inc(amount),
                giftedCoins: inc(amount),
                lastUpdated: now,
            }, { merge: true });
            transaction.set(utils_1.db.collection('coinTransactions').doc(), {
                userId: senderId,
                type: 'debit',
                amount,
                balanceAfter: senderNewTotal,
                reason: 'Gift sent',
                metadata: { toUserId: receiverId, message: message || null, source: 'gift' },
                createdAt: now,
            });
            transaction.set(utils_1.db.collection('coinTransactions').doc(), {
                userId: receiverId,
                type: 'credit',
                amount,
                balanceAfter: receiverNewTotal,
                reason: 'Gift received',
                metadata: { fromUserId: senderId, message: message || null, source: 'gift' },
                createdAt: now,
            });
        });
        (0, utils_1.logInfo)(`giftCoins ${senderId} -> ${receiverId} amount=${amount}`);
        // Notify the receiver, always naming the sender. The in-app tile renders
        // `**{actorName}** {title}`; leaving `pushSent` unset lets the push-parity
        // trigger deliver the FCM push (it now prepends actorName to the push
        // title too), so BOTH the in-app tile and the push name the gifter.
        try {
            const senderProfile = (await utils_1.db.collection('profiles').doc(senderId).get()).data() || {};
            const senderName = senderProfile.displayName ||
                senderProfile.nickname ||
                senderProfile.name ||
                'Someone';
            const senderPhoto = senderProfile.profilePhotoUrl ||
                (Array.isArray(senderProfile.photos) ? senderProfile.photos[0] : undefined) ||
                (Array.isArray(senderProfile.photoUrls) ? senderProfile.photoUrls[0] : undefined);
            const title = `sent you ${amount} coins`;
            const body = message && message.trim().length > 0 ? `"${message.trim()}"` : title;
            await utils_1.db.collection('notifications').add(Object.assign(Object.assign({ userId: receiverId, type: 'coins_gift', title, message: body, body, isRead: false, createdAt: admin.firestore.FieldValue.serverTimestamp(), actorId: senderId, actorName: senderName }, (senderPhoto ? { imageUrl: senderPhoto } : {})), { data: {
                    type: 'coins_gift',
                    action: 'open_wallet',
                    actorId: senderId,
                    actorName: senderName,
                    amount: String(amount),
                } }));
        }
        catch (e) {
            (0, utils_1.logError)('giftCoins: failed to write gift notification', e);
        }
        return {
            success: true,
            senderNewBalance: senderNewTotal,
            receiverNewBalance: receiverNewTotal,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
/**
 * Decline a pending P2P coin gift and refund the ORIGINAL SENDER.
 *
 * This MUST be server-side: the refund credits the SENDER's `coinBalances` doc,
 * a cross-user write that Firestore rules (correctly) deny to the client — the
 * client can only write its OWN balance. The old client-side decline refunded
 * the sender directly, which forced `coinBalances` to stay writable across
 * users (a coin-forgery hole). The Admin SDK bypasses the rules so the refund
 * happens here instead, letting `coinBalances` be locked to owner-only.
 *
 * The caller must be the gift's RECEIVER. Idempotent: only a 'pending' gift is
 * refundable — an already-declined/accepted gift is rejected, so a replayed
 * call can never double-refund.
 */
exports.declineGift = (0, https_1.onCall)({ memory: '256MiB', timeoutSeconds: 60 }, async (request) => {
    try {
        const receiverId = await (0, utils_1.verifyAuth)(request.auth);
        const { giftId } = request.data;
        if (!giftId || typeof giftId !== 'string') {
            throw new https_1.HttpsError('invalid-argument', 'giftId is required');
        }
        const giftRef = utils_1.db.collection('coinGifts').doc(giftId);
        let senderId = '';
        let amount = 0;
        let senderNewTotal = 0;
        await utils_1.db.runTransaction(async (transaction) => {
            var _a;
            const giftDoc = await transaction.get(giftRef);
            if (!giftDoc.exists) {
                throw new https_1.HttpsError('not-found', 'Gift not found');
            }
            const gift = giftDoc.data();
            if (gift.receiverId !== receiverId) {
                throw new https_1.HttpsError('permission-denied', 'Only the gift recipient can decline this gift');
            }
            if (gift.status !== 'pending') {
                // Idempotency guard: already declined/accepted → never double-refund.
                throw new https_1.HttpsError('failed-precondition', 'Gift is not pending (already accepted or declined)');
            }
            senderId = gift.senderId;
            amount = gift.amount || 0;
            if (!senderId || !Number.isInteger(amount) || amount <= 0) {
                throw new https_1.HttpsError('failed-precondition', 'Gift is missing a valid sender/amount');
            }
            const senderRef = utils_1.db.collection('coinBalances').doc(senderId);
            const senderDoc = await transaction.get(senderRef);
            const senderTotal = ((_a = senderDoc.data()) === null || _a === void 0 ? void 0 : _a.totalCoins) || 0;
            senderNewTotal = senderTotal + amount;
            const now = admin.firestore.FieldValue.serverTimestamp();
            const inc = admin.firestore.FieldValue.increment;
            // Refund the sender (cross-user write — server-only). `refundedCoins`
            // is bookkeeping; `spentCoins` is decremented to undo the debit the
            // original send applied when it moved the gift into escrow.
            transaction.set(senderRef, {
                userId: senderId,
                totalCoins: inc(amount),
                spentCoins: inc(-amount),
                refundedCoins: inc(amount),
                lastUpdated: now,
            }, { merge: true });
            transaction.update(giftRef, {
                status: 'declined',
                declinedAt: now,
            });
            transaction.set(utils_1.db.collection('coinTransactions').doc(), {
                userId: senderId,
                type: 'credit',
                amount,
                balanceAfter: senderNewTotal,
                reason: 'Gift declined refund',
                metadata: { fromUserId: receiverId, giftId, source: 'gift_refund' },
                createdAt: now,
            });
        });
        (0, utils_1.logInfo)(`declineGift ${giftId}: refunded ${amount} to sender ${senderId} (declined by ${receiverId})`);
        return {
            success: true,
            senderNewBalance: senderNewTotal,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map