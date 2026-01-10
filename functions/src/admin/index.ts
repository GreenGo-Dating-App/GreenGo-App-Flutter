/**
 * Admin Service
 * 25+ Cloud Functions for admin dashboard, user management, and moderation
 */

import { onCall } from 'firebase-functions/v2/https';
import { verifyAdminAuth, handleError, logInfo, logError, db, FieldValue } from '../shared/utils';
import * as admin from 'firebase-admin';
import { SubscriptionTier, UserRole, ReportStatus } from '../shared/types';

// Interfaces
interface GetDashboardStatsRequest {
  period?: 'today' | 'week' | 'month' | 'year' | 'all';
}

interface GetUserGrowthRequest {
  startDate: string;
  endDate: string;
  interval?: 'day' | 'week' | 'month';
}

interface GetRevenueStatsRequest {
  startDate: string;
  endDate: string;
}

interface GetActiveUsersRequest {
  period?: 'today' | 'week' | 'month';
}

interface GetTopMatchmakersRequest {
  limit?: number;
  period?: string;
}

interface GetChurnRiskUsersRequest {
  limit?: number;
}

interface GetConversionFunnelRequest {
  startDate: string;
  endDate: string;
}

interface ExportDashboardDataRequest {
  type: 'users' | 'revenue' | 'activity' | 'reports';
  startDate?: string;
  endDate?: string;
  format?: 'csv' | 'json';
}

interface GetSystemHealthRequest {
  includeMetrics?: boolean;
}

interface AssignRoleRequest {
  userId: string;
  role: UserRole;
}

interface RevokeRoleRequest {
  userId: string;
}

interface GetAdminUsersRequest {
  limit?: number;
}

interface GetRoleHistoryRequest {
  userId: string;
}

interface CreateAdminInviteRequest {
  email: string;
  role: UserRole;
  expiresInDays?: number;
}

interface AcceptAdminInviteRequest {
  inviteCode: string;
}

interface SuspendUserRequest {
  userId: string;
  reason: string;
  duration?: number; // in days
  notify?: boolean;
}

interface ReactivateUserRequest {
  userId: string;
  notify?: boolean;
}

interface DeleteUserRequest {
  userId: string;
  reason: string;
  hardDelete?: boolean;
}

interface ImpersonateUserRequest {
  userId: string;
  reason: string;
}

interface SearchUsersRequest {
  query?: string;
  filters?: {
    tier?: SubscriptionTier;
    status?: string;
    verified?: boolean;
  };
  limit?: number;
  startAfter?: string;
}

interface GetUserDetailsRequest {
  userId: string;
}

interface UpdateUserProfileRequest {
  userId: string;
  updates: Record<string, any>;
}

interface BanUserRequest {
  userId: string;
  reason: string;
  permanent?: boolean;
  banDuration?: number; // in days
}

interface UnbanUserRequest {
  userId: string;
}

interface GetBannedUsersRequest {
  limit?: number;
  startAfter?: string;
}

interface GetModerationQueueRequest {
  status?: ReportStatus;
  priority?: 'high' | 'medium' | 'low';
  limit?: number;
}

interface ProcessReportRequest {
  reportId: string;
  action: 'dismiss' | 'warn' | 'suspend' | 'ban';
  notes?: string;
}

interface BulkProcessReportsRequest {
  reportIds: string[];
  action: 'dismiss' | 'warn' | 'suspend' | 'ban';
  notes?: string;
}

interface GetReportDetailsRequest {
  reportId: string;
}

interface AssignModeratorRequest {
  reportId: string;
  moderatorId: string;
}

interface GetModeratorStatsRequest {
  moderatorId?: string;
  period?: string;
}

// ========== DASHBOARD FUNCTIONS ==========

