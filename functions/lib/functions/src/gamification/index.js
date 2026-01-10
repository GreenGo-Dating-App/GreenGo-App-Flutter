"use strict";
/**
 * Gamification Service
 * 8 Cloud Functions for managing XP, achievements, challenges, and leaderboards
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateLeaderboardRankings = exports.resetDailyChallenges = exports.claimChallengeReward = exports.trackChallengeProgress = exports.claimLevelRewards = exports.unlockAchievementReward = exports.trackAchievementProgress = exports.grantXP = void 0;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const utils_1 = require("../shared/utils");
const types_1 = require("../shared/types");
const handlers_1 = require("./handlers");
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
};
// Level Configuration (XP required for each level)
const LEVEL_XP_REQUIREMENTS = [
    0, // Level 1 (starting)
    100, // Level 2
    250, // Level 3
    500, // Level 4
    1000, // Level 5
    2000, // Level 6
    3500, // Level 7
    5500, // Level 8
    8000, // Level 9
    11000, // Level 10
    15000, // Level 11
    20000, // Level 12
    26000, // Level 13
    33000, // Level 14
    41000, // Level 15
    50000, // Level 16
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
};
// Daily Challenge Definitions
const DAILY_CHALLENGES = [
    {
        id: 'send_5_messages',
        name: 'Conversation Starter',
        description: 'Send 5 messages today',
        type: types_1.ChallengeType.DAILY,
        target: 5,
        xpReward: 20,
        coinReward: 5,
    },
    {
        id: 'get_3_matches',
        name: 'Match Maker',
        description: 'Get 3 matches today',
        type: types_1.ChallengeType.DAILY,
        target: 3,
        xpReward: 30,
        coinReward: 10,
    },
    {
        id: 'complete_profile',
        name: 'Profile Perfectionist',
        description: 'Complete your profile 100%',
        type: types_1.ChallengeType.DAILY,
        target: 100,
        xpReward: 25,
        coinReward: 5,
    },
    {
        id: 'video_call_1',
        name: 'Face to Face',
        description: 'Complete 1 video call today',
        type: types_1.ChallengeType.DAILY,
        target: 1,
        xpReward: 50,
        coinReward: 15,
    },
];
// ========== 1. GRANT XP (HTTP Callable) ==========
exports.grantXP = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { action, metadata } = request.data;
        return await (0, handlers_1.handleGrantXP)({ uid, action, metadata });
    }
    catch (error) {
        (0, utils_1.logError)('Error granting XP:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 2. TRACK ACHIEVEMENT PROGRESS (HTTP Callable) ==========
exports.trackAchievementProgress = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { achievementId, progress } = request.data;
        return await (0, handlers_1.handleTrackAchievementProgress)({ uid, achievementId, progress });
    }
    catch (error) {
        (0, utils_1.logError)('Error tracking achievement progress:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 3. UNLOCK ACHIEVEMENT REWARD (HTTP Callable) ==========
exports.unlockAchievementReward = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { achievementId } = request.data;
        return await (0, handlers_1.handleUnlockAchievementReward)({ uid, achievementId });
    }
    catch (error) {
        (0, utils_1.logError)('Error unlocking achievement reward:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 4. CLAIM LEVEL REWARDS (HTTP Callable) ==========
exports.claimLevelRewards = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { level } = request.data;
        return await (0, handlers_1.handleClaimLevelRewards)({ uid, level });
    }
    catch (error) {
        (0, utils_1.logError)('Error claiming level rewards:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 5. TRACK CHALLENGE PROGRESS (HTTP Callable) ==========
exports.trackChallengeProgress = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { challengeId, progress } = request.data;
        return await (0, handlers_1.handleTrackChallengeProgress)({ uid, challengeId, progress });
    }
    catch (error) {
        (0, utils_1.logError)('Error tracking challenge progress:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 6. CLAIM CHALLENGE REWARD (HTTP Callable) ==========
exports.claimChallengeReward = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { challengeId } = request.data;
        return await (0, handlers_1.handleClaimChallengeReward)({ uid, challengeId });
    }
    catch (error) {
        (0, utils_1.logError)('Error claiming challenge reward:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 7. RESET DAILY CHALLENGES (Scheduled - Daily Midnight) ==========
exports.resetDailyChallenges = (0, scheduler_1.onSchedule)({
    schedule: '0 0 * * *', // Daily at midnight UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
}, async () => {
    try {
        await (0, handlers_1.handleResetDailyChallenges)();
    }
    catch (error) {
        (0, utils_1.logError)('Error resetting daily challenges:', error);
        throw error;
    }
});
// ========== 8. UPDATE LEADERBOARD RANKINGS (Scheduled - Hourly) ==========
exports.updateLeaderboardRankings = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 300,
}, async () => {
    try {
        await (0, handlers_1.handleUpdateLeaderboardRankings)();
    }
    catch (error) {
        (0, utils_1.logError)('Error updating leaderboard rankings:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map