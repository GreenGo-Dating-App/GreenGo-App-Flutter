"use strict";
/**
 * Analytics Service
 * 20+ Cloud Functions for analytics, metrics, and business intelligence
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
exports.deleteUserSegment = exports.updateSegmentCriteria = exports.getUsersInSegment = exports.getUserSegments = exports.createUserSegment = exports.getMatchQualityMetrics = exports.getConversionMetrics = exports.getEngagementMetrics = exports.getUserMetrics = exports.endABTest = exports.getABTestResults = exports.assignABTestVariant = exports.createABTest = exports.scheduledChurnPrediction = exports.getChurnRiskSegment = exports.predictChurn = exports.getRetentionRates = exports.getCohortAnalysis = exports.getMRRTrends = exports.getRevenueDashboard = exports.autoTrackUserEvent = exports.trackEvent = void 0;
const https_1 = require("firebase-functions/v2/https");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const firestore_1 = require("firebase-functions/v2/firestore");
const utils_1 = require("../shared/utils");
const bigquery_1 = require("@google-cloud/bigquery");
const admin = __importStar(require("firebase-admin"));
const bigquery = new bigquery_1.BigQuery();
const DATASET_ID = 'greengo_analytics';
// ========== EVENT TRACKING ==========
// 1. Track Custom Event
exports.trackEvent = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { eventName, eventData } = request.data;
        (0, utils_1.logInfo)(`Tracking event: ${eventName} for user ${uid}`);
        // Store in Firestore
        await utils_1.db.collection('analytics_events').add({
            userId: uid,
            eventName,
            eventData: eventData || {},
            timestamp: utils_1.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
        (0, utils_1.logError)('Error tracking event:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 2. Auto-track User Events (Firestore Trigger)
exports.autoTrackUserEvent = (0, firestore_1.onDocumentCreated)({
    document: 'users/{userId}',
    memory: '256MiB',
}, async (event) => {
    var _a;
    try {
        const userId = event.params.userId;
        const userData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!userData)
            return;
        (0, utils_1.logInfo)(`Auto-tracking user signup for ${userId}`);
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
    }
    catch (error) {
        (0, utils_1.logError)('Error auto-tracking user event:', error);
    }
});
// ========== REVENUE ANALYTICS ==========
// 3. Get Revenue Dashboard
exports.getRevenueDashboard = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching revenue dashboard from ${startDate} to ${endDate}`);
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
        const totalSubscriptionRevenue = rows.reduce((sum, row) => sum + (row.subscription_revenue || 0), 0);
        const totalCoinRevenue = rows.reduce((sum, row) => sum + (row.coin_revenue || 0), 0);
        return {
            success: true,
            dashboard: {
                totalRevenue: (totalSubscriptionRevenue + totalCoinRevenue).toFixed(2),
                subscriptionRevenue: totalSubscriptionRevenue.toFixed(2),
                coinRevenue: totalCoinRevenue.toFixed(2),
                dailyBreakdown: rows,
            },
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching revenue dashboard:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 4. Get MRR Trends
exports.getMRRTrends = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching MRR trends from ${startDate} to ${endDate}`);
        // Get subscription data from Firestore
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        const subscriptionsSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('createdAt', '>=', start)
            .where('createdAt', '<=', end)
            .get();
        const mrrByMonth = {};
        subscriptionsSnapshot.docs.forEach(doc => {
            const data = doc.data();
            const month = data.createdAt.toDate().toISOString().substring(0, 7); // YYYY-MM
            if (!mrrByMonth[month]) {
                mrrByMonth[month] = { mrr: 0, subscribers: 0 };
            }
            if (data.tier === 'silver')
                mrrByMonth[month].mrr += 9.99;
            if (data.tier === 'gold')
                mrrByMonth[month].mrr += 19.99;
            mrrByMonth[month].subscribers++;
        });
        return {
            success: true,
            trends: mrrByMonth,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching MRR trends:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== COHORT ANALYSIS ==========
// 5. Get Cohort Analysis
exports.getCohortAnalysis = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 120,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { cohortType, startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching ${cohortType} cohort analysis from ${startDate} to ${endDate}`);
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching cohort analysis:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 6. Get Retention Rates
exports.getRetentionRates = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { cohortDate, weeks = 12 } = request.data;
        (0, utils_1.logInfo)(`Fetching retention rates for cohort ${cohortDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(cohortDate));
        const cohortUsersSnapshot = await utils_1.db
            .collection('users')
            .where('createdAt', '>=', start)
            .get();
        const cohortSize = cohortUsersSnapshot.size;
        const retentionByWeek = {};
        for (let week = 0; week < weeks; week++) {
            const weekStart = new Date(new Date(cohortDate).getTime() + week * 7 * 24 * 60 * 60 * 1000);
            const weekEnd = new Date(weekStart.getTime() + 7 * 24 * 60 * 60 * 1000);
            const activeUsersSnapshot = await utils_1.db
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching retention rates:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== CHURN PREDICTION ==========
// 7. Predict Churn
exports.predictChurn = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 120,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, batchSize = 100 } = request.data;
        (0, utils_1.logInfo)(`Predicting churn for ${userId ? 'user ' + userId : batchSize + ' users'}`);
        // Simple churn prediction based on activity patterns
        let usersToAnalyze = [];
        if (userId) {
            const userDoc = await utils_1.db.collection('users').doc(userId).get();
            if (userDoc.exists)
                usersToAnalyze = [userDoc];
        }
        else {
            const snapshot = await utils_1.db.collection('users').limit(batchSize).get();
            usersToAnalyze = snapshot.docs;
        }
        const predictions = [];
        for (const userDoc of usersToAnalyze) {
            const userData = userDoc.data();
            let churnScore = 0;
            const factors = [];
            // Factor 1: Inactivity (0-40 points)
            const daysSinceActive = userData.lastActiveAt
                ? (Date.now() - userData.lastActiveAt.toMillis()) / (24 * 60 * 60 * 1000)
                : 999;
            if (daysSinceActive > 30) {
                churnScore += 40;
                factors.push('inactive_30_days');
            }
            else if (daysSinceActive > 14) {
                churnScore += 25;
                factors.push('inactive_14_days');
            }
            else if (daysSinceActive > 7) {
                churnScore += 10;
                factors.push('inactive_7_days');
            }
            // Factor 2: Low engagement (0-30 points)
            const avgMessagesPerDay = (((_a = userData.stats) === null || _a === void 0 ? void 0 : _a.totalMessages) || 0) / Math.max(daysSinceActive, 1);
            if (avgMessagesPerDay < 1) {
                churnScore += 30;
                factors.push('low_message_activity');
            }
            // Factor 3: No matches recently (0-20 points)
            const recentMatches = ((_b = userData.stats) === null || _b === void 0 ? void 0 : _b.matchesLast30Days) || 0;
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
    }
    catch (error) {
        (0, utils_1.logError)('Error predicting churn:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 8. Get Churn Risk Segment
exports.getChurnRiskSegment = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { threshold = 50, limit = 100 } = request.data;
        (0, utils_1.logInfo)(`Fetching users with churn risk >= ${threshold}`);
        // Get users who haven't been active recently
        const fourteenDaysAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14 * 24 * 60 * 60 * 1000));
        const snapshot = await utils_1.db
            .collection('users')
            .where('lastActiveAt', '<', fourteenDaysAgo)
            .limit(limit)
            .get();
        const churnRiskUsers = snapshot.docs.map(doc => {
            var _a;
            return ({
                userId: doc.id,
                displayName: doc.data().displayName,
                lastActiveAt: (_a = doc.data().lastActiveAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(),
                subscriptionTier: doc.data().subscriptionTier,
            });
        });
        return {
            success: true,
            churnRiskUsers,
            count: churnRiskUsers.length,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching churn risk segment:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 9. Schedule Churn Prediction Job
exports.scheduledChurnPrediction = (0, scheduler_1.onSchedule)({
    schedule: '0 2 * * *', // Daily at 2 AM UTC
    timeZone: 'UTC',
    memory: '1GiB',
    timeoutSeconds: 540,
}, async () => {
    (0, utils_1.logInfo)('Running scheduled churn prediction');
    try {
        // Get all active users
        const usersSnapshot = await utils_1.db.collection('users').where('accountStatus', '==', 'active').get();
        const predictions = [];
        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            let churnScore = 0;
            const daysSinceActive = userData.lastActiveAt
                ? (Date.now() - userData.lastActiveAt.toMillis()) / (24 * 60 * 60 * 1000)
                : 999;
            if (daysSinceActive > 30)
                churnScore += 40;
            else if (daysSinceActive > 14)
                churnScore += 25;
            else if (daysSinceActive > 7)
                churnScore += 10;
            if (churnScore >= 25) {
                predictions.push({
                    userId: userDoc.id,
                    churnRisk: churnScore,
                    timestamp: utils_1.FieldValue.serverTimestamp(),
                });
            }
        }
        // Save predictions
        const batch = utils_1.db.batch();
        predictions.forEach(prediction => {
            const ref = utils_1.db.collection('churn_predictions').doc();
            batch.set(ref, prediction);
        });
        await batch.commit();
        (0, utils_1.logInfo)(`Churn prediction completed: ${predictions.length} high-risk users identified`);
    }
    catch (error) {
        (0, utils_1.logError)('Error in scheduled churn prediction:', error);
    }
});
// ========== A/B TESTING ==========
// 10. Create A/B Test
exports.createABTest = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { name, description, variants, startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Creating A/B test: ${name}`);
        const testRef = await utils_1.db.collection('ab_tests').add({
            name,
            description,
            variants,
            startDate: admin.firestore.Timestamp.fromDate(new Date(startDate)),
            endDate: admin.firestore.Timestamp.fromDate(new Date(endDate)),
            status: 'active',
            createdBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            testId: testRef.id,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error creating A/B test:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 11. Assign A/B Test Variant
exports.assignABTestVariant = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { testId } = request.data;
        (0, utils_1.logInfo)(`Assigning A/B test variant for user ${uid}, test ${testId}`);
        // Check if user already has a variant
        const existingAssignment = await utils_1.db
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
        const testDoc = await utils_1.db.collection('ab_tests').doc(testId).get();
        if (!testDoc.exists) {
            throw new Error('Test not found');
        }
        const testData = testDoc.data();
        const variants = testData.variants;
        // Assign random variant based on weights
        const totalWeight = variants.reduce((sum, v) => sum + v.weight, 0);
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
        await utils_1.db.collection('ab_test_assignments').add({
            userId: uid,
            testId,
            variant: assignedVariant,
            assignedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            variant: assignedVariant,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error assigning A/B test variant:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 12. Get A/B Test Results
exports.getABTestResults = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { testId } = request.data;
        (0, utils_1.logInfo)(`Fetching A/B test results for ${testId}`);
        const assignmentsSnapshot = await utils_1.db
            .collection('ab_test_assignments')
            .where('testId', '==', testId)
            .get();
        const variantCounts = {};
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching A/B test results:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 13. End A/B Test
exports.endABTest = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { testId } = request.data;
        (0, utils_1.logInfo)(`Ending A/B test ${testId}`);
        await utils_1.db.collection('ab_tests').doc(testId).update({
            status: 'ended',
            endedAt: utils_1.FieldValue.serverTimestamp(),
            endedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error ending A/B test:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== METRICS ==========
// 14. Get User Metrics
exports.getUserMetrics = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b, _c, _d, _e, _f;
    try {
        const uid = request.data.userId || (await (0, utils_1.verifyAuth)(request.auth));
        (0, utils_1.logInfo)(`Fetching metrics for user ${uid}`);
        const userDoc = await utils_1.db.collection('users').doc(uid).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        const userData = userDoc.data();
        return {
            success: true,
            metrics: {
                totalMatches: ((_a = userData.stats) === null || _a === void 0 ? void 0 : _a.totalMatches) || 0,
                totalMessages: ((_b = userData.stats) === null || _b === void 0 ? void 0 : _b.totalMessages) || 0,
                totalCalls: ((_c = userData.stats) === null || _c === void 0 ? void 0 : _c.totalCalls) || 0,
                profileViews: ((_d = userData.stats) === null || _d === void 0 ? void 0 : _d.profileViews) || 0,
                likes: ((_e = userData.stats) === null || _e === void 0 ? void 0 : _e.likes) || 0,
                superLikes: ((_f = userData.stats) === null || _f === void 0 ? void 0 : _f.superLikes) || 0,
            },
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching user metrics:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 15. Get Engagement Metrics
exports.getEngagementMetrics = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching engagement metrics from ${startDate} to ${endDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        const [matchesSnapshot, messagesSnapshot, callsSnapshot] = await Promise.all([
            utils_1.db.collection('matches').where('createdAt', '>=', start).where('createdAt', '<=', end).get(),
            utils_1.db.collection('messages').where('createdAt', '>=', start).where('createdAt', '<=', end).get(),
            utils_1.db.collection('calls').where('createdAt', '>=', start).where('createdAt', '<=', end).get(),
        ]);
        return {
            success: true,
            metrics: {
                totalMatches: matchesSnapshot.size,
                totalMessages: messagesSnapshot.size,
                totalCalls: callsSnapshot.size,
            },
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching engagement metrics:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 16. Get Conversion Metrics
exports.getConversionMetrics = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching conversion metrics from ${startDate} to ${endDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        const usersSnapshot = await utils_1.db
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching conversion metrics:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 17. Get Match Quality Metrics
exports.getMatchQualityMetrics = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching match quality metrics from ${startDate} to ${endDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        const matchesSnapshot = await utils_1.db
            .collection('matches')
            .where('createdAt', '>=', start)
            .where('createdAt', '<=', end)
            .get();
        let matchesWithMessages = 0;
        let matchesWithCalls = 0;
        for (const matchDoc of matchesSnapshot.docs) {
            const conversationId = matchDoc.data().conversationId;
            if (conversationId) {
                const messagesSnapshot = await utils_1.db.collection('messages').where('conversationId', '==', conversationId).limit(1).get();
                if (!messagesSnapshot.empty)
                    matchesWithMessages++;
                const callsSnapshot = await utils_1.db.collection('calls').where('conversationId', '==', conversationId).limit(1).get();
                if (!callsSnapshot.empty)
                    matchesWithCalls++;
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching match quality metrics:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== SEGMENTATION ==========
// 18. Create User Segment
exports.createUserSegment = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { name, description, criteria } = request.data;
        (0, utils_1.logInfo)(`Creating user segment: ${name}`);
        const segmentRef = await utils_1.db.collection('user_segments').add({
            name,
            description,
            criteria,
            createdBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            segmentId: segmentRef.id,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error creating user segment:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 19. Get User Segments
exports.getUserSegments = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { limit = 50 } = request.data;
        (0, utils_1.logInfo)('Fetching user segments');
        const snapshot = await utils_1.db.collection('user_segments').limit(limit).get();
        const segments = snapshot.docs.map(doc => (Object.assign({ segmentId: doc.id }, doc.data())));
        return {
            success: true,
            segments,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching user segments:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 20. Get Users in Segment
exports.getUsersInSegment = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 120,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { segmentId, limit = 100 } = request.data;
        (0, utils_1.logInfo)(`Fetching users in segment ${segmentId}`);
        const segmentDoc = await utils_1.db.collection('user_segments').doc(segmentId).get();
        if (!segmentDoc.exists) {
            throw new Error('Segment not found');
        }
        const criteria = segmentDoc.data().criteria;
        // Build query based on criteria
        let query = utils_1.db.collection('users');
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching users in segment:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 21. Update Segment Criteria
exports.updateSegmentCriteria = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { segmentId, criteria } = request.data;
        (0, utils_1.logInfo)(`Updating criteria for segment ${segmentId}`);
        await utils_1.db.collection('user_segments').doc(segmentId).update({
            criteria,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
            updatedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error updating segment criteria:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 22. Delete User Segment
exports.deleteUserSegment = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { segmentId } = request.data;
        (0, utils_1.logInfo)(`Deleting segment ${segmentId}`);
        await utils_1.db.collection('user_segments').doc(segmentId).delete();
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error deleting segment:', error);
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map