/**
 * Membership Service (One-Time Purchases)
 * Cloud Functions for managing one-time membership purchases
 * No recurring billing — users buy consumable products to extend membership duration
 */

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logInfo, logError, db } from '../shared/utils';
import * as admin from 'firebase-admin';
import { SubscriptionTier, SubscriptionStatus } from '../shared/types';
import {
  verifyGooglePlayPurchase,
  verifyAppStorePurchase,
} from '../shared/purchase_verification';
import {
  TierName,
  computeMembershipExtension,
  grantBaseMembership,
  grantCoins,
} from '../shared/grants';

// Product ID → tier and duration mapping
export const PRODUCT_CONFIG: Record<string, { tier: TierName; durationDays: number; price: number }> = {
  'greengo_base_membership': { tier: 'BASIC', durationDays: 365, price: 4.99 },
  '1_month_silver': { tier: 'SILVER', durationDays: 30, price: 9.99 },
  '1_year_silver': { tier: 'SILVER', durationDays: 365, price: 99.90 },
  '1_month_gold': { tier: 'GOLD', durationDays: 30, price: 19.99 },
  '1_year_gold': { tier: 'GOLD', durationDays: 365, price: 199.90 },
  '1_month_platinum': { tier: 'PLATINUM', durationDays: 30, price: 29.99 },
  '1_year_platinum_membership': { tier: 'PLATINUM', durationDays: 365, price: 299.90 },
};

// ========== 0. VERIFY PURCHASE (Callable) ==========