// 1. Get Dashboard Stats
export const getDashboardStats = onCall<GetDashboardStatsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { period = 'month' } = request.data;

      logInfo(`Fetching dashboard stats for period: ${period}`);

      const now = new Date();
      let startDate: Date;

      switch (period) {
        case 'today':
          startDate = new Date(now.setHours(0, 0, 0, 0));
          break;
        case 'week':
          startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
          break;
        case 'month':
          startDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
          break;
        case 'year':
          startDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
          break;
        default:
          startDate = new Date(0); // All time
      }

      const startTimestamp = admin.firestore.Timestamp.fromDate(startDate);

      // Get user stats
      const usersSnapshot = await db.collection('users').where('createdAt', '>=', startTimestamp).get();
      const totalNewUsers = usersSnapshot.size;

      const allUsersSnapshot = await db.collection('users').get();
      const totalUsers = allUsersSnapshot.size;

      // Get active users (last 7 days)
      const sevenDaysAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000));
      const activeUsersSnapshot = await db.collection('users').where('lastActiveAt', '>=', sevenDaysAgo).get();
      const activeUsers = activeUsersSnapshot.size;

      // Get subscription stats
      const subscriptionsSnapshot = await db.collection('subscriptions').where('status', '==', 'active').get();
      const activeSubscriptions = subscriptionsSnapshot.size;

      let mrr = 0; // Monthly Recurring Revenue
      subscriptionsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.tier === SubscriptionTier.SILVER) mrr += 9.99;
        if (data.tier === SubscriptionTier.GOLD) mrr += 19.99;
      });

      // Get match stats
      const matchesSnapshot = await db.collection('matches').where('createdAt', '>=', startTimestamp).get();
      const totalMatches = matchesSnapshot.size;

      // Get message stats
      const messagesSnapshot = await db.collection('messages').where('createdAt', '>=', startTimestamp).get();
      const totalMessages = messagesSnapshot.size;

      // Get report stats
      const reportsSnapshot = await db.collection('reports').where('createdAt', '>=', startTimestamp).get();
      const totalReports = reportsSnapshot.size;
      const pendingReports = reportsSnapshot.docs.filter(d => d.data().status === ReportStatus.PENDING).length;

      return {
        success: true,
        stats: {
          users: {
            total: totalUsers,
            new: totalNewUsers,
            active: activeUsers,
            activeRate: (activeUsers / totalUsers * 100).toFixed(2) + '%',
          },
          revenue: {
            mrr: mrr.toFixed(2),
            activeSubscriptions,
          },
          engagement: {
            totalMatches,
            totalMessages,
            avgMessagesPerUser: (totalMessages / totalUsers).toFixed(2),
          },
          moderation: {
            totalReports,
            pendingReports,
          },
        },
      };
    } catch (error) {
      logError('Error fetching dashboard stats:', error);
      throw handleError(error);
    }
  }
);

