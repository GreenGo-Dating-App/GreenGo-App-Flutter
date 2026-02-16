"use strict";
/**
 * Subscription Service
 * 4 Cloud Functions for managing subscriptions and payment webhooks
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
exports.handleExpiredGracePeriods = exports.checkExpiringSubscriptions = exports.handleAppStoreWebhook = exports.handlePlayStoreWebhook = exports.verifyPurchase = void 0;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
// Subscription tiers configuration
const SUBSCRIPTION_TIERS = {
    basic: {
        name: 'Basic',
        price: 0,
        dailyLikes: 10,
        features: ['basic_matching', 'limited_likes'],
    },
    silver: {
        name: 'Silver',
        price: 9.99,
        currency: 'USD',
        dailyLikes: 100,
        features: [
            'advanced_filters',
            'read_receipts',
            'super_likes_5',
            'rewinds_5',
            'boost_monthly_1',
        ],
    },
    gold: {
        name: 'Gold',
        price: 19.99,
        currency: 'USD',
        dailyLikes: 999999, // Unlimited
        features: [
            'all_silver_features',
            'priority_support',
            'incognito_mode',
            'super_likes_10',
            'boost_monthly_3',
            'see_who_likes_you',
        ],
    },
};
// ========== 0. VERIFY PURCHASE (Callable) ==========
exports.verifyPurchase = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
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
    try {
        (0, utils_1.logInfo)(`Verifying purchase for user ${userId}, product ${productId}, platform ${platform}`);
        // Determine subscription tier from product ID
        let tier;
        if (productId.includes('gold')) {
            tier = types_1.SubscriptionTier.GOLD;
        }
        else if (productId.includes('silver')) {
            tier = types_1.SubscriptionTier.SILVER;
        }
        else {
            tier = types_1.SubscriptionTier.BASIC;
        }
        const tierConfig = SUBSCRIPTION_TIERS[tier.toLowerCase()] || SUBSCRIPTION_TIERS.basic;
        // In production, verify with Google Play / App Store APIs
        // For now, we trust the client-side verification data
        // TODO: Implement server-side verification with:
        // - Google Play Developer API for Android
        // - App Store Server API for iOS
        const verified = true; // Replace with actual verification
        if (!verified) {
            throw new https_1.HttpsError('failed-precondition', 'Purchase verification failed');
        }
        const now = admin.firestore.Timestamp.now();
        const endDate = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
        );
        // Check for existing active subscription
        const existingSubSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('userId', '==', userId)
            .where('status', 'in', ['active', 'in_grace_period'])
            .limit(1)
            .get();
        if (!existingSubSnapshot.empty) {
            // Update existing subscription
            const existingDoc = existingSubSnapshot.docs[0];
            await existingDoc.ref.update({
                tier: tier,
                status: types_1.SubscriptionStatus.ACTIVE,
                currentPeriodEnd: endDate,
                purchaseToken: purchaseToken,
                platform: platform,
                updatedAt: now,
            });
            (0, utils_1.logInfo)(`Updated existing subscription for user ${userId}`);
        }
        else {
            // Create new subscription
            await utils_1.db.collection('subscriptions').add({
                userId: userId,
                tier: tier,
                status: types_1.SubscriptionStatus.ACTIVE,
                startDate: now,
                currentPeriodEnd: endDate,
                nextBillingDate: endDate,
                autoRenew: true,
                platform: platform,
                purchaseToken: purchaseToken,
                transactionId: purchaseToken,
                orderId: purchaseToken,
                price: tierConfig.price,
                currency: 'USD',
                cancelAtPeriodEnd: false,
                createdAt: now,
            });
            (0, utils_1.logInfo)(`Created new subscription for user ${userId}`);
        }
        // Create purchase record
        await utils_1.db.collection('purchases').add({
            userId: userId,
            type: 'subscription',
            status: 'completed',
            productId: productId,
            productName: tierConfig.name,
            tier: tier,
            price: tierConfig.price,
            currency: 'USD',
            platform: platform,
            purchaseToken: purchaseToken,
            transactionId: purchaseToken,
            purchaseDate: now,
            verifiedAt: now,
            verificationMethod: 'cloud_function',
        });
        // Update user's membership tier
        await utils_1.db.collection('users').doc(userId).update({
            subscriptionTier: tier,
            updatedAt: now,
        });
        // Also update the profile
        await utils_1.db.collection('profiles').doc(userId).update({
            membershipTier: tier,
            updatedAt: now,
        });
        (0, utils_1.logInfo)(`Purchase verified successfully for user ${userId}, tier ${tier}`);
        return {
            verified: true,
            tier: tier,
            expiresAt: endDate.toDate().toISOString(),
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
// ========== 1. HANDLE PLAY STORE WEBHOOK (HTTP Request) ==========
exports.handlePlayStoreWebhook = (0, https_1.onRequest)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (req, res) => {
    try {
        (0, utils_1.logInfo)('Received Play Store webhook');
        // Verify webhook signature
        const signature = req.headers['x-goog-signature'];
        if (!signature) {
            res.status(401).send('Missing signature');
            return;
        }
        // Parse notification
        const message = req.body.message;
        if (!message) {
            res.status(400).send('Missing message');
            return;
        }
        const data = JSON.parse(Buffer.from(message.data, 'base64').toString());
        const notification = data.subscriptionNotification;
        if (!notification) {
            res.status(200).send('Not a subscription notification');
            return;
        }
        const { notificationType, purchaseToken, subscriptionId, } = notification;
        (0, utils_1.logInfo)(`Play Store notification type: ${notificationType}`);
        // Find subscription by purchase token
        const subscriptionSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('purchaseToken', '==', purchaseToken)
            .where('platform', '==', 'android')
            .limit(1)
            .get();
        if (subscriptionSnapshot.empty) {
            (0, utils_1.logError)(`Subscription not found for purchase token: ${purchaseToken}`);
            res.status(404).send('Subscription not found');
            return;
        }
        const subscriptionDoc = subscriptionSnapshot.docs[0];
        const subscriptionData = subscriptionDoc.data();
        // Handle different notification types
        switch (notificationType) {
            case 1: // SUBSCRIPTION_RECOVERED
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.ACTIVE,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('Subscription recovered');
                break;
            case 2: // SUBSCRIPTION_RENEWED
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.ACTIVE,
                    currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
                    ),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('Subscription renewed');
                break;
            case 3: // SUBSCRIPTION_CANCELED
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.CANCELED,
                    canceledAt: admin.firestore.FieldValue.serverTimestamp(),
                    cancelAtPeriodEnd: true,
                });
                (0, utils_1.logInfo)('Subscription canceled');
                break;
            case 4: // SUBSCRIPTION_PURCHASED
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.ACTIVE,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('New subscription purchased');
                break;
            case 5: // SUBSCRIPTION_ON_HOLD
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.ON_HOLD,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('Subscription on hold');
                break;
            case 6: // SUBSCRIPTION_IN_GRACE_PERIOD
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.IN_GRACE_PERIOD,
                    gracePeriodEnd: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
                    ),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('Subscription in grace period');
                break;
            case 7: // SUBSCRIPTION_RESTARTED
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.ACTIVE,
                    cancelAtPeriodEnd: false,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('Subscription restarted');
                break;
            case 10: // SUBSCRIPTION_EXPIRED
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.EXPIRED,
                    expiredAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                // Downgrade user to basic
                await utils_1.db.collection('users').doc(subscriptionData.userId).update({
                    subscriptionTier: types_1.SubscriptionTier.BASIC,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)('Subscription expired');
                break;
            default:
                (0, utils_1.logInfo)(`Unhandled notification type: ${notificationType}`);
        }
        // Log event to BigQuery
        // await logSubscriptionEvent(subscriptionData.userId, notificationType, subscriptionData);
        res.status(200).send('Webhook processed');
    }
    catch (error) {
        (0, utils_1.logError)('Error processing Play Store webhook:', error);
        res.status(500).send('Internal error');
    }
});
// ========== 2. HANDLE APP STORE WEBHOOK (HTTP Request) ==========
exports.handleAppStoreWebhook = (0, https_1.onRequest)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (req, res) => {
    try {
        (0, utils_1.logInfo)('Received App Store webhook');
        const { notificationType, data } = req.body;
        if (!notificationType || !data) {
            res.status(400).send('Invalid webhook payload');
            return;
        }
        const { signedTransactionInfo } = data;
        (0, utils_1.logInfo)(`App Store notification type: ${notificationType}`);
        // Decode transaction info (simplified - in production, verify signature)
        const transactionInfo = JSON.parse(Buffer.from(signedTransactionInfo, 'base64').toString());
        const { originalTransactionId, productId } = transactionInfo;
        // Find subscription
        const subscriptionSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('receiptData', '==', originalTransactionId)
            .where('platform', '==', 'ios')
            .limit(1)
            .get();
        if (subscriptionSnapshot.empty) {
            (0, utils_1.logError)(`Subscription not found for transaction: ${originalTransactionId}`);
            res.status(404).send('Subscription not found');
            return;
        }
        const subscriptionDoc = subscriptionSnapshot.docs[0];
        const subscriptionData = subscriptionDoc.data();
        // Handle notification types
        switch (notificationType) {
            case 'DID_RENEW':
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.ACTIVE,
                    currentPeriodEnd: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)),
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case 'DID_CHANGE_RENEWAL_STATUS':
                const willRenew = transactionInfo.autoRenewStatus === 1;
                await subscriptionDoc.ref.update({
                    cancelAtPeriodEnd: !willRenew,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case 'EXPIRED':
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.EXPIRED,
                    expiredAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                await utils_1.db.collection('users').doc(subscriptionData.userId).update({
                    subscriptionTier: types_1.SubscriptionTier.BASIC,
                    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case 'GRACE_PERIOD_EXPIRED':
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.EXPIRED,
                    gracePeriodExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            case 'REFUND':
                await subscriptionDoc.ref.update({
                    status: types_1.SubscriptionStatus.CANCELED,
                    refundedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                break;
            default:
                (0, utils_1.logInfo)(`Unhandled notification type: ${notificationType}`);
        }
        res.status(200).send('Webhook processed');
    }
    catch (error) {
        (0, utils_1.logError)('Error processing App Store webhook:', error);
        res.status(500).send('Internal error');
    }
});
// ========== 3. CHECK EXPIRING SUBSCRIPTIONS (Scheduled - Daily 9am) ==========
exports.checkExpiringSubscriptions = (0, scheduler_1.onSchedule)({
    schedule: '0 9 * * *', // Daily at 9 AM UTC
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Checking for expiring subscriptions');
    try {
        // Get subscriptions expiring in 3 days
        const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
        const snapshot = await utils_1.db
            .collection('subscriptions')
            .where('status', '==', types_1.SubscriptionStatus.ACTIVE)
            .where('cancelAtPeriodEnd', '==', true)
            .where('currentPeriodEnd', '<', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} subscriptions expiring soon`);
        for (const doc of snapshot.docs) {
            const data = doc.data();
            const daysUntilExpiry = Math.ceil((data.currentPeriodEnd.toDate().getTime() - Date.now()) / (24 * 60 * 60 * 1000));
            // Send renewal reminder notification
            await utils_1.db.collection('notifications').add({
                userId: data.userId,
                type: 'subscription_expiring',
                title: 'Subscription Expiring Soon',
                body: `Your ${data.tier} subscription expires in ${daysUntilExpiry} days`,
                data: {
                    subscriptionId: doc.id,
                    tier: data.tier,
                    expiresAt: data.currentPeriodEnd.toDate().toISOString(),
                },
                read: false,
                sent: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            (0, utils_1.logInfo)(`Sent renewal reminder to user ${data.userId}`);
        }
        (0, utils_1.logInfo)('Expiring subscriptions check completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error checking expiring subscriptions:', error);
        throw error;
    }
});
// ========== 4. HANDLE EXPIRED GRACE PERIODS (Scheduled - Hourly) ==========
exports.handleExpiredGracePeriods = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async () => {
    (0, utils_1.logInfo)('Checking for expired grace periods');
    try {
        const now = admin.firestore.Timestamp.now();
        const snapshot = await utils_1.db
            .collection('subscriptions')
            .where('status', '==', types_1.SubscriptionStatus.IN_GRACE_PERIOD)
            .where('gracePeriodEnd', '<', now)
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} expired grace periods`);
        const batch = utils_1.db.batch();
        for (const doc of snapshot.docs) {
            const data = doc.data();
            // Expire subscription
            batch.update(doc.ref, {
                status: types_1.SubscriptionStatus.EXPIRED,
                expiredAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Downgrade user
            const userRef = utils_1.db.collection('users').doc(data.userId);
            batch.update(userRef, {
                subscriptionTier: types_1.SubscriptionTier.BASIC,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Send notification
            await utils_1.db.collection('notifications').add({
                userId: data.userId,
                type: 'subscription_expired',
                title: 'Subscription Expired',
                body: 'Your subscription has expired. Renew now to restore premium features.',
                read: false,
                sent: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        (0, utils_1.logInfo)(`Processed ${snapshot.size} expired grace periods`);
    }
    catch (error) {
        (0, utils_1.logError)('Error handling expired grace periods:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map