/**
 * Gamification Service - Business Logic Handlers
 * Extracted handlers that can be unit tested independently of Cloud Functions
 */

import { db, FieldValue, logInfo, logError } from '../shared/utils';
import * as admin from 'firebase-admin';

// XP Configuration
export const XP_ACTIONS = {
  profile_complete: 50,
  first_message: 25,
  daily_login: 10,
  match: 20,
  conversation_started: 30,
  photo_uploaded: 15,
  video_call: 100,
  super_like_sent: 5,
  bio_updated: 10,
} as const;

// Level Configuration
export const LEVEL_XP_REQUIREMENTS = [
  0,      // Level 1
  100,    // Level 2
  250,    // Level 3
  500,    // Level 4
  1000,   // Level 5
  2000,   // Level 6
  3500,   // Level 7
  5500,   // Level 8
  8000,   // Level 9
  11000,  // Level 10
  15000,  // Level 11
  20000,  // Level 12
  26000,  // Level 13
  33000,  // Level 14
  41000,  // Level 15
  50000,  // Level 16
];

export type XPAction = keyof typeof XP_ACTIONS;

export interface GrantXPParams {
  uid: string;
  action: XPAction;
  metadata?: any;
}

export interface GrantXPResult {
  success: boolean;
  xpGained: number;
  newTotalXP: number;
  newCurrentXP: number;
  newLevel: number;
  leveledUp: boolean;
  rewards: Array<{
    type: string;
    level: number;
    coins: number;
  }>;
}

/**
 * Calculate level based on current XP
 */
export function calculateLevel(currentXP: number): number {
  let level = 1;
  while (level < LEVEL_XP_REQUIREMENTS.length && currentXP >= LEVEL_XP_REQUIREMENTS[level]) {
    level++;
  }
  return level;
}

/**
 * Calculate rewards for leveling up
 */
export function calculateLevelRewards(fromLevel: number, toLevel: number): Array<{ type: string; level: number; coins: number }> {
  const rewards: Array<{ type: string; level: number; coins: number }> = [];
  for (let level = fromLevel + 1; level <= toLevel; level++) {
    rewards.push({
      type: 'level_up',
      level,
      coins: level * 10,
    });
  }
  return rewards;
}

/**
 * Grant XP to a user - Business Logic Handler
 */
