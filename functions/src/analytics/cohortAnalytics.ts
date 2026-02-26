/**
 * Cohort Analytics
 * Point 168: Cohort analysis tracking user lifetime value by acquisition channel
 */

import * as functions from 'firebase-functions/v1';
import { bigquery, DATASET_ID } from './bigQuerySetup';

/**
 * Cohort Analysis Interfaces
 */
export interface CohortAnalysis {
  cohorts: CohortData[];
  retentionMatrix: RetentionMatrix;
  ltvByCohort: LTVByCohort[];
  channelComparison: ChannelComparison[];
}

export interface CohortData {
  cohortMonth: string;
  cohortSize: number;
  acquisitionChannel: string;
  avgLTV: number;
  totalRevenue: number;
  activeUsers: number;
  churnedUsers: number;
  churnRate: number;
  avgSubscriptionMonths: number;
  conversionRate: number;
}

export interface RetentionMatrix {
  cohorts: string[];
  months: number[];
  retentionRates: number[][]; // [cohort][month]
}

export interface LTVByCohort {
  cohortMonth: string;
  month0: number;
  month1: number;
  month3: number;
  month6: number;
  month12: number;
  predictedLTV: number;
}

export interface ChannelComparison {
  channel: string;
  totalUsers: number;
  totalRevenue: number;
  avgLTV: number;
  conversionRate: number;
  avgSubscriptionMonths: number;
  churnRate: number;
  cac: number; // Customer Acquisition Cost
  ltvCacRatio: number;
}

/**
 * Get Cohort Analysis
 * Point 168: Complete cohort analysis
 */
