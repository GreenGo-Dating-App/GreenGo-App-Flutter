/**
 * Coin Service
 * 6 Cloud Functions for managing virtual currency system
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { verifyAuth, handleError, logInfo, logError, db } from '../shared/utils';
import * as admin from 'firebase-admin';
import { CoinSource, SubscriptionTier } from '../shared/types';
import {
  verifyGooglePlayPurchase,
  verifyAppStorePurchase,
} from '../shared/purchase_verification';

// Coin packages
const COIN_PACKAGES = {
  starter: { coins: 100, price: 0.99 },
  popular: { coins: 500, price: 4.99 },
  value: { coins: 1000, price: 8.99 },
  premium: { coins: 5000, price: 39.99 },
};

// Monthly allowances by tier
const MONTHLY_ALLOWANCES = {
  [SubscriptionTier.BASIC]: 0,
  [SubscriptionTier.SILVER]: 100,
  [SubscriptionTier.GOLD]: 250,
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

// ========== 1. VERIFY GOOGLE PLAY COIN PURCHASE (HTTP Callable) ==========

interface VerifyPurchaseRequest {
  purchaseToken: string;
  productId: string;
  packageType: keyof typeof COIN_PACKAGES;
  verificationData?: string;
}

export const verifyGooglePlayCoinPurchase = onCall<VerifyPurchaseRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { purchaseToken, productId, packageType, verificationData } = request.data;

      if (!purchaseToken || !productId || !packageType) {
        throw new HttpsError(
          'invalid-argument',
          'purchaseToken, productId, and packageType are required'
        );
      }

      logInfo(`Verifying Google Play purchase for user ${uid}: ${packageType}`);

      // Verify with Google Play Developer API
      const gpToken = verificationData || purchaseToken;
      const verificationResult = await verifyGooglePlayPurchase(productId, gpToken);
      if (!verificationResult.verified) {
        logError(`Google Play coin purchase verification failed: ${verificationResult.error}`);
        throw new HttpsError('failed-precondition', 'Purchase verification failed');
      }

      const coinPackage = COIN_PACKAGES[packageType];
      if (!coinPackage) {
        throw new HttpsError('invalid-argument', 'Invalid package type');
      }

      // Check if purchase already processed
      const existingPurchase = await db
        .collection('coin_transactions')
        .where('purchaseToken', '==', purchaseToken)
        .limit(1)
        .get();

      if (!existingPurchase.empty) {
        throw new HttpsError('already-exists', 'Purchase already processed');
      }

      // Get current coin balance
      const balanceRef = db.collection('coin_balances').doc(uid);
      const balanceDoc = await balanceRef.get();
      const currentBalance = balanceDoc.data()?.totalCoins || 0;

      // Create coin batch
      const batchId = `batch_${Date.now()}`;
      const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 365 days

      await db.runTransaction(async (transaction) => {
        const balanceSnapshot = await transaction.get(balanceRef);

        const batches = balanceSnapshot.data()?.batches || [];
        batches.push({
          id: batchId,
          amount: coinPackage.coins,
          source: CoinSource.PURCHASED,
          expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          remainingAmount: coinPackage.coins,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.set(
          balanceRef,
          {
            totalCoins: admin.firestore.FieldValue.increment(coinPackage.coins),
            batches,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        // Record transaction
        const transactionRef = db.collection('coin_transactions').doc();
        transaction.set(transactionRef, {
          userId: uid,
          amount: coinPackage.coins,
          type: 'credit',
          source: CoinSource.PURCHASED,
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 2. VERIFY APP STORE COIN PURCHASE (HTTP Callable) ==========

export const verifyAppStoreCoinPurchase = onCall<VerifyPurchaseRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { purchaseToken, productId, packageType, verificationData } = request.data;

      if (!purchaseToken || !productId || !packageType) {
        throw new HttpsError(
          'invalid-argument',
          'purchaseToken, productId, and packageType are required'
        );
      }

      logInfo(`Verifying App Store purchase for user ${uid}: ${packageType}`);

      // Verify with App Store Server API (StoreKit 2 JWS)
      const jws = verificationData || purchaseToken;
      const appAppleId = parseInt(process.env.APPLE_APP_ID || '0', 10);
      const verificationResult = await verifyAppStorePurchase(jws, productId, appAppleId);
      if (!verificationResult.verified) {
        logError(`App Store coin purchase verification failed: ${verificationResult.error}`);
        throw new HttpsError('failed-precondition', 'Purchase verification failed');
      }

      const coinPackage = COIN_PACKAGES[packageType];
      if (!coinPackage) {
        throw new HttpsError('invalid-argument', 'Invalid package type');
      }

      // Check for duplicate
      const existingPurchase = await db
        .collection('coin_transactions')
        .where('purchaseToken', '==', purchaseToken)
        .limit(1)
        .get();

      if (!existingPurchase.empty) {
        throw new HttpsError('already-exists', 'Purchase already processed');
      }

      const balanceRef = db.collection('coin_balances').doc(uid);
      const balanceDoc = await balanceRef.get();
      const currentBalance = balanceDoc.data()?.totalCoins || 0;

      const batchId = `batch_${Date.now()}`;
      const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

      await db.runTransaction(async (transaction) => {
        const balanceSnapshot = await transaction.get(balanceRef);
        const batches = balanceSnapshot.data()?.batches || [];

        batches.push({
          id: batchId,
          amount: coinPackage.coins,
          source: CoinSource.PURCHASED,
          expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          remainingAmount: coinPackage.coins,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.set(
          balanceRef,
          {
            totalCoins: admin.firestore.FieldValue.increment(coinPackage.coins),
            batches,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        const transactionRef = db.collection('coin_transactions').doc();
        transaction.set(transactionRef, {
          userId: uid,
          amount: coinPackage.coins,
          type: 'credit',
          source: CoinSource.PURCHASED,
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 3. GRANT MONTHLY ALLOWANCES (Scheduled - Monthly 1st) ==========

export const grantMonthlyAllowances = onSchedule(
  {
    schedule: '0 0 1 * *', // 1st of every month at midnight UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Granting monthly coin allowances');

    try {
      // Get all users with active subscriptions
      const usersSnapshot = await db
        .collection('users')
        .where('subscriptionTier', 'in', [SubscriptionTier.SILVER, SubscriptionTier.GOLD])
        .get();

      logInfo(`Found ${usersSnapshot.size} eligible users for allowances`);

      let grantedCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const userId = userDoc.id;
        const tier = userData.subscriptionTier as SubscriptionTier;
        const allowance = MONTHLY_ALLOWANCES[tier];

        if (!allowance) continue;

        try {
          const balanceRef = db.collection('coin_balances').doc(userId);
          const batchId = `allowance_${Date.now()}_${userId}`;
          const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

          await db.runTransaction(async (transaction) => {
            const balanceSnapshot = await transaction.get(balanceRef);
            const batches = balanceSnapshot.data()?.batches || [];

            batches.push({
              id: batchId,
              amount: allowance,
              source: CoinSource.ALLOWANCE,
              expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
              remainingAmount: allowance,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            transaction.set(
              balanceRef,
              {
                totalCoins: admin.firestore.FieldValue.increment(allowance),
                batches,
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              },
              { merge: true }
            );

            const transactionRef = db.collection('coin_transactions').doc();
            transaction.set(transactionRef, {
              userId,
              amount: allowance,
              type: 'credit',
              source: CoinSource.ALLOWANCE,
              description: `Monthly ${tier} allowance`,
              batchId,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
              balanceAfter: (balanceSnapshot.data()?.totalCoins || 0) + allowance,
            });
          });

          // Send notification
          await db.collection('notifications').add({
            userId,
            type: 'coins_credited',
            title: 'Monthly Coins Added!',
            body: `You received ${allowance} coins as part of your ${tier} subscription`,
            read: false,
            sent: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          grantedCount++;
        } catch (error) {
          logError(`Error granting allowance to user ${userId}:`, error);
        }
      }

      logInfo(`Monthly allowances granted to ${grantedCount} users`);
    } catch (error) {
      logError('Error granting monthly allowances:', error);
      throw error;
    }
  }
);

// ========== 4. PROCESS EXPIRED COINS (Scheduled - Daily 2am) ==========

export const processExpiredCoins = onSchedule(
  {
    schedule: '0 2 * * *', // Daily at 2 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Processing expired coins');

    try {
      const now = admin.firestore.Timestamp.now();

      // Get all balances with batches
      const balancesSnapshot = await db.collection('coin_balances').get();

      let processedCount = 0;
      let totalExpiredCoins = 0;

      for (const balanceDoc of balancesSnapshot.docs) {
        const data = balanceDoc.data();
        const userId = balanceDoc.id;
        const batches = data.batches || [];

        // Find expired batches
        const expiredBatches = batches.filter(
          (batch: any) => batch.expiresAt.toMillis() < now.toMillis() && batch.remainingAmount > 0
        );

        if (expiredBatches.length === 0) continue;

        const expiredCoins = expiredBatches.reduce(
          (sum: number, batch: any) => sum + batch.remainingAmount,
          0
        );

        // Remove expired batches
        const activeBatches = batches.filter(
          (batch: any) => batch.expiresAt.toMillis() >= now.toMillis() || batch.remainingAmount === 0
        );

        await balanceDoc.ref.update({
          batches: activeBatches,
          totalCoins: admin.firestore.FieldValue.increment(-expiredCoins),
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Record expiration
        await db.collection('coin_transactions').add({
          userId,
          amount: expiredCoins,
          type: 'debit',
          source: CoinSource.PURCHASED,
          description: 'Coins expired (365 days)',
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          balanceAfter: data.totalCoins - expiredCoins,
        });

        processedCount++;
        totalExpiredCoins += expiredCoins;
      }

      logInfo(`Processed ${processedCount} users, ${totalExpiredCoins} coins expired`);
    } catch (error) {
      logError('Error processing expired coins:', error);
      throw error;
    }
  }
);

// ========== 5. SEND EXPIRATION WARNINGS (Scheduled - Daily 10am) ==========

export const sendExpirationWarnings = onSchedule(
  {
    schedule: '0 10 * * *', // Daily at 10 AM UTC
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Sending coin expiration warnings');

    try {
      const thirtyDaysFromNow = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

      const balancesSnapshot = await db.collection('coin_balances').get();

      let warningsSent = 0;

      for (const balanceDoc of balancesSnapshot.docs) {
        const data = balanceDoc.data();
        const userId = balanceDoc.id;
        const batches = data.batches || [];

        // Find batches expiring soon
        const expiringBatches = batches.filter((batch: any) => {
          const expiryDate = batch.expiresAt.toDate();
          return (
            expiryDate <= thirtyDaysFromNow &&
            expiryDate > new Date() &&
            batch.remainingAmount > 0
          );
        });

        if (expiringBatches.length === 0) continue;

        const expiringCoins = expiringBatches.reduce(
          (sum: number, batch: any) => sum + batch.remainingAmount,
          0
        );

        const earliestExpiry = Math.min(
          ...expiringBatches.map((b: any) => b.expiresAt.toMillis())
        );
        const daysUntilExpiry = Math.ceil(
          (earliestExpiry - Date.now()) / (24 * 60 * 60 * 1000)
        );

        // Send warning notification
        await db.collection('notifications').add({
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

      logInfo(`Sent ${warningsSent} expiration warnings`);
    } catch (error) {
      logError('Error sending expiration warnings:', error);
      throw error;
    }
  }
);

// ========== 6. CLAIM REWARD (HTTP Callable) ==========

interface ClaimRewardRequest {
  rewardType: keyof typeof REWARDS;
  metadata?: any;
}

export const claimReward = onCall<ClaimRewardRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { rewardType, metadata } = request.data;

      if (!rewardType || !REWARDS[rewardType]) {
        throw new HttpsError('invalid-argument', 'Invalid reward type');
      }

      logInfo(`User ${uid} claiming reward: ${rewardType}`);

      const rewardCoins = REWARDS[rewardType];

      // Check if reward already claimed (for one-time rewards)
      const oneTimeRewards = ['first_match', 'complete_profile', 'photo_verification'];
      if (oneTimeRewards.includes(rewardType)) {
        const existingClaim = await db
          .collection('coin_transactions')
          .where('userId', '==', uid)
          .where('source', '==', CoinSource.EARNED)
          .where('description', '==', `Reward: ${rewardType}`)
          .limit(1)
          .get();

        if (!existingClaim.empty) {
          throw new HttpsError('already-exists', 'Reward already claimed');
        }
      }

      const balanceRef = db.collection('coin_balances').doc(uid);
      const balanceDoc = await balanceRef.get();
      const currentBalance = balanceDoc.data()?.totalCoins || 0;

      const batchId = `reward_${rewardType}_${Date.now()}`;
      const expiresAt = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

      await db.runTransaction(async (transaction) => {
        const balanceSnapshot = await transaction.get(balanceRef);
        const batches = balanceSnapshot.data()?.batches || [];

        batches.push({
          id: batchId,
          amount: rewardCoins,
          source: CoinSource.EARNED,
          expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          remainingAmount: rewardCoins,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        transaction.set(
          balanceRef,
          {
            totalCoins: admin.firestore.FieldValue.increment(rewardCoins),
            batches,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        const transactionRef = db.collection('coin_transactions').doc();
        transaction.set(transactionRef, {
          userId: uid,
          amount: rewardCoins,
          type: 'credit',
          source: CoinSource.EARNED,
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

interface GiftCoinsRequest {
  receiverId: string;
  amount: number;
  message?: string;
}

/**
 * P2P coin gift. Atomically debits the sender's `coinBalances` and credits the
 * receiver's, plus writes a ledger entry for each. This MUST be server-side:
 * Firestore rules only let a user write their OWN balance doc, so the client
 * (which tried to write the receiver's balance directly) was always denied and
 * gifting failed. The Admin SDK bypasses those rules.
 */
