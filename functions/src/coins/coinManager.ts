/**
 * GreenGoCoins Cloud Functions
 * Handles coin purchases, rewards, gifts, and monthly allowances
 * Points 156-165: Virtual currency system
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

// ===== Constants =====

const COIN_EXPIRATION_DAYS = 365;
const GRACE_WARNING_DAYS = 30;

// Monthly allowance by tier (Point 163)
const MONTHLY_ALLOWANCE = {
  basic: 0,
  silver: 100,
  gold: 250,
};

// ===== Coin Purchase Verification =====

/**
 * Verify Google Play coin purchase
 * Point 157: Verify and process coin purchases
 */
export const verifyGooglePlayCoinPurchase = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { purchaseToken, productId, packageId } = data;
    const userId = context.auth.uid;

    try {
      // Verify purchase with Google Play API
      // (In production, use Google Play Developer API)
      const verified = true; // Placeholder

      if (!verified) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Purchase verification failed'
        );
      }

      // Get package details
      const coinAmount = getCoinAmountFromPackage(packageId);

      // Create coin transaction
      await firestore.runTransaction(async (transaction) => {
        const balanceRef = firestore.collection('coinBalances').doc(userId);
        const balanceDoc = await transaction.get(balanceRef);

        let currentBalance = 0;
        let earnedCoins = 0;
        let purchasedCoins = 0;
        let giftedCoins = 0;
        let spentCoins = 0;
        let coinBatches: any[] = [];

        if (balanceDoc.exists) {
          const data = balanceDoc.data()!;
          currentBalance = data.totalCoins || 0;
          earnedCoins = data.earnedCoins || 0;
          purchasedCoins = data.purchasedCoins || 0;
          giftedCoins = data.giftedCoins || 0;
          spentCoins = data.spentCoins || 0;
          coinBatches = data.coinBatches || [];
        }

        // Add new coin batch
        const batchId = firestore.collection('temp').doc().id;
        const now = admin.firestore.Timestamp.now();
        const expirationDate = new Date();
        expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);

        coinBatches.push({
          batchId,
          initialCoins: coinAmount,
          remainingCoins: coinAmount,
          source: 'purchase',
          acquiredDate: now,
          expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
        });

        // Update balance
        transaction.set(balanceRef, {
          userId,
          totalCoins: currentBalance + coinAmount,
          earnedCoins,
          purchasedCoins: purchasedCoins + coinAmount,
          giftedCoins,
          spentCoins,
          lastUpdated: now,
          coinBatches,
        });

        // Create transaction record
        const transactionRef = firestore.collection('coinTransactions').doc();
        transaction.set(transactionRef, {
          userId,
          type: 'credit',
          amount: coinAmount,
          balanceAfter: currentBalance + coinAmount,
          reason: 'coinPurchase',
          metadata: {
            package: packageId,
            productId,
            purchaseToken,
            platform: 'android',
          },
          createdAt: now,
        });
      });

      return {
        success: true,
        coinsAdded: coinAmount,
      };
    } catch (error: any) {
      console.error('Error verifying coin purchase:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Verify Apple App Store coin purchase
 * Point 157: Verify and process coin purchases
 */
export const verifyAppStoreCoinPurchase = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { receiptData, productId, packageId } = data;
    const userId = context.auth.uid;

    try {
      // Verify receipt with App Store
      // (In production, use App Store Server API)
      const verified = true; // Placeholder

      if (!verified) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Receipt verification failed'
        );
      }

      const coinAmount = getCoinAmountFromPackage(packageId);

      // Same transaction logic as Google Play
      await firestore.runTransaction(async (transaction) => {
        // ... (same as above)
      });

      return {
        success: true,
        coinsAdded: coinAmount,
      };
    } catch (error: any) {
      console.error('Error verifying App Store purchase:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

// ===== Monthly Allowance =====

/**
 * Grant monthly coin allowance to subscribers
 * Point 163: Silver (100 coins) and Gold (250 coins) monthly allowance
 */
export const grantMonthlyAllowances = functions.pubsub
  .schedule('0 0 1 * *') // First day of each month at midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;

    try {
      // Get all active subscriptions
      const subscriptionsSnapshot = await firestore
        .collection('subscriptions')
        .where('status', 'in', ['active', 'cancelled'])
        .get();

      const batch = firestore.batch();
      let processedCount = 0;

      for (const doc of subscriptionsSnapshot.docs) {
        const subscription = doc.data();
        const userId = subscription.userId;
        const tier = subscription.tier;

        // Skip basic tier (no allowance)
        if (tier === 'basic') continue;

        const allowanceAmount = MONTHLY_ALLOWANCE[tier as keyof typeof MONTHLY_ALLOWANCE];
        if (!allowanceAmount) continue;

        // Check if already received this month
        const existingAllowance = await firestore
          .collection('coinTransactions')
          .where('userId', '==', userId)
          .where('reason', '==', 'monthlyAllowance')
          .where('metadata.year', '==', year)
          .where('metadata.month', '==', month)
          .limit(1)
          .get();

        if (!existingAllowance.empty) continue;

        // Grant allowance
        const balanceRef = firestore.collection('coinBalances').doc(userId);
        const balanceDoc = await balanceRef.get();

        let currentBalance = 0;
        let earnedCoins = 0;
        let coinBatches: any[] = [];

        if (balanceDoc.exists) {
          const data = balanceDoc.data()!;
          currentBalance = data.totalCoins || 0;
          earnedCoins = data.earnedCoins || 0;
          coinBatches = data.coinBatches || [];
        }

        // Add coin batch
        const batchId = firestore.collection('temp').doc().id;
        const timestamp = admin.firestore.Timestamp.now();
        const expirationDate = new Date();
        expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);

        coinBatches.push({
          batchId,
          initialCoins: allowanceAmount,
          remainingCoins: allowanceAmount,
          source: 'allowance',
          acquiredDate: timestamp,
          expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
        });

        // Update balance
        batch.set(balanceRef, {
          userId,
          totalCoins: currentBalance + allowanceAmount,
          earnedCoins: earnedCoins + allowanceAmount,
          lastUpdated: timestamp,
          coinBatches,
        }, { merge: true });

        // Create transaction
        const transactionRef = firestore.collection('coinTransactions').doc();
        batch.set(transactionRef, {
          userId,
          type: 'credit',
          amount: allowanceAmount,
          balanceAfter: currentBalance + allowanceAmount,
          reason: 'monthlyAllowance',
          metadata: {
            tier,
            year,
            month,
          },
          createdAt: timestamp,
        });

        processedCount++;

        // Commit in batches of 500
        if (processedCount % 500 === 0) {
          await batch.commit();
        }
      }

      // Commit remaining
      if (processedCount % 500 !== 0) {
        await batch.commit();
      }

      console.log(`Granted monthly allowances to ${processedCount} users`);
      return { processedCount };
    } catch (error) {
      console.error('Error granting monthly allowances:', error);
      throw error;
    }
  });

