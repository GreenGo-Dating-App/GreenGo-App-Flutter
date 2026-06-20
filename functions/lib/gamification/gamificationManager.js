"use strict";
/**
 * Gamification Cloud Functions
 * Points 176-200: Backend support for achievements, levels, and challenges
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateLeaderboardRankings = exports.resetDailyChallenges = exports.claimChallengeReward = exports.trackChallengeProgress = exports.claimLevelRewards = exports.unlockAchievementReward = exports.trackAchievementProgress = exports.grantXP = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
/**
 * Grant XP to User
 * Point 187: XP rewards for actions
 */
exports.grantXP = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, xpAmount, reason } = data;
    if (!userId || !xpAmount || !reason) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    try {
        const levelRef = firestore.collection('user_levels').doc(userId);
        const result = await firestore.runTransaction(async (transaction) => {
            const levelDoc = await transaction.get(levelRef);
            let currentLevel = 1;
            let currentXP = 0;
            let totalXP = 0;
            if (levelDoc.exists) {
                const data = levelDoc.data();
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
            transaction.set(levelRef, {
                userId,
                level: newLevel,
                currentXP: newCurrentXP,
                totalXP: newTotalXP,
                isVIP,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
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
    }
    catch (error) {
        console.error('Error granting XP:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Track Achievement Progress
 * Points 176-185: Update achievement progress
 */
exports.trackAchievementProgress = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, achievementId, incrementBy = 1 } = data;
    try {
        const progressRef = firestore
            .collection('achievement_progress')
            .doc(`${userId}_${achievementId}`);
        const result = await firestore.runTransaction(async (transaction) => {
            const progressDoc = await transaction.get(progressRef);
            let progress = 0;
            let requiredCount = 1;
            if (progressDoc.exists) {
                const data = progressDoc.data();
                progress = data.progress;
                requiredCount = data.requiredCount;
            }
            const newProgress = progress + incrementBy;
            const isCompleted = newProgress >= requiredCount;
            transaction.set(progressRef, {
                userId,
                achievementId,
                progress: newProgress,
                requiredCount,
                isCompleted,
                completedAt: isCompleted
                    ? admin.firestore.FieldValue.serverTimestamp()
                    : null,
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            return {
                progress: newProgress,
                requiredCount,
                isCompleted,
                wasJustCompleted: isCompleted && progress < requiredCount,
            };
        });
        return result;
    }
    catch (error) {
        console.error('Error tracking achievement progress:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Unlock Achievement and Grant Rewards
 * Points 176-185: Unlock achievement
 */
exports.unlockAchievementReward = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, achievementId } = data;
    try {
        const progressRef = firestore
            .collection('achievement_progress')
            .doc(`${userId}_${achievementId}`);
        await firestore.runTransaction(async (transaction) => {
            const progressDoc = await transaction.get(progressRef);
            if (!progressDoc.exists) {
                throw new Error('Achievement progress not found');
            }
            const progressData = progressDoc.data();
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
    }
    catch (error) {
        console.error('Error unlocking achievement:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Claim Level Rewards
 * Point 190: Level-based rewards
 */
exports.claimLevelRewards = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, level } = data;
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
        const userLevel = levelDoc.data().level;
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
    }
    catch (error) {
        console.error('Error claiming level rewards:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Track Challenge Progress
 * Point 197: Challenge tracking
 */
exports.trackChallengeProgress = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, challengeId, incrementBy = 1 } = data;
    try {
        const progressRef = firestore
            .collection('challenge_progress')
            .doc(`${userId}_${challengeId}`);
        const result = await firestore.runTransaction(async (transaction) => {
            const progressDoc = await transaction.get(progressRef);
            let progress = 0;
            let requiredCount = 1;
            if (progressDoc.exists) {
                const data = progressDoc.data();
                progress = data.progress;
                requiredCount = data.requiredCount;
            }
            const newProgress = progress + incrementBy;
            const isCompleted = newProgress >= requiredCount;
            transaction.set(progressRef, {
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
            }, { merge: true });
            return {
                progress: newProgress,
                requiredCount,
                isCompleted,
                wasJustCompleted: isCompleted && progress < requiredCount,
            };
        });
        return result;
    }
    catch (error) {
        console.error('Error tracking challenge progress:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Claim Challenge Reward
 * Point 198: Challenge rewards
 */
exports.claimChallengeReward = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, challengeId } = data;
    try {
        const progressRef = firestore
            .collection('challenge_progress')
            .doc(`${userId}_${challengeId}`);
        await firestore.runTransaction(async (transaction) => {
            const progressDoc = await transaction.get(progressRef);
            if (!progressDoc.exists) {
                throw new Error('Challenge progress not found');
            }
            const progressData = progressDoc.data();
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
    }
    catch (error) {
        console.error('Error claiming challenge reward:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Reset Daily Challenges
 * Point 196: Rotating daily challenges - runs at midnight UTC
 */
exports.resetDailyChallenges = functions.pubsub
    .schedule('0 0 * * *')
    .timeZone('UTC')
    .onRun(async (context) => {
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
    }
    catch (error) {
        console.error('Error resetting daily challenges:', error);
        throw error;
    }
});
/**
 * Update Leaderboard Rankings
 * Point 191, 192: Leaderboard with seasonal resets
 */
exports.updateLeaderboardRankings = functions.pubsub
    .schedule('0 * * * *') // Every hour
    .onRun(async (context) => {
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
    }
    catch (error) {
        console.error('Error updating leaderboard:', error);
        throw error;
    }
});
/**
 * Helper Functions
 */
function calculateLevel(totalXP) {
    let level = 1;
    while (totalXPForLevel(level + 1) <= totalXP && level < 100) {
        level++;
    }
    return level;
}
function totalXPForLevel(level) {
    if (level <= 1)
        return 0;
    let total = 0;
    for (let i = 2; i <= level; i++) {
        total += xpRequiredForLevel(i);
    }
    return total;
}
function xpRequiredForLevel(level) {
    if (level <= 1)
        return 0;
    const baseXP = 100;
    return Math.round(baseXP * Math.pow(level, 1.5));
}
function calculateCurrentXP(totalXP) {
    const level = calculateLevel(totalXP);
    const xpForCurrentLevel = totalXPForLevel(level);
    return totalXP - xpForCurrentLevel;
}
//# sourceMappingURL=gamificationManager.js.map