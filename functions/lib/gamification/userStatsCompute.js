"use strict";
/**
 * User Stats Computation
 * Computes personal statistics for users from source collections
 * and caches them in user_stats/{userId}.
 *
 * - Scheduled: runs daily at 3 AM UTC for all users
 * - Callable: user can trigger a refresh for themselves
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.computeUserStats = computeUserStats;
exports.computeAllUserStats = computeAllUserStats;
const utils_1 = require("../shared/utils");
/** XP thresholds for each level (index = level - 1). Must match client. */
const LEVEL_XP_REQUIREMENTS = [0, 100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000, 20000, 26000, 33000, 41000, 50000];
function calculateLevel(totalXp) {
    let level = 1;
    while (level < LEVEL_XP_REQUIREMENTS.length && totalXp >= LEVEL_XP_REQUIREMENTS[level]) {
        level++;
    }
    return level;
}
/**
 * Compute and cache stats for a single user
 */
async function computeUserStats(userId) {
    var _a, _b, _c;
    (0, utils_1.logInfo)(`Computing stats for user ${userId}`);
    // 1. XP & Level from user_levels (authoritative)
    let totalXp = 0;
    let level = 1;
    const userLevelDoc = await utils_1.db.collection('user_levels').doc(userId).get();
    if (userLevelDoc.exists) {
        const data = userLevelDoc.data();
        totalXp = data.totalXP || 0;
        level = calculateLevel(totalXp);
    }
    // Fallback: check language_progress
    if (totalXp === 0) {
        const langDocs = await utils_1.db.collection('language_progress')
            .where('userId', '==', userId).get();
        for (const doc of langDocs.docs) {
            totalXp += doc.data().totalXpEarned || 0;
        }
        level = calculateLevel(totalXp);
    }
    // 2. XP transactions + daily activity (last 30 days)
    const dailyActivity = {};
    let txnXp = 0;
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    const xpDocs = await utils_1.db.collection('xp_transactions')
        .where('userId', '==', userId)
        .where('createdAt', '>=', thirtyDaysAgo)
        .orderBy('createdAt', 'desc')
        .limit(1000)
        .get();
    for (const doc of xpDocs.docs) {
        const data = doc.data();
        txnXp += data.xpAmount || 0;
        const createdAt = (_b = (_a = data.createdAt) === null || _a === void 0 ? void 0 : _a.toDate) === null || _b === void 0 ? void 0 : _b.call(_a);
        if (createdAt) {
            const key = `${createdAt.getMonth() + 1}/${createdAt.getDate()}`;
            dailyActivity[key] = (dailyActivity[key] || 0) + 1;
        }
    }
    if (txnXp > totalXp)
        totalXp = txnXp;
    // 3. Conversations count
    const [convos1, convos2] = await Promise.all([
        utils_1.db.collection('conversations').where('userId1', '==', userId).count().get(),
        utils_1.db.collection('conversations').where('userId2', '==', userId).count().get(),
    ]);
    const totalConversations = (convos1.data().count || 0) + (convos2.data().count || 0);
    // 4. Messages sent from profile
    let messagesSent = 0;
    const profileDoc = await utils_1.db.collection('profiles').doc(userId).get();
    if (profileDoc.exists) {
        messagesSent = ((_c = profileDoc.data()) === null || _c === void 0 ? void 0 : _c.messagesSent) || 0;
    }
    // 5. Vocabulary: words per language + learned (useCount >= 3)
    const wordsPerLanguage = {};
    const wordsLearnedPerLanguage = {};
    const vocabDocs = await utils_1.db.collection('user_vocabulary')
        .doc(userId).collection('words').get();
    for (const doc of vocabDocs.docs) {
        const data = doc.data();
        const lang = data.language || 'unknown';
        wordsPerLanguage[lang] = (wordsPerLanguage[lang] || 0) + 1;
        const useCount = data.useCount || 0;
        if (useCount >= 3) {
            wordsLearnedPerLanguage[lang] = (wordsLearnedPerLanguage[lang] || 0) + 1;
        }
    }
    // 6. Achievements unlocked
    const achieveCount = await utils_1.db.collection('user_achievements')
        .where('userId', '==', userId)
        .where('isUnlocked', '==', true)
        .count().get();
    // 7. Challenges completed
    const challengeCount = await utils_1.db.collection('user_challenges')
        .where('userId', '==', userId)
        .where('isCompleted', '==', true)
        .count().get();
    // Build stats object
    const statsData = {
        totalXp,
        level,
        messagesSent,
        totalConversations,
        wordsPerLanguage,
        wordsLearnedPerLanguage,
        achievementsUnlocked: achieveCount.data().count || 0,
        challengesCompleted: challengeCount.data().count || 0,
        dailyActivity,
        updatedAt: utils_1.FieldValue.serverTimestamp(),
    };
    // Write to cache
    await utils_1.db.collection('user_stats').doc(userId).set(statsData, { merge: false });
    (0, utils_1.logInfo)(`Stats computed for user ${userId}: XP=${totalXp}, level=${level}, words=${Object.values(wordsPerLanguage).reduce((a, b) => a + b, 0)}`);
    return statsData;
}
/** Page size for Firestore cursor-based pagination */
const PAGE_SIZE = 100;
/** Concurrency batch size for Promise.allSettled */
const BATCH_SIZE = 20;
/** Maximum runtime before graceful stop (8 minutes in ms) */
const TIMEOUT_MS = 480000;
/** Log progress every N users */
const LOG_INTERVAL = 500;
/**
 * Compute stats for ALL users (batch job)
 * Uses Firestore cursor-based pagination to avoid loading all user IDs
 * into memory at once. Processes users in concurrent batches and stops
 * gracefully if the elapsed time exceeds 8 minutes.
 */
