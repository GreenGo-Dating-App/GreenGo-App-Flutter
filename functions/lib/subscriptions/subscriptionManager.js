"use strict";
/**
 * Subscription Management Cloud Functions
 * Points 146-155: Complete subscription lifecycle management
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
exports.handleExpiredGracePeriods = exports.checkExpiringSubscriptions = exports.handleAppStoreWebhook = exports.handlePlayStoreWebhook = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
// Subscription tiers and pricing (Point 148)
const SUBSCRIPTION_TIERS = {
    basic: {
        name: 'Basic',
        price: 0,
        features: {
            dailyLikes: 10,
            superLikes: 1,
            rewinds: 0,
            boosts: 0,
            seeWhoLikesYou: false,
            unlimitedLikes: false,
            advancedFilters: false,
            readReceipts: false,
            prioritySupport: false,
            adFree: false,
            profileBoost: 0,
            incognitoMode: false,
        },
    },
    silver: {
        name: 'Silver',
        price: 9.99,
        productId: 'silver_premium_monthly',
        features: {
            dailyLikes: 100,
            superLikes: 5,
            rewinds: 5,
            boosts: 1,
            seeWhoLikesYou: true,
            unlimitedLikes: false,
            advancedFilters: true,
            readReceipts: true,
            prioritySupport: false,
            adFree: true,
            profileBoost: 1,
            incognitoMode: false,
        },
    },
    gold: {
        name: 'Gold',
        price: 19.99,
        productId: 'gold_premium_monthly',
        features: {
            dailyLikes: -1, // unlimited
            superLikes: 10,
            rewinds: -1,
            boosts: 3,
            seeWhoLikesYou: true,
            unlimitedLikes: true,
            advancedFilters: true,
            readReceipts: true,
            prioritySupport: true,
            adFree: true,
            profileBoost: 5,
            incognitoMode: true,
        },
    },
};
const GRACE_PERIOD_DAYS = 7; // Point 153
const RENEWAL_NOTIFICATION_DAYS = 3; // Point 152
/**
 * Google Play Store webhook handler (Point 146)
 * Handles real-time subscription notifications from Google Play
 */
exports.handlePlayStoreWebhook = functions.https.onRequest(async (req, res) => {
    try {
        const message = req.body.message;
        if (!message || !message.data) {
            res.status(400).send('Invalid webhook payload');
            return;
        }
        // Decode base64 message
        const data = JSON.parse(Buffer.from(message.data, 'base64').toString());
        const subscriptionNotification = data.subscriptionNotification;
        const purchaseToken = subscriptionNotification.purchaseToken;
        const notificationType = subscriptionNotification.notificationType;
        console.log('Play Store webhook received:', notificationType);
        // Find subscription by purchase token
        const subscriptionsSnapshot = await firestore
            .collection('subscriptions')
            .where('purchaseToken', '==', purchaseToken)
            .limit(1)
            .get();
        if (subscriptionsSnapshot.empty) {
            console.error('Subscription not found for token:', purchaseToken);
            res.status(404).send('Subscription not found');
            return;
        }
        const subscriptionDoc = subscriptionsSnapshot.docs[0];
        const subscription = subscriptionDoc.data();
        // Handle different notification types
        switch (notificationType) {
            case 1: // SUBSCRIPTION_RECOVERED
                await handleSubscriptionRecovered(subscriptionDoc.id, subscription);
                break;
            case 2: // SUBSCRIPTION_RENEWED
                await handleSubscriptionRenewed(subscriptionDoc.id, subscription);
                break;
            case 3: // SUBSCRIPTION_CANCELED
                await handleSubscriptionCanceled(subscriptionDoc.id, subscription);
                break;
            case 4: // SUBSCRIPTION_PURCHASED
                await handleSubscriptionPurchased(subscriptionDoc.id, subscription);
                break;
            case 5: // SUBSCRIPTION_ON_HOLD
                await handleSubscriptionOnHold(subscriptionDoc.id, subscription);
                break;
            case 6: // SUBSCRIPTION_IN_GRACE_PERIOD
                await handleGracePeriodStarted(subscriptionDoc.id, subscription);
                break;
            case 7: // SUBSCRIPTION_RESTARTED
                await handleSubscriptionRestarted(subscriptionDoc.id, subscription);
                break;
            case 10: // SUBSCRIPTION_PRICE_CHANGE_CONFIRMED
                await handlePriceChangeConfirmed(subscriptionDoc.id, subscription);
                break;
            case 12: // SUBSCRIPTION_REVOKED
                await handleSubscriptionRevoked(subscriptionDoc.id, subscription);
                break;
            case 13: // SUBSCRIPTION_EXPIRED
                await handleSubscriptionExpired(subscriptionDoc.id, subscription);
                break;
        }
        res.status(200).send('Webhook processed');
    }
    catch (error) {
        console.error('Error processing Play Store webhook:', error);
        res.status(500).send('Internal server error');
    }
});
/**
 * Apple App Store Server Notification handler (Point 147)
 * Handles real-time subscription notifications from App Store
 */
