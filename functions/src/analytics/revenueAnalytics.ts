/**
 * Revenue Analytics
 * Point 167: Revenue dashboard tracking daily, weekly, monthly revenue by source
 */

import * as functions from 'firebase-functions';
import { bigquery, DATASET_ID } from './bigQuerySetup';

/**
 * Revenue Dashboard Data Interface
 */
export interface RevenueDashboardData {
  daily: DailyRevenue[];
  weekly: WeeklyRevenue[];
  monthly: MonthlyRevenue[];
  bySource: RevenueBySource[];
  summary: RevenueSummary;
}

export interface DailyRevenue {
  date: string;
  totalRevenue: number;
  subscriptionRevenue: number;
  coinRevenue: number;
  transactionCount: number;
  userCount: number;
}

export interface WeeklyRevenue {
  weekStart: string;
  weekEnd: string;
  totalRevenue: number;
  subscriptionRevenue: number;
  coinRevenue: number;
  transactionCount: number;
  userCount: number;
  weekNumber: number;
}

export interface MonthlyRevenue {
  month: string;
  totalRevenue: number;
  subscriptionRevenue: number;
  coinRevenue: number;
  transactionCount: number;
  userCount: number;
  mrr: number; // Monthly Recurring Revenue
  newMrr: number;
  expansionMrr: number;
  contractionMrr: number;
  churnedMrr: number;
}

export interface RevenueBySource {
  source: string;
  revenue: number;
  percentage: number;
  transactionCount: number;
  avgTransactionValue: number;
}

export interface RevenueSummary {
  todayRevenue: number;
  yesterdayRevenue: number;
  last7DaysRevenue: number;
  last30DaysRevenue: number;
  currentMonthRevenue: number;
  lastMonthRevenue: number;
  growthRate7d: number;
  growthRate30d: number;
  avgDailyRevenue: number;
}

/**
 * Get Revenue Dashboard Data
 * Point 167: Complete revenue dashboard
 */
