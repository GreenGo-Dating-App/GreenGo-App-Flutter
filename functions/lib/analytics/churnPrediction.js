"use strict";
/**
 * Churn Prediction ML Model
 * Point 169: Subscription churn prediction using ML to identify at-risk users
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
exports.getAtRiskUsers = exports.getUserChurnPrediction = exports.predictChurnDaily = exports.trainChurnModel = void 0;
const functions = __importStar(require("firebase-functions"));
const bigQuerySetup_1 = require("./bigQuerySetup");
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
/**
 * Train Churn Prediction Model
 * Uses BigQuery ML to train a logistic regression model
 */
exports.trainChurnModel = functions.pubsub
    .schedule('0 2 * * 0') // Weekly on Sunday at 2 AM
    .timeZone('UTC')
    .onRun(async (context) => {
    try {
        // Create training dataset
        const createTrainingDataQuery = `
        CREATE OR REPLACE TABLE \`${bigQuerySetup_1.DATASET_ID}.churn_training_data\` AS
        WITH user_features AS (
          SELECT
            uc.user_id,
            uc.is_churned as label,

            -- Engagement features
            COALESCE(e.days_since_last_login, 999) as days_since_last_login,
            COALESCE(e.messages_sent_30d, 0) as messages_sent_30d,
            COALESCE(e.matches_created_30d, 0) as matches_created_30d,
            COALESCE(e.app_opens_30d, 0) as app_opens_30d,
            COALESCE(e.feature_usage_score, 0) as feature_usage_score,

            -- Subscription features
            uc.subscription_months,
            CASE
              WHEN uc.first_subscription_tier = 'gold' THEN 3
              WHEN uc.first_subscription_tier = 'silver' THEN 2
              ELSE 1
            END as initial_tier_value,

            -- Behavioral features
            COALESCE(b.tier_downgrades, 0) as tier_downgrades,
            COALESCE(b.support_tickets, 0) as support_tickets,
            COALESCE(b.payment_failures, 0) as payment_failures,
            COALESCE(b.cancellation_attempts, 0) as cancellation_attempts,

            -- Revenue features
            uc.lifetime_value,
            SAFE_DIVIDE(uc.total_revenue, NULLIF(uc.subscription_months, 0)) as avg_monthly_spend

          FROM \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\` uc
          LEFT JOIN (
            -- Engagement metrics (mock - replace with actual engagement table)
            SELECT
              user_id,
              CAST(RAND() * 30 AS INT64) as days_since_last_login,
              CAST(RAND() * 100 AS INT64) as messages_sent_30d,
              CAST(RAND() * 20 AS INT64) as matches_created_30d,
              CAST(RAND() * 50 AS INT64) as app_opens_30d,
              RAND() as feature_usage_score
            FROM \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\`
          ) e ON uc.user_id = e.user_id
          LEFT JOIN (
            -- Behavioral metrics
            SELECT
              user_id,
              COUNTIF(event_type = 'downgraded') as tier_downgrades,
              0 as support_tickets, -- Mock data
              0 as payment_failures, -- Mock data
              0 as cancellation_attempts -- Mock data
            FROM \`${bigQuerySetup_1.DATASET_ID}.subscription_events\`
            GROUP BY user_id
          ) b ON uc.user_id = b.user_id

          WHERE uc.cohort_month >= FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH))
            AND uc.first_subscription_tier IS NOT NULL
        )
        SELECT * FROM user_features
      `;
        await bigQuerySetup_1.bigquery.query(createTrainingDataQuery);
        console.log('Training data created');
        // Train the model using BigQuery ML
        const trainModelQuery = `
        CREATE OR REPLACE MODEL \`${bigQuerySetup_1.DATASET_ID}.churn_prediction_model\`
        OPTIONS(
          model_type='LOGISTIC_REG',
          input_label_cols=['label'],
          max_iterations=50,
          l1_reg=0.1,
          l2_reg=0.1,
          early_stop=TRUE,
          min_rel_progress=0.01
        ) AS
        SELECT
          label,
          days_since_last_login,
          messages_sent_30d,
          matches_created_30d,
          app_opens_30d,
          feature_usage_score,
          subscription_months,
          initial_tier_value,
          tier_downgrades,
          support_tickets,
          payment_failures,
          cancellation_attempts,
          lifetime_value,
          avg_monthly_spend
        FROM \`${bigQuerySetup_1.DATASET_ID}.churn_training_data\`
      `;
        await bigQuerySetup_1.bigquery.query(trainModelQuery);
        console.log('Churn model trained');
        // Evaluate the model
        const evaluateQuery = `
        SELECT
          roc_auc,
          accuracy,
          precision,
          recall,
          f1_score
        FROM ML.EVALUATE(
          MODEL \`${bigQuerySetup_1.DATASET_ID}.churn_prediction_model\`,
          (SELECT * FROM \`${bigQuerySetup_1.DATASET_ID}.churn_training_data\`)
        )
      `;
        const [evaluationResults] = await bigQuerySetup_1.bigquery.query(evaluateQuery);
        const metrics = evaluationResults[0];
        console.log('Model Evaluation:', {
            accuracy: metrics.accuracy,
            precision: metrics.precision,
            recall: metrics.recall,
            f1_score: metrics.f1_score,
            roc_auc: metrics.roc_auc,
        });
        // Store model metadata
        await firestore.collection('ml_models').doc('churn_prediction').set({
            modelName: 'churn_prediction_model',
            trainedAt: admin.firestore.FieldValue.serverTimestamp(),
            accuracy: metrics.accuracy,
            precision: metrics.precision,
            recall: metrics.recall,
            f1Score: metrics.f1_score,
            rocAuc: metrics.roc_auc,
            version: 1,
        });
        return {
            success: true,
            metrics,
        };
    }
    catch (error) {
        console.error('Error training churn model:', error);
        throw error;
    }
});
/**
 * Predict Churn for Users
 * Runs daily to score all active subscribers
 */