// 2. Get User Growth
export const getUserGrowth = onCall<GetUserGrowthRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate, interval = 'day' } = request.data;

      logInfo(`Fetching user growth from ${startDate} to ${endDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const snapshot = await db
        .collection('users')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      // Group by interval
      const growthData: Record<string, number> = {};

      snapshot.docs.forEach(doc => {
        const createdAt = doc.data().createdAt.toDate();
        let key: string;

        if (interval === 'day') {
          key = createdAt.toISOString().split('T')[0];
        } else if (interval === 'week') {
          const weekStart = new Date(createdAt);
          weekStart.setDate(createdAt.getDate() - createdAt.getDay());
          key = weekStart.toISOString().split('T')[0];
        } else {
          key = createdAt.toISOString().substring(0, 7); // YYYY-MM
        }

        growthData[key] = (growthData[key] || 0) + 1;
      });

      return {
        success: true,
        growthData,
        totalNewUsers: snapshot.size,
      };
    } catch (error) {
      logError('Error fetching user growth:', error);
      throw handleError(error);
    }
  }
);

// 3. Get Revenue Stats
export const getRevenueStats = onCall<GetRevenueStatsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching revenue stats from ${startDate} to ${endDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      // Get subscriptions
      const subscriptionsSnapshot = await db
        .collection('subscriptions')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      let subscriptionRevenue = 0;
      const tierCounts = { silver: 0, gold: 0 };

      subscriptionsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        if (data.tier === SubscriptionTier.SILVER) {
          subscriptionRevenue += 9.99;
          tierCounts.silver++;
        }
        if (data.tier === SubscriptionTier.GOLD) {
          subscriptionRevenue += 19.99;
          tierCounts.gold++;
        }
      });

      // Get coin purchases
      const coinPurchasesSnapshot = await db
        .collection('coin_purchases')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      let coinRevenue = 0;
      coinPurchasesSnapshot.docs.forEach(doc => {
        coinRevenue += doc.data().amount || 0;
      });

      const totalRevenue = subscriptionRevenue + coinRevenue;

      return {
        success: true,
        revenue: {
          total: totalRevenue.toFixed(2),
          subscriptions: subscriptionRevenue.toFixed(2),
          coins: coinRevenue.toFixed(2),
          breakdown: {
            silver: tierCounts.silver,
            gold: tierCounts.gold,
          },
        },
      };
    } catch (error) {
      logError('Error fetching revenue stats:', error);
      throw handleError(error);
    }
  }
);

// 4. Get Active Users
export const getActiveUsers = onCall<GetActiveUsersRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { period = 'week' } = request.data;

      logInfo(`Fetching active users for period: ${period}`);

      const now = Date.now();
      let cutoff: number;

      switch (period) {
        case 'today':
          cutoff = now - 24 * 60 * 60 * 1000;
          break;
        case 'week':
          cutoff = now - 7 * 24 * 60 * 60 * 1000;
          break;
        case 'month':
          cutoff = now - 30 * 24 * 60 * 60 * 1000;
          break;
        default:
          cutoff = now - 7 * 24 * 60 * 60 * 1000;
      }

      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(new Date(cutoff));

      const snapshot = await db
        .collection('users')
        .where('lastActiveAt', '>=', cutoffTimestamp)
        .get();

      const totalUsers = (await db.collection('users').count().get()).data().count;

      return {
        success: true,
        activeUsers: snapshot.size,
        totalUsers,
        activeRate: ((snapshot.size / totalUsers) * 100).toFixed(2) + '%',
      };
    } catch (error) {
      logError('Error fetching active users:', error);
      throw handleError(error);
    }
  }
);

// 5. Get Top Matchmakers
export const getTopMatchmakers = onCall<GetTopMatchmakersRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { limit = 10 } = request.data;

      logInfo(`Fetching top ${limit} matchmakers`);

      const usersSnapshot = await db
        .collection('users')
        .orderBy('stats.totalMatches', 'desc')
        .limit(limit)
        .get();

      const topMatchmakers = usersSnapshot.docs.map(doc => ({
        userId: doc.id,
        displayName: doc.data().displayName,
        totalMatches: doc.data().stats?.totalMatches || 0,
        totalMessages: doc.data().stats?.totalMessages || 0,
      }));

      return {
        success: true,
        topMatchmakers,
      };
    } catch (error) {
      logError('Error fetching top matchmakers:', error);
      throw handleError(error);
    }
  }
);

// 6. Get Churn Risk Users
export const getChurnRiskUsers = onCall<GetChurnRiskUsersRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { limit = 50 } = request.data;

      logInfo(`Fetching ${limit} users at churn risk`);

      // Users who haven't been active in 14+ days but were active before
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
      };
    } catch (error) {
      logError('Error fetching churn risk users:', error);
      throw handleError(error);
    }
  }
);

// 7. Get Conversion Funnel
export const getConversionFunnel = onCall<GetConversionFunnelRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { startDate, endDate } = request.data;

      logInfo(`Fetching conversion funnel from ${startDate} to ${endDate}`);

      const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
      const end = admin.firestore.Timestamp.fromDate(new Date(endDate));

      const usersSnapshot = await db
        .collection('users')
        .where('createdAt', '>=', start)
        .where('createdAt', '<=', end)
        .get();

      const signups = usersSnapshot.size;
      let profileCompleted = 0;
      let firstMatch = 0;
      let firstMessage = 0;
      let subscribed = 0;

      for (const doc of usersSnapshot.docs) {
        const data = doc.data();
        if (data.profileCompleteness >= 100) profileCompleted++;
        if (data.stats?.totalMatches > 0) firstMatch++;
        if (data.stats?.totalMessages > 0) firstMessage++;
        if (data.subscriptionTier !== SubscriptionTier.BASIC) subscribed++;
      }

      return {
        success: true,
        funnel: {
          signups,
          profileCompleted,
          firstMatch,
          firstMessage,
          subscribed,
          conversionRates: {
            profileCompletion: ((profileCompleted / signups) * 100).toFixed(2) + '%',
            firstMatch: ((firstMatch / signups) * 100).toFixed(2) + '%',
            firstMessage: ((firstMessage / signups) * 100).toFixed(2) + '%',
            subscription: ((subscribed / signups) * 100).toFixed(2) + '%',
          },
        },
      };
    } catch (error) {
      logError('Error fetching conversion funnel:', error);
      throw handleError(error);
    }
  }
);

// 8. Export Dashboard Data
export const exportDashboardData = onCall<ExportDashboardDataRequest>(
  {
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { type, startDate, endDate, format = 'csv' } = request.data;

      logInfo(`Exporting ${type} data as ${format}`);

      // This would generate CSV/JSON exports
      // For now, return a placeholder

      return {
        success: true,
        exportUrl: `https://storage.googleapis.com/exports/${type}_${Date.now()}.${format}`,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      };
    } catch (error) {
      logError('Error exporting dashboard data:', error);
      throw handleError(error);
    }
  }
);

