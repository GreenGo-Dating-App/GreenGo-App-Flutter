/**
 * Notification Service
 * 8 Cloud Functions for push notifications, email, and SMS
 */

import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import sgMail from '@sendgrid/mail';
import twilio from 'twilio';
import { verifyAuth, handleError, logInfo, logError, db } from '../shared/utils';
import { NotificationType } from '../shared/types';

// Initialize SendGrid
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY || '';
sgMail.setApiKey(SENDGRID_API_KEY);

// Initialize Twilio
const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || '';
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || '';
const twilioClient = twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

// ========== 1. SEND PUSH NOTIFICATION (HTTP Callable) ==========

interface SendPushNotificationRequest {
  userId: string;
  title: string;
  body: string;
  type: NotificationType;
  data?: Record<string, any>;
  imageUrl?: string;
}

export const sendPushNotification = onCall<SendPushNotificationRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const callerUid = await verifyAuth(request.auth);
      const { userId, title, body, type, data, imageUrl } = request.data;

      if (!userId || !title || !body) {
        throw new HttpsError('invalid-argument', 'userId, title, and body are required');
      }

      logInfo(`Sending push notification to user ${userId}`);

      // Get user's FCM tokens
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'User not found');
      }

      const userData = userDoc.data()!;
      const fcmTokens = userData.fcmTokens || [];

      if (fcmTokens.length === 0) {
        throw new HttpsError('failed-precondition', 'User has no registered devices');
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
      const notificationRef = await db.collection('notifications').add({
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
      const message: admin.messaging.MulticastMessage = {
        tokens: fcmTokens,
        notification: {
          title,
          body,
          imageUrl,
        },
        data: {
          notificationId: notificationRef.id,
          type,
          ...(data || {}),
        },
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
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success && resp.error?.code === 'messaging/invalid-registration-token') {
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 2. SEND BUNDLED NOTIFICATIONS (HTTP Callable) ==========

interface BundledNotificationRequest {
  userId: string;
  notifications: Array<{
    title: string;
    body: string;
    type: NotificationType;
    data?: Record<string, any>;
  }>;
}

export const sendBundledNotifications = onCall<BundledNotificationRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { userId, notifications } = request.data;

      if (!userId || !notifications || notifications.length === 0) {
        throw new HttpsError('invalid-argument', 'userId and notifications are required');
      }

      logInfo(`Sending ${notifications.length} bundled notifications to user ${userId}`);

      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw new HttpsError('not-found', 'User not found');
      }

      const userData = userDoc.data()!;
      const fcmTokens = userData.fcmTokens || [];

      if (fcmTokens.length === 0) {
        return {
          success: false,
          message: 'User has no registered devices',
        };
      }

      // Send bundled notification
      const message: admin.messaging.MulticastMessage = {
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
      const batch = db.batch();
      notifications.forEach(notif => {
        const ref = db.collection('notifications').doc();
        batch.set(ref, {
          userId,
          ...notif,
          read: false,
          sent: true,
          bundled: true,
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });
      await batch.commit();

      return {
        success: true,
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 3. TRACK NOTIFICATION OPENED (HTTP Callable) ==========

interface TrackNotificationRequest {
  notificationId: string;
  action?: string;
}

export const trackNotificationOpened = onCall<TrackNotificationRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { notificationId, action } = request.data;

      if (!notificationId) {
        throw new HttpsError('invalid-argument', 'notificationId is required');
      }

      const notificationRef = db.collection('notifications').doc(notificationId);
      const notificationDoc = await notificationRef.get();

      if (!notificationDoc.exists) {
        throw new HttpsError('not-found', 'Notification not found');
      }

      const data = notificationDoc.data()!;

      if (data.userId !== uid) {
        throw new HttpsError('permission-denied', 'Not authorized');
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 4. GET NOTIFICATION ANALYTICS (HTTP Callable) ==========

export const getNotificationAnalytics = onCall(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);

      // Get notification stats for last 30 days
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

      const snapshot = await db
        .collection('notifications')
        .where('createdAt', '>', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
        .get();

      const stats = {
        total: snapshot.size,
        sent: 0,
        read: 0,
        byType: {} as Record<string, number>,
        openRate: 0,
      };

      snapshot.forEach(doc => {
        const data = doc.data();
        if (data.sent) stats.sent++;
        if (data.read) stats.read++;
        stats.byType[data.type] = (stats.byType[data.type] || 0) + 1;
      });

      stats.openRate = stats.sent > 0 ? (stats.read / stats.sent) * 100 : 0;

      return {
        success: true,
        stats,
        period: '30 days',
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 5. SEND TRANSACTIONAL EMAIL (HTTP Callable) ==========

interface SendEmailRequest {
  to: string;
  templateId: string;
  dynamicData: Record<string, any>;
}

export const sendTransactionalEmail = onCall<SendEmailRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { to, templateId, dynamicData } = request.data;

      if (!to || !templateId) {
        throw new HttpsError('invalid-argument', 'to and templateId are required');
      }

      logInfo(`Sending transactional email to ${to} with template ${templateId}`);

      const msg = {
        to,
        from: 'noreply@greengo.app',
        templateId,
        dynamicTemplateData: dynamicData,
      };

      await sgMail.send(msg);

      // Log email sent
      await db.collection('emails_sent').add({
        to,
        templateId,
        status: 'sent',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: 'Email sent successfully',
      };
    } catch (error) {
      logError('Error sending email:', error);
      throw handleError(error);
    }
  }
);

// ========== 6. START WELCOME EMAIL SERIES (HTTP Callable) ==========

interface WelcomeEmailRequest {
  userId: string;
  email: string;
  name: string;
}

export const startWelcomeEmailSeries = onCall<WelcomeEmailRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { userId, email, name } = request.data;

      if (!userId || !email) {
        throw new HttpsError('invalid-argument', 'userId and email are required');
      }

      logInfo(`Starting welcome email series for ${email}`);

      // Create welcome email series queue
      const welcomeSeries = [
        { day: 0, templateId: 'welcome_day_0', subject: 'Welcome to GreenGo!' },
        { day: 1, templateId: 'welcome_day_1', subject: 'Complete your profile' },
        { day: 3, templateId: 'welcome_day_3', subject: 'Tips for great matches' },
        { day: 7, templateId: 'welcome_day_7', subject: 'Your first week recap' },
      ];

      const batch = db.batch();

      welcomeSeries.forEach(email => {
        const sendDate = new Date(Date.now() + email.day * 24 * 60 * 60 * 1000);
        const ref = db.collection('email_queue').doc();

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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 7. PROCESS WELCOME EMAIL SERIES (Scheduled - Hourly) ==========

export const processWelcomeEmailSeries = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Processing welcome email series');

    try {
      const now = admin.firestore.Timestamp.now();

      const snapshot = await db
        .collection('email_queue')
        .where('status', '==', 'pending')
        .where('scheduledFor', '<=', now)
        .limit(100)
        .get();

      if (snapshot.empty) {
        logInfo('No emails to send');
        return;
      }

      logInfo(`Sending ${snapshot.size} welcome emails`);

      for (const doc of snapshot.docs) {
        const data = doc.data();

        try {
          await sgMail.send({
            to: data.to,
            from: 'noreply@greengo.app',
            templateId: data.templateId,
            dynamicTemplateData: data.dynamicData,
          });

          await doc.ref.update({
            status: 'sent',
            sentAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          logInfo(`Sent email to ${data.to}`);
        } catch (error) {
          logError(`Error sending email to ${data.to}:`, error);

          await doc.ref.update({
            status: 'failed',
            error: String(error),
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      logInfo('Welcome email processing completed');
    } catch (error) {
      logError('Error processing welcome emails:', error);
      throw error;
    }
  }
);

// ========== 8. SEND WEEKLY DIGEST EMAILS (Scheduled - Weekly) ==========

export const sendWeeklyDigestEmails = onSchedule(
  {
    schedule: '0 9 * * 1', // Every Monday at 9 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Sending weekly digest emails');

    try {
      // Get active users who haven't disabled digest emails
      const usersSnapshot = await db
        .collection('users')
        .where('emailPreferences.weeklyDigest', '!=', false)
        .limit(1000)
        .get();

      logInfo(`Sending digest to ${usersSnapshot.size} users`);

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const userId = userDoc.id;

        try {
          // Get user stats for the week
          const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

          // Get matches
          const matchesSnapshot = await db
            .collection('matches')
            .where('participants', 'array-contains', userId)
            .where('createdAt', '>', admin.firestore.Timestamp.fromDate(weekAgo))
            .get();

          // Get messages
          const messagesSnapshot = await db
            .collection('messages')
            .where('receiverId', '==', userId)
            .where('timestamp', '>', admin.firestore.Timestamp.fromDate(weekAgo))
            .get();

          // Get profile views
          const viewsSnapshot = await db
            .collection('profile_views')
            .where('profileId', '==', userId)
            .where('viewedAt', '>', admin.firestore.Timestamp.fromDate(weekAgo))
            .get();

          if (matchesSnapshot.size === 0 && messagesSnapshot.size === 0 && viewsSnapshot.size === 0) {
            continue; // Skip if no activity
          }

          await sgMail.send({
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

          logInfo(`Sent digest to ${userData.email}`);
        } catch (error) {
          logError(`Error sending digest to user ${userId}:`, error);
        }
      }

      logInfo('Weekly digest completed');
    } catch (error) {
      logError('Error sending weekly digests:', error);
      throw error;
    }
  }
);

// ========== 9. SEND RE-ENGAGEMENT CAMPAIGN (Scheduled - Weekly) ==========

export const sendReEngagementCampaign = onSchedule(
  {
    schedule: '0 10 * * 3', // Every Wednesday at 10 AM UTC
    timeZone: 'UTC',
    memory: '512MiB',
    timeoutSeconds: 540,
  },
  async () => {
    logInfo('Sending re-engagement campaign');

    try {
      // Get users who haven't logged in for 14 days
      const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000);

      const usersSnapshot = await db
        .collection('users')
        .where('lastLoginAt', '<', admin.firestore.Timestamp.fromDate(fourteenDaysAgo))
        .where('emailPreferences.marketing', '!=', false)
        .limit(500)
        .get();

      logInfo(`Re-engaging ${usersSnapshot.size} inactive users`);

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();

        try {
          await sgMail.send({
            to: userData.email,
            from: 'noreply@greengo.app',
            templateId: 're_engagement',
            dynamicTemplateData: {
              name: userData.displayName,
              daysInactive: Math.ceil(
                (Date.now() - userData.lastLoginAt.toMillis()) / (24 * 60 * 60 * 1000)
              ),
            },
          });

          logInfo(`Sent re-engagement email to ${userData.email}`);
        } catch (error) {
          logError(`Error sending re-engagement to ${userData.email}:`, error);
        }
      }

      logInfo('Re-engagement campaign completed');
    } catch (error) {
      logError('Error sending re-engagement:', error);
      throw error;
    }
  }
);