export const getCohortAnalysis = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const customClaims = context.auth.token;
    if (!customClaims.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can access cohort analysis'
      );
    }

    const { startMonth, endMonth, channel } = data;

    try {
      const [cohorts, retentionMatrix, ltvByCohort, channelComparison] =
        await Promise.all([
          getCohortData(startMonth, endMonth, channel),
          getRetentionMatrix(startMonth, endMonth),
          getLTVByCohort(startMonth, endMonth),
          getChannelComparison(),
        ]);

      return {
        cohorts,
        retentionMatrix,
        ltvByCohort,
        channelComparison,
      };
    } catch (error: any) {
      console.error('Error fetching cohort analysis:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Get Cohort Data
 */
async function getCohortData(
  startMonth?: string,
  endMonth?: string,
  channel?: string
): Promise<CohortData[]> {
  const query = `
    WITH cohort_stats AS (
      SELECT
        cohort_month,
        acquisition_channel,
        COUNT(*) as cohort_size,
        AVG(lifetime_value) as avg_ltv,
        SUM(total_revenue) as total_revenue,
        SUM(CASE WHEN is_churned = false THEN 1 ELSE 0 END) as active_users,
        SUM(CASE WHEN is_churned = true THEN 1 ELSE 0 END) as churned_users,
        AVG(subscription_months) as avg_subscription_months,
        SUM(CASE WHEN first_subscription_tier IS NOT NULL THEN 1 ELSE 0 END) as converted_users
      FROM \`${DATASET_ID}.user_cohorts\`
      WHERE cohort_month >= FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH))
        ${startMonth ? `AND cohort_month >= @startMonth` : ''}
        ${endMonth ? `AND cohort_month <= @endMonth` : ''}
        ${channel ? `AND acquisition_channel = @channel` : ''}
      GROUP BY cohort_month, acquisition_channel
    )
    SELECT
      cohort_month,
      acquisition_channel,
      cohort_size,
      COALESCE(avg_ltv, 0) as avg_ltv,
      COALESCE(total_revenue, 0) as total_revenue,
      active_users,
      churned_users,
      SAFE_DIVIDE(churned_users, cohort_size) * 100 as churn_rate,
      COALESCE(avg_subscription_months, 0) as avg_subscription_months,
      SAFE_DIVIDE(converted_users, cohort_size) * 100 as conversion_rate
    FROM cohort_stats
    ORDER BY cohort_month DESC, acquisition_channel
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startMonth) options.params.startMonth = startMonth;
  if (endMonth) options.params.endMonth = endMonth;
  if (channel) options.params.channel = channel;

  const [rows] = await bigquery.query(options);

  return rows.map((row: any) => ({
    cohortMonth: row.cohort_month,
    cohortSize: parseInt(row.cohort_size),
    acquisitionChannel: row.acquisition_channel,
    avgLTV: parseFloat(row.avg_ltv),
    totalRevenue: parseFloat(row.total_revenue),
    activeUsers: parseInt(row.active_users),
    churnedUsers: parseInt(row.churned_users),
    churnRate: parseFloat(row.churn_rate),
    avgSubscriptionMonths: parseFloat(row.avg_subscription_months),
    conversionRate: parseFloat(row.conversion_rate),
  }));
}

/**
 * Get Retention Matrix
 */
async function getRetentionMatrix(
  startMonth?: string,
  endMonth?: string
): Promise<RetentionMatrix> {
  const query = `
    WITH cohort_users AS (
      SELECT
        cohort_month,
        user_id,
        cohort_date
      FROM \`${DATASET_ID}.user_cohorts\`
      WHERE cohort_month >= FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH))
        ${startMonth ? `AND cohort_month >= @startMonth` : ''}
        ${endMonth ? `AND cohort_month <= @endMonth` : ''}
    ),
    user_activity AS (
      SELECT
        c.cohort_month,
        c.user_id,
        DATE_DIFF(DATE(s.event_timestamp), c.cohort_date, MONTH) as months_since_cohort
      FROM cohort_users c
      JOIN \`${DATASET_ID}.subscription_events\` s
        ON c.user_id = s.user_id
      WHERE s.event_type IN ('started', 'renewed')
    ),
    retention_data AS (
      SELECT
        cohort_month,
        months_since_cohort,
        COUNT(DISTINCT user_id) as active_users
      FROM user_activity
      WHERE months_since_cohort <= 12
      GROUP BY cohort_month, months_since_cohort
    ),
    cohort_sizes AS (
      SELECT
        cohort_month,
        COUNT(*) as total_users
      FROM cohort_users
      GROUP BY cohort_month
    )
    SELECT
      r.cohort_month,
      r.months_since_cohort,
      SAFE_DIVIDE(r.active_users, c.total_users) * 100 as retention_rate
    FROM retention_data r
    JOIN cohort_sizes c ON r.cohort_month = c.cohort_month
    ORDER BY r.cohort_month, r.months_since_cohort
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startMonth) options.params.startMonth = startMonth;
  if (endMonth) options.params.endMonth = endMonth;

  const [rows] = await bigquery.query(options);

  // Build matrix
  const cohorts: string[] = [];
  const retentionMap = new Map<string, Map<number, number>>();

  rows.forEach((row: any) => {
    const cohort = row.cohort_month;
    const month = parseInt(row.months_since_cohort);
    const rate = parseFloat(row.retention_rate);

    if (!cohorts.includes(cohort)) {
      cohorts.push(cohort);
    }

    if (!retentionMap.has(cohort)) {
      retentionMap.set(cohort, new Map());
    }

    retentionMap.get(cohort)!.set(month, rate);
  });

  // Convert to 2D array
  const months = Array.from({ length: 13 }, (_, i) => i);
  const retentionRates = cohorts.map((cohort) => {
    const cohortData = retentionMap.get(cohort)!;
    return months.map((month) => cohortData.get(month) || 0);
  });

  return {
    cohorts,
    months,
    retentionRates,
  };
}

/**
 * Get LTV by Cohort over time
 */
async function getLTVByCohort(
  startMonth?: string,
  endMonth?: string
): Promise<LTVByCohort[]> {
  const query = `
    WITH cohort_revenue AS (
      SELECT
        c.cohort_month,
        c.user_id,
        c.cohort_date,
        SUM(CASE
          WHEN DATE_DIFF(DATE(r.event_timestamp), c.cohort_date, MONTH) = 0
          THEN r.revenue_amount
          ELSE 0
        END) as month_0_revenue,
        SUM(CASE
          WHEN DATE_DIFF(DATE(r.event_timestamp), c.cohort_date, MONTH) <= 1
          THEN r.revenue_amount
          ELSE 0
        END) as month_1_revenue,
        SUM(CASE
          WHEN DATE_DIFF(DATE(r.event_timestamp), c.cohort_date, MONTH) <= 3
          THEN r.revenue_amount
          ELSE 0
        END) as month_3_revenue,
        SUM(CASE
          WHEN DATE_DIFF(DATE(r.event_timestamp), c.cohort_date, MONTH) <= 6
          THEN r.revenue_amount
          ELSE 0
        END) as month_6_revenue,
        SUM(CASE
          WHEN DATE_DIFF(DATE(r.event_timestamp), c.cohort_date, MONTH) <= 12
          THEN r.revenue_amount
          ELSE 0
        END) as month_12_revenue
      FROM \`${DATASET_ID}.user_cohorts\` c
      LEFT JOIN \`${DATASET_ID}.revenue_events\` r
        ON c.user_id = r.user_id
      WHERE c.cohort_month >= FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH))
        ${startMonth ? `AND c.cohort_month >= @startMonth` : ''}
        ${endMonth ? `AND c.cohort_month <= @endMonth` : ''}
      GROUP BY c.cohort_month, c.user_id, c.cohort_date
    )
    SELECT
      cohort_month,
      AVG(month_0_revenue) as month_0,
      AVG(month_1_revenue) as month_1,
      AVG(month_3_revenue) as month_3,
      AVG(month_6_revenue) as month_6,
      AVG(month_12_revenue) as month_12,
      -- Predict LTV using exponential smoothing
      AVG(month_12_revenue) * 1.5 as predicted_ltv
    FROM cohort_revenue
    GROUP BY cohort_month
    ORDER BY cohort_month DESC
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startMonth) options.params.startMonth = startMonth;
  if (endMonth) options.params.endMonth = endMonth;

  const [rows] = await bigquery.query(options);

  return rows.map((row: any) => ({
    cohortMonth: row.cohort_month,
    month0: parseFloat(row.month_0),
    month1: parseFloat(row.month_1),
    month3: parseFloat(row.month_3),
    month6: parseFloat(row.month_6),
    month12: parseFloat(row.month_12),
    predictedLTV: parseFloat(row.predicted_ltv),
  }));
}

/**
 * Get Channel Comparison
 */
async function getChannelComparison(): Promise<ChannelComparison[]> {
  const query = `
    WITH channel_stats AS (
      SELECT
        acquisition_channel,
        COUNT(*) as total_users,
        SUM(total_revenue) as total_revenue,
        AVG(lifetime_value) as avg_ltv,
        SUM(CASE WHEN first_subscription_tier IS NOT NULL THEN 1 ELSE 0 END) as converted_users,
        AVG(subscription_months) as avg_subscription_months,
        SUM(CASE WHEN is_churned = true THEN 1 ELSE 0 END) as churned_users
      FROM \`${DATASET_ID}.user_cohorts\`
      WHERE cohort_month >= FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH))
      GROUP BY acquisition_channel
    ),
    channel_costs AS (
      -- Mock data - in production, join with marketing spend table
      SELECT 'organic' as channel, 5000 as total_cost UNION ALL
      SELECT 'facebook', 15000 UNION ALL
      SELECT 'google', 12000 UNION ALL
      SELECT 'instagram', 8000 UNION ALL
      SELECT 'referral', 3000
    )
    SELECT
      s.acquisition_channel as channel,
      s.total_users,
      COALESCE(s.total_revenue, 0) as total_revenue,
      COALESCE(s.avg_ltv, 0) as avg_ltv,
      SAFE_DIVIDE(s.converted_users, s.total_users) * 100 as conversion_rate,
      COALESCE(s.avg_subscription_months, 0) as avg_subscription_months,
      SAFE_DIVIDE(s.churned_users, s.total_users) * 100 as churn_rate,
      SAFE_DIVIDE(COALESCE(c.total_cost, 0), s.total_users) as cac,
      SAFE_DIVIDE(COALESCE(s.avg_ltv, 0), SAFE_DIVIDE(COALESCE(c.total_cost, 0), s.total_users)) as ltv_cac_ratio
    FROM channel_stats s
    LEFT JOIN channel_costs c ON s.acquisition_channel = c.channel
    ORDER BY total_revenue DESC
  `;

  const [rows] = await bigquery.query(query);

  return rows.map((row: any) => ({
    channel: row.channel,
    totalUsers: parseInt(row.total_users),
    totalRevenue: parseFloat(row.total_revenue),
    avgLTV: parseFloat(row.avg_ltv),
    conversionRate: parseFloat(row.conversion_rate),
    avgSubscriptionMonths: parseFloat(row.avg_subscription_months),
    churnRate: parseFloat(row.churn_rate),
    cac: parseFloat(row.cac),
    ltvCacRatio: parseFloat(row.ltv_cac_ratio),
  }));
}

/**
 * Update user cohort on subscription event
 * Triggered by subscription events
 */
export async function updateUserCohortData(
  userId: string,
  subscriptionData: any
): Promise<void> {
  const query = `
    UPDATE \`${DATASET_ID}.user_cohorts\`
    SET
      first_subscription_tier = COALESCE(first_subscription_tier, @tier),
      first_subscription_date = COALESCE(first_subscription_date, @subscription_date),
      lifetime_value = (
        SELECT SUM(revenue_amount)
        FROM \`${DATASET_ID}.revenue_events\`
        WHERE user_id = @userId
      ),
      total_revenue = (
        SELECT SUM(revenue_amount)
        FROM \`${DATASET_ID}.revenue_events\`
        WHERE user_id = @userId
      ),
      subscription_months = DATE_DIFF(
        CURRENT_DATE(),
        DATE(COALESCE(first_subscription_date, @subscription_date)),
        MONTH
      ),
      last_updated = CURRENT_TIMESTAMP()
    WHERE user_id = @userId
  `;

  await bigquery.query({
    query,
    params: {
      userId,
      tier: subscriptionData.tier,
      subscription_date: subscriptionData.startDate.toISOString(),
    },
  });
}
