"use strict";
/**
 * Admin Service
 * 25+ Cloud Functions for admin dashboard, user management, and moderation
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
exports.getModeratorStats = exports.assignModerator = exports.getReportDetails = exports.bulkProcessReports = exports.processReport = exports.getModerationQueue = exports.getBannedUsers = exports.unbanUser = exports.banUser = exports.updateUserProfile = exports.getUserDetails = exports.searchUsers = exports.impersonateUser = exports.deleteUserAccount = exports.reactivateUser = exports.suspendUser = exports.acceptAdminInvite = exports.createAdminInvite = exports.getRoleHistory = exports.getAdminUsers = exports.revokeRole = exports.assignRole = exports.getSystemHealth = exports.exportDashboardData = exports.getConversionFunnel = exports.getChurnRiskUsers = exports.getTopMatchmakers = exports.getActiveUsers = exports.getRevenueStats = exports.getUserGrowth = exports.getDashboardStats = void 0;
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../shared/types");
// ========== DASHBOARD FUNCTIONS ==========
// 1. Get Dashboard Stats
exports.getDashboardStats = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { period = 'month' } = request.data;
        (0, utils_1.logInfo)(`Fetching dashboard stats for period: ${period}`);
        const now = new Date();
        let startDate;
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
        const usersSnapshot = await utils_1.db.collection('users').where('createdAt', '>=', startTimestamp).get();
        const totalNewUsers = usersSnapshot.size;
        const allUsersSnapshot = await utils_1.db.collection('users').get();
        const totalUsers = allUsersSnapshot.size;
        // Get active users (last 7 days)
        const sevenDaysAgo = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 24 * 60 * 60 * 1000));
        const activeUsersSnapshot = await utils_1.db.collection('users').where('lastActiveAt', '>=', sevenDaysAgo).get();
        const activeUsers = activeUsersSnapshot.size;
        // Get subscription stats
        const subscriptionsSnapshot = await utils_1.db.collection('subscriptions').where('status', '==', 'active').get();
        const activeSubscriptions = subscriptionsSnapshot.size;
        let mrr = 0; // Monthly Recurring Revenue
        subscriptionsSnapshot.docs.forEach(doc => {
            const data = doc.data();
            if (data.tier === types_1.SubscriptionTier.SILVER)
                mrr += 9.99;
            if (data.tier === types_1.SubscriptionTier.GOLD)
                mrr += 19.99;
        });
        // Get match stats
        const matchesSnapshot = await utils_1.db.collection('matches').where('createdAt', '>=', startTimestamp).get();
        const totalMatches = matchesSnapshot.size;
        // Get message stats
        const messagesSnapshot = await utils_1.db.collection('messages').where('createdAt', '>=', startTimestamp).get();
        const totalMessages = messagesSnapshot.size;
        // Get report stats
        const reportsSnapshot = await utils_1.db.collection('reports').where('createdAt', '>=', startTimestamp).get();
        const totalReports = reportsSnapshot.size;
        const pendingReports = reportsSnapshot.docs.filter(d => d.data().status === types_1.ReportStatus.PENDING).length;
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching dashboard stats:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 2. Get User Growth
exports.getUserGrowth = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate, interval = 'day' } = request.data;
        (0, utils_1.logInfo)(`Fetching user growth from ${startDate} to ${endDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        const snapshot = await utils_1.db
            .collection('users')
            .where('createdAt', '>=', start)
            .where('createdAt', '<=', end)
            .get();
        // Group by interval
        const growthData = {};
        snapshot.docs.forEach(doc => {
            const createdAt = doc.data().createdAt.toDate();
            let key;
            if (interval === 'day') {
                key = createdAt.toISOString().split('T')[0];
            }
            else if (interval === 'week') {
                const weekStart = new Date(createdAt);
                weekStart.setDate(createdAt.getDate() - createdAt.getDay());
                key = weekStart.toISOString().split('T')[0];
            }
            else {
                key = createdAt.toISOString().substring(0, 7); // YYYY-MM
            }
            growthData[key] = (growthData[key] || 0) + 1;
        });
        return {
            success: true,
            growthData,
            totalNewUsers: snapshot.size,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching user growth:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 3. Get Revenue Stats
exports.getRevenueStats = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching revenue stats from ${startDate} to ${endDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        // Get subscriptions
        const subscriptionsSnapshot = await utils_1.db
            .collection('subscriptions')
            .where('createdAt', '>=', start)
            .where('createdAt', '<=', end)
            .get();
        let subscriptionRevenue = 0;
        const tierCounts = { silver: 0, gold: 0 };
        subscriptionsSnapshot.docs.forEach(doc => {
            const data = doc.data();
            if (data.tier === types_1.SubscriptionTier.SILVER) {
                subscriptionRevenue += 9.99;
                tierCounts.silver++;
            }
            if (data.tier === types_1.SubscriptionTier.GOLD) {
                subscriptionRevenue += 19.99;
                tierCounts.gold++;
            }
        });
        // Get coin purchases
        const coinPurchasesSnapshot = await utils_1.db
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching revenue stats:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 4. Get Active Users
exports.getActiveUsers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { period = 'week' } = request.data;
        (0, utils_1.logInfo)(`Fetching active users for period: ${period}`);
        const now = Date.now();
        let cutoff;
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
        const snapshot = await utils_1.db
            .collection('users')
            .where('lastActiveAt', '>=', cutoffTimestamp)
            .get();
        const totalUsers = (await utils_1.db.collection('users').count().get()).data().count;
        return {
            success: true,
            activeUsers: snapshot.size,
            totalUsers,
            activeRate: ((snapshot.size / totalUsers) * 100).toFixed(2) + '%',
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching active users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 5. Get Top Matchmakers
exports.getTopMatchmakers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { limit = 10 } = request.data;
        (0, utils_1.logInfo)(`Fetching top ${limit} matchmakers`);
        const usersSnapshot = await utils_1.db
            .collection('users')
            .orderBy('stats.totalMatches', 'desc')
            .limit(limit)
            .get();
        const topMatchmakers = usersSnapshot.docs.map(doc => {
            var _a, _b;
            return ({
                userId: doc.id,
                displayName: doc.data().displayName,
                totalMatches: ((_a = doc.data().stats) === null || _a === void 0 ? void 0 : _a.totalMatches) || 0,
                totalMessages: ((_b = doc.data().stats) === null || _b === void 0 ? void 0 : _b.totalMessages) || 0,
            });
        });
        return {
            success: true,
            topMatchmakers,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching top matchmakers:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 6. Get Churn Risk Users
exports.getChurnRiskUsers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { limit = 50 } = request.data;
        (0, utils_1.logInfo)(`Fetching ${limit} users at churn risk`);
        // Users who haven't been active in 14+ days but were active before
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
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching churn risk users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 7. Get Conversion Funnel
exports.getConversionFunnel = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { startDate, endDate } = request.data;
        (0, utils_1.logInfo)(`Fetching conversion funnel from ${startDate} to ${endDate}`);
        const start = admin.firestore.Timestamp.fromDate(new Date(startDate));
        const end = admin.firestore.Timestamp.fromDate(new Date(endDate));
        const usersSnapshot = await utils_1.db
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
            if (data.profileCompleteness >= 100)
                profileCompleted++;
            if (((_a = data.stats) === null || _a === void 0 ? void 0 : _a.totalMatches) > 0)
                firstMatch++;
            if (((_b = data.stats) === null || _b === void 0 ? void 0 : _b.totalMessages) > 0)
                firstMessage++;
            if (data.subscriptionTier !== types_1.SubscriptionTier.BASIC)
                subscribed++;
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching conversion funnel:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 8. Export Dashboard Data
exports.exportDashboardData = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 540,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { type, startDate, endDate, format = 'csv' } = request.data;
        (0, utils_1.logInfo)(`Exporting ${type} data as ${format}`);
        // This would generate CSV/JSON exports
        // For now, return a placeholder
        return {
            success: true,
            exportUrl: `https://storage.googleapis.com/exports/${type}_${Date.now()}.${format}`,
            expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error exporting dashboard data:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 9. Get System Health
exports.getSystemHealth = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        (0, utils_1.logInfo)('Fetching system health');
        // Check various system metrics
        const userCount = (await utils_1.db.collection('users').count().get()).data().count;
        const messageCount = (await utils_1.db.collection('messages').count().get()).data().count;
        const pendingReportsCount = (await utils_1.db.collection('reports').where('status', '==', types_1.ReportStatus.PENDING).count().get()).data().count;
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching system health:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== ROLE MANAGEMENT FUNCTIONS ==========
// 10. Assign Role
exports.assignRole = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b, _c;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, role } = request.data;
        (0, utils_1.logInfo)(`Assigning role ${role} to user ${userId}`);
        const userRef = utils_1.db.collection('users').doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        const previousRole = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
        await userRef.update({
            role,
            previousRole,
            roleChangedAt: utils_1.FieldValue.serverTimestamp(),
            roleChangedBy: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Log role change
        await utils_1.db.collection('audit_logs').add({
            type: 'role_change',
            userId,
            performedBy: (_c = request.auth) === null || _c === void 0 ? void 0 : _c.uid,
            previousRole,
            newRole: role,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error assigning role:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 11. Revoke Role
exports.revokeRole = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId } = request.data;
        (0, utils_1.logInfo)(`Revoking admin role from user ${userId}`);
        const userRef = utils_1.db.collection('users').doc(userId);
        const userDoc = await userRef.get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        const previousRole = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
        await userRef.update({
            role: types_1.UserRole.USER,
            previousRole,
            roleChangedAt: utils_1.FieldValue.serverTimestamp(),
            roleChangedBy: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error revoking role:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 12. Get Admin Users
exports.getAdminUsers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { limit = 50 } = request.data;
        (0, utils_1.logInfo)('Fetching admin users');
        const snapshot = await utils_1.db
            .collection('users')
            .where('role', '==', types_1.UserRole.ADMIN)
            .limit(limit)
            .get();
        const admins = snapshot.docs.map(doc => {
            var _a;
            return ({
                userId: doc.id,
                email: doc.data().email,
                displayName: doc.data().displayName,
                role: doc.data().role,
                roleChangedAt: (_a = doc.data().roleChangedAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(),
            });
        });
        return {
            success: true,
            admins,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching admin users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 13. Get Role History
exports.getRoleHistory = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId } = request.data;
        (0, utils_1.logInfo)(`Fetching role history for user ${userId}`);
        const snapshot = await utils_1.db
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
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching role history:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 14. Create Admin Invite
exports.createAdminInvite = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { email, role, expiresInDays = 7 } = request.data;
        (0, utils_1.logInfo)(`Creating admin invite for ${email}`);
        const inviteCode = Math.random().toString(36).substring(2, 15);
        const expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000);
        await utils_1.db.collection('admin_invites').add({
            email,
            role,
            inviteCode,
            createdBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            used: false,
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            inviteCode,
            expiresAt: expiresAt.toISOString(),
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error creating admin invite:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 15. Accept Admin Invite
exports.acceptAdminInvite = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        const uid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
        if (!uid)
            throw new Error('Not authenticated');
        const { inviteCode } = request.data;
        (0, utils_1.logInfo)(`Accepting admin invite: ${inviteCode}`);
        const inviteSnapshot = await utils_1.db
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
        await utils_1.db.collection('users').doc(uid).update({
            role: inviteData.role,
            roleChangedAt: utils_1.FieldValue.serverTimestamp(),
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Mark invite as used
        await inviteDoc.ref.update({
            used: true,
            usedBy: uid,
            usedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error accepting admin invite:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== USER MANAGEMENT FUNCTIONS ==========
// 16. Suspend User
exports.suspendUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, reason, duration, notify = true } = request.data;
        (0, utils_1.logInfo)(`Suspending user ${userId}`);
        const suspendedUntil = duration
            ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + duration * 24 * 60 * 60 * 1000))
            : null;
        await utils_1.db.collection('users').doc(userId).update({
            accountStatus: 'suspended',
            suspendedAt: utils_1.FieldValue.serverTimestamp(),
            suspendedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            suspensionReason: reason,
            suspendedUntil,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        if (notify) {
            await utils_1.db.collection('notifications').add({
                userId,
                type: 'account_suspended',
                title: 'Account Suspended',
                body: `Your account has been suspended. Reason: ${reason}`,
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error suspending user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 17. Reactivate User
exports.reactivateUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, notify = true } = request.data;
        (0, utils_1.logInfo)(`Reactivating user ${userId}`);
        await utils_1.db.collection('users').doc(userId).update({
            accountStatus: 'active',
            reactivatedAt: utils_1.FieldValue.serverTimestamp(),
            reactivatedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        if (notify) {
            await utils_1.db.collection('notifications').add({
                userId,
                type: 'account_reactivated',
                title: 'Account Reactivated',
                body: 'Your account has been reactivated',
                read: false,
                sent: false,
                createdAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error reactivating user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 18. Delete User Account
exports.deleteUserAccount = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, reason, hardDelete = false } = request.data;
        (0, utils_1.logInfo)(`Deleting user ${userId} (hard: ${hardDelete})`);
        if (hardDelete) {
            // Hard delete - permanently remove all data
            await admin.auth().deleteUser(userId);
            await utils_1.db.collection('users').doc(userId).delete();
            // Would also delete related data in production
        }
        else {
            // Soft delete - mark as deleted but keep data
            await utils_1.db.collection('users').doc(userId).update({
                accountStatus: 'deleted',
                deletedAt: utils_1.FieldValue.serverTimestamp(),
                deletedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
                deletionReason: reason,
                updatedAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error deleting user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 19. Impersonate User
exports.impersonateUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, reason } = request.data;
        (0, utils_1.logInfo)(`Admin ${(_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid} impersonating user ${userId}`);
        // Log impersonation
        await utils_1.db.collection('audit_logs').add({
            type: 'impersonation',
            adminId: (_b = request.auth) === null || _b === void 0 ? void 0 : _b.uid,
            targetUserId: userId,
            reason,
            timestamp: utils_1.FieldValue.serverTimestamp(),
        });
        // Generate impersonation token (in production, this would be a custom token)
        const customToken = await admin.auth().createCustomToken(userId);
        return {
            success: true,
            token: customToken,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error impersonating user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 20. Search Users
exports.searchUsers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { query, filters, limit = 50, startAfter } = request.data;
        (0, utils_1.logInfo)(`Searching users: ${query}`);
        let queryRef = utils_1.db.collection('users').limit(limit);
        if (filters === null || filters === void 0 ? void 0 : filters.tier) {
            queryRef = queryRef.where('subscriptionTier', '==', filters.tier);
        }
        if ((filters === null || filters === void 0 ? void 0 : filters.verified) !== undefined) {
            queryRef = queryRef.where('verified', '==', filters.verified);
        }
        if (startAfter) {
            const startDoc = await utils_1.db.collection('users').doc(startAfter).get();
            if (startDoc.exists) {
                queryRef = queryRef.startAfter(startDoc);
            }
        }
        const snapshot = await queryRef.get();
        let users = snapshot.docs.map(doc => (Object.assign({ userId: doc.id }, doc.data())));
        // Filter by query if provided
        if (query) {
            const lowerQuery = query.toLowerCase();
            users = users.filter((user) => {
                var _a, _b;
                return ((_a = user.displayName) === null || _a === void 0 ? void 0 : _a.toLowerCase().includes(lowerQuery)) ||
                    ((_b = user.email) === null || _b === void 0 ? void 0 : _b.toLowerCase().includes(lowerQuery));
            });
        }
        return {
            success: true,
            users,
            hasMore: snapshot.size === limit,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error searching users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 21. Get User Details
exports.getUserDetails = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId } = request.data;
        (0, utils_1.logInfo)(`Fetching details for user ${userId}`);
        const userDoc = await utils_1.db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        return {
            success: true,
            user: Object.assign({ userId: userDoc.id }, userDoc.data()),
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching user details:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 22. Update User Profile
exports.updateUserProfile = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, updates } = request.data;
        (0, utils_1.logInfo)(`Updating profile for user ${userId}`);
        await utils_1.db.collection('users').doc(userId).update(Object.assign(Object.assign({}, updates), { updatedAt: utils_1.FieldValue.serverTimestamp(), updatedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid }));
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error updating user profile:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 23. Ban User
exports.banUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId, reason, permanent = false, banDuration } = request.data;
        (0, utils_1.logInfo)(`Banning user ${userId} (permanent: ${permanent})`);
        const bannedUntil = !permanent && banDuration
            ? admin.firestore.Timestamp.fromDate(new Date(Date.now() + banDuration * 24 * 60 * 60 * 1000))
            : null;
        await utils_1.db.collection('users').doc(userId).update({
            banned: true,
            bannedAt: utils_1.FieldValue.serverTimestamp(),
            bannedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            banReason: reason,
            bannedUntil,
            permanentBan: permanent,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error banning user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 24. Unban User
exports.unbanUser = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId } = request.data;
        (0, utils_1.logInfo)(`Unbanning user ${userId}`);
        await utils_1.db.collection('users').doc(userId).update({
            banned: false,
            unbannedAt: utils_1.FieldValue.serverTimestamp(),
            unbannedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error unbanning user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 25. Get Banned Users
exports.getBannedUsers = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { limit = 50, startAfter } = request.data;
        (0, utils_1.logInfo)('Fetching banned users');
        let query = utils_1.db.collection('users').where('banned', '==', true).limit(limit);
        if (startAfter) {
            const startDoc = await utils_1.db.collection('users').doc(startAfter).get();
            if (startDoc.exists) {
                query = query.startAfter(startDoc);
            }
        }
        const snapshot = await query.get();
        const bannedUsers = snapshot.docs.map(doc => {
            var _a;
            return ({
                userId: doc.id,
                displayName: doc.data().displayName,
                email: doc.data().email,
                bannedAt: (_a = doc.data().bannedAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(),
                banReason: doc.data().banReason,
                permanentBan: doc.data().permanentBan,
            });
        });
        return {
            success: true,
            bannedUsers,
            hasMore: snapshot.size === limit,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching banned users:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== MODERATION QUEUE FUNCTIONS ==========
// 26. Get Moderation Queue
exports.getModerationQueue = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { status = types_1.ReportStatus.PENDING, priority, limit = 50 } = request.data;
        (0, utils_1.logInfo)(`Fetching moderation queue (status: ${status})`);
        let query = utils_1.db.collection('reports').where('status', '==', status).limit(limit);
        if (priority) {
            query = query.where('priority', '==', priority);
        }
        const snapshot = await query.get();
        const reports = snapshot.docs.map(doc => (Object.assign({ reportId: doc.id }, doc.data())));
        return {
            success: true,
            reports,
            totalCount: snapshot.size,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching moderation queue:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 27. Process Report
exports.processReport = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { reportId, action, notes } = request.data;
        (0, utils_1.logInfo)(`Processing report ${reportId} with action: ${action}`);
        const reportRef = utils_1.db.collection('reports').doc(reportId);
        const reportDoc = await reportRef.get();
        if (!reportDoc.exists) {
            throw new Error('Report not found');
        }
        const reportData = reportDoc.data();
        // Update report
        await reportRef.update({
            status: types_1.ReportStatus.RESOLVED,
            resolvedAt: utils_1.FieldValue.serverTimestamp(),
            resolvedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
            action,
            moderatorNotes: notes,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        // Take action on reported user
        const reportedUserId = reportData.reportedUserId;
        switch (action) {
            case 'warn':
                await utils_1.db.collection('notifications').add({
                    userId: reportedUserId,
                    type: 'warning',
                    title: 'Warning',
                    body: 'Your content has been flagged for violating community guidelines',
                    read: false,
                    sent: false,
                    createdAt: utils_1.FieldValue.serverTimestamp(),
                });
                break;
            case 'suspend':
                await utils_1.db.collection('users').doc(reportedUserId).update({
                    accountStatus: 'suspended',
                    suspendedAt: utils_1.FieldValue.serverTimestamp(),
                    suspensionReason: 'Community guidelines violation',
                    updatedAt: utils_1.FieldValue.serverTimestamp(),
                });
                break;
            case 'ban':
                await utils_1.db.collection('users').doc(reportedUserId).update({
                    banned: true,
                    bannedAt: utils_1.FieldValue.serverTimestamp(),
                    banReason: 'Community guidelines violation',
                    updatedAt: utils_1.FieldValue.serverTimestamp(),
                });
                break;
            case 'dismiss':
                // No action needed
                break;
        }
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error processing report:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 28. Bulk Process Reports
exports.bulkProcessReports = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { reportIds, action, notes } = request.data;
        (0, utils_1.logInfo)(`Bulk processing ${reportIds.length} reports with action: ${action}`);
        const batch = utils_1.db.batch();
        for (const reportId of reportIds) {
            const reportRef = utils_1.db.collection('reports').doc(reportId);
            batch.update(reportRef, {
                status: types_1.ReportStatus.RESOLVED,
                resolvedAt: utils_1.FieldValue.serverTimestamp(),
                resolvedBy: (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid,
                action,
                moderatorNotes: notes,
                updatedAt: utils_1.FieldValue.serverTimestamp(),
            });
        }
        await batch.commit();
        return {
            success: true,
            processedCount: reportIds.length,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error bulk processing reports:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 29. Get Report Details
exports.getReportDetails = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { reportId } = request.data;
        (0, utils_1.logInfo)(`Fetching report details: ${reportId}`);
        const reportDoc = await utils_1.db.collection('reports').doc(reportId).get();
        if (!reportDoc.exists) {
            throw new Error('Report not found');
        }
        return {
            success: true,
            report: Object.assign({ reportId: reportDoc.id }, reportDoc.data()),
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching report details:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 30. Assign Moderator
exports.assignModerator = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { reportId, moderatorId } = request.data;
        (0, utils_1.logInfo)(`Assigning moderator ${moderatorId} to report ${reportId}`);
        await utils_1.db.collection('reports').doc(reportId).update({
            assignedTo: moderatorId,
            assignedAt: utils_1.FieldValue.serverTimestamp(),
            status: types_1.ReportStatus.UNDER_REVIEW,
            updatedAt: utils_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        (0, utils_1.logError)('Error assigning moderator:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// 31. Get Moderator Stats
exports.getModeratorStats = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a;
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { moderatorId, period = 'month' } = request.data;
        const targetModeratorId = moderatorId || ((_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid);
        (0, utils_1.logInfo)(`Fetching moderator stats for ${targetModeratorId}`);
        const snapshot = await utils_1.db
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
                stats.actionBreakdown[action]++;
            }
        });
        return {
            success: true,
            stats,
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error fetching moderator stats:', error);
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map