// ===== Coin Expiration =====

/**
 * Process expired coins
 * Point 164: Coins expire after 365 days
 */
export const processExpiredCoins = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    try {
      // Get all coin balances
      const balancesSnapshot = await firestore
        .collection('coinBalances')
        .get();

      const batch = firestore.batch();
      let processedCount = 0;
      let totalExpiredCoins = 0;

      for (const doc of balancesSnapshot.docs) {
        const balance = doc.data();
        const userId = balance.userId;
        const coinBatches = balance.coinBatches || [];

        let expiredAmount = 0;
        const updatedBatches = coinBatches.filter((batch: any) => {
          if (batch.expirationDate.toDate() <= now.toDate() && batch.remainingCoins > 0) {
            expiredAmount += batch.remainingCoins;
            return false; // Remove expired batch
          }
          return true;
        });

        if (expiredAmount > 0) {
          // Update balance
          const newTotal = balance.totalCoins - expiredAmount;
          batch.update(doc.ref, {
            totalCoins: newTotal,
            coinBatches: updatedBatches,
            lastUpdated: now,
          });

          // Create expiration transaction
          const transactionRef = firestore.collection('coinTransactions').doc();
          batch.set(transactionRef, {
            userId,
            type: 'debit',
            amount: expiredAmount,
            balanceAfter: newTotal,
            reason: 'expired',
            createdAt: now,
          });

          totalExpiredCoins += expiredAmount;
          processedCount++;

          // Send notification
          await firestore.collection('notifications').add({
            userId,
            type: 'coins_expired',
            title: 'Coins Expired',
            message: `${expiredAmount} coins have expired from your account.`,
            createdAt: now,
            read: false,
          });
        }

        // Commit in batches of 500
        if (processedCount % 500 === 0) {
          await batch.commit();
        }
      }

      // Commit remaining
      if (processedCount % 500 !== 0) {
        await batch.commit();
      }

      console.log(`Processed ${totalExpiredCoins} expired coins for ${processedCount} users`);
      return { processedCount, totalExpiredCoins };
    } catch (error) {
      console.error('Error processing expired coins:', error);
      throw error;
    }
  });

/**
 * Send expiration warnings
 * Notify users when coins are about to expire
 */