exports.predictChurnDaily = functions.pubsub
    .schedule('0 3 * * *') // Daily at 3 AM
    .timeZone('UTC')
    .onRun(async (context) => {
    try {
        // Get predictions for all active users
        const predictQuery = `
        WITH current_features AS (
          SELECT
            uc.user_id,
            COALESCE(e.days_since_last_login, 999) as days_since_last_login,
            COALESCE(e.messages_sent_30d, 0) as messages_sent_30d,
            COALESCE(e.matches_created_30d, 0) as matches_created_30d,
            COALESCE(e.app_opens_30d, 0) as app_opens_30d,
            COALESCE(e.feature_usage_score, 0) as feature_usage_score,
            uc.subscription_months,
            CASE
              WHEN uc.first_subscription_tier = 'gold' THEN 3
              WHEN uc.first_subscription_tier = 'silver' THEN 2
              ELSE 1
            END as initial_tier_value,
            COALESCE(b.tier_downgrades, 0) as tier_downgrades,
            COALESCE(b.support_tickets, 0) as support_tickets,
            COALESCE(b.payment_failures, 0) as payment_failures,
            COALESCE(b.cancellation_attempts, 0) as cancellation_attempts,
            uc.lifetime_value,
            SAFE_DIVIDE(uc.total_revenue, NULLIF(uc.subscription_months, 0)) as avg_monthly_spend
          FROM \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\` uc
          LEFT JOIN (
            SELECT
              user_id,
              CAST(RAND() * 30 AS INT64) as days_since_last_login,
              CAST(RAND() * 100 AS INT64) as messages_sent_30d,
              CAST(RAND() * 20 AS INT64) as matches_created_30d,
              CAST(RAND() * 50 AS INT64) as app_opens_30d,
              RAND() as feature_usage_score
            FROM \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\`
          ) e ON uc.user_id = e.user_id
          LEFT JOIN (
            SELECT
              user_id,
              COUNTIF(event_type = 'downgraded') as tier_downgrades,
              0 as support_tickets,
              0 as payment_failures,
              0 as cancellation_attempts
            FROM \`${bigQuerySetup_1.DATASET_ID}.subscription_events\`
            GROUP BY user_id
          ) b ON uc.user_id = b.user_id
          WHERE uc.is_churned = false
            AND uc.first_subscription_tier IS NOT NULL
        )
        SELECT
          user_id,
          predicted_label,
          predicted_label_probs[OFFSET(1)].prob as churn_probability
        FROM ML.PREDICT(
          MODEL \`${bigQuerySetup_1.DATASET_ID}.churn_prediction_model\`,
          TABLE current_features
        )
        WHERE predicted_label_probs[OFFSET(1)].prob >= 0.3
        ORDER BY churn_probability DESC
      `;
        const [predictions] = await bigQuerySetup_1.bigquery.query(predictQuery);
        // Update user cohorts with churn scores
        const batch = firestore.batch();
        let batchCount = 0;
        for (const prediction of predictions) {
            const churnScore = parseFloat(prediction.churn_probability);
            const riskLevel = getRiskLevel(churnScore);
            // Update BigQuery
            const updateQuery = `
          UPDATE \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\`
          SET
            churn_prediction_score = @churnScore,
            last_updated = CURRENT_TIMESTAMP()
          WHERE user_id = @userId
        `;
            await bigQuerySetup_1.bigquery.query({
                query: updateQuery,
                params: {
                    userId: prediction.user_id,
                    churnScore,
                },
            });
            // Create retention alert for high-risk users
            if (riskLevel === 'high' || riskLevel === 'critical') {
                const alertRef = firestore.collection('retention_alerts').doc();
                batch.set(alertRef, {
                    userId: prediction.user_id,
                    churnScore,
                    riskLevel,
                    createdAt: admin.firestore.FieldValue.serverTimestamp(),
                    actioned: false,
                });
                batchCount++;
                if (batchCount >= 500) {
                    await batch.commit();
                    batchCount = 0;
                }
            }
        }
        if (batchCount > 0) {
            await batch.commit();
        }
        console.log(`Processed ${predictions.length} churn predictions`);
        return { predictionsCount: predictions.length };
    }
    catch (error) {
        console.error('Error predicting churn:', error);
        throw error;
    }
});
/**
 * Get Churn Prediction for User
 */