export const giftCoins = onCall<GiftCoinsRequest>(
  { memory: '256MiB', timeoutSeconds: 60 },
  async (request) => {
    try {
      const senderId = await verifyAuth(request.auth);
      const { receiverId, amount, message } = request.data;

      if (!receiverId || typeof receiverId !== 'string') {
        throw new HttpsError('invalid-argument', 'receiverId is required');
      }
      if (receiverId === senderId) {
        throw new HttpsError('invalid-argument', 'Cannot gift coins to yourself');
      }
      if (!Number.isInteger(amount) || amount <= 0 || amount > 100000) {
        throw new HttpsError(
          'invalid-argument',
          'amount must be a positive integer up to 100000',
        );
      }

      // Recipient must exist.
      const receiverProfile = await db.collection('profiles').doc(receiverId).get();
      if (!receiverProfile.exists) {
        throw new HttpsError('not-found', 'Recipient not found');
      }

      const senderRef = db.collection('coinBalances').doc(senderId);
      const receiverRef = db.collection('coinBalances').doc(receiverId);

      let senderNewTotal = 0;
      let receiverNewTotal = 0;

      await db.runTransaction(async (transaction) => {
        const senderDoc = await transaction.get(senderRef);
        const receiverDoc = await transaction.get(receiverRef);

        const senderTotal = (senderDoc.data() as any)?.totalCoins || 0;
        if (senderTotal < amount) {
          throw new HttpsError('failed-precondition', 'Insufficient coins');
        }
        const receiverTotal = (receiverDoc.data() as any)?.totalCoins || 0;

        senderNewTotal = senderTotal - amount;
        receiverNewTotal = receiverTotal + amount;

        const now = admin.firestore.FieldValue.serverTimestamp();
        const inc = admin.firestore.FieldValue.increment;

        transaction.set(
          senderRef,
          {
            userId: senderId,
            totalCoins: inc(-amount),
            spentCoins: inc(amount),
            lastUpdated: now,
          },
          { merge: true },
        );
        transaction.set(
          receiverRef,
          {
            userId: receiverId,
            totalCoins: inc(amount),
            giftedCoins: inc(amount),
            lastUpdated: now,
          },
          { merge: true },
        );

        transaction.set(db.collection('coinTransactions').doc(), {
          userId: senderId,
          type: 'debit',
          amount,
          balanceAfter: senderNewTotal,
          reason: 'Gift sent',
          metadata: { toUserId: receiverId, message: message || null, source: 'gift' },
          createdAt: now,
        });
        transaction.set(db.collection('coinTransactions').doc(), {
          userId: receiverId,
          type: 'credit',
          amount,
          balanceAfter: receiverNewTotal,
          reason: 'Gift received',
          metadata: { fromUserId: senderId, message: message || null, source: 'gift' },
          createdAt: now,
        });
      });

      logInfo(`giftCoins ${senderId} -> ${receiverId} amount=${amount}`);

      // Notify the receiver, always naming the sender. The in-app tile renders
      // `**{actorName}** {title}`; leaving `pushSent` unset lets the push-parity
      // trigger deliver the FCM push (it now prepends actorName to the push
      // title too), so BOTH the in-app tile and the push name the gifter.
      try {
        const senderProfile = (await db.collection('profiles').doc(senderId).get()).data() || {};
        const senderName =
          (senderProfile.displayName as string) ||
          (senderProfile.nickname as string) ||
          (senderProfile.name as string) ||
          'Someone';
        const senderPhoto =
          (senderProfile.profilePhotoUrl as string) ||
          (Array.isArray(senderProfile.photos) ? (senderProfile.photos[0] as string) : undefined) ||
          (Array.isArray(senderProfile.photoUrls) ? (senderProfile.photoUrls[0] as string) : undefined);
        const title = `sent you ${amount} coins`;
        const body = message && message.trim().length > 0 ? `"${message.trim()}"` : title;
        await db.collection('notifications').add({
          userId: receiverId,
          type: 'coins_gift',
          title, // action phrase WITHOUT the name (tile prepends actorName)
          message: body,
          body,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          actorId: senderId,
          actorName: senderName,
          ...(senderPhoto ? { imageUrl: senderPhoto } : {}),
          data: {
            type: 'coins_gift',
            action: 'open_wallet',
            actorId: senderId,
            actorName: senderName,
            amount: String(amount),
          },
        });
      } catch (e) {
        logError('giftCoins: failed to write gift notification', e);
      }

      return {
        success: true,
        senderNewBalance: senderNewTotal,
        receiverNewBalance: receiverNewTotal,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);