export const verifyPurchase = onCall(
  {
    memory: '512MiB',
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

    const userEmail = request.auth.token.email || null;

    try {
      logInfo(`Verifying membership purchase for user ${userId} (${userEmail}), product ${productId}, platform ${platform}`);

      // iOS auto-renewable subscription IDs are prefixed `subscription_`;
      // normalize to the shared catalog key (Android uses the unprefixed IDs).
      const catalogId = productId.replace(/^subscription_/, '');

      // Look up product configuration
      const config = PRODUCT_CONFIG[catalogId];
      if (!config) {
        throw new HttpsError('invalid-argument', `Unknown product ID: ${productId}`);
      }

      const tier = config.tier;
      const durationDays = config.durationDays;
      const durationMs = durationDays * 24 * 60 * 60 * 1000;

      // Verify purchase with the respective store
      let verified = false;
      // Subscription identity used to match later renewal/expiry notifications.
      // iOS: Apple's originalTransactionId. Android: the subscription purchase token.
      let originalTransactionId: string | undefined;
      let storeExpiryMs: number | undefined;

      if (platform === 'android') {
        // verificationData = Google Play purchase token (from serverVerificationData)
        if (!verificationData) {
          throw new HttpsError('invalid-argument', 'Missing verificationData for Android purchase');
        }
        const result = await verifyGooglePlayPurchase(productId, verificationData);
        verified = result.verified;
        originalTransactionId = verificationData; // Play RTDN matches on purchaseToken
        if (!verified) {
          logError(`Google Play verification failed for ${productId}: ${result.error}`);
        }
      } else if (platform === 'ios') {
        // verificationData = JWS signed transaction from StoreKit 2
        if (!verificationData) {
          throw new HttpsError('invalid-argument', 'Missing verificationData for iOS purchase');
        }
        const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
        const result = await verifyAppStorePurchase(verificationData, productId, appAppleId);
        verified = result.verified;
        originalTransactionId = result.originalTransactionId;
        storeExpiryMs = result.expiresDateMs;
        if (!verified) {
          logError(`App Store verification failed for ${productId}: ${result.error}`);
        }
      } else {
        logError(`Unknown platform: ${platform}`);
        throw new HttpsError('invalid-argument', `Unsupported platform: ${platform}`);
      }

      if (!verified) {
        throw new HttpsError('failed-precondition', 'Purchase verification failed');
      }

      // CRITICAL: Prevent shared billing account abuse.
      const tokenSnapshot = await db
        .collection('subscriptions')
        .where('purchaseToken', '==', purchaseToken)
        .limit(1)
        .get();

      if (!tokenSnapshot.empty) {
        const existingOwner = tokenSnapshot.docs[0].data().userId;
        if (existingOwner !== userId) {
          logInfo(`Purchase token already belongs to user ${existingOwner}, rejecting for user ${userId}`);
          throw new HttpsError(
            'already-exists',
            'This purchase is already linked to a different account.'
          );
        }
      }

      const purchaseTokenCheck = await db
        .collection('purchases')
        .where('purchaseToken', '==', purchaseToken)
        .limit(1)
        .get();

      if (!purchaseTokenCheck.empty) {
        const purchaseOwner = purchaseTokenCheck.docs[0].data().userId;
        if (purchaseOwner !== userId) {
          throw new HttpsError(
            'already-exists',
            'This purchase is already linked to a different account.'
          );
        }
      }

      const now = admin.firestore.Timestamp.now();

      // ── Compute new end date with extension/upgrade logic + apply grants via shared helpers ──
      const profileDoc = await db.collection('profiles').doc(userId).get();
      const profileData = profileDoc.data() || {};
      const currentTier = (profileData.membershipTier as string) || 'BASIC';
      const currentEndTimestamp = profileData.membershipEndDate as admin.firestore.Timestamp | undefined;
      const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;

      const { effectiveTier, newEndDate, newEndTimestamp: endTimestamp } = computeMembershipExtension(
        currentTier,
        currentEndDate,
        tier,
        durationMs,
        now.toDate(),
      );

      // ── Create subscription record ──
      // `originalTransactionId` is the stable key store renewal/expiry
      // notifications carry (Apple originalTransactionId / Play purchaseToken),
      // so the webhook handlers can find this user when the store auto-renews.
      await db.collection('subscriptions').add({
        userId: userId,
        userEmail: userEmail,
        tier: effectiveTier,
        status: SubscriptionStatus.ACTIVE,
        startDate: now,
        endDate: endTimestamp,
        durationDays: durationDays,
        platform: platform,
        purchaseToken: purchaseToken,
        transactionId: purchaseToken,
        orderId: purchaseToken,
        originalTransactionId: originalTransactionId || purchaseToken,
        storeExpiryDate: storeExpiryMs
          ? admin.firestore.Timestamp.fromMillis(storeExpiryMs)
          : null,
        productId: productId,
        price: config.price,
        currency: 'USD',
        autoRenewing: true,
        createdAt: now,
      });

      // ── Create purchase record ──
      await db.collection('purchases').add({
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

      // ── Update profile + users docs (tier extension) ──
      await db.collection('profiles').doc(userId).update({
        membershipTier: effectiveTier,
        membershipEndDate: endTimestamp,
        membershipStartDate: now,
        updatedAt: now,
      });

      await db.collection('users').doc(userId).update({
        subscriptionTier: effectiveTier,
        membershipEndDate: endTimestamp,
        updatedAt: now,
      });

      // ── Apply base membership flag + 500 coin welcome bonus for the base product ──
      let coinsGranted = 0;
      if (catalogId === 'greengo_base_membership') {
        await grantBaseMembership(userId, durationMs);
        await grantCoins(userId, 500, 'membership_bonus', 'Base membership welcome bonus', { productId });
        coinsGranted = 500;
      }

      logInfo(`Membership purchase verified for user ${userId}: tier=${effectiveTier}, endDate=${newEndDate.toISOString()}, coins=${coinsGranted}`);

      return {
        verified: true,
        tier: effectiveTier,
        endDate: newEndDate.toISOString(),
        coinsGranted: coinsGranted,
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

// ========== 1. CHECK EXPIRING MEMBERSHIPS (Scheduled - Daily 9am) ==========

export const checkExpiringSubscriptions = onSchedule(
  {
    schedule: '0 9 * * *', // Daily at 9 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Checking for expiring memberships');

    try {
      const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

      // Find profiles with membership ending within 3 days
      const snapshot = await db
        .collection('profiles')
        .where('membershipEndDate', '<', admin.firestore.Timestamp.fromDate(threeDaysFromNow))
        .where('membershipEndDate', '>', admin.firestore.Timestamp.now())
        .get();

      logInfo(`Found ${snapshot.size} memberships expiring soon`);

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const endDate = data.membershipEndDate?.toDate();
        if (!endDate) continue;

        const daysUntilExpiry = Math.ceil(
          (endDate.getTime() - Date.now()) / (24 * 60 * 60 * 1000)
        );

        await db.collection('notifications').add({
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

        logInfo(`Sent expiry reminder to user ${doc.id}`);
      }

      logInfo('Expiring memberships check completed');
    } catch (error) {
      logError('Error checking expiring memberships:', error);
      throw error;
    }
  }
);

// ========== 2. HANDLE EXPIRED MEMBERSHIPS (Scheduled - Hourly) ==========

export const handleExpiredMemberships = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async () => {
    logInfo('Checking for expired memberships');

    try {
      const now = admin.firestore.Timestamp.now();

      // Find profiles with expired membership end dates
      const snapshot = await db
        .collection('profiles')
        .where('membershipEndDate', '<', now)
        .where('membershipTier', '!=', 'BASIC')
        .get();

      logInfo(`Found ${snapshot.size} expired memberships`);

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
          await db.collection('users').doc(doc.id).update({
            subscriptionTier: SubscriptionTier.BASIC,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        } catch (e) {
          logError(`Failed to update users collection for ${doc.id}:`, e);
        }

        // Mark any active subscriptions as expired
        const activeSubs = await db
          .collection('subscriptions')
          .where('userId', '==', doc.id)
          .where('status', '==', SubscriptionStatus.ACTIVE)
          .get();

        for (const subDoc of activeSubs.docs) {
          await subDoc.ref.update({
            status: SubscriptionStatus.EXPIRED,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Send notification
        await db.collection('notifications').add({
          userId: doc.id,
          type: 'membership_expired',
          title: 'Membership Expired',
          body: 'Your membership has expired. Purchase a new membership to restore premium features.',
          read: false,
          sent: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logInfo(`Downgraded user ${doc.id} from ${data.membershipTier} to BASIC`);
      }

      logInfo(`Processed ${snapshot.size} expired memberships`);
    } catch (error) {
      logError('Error handling expired memberships:', error);
      throw error;
    }
  }
);