// 9. Get System Health
export const getSystemHealth = onCall<GetSystemHealthRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);

      logInfo('Fetching system health');

      // Check various system metrics
      const userCount = (await db.collection('users').count().get()).data().count;
      const messageCount = (await db.collection('messages').count().get()).data().count;
      const pendingReportsCount = (await db.collection('reports').where('status', '==', ReportStatus.PENDING).count().get()).data().count;

      return {
        success: true,
        health: {
          status: 'healthy',
          metrics: {
            totalUsers: userCount,
            totalMessages: messageCount,
            pendingReports: pendingReportsCount,
          },
          timestamp: new Date().toISOString(),
        },
      };
    } catch (error) {
      logError('Error fetching system health:', error);
      throw handleError(error);
    }
  }
);

// ========== ROLE MANAGEMENT FUNCTIONS ==========

// 10. Assign Role
export const assignRole = onCall<AssignRoleRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, role } = request.data;

      logInfo(`Assigning role ${role} to user ${userId}`);

      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const previousRole = userDoc.data()?.role;

      await userRef.update({
        role,
        previousRole,
        roleChangedAt: FieldValue.serverTimestamp(),
        roleChangedBy: request.auth?.uid,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Log role change
      await db.collection('audit_logs').add({
        type: 'role_change',
        userId,
        performedBy: request.auth?.uid,
        previousRole,
        newRole: role,
        timestamp: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error assigning role:', error);
      throw handleError(error);
    }
  }
);

// 11. Revoke Role
export const revokeRole = onCall<RevokeRoleRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId } = request.data;

      logInfo(`Revoking admin role from user ${userId}`);

      const userRef = db.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      const previousRole = userDoc.data()?.role;

      await userRef.update({
        role: UserRole.USER,
        previousRole,
        roleChangedAt: FieldValue.serverTimestamp(),
        roleChangedBy: request.auth?.uid,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error revoking role:', error);
      throw handleError(error);
    }
  }
);

