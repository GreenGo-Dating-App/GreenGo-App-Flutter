/**
 * Gamification Cloud Functions
 * Points 176-200: Backend support for achievements, levels, and challenges
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { weeklyXpFields } from './weekKey';

const firestore = admin.firestore();

// ---------------------------------------------------------------------------
// L-04 (security Phase 1): every callable below used to trust `data.userId`
// and build doc ids like `${userId}_${id}` from raw input, so any user could
// write another user's XP / progress / claims (and inject '/' into paths).
// The subject is now ALWAYS the caller. `userId` is still accepted for
// backward compatibility (the apps send their own uid) but must equal it.
// ---------------------------------------------------------------------------
const SAFE_ID = /^[A-Za-z0-9_-]{1,64}$/;

function callerUid(data: any, context: functions.https.CallableContext): string {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  const claimed = data?.userId;
  if (claimed !== undefined && claimed !== null && claimed !== '' && claimed !== uid) {
    throw new functions.https.HttpsError('permission-denied', 'userId must be the caller');
  }
  return uid;
}

function safeId(value: unknown, field: string): string {
  if (typeof value !== 'string' || !SAFE_ID.test(value)) {
    throw new functions.https.HttpsError('invalid-argument', `Invalid ${field}`);
  }
  return value;
}

function boundedInt(value: unknown, field: string, min: number, max: number, fallback?: number): number {
  const v = value === undefined && fallback !== undefined ? fallback : value;
  if (typeof v !== 'number' || !Number.isInteger(v) || v < min || v > max) {
    throw new functions.https.HttpsError('invalid-argument', `Invalid ${field}`);
  }
  return v;
}

/**
 * Grant XP to User
 * Point 187: XP rewards for actions
 */
