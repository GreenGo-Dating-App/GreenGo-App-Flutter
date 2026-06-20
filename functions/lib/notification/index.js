"use strict";
/**
 * Notification Service
 * 8 Cloud Functions for push notifications, email, and SMS
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendReEngagementCampaign = exports.sendWeeklyDigestEmails = exports.processWelcomeEmailSeries = exports.startWelcomeEmailSeries = exports.sendTransactionalEmail = exports.getNotificationAnalytics = exports.trackNotificationOpened = exports.sendBundledNotifications = exports.sendPushNotification = void 0;
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const mail_1 = __importDefault(require("@sendgrid/mail"));
const twilio_1 = __importDefault(require("twilio"));
const utils_1 = require("../shared/utils");
// Initialize SendGrid
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || '';
mail_1.default.setApiKey(SENDGRID_API_KEY);
// Initialize Twilio
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || '';
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || '';
const twilioClient = (0, twilio_1.default)(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);
exports.sendPushNotification = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const callerUid = await (0, utils_1.verifyAuth)(request.auth);
        const { userId, title, body, type, data, imageUrl } = request.data;
        if (!userId || !title || !body) {
            throw new https_1.HttpsError('invalid-argument', 'userId, title, and body are required');
        }
        (0, utils_1.logInfo)(`Sending push notification to user ${userId}`);
        // Get user's FCM tokens
        const userDoc = await utils_1.db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new https_1.HttpsError('not-found', 'User not found');
        }
        const userData = userDoc.data();
        const fcmTokens = userData.fcmTokens || [];
        if (fcmTokens.length === 0) {
            throw new https_1.HttpsError('failed-precondition', 'User has no registered devices');
        }
        // Check notification preferences
        const preferences = userData.notificationPreferences || {};
        if (preferences[type] === false) {
            return {
                success: false,
                message: 'User has disabled this notification type',
            };
        }
        // Create notification in Firestore
        const notificationRef = await utils_1.db.collection('notifications').add({
            userId,
            type,
            title,
            body,
            data: data || {},
            imageUrl,
            read: false,
            sent: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        // Send FCM notification
        const message = {
            tokens: fcmTokens,
            notification: {
                title,
                body,
                imageUrl,
            },
            data: Object.assign({ notificationId: notificationRef.id, type }, (data || {})),
            android: {
                priority: 'high',
                notification: {
                    sound: 'default',
                    channelId: type,
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        // Update notification status
        await notificationRef.update({
            sent: true,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            successCount: response.successCount,
            failureCount: response.failureCount,
        });
        // Remove invalid tokens
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
            var _a;
            if (!resp.success && ((_a = resp.error) === null || _a === void 0 ? void 0 : _a.code) === 'messaging/invalid-registration-token') {
                invalidTokens.push(fcmTokens[idx]);
            }
        });
        if (invalidTokens.length > 0) {
            await userDoc.ref.update({
                fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
            });
        }
        return {
            success: true,
            notificationId: notificationRef.id,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.sendBundledNotifications = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAuth)(request.auth);
        const { userId, notifications } = request.data;
        if (!userId || !notifications || notifications.length === 0) {
            throw new https_1.HttpsError('invalid-argument', 'userId and notifications are required');
        }
        (0, utils_1.logInfo)(`Sending ${notifications.length} bundled notifications to user ${userId}`);
        const userDoc = await utils_1.db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new https_1.HttpsError('not-found', 'User not found');
        }
        const userData = userDoc.data();
        const fcmTokens = userData.fcmTokens || [];
        if (fcmTokens.length === 0) {
            return {
                success: false,
                message: 'User has no registered devices',
            };
        }
        // Send bundled notification
        const message = {
            tokens: fcmTokens,
            notification: {
                title: `${notifications.length} new notifications`,
                body: notifications[0].body,
            },
            data: {
                bundled: 'true',
                count: notifications.length.toString(),
            },
            android: {
                notification: {
                    channelId: 'bundled_notifications',
                },
            },
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        // Save each notification
        const batch = utils_1.db.batch();
        notifications.forEach(notif => {
            const ref = utils_1.db.collection('notifications').doc();
            batch.set(ref, Object.assign(Object.assign({ userId }, notif), { read: false, sent: true, bundled: true, sentAt: admin.firestore.FieldValue.serverTimestamp() }));
        });
        await batch.commit();
        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.trackNotificationOpened = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { notificationId, action } = request.data;
        if (!notificationId) {
            throw new https_1.HttpsError('invalid-argument', 'notificationId is required');
        }
        const notificationRef = utils_1.db.collection('notifications').doc(notificationId);
        const notificationDoc = await notificationRef.get();
        if (!notificationDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Notification not found');
        }
        const data = notificationDoc.data();
        if (data.userId !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        await notificationRef.update({
            read: true,
            readAt: admin.firestore.FieldValue.serverTimestamp(),
            action: action || 'opened',
        });
        // Track analytics
        // await logEventToBigQuery('notification_opened', { notificationId, action, type: data.type });
        return {
            success: true,
            message: 'Notification tracked',
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 4. GET NOTIFICATION ANALYTICS (HTTP Callable) ==========
exports.getNotificationAnalytics = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAuth)(request.auth);
        // Get notification stats for last 30 days
        const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
        const snapshot = await utils_1.db
            .collection('notifications')
            .where('createdAt', '>', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
            .get();
        const stats = {
            total: snapshot.size,
            sent: 0,
            read: 0,
            byType: {},
            openRate: 0,
        };
        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.sent)
                stats.sent++;
            if (data.read)
                stats.read++;
            stats.byType[data.type] = (stats.byType[data.type] || 0) + 1;
        });
        stats.openRate = stats.sent > 0 ? (stats.read / stats.sent) * 100 : 0;
        return {
            success: true,
            stats,
            period: '30 days',
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.sendTransactionalEmail = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAuth)(request.auth);
        const { to, templateId, dynamicData } = request.data;
        if (!to || !templateId) {
            throw new https_1.HttpsError('invalid-argument', 'to and templateId are required');
        }
        (0, utils_1.logInfo)(`Sending transactional email to ${to} with template ${templateId}`);
        const msg = {
            to,
            from: 'noreply@greengo.app',
            templateId,
            dynamicTemplateData: dynamicData,
        };
        await mail_1.default.send(msg);
        // Log email sent
        await utils_1.db.collection('emails_sent').add({
            to,
            templateId,
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            message: 'Email sent successfully',
        };
    }
    catch (error) {
        (0, utils_1.logError)('Error sending email:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.startWelcomeEmailSeries = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        await (0, utils_1.verifyAuth)(request.auth);
        const { userId, email, name } = request.data;
        if (!userId || !email) {
            throw new https_1.HttpsError('invalid-argument', 'userId and email are required');
        }
        (0, utils_1.logInfo)(`Starting welcome email series for ${email}`);
        // Create welcome email series queue
        const welcomeSeries = [
            { day: 0, templateId: 'welcome_day_0', subject: 'Welcome to GreenGo!' },
            { day: 1, templateId: 'welcome_day_1', subject: 'Complete your profile' },
            { day: 3, templateId: 'welcome_day_3', subject: 'Tips for great matches' },
            { day: 7, templateId: 'welcome_day_7', subject: 'Your first week recap' },
        ];
        const batch = utils_1.db.batch();
        welcomeSeries.forEach(email => {
            const sendDate = new Date(Date.now() + email.day * 24 * 60 * 60 * 1000);
            const ref = utils_1.db.collection('email_queue').doc();
            batch.set(ref, {
                userId,
                to: email,
                templateId: email.templateId,
                subject: email.subject,
                dynamicData: { name: name || 'there' },
                scheduledFor: admin.firestore.Timestamp.fromDate(sendDate),
                series: 'welcome',
                status: 'pending',
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        await batch.commit();
        return {
            success: true,
            emailsQueued: welcomeSeries.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 7. PROCESS WELCOME EMAIL SERIES (Scheduled - Hourly) ==========
exports.processWelcomeEmailSeries = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Processing welcome email series');
    try {
        const now = admin.firestore.Timestamp.now();
        const snapshot = await utils_1.db
            .collection('email_queue')
            .where('status', '==', 'pending')
            .where('scheduledFor', '<=', now)
            .limit(100)
            .get();
        if (snapshot.empty) {
            (0, utils_1.logInfo)('No emails to send');
            return;
        }
        (0, utils_1.logInfo)(`Sending ${snapshot.size} welcome emails`);
        for (const doc of snapshot.docs) {
            const data = doc.data();
            try {
                await mail_1.default.send({
                    to: data.to,
                    from: 'noreply@greengo.app',
                    templateId: data.templateId,
                    dynamicTemplateData: data.dynamicData,
                });
                await doc.ref.update({
                    status: 'sent',
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                });
                (0, utils_1.logInfo)(`Sent email to ${data.to}`);
            }
            catch (error) {
                (0, utils_1.logError)(`Error sending email to ${data.to}:`, error);
                await doc.ref.update({
                    status: 'failed',
                    error: String(error),
                    failedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        }
        (0, utils_1.logInfo)('Welcome email processing completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error processing welcome emails:', error);
        throw error;
    }
});
// ========== 8. SEND WEEKLY DIGEST EMAILS (Scheduled - Weekly) ==========
exports.sendWeeklyDigestEmails = (0, scheduler_1.onSchedule)({
    schedule: '0 9 * * 1', // Every Monday at 9 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    (0, utils_1.logInfo)('Sending weekly digest emails');
    try {
        // Get active users who haven't disabled digest emails
        const usersSnapshot = await utils_1.db
            .collection('users')
            .where('emailPreferences.weeklyDigest', '!=', false)
            .limit(1000)
            .get();
        (0, utils_1.logInfo)(`Sending digest to ${usersSnapshot.size} users`);
        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const userId = userDoc.id;
            try {
                // Get user stats for the week
                const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
                // Get matches
                const matchesSnapshot = await utils_1.db
                    .collection('matches')
                    .where('participants', 'array-contains', userId)
                    .where('createdAt', '>', admin.firestore.Timestamp.fromDate(weekAgo))
                    .get();
                // Get messages
                const messagesSnapshot = await utils_1.db
                    .collection('messages')
                    .where('receiverId', '==', userId)
                    .where('timestamp', '>', admin.firestore.Timestamp.fromDate(weekAgo))
                    .get();
                // Get profile views
                const viewsSnapshot = await utils_1.db
                    .collection('profile_views')
                    .where('profileId', '==', userId)
                    .where('viewedAt', '>', admin.firestore.Timestamp.fromDate(weekAgo))
                    .get();
                if (matchesSnapshot.size === 0 && messagesSnapshot.size === 0 && viewsSnapshot.size === 0) {
                    continue; // Skip if no activity
                }
                await mail_1.default.send({
                    to: userData.email,
                    from: 'noreply@greengo.app',
                    templateId: 'weekly_digest',
                    dynamicTemplateData: {
                        name: userData.displayName,
                        newMatches: matchesSnapshot.size,
                        newMessages: messagesSnapshot.size,
                        profileViews: viewsSnapshot.size,
                    },
                });
                (0, utils_1.logInfo)(`Sent digest to ${userData.email}`);
            }
            catch (error) {
                (0, utils_1.logError)(`Error sending digest to user ${userId}:`, error);
            }
        }
        (0, utils_1.logInfo)('Weekly digest completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error sending weekly digests:', error);
        throw error;
    }
});
// ========== 9. SEND RE-ENGAGEMENT CAMPAIGN (Scheduled - Weekly) ==========
exports.sendReEngagementCampaign = (0, scheduler_1.onSchedule)({
    schedule: '0 10 * * 3', // Every Wednesday at 10 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
}, async () => {
    (0, utils_1.logInfo)('Sending re-engagement campaign');
    try {
        // Get users who haven't logged in for 14 days
        const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);
        const usersSnapshot = await utils_1.db
            .collection('users')
            .where('lastLoginAt', '<', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
            .where('emailPreferences.marketing', '!=', false)
            .limit(500)
            .get();
        (0, utils_1.logInfo)(`Re-engaging ${usersSnapshot.size} inactive users`);
        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            try {
                await mail_1.default.send({
                    to: userData.email,
                    from: 'noreply@greengo.app',
                    templateId: 're_engagement',
                    dynamicTemplateData: {
                        name: userData.displayName,
                        daysInactive: Math.ceil((Date.now() - userData.lastLoginAt.toMillis()) / (24 * 60 * 60 * 1000)),
                    },
                });
                (0, utils_1.logInfo)(`Sent re-engagement email to ${userData.email}`);
            }
            catch (error) {
                (0, utils_1.logError)(`Error sending re-engagement to ${userData.email}:`, error);
            }
        }
        (0, utils_1.logInfo)('Re-engagement campaign completed');
    }
    catch (error) {
        (0, utils_1.logError)('Error sending re-engagement:', error);
        throw error;
    }
});
//# sourceMappingURL=index.js.map