// 12. Get Admin Users
export const getAdminUsers = onCall<GetAdminUsersRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { limit = 50 } = request.data;

      logInfo('Fetching admin users');

      const snapshot = await db
        .collection('users')
        .where('role', '==', UserRole.ADMIN)
        .limit(limit)
        .get();

      const admins = snapshot.docs.map(doc => ({
        userId: doc.id,
        email: doc.data().email,
        displayName: doc.data().displayName,
        role: doc.data().role,
        roleChangedAt: doc.data().roleChangedAt?.toDate().toISOString(),
      }));

      return {
        success: true,
        admins,
      };
    } catch (error) {
      logError('Error fetching admin users:', error);
      throw handleError(error);
    }
  }
);

// 13. Get Role History
export const getRoleHistory = onCall<GetRoleHistoryRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId } = request.data;

      logInfo(`Fetching role history for user ${userId}`);

      const snapshot = await db
        .collection('audit_logs')
        .where('type', '==', 'role_change')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .get();

      const history = snapshot.docs.map(doc => doc.data());

      return {
        success: true,
        history,
      };
    } catch (error) {
      logError('Error fetching role history:', error);
      throw handleError(error);
    }
  }
);

// 14. Create Admin Invite
export const createAdminInvite = onCall<CreateAdminInviteRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { email, role, expiresInDays = 7 } = request.data;

      logInfo(`Creating admin invite for ${email}`);

      const inviteCode = Math.random().toString(36).substring(2, 15);
      const expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000);

      await db.collection('admin_invites').add({
        email,
        role,
        inviteCode,
        createdBy: request.auth?.uid,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        used: false,
        createdAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        inviteCode,
        expiresAt: expiresAt.toISOString(),
      };
    } catch (error) {
      logError('Error creating admin invite:', error);
      throw handleError(error);
    }
  }
);

// 15. Accept Admin Invite
export const acceptAdminInvite = onCall<AcceptAdminInviteRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = request.auth?.uid;
      if (!uid) throw new Error('Not authenticated');

      const { inviteCode } = request.data;

      logInfo(`Accepting admin invite: ${inviteCode}`);

      const inviteSnapshot = await db
        .collection('admin_invites')
        .where('inviteCode', '==', inviteCode)
        .limit(1)
        .get();

      if (inviteSnapshot.empty) {
        throw new Error('Invalid invite code');
      }

      const inviteDoc = inviteSnapshot.docs[0];
      const inviteData = inviteDoc.data();

      if (inviteData.used) {
        throw new Error('Invite already used');
      }

      if (inviteData.expiresAt.toMillis() < Date.now()) {
        throw new Error('Invite expired');
      }

      // Update user role
      await db.collection('users').doc(uid).update({
        role: inviteData.role,
        roleChangedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Mark invite as used
      await inviteDoc.ref.update({
        used: true,
        usedBy: uid,
        usedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error accepting admin invite:', error);
      throw handleError(error);
    }
  }
);

// ========== USER MANAGEMENT FUNCTIONS ==========

// 16. Suspend User
export const suspendUser = onCall<SuspendUserRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, reason, duration, notify = true } = request.data;

      logInfo(`Suspending user ${userId}`);

      const suspendedUntil = duration
        ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + duration * 24 * 60 * 60 * 1000))
        : null;

      await db.collection('users').doc(userId).update({
        accountStatus: 'suspended',
        suspendedAt: FieldValue.serverTimestamp(),
        suspendedBy: request.auth?.uid,
        suspensionReason: reason,
        suspendedUntil,
        updatedAt: FieldValue.serverTimestamp(),
      });

      if (notify) {
        await db.collection('notifications').add({
          userId,
          type: 'account_suspended',
          title: 'Account Suspended',
          body: `Your account has been suspended. Reason: ${reason}`,
          read: false,
          sent: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      return { success: true };
    } catch (error) {
      logError('Error suspending user:', error);
      throw handleError(error);
    }
  }
);

