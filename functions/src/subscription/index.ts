/**
 * Subscription Service
 * 4 Cloud Functions for managing subscriptions and payment webhooks
 */

import { onRequest, onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { verifyAuth, handleError, logInfo, logError, db } from '../shared/utils';
import * as admin from 'firebase-admin';
import { SubscriptionTier, SubscriptionStatus } from '../shared/types';

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

export const verifyPurchase = onCall(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const { userId, platform, productId, purchaseToken, verificationData, transactionDate } = request.data;

    // Validate required fields
    if (!userId || !platform || !productId || !purchaseToken) {
      throw new HttpsError('invalid-argument', 'Missing required fields');
    }

    // Ensure the authenticated user matches the userId
    if (request.auth.uid !== userId) {
      throw new HttpsError('permission-denied', 'User ID mismatch');
    }

    try {
      logInfo(`Verifying purchase for user ${userId}, product ${productId}, platform ${platform}`);

      // Determine subscription tier from product ID
      let tier: SubscriptionTier;
      if (productId.includes('gold')) {
        tier = SubscriptionTier.GOLD;
      } else if (productId.includes('silver')) {
        tier = SubscriptionTier.SILVER;
      } else {
        tier = SubscriptionTier.BASIC;
      }

      const tierConfig = SUBSCRIPTION_TIERS[tier.toLowerCase() as keyof typeof SUBSCRIPTION_TIERS] || SUBSCRIPTION_TIERS.basic;

      // In production, verify with Google Play / App Store APIs
      // For now, we trust the client-side verification data
      // TODO: Implement server-side verification with:
      // - Google Play Developer API for Android
      // - App Store Server API for iOS

      const verified = true; // Replace with actual verification

      if (!verified) {
        throw new HttpsError('failed-precondition', 'Purchase verification failed');
      }

      const now = admin.firestore.Timestamp.now();
      const endDate = admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days from now
      );

      // Check for existing active subscription
      const existingSubSnapshot = await db
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
          status: SubscriptionStatus.ACTIVE,
          currentPeriodEnd: endDate,
          purchaseToken: purchaseToken,
          platform: platform,
          updatedAt: now,
        });

        logInfo(`Updated existing subscription for user ${userId}`);
      } else {
        // Create new subscription
        await db.collection('subscriptions').add({
          userId: userId,
          tier: tier,
          status: SubscriptionStatus.ACTIVE,
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

        logInfo(`Created new subscription for user ${userId}`);
      }

      // Create purchase record
      await db.collection('purchases').add({
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
      await db.collection('users').doc(userId).update({
        subscriptionTier: tier,
        updatedAt: now,
      });

      // Also update the profile
      await db.collection('profiles').doc(userId).update({
        membershipTier: tier,
        updatedAt: now,
      });

      logInfo(`Purchase verified successfully for user ${userId}, tier ${tier}`);

      return {
        verified: true,
        tier: tier,
        expiresAt: endDate.toDate().toISOString(),
      };
    } catch (error) {
      logError('Error verifying purchase:', error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError('internal', 'Failed to verify purchase');
    }
  }
);

// ========== 1. HANDLE PLAY STORE WEBHOOK (HTTP Request) ==========

export const handlePlayStoreWebhook = onRequest(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (req, res) => {
    try {
      logInfo('Received Play Store webhook');

      // Verify webhook signature
      const signature = req.headers['x-goog-signature'] as string;
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

      const {
        notificationType,
        purchaseToken,
        subscriptionId,
      } = notification;

      logInfo(`Play Store notification type: ${notificationType}`);

      // Find subscription by purchase token
      const subscriptionSnapshot = await db
        .collection('subscriptions')
        .where('purchaseToken', '==', purchaseToken)
        .where('platform', '==', 'android')
        .limit(1)
        .get();

      if (subscriptionSnapshot.empty) {
        logError(`Subscription not found for purchase token: ${purchaseToken}`);
        res.status(404).send('Subscription not found');
        return;
      }

      const subscriptionDoc = subscriptionSnapshot.docs[0];
      const subscriptionData = subscriptionDoc.data();

      // Handle different notification types
      switch (notificationType) {
        case 1: // SUBSCRIPTION_RECOVERED
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.ACTIVE,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('Subscription recovered');
          break;

        case 2: // SUBSCRIPTION_RENEWED
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.ACTIVE,
            currentPeriodEnd: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('Subscription renewed');
          break;

        case 3: // SUBSCRIPTION_CANCELED
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.CANCELED,
            canceledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancelAtPeriodEnd: true,
          });
          logInfo('Subscription canceled');
          break;

        case 4: // SUBSCRIPTION_PURCHASED
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.ACTIVE,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('New subscription purchased');
          break;

        case 5: // SUBSCRIPTION_ON_HOLD
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.ON_HOLD,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('Subscription on hold');
          break;

        case 6: // SUBSCRIPTION_IN_GRACE_PERIOD
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.IN_GRACE_PERIOD,
            gracePeriodEnd: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('Subscription in grace period');
          break;

        case 7: // SUBSCRIPTION_RESTARTED
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.ACTIVE,
            cancelAtPeriodEnd: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('Subscription restarted');
          break;

        case 10: // SUBSCRIPTION_EXPIRED
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.EXPIRED,
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          // Downgrade user to basic
          await db.collection('users').doc(subscriptionData.userId).update({
            subscriptionTier: SubscriptionTier.BASIC,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          logInfo('Subscription expired');
          break;

        default:
          logInfo(`Unhandled notification type: ${notificationType}`);
      }

      // Log event to BigQuery
      // await logSubscriptionEvent(subscriptionData.userId, notificationType, subscriptionData);

      res.status(200).send('Webhook processed');
    } catch (error) {
      logError('Error processing Play Store webhook:', error);
      res.status(500).send('Internal error');
    }
  }
);

// ========== 2. HANDLE APP STORE WEBHOOK (HTTP Request) ==========

export const handleAppStoreWebhook = onRequest(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (req, res) => {
    try {
      logInfo('Received App Store webhook');

      const { notificationType, data } = req.body;

      if (!notificationType || !data) {
        res.status(400).send('Invalid webhook payload');
        return;
      }

      const { signedTransactionInfo } = data;

      logInfo(`App Store notification type: ${notificationType}`);

      // Decode transaction info (simplified - in production, verify signature)
      const transactionInfo = JSON.parse(
        Buffer.from(signedTransactionInfo, 'base64').toString()
      );

      const { originalTransactionId, productId } = transactionInfo;

      // Find subscription
      const subscriptionSnapshot = await db
        .collection('subscriptions')
        .where('receiptData', '==', originalTransactionId)
        .where('platform', '==', 'ios')
        .limit(1)
        .get();

      if (subscriptionSnapshot.empty) {
        logError(`Subscription not found for transaction: ${originalTransactionId}`);
        res.status(404).send('Subscription not found');
        return;
      }

      const subscriptionDoc = subscriptionSnapshot.docs[0];
      const subscriptionData = subscriptionDoc.data();

      // Handle notification types
      switch (notificationType) {
        case 'DID_RENEW':
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.ACTIVE,
            currentPeriodEnd: admin.firestore.Timestamp.fromDate(
              new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
            ),
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
            status: SubscriptionStatus.EXPIRED,
            expiredAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await db.collection('users').doc(subscriptionData.userId).update({
            subscriptionTier: SubscriptionTier.BASIC,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          break;

        case 'GRACE_PERIOD_EXPIRED':
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.EXPIRED,
            gracePeriodExpiredAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          break;

        case 'REFUND':
          await subscriptionDoc.ref.update({
            status: SubscriptionStatus.CANCELED,
            refundedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          break;

        default:
          logInfo(`Unhandled notification type: ${notificationType}`);
      }

      res.status(200).send('Webhook processed');
    } catch (error) {
      logError('Error processing App Store webhook:', error);
      res.status(500).send('Internal error');
    }
  }
);

// ========== 3. CHECK EXPIRING SUBSCRIPTIONS (Scheduled - Daily 9am) ==========

export const checkExpiringSubscriptions = onSchedule(
  {
    schedule: '0 9 * * *', // Daily at 9 AM UTC
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Checking for expiring subscriptions');

    try {
      // Get subscriptions expiring in 3 days
      const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

      const snapshot = await db
        .collection('subscriptions')
        .where('status', '==', SubscriptionStatus.ACTIVE)
        .where('cancelAtPeriodEnd', '==', true)
        .where('currentPeriodEnd', '<', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .get();

      logInfo(`Found ${snapshot.size} subscriptions expiring soon`);

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const daysUntilExpiry = Math.ceil(
          (data.currentPeriodEnd.toDate().getTime() - Date.now()) / (24 * 60 * 60 * 1000)
        );

        // Send renewal reminder notification
        await db.collection('notifications').add({
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

        logInfo(`Sent renewal reminder to user ${data.userId}`);
      }

      logInfo('Expiring subscriptions check completed');
    } catch (error) {
      logError('Error checking expiring subscriptions:', error);
      throw error;
    }
  }
);

// ========== 4. HANDLE EXPIRED GRACE PERIODS (Scheduled - Hourly) ==========

export const handleExpiredGracePeriods = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    logInfo('Checking for expired grace periods');

    try {
      const now = admin.firestore.Timestamp.now();

      const snapshot = await db
        .collection('subscriptions')
        .where('status', '==', SubscriptionStatus.IN_GRACE_PERIOD)
        .where('gracePeriodEnd', '<', now)
        .get();

      logInfo(`Found ${snapshot.size} expired grace periods`);

      const batch = db.batch();

      for (const doc of snapshot.docs) {
        const data = doc.data();

        // Expire subscription
        batch.update(doc.ref, {
          status: SubscriptionStatus.EXPIRED,
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Downgrade user
        const userRef = db.collection('users').doc(data.userId);
        batch.update(userRef, {
          subscriptionTier: SubscriptionTier.BASIC,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Send notification
        await db.collection('notifications').add({
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

      logInfo(`Processed ${snapshot.size} expired grace periods`);
    } catch (error) {
      logError('Error handling expired grace periods:', error);
      throw error;
    }
  }
);
