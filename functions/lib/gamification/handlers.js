"use strict";
/**
 * Gamification Service - Business Logic Handlers
 * Extracted handlers that can be unit tested independently of Cloud Functions
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DAILY_CHALLENGES = exports.ACHIEVEMENTS = exports.LEVEL_XP_REQUIREMENTS = exports.XP_ACTIONS = void 0;
exports.calculateLevel = calculateLevel;
exports.calculateLevelRewards = calculateLevelRewards;
exports.handleGrantXP = handleGrantXP;
exports.handleTrackAchievementProgress = handleTrackAchievementProgress;
exports.handleUnlockAchievementReward = handleUnlockAchievementReward;
exports.handleClaimLevelRewards = handleClaimLevelRewards;
exports.handleTrackChallengeProgress = handleTrackChallengeProgress;
exports.handleClaimChallengeReward = handleClaimChallengeReward;
exports.handleResetDailyChallenges = handleResetDailyChallenges;
exports.handleUpdateLeaderboardRankings = handleUpdateLeaderboardRankings;
const utils_1 = require("../shared/utils");
// XP Configuration
exports.XP_ACTIONS = {
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
// Level Configuration
exports.LEVEL_XP_REQUIREMENTS = [
    0, // Level 1
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
/**
 * Calculate level based on current XP
 */
function calculateLevel(currentXP) {
    let level = 1;
    while (level < exports.LEVEL_XP_REQUIREMENTS.length && currentXP >= exports.LEVEL_XP_REQUIREMENTS[level]) {
        level++;
    }
    return level;
}
/**
 * Calculate rewards for leveling up
 */