exports.handleAppStoreWebhook = functions.https.onRequest(async (req, res) => {
    var _a;
    try {
        const { signedPayload } = req.body;
        if (!signedPayload) {
            res.status(400).send('Invalid webhook payload');
            return;
        }
        // TODO: Verify JWT signature with Apple's public key
        // For production, implement proper JWT verification
        // Decode payload (simplified - use proper JWT library)
        const payload = JSON.parse(Buffer.from(signedPayload.split('.')[1], 'base64').toString());
        const notificationType = payload.notificationType;
        const transactionInfo = (_a = payload.data) === null || _a === void 0 ? void 0 : _a.signedTransactionInfo;
        console.log('App Store webhook received:', notificationType);
        // Find subscription by transaction ID
        const subscriptionsSnapshot = await firestore
            .collection('subscriptions')
            .where('transactionId', '==', transactionInfo === null || transactionInfo === void 0 ? void 0 : transactionInfo.transactionId)
            .limit(1)
            .get();
        if (subscriptionsSnapshot.empty) {
            console.error('Subscription not found');
            res.status(404).send('Subscription not found');
            return;
        }
        const subscriptionDoc = subscriptionsSnapshot.docs[0];
        const subscription = subscriptionDoc.data();
        // Handle different notification types
        switch (notificationType) {
            case 'DID_RENEW':
                await handleSubscriptionRenewed(subscriptionDoc.id, subscription);
                break;
            case 'EXPIRED':
                await handleSubscriptionExpired(subscriptionDoc.id, subscription);
                break;
            case 'GRACE_PERIOD_EXPIRED':
                await endGracePeriod(subscriptionDoc.id);
                break;
            case 'REFUND':
                await handleRefund(subscriptionDoc.id, subscription);
                break;
            case 'REVOKE':
                await handleSubscriptionRevoked(subscriptionDoc.id, subscription);
                break;
        }
        res.status(200).send('Webhook processed');
    }
    catch (error) {
        console.error('Error processing App Store webhook:', error);
        res.status(500).send('Internal server error');
    }
});
/**
 * Handle subscription recovered from grace period
 */
async function handleSubscriptionRecovered(subscriptionId, subscription) {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'active',
        inGracePeriod: false,
        gracePeriodEndDate: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Send notification to user
    await firestore.collection('notifications').add({
        userId: subscription.userId,
        type: 'subscription_recovered',
        title: 'Subscription Restored',
        message: 'Your subscription has been successfully restored!',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
    });
    console.log(`Subscription ${subscriptionId} recovered from grace period`);
}
/**
 * Handle subscription renewal (Point 152)
 */