exports.getUserChurnPrediction = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId } = data;
    // Check if admin or requesting own data
    const customClaims = context.auth.token;
    if (!customClaims.admin && context.auth.uid !== userId) {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    try {
        // Get churn score from BigQuery
        const query = `
        SELECT
          churn_prediction_score,
          is_churned,
          subscription_months,
          lifetime_value
        FROM \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\`
        WHERE user_id = @userId
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query,
            params: { userId },
        });
        if (rows.length === 0) {
            throw new functions.https.HttpsError('not-found', 'User not found');
        }
        const userData = rows[0];
        const churnScore = parseFloat(userData.churn_prediction_score || 0);
        const riskLevel = getRiskLevel(churnScore);
        // Analyze churn factors
        const factors = await analyzeChurnFactors(userId);
        const recommendations = generateRecommendations(churnScore, factors);
        return {
            userId,
            churnScore,
            riskLevel,
            factors,
            recommendations,
            predictedChurnDate: estimateChurnDate(churnScore),
        };
    }
    catch (error) {
        console.error('Error getting churn prediction:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get At-Risk Users
 */
exports.getAtRiskUsers = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can access at-risk users');
    }
    const { minScore = 0.5, limit = 100 } = data;
    try {
        const query = `
        SELECT
          user_id,
          churn_prediction_score,
          cohort_month,
          acquisition_channel,
          first_subscription_tier,
          lifetime_value,
          subscription_months
        FROM \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\`
        WHERE churn_prediction_score >= @minScore
          AND is_churned = false
        ORDER BY churn_prediction_score DESC
        LIMIT @limit
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query,
            params: { minScore, limit },
        });
        return {
            users: rows.map((row) => ({
                userId: row.user_id,
                churnScore: parseFloat(row.churn_prediction_score),
                riskLevel: getRiskLevel(parseFloat(row.churn_prediction_score)),
                cohortMonth: row.cohort_month,
                acquisitionChannel: row.acquisition_channel,
                subscriptionTier: row.first_subscription_tier,
                lifetimeValue: parseFloat(row.lifetime_value),
                subscriptionMonths: parseInt(row.subscription_months),
            })),
            count: rows.length,
        };
    }
    catch (error) {
        console.error('Error getting at-risk users:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Helper Functions
 */
function getRiskLevel(churnScore) {
    if (churnScore >= 0.8)
        return 'critical';
    if (churnScore >= 0.6)
        return 'high';
    if (churnScore >= 0.4)
        return 'medium';
    return 'low';
}
async function analyzeChurnFactors(userId) {
    // Simplified factor analysis
    return [
        {
            factor: 'Engagement',
            impact: -0.35,
            description: 'Low app usage in last 30 days',
        },
        {
            factor: 'Message Activity',
            impact: -0.25,
            description: 'Decreased messaging frequency',
        },
        {
            factor: 'Match Rate',
            impact: -0.15,
            description: 'Fewer matches than average',
        },
        {
            factor: 'Subscription Duration',
            impact: 0.20,
            description: 'Long-term subscriber (positive)',
        },
    ];
}
function generateRecommendations(churnScore, factors) {
    const recommendations = [];
    if (churnScore >= 0.7) {
        recommendations.push('Send personalized retention offer (50% off next month)');
        recommendations.push('Assign dedicated support representative');
        recommendations.push('Offer free profile boost or premium features trial');
    }
    if (churnScore >= 0.5) {
        recommendations.push('Send re-engagement email campaign');
        recommendations.push('Highlight unused premium features');
        recommendations.push('Offer coins bundle discount');
    }
    // Factor-specific recommendations
    factors.forEach((factor) => {
        if (factor.impact < -0.2) {
            if (factor.factor === 'Engagement') {
                recommendations.push('Send push notification about new matches');
            }
            else if (factor.factor === 'Message Activity') {
                recommendations.push('Suggest conversation starters');
            }
        }
    });
    return recommendations;
}
function estimateChurnDate(churnScore) {
    if (churnScore < 0.5)
        return undefined;
    const daysUntilChurn = Math.round((1 - churnScore) * 90); // Max 90 days
    const churnDate = new Date();
    churnDate.setDate(churnDate.getDate() + daysUntilChurn);
    return churnDate;
}
//# sourceMappingURL=churnPrediction.js.map