// 17. Reactivate User
export const reactivateUser = onCall<ReactivateUserRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, notify = true } = request.data;

      logInfo(`Reactivating user ${userId}`);

      await db.collection('users').doc(userId).update({
        accountStatus: 'active',
        reactivatedAt: FieldValue.serverTimestamp(),
        reactivatedBy: request.auth?.uid,
        updatedAt: FieldValue.serverTimestamp(),
      });

      if (notify) {
        await db.collection('notifications').add({
          userId,
          type: 'account_reactivated',
          title: 'Account Reactivated',
          body: 'Your account has been reactivated',
          read: false,
          sent: false,
          createdAt: FieldValue.serverTimestamp(),
        });
      }

      return { success: true };
    } catch (error) {
      logError('Error reactivating user:', error);
      throw handleError(error);
    }
  }
);

// 18. Delete User Account
export const deleteUserAccount = onCall<DeleteUserRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, reason, hardDelete = false } = request.data;

      logInfo(`Deleting user ${userId} (hard: ${hardDelete})`);

      if (hardDelete) {
        // Hard delete - permanently remove all data
        await admin.auth().deleteUser(userId);
        await db.collection('users').doc(userId).delete();
        // Would also delete related data in production
      } else {
        // Soft delete - mark as deleted but keep data
        await db.collection('users').doc(userId).update({
          accountStatus: 'deleted',
          deletedAt: FieldValue.serverTimestamp(),
          deletedBy: request.auth?.uid,
          deletionReason: reason,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      return { success: true };
    } catch (error) {
      logError('Error deleting user:', error);
      throw handleError(error);
    }
  }
);

// 19. Impersonate User
export const impersonateUser = onCall<ImpersonateUserRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, reason } = request.data;

      logInfo(`Admin ${request.auth?.uid} impersonating user ${userId}`);

      // Log impersonation
      await db.collection('audit_logs').add({
        type: 'impersonation',
        adminId: request.auth?.uid,
        targetUserId: userId,
        reason,
        timestamp: FieldValue.serverTimestamp(),
      });

      // Generate impersonation token (in production, this would be a custom token)
      const customToken = await admin.auth().createCustomToken(userId);

      return {
        success: true,
        token: customToken,
      };
    } catch (error) {
      logError('Error impersonating user:', error);
      throw handleError(error);
    }
  }
);

// 20. Search Users
export const searchUsers = onCall<SearchUsersRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { query, filters, limit = 50, startAfter } = request.data;

      logInfo(`Searching users: ${query}`);

      let queryRef = db.collection('users').limit(limit);

      if (filters?.tier) {
        queryRef = queryRef.where('subscriptionTier', '==', filters.tier) as any;
      }

      if (filters?.verified !== undefined) {
        queryRef = queryRef.where('verified', '==', filters.verified) as any;
      }

      if (startAfter) {
        const startDoc = await db.collection('users').doc(startAfter).get();
        if (startDoc.exists) {
          queryRef = queryRef.startAfter(startDoc) as any;
        }
      }

      const snapshot = await queryRef.get();

      let users = snapshot.docs.map(doc => ({
        userId: doc.id,
        ...(doc.data() as any),
      }));

      // Filter by query if provided
      if (query) {
        const lowerQuery = query.toLowerCase();
        users = users.filter((user: any) =>
          user.displayName?.toLowerCase().includes(lowerQuery) ||
          user.email?.toLowerCase().includes(lowerQuery)
        );
      }

      return {
        success: true,
        users,
        hasMore: snapshot.size === limit,
      };
    } catch (error) {
      logError('Error searching users:', error);
      throw handleError(error);
    }
  }
);

// 21. Get User Details
export const getUserDetails = onCall<GetUserDetailsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId } = request.data;

      logInfo(`Fetching details for user ${userId}`);

      const userDoc = await db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw new Error('User not found');
      }

      return {
        success: true,
        user: {
          userId: userDoc.id,
          ...userDoc.data(),
        },
      };
    } catch (error) {
      logError('Error fetching user details:', error);
      throw handleError(error);
    }
  }
);

