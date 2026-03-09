/**
 * User Stats Computation
 * Computes personal statistics for users from source collections
 * and caches them in user_stats/{userId}.
 *
 * - Scheduled: runs daily at 3 AM UTC for all users
 * - Callable: user can trigger a refresh for themselves
 */

import { db, FieldValue, logInfo, logError } from '../shared/utils';

/**
 * Compute and cache stats for a single user
 */
export async function computeUserStats(userId: string): Promise<Record<string, any>> {
  logInfo(`Computing stats for user ${userId}`);

  // 1. XP & Level from user_levels (authoritative)
  let totalXp = 0;
  let level = 1;
  const userLevelDoc = await db.collection('user_levels').doc(userId).get();
  if (userLevelDoc.exists) {
    const data = userLevelDoc.data()!;
    totalXp = (data.totalXP as number) || 0;
    level = (data.level as number) || Math.floor(totalXp / 100) + 1;
  }

  // Fallback: check language_progress
  if (totalXp === 0) {
    const langDocs = await db.collection('language_progress')
      .where('userId', '==', userId).get();
    for (const doc of langDocs.docs) {
      totalXp += (doc.data().totalXpEarned as number) || 0;
    }
    level = Math.floor(totalXp / 100) + 1;
  }

  // 2. XP transactions + daily activity (last 30 days)
  const dailyActivity: Record<string, number> = {};
  let txnXp = 0;
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const xpDocs = await db.collection('xp_transactions')
    .where('userId', '==', userId)
    .where('createdAt', '>=', thirtyDaysAgo)
    .orderBy('createdAt', 'desc')
    .limit(1000)
    .get();

  for (const doc of xpDocs.docs) {
    const data = doc.data();
    txnXp += (data.xpAmount as number) || 0;
    const createdAt = data.createdAt?.toDate?.();
    if (createdAt) {
      const key = `${createdAt.getMonth() + 1}/${createdAt.getDate()}`;
      dailyActivity[key] = (dailyActivity[key] || 0) + 1;
    }
  }
  if (txnXp > totalXp) totalXp = txnXp;

  // 3. Conversations count
  const [convos1, convos2] = await Promise.all([
    db.collection('conversations').where('userId1', '==', userId).count().get(),
    db.collection('conversations').where('userId2', '==', userId).count().get(),
  ]);
  const totalConversations = (convos1.data().count || 0) + (convos2.data().count || 0);

  // 4. Messages sent from profile
  let messagesSent = 0;
  const profileDoc = await db.collection('profiles').doc(userId).get();
  if (profileDoc.exists) {
    messagesSent = (profileDoc.data()?.messagesSent as number) || 0;
  }

  // 5. Vocabulary: words per language + learned (useCount >= 3)
  const wordsPerLanguage: Record<string, number> = {};
  const wordsLearnedPerLanguage: Record<string, number> = {};
  const vocabDocs = await db.collection('user_vocabulary')
    .doc(userId).collection('words').get();

  for (const doc of vocabDocs.docs) {
    const data = doc.data();
    const lang = (data.language as string) || 'unknown';
    wordsPerLanguage[lang] = (wordsPerLanguage[lang] || 0) + 1;
    const useCount = (data.useCount as number) || 0;
    if (useCount >= 3) {
      wordsLearnedPerLanguage[lang] = (wordsLearnedPerLanguage[lang] || 0) + 1;
    }
  }

  // 6. Achievements unlocked
  const achieveCount = await db.collection('user_achievements')
    .where('userId', '==', userId)
    .where('isUnlocked', '==', true)
    .count().get();

  // 7. Challenges completed
  const challengeCount = await db.collection('user_challenges')
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
    updatedAt: FieldValue.serverTimestamp(),
  };

  // Write to cache
  await db.collection('user_stats').doc(userId).set(statsData, { merge: false });

  logInfo(`Stats computed for user ${userId}: XP=${totalXp}, level=${level}, words=${Object.values(wordsPerLanguage).reduce((a, b) => a + b, 0)}`);

  return statsData;
}

/**
 * Compute stats for ALL users (batch job)
 * Iterates through all user profiles and computes stats for each.
 */
export async function computeAllUserStats(): Promise<number> {
  logInfo('Starting daily user stats computation for all users');

  // Get all user IDs from profiles collection
  const profilesSnapshot = await db.collection('profiles').select().get();
  const userIds = profilesSnapshot.docs.map(doc => doc.id);

  logInfo(`Found ${userIds.length} users to process`);

  let processed = 0;
  let errors = 0;

  // Process in batches of 10 to avoid overloading
  for (let i = 0; i < userIds.length; i += 10) {
    const batch = userIds.slice(i, i + 10);
    const results = await Promise.allSettled(
      batch.map(userId => computeUserStats(userId))
    );

    for (const result of results) {
      if (result.status === 'fulfilled') {
        processed++;
      } else {
        errors++;
        logError('Error computing user stats', result.reason);
      }
    }
  }

  logInfo(`Daily stats computation complete: ${processed} processed, ${errors} errors out of ${userIds.length} users`);
  return processed;
}
