/**
 * Analytics Service
 * 20+ Cloud Functions for analytics, metrics, and business intelligence
 */

import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { verifyAdminAuth, verifyAuth, handleError, logInfo, logError, db, FieldValue } from '../shared/utils';
import { BigQuery } from '@google-cloud/bigquery';
import * as admin from 'firebase-admin';

const bigquery = new BigQuery();
const DATASET_ID = 'greengo_analytics';

// Interfaces
interface TrackEventRequest {
  eventName: string;
  eventData?: Record<string, any>;
}

interface GetRevenueDashboardRequest {
  startDate: string;
  endDate: string;
}

interface GetMRRTrendsRequest {
  startDate: string;
  endDate: string;
}

interface GetCohortAnalysisRequest {
  cohortType: 'weekly' | 'monthly';
  startDate: string;
  endDate: string;
}

interface GetRetentionRatesRequest {
  cohortDate: string;
  weeks?: number;
}

interface PredictChurnRequest {
  userId?: string;
  batchSize?: number;
}

interface GetChurnRiskSegmentRequest {
  threshold?: number;
  limit?: number;
}

interface CreateABTestRequest {
  name: string;
  description: string;
  variants: Array<{ name: string; weight: number }>;
  startDate: string;
  endDate: string;
}

interface AssignABTestVariantRequest {
  testId: string;
}

interface GetABTestResultsRequest {
  testId: string;
}

interface GetUserMetricsRequest {
  userId: string;
  period?: string;
}

interface GetEngagementMetricsRequest {
  startDate: string;
  endDate: string;
}

interface GetConversionMetricsRequest {
  startDate: string;
  endDate: string;
}

interface GetMatchQualityMetricsRequest {
  startDate: string;
  endDate: string;
}

interface CreateUserSegmentRequest {
  name: string;
  description: string;
  criteria: Record<string, any>;
}

interface GetUserSegmentsRequest {
  limit?: number;
}

interface GetUsersInSegmentRequest {
  segmentId: string;
  limit?: number;
}

interface UpdateSegmentCriteriaRequest {
  segmentId: string;
  criteria: Record<string, any>;
}

// ========== EVENT TRACKING ==========

// 1. Track Custom Event
export const trackEvent = onCall<TrackEventRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { eventName, eventData } = request.data;

      logInfo(`Tracking event: ${eventName} for user ${uid}`);

      // Store in Firestore
      await db.collection('analytics_events').add({
        userId: uid,
        eventName,
        eventData: eventData || {},
        timestamp: FieldValue.serverTimestamp(),
      });

      // Also send to BigQuery for analytics
      const table = bigquery.dataset(DATASET_ID).table('user_events');
      await table.insert([{
        user_id: uid,
        event_name: eventName,
        event_data: JSON.stringify(eventData || {}),
        timestamp: new Date().toISOString(),
      }]);

      return { success: true };
    } catch (error) {
      logError('Error tracking event:', error);
      throw handleError(error);
    }
  }
);

// 2. Auto-track User Events (Firestore Trigger)
export const autoTrackUserEvent = onDocumentCreated(
  {
    document: 'users/{userId}',
    memory: '256MiB',
  },
  async (event) => {
    try {
      const userId = event.params.userId;
      const userData = event.data?.data();

      if (!userData) return;

      logInfo(`Auto-tracking user signup for ${userId}`);

      // Track signup event in BigQuery
      const table = bigquery.dataset(DATASET_ID).table('user_events');
      await table.insert([{
        user_id: userId,
        event_name: 'user_signup',
        event_data: JSON.stringify({
          email: userData.email,
          subscription_tier: userData.subscriptionTier,
        }),
        timestamp: new Date().toISOString(),
      }]);
    } catch (error) {
      logError('Error auto-tracking user event:', error);
    }
  }
);

// ========== REVENUE ANALYTICS ==========