function calculateLevelRewards(fromLevel, toLevel) {
    const rewards = [];
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
async function handleGrantXP(params) {
    const { uid, action, metadata } = params;
    if (!exports.XP_ACTIONS[action]) {
        throw new Error(`Invalid action: ${action}`);
    }
    const xpGained = exports.XP_ACTIONS[action];
    (0, utils_1.logInfo)(`Granting ${xpGained} XP to user ${uid} for action: ${action}`);
    // Get user's gamification data
    const userGamificationRef = utils_1.db.collection('gamification').doc(uid);
    const userGamificationDoc = await userGamificationRef.get();
    let currentXP = 0;
    let currentLevel = 1;
    let totalXP = 0;
    if (userGamificationDoc.exists) {
        const data = userGamificationDoc.data();
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
        const userRef = utils_1.db.collection('users').doc(uid);
        await userRef.update({
            'coins.balance': utils_1.FieldValue.increment(totalCoins),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        (0, utils_1.logInfo)(`User ${uid} leveled up from ${currentLevel} to ${newLevel}, earned ${totalCoins} coins`);
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
            timestamp: utils_1.FieldValue.serverTimestamp(),
            metadata,
        },
        updatedAt: utils_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    // Log XP event
    await utils_1.db.collection('gamification').doc(uid).collection('xp_history').add({
        action,
        xpGained,
        metadata,
        timestamp: utils_1.FieldValue.serverTimestamp(),
    });
    // Send level-up notification
    if (leveledUp) {
        const totalCoins = rewardsEarned.reduce((sum, r) => sum + r.coins, 0);
        await utils_1.db.collection('notifications').add({
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
            createdAt: utils_1.FieldValue.serverTimestamp(),
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
exports.ACHIEVEMENTS = {
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
/**
 * Track Achievement Progress Handler
 */
async function handleTrackAchievementProgress(params) {
    var _a, _b;
    const { uid, achievementId, progress } = params;
    if (!exports.ACHIEVEMENTS[achievementId]) {
        throw new Error(`Invalid achievement ID: ${achievementId}`);
    }
    const achievement = exports.ACHIEVEMENTS[achievementId];
    (0, utils_1.logInfo)(`Tracking achievement progress for user ${uid}: ${achievementId} - ${progress}`);
    const achievementRef = utils_1.db.collection('gamification').doc(uid).collection('achievements').doc(achievementId);
    const achievementDoc = await achievementRef.get();
    const currentProgress = achievementDoc.exists ? (((_a = achievementDoc.data()) === null || _a === void 0 ? void 0 : _a.progress) || 0) : 0;
    const achievementTarget = achievement.target || 1;
    const newProgress = Math.min(progress, achievementTarget);
    const unlocked = achievementDoc.exists ? (((_b = achievementDoc.data()) === null || _b === void 0 ? void 0 : _b.unlocked) || false) : false;
    const shouldUnlock = !unlocked && newProgress >= achievementTarget;
    await achievementRef.set({
        userId: uid,
        achievementId,
        progress: newProgress,
        target: achievementTarget,
        unlocked: shouldUnlock ? true : unlocked,
        unlockedAt: shouldUnlock ? utils_1.FieldValue.serverTimestamp() : null,
        claimed: false,
        updatedAt: utils_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    if (shouldUnlock) {
        await utils_1.db.collection('notifications').add({
            userId: uid,
            type: 'achievement_unlocked',
            title: `Achievement Unlocked: ${achievement.name}!`,
            body: achievement.description || achievement.name,
            data: {
                achievementId,
                xpReward: achievement.xpReward,
                coinReward: achievement.coinReward,
            },
            read: false,
            sent: false,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        (0, utils_1.logInfo)(`Achievement unlocked for user ${uid}: ${achievementId}`);
    }
    return {
        success: true,
        achievementId,
        progress: newProgress,
        target: achievementTarget,
        unlocked: shouldUnlock ? true : unlocked,
    };
}
/**
 * Unlock Achievement Reward Handler
 */
async function handleUnlockAchievementReward(params) {
    const { uid, achievementId } = params;
    if (!exports.ACHIEVEMENTS[achievementId]) {
        throw new Error(`Invalid achievement ID: ${achievementId}`);
    }
    const achievement = exports.ACHIEVEMENTS[achievementId];
    (0, utils_1.logInfo)(`Claiming achievement reward for user ${uid}: ${achievementId}`);
    const achievementRef = utils_1.db.collection('gamification').doc(uid).collection('achievements').doc(achievementId);
    const achievementDoc = await achievementRef.get();
    if (!achievementDoc.exists) {
        throw new Error('Achievement not found');
    }
    const achievementData = achievementDoc.data();
    if (!achievementData.unlocked) {
        throw new Error('Achievement not yet unlocked');
    }
    if (achievementData.claimed) {
        throw new Error('Reward already claimed');
    }
    await utils_1.db.runTransaction(async (transaction) => {
        var _a, _b;
        const gamificationRef = utils_1.db.collection('gamification').doc(uid);
        const gamificationDoc = await transaction.get(gamificationRef);
        const currentTotalXP = gamificationDoc.exists ? (((_a = gamificationDoc.data()) === null || _a === void 0 ? void 0 : _a.totalXP) || 0) : 0;
        const currentXP = gamificationDoc.exists ? (((_b = gamificationDoc.data()) === null || _b === void 0 ? void 0 : _b.currentXP) || 0) : 0;
        transaction.set(gamificationRef, {
            totalXP: currentTotalXP + achievement.xpReward,
            currentXP: currentXP + achievement.xpReward,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        const userRef = utils_1.db.collection('users').doc(uid);
        transaction.update(userRef, {
            'coins.balance': utils_1.FieldValue.increment(achievement.coinReward),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        transaction.update(achievementRef, {
            claimed: true,
            claimedAt: utils_1.FieldValue.serverTimestamp(),
        });
    });
    (0, utils_1.logInfo)(`Achievement reward claimed for user ${uid}: ${achievementId}`);
    return {
        success: true,
        achievementId,
        xpReward: achievement.xpReward,
        coinReward: achievement.coinReward,
    };
}
/**
 * Claim Level Rewards Handler
 */
async function handleClaimLevelRewards(params) {
    const { uid, level } = params;
    if (level < 1 || level > exports.LEVEL_XP_REQUIREMENTS.length) {
        throw new Error(`Invalid level: ${level}`);
    }
    (0, utils_1.logInfo)(`Claiming level rewards for user ${uid}: Level ${level}`);
    const gamificationRef = utils_1.db.collection('gamification').doc(uid);
    const gamificationDoc = await gamificationRef.get();
    if (!gamificationDoc.exists) {
        throw new Error('Gamification data not found');
    }
    const gamificationData = gamificationDoc.data();
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
    await utils_1.db.runTransaction(async (transaction) => {
        const userRef = utils_1.db.collection('users').doc(uid);
        transaction.update(userRef, {
            'coins.balance': utils_1.FieldValue.increment(totalCoins),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        transaction.update(gamificationRef, {
            claimedLevelRewards: utils_1.FieldValue.arrayUnion(level),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
    });
    (0, utils_1.logInfo)(`Level ${level} rewards claimed for user ${uid}: ${totalCoins} coins`);
    return {
        success: true,
        level,
        coinReward: totalCoins,
        bonusReward: bonusReward > 0,
    };
}
// ========== CHALLENGES ==========
exports.DAILY_CHALLENGES = [
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
];
/**
 * Track Challenge Progress Handler
 */
async function handleTrackChallengeProgress(params) {
    var _a, _b;
    const { uid, challengeId, progress } = params;
    (0, utils_1.logInfo)(`Tracking challenge progress for user ${uid}: ${challengeId} - ${progress}`);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];
    const challengeRef = utils_1.db
        .collection('gamification')
        .doc(uid)
        .collection('challenges')
        .doc(`${challengeId}_${todayStr}`);
    const challengeDoc = await challengeRef.get();
    const challengeDef = exports.DAILY_CHALLENGES.find(c => c.id === challengeId);
    if (!challengeDef) {
        throw new Error(`Invalid challenge ID: ${challengeId}`);
    }
    const currentProgress = challengeDoc.exists ? (((_a = challengeDoc.data()) === null || _a === void 0 ? void 0 : _a.progress) || 0) : 0;
    const newProgress = Math.min(progress, challengeDef.target);
    const completed = challengeDoc.exists ? (((_b = challengeDoc.data()) === null || _b === void 0 ? void 0 : _b.completed) || false) : false;
    const shouldComplete = !completed && newProgress >= challengeDef.target;
    await challengeRef.set({
        userId: uid,
        challengeId,
        date: todayStr,
        progress: newProgress,
        target: challengeDef.target,
        completed: shouldComplete ? true : completed,
        completedAt: shouldComplete ? utils_1.FieldValue.serverTimestamp() : null,
        claimed: false,
        updatedAt: utils_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    if (shouldComplete) {
        await utils_1.db.collection('notifications').add({
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
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        (0, utils_1.logInfo)(`Challenge completed for user ${uid}: ${challengeId}`);
    }
    return {
        success: true,
        challengeId,
        progress: newProgress,
        target: challengeDef.target,
        completed: shouldComplete ? true : completed,
    };
}
/**
 * Claim Challenge Reward Handler
 */
async function handleClaimChallengeReward(params) {
    const { uid, challengeId } = params;
    (0, utils_1.logInfo)(`Claiming challenge reward for user ${uid}: ${challengeId}`);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStr = today.toISOString().split('T')[0];
    const challengeRef = utils_1.db
        .collection('gamification')
        .doc(uid)
        .collection('challenges')
        .doc(`${challengeId}_${todayStr}`);
    const challengeDoc = await challengeRef.get();
    if (!challengeDoc.exists) {
        throw new Error('Challenge not found');
    }
    const challengeData = challengeDoc.data();
    if (!challengeData.completed) {
        throw new Error('Challenge not yet completed');
    }
    if (challengeData.claimed) {
        throw new Error('Reward already claimed');
    }
    const challengeDef = exports.DAILY_CHALLENGES.find(c => c.id === challengeId);
    if (!challengeDef) {
        throw new Error(`Invalid challenge ID: ${challengeId}`);
    }
    await utils_1.db.runTransaction(async (transaction) => {
        var _a, _b;
        const gamificationRef = utils_1.db.collection('gamification').doc(uid);
        const gamificationDoc = await transaction.get(gamificationRef);
        const currentTotalXP = gamificationDoc.exists ? (((_a = gamificationDoc.data()) === null || _a === void 0 ? void 0 : _a.totalXP) || 0) : 0;
        const currentXP = gamificationDoc.exists ? (((_b = gamificationDoc.data()) === null || _b === void 0 ? void 0 : _b.currentXP) || 0) : 0;
        transaction.set(gamificationRef, {
            totalXP: currentTotalXP + challengeDef.xpReward,
            currentXP: currentXP + challengeDef.xpReward,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        const userRef = utils_1.db.collection('users').doc(uid);
        transaction.update(userRef, {
            'coins.balance': utils_1.FieldValue.increment(challengeDef.coinReward),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        transaction.update(challengeRef, {
            claimed: true,
            claimedAt: utils_1.FieldValue.serverTimestamp(),
        });
    });
    (0, utils_1.logInfo)(`Challenge reward claimed for user ${uid}: ${challengeId}`);
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
async function handleResetDailyChallenges() {
    (0, utils_1.logInfo)('Resetting daily challenges for all users');
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    yesterday.setHours(0, 0, 0, 0);
    const yesterdayStr = yesterday.toISOString().split('T')[0];
    const gamificationSnapshot = await utils_1.db.collection('gamification').get();
    let usersProcessed = 0;
    let challengesReset = 0;
    for (const gamificationDoc of gamificationSnapshot.docs) {
        const userId = gamificationDoc.id;
        try {
            const challengesSnapshot = await utils_1.db
                .collection('gamification')
                .doc(userId)
                .collection('challenges')
                .where('date', '==', yesterdayStr)
                .get();
            for (const challengeDoc of challengesSnapshot.docs) {
                const challengeData = challengeDoc.data();
                if (challengeData.completed && challengeData.claimed) {
                    await utils_1.db
                        .collection('gamification')
                        .doc(userId)
                        .collection('challenge_history')
                        .add(Object.assign(Object.assign({}, challengeData), { archivedAt: utils_1.FieldValue.serverTimestamp() }));
                    await challengeDoc.ref.delete();
                    challengesReset++;
                }
            }
            usersProcessed++;
        }
        catch (error) {
            (0, utils_1.logError)(`Error resetting challenges for user ${userId}:`, error);
        }
    }
    (0, utils_1.logInfo)(`Daily challenges reset completed: ${usersProcessed} users, ${challengesReset} challenges archived`);
}
/**
 * Update Leaderboard Rankings Handler (Scheduled)
 */
async function handleUpdateLeaderboardRankings() {
    (0, utils_1.logInfo)('Updating leaderboard rankings');
    const gamificationSnapshot = await utils_1.db
        .collection('gamification')
        .orderBy('totalXP', 'desc')
        .limit(1000)
        .get();
    const leaderboardData = [];
    let rank = 1;
    for (const doc of gamificationSnapshot.docs) {
        const data = doc.data();
        leaderboardData.push({
            userId: doc.id,
            rank,
            totalXP: data.totalXP || 0,
            level: data.level || 1,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        rank++;
    }
    const batchSize = 500;
    for (let i = 0; i < leaderboardData.length; i += batchSize) {
        const batch = utils_1.db.batch();
        const batchData = leaderboardData.slice(i, i + batchSize);
        for (const entry of batchData) {
            const leaderboardRef = utils_1.db.collection('leaderboards').doc('xp').collection('rankings').doc(entry.userId);
            batch.set(leaderboardRef, entry, { merge: true });
        }
        await batch.commit();
    }
    await utils_1.db.collection('leaderboards').doc('xp').set({
        totalUsers: leaderboardData.length,
        lastUpdated: utils_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    const today = new Date();
    const dayOfWeek = today.getDay();
    if (dayOfWeek === 1 && today.getHours() === 0) {
        const weeklyLeaderboardRef = utils_1.db.collection('leaderboards').doc('weekly');
        await weeklyLeaderboardRef.collection('rankings').get().then(snapshot => {
            const batch = utils_1.db.batch();
            snapshot.docs.forEach(doc => batch.delete(doc.ref));
            return batch.commit();
        });
        (0, utils_1.logInfo)('Weekly leaderboard reset');
    }
    (0, utils_1.logInfo)(`Leaderboard updated: ${leaderboardData.length} users ranked`);
}
//# sourceMappingURL=handlers.js.map