export const grantXP = functions
  .runWith({ memory: '512MB' })
  .https.onCall(monitored("grantXP", async (data, context) => {
  const userId = callerUid(data, context);
  const { reason } = data;
  if (!data?.xpAmount || !reason) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing required fields'
    );
  }
  const xpAmount = boundedInt(data.xpAmount, 'xpAmount', 1, 10000);
  if (typeof reason !== 'string' || reason.length > 100) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid reason');
  }

  try {
    const levelRef = firestore.collection('user_levels').doc(userId);

    const result = await firestore.runTransaction(async (transaction) => {
      const levelDoc = await transaction.get(levelRef);

      let currentLevel = 1;
      let currentXP = 0;
      let totalXP = 0;
      // Weekly leaderboard bookkeeping (weekKey/weeklyXP), same transaction.
      const weekly = weeklyXpFields(levelDoc.exists ? levelDoc.data() : undefined, xpAmount);

      if (levelDoc.exists) {
        const data = levelDoc.data()!;
        currentLevel = data.level;
        currentXP = data.currentXP;
        totalXP = data.totalXP;
      }

      // Calculate new totals
      const newTotalXP = totalXP + xpAmount;
      const newLevel = calculateLevel(newTotalXP);
      const newCurrentXP = calculateCurrentXP(newTotalXP);

      // Check for VIP status (Point 193: Level 50+)
      const isVIP = newLevel >= 50;

      const leveledUp = newLevel > currentLevel;

      // Update level
      transaction.set(
        levelRef,
        {
          userId,
          level: newLevel,
          currentXP: newCurrentXP,
          totalXP: newTotalXP,
          isVIP,
          weekKey: weekly.weekKey,
          weeklyXP: weekly.weeklyXP,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Record XP transaction
      const xpTransactionRef = firestore
        .collection('xp_transactions')
        .doc();
      transaction.set(xpTransactionRef, {
        userId,
        xpAmount,
        reason,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        levelBefore: currentLevel,
        levelAfter: newLevel,
      });

      return {
        oldLevel: currentLevel,
        newLevel,
        leveledUp,
        totalXP: newTotalXP,
        isVIP,
      };
    });

    return result;
  } catch (error: any) {
    console.error('Error granting XP:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
}));

/**
 * Track Achievement Progress
 * Points 176-185: Update achievement progress
 */
export const trackAchievementProgress = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("trackAchievementProgress", async (data, context) => {
    const userId = callerUid(data, context);
    const achievementId = safeId(data?.achievementId, 'achievementId');
    const incrementBy = boundedInt(data?.incrementBy, 'incrementBy', 1, 1000, 1);

    try {
      const progressRef = firestore
        .collection('achievement_progress')
        .doc(`${userId}_${achievementId}`);

      const result = await firestore.runTransaction(async (transaction) => {
        const progressDoc = await transaction.get(progressRef);

        let progress = 0;
        let requiredCount = 1;

        if (progressDoc.exists) {
          const data = progressDoc.data()!;
          progress = data.progress;
          requiredCount = data.requiredCount;
        }

        const newProgress = progress + incrementBy;
        const isCompleted = newProgress >= requiredCount;

        transaction.set(
          progressRef,
          {
            userId,
            achievementId,
            progress: newProgress,
            requiredCount,
            isCompleted,
            completedAt: isCompleted
              ? admin.firestore.FieldValue.serverTimestamp()
              : null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        return {
          progress: newProgress,
          requiredCount,
          isCompleted,
          wasJustCompleted: isCompleted && progress < requiredCount,
        };
      });

      return result;
    } catch (error: any) {
      console.error('Error tracking achievement progress:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  })
);

/**
 * Unlock Achievement and Grant Rewards
 * Points 176-185: Unlock achievement
 */
export const unlockAchievementReward = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("unlockAchievementReward", async (data, context) => {
    const userId = callerUid(data, context);
    const achievementId = safeId(data?.achievementId, 'achievementId');

    try {
      const progressRef = firestore
        .collection('achievement_progress')
        .doc(`${userId}_${achievementId}`);

      await firestore.runTransaction(async (transaction) => {
        const progressDoc = await transaction.get(progressRef);

        if (!progressDoc.exists) {
          throw new Error('Achievement progress not found');
        }

        const progressData = progressDoc.data()!;

        if (progressData.isUnlocked) {
          throw new Error('Achievement already unlocked');
        }

        // Mark as unlocked
        transaction.update(progressRef, {
          isUnlocked: true,
          unlockedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      // Achievement rewards are granted on client side
      return { success: true };
    } catch (error: any) {
      console.error('Error unlocking achievement:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  })
);

/**
 * Claim Level Rewards
 * Point 190: Level-based rewards
 */
export const claimLevelRewards = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("claimLevelRewards", async (data, context) => {
    const userId = callerUid(data, context);
    const level = boundedInt(data?.level, 'level', 1, 1000);

    try {
      const claimedRef = firestore
        .collection('level_rewards_claimed')
        .doc(`${userId}_${level}`);

      // Check if already claimed
      const claimedDoc = await claimedRef.get();
      if (claimedDoc.exists) {
        throw new Error('Rewards already claimed for this level');
      }

      // Get user's level
      const levelDoc = await firestore
        .collection('user_levels')
        .doc(userId)
        .get();

      if (!levelDoc.exists) {
        throw new Error('User level not found');
      }

      const userLevel = levelDoc.data()!.level;
      if (userLevel < level) {
        throw new Error(`User has not reached level ${level} yet`);
      }

      // Mark as claimed
      await claimedRef.set({
        userId,
        level,
        claimedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Rewards are granted on client side
      return { success: true };
    } catch (error: any) {
      console.error('Error claiming level rewards:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  })
);

/**
 * Track Challenge Progress
 * Point 197: Challenge tracking
 */
export const trackChallengeProgress = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("trackChallengeProgress", async (data, context) => {
    const userId = callerUid(data, context);
    const challengeId = safeId(data?.challengeId, 'challengeId');
    const incrementBy = boundedInt(data?.incrementBy, 'incrementBy', 1, 1000, 1);

    try {
      const progressRef = firestore
        .collection('challenge_progress')
        .doc(`${userId}_${challengeId}`);

      const result = await firestore.runTransaction(async (transaction) => {
        const progressDoc = await transaction.get(progressRef);

        let progress = 0;
        let requiredCount = 1;

        if (progressDoc.exists) {
          const data = progressDoc.data()!;
          progress = data.progress;
          requiredCount = data.requiredCount;
        }

        const newProgress = progress + incrementBy;
        const isCompleted = newProgress >= requiredCount;

        transaction.set(
          progressRef,
          {
            userId,
            challengeId,
            progress: newProgress,
            requiredCount,
            isCompleted,
            completedAt: isCompleted
              ? admin.firestore.FieldValue.serverTimestamp()
              : null,
            rewardsClaimed: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        return {
          progress: newProgress,
          requiredCount,
          isCompleted,
          wasJustCompleted: isCompleted && progress < requiredCount,
        };
      });

      return result;
    } catch (error: any) {
      console.error('Error tracking challenge progress:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  })
);

/**
 * Claim Challenge Reward
 * Point 198: Challenge rewards
 */
export const claimChallengeReward = functions
  .runWith({ memory: '512MB' })
  .https.onCall(
  monitored("claimChallengeReward", async (data, context) => {
    const userId = callerUid(data, context);
    const challengeId = safeId(data?.challengeId, 'challengeId');

    try {
      const progressRef = firestore
        .collection('challenge_progress')
        .doc(`${userId}_${challengeId}`);

      await firestore.runTransaction(async (transaction) => {
        const progressDoc = await transaction.get(progressRef);

        if (!progressDoc.exists) {
          throw new Error('Challenge progress not found');
        }

        const progressData = progressDoc.data()!;

        if (!progressData.isCompleted) {
          throw new Error('Challenge not completed');
        }

        if (progressData.rewardsClaimed) {
          throw new Error('Rewards already claimed');
        }

        // Mark as claimed
        transaction.update(progressRef, {
          rewardsClaimed: true,
        });
      });

      // Rewards are returned to client (mocked here)
      const rewards = [
        { type: 'xp', amount: 50, itemId: null },
        { type: 'coins', amount: 20, itemId: null },
      ];

      return { rewards };
    } catch (error: any) {
      console.error('Error claiming challenge reward:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  })
);

/**
 * Reset Daily Challenges
 * Point 196: Rotating daily challenges - runs at midnight UTC
 */
export const resetDailyChallenges = functions
  .runWith({ memory: '512MB' })
  .pubsub
  .schedule('0 0 * * *')
  .timeZone('UTC')
  .onRun(monitored("resetDailyChallenges", async (context) => {
    try {
      // Reset daily challenge progress for all users
      const batch = firestore.batch();
      let count = 0;

      const progressSnapshot = await firestore
        .collection('challenge_progress')
        .where('challengeId', '>=', 'daily_')
        .get();

      progressSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
        count++;
      });

      await batch.commit();

      console.log(`Reset ${count} daily challenge progress records`);
      return { resetCount: count };
    } catch (error) {
      console.error('Error resetting daily challenges:', error);
      throw error;
    }
  }));

/**
 * Update Leaderboard Rankings
 * Point 191, 192: Leaderboard with seasonal resets
 */
export const updateLeaderboardRankings = functions
  .runWith({ memory: '512MB' })
  .pubsub
  .schedule('0 * * * *') // Every hour
  .onRun(monitored("updateLeaderboardRankings", async (context) => {
    try {
      // Get all users sorted by totalXP
      const usersSnapshot = await firestore
        .collection('user_levels')
        .orderBy('totalXP', 'desc')
        .get();

      const batch = firestore.batch();
      let rank = 1;

      usersSnapshot.docs.forEach((doc) => {
        batch.update(doc.ref, {
          globalRank: rank++,
        });
      });

      await batch.commit();

      console.log(`Updated ${rank - 1} user rankings`);
      return { usersUpdated: rank - 1 };
    } catch (error) {
      console.error('Error updating leaderboard:', error);
      throw error;
    }
  }));

/**
 * Helper Functions
 */

function calculateLevel(totalXP: number): number {
  let level = 1;
  while (totalXPForLevel(level + 1) <= totalXP && level < 100) {
    level++;
  }
  return level;
}

function totalXPForLevel(level: number): number {
  if (level <= 1) return 0;

  let total = 0;
  for (let i = 2; i <= level; i++) {
    total += xpRequiredForLevel(i);
  }
  return total;
}

function xpRequiredForLevel(level: number): number {
  if (level <= 1) return 0;
  const baseXP = 100;
  return Math.round(baseXP * Math.pow(level, 1.5));
}

function calculateCurrentXP(totalXP: number): number {
  const level = calculateLevel(totalXP);
  const xpForCurrentLevel = totalXPForLevel(level);
  return totalXP - xpForCurrentLevel;
}