// 3. Get Revenue Dashboard
export const getRevenueDashboard = onCall<GetRevenueDashboardRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching revenue dashboard from ${startDate} to ${endDate}`);

      // Query BigQuery for revenue data
      const query = `
        SELECT
          DATE(timestamp) as date,
          SUM(CASE WHEN event_name = 'subscription_purchase' THEN CAST(JSON_EXTRACT_SCALAR(event_data, '$.amount') AS FLOAT64) ELSE 0 END) as subscription_revenue,
          SUM(CASE WHEN event_name = 'coin_purchase' THEN CAST(JSON_EXTRACT_SCALAR(event_data, '$.amount') AS FLOAT64) ELSE 0 END) as coin_revenue,
          COUNT(DISTINCT CASE WHEN event_name = 'subscription_purchase' THEN user_id END) as new_subscribers,
          COUNT(DISTINCT CASE WHEN event_name = 'coin_purchase' THEN user_id END) as coin_purchasers
        FROM \`${DATASET_ID}.revenue_events\`
        WHERE DATE(timestamp) BETWEEN @startDate AND @endDate
        GROUP BY date
        ORDER BY date DESC
      `;

      const options = {
        query,
        params: { startDate, endDate },
      };

      const [rows] = await bigquery.query(options);

      const totalSubscriptionRevenue = rows.reduce((sum: number, row: any) => sum + (row.subscription_revenue || 0), 0);
      const totalCoinRevenue = rows.reduce((sum: number, row: any) => sum + (row.coin_revenue || 0), 0);

      return {
        success: true,
        dashboard: {
          totalRevenue: (totalSubscriptionRevenue + totalCoinRevenue).toFixed(2),
          subscriptionRevenue: totalSubscriptionRevenue.toFixed(2),
          coinRevenue: totalCoinRevenue.toFixed(2),
          dailyBreakdown: rows,
        },
      };
    } catch (error) {
      logError('Error fetching revenue dashboard:', error);
      throw handleError(error);
    }
  }
);

// 4. Get MRR Trends
export const getMRRTrends = onCall<GetMRRTrendsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching MRR trends from ${startDate} to ${endDate}`);

      // Get subscription data from Firestore
      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const subscriptionsSnapshot = await db
        .collection('subscriptions')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      const mrrByMonth: Record<string, { mrr: number, subscribers: number }> = {};

      subscriptionsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        const month = data.createdAt.toDate().toISOString().substring(0, 7); // YYYY-MM

        if (!mrrByMonth[month]) {
          mrrByMonth[month] = { mrr: 0, subscribers: 0 };
        }

        if (data.tier === 'silver') mrrByMonth[month].mrr += 9.99;
        if (data.tier === 'gold') mrrByMonth[month].mrr += 19.99;
        mrrByMonth[month].subscribers++;
      });

      return {
        success: true,
        trends: mrrByMonth,
      };
    } catch (error) {
      logError('Error fetching MRR trends:', error);
      throw handleError(error);
    }
  }
);

// ========== COHORT ANALYSIS ==========

// 5. Get Cohort Analysis
export const getCohortAnalysis = onCall<GetCohortAnalysisRequest>(
  {
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { cohortType, startDate, endDate } = request.data;

      logInfo(`Fetching ${cohortType} cohort analysis from ${startDate} to ${endDate}`);

      // Query BigQuery for cohort data
      const query = `
        WITH cohorts AS (
          SELECT
            user_id,
            DATE_TRUNC(DATE(MIN(timestamp)), ${cohortType === 'weekly' ? 'WEEK' : 'MONTH'}) as cohort_date
          FROM \`${DATASET_ID}.user_events\`
          WHERE event_name = 'user_signup'
          GROUP BY user_id
        ),
        user_activity AS (
          SELECT DISTINCT
            user_id,
            DATE_TRUNC(DATE(timestamp), ${cohortType === 'weekly' ? 'WEEK' : 'MONTH'}) as activity_date
          FROM \`${DATASET_ID}.user_events\`
        )
        SELECT
          c.cohort_date,
          a.activity_date,
          COUNT(DISTINCT c.user_id) as users
        FROM cohorts c
        LEFT JOIN user_activity a ON c.user_id = a.user_id
        WHERE c.cohort_date BETWEEN @startDate AND @endDate
        GROUP BY c.cohort_date, a.activity_date
        ORDER BY c.cohort_date, a.activity_date
      `;

      const options = {
        query,
        params: { startDate, endDate },
      };

      const [rows] = await bigquery.query(options);

      return {
        success: true,
        cohorts: rows,
      };
    } catch (error) {
      logError('Error fetching cohort analysis:', error);
      throw handleError(error);
    }
  }
);

