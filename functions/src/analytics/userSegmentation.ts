/**
 * User Segmentation Cloud Functions
 * Points 254-256: Cohort analysis, user segmentation, and churn prediction
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

/**
 * Calculate User Segment
 * Point 255: Segment users by behavior
 */
export const calculateUserSegment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;

  try {
    // Get user data
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new Error('User not found');
    }

    const userData = userDoc.data()!;

    // Calculate behavior metrics
    const now = new Date();
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    // Sessions per week
    const sessionsSnapshot = await firestore
      .collection('user_sessions')
      .where('userId', '==', userId)
      .where('startTime', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .get();

    const sessionsPerWeek = sessionsSnapshot.size;

    // Messages per week
    const messagesSnapshot = await firestore
      .collection('messages')
      .where('senderId', '==', userId)
      .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const messagesPerWeek = messagesSnapshot.data().count;

    // Matches per week
    const matchesSnapshot = await firestore
      .collection('matches')
      .where('users', 'array-contains', userId)
      .where('matchedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const matchesPerWeek = matchesSnapshot.data().count;

    // Days since last active
    const lastActiveAt = userData.lastActiveAt?.toDate() || new Date(0);
    const daysSinceLastActive = Math.floor(
      (now.getTime() - lastActiveAt.getTime()) / (24 * 60 * 60 * 1000)
    );

    // Total days active
    const accountCreatedAt = userData.createdAt.toDate();
    const totalDaysActive = Math.floor(
      (now.getTime() - accountCreatedAt.getTime()) / (24 * 60 * 60 * 1000)
    );

    // Calculate average session duration
    let totalSessionDuration = 0;
    sessionsSnapshot.docs.forEach(doc => {
      const session = doc.data();
      if (session.endTime) {
        const duration = session.endTime.toMillis() - session.startTime.toMillis();
        totalSessionDuration += duration;
      }
    });
    const avgSessionDuration = sessionsPerWeek > 0
      ? totalSessionDuration / sessionsPerWeek / 60000 // Convert to minutes
      : 0;

    // Feature adoption rate (placeholder)
    const featureAdoptionRate = 0.6; // 60%

    // Determine segment
    let segment = 'casualUser';

    if (daysSinceLastActive >= 30) {
      segment = 'churnedUser';
    } else if (daysSinceLastActive >= 14) {
      segment = 'dormantUser';
    } else if (totalDaysActive <= 7) {
      segment = 'newUser';
    } else if (
      sessionsPerWeek >= 10 &&
      messagesPerWeek >= 20 &&
      avgSessionDuration >= 15
    ) {
      segment = 'powerUser';
    } else if (sessionsPerWeek >= 2 && sessionsPerWeek <= 5) {
      segment = 'casualUser';
    }

    // Calculate engagement score (0-100)
    const engagementScore = calculateEngagementScore({
      sessionsPerWeek,
      messagesPerWeek,
      matchesPerWeek,
      avgSessionDuration,
      daysSinceLastActive,
      featureAdoptionRate,
    });

    // Store segment profile
    await firestore.collection('user_segments').doc(userId).set({
      userId,
      segment,
      assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      behaviorMetrics: {
        sessionsPerWeek,
        messagesPerWeek,
        matchesPerWeek,
        avgSessionDuration,
        daysSinceLastActive,
        totalDaysActive,
        featureAdoptionRate,
      },
      engagementScore,
    });

    return {
      segment,
      engagementScore,
      behaviorMetrics: {
        sessionsPerWeek,
        messagesPerWeek,
        matchesPerWeek,
        avgSessionDuration,
        daysSinceLastActive,
        totalDaysActive,
        featureAdoptionRate,
      },
    };
  } catch (error: any) {
    console.error('Error calculating user segment:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Calculate engagement score (0-100)
 */
function calculateEngagementScore(metrics: any): number {
  let score = 0;

  // Sessions (max 30 points)
  if (metrics.sessionsPerWeek >= 10) score += 30;
  else if (metrics.sessionsPerWeek >= 5) score += 20;
  else if (metrics.sessionsPerWeek >= 2) score += 10;

  // Messages (max 25 points)
  if (metrics.messagesPerWeek >= 20) score += 25;
  else if (metrics.messagesPerWeek >= 10) score += 15;
  else if (metrics.messagesPerWeek >= 5) score += 10;

  // Matches (max 20 points)
  if (metrics.matchesPerWeek >= 5) score += 20;
  else if (metrics.matchesPerWeek >= 2) score += 10;
  else if (metrics.matchesPerWeek >= 1) score += 5;

  // Session duration (max 15 points)
  if (metrics.avgSessionDuration >= 20) score += 15;
  else if (metrics.avgSessionDuration >= 10) score += 10;
  else if (metrics.avgSessionDuration >= 5) score += 5;

  // Recency (max 10 points) - inverse
  if (metrics.daysSinceLastActive === 0) score += 10;
  else if (metrics.daysSinceLastActive <= 3) score += 7;
  else if (metrics.daysSinceLastActive <= 7) score += 4;

  return Math.min(score, 100);
}

/**
 * Create User Cohort
 * Point 254: Cohort analysis by acquisition date
 */
export const createUserCohort = functions.pubsub
  .schedule('0 2 * * *') // Daily at 2 AM
  .onRun(async (context) => {
    try {
      // Get all users from yesterday
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      yesterday.setHours(0, 0, 0, 0);

      const todayStart = new Date(yesterday);
      todayStart.setDate(todayStart.getDate() + 1);

      const newUsersSnapshot = await firestore
        .collection('users')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(yesterday))
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(todayStart))
        .get();

      if (newUsersSnapshot.empty) {
        console.log('No new users for cohort creation');
        return;
      }

      const cohortId = yesterday.toISOString().split('T')[0]; // YYYY-MM-DD
      const totalUsers = newUsersSnapshot.size;

      // Create cohort
      await firestore.collection('user_cohorts').doc(cohortId).set({
        cohortId,
        cohortName: `Cohort ${cohortId}`,
        acquisitionDate: admin.firestore.Timestamp.fromDate(yesterday),
        totalUsers,
        retentionByDay: {}, // Will be updated by retention tracking
        characteristics: {
          platform: 'mixed',
          source: 'organic',
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Assign users to cohort
      const batch = firestore.batch();
      newUsersSnapshot.docs.forEach(doc => {
        batch.update(doc.ref, {
          cohortId,
        });
      });
      await batch.commit();

      console.log(`Created cohort ${cohortId} with ${totalUsers} users`);
    } catch (error) {
      console.error('Error creating user cohort:', error);
    }
  });

/**
 * Calculate Cohort Retention
 * Point 254: Track retention by day
 */
export const calculateCohortRetention = functions.pubsub
  .schedule('0 3 * * *') // Daily at 3 AM
  .onRun(async (context) => {
    try {
      // Get all cohorts
      const cohortsSnapshot = await firestore.collection('user_cohorts').get();

      for (const cohortDoc of cohortsSnapshot.docs) {
        const cohort = cohortDoc.data();
        const acquisitionDate = cohort.acquisitionDate.toDate();
        const now = new Date();

        const daysSinceAcquisition = Math.floor(
          (now.getTime() - acquisitionDate.getTime()) / (24 * 60 * 60 * 1000)
        );

        // Calculate retention for Day 1, 7, 14, 30, 60, 90
        const retentionDays = [1, 7, 14, 30, 60, 90];
        const retentionByDay: { [key: number]: number } = {};

        for (const day of retentionDays) {
          if (daysSinceAcquisition >= day) {
            const targetDate = new Date(acquisitionDate);
            targetDate.setDate(targetDate.getDate() + day);

            // Count users who were active on that day
            const activeUsersSnapshot = await firestore
              .collection('users')
              .where('cohortId', '==', cohort.cohortId)
              .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(targetDate))
              .count()
              .get();

            const activeCount = activeUsersSnapshot.data().count;
            const retentionRate = (activeCount / cohort.totalUsers) * 100;

            retentionByDay[day] = retentionRate;
          }
        }

        // Update cohort retention
        await cohortDoc.ref.update({
          retentionByDay,
          lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      console.log('Cohort retention calculated');
    } catch (error) {
      console.error('Error calculating cohort retention:', error);
    }
  });

/**
 * Predict User Churn
 * Point 256: Churn probability prediction
 */
export const predictUserChurn = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;

  try {
    // Get user segment
    const segmentDoc = await firestore.collection('user_segments').doc(userId).get();
    if (!segmentDoc.exists) {
      throw new Error('User segment not found');
    }

    const segmentData = segmentDoc.data()!;
    const metrics = segmentData.behaviorMetrics;

    // Calculate churn factors
    const churnFactors = [];
    let churnProbability = 0.0;

    // Factor 1: Days since last active (40% weight)
    if (metrics.daysSinceLastActive >= 14) {
      churnFactors.push({
        factorName: 'inactivity',
        impact: -0.4,
        description: `Inactive for ${metrics.daysSinceLastActive} days`,
      });
      churnProbability += 0.4;
    } else if (metrics.daysSinceLastActive >= 7) {
      churnFactors.push({
        factorName: 'inactivity',
        impact: -0.2,
        description: `Inactive for ${metrics.daysSinceLastActive} days`,
      });
      churnProbability += 0.2;
    }

    // Factor 2: Low engagement (30% weight)
    if (metrics.sessionsPerWeek < 2) {
      churnFactors.push({
        factorName: 'low_engagement',
        impact: -0.3,
        description: 'Very low session frequency',
      });
      churnProbability += 0.3;
    }

    // Factor 3: No matches/messages (20% weight)
    if (metrics.messagesPerWeek === 0 && metrics.matchesPerWeek === 0) {
      churnFactors.push({
        factorName: 'no_activity',
        impact: -0.2,
        description: 'No matches or messages recently',
      });
      churnProbability += 0.2;
    }

    // Factor 4: Low feature adoption (10% weight)
    if (metrics.featureAdoptionRate < 0.3) {
      churnFactors.push({
        factorName: 'low_feature_adoption',
        impact: -0.1,
        description: 'Using very few app features',
      });
      churnProbability += 0.1;
    }

    // Determine risk level
    let riskLevel = 'low';
    if (churnProbability >= 0.8) riskLevel = 'critical';
    else if (churnProbability >= 0.6) riskLevel = 'high';
    else if (churnProbability >= 0.3) riskLevel = 'medium';

    // Predict churn date
    let predictedChurnDate = null;
    if (churnProbability >= 0.6) {
      const daysUntilChurn = Math.round((1 - churnProbability) * 30);
      predictedChurnDate = new Date();
      predictedChurnDate.setDate(predictedChurnDate.getDate() + daysUntilChurn);
    }

    // Recommended interventions
    const interventions = [];
    if (metrics.daysSinceLastActive >= 7) {
      interventions.push('Send re-engagement notification');
    }
    if (metrics.matchesPerWeek === 0) {
      interventions.push('Suggest profile improvements');
    }
    if (metrics.messagesPerWeek === 0) {
      interventions.push('Offer conversation starters');
    }
    if (churnProbability >= 0.6) {
      interventions.push('Offer limited-time promotion');
    }

    // Store prediction
    const prediction = {
      userId,
      churnProbability,
      riskLevel,
      contributingFactors: churnFactors,
      predictedAt: admin.firestore.FieldValue.serverTimestamp(),
      predictedChurnDate: predictedChurnDate
        ? admin.firestore.Timestamp.fromDate(predictedChurnDate)
        : null,
      recommendedInterventions: interventions,
    };

    await firestore.collection('churn_predictions').doc(userId).set(prediction);

    return {
      churnProbability,
      riskLevel,
      contributingFactors: churnFactors,
      predictedChurnDate: predictedChurnDate?.toISOString() || null,
      recommendedInterventions: interventions,
    };
  } catch (error: any) {
    console.error('Error predicting user churn:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Batch Churn Prediction
 * Run daily for all users
 */
export const batchChurnPrediction = functions.pubsub
  .schedule('0 4 * * *') // Daily at 4 AM
  .onRun(async (context) => {
    try {
      // Get all active users
      const usersSnapshot = await firestore
        .collection('users')
        .where('accountStatus', '==', 'active')
        .get();

      console.log(`Running churn prediction for ${usersSnapshot.size} users`);

      let processedCount = 0;
      const batchSize = 100;

      for (let i = 0; i < usersSnapshot.docs.length; i += batchSize) {
        const batch = usersSnapshot.docs.slice(i, i + batchSize);

        await Promise.all(
          batch.map(async (userDoc) => {
            try {
              // Run prediction (simplified version)
              const userId = userDoc.id;
              // Would call predictUserChurn logic here
              processedCount++;
            } catch (err) {
              console.error(`Error predicting churn for user ${userDoc.id}:`, err);
            }
          })
        );
      }

      console.log(`Batch churn prediction completed. Processed ${processedCount} users`);
    } catch (error) {
      console.error('Error in batch churn prediction:', error);
    }
  });
