"use strict";
/**
 * Advanced Analytics
 * Points 170-175: A/B Testing, Fraud Detection, Forecasting, ARPU, Refunds, Tax
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
exports.getTaxReport = exports.calculateTax = exports.getRefundAnalytics = exports.getARPU = exports.forecastMRR = exports.detectFraud = exports.getABTestResults = exports.recordConversion = exports.assignUserToTest = exports.createABTest = void 0;
exports.recordTaxTransaction = recordTaxTransaction;
const functions = __importStar(require("firebase-functions/v1"));
const bigQuerySetup_1 = require("./bigQuerySetup");
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
/**
 * Create A/B Test
 * Point 170: A/B testing framework
 */
exports.createABTest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const { name, description, testType, variants, startDate, targetAudience } = data;
    try {
        const testId = firestore.collection('ab_tests').doc().id;
        const testDoc = {
            testId,
            name,
            description,
            testType,
            variants,
            startDate: admin.firestore.Timestamp.fromDate(new Date(startDate)),
            status: 'active',
            targetAudience,
            sample_size: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await firestore.collection('ab_tests').doc(testId).set(testDoc);
        return { testId, success: true };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Assign User to A/B Test Variant
 */
exports.assignUserToTest = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const { testId } = data;
    const userId = context.auth.uid;
    try {
        // Check if already assigned
        const existingAssignment = await firestore
            .collection('ab_assignments')
            .where('userId', '==', userId)
            .where('testId', '==', testId)
            .limit(1)
            .get();
        if (!existingAssignment.empty) {
            return existingAssignment.docs[0].data();
        }
        // Get test details
        const testDoc = await firestore.collection('ab_tests').doc(testId).get();
        if (!testDoc.exists) {
            throw new Error('Test not found');
        }
        const test = testDoc.data();
        const variant = selectVariant(test.variants);
        // Create assignment
        const assignment = {
            userId,
            testId,
            variant: variant.variantId,
            assignedAt: admin.firestore.FieldValue.serverTimestamp(),
            converted: false,
        };
        await firestore.collection('ab_assignments').add(assignment);
        // Log to BigQuery
        const dataset = bigQuerySetup_1.bigquery.dataset(bigQuerySetup_1.DATASET_ID);
        const table = dataset.table('ab_test_results');
        await table.insert([{
                test_id: testId,
                user_id: userId,
                variant: variant.variantId,
                test_type: test.testType,
                assigned_at: new Date().toISOString(),
                converted: false,
                conversion_timestamp: null,
                conversion_value: null,
                days_to_conversion: null,
                metadata: JSON.stringify({ variantConfig: variant.config }),
            }]);
        return { variant: variant.variantId, config: variant.config };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Record A/B Test Conversion
 */
exports.recordConversion = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const { testId, conversionValue } = data;
    const userId = context.auth.uid;
    try {
        // Find assignment
        const assignmentSnapshot = await firestore
            .collection('ab_assignments')
            .where('userId', '==', userId)
            .where('testId', '==', testId)
            .limit(1)
            .get();
        if (assignmentSnapshot.empty) {
            throw new Error('No assignment found');
        }
        const assignmentDoc = assignmentSnapshot.docs[0];
        const assignment = assignmentDoc.data();
        if (assignment.converted) {
            return { message: 'Already converted' };
        }
        const assignedAt = assignment.assignedAt.toDate();
        const now = new Date();
        const daysToConversion = Math.floor((now.getTime() - assignedAt.getTime()) / (1000 * 60 * 60 * 24));
        // Update Firestore
        await assignmentDoc.ref.update({
            converted: true,
            convertedAt: admin.firestore.FieldValue.serverTimestamp(),
            conversionValue,
        });
        // Update BigQuery
        const query = `
        UPDATE \`${bigQuerySetup_1.DATASET_ID}.ab_test_results\`
        SET
          converted = true,
          conversion_timestamp = @conversionTimestamp,
          conversion_value = @conversionValue,
          days_to_conversion = @daysToConversion
        WHERE test_id = @testId AND user_id = @userId
      `;
        await bigQuerySetup_1.bigquery.query({
            query,
            params: {
                testId,
                userId,
                conversionTimestamp: now.toISOString(),
                conversionValue,
                daysToConversion,
            },
        });
        return { success: true };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get A/B Test Results
 */
exports.getABTestResults = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const { testId } = data;
    try {
        const query = `
        SELECT
          variant,
          COUNT(*) as users,
          SUM(CASE WHEN converted THEN 1 ELSE 0 END) as conversions,
          SAFE_DIVIDE(SUM(CASE WHEN converted THEN 1 ELSE 0 END), COUNT(*)) * 100 as conversion_rate,
          AVG(CASE WHEN converted THEN conversion_value END) as avg_conversion_value,
          AVG(CASE WHEN converted THEN days_to_conversion END) as avg_days_to_conversion
        FROM \`${bigQuerySetup_1.DATASET_ID}.ab_test_results\`
        WHERE test_id = @testId
        GROUP BY variant
        ORDER BY conversion_rate DESC
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query,
            params: { testId },
        });
        // Calculate statistical significance
        const results = rows.map((row) => ({
            variant: row.variant,
            users: parseInt(row.users),
            conversions: parseInt(row.conversions),
            conversionRate: parseFloat(row.conversion_rate),
            avgConversionValue: parseFloat(row.avg_conversion_value || 0),
            avgDaysToConversion: parseFloat(row.avg_days_to_conversion || 0),
        }));
        // Calculate p-value for significance
        const significance = calculateStatisticalSignificance(results);
        return {
            results,
            significance,
            winner: significance.isSignificant ? results[0].variant : null,
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// ===== Point 171: Payment Fraud Detection =====
/**
 * Detect Fraudulent Transactions
 * Uses anomaly detection algorithms
 */
exports.detectFraud = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const { transactionId } = data;
    try {
        // Get transaction details
        const transactionQuery = `
        SELECT
          user_id,
          revenue_amount,
          platform,
          country,
          event_timestamp,
          metadata
        FROM \`${bigQuerySetup_1.DATASET_ID}.revenue_events\`
        WHERE event_id = @transactionId
      `;
        const [transactions] = await bigQuerySetup_1.bigquery.query({
            query: transactionQuery,
            params: { transactionId },
        });
        if (transactions.length === 0) {
            throw new Error('Transaction not found');
        }
        const transaction = transactions[0];
        const fraudScore = await calculateFraudScore(transaction);
        const isFraudulent = fraudScore > 0.7;
        if (isFraudulent) {
            // Create fraud alert
            await firestore.collection('fraud_alerts').add({
                transactionId,
                userId: transaction.user_id,
                fraudScore,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                reviewed: false,
            });
        }
        return {
            transactionId,
            fraudScore,
            isFraudulent,
            riskLevel: fraudScore > 0.9 ? 'critical' : fraudScore > 0.7 ? 'high' : fraudScore > 0.5 ? 'medium' : 'low',
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
async function calculateFraudScore(transaction) {
    var _a;
    let score = 0;
    // Factor 1: Unusual transaction amount (20%)
    const avgTransactionQuery = `
    SELECT AVG(revenue_amount) as avg_amount
    FROM \`${bigQuerySetup_1.DATASET_ID}.revenue_events\`
    WHERE user_id = @userId
  `;
    const [avgResults] = await bigQuerySetup_1.bigquery.query({
        query: avgTransactionQuery,
        params: { userId: transaction.user_id },
    });
    const avgAmount = parseFloat(((_a = avgResults[0]) === null || _a === void 0 ? void 0 : _a.avg_amount) || 50);
    if (transaction.revenue_amount > avgAmount * 3) {
        score += 0.2;
    }
    // Factor 2: Multiple transactions in short time (25%)
    const recentTransactionsQuery = `
    SELECT COUNT(*) as count
    FROM \`${bigQuerySetup_1.DATASET_ID}.revenue_events\`
    WHERE user_id = @userId
      AND event_timestamp >= TIMESTAMP_SUB(@timestamp, INTERVAL 1 HOUR)
  `;
    const [recentResults] = await bigQuerySetup_1.bigquery.query({
        query: recentTransactionsQuery,
        params: {
            userId: transaction.user_id,
            timestamp: transaction.event_timestamp,
        },
    });
    if (parseInt(recentResults[0].count) > 3) {
        score += 0.25;
    }
    // Factor 3: High-risk country (15%)
    const highRiskCountries = ['XX', 'YY']; // Mock data
    if (highRiskCountries.includes(transaction.country)) {
        score += 0.15;
    }
    // Factor 4: VPN/proxy detected (20%)
    // Mock - in production, integrate with fraud detection service
    score += 0.0;
    // Factor 5: Refund history (20%)
    const refundHistoryQuery = `
    SELECT COUNT(*) as refund_count
    FROM \`${bigQuerySetup_1.DATASET_ID}.refund_events\`
    WHERE user_id = @userId
  `;
    const [refundResults] = await bigQuerySetup_1.bigquery.query({
        query: refundHistoryQuery,
        params: { userId: transaction.user_id },
    });
    if (parseInt(refundResults[0].refund_count) > 2) {
        score += 0.2;
    }
    return Math.min(score, 1.0);
}
// ===== Point 172: Revenue Forecasting =====
/**
 * Forecast Monthly Recurring Revenue
 */
exports.forecastMRR = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const { months = 6 } = data;
    try {
        // Use BigQuery ML for time series forecasting
        const forecastQuery = `
        WITH historical_mrr AS (
          SELECT
            FORMAT_DATE('%Y-%m', DATE(event_timestamp)) as month,
            SUM(CASE WHEN event_type = 'subscription' THEN revenue_amount ELSE 0 END) as mrr
          FROM \`${bigQuerySetup_1.DATASET_ID}.revenue_events\`
          WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH)
          GROUP BY month
          ORDER BY month
        ),
        -- Simple linear regression forecast
        trend_data AS (
          SELECT
            month,
            mrr,
            ROW_NUMBER() OVER (ORDER BY month) as month_number
          FROM historical_mrr
        )
        SELECT
          month,
          mrr as actual_mrr,
          AVG(mrr) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as forecasted_mrr
        FROM trend_data
        ORDER BY month DESC
        LIMIT @months
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query: forecastQuery,
            params: { months },
        });
        // Calculate growth rate
        const growthRate = rows.length > 1
            ? ((parseFloat(rows[0].actual_mrr) - parseFloat(rows[1].actual_mrr)) / parseFloat(rows[1].actual_mrr)) * 100
            : 0;
        // Project future months
        const lastMRR = parseFloat(rows[0].actual_mrr);
        const projections = [];
        for (let i = 1; i <= months; i++) {
            const projectedMRR = lastMRR * Math.pow(1 + (growthRate / 100), i);
            projections.push({
                month: getMonthOffset(i),
                projectedMRR,
                confidence: Math.max(0.5, 1 - (i * 0.05)), // Confidence decreases over time
            });
        }
        return {
            historical: rows.map((row) => ({
                month: row.month,
                actualMRR: parseFloat(row.actual_mrr),
            })),
            projections,
            growthRate,
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// ===== Point 173: ARPU Tracking =====
/**
 * Get ARPU (Average Revenue Per User) by Tier and Region
 */
exports.getARPU = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const { startDate, endDate } = data;
    try {
        const query = `
        WITH user_revenue AS (
          SELECT
            r.user_id,
            c.first_subscription_tier as tier,
            c.region,
            SUM(r.revenue_amount) as total_revenue
          FROM \`${bigQuerySetup_1.DATASET_ID}.revenue_events\` r
          JOIN \`${bigQuerySetup_1.DATASET_ID}.user_cohorts\` c ON r.user_id = c.user_id
          WHERE DATE(r.event_timestamp) >= @startDate
            AND DATE(r.event_timestamp) <= @endDate
          GROUP BY r.user_id, c.first_subscription_tier, c.region
        )
        SELECT
          tier,
          region,
          COUNT(DISTINCT user_id) as user_count,
          SUM(total_revenue) as total_revenue,
          AVG(total_revenue) as arpu,
          STDDEV(total_revenue) as stddev
        FROM user_revenue
        WHERE tier IS NOT NULL
        GROUP BY tier, region
        ORDER BY total_revenue DESC
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query,
            params: { startDate, endDate },
        });
        return {
            byTier: rows.map((row) => ({
                tier: row.tier,
                region: row.region,
                userCount: parseInt(row.user_count),
                totalRevenue: parseFloat(row.total_revenue),
                arpu: parseFloat(row.arpu),
                stddev: parseFloat(row.stddev),
            })),
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// ===== Point 174: Refund Analytics =====
/**
 * Get Refund Analytics
 */
exports.getRefundAnalytics = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const { startDate, endDate } = data;
    try {
        const query = `
        SELECT
          DATE(refund_timestamp) as date,
          COUNT(*) as refund_count,
          SUM(refund_amount) as total_refunded,
          AVG(refund_amount) as avg_refund,
          refund_reason,
          platform,
          product_type,
          SUM(CASE WHEN is_fraudulent THEN 1 ELSE 0 END) as fraudulent_count
        FROM \`${bigQuerySetup_1.DATASET_ID}.refund_events\`
        WHERE DATE(refund_timestamp) >= @startDate
          AND DATE(refund_timestamp) <= @endDate
        GROUP BY date, refund_reason, platform, product_type
        ORDER BY date DESC, total_refunded DESC
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query,
            params: { startDate, endDate },
        });
        // Calculate refund rate
        const revenueQuery = `
        SELECT SUM(revenue_amount) as total_revenue
        FROM \`${bigQuerySetup_1.DATASET_ID}.revenue_events\`
        WHERE DATE(event_timestamp) >= @startDate
          AND DATE(event_timestamp) <= @endDate
      `;
        const [revenueRows] = await bigQuerySetup_1.bigquery.query({
            query: revenueQuery,
            params: { startDate, endDate },
        });
        const totalRevenue = parseFloat(revenueRows[0].total_revenue);
        const totalRefunded = rows.reduce((sum, row) => sum + parseFloat(row.total_refunded), 0);
        const refundRate = (totalRefunded / totalRevenue) * 100;
        return {
            refunds: rows.map((row) => ({
                date: row.date.value,
                refundCount: parseInt(row.refund_count),
                totalRefunded: parseFloat(row.total_refunded),
                avgRefund: parseFloat(row.avg_refund),
                reason: row.refund_reason,
                platform: row.platform,
                productType: row.product_type,
                fraudulentCount: parseInt(row.fraudulent_count),
            })),
            summary: {
                totalRefunded,
                refundRate,
                totalRevenue,
            },
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// ===== Point 175: Tax Compliance =====
/**
 * Calculate Tax for Transaction
 */
exports.calculateTax = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const { amount, country, stateProvince, postalCode } = data;
    try {
        const taxRate = await getTaxRate(country, stateProvince, postalCode);
        const taxAmount = amount * taxRate;
        const netAmount = amount - taxAmount;
        return {
            grossAmount: amount,
            taxAmount,
            netAmount,
            taxRate,
            taxJurisdiction: `${country}-${stateProvince || 'FEDERAL'}`,
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Record Tax Transaction
 */
async function recordTaxTransaction(transactionId, userId, grossAmount, location) {
    const taxRate = await getTaxRate(location.country, location.stateProvince, location.postalCode);
    const taxAmount = grossAmount * taxRate;
    const netAmount = grossAmount - taxAmount;
    const dataset = bigQuerySetup_1.bigquery.dataset(bigQuerySetup_1.DATASET_ID);
    const table = dataset.table('tax_records');
    await table.insert([{
            tax_record_id: firestore.collection('temp').doc().id,
            transaction_id: transactionId,
            user_id: userId,
            transaction_date: new Date().toISOString(),
            gross_amount: grossAmount,
            tax_amount: taxAmount,
            net_amount: netAmount,
            tax_rate: taxRate,
            tax_jurisdiction: `${location.country}-${location.stateProvince || 'FEDERAL'}`,
            country: location.country,
            state_province: location.stateProvince,
            city: location.city,
            postal_code: location.postalCode,
            tax_type: getTaxType(location.country),
            remitted: false,
            remittance_date: null,
            metadata: null,
        }]);
}
/**
 * Get Tax Compliance Report
 */
exports.getTaxReport = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    }
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const { startDate, endDate } = data;
    try {
        const query = `
        SELECT
          tax_jurisdiction,
          country,
          state_province,
          tax_type,
          COUNT(*) as transaction_count,
          SUM(gross_amount) as total_gross,
          SUM(tax_amount) as total_tax,
          SUM(net_amount) as total_net,
          AVG(tax_rate) * 100 as avg_tax_rate,
          SUM(CASE WHEN remitted THEN tax_amount ELSE 0 END) as remitted_amount,
          SUM(CASE WHEN NOT remitted THEN tax_amount ELSE 0 END) as pending_amount
        FROM \`${bigQuerySetup_1.DATASET_ID}.tax_records\`
        WHERE DATE(transaction_date) >= @startDate
          AND DATE(transaction_date) <= @endDate
        GROUP BY tax_jurisdiction, country, state_province, tax_type
        ORDER BY total_tax DESC
      `;
        const [rows] = await bigQuerySetup_1.bigquery.query({
            query,
            params: { startDate, endDate },
        });
        return {
            byJurisdiction: rows.map((row) => ({
                jurisdiction: row.tax_jurisdiction,
                country: row.country,
                stateProvince: row.state_province,
                taxType: row.tax_type,
                transactionCount: parseInt(row.transaction_count),
                totalGross: parseFloat(row.total_gross),
                totalTax: parseFloat(row.total_tax),
                totalNet: parseFloat(row.total_net),
                avgTaxRate: parseFloat(row.avg_tax_rate),
                remittedAmount: parseFloat(row.remitted_amount),
                pendingAmount: parseFloat(row.pending_amount),
            })),
        };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', error.message);
    }
});
// Helper functions
function selectVariant(variants) {
    const random = Math.random() * 100;
    let cumulative = 0;
    for (const variant of variants) {
        cumulative += variant.traffic_percentage;
        if (random <= cumulative) {
            return variant;
        }
    }
    return variants[0];
}
function calculateStatisticalSignificance(results) {
    if (results.length < 2)
        return { isSignificant: false };
    // Simplified chi-square test
    const control = results[0];
    const variant = results[1];
    const p1 = control.conversions / control.users;
    const p2 = variant.conversions / variant.users;
    const pooled = (control.conversions + variant.conversions) / (control.users + variant.users);
    const se = Math.sqrt(pooled * (1 - pooled) * (1 / control.users + 1 / variant.users));
    const z = (p2 - p1) / se;
    const pValue = 2 * (1 - normalCDF(Math.abs(z)));
    return {
        isSignificant: pValue < 0.05,
        pValue,
        zScore: z,
    };
}
function normalCDF(z) {
    return (1 + erf(z / Math.sqrt(2))) / 2;
}
function erf(x) {
    const sign = x >= 0 ? 1 : -1;
    x = Math.abs(x);
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    const t = 1 / (1 + p * x);
    const y = 1 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);
    return sign * y;
}
async function getTaxRate(country, stateProvince, postalCode) {
    // Mock tax rates - in production, integrate with tax API (Avalara, TaxJar, etc.)
    const taxRates = {
        'US': 0.0, // Federal level, states vary
        'US-CA': 0.0725, // California
        'US-NY': 0.04, // New York
        'US-TX': 0.0625, // Texas
        'CA': 0.05, // Canada GST
        'GB': 0.20, // UK VAT
        'DE': 0.19, // Germany VAT
        'FR': 0.20, // France VAT
        'AU': 0.10, // Australia GST
    };
    const key = stateProvince ? `${country}-${stateProvince}` : country;
    return taxRates[key] || 0;
}
function getTaxType(country) {
    const vatCountries = ['GB', 'DE', 'FR', 'IT', 'ES'];
    const gstCountries = ['CA', 'AU', 'NZ', 'SG'];
    if (vatCountries.includes(country))
        return 'vat';
    if (gstCountries.includes(country))
        return 'gst';
    return 'sales_tax';
}
function getMonthOffset(months) {
    const date = new Date();
    date.setMonth(date.getMonth() + months);
    return date.toISOString().substring(0, 7);
}
//# sourceMappingURL=advancedAnalytics.js.map