async function handleSubscriptionRenewed(subscriptionId, subscription) {
    const now = new Date();
    const nextBillingDate = new Date(now);
    nextBillingDate.setMonth(nextBillingDate.getMonth() + 1);
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'active',
        nextBillingDate: admin.firestore.Timestamp.fromDate(nextBillingDate),
        inGracePeriod: false,
        gracePeriodEndDate: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Create purchase record
    await firestore.collection('purchases').add({
        userId: subscription.userId,
        subscriptionId,
        type: 'subscription',
        status: 'completed',
        productId: subscription.tier === 'silver' ? 'silver_premium_monthly' : 'gold_premium_monthly',
        tier: subscription.tier,
        price: SUBSCRIPTION_TIERS[subscription.tier].price,
        currency: subscription.currency || 'USD',
        platform: subscription.platform,
        purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Subscription ${subscriptionId} renewed successfully`);
}
/**
 * Handle subscription cancellation (Point 151)
 */
async function handleSubscriptionCanceled(subscriptionId, subscription) {
    var _a;
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'cancelled',
        autoRenew: false,
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Send notification
    await firestore.collection('notifications').add({
        userId: subscription.userId,
        type: 'subscription_cancelled',
        title: 'Subscription Cancelled',
        message: `Your ${subscription.tier} subscription has been cancelled. You'll have access until ${(_a = subscription.endDate) === null || _a === void 0 ? void 0 : _a.toDate().toLocaleDateString()}.`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
    });
    console.log(`Subscription ${subscriptionId} cancelled`);
}
/**
 * Handle new subscription purchase (Points 146-147)
 */
async function handleSubscriptionPurchased(subscriptionId, subscription) {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'active',
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Welcome notification
    await firestore.collection('notifications').add({
        userId: subscription.userId,
        type: 'subscription_activated',
        title: `Welcome to ${subscription.tier} Premium!`,
        message: 'Thank you for subscribing. Enjoy your premium features!',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
    });
    console.log(`New subscription ${subscriptionId} activated`);
}
/**
 * Handle subscription on hold (payment issue)
 */
async function handleSubscriptionOnHold(subscriptionId, subscription) {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'suspended',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Send alert notification
    await firestore.collection('notifications').add({
        userId: subscription.userId,
        type: 'payment_failed',
        title: 'Payment Issue',
        message: 'There was a problem with your payment. Please update your payment method.',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        actionUrl: '/settings/subscription',
    });
    console.log(`Subscription ${subscriptionId} on hold`);
}
/**
 * Handle grace period start (Point 153)
 * 7-day grace period for failed payments
 */
async function handleGracePeriodStarted(subscriptionId, subscription) {
    const gracePeriodEnd = new Date();
    gracePeriodEnd.setDate(gracePeriodEnd.getDate() + GRACE_PERIOD_DAYS);
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'suspended',
        inGracePeriod: true,
        gracePeriodEndDate: admin.firestore.Timestamp.fromDate(gracePeriodEnd),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Send grace period notification
    await firestore.collection('notifications').add({
        userId: subscription.userId,
        type: 'grace_period_started',
        title: 'Payment Failed - Grace Period Active',
        message: `Your payment failed. You have ${GRACE_PERIOD_DAYS} days to update your payment method.`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        actionUrl: '/settings/subscription',
    });
    console.log(`Grace period started for subscription ${subscriptionId}`);
}
/**
 * Handle subscription restart
 */
async function handleSubscriptionRestarted(subscriptionId, subscription) {
    const now = new Date();
    const endDate = new Date(now);
    endDate.setMonth(endDate.getMonth() + 1);
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'active',
        startDate: admin.firestore.Timestamp.fromDate(now),
        endDate: admin.firestore.Timestamp.fromDate(endDate),
        autoRenew: true,
        inGracePeriod: false,
        gracePeriodEndDate: null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Subscription ${subscriptionId} restarted`);
}
/**
 * Handle price change confirmation
 */
async function handlePriceChangeConfirmed(subscriptionId, subscription) {
    // Update with new price if needed
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Price change confirmed for subscription ${subscriptionId}`);
}
/**
 * Handle subscription revoked (refund issued)
 */
async function handleSubscriptionRevoked(subscriptionId, subscription) {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'refunded',
        endDate: admin.firestore.FieldValue.serverTimestamp(),
        autoRenew: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Downgrade to basic
    await downgradeToBasic(subscription.userId);
    console.log(`Subscription ${subscriptionId} revoked (refunded)`);
}
/**
 * Handle subscription expiration
 */
async function handleSubscriptionExpired(subscriptionId, subscription) {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'expired',
        autoRenew: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    // Downgrade to basic
    await downgradeToBasic(subscription.userId);
    // Send notification
    await firestore.collection('notifications').add({
        userId: subscription.userId,
        type: 'subscription_expired',
        title: 'Subscription Expired',
        message: 'Your premium subscription has expired. Renew to continue enjoying premium features!',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        actionUrl: '/subscription',
    });
    console.log(`Subscription ${subscriptionId} expired`);
}
/**
 * Handle refund
 */
