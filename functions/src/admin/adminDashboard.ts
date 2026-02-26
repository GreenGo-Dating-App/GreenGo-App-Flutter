/**
 * Admin Dashboard Cloud Functions
 * Points 228-235: Dashboard analytics and monitoring
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

/**
 * Verify Admin Permission
 * Helper function to check if user has required permission
 */
async function verifyAdminPermission(
  context: functions.https.CallableContext,
  requiredPermission: string
): Promise<void> {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const customClaims = context.auth.token;

  // Check if user has admin role
  if (!customClaims.admin && !customClaims.moderator && !customClaims.support && !customClaims.analyst) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'User does not have admin access'
    );
  }

  // Check specific permission
  const adminDoc = await firestore.collection('admins').doc(context.auth.uid).get();
  if (!adminDoc.exists) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin profile not found'
    );
  }

  const permissions = adminDoc.data()!.permissions || [];
  if (!permissions.includes(requiredPermission)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      `Missing required permission: ${requiredPermission}`
    );
  }
}

/**
 * Log Admin Action
 * Point 235: Audit log for all admin actions
 */
async function logAdminAction(
  adminId: string,
  action: string,
  targetType: string,
  targetId: string,
  details: any,
  ipAddress?: string
): Promise<void> {
  const adminDoc = await firestore.collection('admins').doc(adminId).get();
  const adminData = adminDoc.data();

  await firestore.collection('admin_audit_log').add({
    adminId,
    adminEmail: adminData?.email || 'unknown',
    adminRole: adminData?.role || 'unknown',
    action,
    targetType,
    targetId,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    ipAddress: ipAddress || null,
  });
}

/**
 * Get User Activity Metrics
 * Point 228: Real-time user activity
 */