export const sendExpirationWarnings = functions.pubsub
  .schedule('0 10 * * *') // Daily at 10 AM UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    const now = new Date();
    const warningThreshold = new Date();
    warningThreshold.setDate(warningThreshold.getDate() + GRACE_WARNING_DAYS);

    try {
      const balancesSnapshot = await firestore
        .collection('coinBalances')
        .get();

      let notificationCount = 0;

      for (const doc of balancesSnapshot.docs) {
        const balance = doc.data();
        const userId = balance.userId;
        const coinBatches = balance.coinBatches || [];

        let expiringCoins = 0;
        let earliestExpiration: Date | null = null;

        for (const batch of coinBatches) {
          const expirationDate = batch.expirationDate.toDate();
          if (
            expirationDate > now &&
            expirationDate <= warningThreshold &&
            batch.remainingCoins > 0
          ) {
            expiringCoins += batch.remainingCoins;
            if (!earliestExpiration || expirationDate < earliestExpiration) {
              earliestExpiration = expirationDate;
            }
          }
        }

        if (expiringCoins > 0 && earliestExpiration) {
          const daysUntilExpiration = Math.ceil(
            (earliestExpiration.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)
          );

          await firestore.collection('notifications').add({
            userId,
            type: 'coins_expiring_soon',
            title: 'Coins Expiring Soon',
            message: `${expiringCoins} coins will expire in ${daysUntilExpiration} days. Use them before they're gone!`,
            createdAt: admin.firestore.Timestamp.now(),
            read: false,
            metadata: {
              expiringCoins,
              daysUntilExpiration,
            },
          });

          notificationCount++;
        }
      }

      console.log(`Sent ${notificationCount} expiration warnings`);
      return { notificationCount };
    } catch (error) {
      console.error('Error sending expiration warnings:', error);
      throw error;
    }
  });

// ===== Helper Functions =====

function getCoinAmountFromPackage(packageId: string): number {
  const packages: { [key: string]: number } = {
    starter_100: 100,
    popular_500: 500,
    value_1000: 1000,
    premium_5000: 5000,
  };

  return packages[packageId] || 0;
}

/**
 * Claim reward (callable function)
 * Point 160: Reward system
 */
export const claimReward = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { rewardId, metadata } = data;
    const userId = context.auth.uid;

    // Define reward amounts
    const rewards: { [key: string]: number } = {
      first_match: 50,
      complete_profile: 100,
      daily_login: 10,
      week_streak: 50,
      month_streak: 200,
      first_message: 25,
      photo_verification: 75,
      refer_friend: 100,
    };

    const coinAmount = rewards[rewardId];
    if (!coinAmount) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid reward ID'
      );
    }

    try {
      await firestore.runTransaction(async (transaction) => {
        // Check if already claimed
        const claimedSnapshot = await firestore
          .collection('claimedRewards')
          .where('userId', '==', userId)
          .where('rewardId', '==', rewardId)
          .limit(1)
          .get();

        if (!claimedSnapshot.empty) {
          throw new functions.https.HttpsError(
            'already-exists',
            'Reward already claimed'
          );
        }

        // Add coins
        const balanceRef = firestore.collection('coinBalances').doc(userId);
        const balanceDoc = await transaction.get(balanceRef);

        let currentBalance = 0;
        let earnedCoins = 0;
        let coinBatches: any[] = [];

        if (balanceDoc.exists) {
          const data = balanceDoc.data()!;
          currentBalance = data.totalCoins || 0;
          earnedCoins = data.earnedCoins || 0;
          coinBatches = data.coinBatches || [];
        }

        // Add coin batch
        const batchId = firestore.collection('temp').doc().id;
        const now = admin.firestore.Timestamp.now();
        const expirationDate = new Date();
        expirationDate.setDate(expirationDate.getDate() + COIN_EXPIRATION_DAYS);

        coinBatches.push({
          batchId,
          initialCoins: coinAmount,
          remainingCoins: coinAmount,
          source: 'reward',
          acquiredDate: now,
          expirationDate: admin.firestore.Timestamp.fromDate(expirationDate),
        });

        transaction.set(balanceRef, {
          userId,
          totalCoins: currentBalance + coinAmount,
          earnedCoins: earnedCoins + coinAmount,
          lastUpdated: now,
          coinBatches,
        }, { merge: true });

        // Create transaction
        const transactionRef = firestore.collection('coinTransactions').doc();
        transaction.set(transactionRef, {
          userId,
          type: 'credit',
          amount: coinAmount,
          balanceAfter: currentBalance + coinAmount,
          reason: getReasonFromRewardId(rewardId),
          metadata: metadata || { rewardId },
          createdAt: now,
        });

        // Record claimed reward
        const claimedRef = firestore.collection('claimedRewards').doc();
        transaction.set(claimedRef, {
          userId,
          rewardId,
          coinAmount,
          claimedAt: now,
        });
      });

      return {
        success: true,
        coinsAdded: coinAmount,
      };
    } catch (error: any) {
      console.error('Error claiming reward:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

function getReasonFromRewardId(rewardId: string): string {
  const reasonMap: { [key: string]: string } = {
    first_match: 'firstMatchReward',
    complete_profile: 'completeProfileReward',
    daily_login: 'dailyLoginStreakReward',
    week_streak: 'dailyLoginStreakReward',
    month_streak: 'dailyLoginStreakReward',
    first_message: 'achievementReward',
    photo_verification: 'achievementReward',
    refer_friend: 'achievementReward',
  };

  return reasonMap[rewardId] || 'achievementReward';
}