async function handleRefund(subscriptionId, subscription) {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'refunded',
        endDate: admin.firestore.FieldValue.serverTimestamp(),
        autoRenew: false,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    await downgradeToBasic(subscription.userId);
    console.log(`Refund processed for subscription ${subscriptionId}`);
}
/**
 * End grace period (Point 153)
 */
async function endGracePeriod(subscriptionId) {
    var _a;
    await firestore.collection('subscriptions').doc(subscriptionId).update({
        status: 'expired',
        inGracePeriod: false,
        gracePeriodEndDate: null,
        autoRenew: false,
        endDate: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    const subscription = await firestore.collection('subscriptions').doc(subscriptionId).get();
    await downgradeToBasic((_a = subscription.data()) === null || _a === void 0 ? void 0 : _a.userId);
    console.log(`Grace period ended for subscription ${subscriptionId}`);
}
/**
 * Downgrade user to basic tier
 */
async function downgradeToBasic(userId) {
    // Create new basic subscription
    await firestore.collection('subscriptions').add({
        userId,
        tier: 'basic',
        status: 'active',
        startDate: admin.firestore.FieldValue.serverTimestamp(),
        endDate: null,
        autoRenew: false,
        price: 0,
        currency: 'USD',
        platform: 'system',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
/**
 * Scheduled function to check for expiring subscriptions
 * Point 152: Send renewal notifications 3 days before expiration
 */
exports.checkExpiringSubscriptions = functions.pubsub
    .schedule('every day 09:00')
    .timeZone('UTC')
    .onRun(async (context) => {
    console.log('Checking for expiring subscriptions...');
    const threeDaysFromNow = new Date();
    threeDaysFromNow.setDate(threeDaysFromNow.getDate() + RENEWAL_NOTIFICATION_DAYS);
    const fourDaysFromNow = new Date();
    fourDaysFromNow.setDate(fourDaysFromNow.getDate() + RENEWAL_NOTIFICATION_DAYS + 1);
    // Find subscriptions expiring in 3 days
    const expiringSubscriptionsSnapshot = await firestore
        .collection('subscriptions')
        .where('status', 'in', ['active', 'cancelled'])
        .where('endDate', '>=', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .where('endDate', '<', admin.firestore.Timestamp.fromDate(fourDaysFromNow))
        .get();
    console.log(`Found ${expiringSubscriptionsSnapshot.size} expiring subscriptions`);
    for (const doc of expiringSubscriptionsSnapshot.docs) {
        const subscription = doc.data();
        // Send renewal reminder
        await firestore.collection('notifications').add({
            userId: subscription.userId,
            type: 'subscription_expiring_soon',
            title: 'Subscription Expiring Soon',
            message: `Your ${subscription.tier} subscription expires in 3 days! Renew to keep your premium features.`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            actionUrl: '/settings/subscription',
        });
        console.log(`Renewal notification sent for subscription ${doc.id}`);
    }
    return {
        success: true,
        notificationsSent: expiringSubscriptionsSnapshot.size,
    };
});
/**
 * Scheduled function to handle expired grace periods
 * Point 153: Grace period expiration
 */
exports.handleExpiredGracePeriods = functions.pubsub
    .schedule('every 1 hours')
    .onRun(async (context) => {
    console.log('Checking for expired grace periods...');
    const now = new Date();
    const expiredGracePeriodsSnapshot = await firestore
        .collection('subscriptions')
        .where('inGracePeriod', '==', true)
        .where('gracePeriodEndDate', '<=', admin.firestore.Timestamp.fromDate(now))
        .get();
    console.log(`Found ${expiredGracePeriodsSnapshot.size} expired grace periods`);
    for (const doc of expiredGracePeriodsSnapshot.docs) {
        await endGracePeriod(doc.id);
    }
    return {
        success: true,
        gracePeriadsExpired: expiredGracePeriodsSnapshot.size,
    };
});
//# sourceMappingURL=subscriptionManager.js.map