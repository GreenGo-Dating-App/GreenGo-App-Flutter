"use strict";
/**
 * BigQuery Data Warehouse Setup
 * Point 166: BigQuery integration for financial analytics
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DATASET_ID = exports.bigquery = exports.taxRecordsSchema = exports.abTestResultsSchema = exports.refundEventsSchema = exports.userCohortsSchema = exports.subscriptionEventsSchema = exports.revenueEventsSchema = void 0;
exports.initializeBigQuery = initializeBigQuery;
exports.insertRevenueEvent = insertRevenueEvent;
exports.insertSubscriptionEvent = insertSubscriptionEvent;
exports.insertRefundEvent = insertRefundEvent;
exports.upsertUserCohort = upsertUserCohort;
const bigquery_1 = require("@google-cloud/bigquery");
const bigquery = new bigquery_1.BigQuery();
exports.bigquery = bigquery;
const DATASET_ID = 'greengo_analytics';
exports.DATASET_ID = DATASET_ID;
/**
 * BigQuery Schema Definitions
 */
// Revenue Events Table Schema
exports.revenueEventsSchema = [
    { name: 'event_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'event_type', type: 'STRING', mode: 'REQUIRED' }, // subscription, coin_purchase, refund
    { name: 'event_timestamp', type: 'TIMESTAMP', mode: 'REQUIRED' },
    { name: 'revenue_amount', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'currency', type: 'STRING', mode: 'REQUIRED' },
    { name: 'platform', type: 'STRING', mode: 'NULLABLE' }, // android, ios, web
    { name: 'subscription_tier', type: 'STRING', mode: 'NULLABLE' }, // basic, silver, gold
    { name: 'product_id', type: 'STRING', mode: 'NULLABLE' },
    { name: 'transaction_id', type: 'STRING', mode: 'NULLABLE' },
    { name: 'purchase_token', type: 'STRING', mode: 'NULLABLE' },
    { name: 'country', type: 'STRING', mode: 'NULLABLE' },
    { name: 'region', type: 'STRING', mode: 'NULLABLE' },
    { name: 'acquisition_channel', type: 'STRING', mode: 'NULLABLE' },
    { name: 'user_cohort', type: 'DATE', mode: 'NULLABLE' }, // Sign-up date
    { name: 'is_trial', type: 'BOOLEAN', mode: 'NULLABLE' },
    { name: 'is_renewal', type: 'BOOLEAN', mode: 'NULLABLE' },
    { name: 'previous_tier', type: 'STRING', mode: 'NULLABLE' },
    { name: 'metadata', type: 'JSON', mode: 'NULLABLE' },
];
// Subscription Events Table Schema
exports.subscriptionEventsSchema = [
    { name: 'event_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'subscription_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'event_type', type: 'STRING', mode: 'REQUIRED' }, // started, renewed, upgraded, downgraded, cancelled, expired
    { name: 'event_timestamp', type: 'TIMESTAMP', mode: 'REQUIRED' },
    { name: 'tier', type: 'STRING', mode: 'REQUIRED' },
    { name: 'previous_tier', type: 'STRING', mode: 'NULLABLE' },
    { name: 'price', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'billing_period', type: 'STRING', mode: 'REQUIRED' }, // monthly, yearly
    { name: 'platform', type: 'STRING', mode: 'REQUIRED' },
    { name: 'cancel_reason', type: 'STRING', mode: 'NULLABLE' },
    { name: 'days_subscribed', type: 'INTEGER', mode: 'NULLABLE' },
    { name: 'lifetime_value', type: 'NUMERIC', mode: 'NULLABLE' },
    { name: 'is_in_grace_period', type: 'BOOLEAN', mode: 'NULLABLE' },
    { name: 'country', type: 'STRING', mode: 'NULLABLE' },
    { name: 'metadata', type: 'JSON', mode: 'NULLABLE' },
];
// User Cohorts Table Schema
exports.userCohortsSchema = [
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'cohort_date', type: 'DATE', mode: 'REQUIRED' },
    { name: 'cohort_month', type: 'STRING', mode: 'REQUIRED' }, // YYYY-MM
    { name: 'acquisition_channel', type: 'STRING', mode: 'REQUIRED' },
    { name: 'initial_platform', type: 'STRING', mode: 'REQUIRED' },
    { name: 'country', type: 'STRING', mode: 'NULLABLE' },
    { name: 'region', type: 'STRING', mode: 'NULLABLE' },
    { name: 'first_subscription_tier', type: 'STRING', mode: 'NULLABLE' },
    { name: 'first_subscription_date', type: 'TIMESTAMP', mode: 'NULLABLE' },
    { name: 'lifetime_value', type: 'NUMERIC', mode: 'NULLABLE' },
    { name: 'total_revenue', type: 'NUMERIC', mode: 'NULLABLE' },
    { name: 'subscription_months', type: 'INTEGER', mode: 'NULLABLE' },
    { name: 'is_churned', type: 'BOOLEAN', mode: 'NULLABLE' },
    { name: 'churn_date', type: 'TIMESTAMP', mode: 'NULLABLE' },
    { name: 'churn_prediction_score', type: 'NUMERIC', mode: 'NULLABLE' },
    { name: 'last_updated', type: 'TIMESTAMP', mode: 'REQUIRED' },
];
// Refund Events Table Schema
exports.refundEventsSchema = [
    { name: 'refund_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'original_transaction_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'refund_timestamp', type: 'TIMESTAMP', mode: 'REQUIRED' },
    { name: 'refund_amount', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'currency', type: 'STRING', mode: 'REQUIRED' },
    { name: 'refund_reason', type: 'STRING', mode: 'NULLABLE' },
    { name: 'refund_type', type: 'STRING', mode: 'REQUIRED' }, // full, partial
    { name: 'platform', type: 'STRING', mode: 'REQUIRED' },
    { name: 'product_type', type: 'STRING', mode: 'REQUIRED' }, // subscription, coins
    { name: 'days_since_purchase', type: 'INTEGER', mode: 'NULLABLE' },
    { name: 'is_fraudulent', type: 'BOOLEAN', mode: 'NULLABLE' },
    { name: 'fraud_score', type: 'NUMERIC', mode: 'NULLABLE' },
    { name: 'country', type: 'STRING', mode: 'NULLABLE' },
    { name: 'metadata', type: 'JSON', mode: 'NULLABLE' },
];
// A/B Test Results Table Schema
exports.abTestResultsSchema = [
    { name: 'test_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'variant', type: 'STRING', mode: 'REQUIRED' }, // control, variant_a, variant_b
    { name: 'test_type', type: 'STRING', mode: 'REQUIRED' }, // pricing, ui, feature
    { name: 'assigned_at', type: 'TIMESTAMP', mode: 'REQUIRED' },
    { name: 'converted', type: 'BOOLEAN', mode: 'REQUIRED' },
    { name: 'conversion_timestamp', type: 'TIMESTAMP', mode: 'NULLABLE' },
    { name: 'conversion_value', type: 'NUMERIC', mode: 'NULLABLE' },
    { name: 'days_to_conversion', type: 'INTEGER', mode: 'NULLABLE' },
    { name: 'metadata', type: 'JSON', mode: 'NULLABLE' },
];
// Tax Records Table Schema
exports.taxRecordsSchema = [
    { name: 'tax_record_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'transaction_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'transaction_date', type: 'TIMESTAMP', mode: 'REQUIRED' },
    { name: 'gross_amount', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'tax_amount', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'net_amount', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'tax_rate', type: 'NUMERIC', mode: 'REQUIRED' },
    { name: 'tax_jurisdiction', type: 'STRING', mode: 'REQUIRED' },
    { name: 'country', type: 'STRING', mode: 'REQUIRED' },
    { name: 'state_province', type: 'STRING', mode: 'NULLABLE' },
    { name: 'city', type: 'STRING', mode: 'NULLABLE' },
    { name: 'postal_code', type: 'STRING', mode: 'NULLABLE' },
    { name: 'tax_type', type: 'STRING', mode: 'REQUIRED' }, // vat, sales_tax, gst
    { name: 'remitted', type: 'BOOLEAN', mode: 'REQUIRED' },
    { name: 'remittance_date', type: 'TIMESTAMP', mode: 'NULLABLE' },
    { name: 'metadata', type: 'JSON', mode: 'NULLABLE' },
];
/**
 * Initialize BigQuery dataset and tables
 */
async function initializeBigQuery() {
    try {
        // Create dataset if it doesn't exist
        const [datasets] = await bigquery.getDatasets();
        const datasetExists = datasets.some(ds => ds.id === DATASET_ID);
        if (!datasetExists) {
            await bigquery.createDataset(DATASET_ID, {
                location: 'US',
                description: 'GreenGo Financial Analytics Data Warehouse',
            });
            console.log(`Dataset ${DATASET_ID} created`);
        }
        const dataset = bigquery.dataset(DATASET_ID);
        // Create tables
        const tables = [
            { name: 'revenue_events', schema: exports.revenueEventsSchema },
            { name: 'subscription_events', schema: exports.subscriptionEventsSchema },
            { name: 'user_cohorts', schema: exports.userCohortsSchema },
            { name: 'refund_events', schema: exports.refundEventsSchema },
            { name: 'ab_test_results', schema: exports.abTestResultsSchema },
            { name: 'tax_records', schema: exports.taxRecordsSchema },
        ];
        for (const tableConfig of tables) {
            const [tableExists] = await dataset.table(tableConfig.name).exists();
            if (!tableExists) {
                await dataset.createTable(tableConfig.name, {
                    schema: tableConfig.schema,
                    timePartitioning: {
                        type: 'DAY',
                        field: tableConfig.name === 'user_cohorts' ? 'cohort_date' :
                            tableConfig.name === 'revenue_events' ? 'event_timestamp' :
                                tableConfig.name === 'subscription_events' ? 'event_timestamp' :
                                    tableConfig.name === 'refund_events' ? 'refund_timestamp' :
                                        tableConfig.name === 'ab_test_results' ? 'assigned_at' :
                                            'transaction_date',
                    },
                    clustering: {
                        fields: tableConfig.name === 'revenue_events' ? ['user_id', 'event_type'] :
                            tableConfig.name === 'subscription_events' ? ['user_id', 'tier'] :
                                tableConfig.name === 'user_cohorts' ? ['cohort_month', 'acquisition_channel'] :
                                    tableConfig.name === 'refund_events' ? ['user_id', 'platform'] :
                                        tableConfig.name === 'ab_test_results' ? ['test_id', 'variant'] :
                                            ['country', 'tax_jurisdiction'],
                    },
                });
                console.log(`Table ${tableConfig.name} created`);
            }
        }
        console.log('BigQuery initialization complete');
    }
    catch (error) {
        console.error('Error initializing BigQuery:', error);
        throw error;
    }
}
/**
 * Insert revenue event into BigQuery
 */
async function insertRevenueEvent(data) {
    var _a;
    const dataset = bigquery.dataset(DATASET_ID);
    const table = dataset.table('revenue_events');
    const row = {
        event_id: data.eventId,
        user_id: data.userId,
        event_type: data.eventType,
        event_timestamp: data.eventTimestamp.toISOString(),
        revenue_amount: data.revenueAmount,
        currency: data.currency,
        platform: data.platform,
        subscription_tier: data.subscriptionTier,
        product_id: data.productId,
        transaction_id: data.transactionId,
        purchase_token: data.purchaseToken,
        country: data.country,
        region: data.region,
        acquisition_channel: data.acquisitionChannel,
        user_cohort: (_a = data.userCohort) === null || _a === void 0 ? void 0 : _a.toISOString().split('T')[0],
        is_trial: data.isTrial,
        is_renewal: data.isRenewal,
        previous_tier: data.previousTier,
        metadata: data.metadata ? JSON.stringify(data.metadata) : null,
    };
    await table.insert([row]);
}
/**
 * Insert subscription event into BigQuery
 */
async function insertSubscriptionEvent(data) {
    const dataset = bigquery.dataset(DATASET_ID);
    const table = dataset.table('subscription_events');
    const row = {
        event_id: data.eventId,
        subscription_id: data.subscriptionId,
        user_id: data.userId,
        event_type: data.eventType,
        event_timestamp: data.eventTimestamp.toISOString(),
        tier: data.tier,
        previous_tier: data.previousTier,
        price: data.price,
        billing_period: data.billingPeriod,
        platform: data.platform,
        cancel_reason: data.cancelReason,
        days_subscribed: data.daysSubscribed,
        lifetime_value: data.lifetimeValue,
        is_in_grace_period: data.isInGracePeriod,
        country: data.country,
        metadata: data.metadata ? JSON.stringify(data.metadata) : null,
    };
    await table.insert([row]);
}
/**
 * Insert refund event into BigQuery
 */
async function insertRefundEvent(data) {
    const dataset = bigquery.dataset(DATASET_ID);
    const table = dataset.table('refund_events');
    const row = {
        refund_id: data.refundId,
        user_id: data.userId,
        original_transaction_id: data.originalTransactionId,
        refund_timestamp: data.refundTimestamp.toISOString(),
        refund_amount: data.refundAmount,
        currency: data.currency,
        refund_reason: data.refundReason,
        refund_type: data.refundType,
        platform: data.platform,
        product_type: data.productType,
        days_since_purchase: data.daysSincePurchase,
        is_fraudulent: data.isFraudulent,
        fraud_score: data.fraudScore,
        country: data.country,
        metadata: data.metadata ? JSON.stringify(data.metadata) : null,
    };
    await table.insert([row]);
}
/**
 * Update user cohort data
 */
async function upsertUserCohort(data) {
    var _a, _b;
    const dataset = bigquery.dataset(DATASET_ID);
    // Use MERGE to upsert
    const query = `
    MERGE \`${DATASET_ID}.user_cohorts\` T
    USING (SELECT
      @user_id AS user_id,
      @cohort_date AS cohort_date,
      @cohort_month AS cohort_month,
      @acquisition_channel AS acquisition_channel,
      @initial_platform AS initial_platform,
      @country AS country,
      @region AS region,
      @first_subscription_tier AS first_subscription_tier,
      @first_subscription_date AS first_subscription_date,
      @lifetime_value AS lifetime_value,
      @total_revenue AS total_revenue,
      @subscription_months AS subscription_months,
      @is_churned AS is_churned,
      @churn_date AS churn_date,
      @churn_prediction_score AS churn_prediction_score,
      CURRENT_TIMESTAMP() AS last_updated
    ) S
    ON T.user_id = S.user_id
    WHEN MATCHED THEN
      UPDATE SET
        lifetime_value = S.lifetime_value,
        total_revenue = S.total_revenue,
        subscription_months = S.subscription_months,
        is_churned = S.is_churned,
        churn_date = S.churn_date,
        churn_prediction_score = S.churn_prediction_score,
        last_updated = S.last_updated
    WHEN NOT MATCHED THEN
      INSERT (user_id, cohort_date, cohort_month, acquisition_channel,
              initial_platform, country, region, first_subscription_tier,
              first_subscription_date, lifetime_value, total_revenue,
              subscription_months, is_churned, churn_date,
              churn_prediction_score, last_updated)
      VALUES (S.user_id, S.cohort_date, S.cohort_month, S.acquisition_channel,
              S.initial_platform, S.country, S.region, S.first_subscription_tier,
              S.first_subscription_date, S.lifetime_value, S.total_revenue,
              S.subscription_months, S.is_churned, S.churn_date,
              S.churn_prediction_score, S.last_updated)
  `;
    await bigquery.query({
        query,
        params: {
            user_id: data.userId,
            cohort_date: data.cohortDate.toISOString().split('T')[0],
            cohort_month: data.cohortMonth,
            acquisition_channel: data.acquisitionChannel,
            initial_platform: data.initialPlatform,
            country: data.country,
            region: data.region,
            first_subscription_tier: data.firstSubscriptionTier,
            first_subscription_date: (_a = data.firstSubscriptionDate) === null || _a === void 0 ? void 0 : _a.toISOString(),
            lifetime_value: data.lifetimeValue,
            total_revenue: data.totalRevenue,
            subscription_months: data.subscriptionMonths,
            is_churned: data.isChurned,
            churn_date: (_b = data.churnDate) === null || _b === void 0 ? void 0 : _b.toISOString(),
            churn_prediction_score: data.churnPredictionScore,
        },
    });
}
//# sourceMappingURL=bigQuerySetup.js.map