export const getUserActivityMetrics = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  try {
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Active users (online in last 5 minutes)
    const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
    const activeNowSnapshot = await firestore
      .collection('users')
      .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(fiveMinutesAgo))
      .where('accountStatus', '==', 'active')
      .count()
      .get();

    // Active today
    const activeTodaySnapshot = await firestore
      .collection('users')
      .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .where('accountStatus', '==', 'active')
      .count()
      .get();

    // Active this week
    const activeWeekSnapshot = await firestore
      .collection('users')
      .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .where('accountStatus', '==', 'active')
      .count()
      .get();

    // Active this month
    const activeMonthSnapshot = await firestore
      .collection('users')
      .where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .where('accountStatus', '==', 'active')
      .count()
      .get();

    // New signups today
    const signupsTodaySnapshot = await firestore
      .collection('users')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    // New signups week
    const signupsWeekSnapshot = await firestore
      .collection('users')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    // New signups month
    const signupsMonthSnapshot = await firestore
      .collection('users')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Deleted accounts today
    const deletedTodaySnapshot = await firestore
      .collection('users')
      .where('accountStatus', '==', 'deleted')
      .where('deletedAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    // Deleted accounts week
    const deletedWeekSnapshot = await firestore
      .collection('users')
      .where('accountStatus', '==', 'deleted')
      .where('deletedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    // Deleted accounts month
    const deletedMonthSnapshot = await firestore
      .collection('users')
      .where('accountStatus', '==', 'deleted')
      .where('deletedAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    return {
      activeUsersNow: activeNowSnapshot.data().count,
      activeUsersToday: activeTodaySnapshot.data().count,
      activeUsersWeek: activeWeekSnapshot.data().count,
      activeUsersMonth: activeMonthSnapshot.data().count,
      newSignupsToday: signupsTodaySnapshot.data().count,
      newSignupsWeek: signupsWeekSnapshot.data().count,
      newSignupsMonth: signupsMonthSnapshot.data().count,
      deletedAccountsToday: deletedTodaySnapshot.data().count,
      deletedAccountsWeek: deletedWeekSnapshot.data().count,
      deletedAccountsMonth: deletedMonthSnapshot.data().count,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('Error getting user activity metrics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get User Growth Chart
 * Point 229: User growth visualization
 */
export const getUserGrowthChart = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  const { period = 'daily', days = 30 } = data;

  try {
    const now = new Date();
    const startDate = new Date(now.getTime() - days * 24 * 60 * 60 * 1000);

    const dataPoints = [];
    let currentDate = new Date(startDate);

    while (currentDate <= now) {
      const nextDate = new Date(currentDate);
      nextDate.setDate(nextDate.getDate() + 1);

      // Get signups for this day
      const signupsSnapshot = await firestore
        .collection('users')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(currentDate))
        .where('createdAt', '<', admin.firestore.Timestamp.fromDate(nextDate))
        .count()
        .get();

      // Get deletions for this day
      const deletionsSnapshot = await firestore
        .collection('users')
        .where('accountStatus', '==', 'deleted')
        .where('deletedAt', '>=', admin.firestore.Timestamp.fromDate(currentDate))
        .where('deletedAt', '<', admin.firestore.Timestamp.fromDate(nextDate))
        .count()
        .get();

      const newSignups = signupsSnapshot.data().count;
      const deletedAccounts = deletionsSnapshot.data().count;
      const netGrowth = newSignups - deletedAccounts;

      dataPoints.push({
        date: currentDate.toISOString(),
        newSignups,
        deletedAccounts,
        netGrowth,
      });

      currentDate.setDate(currentDate.getDate() + 1);
    }

    // Calculate growth rate
    const firstPoint = dataPoints[0];
    const lastPoint = dataPoints[dataPoints.length - 1];
    const totalGrowth = dataPoints.reduce((sum, point) => sum + point.netGrowth, 0);
    const growthRate = firstPoint.newSignups > 0
      ? ((lastPoint.newSignups - firstPoint.newSignups) / firstPoint.newSignups) * 100
      : 0;

    // Determine trend
    let trend = 'stable';
    if (growthRate > 5) trend = 'increasing';
    else if (growthRate < -5) trend = 'decreasing';

    return {
      dailyData: dataPoints,
      growthRate,
      trend,
      totalGrowth,
    };
  } catch (error: any) {
    console.error('Error getting user growth chart:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get Revenue Metrics
 * Point 230: Revenue dashboard
 */
export const getRevenueMetrics = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  try {
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);

    // Active subscriptions
    const activeSubsSnapshot = await firestore
      .collection('subscriptions')
      .where('status', '==', 'active')
      .get();

    const activeSubscriptions = activeSubsSnapshot.docs.map(doc => doc.data());
    const activeSubscriberCount = activeSubscriptions.length;

    // Calculate revenue by tier
    const revenueByTier: { [key: string]: number } = {
      Silver: 0,
      Gold: 0,
      Platinum: 0,
    };

    let mrr = 0; // Monthly Recurring Revenue

    activeSubscriptions.forEach(sub => {
      const monthlyPrice = calculateMonthlyPrice(sub.tier, sub.billingPeriod);
      mrr += monthlyPrice;
      revenueByTier[sub.tier] = (revenueByTier[sub.tier] || 0) + monthlyPrice;
    });

    const arr = mrr * 12; // Annual Recurring Revenue

    // Get revenue for different periods
    const todayRevenue = await calculateRevenueForPeriod(oneDayAgo, now);
    const weekRevenue = await calculateRevenueForPeriod(oneWeekAgo, now);
    const monthRevenue = await calculateRevenueForPeriod(oneMonthAgo, now);
    const yearRevenue = await calculateRevenueForPeriod(oneYearAgo, now);

    // New subscribers
    const newSubsTodaySnapshot = await firestore
      .collection('subscriptions')
      .where('purchaseDate', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    const newSubsWeekSnapshot = await firestore
      .collection('subscriptions')
      .where('purchaseDate', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const newSubsMonthSnapshot = await firestore
      .collection('subscriptions')
      .where('purchaseDate', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Churned subscribers
    const churnedTodaySnapshot = await firestore
      .collection('subscriptions')
      .where('status', 'in', ['canceled', 'expired'])
      .where('canceledAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    const churnedWeekSnapshot = await firestore
      .collection('subscriptions')
      .where('status', 'in', ['canceled', 'expired'])
      .where('canceledAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const churnedMonthSnapshot = await firestore
      .collection('subscriptions')
      .where('status', 'in', ['canceled', 'expired'])
      .where('canceledAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Calculate churn rate
    const churnRate = activeSubscriberCount > 0
      ? (churnedMonthSnapshot.data().count / activeSubscriberCount) * 100
      : 0;

    return {
      todayRevenue,
      weekRevenue,
      monthRevenue,
      yearRevenue,
      mrr,
      arr,
      activeSubscribers: activeSubscriberCount,
      newSubscribersToday: newSubsTodaySnapshot.data().count,
      newSubscribersWeek: newSubsWeekSnapshot.data().count,
      newSubscribersMonth: newSubsMonthSnapshot.data().count,
      churnedSubscribersToday: churnedTodaySnapshot.data().count,
      churnedSubscribersWeek: churnedWeekSnapshot.data().count,
      churnedSubscribersMonth: churnedMonthSnapshot.data().count,
      churnRate,
      revenueByTier,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('Error getting revenue metrics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Calculate monthly price based on tier and billing period
 */
function calculateMonthlyPrice(tier: string, billingPeriod: string): number {
  const prices: { [key: string]: { [key: string]: number } } = {
    Silver: { monthly: 9.99, quarterly: 24.99, annual: 89.99 },
    Gold: { monthly: 19.99, quarterly: 49.99, annual: 179.99 },
    Platinum: { monthly: 29.99, quarterly: 74.99, annual: 269.99 },
  };

  const price = prices[tier]?.[billingPeriod] || 0;

  if (billingPeriod === 'quarterly') {
    return price / 3; // Convert to monthly
  } else if (billingPeriod === 'annual') {
    return price / 12; // Convert to monthly
  }

  return price;
}

/**
 * Calculate revenue for a specific time period
 */
async function calculateRevenueForPeriod(startDate: Date, endDate: Date): Promise<number> {
  const paymentsSnapshot = await firestore
    .collection('payment_history')
    .where('paidAt', '>=', admin.firestore.Timestamp.fromDate(startDate))
    .where('paidAt', '<', admin.firestore.Timestamp.fromDate(endDate))
    .where('status', '==', 'completed')
    .get();

  return paymentsSnapshot.docs.reduce((total, doc) => {
    return total + (doc.data().amount || 0);
  }, 0);
}

/**
 * Get Engagement Metrics
 * Point 231: Engagement dashboard
 */
export const getEngagementMetrics = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  try {
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    // Messages
    const messagesTodaySnapshot = await firestore
      .collection('messages')
      .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    const messagesWeekSnapshot = await firestore
      .collection('messages')
      .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const messagesMonthSnapshot = await firestore
      .collection('messages')
      .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Matches
    const matchesTodaySnapshot = await firestore
      .collection('matches')
      .where('matchedAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    const matchesWeekSnapshot = await firestore
      .collection('matches')
      .where('matchedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const matchesMonthSnapshot = await firestore
      .collection('matches')
      .where('matchedAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Likes
    const likesTodaySnapshot = await firestore
      .collection('likes')
      .where('likedAt', '>=', admin.firestore.Timestamp.fromDate(oneDayAgo))
      .count()
      .get();

    const likesWeekSnapshot = await firestore
      .collection('likes')
      .where('likedAt', '>=', admin.firestore.Timestamp.fromDate(oneWeekAgo))
      .count()
      .get();

    const likesMonthSnapshot = await firestore
      .collection('likes')
      .where('likedAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .count()
      .get();

    // Feature usage
    const featureUsage: { [key: string]: number } = {};
    const coinTransactionsSnapshot = await firestore
      .collection('coin_transactions')
      .where('transactionDate', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .where('type', '==', 'debit')
      .get();

    coinTransactionsSnapshot.docs.forEach(doc => {
      const reason = doc.data().reason;
      featureUsage[reason] = (featureUsage[reason] || 0) + 1;
    });

    // Get total user count for averages
    const totalUsersSnapshot = await firestore
      .collection('users')
      .where('accountStatus', '==', 'active')
      .count()
      .get();

    const totalUsers = totalUsersSnapshot.data().count;

    return {
      messagesToday: messagesTodaySnapshot.data().count,
      messagesWeek: messagesWeekSnapshot.data().count,
      messagesMonth: messagesMonthSnapshot.data().count,
      matchesToday: matchesTodaySnapshot.data().count,
      matchesWeek: matchesWeekSnapshot.data().count,
      matchesMonth: matchesMonthSnapshot.data().count,
      likesToday: likesTodaySnapshot.data().count,
      likesWeek: likesWeekSnapshot.data().count,
      likesMonth: likesMonthSnapshot.data().count,
      avgMessagesPerUser: totalUsers > 0 ? messagesMonthSnapshot.data().count / totalUsers : 0,
      avgMatchesPerUser: totalUsers > 0 ? matchesMonthSnapshot.data().count / totalUsers : 0,
      featureUsage,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('Error getting engagement metrics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get Geographic Heatmap
 * Point 232: User distribution map
 */
export const getGeographicHeatmap = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  try {
    const usersSnapshot = await firestore
      .collection('users')
      .where('accountStatus', '==', 'active')
      .select('location', 'latitude', 'longitude', 'lastActiveAt')
      .get();

    const locationCounts: { [key: string]: any } = {};
    const now = new Date();
    const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);

    usersSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const location = data.location || 'Unknown';
      const isActive = data.lastActiveAt && data.lastActiveAt.toDate() > oneDayAgo;

      if (!locationCounts[location]) {
        locationCounts[location] = {
          country: location.split(',')[0]?.trim() || 'Unknown',
          city: location.split(',')[1]?.trim() || null,
          latitude: data.latitude || 0,
          longitude: data.longitude || 0,
          userCount: 0,
          activeUserCount: 0,
        };
      }

      locationCounts[location].userCount++;
      if (isActive) {
        locationCounts[location].activeUserCount++;
      }
    });

    // Convert to array and calculate intensity
    const locations = Object.values(locationCounts);
    const maxUsers = Math.max(...locations.map((loc: any) => loc.userCount));

    const locationsWithIntensity = locations.map((loc: any) => ({
      ...loc,
      intensity: loc.userCount / maxUsers,
    }));

    // Find top country and city
    const sortedByCount = [...locationsWithIntensity].sort(
      (a: any, b: any) => b.userCount - a.userCount
    );

    return {
      locations: locationsWithIntensity,
      topCountry: sortedByCount[0]?.country || 'Unknown',
      topCity: sortedByCount[0]?.city || 'Unknown',
      totalCountries: new Set(locations.map((loc: any) => loc.country)).size,
      totalCities: locations.length,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('Error getting geographic heatmap:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get System Health Metrics
 * Point 233: System monitoring
 */
export const getSystemHealthMetrics = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  try {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);

    // Get API logs from last hour
    const logsSnapshot = await firestore
      .collection('api_logs')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(oneHourAgo))
      .get();

    let totalRequests = 0;
    let failedRequests = 0;
    let totalResponseTime = 0;
    const endpointStats: { [key: string]: any } = {};

    logsSnapshot.docs.forEach(doc => {
      const log = doc.data();
      totalRequests++;

      if (log.statusCode >= 400) {
        failedRequests++;
      }

      totalResponseTime += log.responseTime || 0;

      // Track by endpoint
      const endpoint = log.endpoint || 'unknown';
      if (!endpointStats[endpoint]) {
        endpointStats[endpoint] = {
          totalRequests: 0,
          failedRequests: 0,
          totalResponseTime: 0,
        };
      }

      endpointStats[endpoint].totalRequests++;
      if (log.statusCode >= 400) {
        endpointStats[endpoint].failedRequests++;
      }
      endpointStats[endpoint].totalResponseTime += log.responseTime || 0;
    });

    const avgResponseTime = totalRequests > 0 ? totalResponseTime / totalRequests : 0;
    const errorRate = totalRequests > 0 ? (failedRequests / totalRequests) * 100 : 0;
    const successRate = 100 - errorRate;

    // Build endpoint health
    const endpointHealth: { [key: string]: any } = {};
    Object.keys(endpointStats).forEach(endpoint => {
      const stats = endpointStats[endpoint];
      const avgTime = stats.totalRequests > 0
        ? stats.totalResponseTime / stats.totalRequests
        : 0;
      const errRate = stats.totalRequests > 0
        ? (stats.failedRequests / stats.totalRequests) * 100
        : 0;

      let status = 'healthy';
      if (errRate > 10 || avgTime > 2000) status = 'critical';
      else if (errRate > 5 || avgTime > 1000) status = 'degraded';

      endpointHealth[endpoint] = {
        endpoint,
        avgResponseTime: avgTime,
        errorRate: errRate,
        requestCount: stats.totalRequests,
        status,
      };
    });

    // Get active alerts
    const alertsSnapshot = await firestore
      .collection('system_alerts')
      .where('isResolved', '==', false)
      .orderBy('triggeredAt', 'desc')
      .get();

    const activeAlerts = alertsSnapshot.docs.map(doc => doc.data());

    // Determine overall system status
    let systemStatus = 'healthy';
    if (errorRate > 20 || avgResponseTime > 3000) systemStatus = 'critical';
    else if (errorRate > 10 || avgResponseTime > 1500) systemStatus = 'degraded';

    return {
      apiResponseTime: avgResponseTime,
      errorRate,
      successRate,
      totalRequests,
      failedRequests,
      endpointHealth,
      activeAlerts,
      status: systemStatus,
      calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
  } catch (error: any) {
    console.error('Error getting system health metrics:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Create System Alert
 * Point 234: Alert creation and management
 */
export const createSystemAlert = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  const { title, description, type, severity, metadata = {} } = data;

  try {
    const alertRef = firestore.collection('system_alerts').doc();
    await alertRef.set({
      alertId: alertRef.id,
      title,
      description,
      type,
      severity,
      triggeredAt: admin.firestore.FieldValue.serverTimestamp(),
      resolvedAt: null,
      isResolved: false,
      resolvedBy: null,
      metadata,
    });

    return {
      alertId: alertRef.id,
      success: true,
    };
  } catch (error: any) {
    console.error('Error creating system alert:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Resolve System Alert
 * Point 234: Alert resolution
 */
export const resolveSystemAlert = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewDashboard');

  const { alertId } = data;
  const adminId = context.auth!.uid;

  try {
    await firestore.collection('system_alerts').doc(alertId).update({
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      isResolved: true,
      resolvedBy: adminId,
    });

    await logAdminAction(
      adminId,
      'resolvedAlert',
      'system_alert',
      alertId,
      { alertId }
    );

    return { success: true };
  } catch (error: any) {
    console.error('Error resolving system alert:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get Admin Audit Log
 * Point 235: View audit log
 */
export const getAdminAuditLog = functions.https.onCall(async (data, context) => {
  await verifyAdminPermission(context, 'viewAuditLog');

  const { limit = 100, offset = 0, adminId = null, action = null } = data;

  try {
    let query: any = firestore
      .collection('admin_audit_log')
      .orderBy('timestamp', 'desc');

    if (adminId) {
      query = query.where('adminId', '==', adminId);
    }

    if (action) {
      query = query.where('action', '==', action);
    }

    const snapshot = await query.limit(limit).offset(offset).get();

    const logs = snapshot.docs.map(doc => doc.data());

    return {
      logs,
      total: snapshot.size,
    };
  } catch (error: any) {
    console.error('Error getting audit log:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
