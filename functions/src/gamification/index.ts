/**
 * Gamification Service
 * 8 Cloud Functions for managing XP, achievements, challenges, and leaderboards
 */

import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { verifyAuth, handleError, logError } from '../shared/utils';
import { AchievementType, ChallengeType } from '../shared/types';
import {
  handleGrantXP,
  handleTrackAchievementProgress,
  handleUnlockAchievementReward,
  handleClaimLevelRewards,
  handleTrackChallengeProgress,
  handleClaimChallengeReward,
  handleResetDailyChallenges,
  handleUpdateLeaderboardRankings,
} from './handlers';

// XP Configuration
const XP_ACTIONS = {
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

// Level Configuration (XP required for each level)
const LEVEL_XP_REQUIREMENTS = [
  0,      // Level 1 (starting)
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

// Achievement Definitions
const ACHIEVEMENTS = {
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

// Daily Challenge Definitions
const DAILY_CHALLENGES = [
  {
    id: 'send_5_messages',
    name: 'Conversation Starter',
    description: 'Send 5 messages today',
    type: ChallengeType.DAILY,
    target: 5,
    xpReward: 20,
    coinReward: 5,
  },
  {
    id: 'get_3_matches',
    name: 'Match Maker',
    description: 'Get 3 matches today',
    type: ChallengeType.DAILY,
    target: 3,
    xpReward: 30,
    coinReward: 10,
  },
  {
    id: 'complete_profile',
    name: 'Profile Perfectionist',
    description: 'Complete your profile 100%',
    type: ChallengeType.DAILY,
    target: 100,
    xpReward: 25,
    coinReward: 5,
  },
  {
    id: 'video_call_1',
    name: 'Face to Face',
    description: 'Complete 1 video call today',
    type: ChallengeType.DAILY,
    target: 1,
    xpReward: 50,
    coinReward: 15,
  },
] as const;

// Interfaces
interface GrantXPRequest {
  action: keyof typeof XP_ACTIONS;
  metadata?: Record<string, any>;
}

interface TrackAchievementProgressRequest {
  achievementId: keyof typeof ACHIEVEMENTS;
  progress: number;
}

interface UnlockAchievementRewardRequest {
  achievementId: string;
}

interface ClaimLevelRewardsRequest {
  level: number;
}

interface TrackChallengeProgressRequest {
  challengeId: string;
  progress: number;
}

interface ClaimChallengeRewardRequest {
  challengeId: string;
}

// ========== 1. GRANT XP (HTTP Callable) ==========

export const grantXP = onCall<GrantXPRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { action, metadata } = request.data;

      return await handleGrantXP({ uid, action, metadata });
    } catch (error) {
      logError('Error granting XP:', error);
      throw handleError(error);
    }
  }
);

// ========== 2. TRACK ACHIEVEMENT PROGRESS (HTTP Callable) ==========

export const trackAchievementProgress = onCall<TrackAchievementProgressRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { achievementId, progress } = request.data;

      return await handleTrackAchievementProgress({ uid, achievementId, progress });
    } catch (error) {
      logError('Error tracking achievement progress:', error);
      throw handleError(error);
    }
  }
);

// ========== 3. UNLOCK ACHIEVEMENT REWARD (HTTP Callable) ==========

export const unlockAchievementReward = onCall<UnlockAchievementRewardRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { achievementId } = request.data;

      return await handleUnlockAchievementReward({ uid, achievementId });
    } catch (error) {
      logError('Error unlocking achievement reward:', error);
      throw handleError(error);
    }
  }
);

// ========== 4. CLAIM LEVEL REWARDS (HTTP Callable) ==========

export const claimLevelRewards = onCall<ClaimLevelRewardsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { level } = request.data;

      return await handleClaimLevelRewards({ uid, level });
    } catch (error) {
      logError('Error claiming level rewards:', error);
      throw handleError(error);
    }
  }
);

// ========== 5. TRACK CHALLENGE PROGRESS (HTTP Callable) ==========

export const trackChallengeProgress = onCall<TrackChallengeProgressRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { challengeId, progress } = request.data;

      return await handleTrackChallengeProgress({ uid, challengeId, progress });
    } catch (error) {
      logError('Error tracking challenge progress:', error);
      throw handleError(error);
    }
  }
);

// ========== 6. CLAIM CHALLENGE REWARD (HTTP Callable) ==========

export const claimChallengeReward = onCall<ClaimChallengeRewardRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { challengeId } = request.data;

      return await handleClaimChallengeReward({ uid, challengeId });
    } catch (error) {
      logError('Error claiming challenge reward:', error);
      throw handleError(error);
    }
  }
);

// ========== 7. RESET DAILY CHALLENGES (Scheduled - Daily Midnight) ==========

export const resetDailyChallenges = onSchedule(
  {
    schedule: '0 0 * * *', // Daily at midnight UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    try {
      await handleResetDailyChallenges();
    } catch (error) {
      logError('Error resetting daily challenges:', error);
      throw error;
    }
  }
);

// ========== 8. UPDATE LEADERBOARD RANKINGS (Scheduled - Hourly) ==========

export const updateLeaderboardRankings = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async () => {
    try {
      await handleUpdateLeaderboardRankings();
    } catch (error) {
      logError('Error updating leaderboard rankings:', error);
      throw error;
    }
  }
);