// 22. Update User Profile
export const updateUserProfile = onCall<UpdateUserProfileRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, updates } = request.data;

      logInfo(`Updating profile for user ${userId}`);

      await db.collection('users').doc(userId).update({
        ...updates,
        updatedAt: FieldValue.serverTimestamp(),
        updatedBy: request.auth?.uid,
      });

      return { success: true };
    } catch (error) {
      logError('Error updating user profile:', error);
      throw handleError(error);
    }
  }
);

// 23. Ban User
export const banUser = onCall<BanUserRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId, reason, permanent = false, banDuration } = request.data;

      logInfo(`Banning user ${userId} (permanent: ${permanent})`);

      const bannedUntil = !permanent && banDuration
        ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + banDuration * 24 * 60 * 60 * 1000))
        : null;

      await db.collection('users').doc(userId).update({
        banned: true,
        bannedAt: FieldValue.serverTimestamp(),
        bannedBy: request.auth?.uid,
        banReason: reason,
        bannedUntil,
        permanentBan: permanent,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error banning user:', error);
      throw handleError(error);
    }
  }
);

// 24. Unban User
export const unbanUser = onCall<UnbanUserRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId } = request.data;

      logInfo(`Unbanning user ${userId}`);

      await db.collection('users').doc(userId).update({
        banned: false,
        unbannedAt: FieldValue.serverTimestamp(),
        unbannedBy: request.auth?.uid,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error unbanning user:', error);
      throw handleError(error);
    }
  }
);

// 25. Get Banned Users
export const getBannedUsers = onCall<GetBannedUsersRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { limit = 50, startAfter } = request.data;

      logInfo('Fetching banned users');

      let query = db.collection('users').where('banned', '==', true).limit(limit);

      if (startAfter) {
        const startDoc = await db.collection('users').doc(startAfter).get();
        if (startDoc.exists) {
          query = query.startAfter(startDoc);
        }
      }

      const snapshot = await query.get();

      const bannedUsers = snapshot.docs.map(doc => ({
        userId: doc.id,
        displayName: doc.data().displayName,
        email: doc.data().email,
        bannedAt: doc.data().bannedAt?.toDate().toISOString(),
        banReason: doc.data().banReason,
        permanentBan: doc.data().permanentBan,
      }));

      return {
        success: true,
        bannedUsers,
        hasMore: snapshot.size === limit,
      };
    } catch (error) {
      logError('Error fetching banned users:', error);
      throw handleError(error);
    }
  }
);

// ========== MODERATION QUEUE FUNCTIONS ==========

// 26. Get Moderation Queue
export const getModerationQueue = onCall<GetModerationQueueRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { status = ReportStatus.PENDING, priority, limit = 50 } = request.data;

      logInfo(`Fetching moderation queue (status: ${status})`);

      let query = db.collection('reports').where('status', '==', status).limit(limit);

      if (priority) {
        query = query.where('priority', '==', priority) as any;
      }

      const snapshot = await query.get();

      const reports = snapshot.docs.map(doc => ({
        reportId: doc.id,
        ...doc.data(),
      }));

      return {
        success: true,
        reports,
        totalCount: snapshot.size,
      };
    } catch (error) {
      logError('Error fetching moderation queue:', error);
      throw handleError(error);
    }
  }
);