async function computeAllUserStats() {
    (0, utils_1.logInfo)('Starting daily user stats computation for all users');
    const startTime = Date.now();
    let processed = 0;
    let errors = 0;
    let totalSeen = 0;
    let timedOut = false;
    // Cursor-based pagination through profiles collection
    let query = utils_1.db.collection('profiles').select().orderBy('__name__').limit(PAGE_SIZE);
    let hasMore = true;
    while (hasMore) {
        // Timeout safety check before fetching the next page
        if (Date.now() - startTime > TIMEOUT_MS) {
            timedOut = true;
            (0, utils_1.logInfo)(`Timeout reached after ${Math.round((Date.now() - startTime) / 1000)}s. Stopping gracefully.`);
            break;
        }
        const pageSnapshot = await query.get();
        const docs = pageSnapshot.docs;
        if (docs.length === 0) {
            hasMore = false;
            break;
        }
        const userIds = docs.map(doc => doc.id);
        totalSeen += userIds.length;
        // Process this page in concurrent batches of BATCH_SIZE
        for (let i = 0; i < userIds.length; i += BATCH_SIZE) {
            // Timeout safety check before each batch
            if (Date.now() - startTime > TIMEOUT_MS) {
                timedOut = true;
                (0, utils_1.logInfo)(`Timeout reached after ${Math.round((Date.now() - startTime) / 1000)}s. Stopping gracefully.`);
                break;
            }
            const batch = userIds.slice(i, i + BATCH_SIZE);
            const results = await Promise.allSettled(batch.map(userId => computeUserStats(userId)));
            for (const result of results) {
                if (result.status === 'fulfilled') {
                    processed++;
                }
                else {
                    errors++;
                    (0, utils_1.logError)('Error computing user stats', result.reason);
                }
            }
            // Progress logging
            if (processed % LOG_INTERVAL < BATCH_SIZE && processed >= LOG_INTERVAL) {
                const elapsed = Math.round((Date.now() - startTime) / 1000);
                (0, utils_1.logInfo)(`Progress: ${processed} processed, ${errors} errors, ${elapsed}s elapsed`);
            }
        }
        if (timedOut)
            break;
        // Set cursor for the next page
        const lastDoc = docs[docs.length - 1];
        if (docs.length < PAGE_SIZE) {
            hasMore = false;
        }
        else {
            query = utils_1.db.collection('profiles').select().orderBy('__name__').startAfter(lastDoc).limit(PAGE_SIZE);
        }
    }
    const elapsed = Math.round((Date.now() - startTime) / 1000);
    if (timedOut) {
        (0, utils_1.logInfo)(`Daily stats computation STOPPED (timeout): ${processed} processed, ${errors} errors, ${totalSeen} seen in ${elapsed}s`);
    }
    else {
        (0, utils_1.logInfo)(`Daily stats computation complete: ${processed} processed, ${errors} errors out of ${totalSeen} users in ${elapsed}s`);
    }
    return processed;
}
//# sourceMappingURL=userStatsCompute.js.map