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

// Product ID → tier and duration mapping
const PRODUCT_CONFIG: Record<string, { tier: string; durationDays: number; price: number }> = {
  'greengo_base_membership': { tier: 'BASIC', durationDays: 365, price: 9.99 },
  '1_month_silver': { tier: 'SILVER', durationDays: 30, price: 9.99 },
  '1_year_silver': { tier: 'SILVER', durationDays: 365, price: 99.90 },
  '1_month_gold': { tier: 'GOLD', durationDays: 30, price: 19.99 },
  '1_year_gold': { tier: 'GOLD', durationDays: 365, price: 199.90 },
  '1_month_platinum': { tier: 'PLATINUM', durationDays: 30, price: 29.99 },
  '1_year_platinum_membership': { tier: 'PLATINUM', durationDays: 365, price: 299.90 },
};

// Tier hierarchy for upgrade logic
const TIER_RANK: Record<string, number> = {
  'BASIC': 0,
  'SILVER': 1,
  'GOLD': 2,
  'PLATINUM': 3,
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

    const userEmail = request.auth.token.email || null;

    try {
      logInfo(`Verifying membership purchase for user ${userId} (${userEmail}), product ${productId}, platform ${platform}`);

      // Look up product configuration
      const config = PRODUCT_CONFIG[productId];
      if (!config) {
        throw new HttpsError('invalid-argument', `Unknown product ID: ${productId}`);
      }

      const tier = config.tier;
      const durationDays = config.durationDays;
      const durationMs = durationDays * 24 * 60 * 60 * 1000;

      // TODO: Implement server-side verification with:
      // - Google Play Developer API for Android
      // - App Store Server API for iOS
      const verified = true; // Replace with actual verification

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
      const nowDate = now.toDate();

      // ── Compute new end date with extension/upgrade logic ──
      const profileDoc = await db.collection('profiles').doc(userId).get();
      const profileData = profileDoc.data() || {};
      const currentTier = (profileData.membershipTier as string) || 'BASIC';
      const currentEndTimestamp = profileData.membershipEndDate as admin.firestore.Timestamp | undefined;
      const currentEndDate = currentEndTimestamp ? currentEndTimestamp.toDate() : null;

      let newEndDate: Date;
      let effectiveTier = tier;

      if (currentEndDate && currentEndDate > nowDate) {
        // User has active membership
        const purchasedRank = TIER_RANK[tier] || 0;
        const currentRank = TIER_RANK[currentTier] || 0;

        if (purchasedRank >= currentRank) {
          // Same or higher tier: user gets higher tier immediately, end date extends from current end
          newEndDate = new Date(currentEndDate.getTime() + durationMs);
          effectiveTier = tier;
        } else {
          // Lower tier: keep higher tier, extend end date from current end
          newEndDate = new Date(currentEndDate.getTime() + durationMs);
          effectiveTier = currentTier;
        }
      } else {
        // No active membership or expired — start from now
        newEndDate = new Date(nowDate.getTime() + durationMs);
      }

      const endTimestamp = admin.firestore.Timestamp.fromDate(newEndDate);

      // ── Create subscription record ──
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
        productId: productId,
        price: config.price,
        currency: 'USD',
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

      // ── Update profile with membership info ──
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

      // ── Grant 500 coins for base membership ──
      let coinsGranted = 0;
      if (productId === 'greengo_base_membership') {
        const balanceRef = db.collection('coinBalances').doc(userId);
        const balanceDoc = await balanceRef.get();

        if (balanceDoc.exists) {
          const currentTotal = (balanceDoc.data()?.totalCoins as number) || 0;
          await balanceRef.update({ totalCoins: currentTotal + 500 });
        } else {
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
        logInfo(`Granted 500 bonus coins to user ${userId}`);
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
    memory: '256MiB',
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
    memory: '256MiB',
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

        // Downgrade to basic/free
        await doc.ref.update({
          membershipTier: 'BASIC',
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