// 27. Process Report
export const processReport = onCall<ProcessReportRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { reportId, action, notes } = request.data;

      logInfo(`Processing report ${reportId} with action: ${action}`);

      const reportRef = db.collection('reports').doc(reportId);
      const reportDoc = await reportRef.get();

      if (!reportDoc.exists) {
        throw new Error('Report not found');
      }

      const reportData = reportDoc.data()!;

      // Update report
      await reportRef.update({
        status: ReportStatus.RESOLVED,
        resolvedAt: FieldValue.serverTimestamp(),
        resolvedBy: request.auth?.uid,
        action,
        moderatorNotes: notes,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Take action on reported user
      const reportedUserId = reportData.reportedUserId;

      switch (action) {
        case 'warn':
          await db.collection('notifications').add({
            userId: reportedUserId,
            type: 'warning',
            title: 'Warning',
            body: 'Your content has been flagged for violating community guidelines',
            read: false,
            sent: false,
            createdAt: FieldValue.serverTimestamp(),
          });
          break;

        case 'suspend':
          await db.collection('users').doc(reportedUserId).update({
            accountStatus: 'suspended',
            suspendedAt: FieldValue.serverTimestamp(),
            suspensionReason: 'Community guidelines violation',
            updatedAt: FieldValue.serverTimestamp(),
          });
          break;

        case 'ban':
          await db.collection('users').doc(reportedUserId).update({
            banned: true,
            bannedAt: FieldValue.serverTimestamp(),
            banReason: 'Community guidelines violation',
            updatedAt: FieldValue.serverTimestamp(),
          });
          break;

        case 'dismiss':
          // No action needed
          break;
      }

      return { success: true };
    } catch (error) {
      logError('Error processing report:', error);
      throw handleError(error);
    }
  }
);

// 28. Bulk Process Reports
export const bulkProcessReports = onCall<BulkProcessReportsRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { reportIds, action, notes } = request.data;

      logInfo(`Bulk processing ${reportIds.length} reports with action: ${action}`);

      const batch = db.batch();

      for (const reportId of reportIds) {
        const reportRef = db.collection('reports').doc(reportId);
        batch.update(reportRef, {
          status: ReportStatus.RESOLVED,
          resolvedAt: FieldValue.serverTimestamp(),
          resolvedBy: request.auth?.uid,
          action,
          moderatorNotes: notes,
          updatedAt: FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return {
        success: true,
        processedCount: reportIds.length,
      };
    } catch (error) {
      logError('Error bulk processing reports:', error);
      throw handleError(error);
    }
  }
);

// 29. Get Report Details
export const getReportDetails = onCall<GetReportDetailsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { reportId } = request.data;

      logInfo(`Fetching report details: ${reportId}`);

      const reportDoc = await db.collection('reports').doc(reportId).get();

      if (!reportDoc.exists) {
        throw new Error('Report not found');
      }

      return {
        success: true,
        report: {
          reportId: reportDoc.id,
          ...reportDoc.data(),
        },
      };
    } catch (error) {
      logError('Error fetching report details:', error);
      throw handleError(error);
    }
  }
);

// 30. Assign Moderator
export const assignModerator = onCall<AssignModeratorRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { reportId, moderatorId } = request.data;

      logInfo(`Assigning moderator ${moderatorId} to report ${reportId}`);

      await db.collection('reports').doc(reportId).update({
        assignedTo: moderatorId,
        assignedAt: FieldValue.serverTimestamp(),
        status: ReportStatus.UNDER_REVIEW,
        updatedAt: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      logError('Error assigning moderator:', error);
      throw handleError(error);
    }
  }
);

// 31. Get Moderator Stats
export const getModeratorStats = onCall<GetModeratorStatsRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { moderatorId, period = 'month' } = request.data;

      const targetModeratorId = moderatorId || request.auth?.uid;

      logInfo(`Fetching moderator stats for ${targetModeratorId}`);

      const snapshot = await db
        .collection('reports')
        .where('resolvedBy', '==', targetModeratorId)
        .get();

      const stats = {
        totalResolved: snapshot.size,
        actionBreakdown: {
          dismissed: 0,
          warned: 0,
          suspended: 0,
          banned: 0,
        },
      };

      snapshot.docs.forEach(doc => {
        const action = doc.data().action;
        if (action in stats.actionBreakdown) {
          stats.actionBreakdown[action as keyof typeof stats.actionBreakdown]++;
        }
      });

      return {
        success: true,
        stats,
      };
    } catch (error) {
      logError('Error fetching moderator stats:', error);
      throw handleError(error);
    }
  }
);