export const getRevenueDashboard = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    // Check if user is admin
    const customClaims = context.auth.token;
    if (!customClaims.admin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can access revenue dashboard'
      );
    }

    const { startDate, endDate } = data;

    try {
      const [
        dailyRevenue,
        weeklyRevenue,
        monthlyRevenue,
        revenueBySource,
        summary,
      ] = await Promise.all([
        getDailyRevenue(startDate, endDate),
        getWeeklyRevenue(startDate, endDate),
        getMonthlyRevenue(startDate, endDate),
        getRevenueBySource(startDate, endDate),
        getRevenueSummary(),
      ]);

      return {
        daily: dailyRevenue,
        weekly: weeklyRevenue,
        monthly: monthlyRevenue,
        bySource: revenueBySource,
        summary,
      };
    } catch (error: any) {
      console.error('Error fetching revenue dashboard:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);

/**
 * Get Daily Revenue
 */
async function getDailyRevenue(
  startDate?: string,
  endDate?: string
): Promise<DailyRevenue[]> {
  const query = `
    SELECT
      DATE(event_timestamp) as date,
      SUM(revenue_amount) as total_revenue,
      SUM(CASE WHEN event_type = 'subscription' THEN revenue_amount ELSE 0 END) as subscription_revenue,
      SUM(CASE WHEN event_type = 'coin_purchase' THEN revenue_amount ELSE 0 END) as coin_revenue,
      COUNT(*) as transaction_count,
      COUNT(DISTINCT user_id) as user_count
    FROM \`${DATASET_ID}.revenue_events\`
    WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      ${startDate ? `AND DATE(event_timestamp) >= @startDate` : ''}
      ${endDate ? `AND DATE(event_timestamp) <= @endDate` : ''}
    GROUP BY date
    ORDER BY date DESC
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startDate) options.params.startDate = startDate;
  if (endDate) options.params.endDate = endDate;

  const [rows] = await bigquery.query(options);

  return rows.map((row: any) => ({
    date: row.date.value,
    totalRevenue: parseFloat(row.total_revenue),
    subscriptionRevenue: parseFloat(row.subscription_revenue),
    coinRevenue: parseFloat(row.coin_revenue),
    transactionCount: parseInt(row.transaction_count),
    userCount: parseInt(row.user_count),
  }));
}

/**
 * Get Weekly Revenue
 */
async function getWeeklyRevenue(
  startDate?: string,
  endDate?: string
): Promise<WeeklyRevenue[]> {
  const query = `
    SELECT
      DATE_TRUNC(DATE(event_timestamp), WEEK) as week_start,
      DATE_ADD(DATE_TRUNC(DATE(event_timestamp), WEEK), INTERVAL 6 DAY) as week_end,
      EXTRACT(WEEK FROM event_timestamp) as week_number,
      SUM(revenue_amount) as total_revenue,
      SUM(CASE WHEN event_type = 'subscription' THEN revenue_amount ELSE 0 END) as subscription_revenue,
      SUM(CASE WHEN event_type = 'coin_purchase' THEN revenue_amount ELSE 0 END) as coin_revenue,
      COUNT(*) as transaction_count,
      COUNT(DISTINCT user_id) as user_count
    FROM \`${DATASET_ID}.revenue_events\`
    WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 WEEK)
      ${startDate ? `AND DATE(event_timestamp) >= @startDate` : ''}
      ${endDate ? `AND DATE(event_timestamp) <= @endDate` : ''}
    GROUP BY week_start, week_end, week_number
    ORDER BY week_start DESC
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startDate) options.params.startDate = startDate;
  if (endDate) options.params.endDate = endDate;

  const [rows] = await bigquery.query(options);

  return rows.map((row: any) => ({
    weekStart: row.week_start.value,
    weekEnd: row.week_end.value,
    weekNumber: parseInt(row.week_number),
    totalRevenue: parseFloat(row.total_revenue),
    subscriptionRevenue: parseFloat(row.subscription_revenue),
    coinRevenue: parseFloat(row.coin_revenue),
    transactionCount: parseInt(row.transaction_count),
    userCount: parseInt(row.user_count),
  }));
}

/**
 * Get Monthly Revenue with MRR metrics
 */
async function getMonthlyRevenue(
  startDate?: string,
  endDate?: string
): Promise<MonthlyRevenue[]> {
  const query = `
    WITH monthly_revenue AS (
      SELECT
        FORMAT_DATE('%Y-%m', DATE(event_timestamp)) as month,
        SUM(revenue_amount) as total_revenue,
        SUM(CASE WHEN event_type = 'subscription' THEN revenue_amount ELSE 0 END) as subscription_revenue,
        SUM(CASE WHEN event_type = 'coin_purchase' THEN revenue_amount ELSE 0 END) as coin_revenue,
        COUNT(*) as transaction_count,
        COUNT(DISTINCT user_id) as user_count
      FROM \`${DATASET_ID}.revenue_events\`
      WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
        ${startDate ? `AND DATE(event_timestamp) >= @startDate` : ''}
        ${endDate ? `AND DATE(event_timestamp) <= @endDate` : ''}
      GROUP BY month
    ),
    mrr_metrics AS (
      SELECT
        FORMAT_DATE('%Y-%m', DATE(event_timestamp)) as month,
        SUM(CASE
          WHEN event_type = 'started' THEN price
          ELSE 0
        END) as new_mrr,
        SUM(CASE
          WHEN event_type = 'upgraded' THEN price - COALESCE(
            (SELECT price FROM \`${DATASET_ID}.subscription_events\` s2
             WHERE s2.subscription_id = s1.subscription_id
             AND s2.tier = s1.previous_tier
             LIMIT 1), 0
          )
          ELSE 0
        END) as expansion_mrr,
        SUM(CASE
          WHEN event_type = 'downgraded' THEN COALESCE(
            (SELECT price FROM \`${DATASET_ID}.subscription_events\` s2
             WHERE s2.subscription_id = s1.subscription_id
             AND s2.tier = s1.previous_tier
             LIMIT 1), 0
          ) - price
          ELSE 0
        END) as contraction_mrr,
        SUM(CASE
          WHEN event_type IN ('cancelled', 'expired') THEN price
          ELSE 0
        END) as churned_mrr
      FROM \`${DATASET_ID}.subscription_events\` s1
      WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
      GROUP BY month
    )
    SELECT
      r.month,
      r.total_revenue,
      r.subscription_revenue,
      r.coin_revenue,
      r.transaction_count,
      r.user_count,
      COALESCE(m.new_mrr, 0) + COALESCE(m.expansion_mrr, 0) - COALESCE(m.contraction_mrr, 0) - COALESCE(m.churned_mrr, 0) as mrr,
      COALESCE(m.new_mrr, 0) as new_mrr,
      COALESCE(m.expansion_mrr, 0) as expansion_mrr,
      COALESCE(m.contraction_mrr, 0) as contraction_mrr,
      COALESCE(m.churned_mrr, 0) as churned_mrr
    FROM monthly_revenue r
    LEFT JOIN mrr_metrics m ON r.month = m.month
    ORDER BY r.month DESC
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startDate) options.params.startDate = startDate;
  if (endDate) options.params.endDate = endDate;

  const [rows] = await bigquery.query(options);

  return rows.map((row: any) => ({
    month: row.month,
    totalRevenue: parseFloat(row.total_revenue),
    subscriptionRevenue: parseFloat(row.subscription_revenue),
    coinRevenue: parseFloat(row.coin_revenue),
    transactionCount: parseInt(row.transaction_count),
    userCount: parseInt(row.user_count),
    mrr: parseFloat(row.mrr),
    newMrr: parseFloat(row.new_mrr),
    expansionMrr: parseFloat(row.expansion_mrr),
    contractionMrr: parseFloat(row.contraction_mrr),
    churnedMrr: parseFloat(row.churned_mrr),
  }));
}

/**
 * Get Revenue by Source
 */
async function getRevenueBySource(
  startDate?: string,
  endDate?: string
): Promise<RevenueBySource[]> {
  const query = `
    WITH revenue_by_source AS (
      SELECT
        event_type as source,
        SUM(revenue_amount) as revenue,
        COUNT(*) as transaction_count,
        AVG(revenue_amount) as avg_transaction_value
      FROM \`${DATASET_ID}.revenue_events\`
      WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
        ${startDate ? `AND DATE(event_timestamp) >= @startDate` : ''}
        ${endDate ? `AND DATE(event_timestamp) <= @endDate` : ''}
      GROUP BY source
    ),
    total_revenue AS (
      SELECT SUM(revenue) as total FROM revenue_by_source
    )
    SELECT
      r.source,
      r.revenue,
      (r.revenue / t.total * 100) as percentage,
      r.transaction_count,
      r.avg_transaction_value
    FROM revenue_by_source r
    CROSS JOIN total_revenue t
    ORDER BY r.revenue DESC
  `;

  const options: any = {
    query,
    params: {},
  };

  if (startDate) options.params.startDate = startDate;
  if (endDate) options.params.endDate = endDate;

  const [rows] = await bigquery.query(options);

  return rows.map((row: any) => ({
    source: row.source,
    revenue: parseFloat(row.revenue),
    percentage: parseFloat(row.percentage),
    transactionCount: parseInt(row.transaction_count),
    avgTransactionValue: parseFloat(row.avg_transaction_value),
  }));
}

/**
 * Get Revenue Summary
 */
async function getRevenueSummary(): Promise<RevenueSummary> {
  const query = `
    WITH daily_revenue AS (
      SELECT
        DATE(event_timestamp) as date,
        SUM(revenue_amount) as revenue
      FROM \`${DATASET_ID}.revenue_events\`
      WHERE DATE(event_timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
      GROUP BY date
    )
    SELECT
      COALESCE(SUM(CASE WHEN date = CURRENT_DATE() THEN revenue ELSE 0 END), 0) as today_revenue,
      COALESCE(SUM(CASE WHEN date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) THEN revenue ELSE 0 END), 0) as yesterday_revenue,
      COALESCE(SUM(CASE WHEN date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN revenue ELSE 0 END), 0) as last_7_days_revenue,
      COALESCE(SUM(CASE WHEN date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN revenue ELSE 0 END), 0) as last_30_days_revenue,
      COALESCE(SUM(CASE WHEN FORMAT_DATE('%Y-%m', date) = FORMAT_DATE('%Y-%m', CURRENT_DATE()) THEN revenue ELSE 0 END), 0) as current_month_revenue,
      COALESCE(SUM(CASE WHEN FORMAT_DATE('%Y-%m', date) = FORMAT_DATE('%Y-%m', DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH)) THEN revenue ELSE 0 END), 0) as last_month_revenue,
      COALESCE(AVG(CASE WHEN date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) THEN revenue END), 0) as avg_daily_revenue
    FROM daily_revenue
  `;

  const [rows] = await bigquery.query(query);
  const row = rows[0];

  const todayRevenue = parseFloat(row.today_revenue);
  const yesterdayRevenue = parseFloat(row.yesterday_revenue);
  const last7DaysRevenue = parseFloat(row.last_7_days_revenue);
  const last30DaysRevenue = parseFloat(row.last_30_days_revenue);
  const currentMonthRevenue = parseFloat(row.current_month_revenue);
  const lastMonthRevenue = parseFloat(row.last_month_revenue);
  const avgDailyRevenue = parseFloat(row.avg_daily_revenue);

  // Calculate growth rates
  const growthRate7d = yesterdayRevenue > 0
    ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100
    : 0;

  const growthRate30d = lastMonthRevenue > 0
    ? ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
    : 0;

  return {
    todayRevenue,
    yesterdayRevenue,
    last7DaysRevenue,
    last30DaysRevenue,
    currentMonthRevenue,
    lastMonthRevenue,
    growthRate7d,
    growthRate30d,
    avgDailyRevenue,
  };
}

/**
 * Export revenue data to CSV
 */
export const exportRevenueData = functions.https.onCall(
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
        'Only admins can export revenue data'
      );
    }

    const { startDate, endDate, format } = data;

    try {
      const query = `
        SELECT
          event_id,
          user_id,
          event_type,
          event_timestamp,
          revenue_amount,
          currency,
          platform,
          subscription_tier,
          country,
          acquisition_channel
        FROM \`${DATASET_ID}.revenue_events\`
        WHERE DATE(event_timestamp) >= @startDate
          AND DATE(event_timestamp) <= @endDate
        ORDER BY event_timestamp DESC
      `;

      const [rows] = await bigquery.query({
        query,
        params: { startDate, endDate },
      });

      return {
        data: rows,
        count: rows.length,
      };
    } catch (error: any) {
      console.error('Error exporting revenue data:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  }
);