// 6. Get Retention Rates
export const getRetentionRates = onCall<GetRetentionRatesRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { cohortDate, weeks = 12 } = request.data;

      logInfo(`Fetching retention rates for cohort ${cohortDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(cohortDate));
      const cohortUsersSnapshot = await db
        .collection('users')
        .where('createdAt', '>=', start)
        .get();

      const cohortSize = cohortUsersSnapshot.size;
      const retentionByWeek: Record<number, number> = {};

      for (let week = 0; week < weeks; week++) {
        const weekStart = new Date(new Date(cohortDate).getTime() + week * 7 * 24 * 60 * 60 * 1000);
        const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);

        const activeUsersSnapshot = await db
          .collection('users')
          .where('createdAt', '>=', start)
          .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(weekStart))
          .where('lastActiveAt', '<', admin.firestore.Timestamp.fromDate(weekEnd))
          .get();

        retentionByWeek[week] = (activeUsersSnapshot.size / cohortSize * 100);
      }

      return {
        success: true,
        cohortSize,
        retentionByWeek,
      };
    } catch (error) {
      logError('Error fetching retention rates:', error);
      throw handleError(error);
    }
  }
);

// ========== CHURN PREDICTION ==========

// 7. Predict Churn
export const predictChurn = onCall<PredictChurnRequest>(
  {
    memory: '1GiB',
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, batchSize = 100 } = request.data;

      logInfo(`Predicting churn for ${userId ? 'user ' + userId : batchSize + ' users'}`);

      // Simple churn prediction based on activity patterns
      let usersToAnalyze: any[] = [];

      if (userId) {
        const userDoc = await db.collection('users').doc(userId).get();
        if (userDoc.exists) usersToAnalyze = [userDoc];
      } else {
        const snapshot = await db.collection('users').limit(batchSize).get();
        usersToAnalyze = snapshot.docs;
      }

      const predictions: Array<{ userId: string; churnRisk: number; factors: string[] }> = [];

      for (const userDoc of usersToAnalyze) {
        const userData = userDoc.data();
        let churnScore = 0;
        const factors: string[] = [];

        // Factor 1: Inactivity (0-40 points)
        const daysSinceActive = userData.lastActiveAt
          ? (Date.now() - userData.lastActiveAt.toMillis()) / (24 * 60 * 60 * 1000)
          : 999;

        if (daysSinceActive > 30) {
          churnScore += 40;
          factors.push('inactive_30_days');
        } else if (daysSinceActive > 14) {
          churnScore += 25;
          factors.push('inactive_14_days');
        } else if (daysSinceActive > 7) {
          churnScore += 10;
          factors.push('inactive_7_days');
        }

        // Factor 2: Low engagement (0-30 points)
        const avgMessagesPerDay = (userData.stats?.totalMessages || 0) / Math.max(daysSinceActive, 1);
        if (avgMessagesPerDay < 1) {
          churnScore += 30;
          factors.push('low_message_activity');
        }

        // Factor 3: No matches recently (0-20 points)
        const recentMatches = userData.stats?.matchesLast30Days || 0;
        if (recentMatches === 0) {
          churnScore += 20;
          factors.push('no_recent_matches');
        }

        // Factor 4: Subscription cancelled (0-10 points)
        if (userData.subscriptionCancelled) {
          churnScore += 10;
          factors.push('subscription_cancelled');
        }

        predictions.push({
          userId: userDoc.id,
          churnRisk: Math.min(churnScore, 100),
          factors,
        });
      }

      return {
        success: true,
        predictions,
      };
    } catch (error) {
      logError('Error predicting churn:', error);
      throw handleError(error);
    }
  }
);

// 8. Get Churn Risk Segment
export const getChurnRiskSegment = onCall<GetChurnRiskSegmentRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { threshold = 50, limit = 100 } = request.data;

      logInfo(`Fetching users with churn risk >= ${threshold}`);

      // Get users who haven't been active recently
      const fourteenDaysAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14 * 24 * 60 * 60 * 1000));

      const snapshot = await db
        .collection('users')
        .where('lastActiveAt', '<', fourteenDaysAgo)
        .limit(limit)
        .get();

      const churnRiskUsers = snapshot.docs.map(doc => ({
        userId: doc.id,
        displayName: doc.data().displayName,
        lastActiveAt: doc.data().lastActiveAt?.toDate().toISOString(),
        subscriptionTier: doc.data().subscriptionTier,
      }));

      return {
        success: true,
        churnRiskUsers,
        count: churnRiskUsers.length,
      };
    } catch (error) {
      logError('Error fetching churn risk segment:', error);
      throw handleError(error);
    }
  }
);

// 9. Schedule Churn Prediction Job
export const scheduledChurnPrediction = onSchedule(
  {
    schedule: '0 2 * * *', // Daily at 2 AM UTC
    timeZone: 'UTC',
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Running scheduled churn prediction');

    try {
      // Get all active users
      const usersSnapshot = await db.collection('users').where('accountStatus', '==', 'active').get();

      const predictions: any[] = [];

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        let churnScore = 0;

        const daysSinceActive = userData.lastActiveAt
          ? (Date.now() - userData.lastActiveAt.toMillis()) / (24 * 60 * 60 * 1000)
          : 999;

        if (daysSinceActive > 30) churnScore += 40;
        else if (daysSinceActive > 14) churnScore += 25;
        else if (daysSinceActive > 7) churnScore += 10;

        if (churnScore >= 25) {
          predictions.push({
            userId: userDoc.id,
            churnRisk: churnScore,
            timestamp: FieldValue.serverTimestamp(),
          });
        }
      }

      // Save predictions
      const batch = db.batch();
      predictions.forEach(prediction => {
        const ref = db.collection('churn_predictions').doc();
        batch.set(ref, prediction);
      });

      await batch.commit();

      logInfo(`Churn prediction completed: ${predictions.length} high-risk users identified`);
    } catch (error) {
      logError('Error in scheduled churn prediction:', error);
    }
  }
);

// ========== A/B TESTING ==========

// 10. Create A/B Test
export const createABTest = onCall<CreateABTestRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { name, description, variants, startDate, endDate } = request.data;

      logInfo(`Creating A/B test: ${name}`);

      const testRef = await db.collection('ab_tests').add({
        name,
        description,
        variants,
        startDate: admin.firestore.Timestamp.fromDate(new Date(startDate)),
        endDate: admin.firestore.Timestamp.fromDate(new Date(endDate)),
        status: 'active',
        createdBy: request.auth?.uid,
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        testId: testRef.id,
      };
    } catch (error) {
      logError('Error creating A/B test:', error);
      throw handleError(error);
    }
  }
);

// 11. Assign A/B Test Variant
export const assignABTestVariant = onCall<AssignABTestVariantRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { testId } = request.data;

      logInfo(`Assigning A/B test variant for user ${uid}, test ${testId}`);

      // Check if user already has a variant
      const existingAssignment = await db
        .collection('ab_test_assignments')
        .where('userId', '==', uid)
        .where('testId', '==', testId)
        .limit(1)
        .get();

      if (!existingAssignment.empty) {
        const variant = existingAssignment.docs[0].data().variant;
        return { success: true, variant };
      }

      // Get test details
      const testDoc = await db.collection('ab_tests').doc(testId).get();
      if (!testDoc.exists) {
        throw new Error('Test not found');
      }

      const testData = testDoc.data()!;
      const variants = testData.variants;

      // Assign random variant based on weights
      const totalWeight = variants.reduce((sum: number, v: any) => sum + v.weight, 0);
      let random = Math.random() * totalWeight;

      let assignedVariant = variants[0].name;
      for (const variant of variants) {
        random -= variant.weight;
        if (random <= 0) {
          assignedVariant = variant.name;
          break;
        }
      }

      // Save assignment
      await db.collection('ab_test_assignments').add({
        userId: uid,
        testId,
        variant: assignedVariant,
        assignedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        variant: assignedVariant,
      };
    } catch (error) {
      logError('Error assigning A/B test variant:', error);
      throw handleError(error);
    }
  }
);

// 12. Get A/B Test Results
export const getABTestResults = onCall<GetABTestResultsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { testId } = request.data;

      logInfo(`Fetching A/B test results for ${testId}`);

      const assignmentsSnapshot = await db
        .collection('ab_test_assignments')
        .where('testId', '==', testId)
        .get();

      const variantCounts: Record<string, number> = {};
      assignmentsSnapshot.docs.forEach(doc => {
        const variant = doc.data().variant;
        variantCounts[variant] = (variantCounts[variant] || 0) + 1;
      });

      return {
        success: true,
        results: {
          totalAssignments: assignmentsSnapshot.size,
          variantCounts,
        },
      };
    } catch (error) {
      logError('Error fetching A/B test results:', error);
      throw handleError(error);
    }
  }
);

// 13. End A/B Test
export const endABTest = onCall<{ testId: string }>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { testId } = request.data;

      logInfo(`Ending A/B test ${testId}`);

      await db.collection('ab_tests').doc(testId).update({
        status: 'ended',
        endedAt: FieldValue.serverTimestamp(),
        endedBy: request.auth?.uid,
      });

      return { success: true };
    } catch (error) {
      logError('Error ending A/B test:', error);
      throw handleError(error);
    }
  }
);

// ========== METRICS ==========

// 14. Get User Metrics
export const getUserMetrics = onCall<GetUserMetricsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = request.data.userId || (await verifyAuth(request.auth));

      logInfo(`Fetching metrics for user ${uid}`);

      const userDoc = await db.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const userData = userDoc.data()!;

      return {
        success: true,
        metrics: {
          totalMatches: userData.stats?.totalMatches || 0,
          totalMessages: userData.stats?.totalMessages || 0,
          totalCalls: userData.stats?.totalCalls || 0,
          profileViews: userData.stats?.profileViews || 0,
          likes: userData.stats?.likes || 0,
          superLikes: userData.stats?.superLikes || 0,
        },
      };
    } catch (error) {
      logError('Error fetching user metrics:', error);
      throw handleError(error);
    }
  }
);

// 15. Get Engagement Metrics
export const getEngagementMetrics = onCall<GetEngagementMetricsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching engagement metrics from ${startDate} to ${endDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const [matchesSnapshot, messagesSnapshot, callsSnapshot] = await Promise.all([
        db.collection('matches').where('createdAt', '>=', start).where('createdAt', '<=', end).get(),
        db.collection('messages').where('createdAt', '>=', start).where('createdAt', '<=', end).get(),
        db.collection('calls').where('createdAt', '>=', start).where('createdAt', '<=', end).get(),
      ]);

      return {
        success: true,
        metrics: {
          totalMatches: matchesSnapshot.size,
          totalMessages: messagesSnapshot.size,
          totalCalls: callsSnapshot.size,
        },
      };
    } catch (error) {
      logError('Error fetching engagement metrics:', error);
      throw handleError(error);
    }
  }
);

// 16. Get Conversion Metrics
export const getConversionMetrics = onCall<GetConversionMetricsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching conversion metrics from ${startDate} to ${endDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const usersSnapshot = await db
        .collection('users')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      const totalSignups = usersSnapshot.size;
      let convertedToSubscriber = 0;

      usersSnapshot.docs.forEach(doc => {
        if (doc.data().subscriptionTier !== 'basic') {
          convertedToSubscriber++;
        }
      });

      return {
        success: true,
        metrics: {
          totalSignups,
          convertedToSubscriber,
          conversionRate: ((convertedToSubscriber / totalSignups) * 100).toFixed(2) + '%',
        },
      };
    } catch (error) {
      logError('Error fetching conversion metrics:', error);
      throw handleError(error);
    }
  }
);

// 17. Get Match Quality Metrics
export const getMatchQualityMetrics = onCall<GetMatchQualityMetricsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching match quality metrics from ${startDate} to ${endDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const matchesSnapshot = await db
        .collection('matches')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      let matchesWithMessages = 0;
      let matchesWithCalls = 0;

      for (const matchDoc of matchesSnapshot.docs) {
        const conversationId = matchDoc.data().conversationId;
        if (conversationId) {
          const messagesSnapshot = await db.collection('messages').where('conversationId', '==', conversationId).limit(1).get();
          if (!messagesSnapshot.empty) matchesWithMessages++;

          const callsSnapshot = await db.collection('calls').where('conversationId', '==', conversationId).limit(1).get();
          if (!callsSnapshot.empty) matchesWithCalls++;
        }
      }

      return {
        success: true,
        metrics: {
          totalMatches: matchesSnapshot.size,
          matchesWithMessages,
          matchesWithCalls,
          messageRate: ((matchesWithMessages / matchesSnapshot.size) * 100).toFixed(2) + '%',
          callRate: ((matchesWithCalls / matchesSnapshot.size) * 100).toFixed(2) + '%',
        },
      };
    } catch (error) {
      logError('Error fetching match quality metrics:', error);
      throw handleError(error);
    }
  }
);

// ========== SEGMENTATION ==========

// 18. Create User Segment
export const createUserSegment = onCall<CreateUserSegmentRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { name, description, criteria } = request.data;

      logInfo(`Creating user segment: ${name}`);

      const segmentRef = await db.collection('user_segments').add({
        name,
        description,
        criteria,
        createdBy: request.auth?.uid,
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        segmentId: segmentRef.id,
      };
    } catch (error) {
      logError('Error creating user segment:', error);
      throw handleError(error);
    }
  }
);

// 19. Get User Segments
export const getUserSegments = onCall<GetUserSegmentsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { limit = 50 } = request.data;

      logInfo('Fetching user segments');

      const snapshot = await db.collection('user_segments').limit(limit).get();

      const segments = snapshot.docs.map(doc => ({
        segmentId: doc.id,
        ...doc.data(),
      }));

      return {
        success: true,
        segments,
      };
    } catch (error) {
      logError('Error fetching user segments:', error);
      throw handleError(error);
    }
  }
);

// 20. Get Users in Segment
export const getUsersInSegment = onCall<GetUsersInSegmentRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 120,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { segmentId, limit = 100 } = request.data;

      logInfo(`Fetching users in segment ${segmentId}`);

      const segmentDoc = await db.collection('user_segments').doc(segmentId).get();

      if (!segmentDoc.exists) {
        throw new Error('Segment not found');
      }

      const criteria = segmentDoc.data()!.criteria;

      // Build query based on criteria
      let query: any = db.collection('users');

      if (criteria.subscriptionTier) {
        query = query.where('subscriptionTier', '==', criteria.subscriptionTier);
      }

      if (criteria.minMatches) {
        query = query.where('stats.totalMatches', '>=', criteria.minMatches);
      }

      query = query.limit(limit);

      const snapshot = await query.get();

      const users = snapshot.docs.map(doc => ({
        userId: doc.id,
        displayName: doc.data().displayName,
        email: doc.data().email,
        subscriptionTier: doc.data().subscriptionTier,
      }));

      return {
        success: true,
        users,
        count: users.length,
      };
    } catch (error) {
      logError('Error fetching users in segment:', error);
      throw handleError(error);
    }
  }
);

// 21. Update Segment Criteria
export const updateSegmentCriteria = onCall<UpdateSegmentCriteriaRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { segmentId, criteria } = request.data;

      logInfo(`Updating criteria for segment ${segmentId}`);

      await db.collection('user_segments').doc(segmentId).update({
        criteria,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth?.uid,
      });

      return { success: true };
    } catch (error) {
      logError('Error updating segment criteria:', error);
      throw handleError(error);
    }
  }
);

// 22. Delete User Segment
export const deleteUserSegment = onCall<{ segmentId: string }>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { segmentId } = request.data;

      logInfo(`Deleting segment ${segmentId}`);

      await db.collection('user_segments').doc(segmentId).delete();

      return { success: true };
    } catch (error) {
      logError('Error deleting segment:', error);
      throw handleError(error);
    }
  }
);