export async function handleGrantXP(params: GrantXPParams): Promise<GrantXPResult> {
  const { uid, action, metadata } = params;

  if (!XP_ACTIONS[action]) {
    throw new Error(`Invalid action: ${action}`);
  }

  const xpGained = XP_ACTIONS[action];
  logInfo(`Granting ${xpGained} XP to user ${uid} for action: ${action}`);

  // Get user's gamification data
  const userGamificationRef = db.collection('gamification').doc(uid);
  const userGamificationDoc = await userGamificationRef.get();

  let currentXP = 0;
  let currentLevel = 1;
  let totalXP = 0;

  if (userGamificationDoc.exists) {
    const data = userGamificationDoc.data()!;
    currentXP = data.currentXP || 0;
    currentLevel = data.level || 1;
    totalXP = data.totalXP || 0;
  }

  // Add XP
  const newTotalXP = totalXP + xpGained;
  const newCurrentXP = currentXP + xpGained;

  // Calculate new level
  const newLevel = calculateLevel(newCurrentXP);
  const leveledUp = newLevel > currentLevel;

  // Calculate rewards
  const rewardsEarned = leveledUp ? calculateLevelRewards(currentLevel, newLevel) : [];

  // Grant coin rewards if leveled up
  if (leveledUp) {
    const totalCoins = rewardsEarned.reduce((sum, r) => sum + r.coins, 0);
    const userRef = db.collection('users').doc(uid);
    await userRef.update({
      'coins.balance': FieldValue.increment(totalCoins),
      updatedAt: FieldValue.serverTimestamp(),
    });

    logInfo(`User ${uid} leveled up from ${currentLevel} to ${newLevel}, earned ${totalCoins} coins`);
  }

  // Update gamification data
  await userGamificationRef.set({
    userId: uid,
    currentXP: newCurrentXP,
    totalXP: newTotalXP,
    level: newLevel,
    lastXPGained: {
      action,
      amount: xpGained,
      timestamp: FieldValue.serverTimestamp(),
      metadata,
    },
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  // Log XP event
  await db.collection('gamification').doc(uid).collection('xp_history').add({
    action,
    xpGained,
    metadata,
    timestamp: FieldValue.serverTimestamp(),
  });

  // Send level-up notification
  if (leveledUp) {
    const totalCoins = rewardsEarned.reduce((sum, r) => sum + r.coins, 0);
    await db.collection('notifications').add({
      userId: uid,
      type: 'level_up',
      title: `Level Up! You're now level ${newLevel}!`,
      body: `Congratulations! You've earned ${totalCoins} coins.`,
      data: {
        newLevel,
        rewards: rewardsEarned,
      },
      read: false,
      sent: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  return {
    success: true,
    xpGained,
    newTotalXP,
    newCurrentXP,
    newLevel,
    leveledUp,
    rewards: rewardsEarned,
  };
}

// ========== ACHIEVEMENTS ==========

export const ACHIEVEMENTS = {
  first_match: {
    name: 'First Match',
    description: 'Get your first match',
    xpReward: 50,
    coinReward: 10,
    icon: 'heart',
  },
  social_butterfly: {
    name: 'Social Butterfly',
    description: 'Send 100 messages',
    xpReward: 100,
    coinReward: 25,
    icon: 'chat',
    target: 100,
  },
  popular: {
    name: 'Popular',
    description: 'Get 50 matches',
    xpReward: 200,
    coinReward: 50,
    icon: 'star',
    target: 50,
  },
  video_enthusiast: {
    name: 'Video Enthusiast',
    description: 'Complete 10 video calls',
    xpReward: 250,
    coinReward: 75,
    icon: 'video',
    target: 10,
  },
  daily_streak_7: {
    name: '7-Day Streak',
    description: 'Login for 7 consecutive days',
    xpReward: 150,
    coinReward: 30,
    icon: 'flame',
    target: 7,
  },
  daily_streak_30: {
    name: '30-Day Streak',
    description: 'Login for 30 consecutive days',
    xpReward: 500,
    coinReward: 100,
    icon: 'trophy',
    target: 30,
  },
} as const;

export interface TrackAchievementParams {
  uid: string;
  achievementId: string;
  progress: number;
}

/**
 * Track Achievement Progress Handler
 */
export async function handleTrackAchievementProgress(params: TrackAchievementParams) {
  const { uid, achievementId, progress } = params;

  if (!ACHIEVEMENTS[achievementId as keyof typeof ACHIEVEMENTS]) {
    throw new Error(`Invalid achievement ID: ${achievementId}`);
  }

  const achievement = ACHIEVEMENTS[achievementId as keyof typeof ACHIEVEMENTS];
  logInfo(`Tracking achievement progress for user ${uid}: ${achievementId} - ${progress}`);

  const achievementRef = db.collection('gamification').doc(uid).collection('achievements').doc(achievementId);
  const achievementDoc = await achievementRef.get();

  const currentProgress = achievementDoc.exists ? (achievementDoc.data()?.progress || 0) : 0;
  const achievementTarget = (achievement as any).target || 1;
  const newProgress = Math.min(progress, achievementTarget);
  const unlocked = achievementDoc.exists ? (achievementDoc.data()?.unlocked || false) : false;

  const shouldUnlock = !unlocked && newProgress >= achievementTarget;

  await achievementRef.set({
    userId: uid,
    achievementId,
    progress: newProgress,
    target: achievementTarget,
    unlocked: shouldUnlock ? true : unlocked,
    unlockedAt: shouldUnlock ? FieldValue.serverTimestamp() : null,
    claimed: false,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  if (shouldUnlock) {
    await db.collection('notifications').add({
      userId: uid,
      type: 'achievement_unlocked',
      title: `Achievement Unlocked: ${achievement.name}!`,
      body: (achievement as any).description || achievement.name,
      data: {
        achievementId,
        xpReward: achievement.xpReward,
        coinReward: achievement.coinReward,
      },
      read: false,
      sent: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    logInfo(`Achievement unlocked for user ${uid}: ${achievementId}`);
  }

  return {
    success: true,
    achievementId,
    progress: newProgress,
    target: achievementTarget,
    unlocked: shouldUnlock ? true : unlocked,
  };
}

export interface UnlockAchievementParams {
  uid: string;
  achievementId: string;
}

/**
 * Unlock Achievement Reward Handler
 */
export async function handleUnlockAchievementReward(params: UnlockAchievementParams) {
  const { uid, achievementId } = params;

  if (!ACHIEVEMENTS[achievementId as keyof typeof ACHIEVEMENTS]) {
    throw new Error(`Invalid achievement ID: ${achievementId}`);
  }

  const achievement = ACHIEVEMENTS[achievementId as keyof typeof ACHIEVEMENTS];
  logInfo(`Claiming achievement reward for user ${uid}: ${achievementId}`);

  const achievementRef = db.collection('gamification').doc(uid).collection('achievements').doc(achievementId);
  const achievementDoc = await achievementRef.get();

  if (!achievementDoc.exists) {
    throw new Error('Achievement not found');
  }

  const achievementData = achievementDoc.data()!;

  if (!achievementData.unlocked) {
    throw new Error('Achievement not yet unlocked');
  }

  if (achievementData.claimed) {
    throw new Error('Reward already claimed');
  }

  await db.runTransaction(async (transaction) => {
    const gamificationRef = db.collection('gamification').doc(uid);
    const gamificationDoc = await transaction.get(gamificationRef);

    const currentTotalXP = gamificationDoc.exists ? (gamificationDoc.data()?.totalXP || 0) : 0;
    const currentXP = gamificationDoc.exists ? (gamificationDoc.data()?.currentXP || 0) : 0;

    transaction.set(gamificationRef, {
      totalXP: currentTotalXP + achievement.xpReward,
      currentXP: currentXP + achievement.xpReward,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    const userRef = db.collection('users').doc(uid);
    transaction.update(userRef, {
      'coins.balance': FieldValue.increment(achievement.coinReward),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(achievementRef, {
      claimed: true,
      claimedAt: FieldValue.serverTimestamp(),
    });
  });

  logInfo(`Achievement reward claimed for user ${uid}: ${achievementId}`);

  return {
    success: true,
    achievementId,
    xpReward: achievement.xpReward,
    coinReward: achievement.coinReward,
  };
}

export interface ClaimLevelParams {
  uid: string;
  level: number;
}

/**
 * Claim Level Rewards Handler
 */
export async function handleClaimLevelRewards(params: ClaimLevelParams) {
  const { uid, level } = params;

  if (level < 1 || level > LEVEL_XP_REQUIREMENTS.length) {
    throw new Error(`Invalid level: ${level}`);
  }

  logInfo(`Claiming level rewards for user ${uid}: Level ${level}`);

  const gamificationRef = db.collection('gamification').doc(uid);
  const gamificationDoc = await gamificationRef.get();

  if (!gamificationDoc.exists) {
    throw new Error('Gamification data not found');
  }

  const gamificationData = gamificationDoc.data()!;
  const currentLevel = gamificationData.level || 1;

  if (currentLevel < level) {
    throw new Error('User has not reached this level yet');
  }

  const claimedLevels = gamificationData.claimedLevelRewards || [];
  if (claimedLevels.includes(level)) {
    throw new Error('Level rewards already claimed');
  }

  const coinReward = level * 10;
  const bonusReward = level % 5 === 0 ? level * 5 : 0;
  const totalCoins = coinReward + bonusReward;

  await db.runTransaction(async (transaction) => {
    const userRef = db.collection('users').doc(uid);
    transaction.update(userRef, {
      'coins.balance': FieldValue.increment(totalCoins),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(gamificationRef, {
      claimedLevelRewards: FieldValue.arrayUnion(level),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  logInfo(`Level ${level} rewards claimed for user ${uid}: ${totalCoins} coins`);

  return {
    success: true,
    level,
    coinReward: totalCoins,
    bonusReward: bonusReward > 0,
  };
}

// ========== CHALLENGES ==========

export const DAILY_CHALLENGES = [
  {
    id: 'send_5_messages',
    name: 'Conversation Starter',
    description: 'Send 5 messages today',
    target: 5,
    xpReward: 20,
    coinReward: 5,
  },
  {
    id: 'get_3_matches',
    name: 'Match Maker',
    description: 'Get 3 matches today',
    target: 3,
    xpReward: 30,
    coinReward: 10,
  },
  {
    id: 'complete_profile',
    name: 'Profile Perfectionist',
    description: 'Complete your profile 100%',
    target: 100,
    xpReward: 25,
    coinReward: 5,
  },
  {
    id: 'video_call_1',
    name: 'Face to Face',
    description: 'Complete 1 video call today',
    target: 1,
    xpReward: 50,
    coinReward: 15,
  },
] as const;

export interface TrackChallengeParams {
  uid: string;
  challengeId: string;
  progress: number;
}

/**
 * Track Challenge Progress Handler
 */
export async function handleTrackChallengeProgress(params: TrackChallengeParams) {
  const { uid, challengeId, progress } = params;

  logInfo(`Tracking challenge progress for user ${uid}: ${challengeId} - ${progress}`);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayStr = today.toISOString().split('T')[0];

  const challengeRef = db
    .collection('gamification')
    .doc(uid)
    .collection('challenges')
    .doc(`${challengeId}_${todayStr}`);

  const challengeDoc = await challengeRef.get();

  const challengeDef = DAILY_CHALLENGES.find(c => c.id === challengeId);
  if (!challengeDef) {
    throw new Error(`Invalid challenge ID: ${challengeId}`);
  }

  const currentProgress = challengeDoc.exists ? (challengeDoc.data()?.progress || 0) : 0;
  const newProgress = Math.min(progress, challengeDef.target);
  const completed = challengeDoc.exists ? (challengeDoc.data()?.completed || false) : false;

  const shouldComplete = !completed && newProgress >= challengeDef.target;

  await challengeRef.set({
    userId: uid,
    challengeId,
    date: todayStr,
    progress: newProgress,
    target: challengeDef.target,
    completed: shouldComplete ? true : completed,
    completedAt: shouldComplete ? FieldValue.serverTimestamp() : null,
    claimed: false,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  if (shouldComplete) {
    await db.collection('notifications').add({
      userId: uid,
      type: 'challenge_completed',
      title: `Challenge Completed: ${challengeDef.name}!`,
      body: `Claim your rewards: ${challengeDef.xpReward} XP and ${challengeDef.coinReward} coins`,
      data: {
        challengeId,
        xpReward: challengeDef.xpReward,
        coinReward: challengeDef.coinReward,
      },
      read: false,
      sent: false,
      createdAt: FieldValue.serverTimestamp(),
    });

    logInfo(`Challenge completed for user ${uid}: ${challengeId}`);
  }

  return {
    success: true,
    challengeId,
    progress: newProgress,
    target: challengeDef.target,
    completed: shouldComplete ? true : completed,
  };
}

export interface ClaimChallengeParams {
  uid: string;
  challengeId: string;
}

/**
 * Claim Challenge Reward Handler
 */
export async function handleClaimChallengeReward(params: ClaimChallengeParams) {
  const { uid, challengeId } = params;

  logInfo(`Claiming challenge reward for user ${uid}: ${challengeId}`);

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayStr = today.toISOString().split('T')[0];

  const challengeRef = db
    .collection('gamification')
    .doc(uid)
    .collection('challenges')
    .doc(`${challengeId}_${todayStr}`);

  const challengeDoc = await challengeRef.get();

  if (!challengeDoc.exists) {
    throw new Error('Challenge not found');
  }

  const challengeData = challengeDoc.data()!;

  if (!challengeData.completed) {
    throw new Error('Challenge not yet completed');
  }

  if (challengeData.claimed) {
    throw new Error('Reward already claimed');
  }

  const challengeDef = DAILY_CHALLENGES.find(c => c.id === challengeId);
  if (!challengeDef) {
    throw new Error(`Invalid challenge ID: ${challengeId}`);
  }

  await db.runTransaction(async (transaction) => {
    const gamificationRef = db.collection('gamification').doc(uid);
    const gamificationDoc = await transaction.get(gamificationRef);

    const currentTotalXP = gamificationDoc.exists ? (gamificationDoc.data()?.totalXP || 0) : 0;
    const currentXP = gamificationDoc.exists ? (gamificationDoc.data()?.currentXP || 0) : 0;

    transaction.set(gamificationRef, {
      totalXP: currentTotalXP + challengeDef.xpReward,
      currentXP: currentXP + challengeDef.xpReward,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    const userRef = db.collection('users').doc(uid);
    transaction.update(userRef, {
      'coins.balance': FieldValue.increment(challengeDef.coinReward),
      updatedAt: FieldValue.serverTimestamp(),
    });

    transaction.update(challengeRef, {
      claimed: true,
      claimedAt: FieldValue.serverTimestamp(),
    });
  });

  logInfo(`Challenge reward claimed for user ${uid}: ${challengeId}`);

  return {
    success: true,
    challengeId,
    xpReward: challengeDef.xpReward,
    coinReward: challengeDef.coinReward,
  };
}

/**
 * Reset Daily Challenges Handler (Scheduled)
 */
export async function handleResetDailyChallenges() {
  logInfo('Resetting daily challenges for all users');

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(0, 0, 0, 0);
  const yesterdayStr = yesterday.toISOString().split('T')[0];

  const gamificationSnapshot = await db.collection('gamification').get();

  let usersProcessed = 0;
  let challengesReset = 0;

  for (const gamificationDoc of gamificationSnapshot.docs) {
    const userId = gamificationDoc.id;

    try {
      const challengesSnapshot = await db
        .collection('gamification')
        .doc(userId)
        .collection('challenges')
        .where('date', '==', yesterdayStr)
        .get();

      for (const challengeDoc of challengesSnapshot.docs) {
        const challengeData = challengeDoc.data();
        if (challengeData.completed && challengeData.claimed) {
          await db
            .collection('gamification')
            .doc(userId)
            .collection('challenge_history')
            .add({
              ...challengeData,
              archivedAt: FieldValue.serverTimestamp(),
            });

          await challengeDoc.ref.delete();
          challengesReset++;
        }
      }

      usersProcessed++;
    } catch (error) {
      logError(`Error resetting challenges for user ${userId}:`, error);
    }
  }

  logInfo(`Daily challenges reset completed: ${usersProcessed} users, ${challengesReset} challenges archived`);
}

/**
 * Update Leaderboard Rankings Handler (Scheduled)
 */
export async function handleUpdateLeaderboardRankings() {
  logInfo('Updating leaderboard rankings');

  const gamificationSnapshot = await db
    .collection('gamification')
    .orderBy('totalXP', 'desc')
    .limit(1000)
    .get();

  const leaderboardData: any[] = [];
  let rank = 1;

  for (const doc of gamificationSnapshot.docs) {
    const data = doc.data();
    leaderboardData.push({
      userId: doc.id,
      rank,
      totalXP: data.totalXP || 0,
      level: data.level || 1,
      updatedAt: FieldValue.serverTimestamp(),
    });
    rank++;
  }

  const batchSize = 500;
  for (let i = 0; i < leaderboardData.length; i += batchSize) {
    const batch = db.batch();
    const batchData = leaderboardData.slice(i, i + batchSize);

    for (const entry of batchData) {
      const leaderboardRef = db.collection('leaderboards').doc('xp').collection('rankings').doc(entry.userId);
      batch.set(leaderboardRef, entry, { merge: true });
    }

    await batch.commit();
  }

  await db.collection('leaderboards').doc('xp').set({
    totalUsers: leaderboardData.length,
    lastUpdated: FieldValue.serverTimestamp(),
  }, { merge: true });

  const today = new Date();
  const dayOfWeek = today.getDay();

  if (dayOfWeek === 1 && today.getHours() === 0) {
    const weeklyLeaderboardRef = db.collection('leaderboards').doc('weekly');
    await weeklyLeaderboardRef.collection('rankings').get().then(snapshot => {
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      return batch.commit();
    });

    logInfo('Weekly leaderboard reset');
  }

  logInfo(`Leaderboard updated: ${leaderboardData.length} users ranked`);
}
