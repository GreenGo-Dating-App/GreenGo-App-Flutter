"use strict";
/**
 * Push Notification Cloud Functions
 * Points 271-280: Firebase Cloud Messaging integration
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
exports.getNotificationAnalytics = exports.trackNotificationOpened = exports.sendBundledNotifications = exports.sendPushNotification = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
const messaging = admin.messaging();
/**
 * Send Push Notification
 * Point 271: Firebase Cloud Messaging
 */
exports.sendPushNotification = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { userId, type, title, body, imageUrl, actionButtons, deepLink } = data;
    try {
        // Get user's FCM token
        const userDoc = await firestore.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            throw new Error('User not found');
        }
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        if (!fcmToken) {
            console.log(`No FCM token for user ${userId}`);
            return { success: false, reason: 'No FCM token' };
        }
        // Check notification preferences
        const prefsDoc = await firestore
            .collection('notification_preferences')
            .doc(userId)
            .get();
        if (prefsDoc.exists) {
            const prefs = prefsDoc.data();
            // Check if notification type is enabled
            if (prefs.enabledTypes && prefs.enabledTypes[type] === false) {
                console.log(`Notification type ${type} disabled for user ${userId}`);
                return { success: false, reason: 'Notification type disabled' };
            }
            // Check silent hours (Point 278)
            if ((_a = prefs.silentHours) === null || _a === void 0 ? void 0 : _a.enabled) {
                const now = new Date();
                if (isWithinSilentHours(now, prefs.silentHours)) {
                    console.log(`Within silent hours for user ${userId}`);
                    // Schedule for later
                    await scheduleNotification(userId, type, title, body, imageUrl, deepLink);
                    return { success: true, scheduled: true };
                }
            }
            // Check smart timing (Point 274)
            if (prefs.smartTiming === 'enabled' || prefs.smartTiming === 'aggressiveOptimization') {
                const optimalTime = await calculateOptimalSendTime(userId);
                const now = new Date();
                // If more than 1 hour away from optimal time, schedule it
                if (Math.abs(optimalTime.getTime() - now.getTime()) > 60 * 60 * 1000) {
                    await scheduleNotification(userId, type, title, body, imageUrl, deepLink, optimalTime);
                    return { success: true, scheduled: true, scheduledFor: optimalTime };
                }
            }
        }
        // Build notification payload
        const message = {
            token: fcmToken,
            notification: {
                title,
                body,
                imageUrl,
            },
            data: {
                type,
                deepLink: deepLink || '',
                timestamp: new Date().toISOString(),
            },
            android: {
                priority: 'high',
                notification: {
                    sound: 'gold_chime', // Point 277
                    channelId: 'default',
                    priority: 'high',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'gold_chime.mp3',
                        badge: 1,
                    },
                },
            },
        };
        // Send notification
        const response = await messaging.send(message);
        // Store notification record
        await firestore.collection('notifications').add({
            userId,
            type,
            title,
            body,
            imageUrl: imageUrl || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            isRead: false,
            deepLink: deepLink || null,
            fcmMessageId: response,
        });
        // Track analytics (Point 279)
        await firestore.collection('notification_analytics').add({
            notificationId: response,
            userId,
            type,
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
            wasDelivered: true,
            wasOpened: false,
            wasDismissed: false,
            platform: userData.devicePlatform || 'unknown',
            deviceToken: fcmToken,
        });
        return { success: true, messageId: response };
    }
    catch (error) {
        console.error('Error sending push notification:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Send Bundled Notifications
 * Point 275: Notification bundling
 */
exports.sendBundledNotifications = functions.pubsub
    .schedule('*/15 * * * *') // Every 15 minutes
    .onRun(async (context) => {
    try {
        // Get all pending notifications from last 15 minutes
        const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
        const pendingNotifications = await firestore
            .collection('pending_notifications')
            .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(fifteenMinutesAgo))
            .where('isSent', '==', false)
            .get();
        // Group by user and type
        const groupedByUser = {};
        pendingNotifications.docs.forEach(doc => {
            const notif = doc.data();
            if (!groupedByUser[notif.userId]) {
                groupedByUser[notif.userId] = {};
            }
            if (!groupedByUser[notif.userId][notif.type]) {
                groupedByUser[notif.userId][notif.type] = [];
            }
            groupedByUser[notif.userId][notif.type].push(Object.assign({ id: doc.id }, notif));
        });
        // Send bundled notifications
        for (const userId of Object.keys(groupedByUser)) {
            for (const type of Object.keys(groupedByUser[userId])) {
                const notifications = groupedByUser[userId][type];
                if (notifications.length > 1) {
                    // Bundle notifications
                    const bundledTitle = getBundledTitle(type, notifications.length);
                    const bundledBody = getBundledBody(type, notifications);
                    await exports.sendPushNotification.run({
                        userId,
                        type,
                        title: bundledTitle,
                        body: bundledBody,
                        deepLink: getDeepLinkForType(type),
                    }, { auth: { uid: userId } });
                    // Mark as sent
                    const batch = firestore.batch();
                    notifications.forEach(notif => {
                        batch.update(firestore.collection('pending_notifications').doc(notif.id), {
                            isSent: true,
                            sentAt: admin.firestore.FieldValue.serverTimestamp(),
                        });
                    });
                    await batch.commit();
                }
                else {
                    // Send single notification
                    const notif = notifications[0];
                    await exports.sendPushNotification.run({
                        userId,
                        type: notif.type,
                        title: notif.title,
                        body: notif.body,
                        imageUrl: notif.imageUrl,
                        deepLink: notif.deepLink,
                    }, { auth: { uid: userId } });
                    await firestore.collection('pending_notifications').doc(notif.id).update({
                        isSent: true,
                        sentAt: admin.firestore.FieldValue.serverTimestamp(),
                    });
                }
            }
        }
        console.log('Bundled notifications sent');
    }
    catch (error) {
        console.error('Error sending bundled notifications:', error);
    }
});
/**
 * Calculate Optimal Send Time
 * Point 274: Smart notification timing using ML
 */
async function calculateOptimalSendTime(userId) {
    // Get user activity history
    const activitySnapshot = await firestore
        .collection('user_activity')
        .where('userId', '==', userId)
        .orderBy('timestamp', 'desc')
        .limit(100)
        .get();
    const hourlyActivity = {};
    activitySnapshot.docs.forEach(doc => {
        const activity = doc.data();
        const hour = activity.timestamp.toDate().getHours();
        hourlyActivity[hour] = (hourlyActivity[hour] || 0) + 1;
    });
    // Find hour with most activity
    let maxHour = 12; // Default to noon
    let maxActivity = 0;
    for (let hour = 0; hour < 24; hour++) {
        if ((hourlyActivity[hour] || 0) > maxActivity) {
            maxActivity = hourlyActivity[hour] || 0;
            maxHour = hour;
        }
    }
    // Schedule for that hour today or tomorrow
    const optimalTime = new Date();
    optimalTime.setHours(maxHour, 0, 0, 0);
    if (optimalTime < new Date()) {
        optimalTime.setDate(optimalTime.getDate() + 1);
    }
    return optimalTime;
}
/**
 * Schedule Notification
 */
async function scheduleNotification(userId, type, title, body, imageUrl, deepLink, scheduledFor) {
    await firestore.collection('scheduled_notifications').add({
        userId,
        type,
        title,
        body,
        imageUrl: imageUrl || null,
        deepLink: deepLink || null,
        scheduledFor: admin.firestore.Timestamp.fromDate(scheduledFor || new Date()),
        isSent: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}
/**
 * Check Silent Hours
 * Point 278: Silent hours configuration
 */
function isWithinSilentHours(time, silentHours) {
    const dayOfWeek = time.getDay();
    if (!silentHours.activeDays.includes(dayOfWeek)) {
        return false;
    }
    const currentMinutes = time.getHours() * 60 + time.getMinutes();
    const startMinutes = silentHours.startTime.hour * 60 + silentHours.startTime.minute;
    const endMinutes = silentHours.endTime.hour * 60 + silentHours.endTime.minute;
    if (startMinutes <= endMinutes) {
        return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
    else {
        return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
}
/**
 * Get bundled title
 */
function getBundledTitle(type, count) {
    switch (type) {
        case 'newMessage':
            return `${count} new messages`;
        case 'newLike':
            return `${count} people liked you`;
        case 'profileView':
            return `${count} profile views`;
        case 'newMatch':
            return `${count} new matches`;
        default:
            return `${count} notifications`;
    }
}
/**
 * Get bundled body
 */
function getBundledBody(type, notifications) {
    const names = notifications
        .slice(0, 3)
        .map(n => { var _a; return ((_a = n.data) === null || _a === void 0 ? void 0 : _a.fromUserName) || 'Someone'; })
        .join(', ');
    if (notifications.length > 3) {
        return `${names} and ${notifications.length - 3} others`;
    }
    return names;
}
/**
 * Get deep link for type
 */
function getDeepLinkForType(type) {
    switch (type) {
        case 'newMessage':
            return '/conversations';
        case 'newMatch':
            return '/matches';
        case 'newLike':
            return '/likes';
        case 'profileView':
            return '/profile-views';
        default:
            return '/notifications';
    }
}
/**
 * Track Notification Analytics
 * Point 279: Notification analytics
 */
exports.trackNotificationOpened = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { notificationId, actionTaken } = data;
    try {
        const analyticsDoc = await firestore
            .collection('notification_analytics')
            .where('notificationId', '==', notificationId)
            .limit(1)
            .get();
        if (!analyticsDoc.empty) {
            const doc = analyticsDoc.docs[0];
            const sentAt = doc.data().sentAt.toDate();
            const openedAt = new Date();
            const timeToOpen = openedAt.getTime() - sentAt.getTime();
            await doc.ref.update({
                wasOpened: true,
                openedAt: admin.firestore.FieldValue.serverTimestamp(),
                actionTaken: actionTaken || null,
                timeToOpen: timeToOpen,
            });
        }
        return { success: true };
    }
    catch (error) {
        console.error('Error tracking notification opened:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get Notification Analytics
 * Point 279: Analytics summary
 */
exports.getNotificationAnalytics = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { startDate, endDate } = data;
    try {
        const start = new Date(startDate);
        const end = new Date(endDate);
        const analyticsSnapshot = await firestore
            .collection('notification_analytics')
            .where('sentAt', '>=', admin.firestore.Timestamp.fromDate(start))
            .where('sentAt', '<=', admin.firestore.Timestamp.fromDate(end))
            .get();
        let totalSent = 0;
        let totalDelivered = 0;
        let totalOpened = 0;
        let totalDismissed = 0;
        let totalTimeToOpen = 0;
        const sentByType = {};
        const openRateByType = {};
        const actionsTaken = {};
        analyticsSnapshot.docs.forEach(doc => {
            const data = doc.data();
            totalSent++;
            if (data.wasDelivered)
                totalDelivered++;
            if (data.wasOpened)
                totalOpened++;
            if (data.wasDismissed)
                totalDismissed++;
            if (data.timeToOpen) {
                totalTimeToOpen += data.timeToOpen;
            }
            sentByType[data.type] = (sentByType[data.type] || 0) + 1;
            if (!openRateByType[data.type]) {
                openRateByType[data.type] = { sent: 0, opened: 0 };
            }
            openRateByType[data.type].sent++;
            if (data.wasOpened) {
                openRateByType[data.type].opened++;
            }
            if (data.actionTaken) {
                actionsTaken[data.actionTaken] = (actionsTaken[data.actionTaken] || 0) + 1;
            }
        });
        const deliveryRate = totalSent > 0 ? (totalDelivered / totalSent) * 100 : 0;
        const openRate = totalDelivered > 0 ? (totalOpened / totalDelivered) * 100 : 0;
        const dismissRate = totalSent > 0 ? (totalDismissed / totalSent) * 100 : 0;
        const avgTimeToOpen = totalOpened > 0 ? totalTimeToOpen / totalOpened : 0;
        const openRateByTypeCalculated = {};
        Object.keys(openRateByType).forEach(type => {
            const stats = openRateByType[type];
            openRateByTypeCalculated[type] = stats.sent > 0
                ? (stats.opened / stats.sent) * 100
                : 0;
        });
        return {
            startDate,
            endDate,
            totalSent,
            totalDelivered,
            totalOpened,
            totalDismissed,
            deliveryRate,
            openRate,
            dismissRate,
            avgTimeToOpen,
            sentByType,
            openRateByType: openRateByTypeCalculated,
            actionsTaken,
        };
    }
    catch (error) {
        console.error('Error getting notification analytics:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=pushNotifications.js.map