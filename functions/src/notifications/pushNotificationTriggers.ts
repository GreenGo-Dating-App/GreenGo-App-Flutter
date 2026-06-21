/**
 * Push Notification Firestore Triggers
 * Auto-send push notifications when likes, matches, and messages are created
 */

import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { logInfo, logError } from '../shared/utils';
import { monitored } from '../shared/monitoring';

const db = admin.firestore();
const messaging = admin.messaging();

// Maps notification "type" to the flat boolean field used by the Flutter app.
const TYPE_TO_PREF_FIELD: Record<string, string> = {
  newMessage: 'newMessageNotifications',
  newMatch: 'newMatchNotifications',
  newLike: 'newLikeNotifications',
  superLike: 'superLikeNotifications',
  profileView: 'profileViewNotifications',
  matchExpiring: 'matchExpiringNotifications',
};

interface SendOptions {
  imageUrl?: string;
  collapseKey?: string; // Android tag + APNs apns-collapse-id (used for replace-in-tray)
  threadId?: string; // iOS group key
  isCritical?: boolean; // bypasses quiet hours, sets time-sensitive on iOS
}

function isInQuietHours(prefs: any): boolean {
  if (!prefs?.quietHoursEnabled) return false;
  const start = prefs.quietHoursStart;
  const end = prefs.quietHoursEnd;
  if (!start || !end) return false;
  const now = new Date();
  // Note: quiet hours interpreted in UTC. Future improvement: honor user TZ.
  const cur = now.getUTCHours() * 60 + now.getUTCMinutes();
  const [sh, sm] = String(start).split(':').map(Number);
  const [eh, em] = String(end).split(':').map(Number);
  if ([sh, sm, eh, em].some((n) => Number.isNaN(n))) return false;
  const startMin = sh * 60 + sm;
  const endMin = eh * 60 + em;
  if (startMin === endMin) return false;
  if (startMin < endMin) return cur >= startMin && cur < endMin;
  // Crosses midnight
  return cur >= startMin || cur < endMin;
}

/**
 * Helper: Send FCM push notification to a user
 * Reads FCM token, checks notification preferences, sends via FCM, and writes in-app notification
 */
async function sendPushToUser(
  userId: string,
  type: string,
  title: string,
  body: string,
  data?: Record<string, string>,
  options?: SendOptions,
): Promise<boolean> {
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      logError(`sendPushToUser: User ${userId} not found`);
      return false;
    }

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;

    // Notification preferences
    const prefsDoc = await db.collection('notification_preferences').doc(userId).get();
    if (prefsDoc.exists) {
      const prefs = prefsDoc.data()!;

      // Master toggle (only blocks push, not in-app)
      if (prefs.pushNotificationsEnabled === false) {
        logInfo(`sendPushToUser: Push disabled (master) for user ${userId}`);
        await writeInAppNotification(userId, type, title, body, data);
        return false;
      }

      // Per-type toggle (flat field shape used by Flutter app)
      const fieldName = TYPE_TO_PREF_FIELD[type];
      if (fieldName && prefs[fieldName] === false) {
        logInfo(`sendPushToUser: Type ${type} disabled for user ${userId}`);
        await writeInAppNotification(userId, type, title, body, data);
        return false;
      }

      // Legacy enabledTypes map shape (backward compat)
      if (prefs.enabledTypes && prefs.enabledTypes[type] === false) {
        await writeInAppNotification(userId, type, title, body, data);
        return false;
      }

      // Quiet hours (skip suppression for critical notifications)
      if (!options?.isCritical && isInQuietHours(prefs)) {
        logInfo(`sendPushToUser: In quiet hours for user ${userId}`);
        await writeInAppNotification(userId, type, title, body, data);
        return false;
      }
    }

    if (!fcmToken) {
      logInfo(`sendPushToUser: No FCM token for user ${userId}`);
      await writeInAppNotification(userId, type, title, body, data);
      return false;
    }

    // Build FCM message
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
        ...(options?.imageUrl ? { imageUrl: options.imageUrl } : {}),
      },
      data: {
        type,
        timestamp: new Date().toISOString(),
        ...(data || {}),
      },
      android: {
        priority: 'high',
        ...(options?.collapseKey ? { collapseKey: options.collapseKey } : {}),
        notification: {
          sound: 'default',
          channelId: 'greengo_notifications',
          priority: 'high' as any,
          ...(options?.collapseKey ? { tag: options.collapseKey } : {}),
          ...(options?.imageUrl ? { imageUrl: options.imageUrl } : {}),
        },
      },
      apns: {
        ...(options?.collapseKey
          ? { headers: { 'apns-collapse-id': options.collapseKey } }
          : {}),
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            ...(options?.threadId ? { 'thread-id': options.threadId } : {}),
            ...(options?.isCritical ? { 'interruption-level': 'time-sensitive' as any } : {}),
          },
        },
      },
    };

    const response = await messaging.send(message);
    await writeInAppNotification(userId, type, title, body, data, response);
    logInfo(`sendPushToUser: Sent ${type} notification to user ${userId}`);
    return true;
  } catch (error: any) {
    if (
      error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered'
    ) {
      logInfo(`sendPushToUser: Clearing stale FCM token for user ${userId}`);
      await db.collection('users').doc(userId).update({ fcmToken: null }).catch(() => {});
    } else {
      logError(`sendPushToUser: Error sending to user ${userId}`, error);
    }
    return false;
  }
}

async function writeInAppNotification(
  userId: string,
  type: string,
  title: string,
  body: string,
  data?: Record<string, string>,
  fcmMessageId?: string,
): Promise<void> {
  try {
    await db.collection('notifications').add({
      userId,
      type,
      title,
      message: body, // Flutter NotificationModel reads `message`
      body, // legacy field for older clients
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      ...(fcmMessageId ? { sentAt: admin.firestore.FieldValue.serverTimestamp(), fcmMessageId } : {}),
      ...(data ? { data } : {}),
    });
  } catch (e) {
    logError('writeInAppNotification error', e);
  }
}

/**
 * Bidirectional block check between two users.
 * Returns true if either has blocked the other.
 */
async function isBlocked(userA: string, userB: string): Promise<boolean> {
  try {
    const [a, b] = await Promise.all([
      db
        .collection('blockedUsers')
        .where('blockerId', '==', userA)
        .where('blockedUserId', '==', userB)
        .limit(1)
        .get(),
      db
        .collection('blockedUsers')
        .where('blockerId', '==', userB)
        .where('blockedUserId', '==', userA)
        .limit(1)
        .get(),
    ]);
    return !a.empty || !b.empty;
  } catch (e) {
    logError('isBlocked error', e);
    return false;
  }
}

/**
 * onNewLikePush - Trigger on likes/{likeId} create
 */
export const onNewLikePush = onDocumentCreated(
  {
    document: 'likes/{likeId}',
    memory: '256MiB',
  },
  monitored("onNewLikePush", async (event) => {
    try {
      const data = event.data?.data();
      if (!data) return;

      const likedUserId = data.likedUserId;
      const likerId = data.likerId;
      const likeType = data.type;

      if (!likedUserId || !likerId) {
        logError('onNewLikePush: Missing likedUserId or likerId');
        return;
      }

      // Suppress if blocked either way
      if (await isBlocked(likerId, likedUserId)) {
        logInfo(`onNewLikePush: ${likerId} <-> ${likedUserId} blocked, skip`);
        return;
      }

      const likerDoc = await db.collection('users').doc(likerId).get();
      const likerName = likerDoc.data()?.displayName || 'Someone';

      let likerAvatar: string | undefined;
      try {
        const profDoc = await db.collection('profiles').doc(likerId).get();
        const profData = profDoc.data();
        likerAvatar = profData?.profilePhotoUrl || profData?.photos?.[0];
      } catch {}

      if (likeType === 'super_like') {
        await sendPushToUser(
          likedUserId,
          'superLike',
          'You received a Super Like!',
          `${likerName} sent you a Super Like!`,
          { fromUserId: likerId },
          { imageUrl: likerAvatar, threadId: 'likes' },
        );
      } else {
        await sendPushToUser(
          likedUserId,
          'newLike',
          'Someone liked your profile!',
          `${likerName} liked your profile`,
          { fromUserId: likerId },
          { imageUrl: likerAvatar, threadId: 'likes' },
        );
      }
    } catch (error) {
      logError('onNewLikePush: Error', error);
    }
  }),
);

/**
 * onNewMatchPush - Trigger on matches/{matchId} create
 */
export const onNewMatchPush = onDocumentCreated(
  {
    document: 'matches/{matchId}',
    memory: '256MiB',
  },
  monitored("onNewMatchPush", async (event) => {
    try {
      const data = event.data?.data();
      if (!data) return;

      const users: string[] = data.users || [];
      const user1Id = data.user1Id || users[0];
      const user2Id = data.user2Id || users[1];

      if (!user1Id || !user2Id) {
        logError('onNewMatchPush: Missing user IDs in match document');
        return;
      }

      if (await isBlocked(user1Id, user2Id)) {
        logInfo(`onNewMatchPush: ${user1Id} <-> ${user2Id} blocked, skip`);
        return;
      }

      const [user1Doc, user2Doc] = await Promise.all([
        db.collection('users').doc(user1Id).get(),
        db.collection('users').doc(user2Id).get(),
      ]);

      const user1Name = user1Doc.data()?.displayName || 'Someone';
      const user2Name = user2Doc.data()?.displayName || 'Someone';

      let user1Avatar: string | undefined;
      let user2Avatar: string | undefined;
      try {
        const [p1, p2] = await Promise.all([
          db.collection('profiles').doc(user1Id).get(),
          db.collection('profiles').doc(user2Id).get(),
        ]);
        user1Avatar = p1.data()?.profilePhotoUrl || p1.data()?.photos?.[0];
        user2Avatar = p2.data()?.profilePhotoUrl || p2.data()?.photos?.[0];
      } catch {}

      const matchId = event.params.matchId;

      await Promise.all([
        sendPushToUser(
          user1Id,
          'newMatch',
          'You have a new match!',
          `You matched with ${user2Name}!`,
          { matchId, matchedUserId: user2Id },
          { imageUrl: user2Avatar, threadId: 'matches' },
        ),
        sendPushToUser(
          user2Id,
          'newMatch',
          'You have a new match!',
          `You matched with ${user1Name}!`,
          { matchId, matchedUserId: user1Id },
          { imageUrl: user1Avatar, threadId: 'matches' },
        ),
      ]);
    } catch (error) {
      logError('onNewMatchPush: Error', error);
    }
  }),
);

/**
 * onNewMessagePush - Trigger on conversations/{convId}/messages/{msgId} create
 * Sends "{senderName}" with message preview to recipient(s).
 * Honors per-user mute (`conversations.mutedBy[recipientId]`), legacy global mute,
 * bidirectional blocks, and stacks notifications per-conversation via collapseKey/threadId.
 */
export const onNewMessagePush = onDocumentCreated(
  {
    document: 'conversations/{convId}/messages/{msgId}',
    memory: '256MiB',
  },
  monitored("onNewMessagePush", async (event) => {
    try {
      const data = event.data?.data();
      if (!data) return;

      const senderId = data.senderId;
      const convId = event.params.convId;

      if (!senderId) {
        logError('onNewMessagePush: Missing senderId');
        return;
      }

      const convDoc = await db.collection('conversations').doc(convId).get();
      if (!convDoc.exists) {
        logError(`onNewMessagePush: Conversation ${convId} not found`);
        return;
      }

      const convData = convDoc.data()!;
      const participants: string[] = convData.participants || [];
      const mutedBy: Record<string, number> = convData.mutedBy || {};
      const globallyMuted =
        convData.isMuted === true &&
        (!convData.mutedUntil || convData.mutedUntil.toMillis() > Date.now());

      // Sender info for title + avatar
      const senderDoc = await db.collection('users').doc(senderId).get();
      const senderData = senderDoc.data() || {};
      const senderName = senderData.displayName || 'Someone';

      let senderAvatar: string | undefined;
      try {
        const profDoc = await db.collection('profiles').doc(senderId).get();
        const profData = profDoc.data();
        senderAvatar = profData?.profilePhotoUrl || profData?.photos?.[0];
      } catch {}

      // Build message preview
      const messageText = data.text || data.content || '';
      const messageType = data.type || 'text';
      let preview: string;
      if (messageType === 'image') preview = '📷 Photo';
      else if (messageType === 'voice') preview = '🎤 Voice message';
      else if (messageType === 'video') preview = '🎥 Video';
      else if (messageText.length > 100) preview = messageText.substring(0, 97) + '...';
      else preview = messageText;

      const recipients = participants.filter((id: string) => id !== senderId);
      const now = Date.now();

      await Promise.all(
        recipients.map(async (recipientId: string) => {
          // Per-user mute (mutedBy map: 0 = forever, > 0 = epoch ms expiry)
          const mutedExpiry = mutedBy[recipientId];
          if (mutedExpiry !== undefined) {
            if (mutedExpiry === 0 || mutedExpiry > now) {
              logInfo(`onNewMessagePush: conv ${convId} muted for ${recipientId}, skip`);
              return;
            }
          }

          // Legacy global mute (per-conversation)
          if (globallyMuted) {
            logInfo(`onNewMessagePush: conv ${convId} globally muted, skip`);
            return;
          }

          // Bidirectional block list
          if (await isBlocked(senderId, recipientId)) {
            logInfo(`onNewMessagePush: ${senderId} <-> ${recipientId} blocked, skip`);
            return;
          }

          await sendPushToUser(
            recipientId,
            'newMessage',
            senderName,
            preview,
            {
              conversationId: convId,
              fromUserId: senderId,
              senderName,
              messageType,
            },
            {
              imageUrl: senderAvatar,
              collapseKey: convId, // Replaces previous notif from same conversation
              threadId: convId, // iOS groups them
            },
          );
        }),
      );
    } catch (error) {
      logError('onNewMessagePush: Error', error);
    }
  }),
);

/**
 * onSupportMessagePush - Trigger on support_messages/{msgId} create
 */
export const onSupportMessagePush = onDocumentCreated(
  {
    document: 'support_messages/{msgId}',
    memory: '256MiB',
  },
  monitored("onSupportMessagePush", async (event) => {
    try {
      const data = event.data?.data();
      if (!data) return;

      const senderType = data.senderType;
      const conversationId = data.conversationId;

      if (!conversationId) {
        logError('onSupportMessagePush: Missing conversationId');
        return;
      }

      const chatDoc = await db.collection('support_chats').doc(conversationId).get();
      if (!chatDoc.exists) {
        logError(`onSupportMessagePush: support_chats/${conversationId} not found`);
        return;
      }

      const chatData = chatDoc.data()!;

      if (senderType === 'admin') {
        const userId = chatData.userId;
        if (!userId) {
          logError('onSupportMessagePush: No userId in support_chats doc');
          return;
        }

        await sendPushToUser(
          userId,
          'supportReply',
          'Support replied to your ticket',
          data.text || 'You have a new reply from support.',
          { conversationId, action: 'support_message' },
          { collapseKey: `support_${conversationId}`, threadId: `support_${conversationId}` },
        );
      } else if (senderType === 'user') {
        const agentId = chatData.supportAgentId || chatData.assignedTo;
        if (!agentId) {
          logInfo('onSupportMessagePush: No assigned agent for this ticket');
          return;
        }

        await sendPushToUser(
          agentId,
          'supportMessage',
          'New message on support ticket',
          data.text || 'A user sent a new message.',
          { conversationId, action: 'support_message' },
          { collapseKey: `support_${conversationId}`, threadId: `support_${conversationId}` },
        );
      }
    } catch (error) {
      logError('onSupportMessagePush: Error', error);
    }
  }),
);

/**
 * checkExpiringModes - Scheduled every 15 minutes
 */
export const checkExpiringModes = onSchedule(
  {
    schedule: 'every 15 minutes',
    memory: '256MiB',
    timeZone: 'UTC',
  },
  monitored("checkExpiringModes", async () => {
    try {
      const now = admin.firestore.Timestamp.now();
      const oneHourFromNow = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 60 * 60 * 1000,
      );

      const incognitoSnap = await db
        .collection('profiles')
        .where('isIncognito', '==', true)
        .where('incognitoExpiry', '>', now)
        .where('incognitoExpiry', '<=', oneHourFromNow)
        .get();

      for (const doc of incognitoSnap.docs) {
        const data = doc.data();
        if (data.incognitoWarningNotified) continue;

        await sendPushToUser(
          doc.id,
          'modeExpiry',
          'Incognito Mode Expiring Soon',
          'Your Incognito Mode expires in less than 1 hour!',
        );

        await doc.ref.update({ incognitoWarningNotified: true });
        logInfo(`checkExpiringModes: Warned ${doc.id} about incognito expiry`);
      }

      const travelerSnap = await db
        .collection('profiles')
        .where('isTraveler', '==', true)
        .where('travelerExpiry', '>', now)
        .where('travelerExpiry', '<=', oneHourFromNow)
        .get();

      for (const doc of travelerSnap.docs) {
        const data = doc.data();
        if (data.travelerWarningNotified) continue;

        await sendPushToUser(
          doc.id,
          'modeExpiry',
          'Traveler Mode Expiring Soon',
          'Your Traveler Mode expires in less than 1 hour!',
        );

        await doc.ref.update({ travelerWarningNotified: true });
        logInfo(`checkExpiringModes: Warned ${doc.id} about traveler expiry`);
      }
    } catch (error) {
      logError('checkExpiringModes: Error', error);
    }
  }),
);

/**
 * onVerificationStatusChange - Trigger on profiles/{userId} update
 */
export const onVerificationStatusChange = onDocumentUpdated(
  {
    document: 'profiles/{userId}',
    memory: '256MiB',
  },
  monitored("onVerificationStatusChange", async (event) => {
    try {
      const beforeData = event.data?.before?.data();
      const afterData = event.data?.after?.data();
      if (!beforeData || !afterData) return;

      const beforeStatus = beforeData.verificationStatus;
      const afterStatus = afterData.verificationStatus;

      if (beforeStatus === afterStatus) return;

      const userId = event.params.userId;
      const reason = afterData.verificationReason || afterData.verificationNote || '';

      if (afterStatus === 'approved') {
        await sendPushToUser(
          userId,
          'verification',
          'Profile Verified!',
          'Your profile has been verified! You now have a verified badge.',
          undefined,
          { isCritical: true },
        );
      } else if (afterStatus === 'needsResubmission') {
        const body = reason
          ? `Please submit a new verification photo. Reason: ${reason}`
          : 'Please submit a new verification photo.';
        await sendPushToUser(
          userId,
          'verification',
          'New Verification Photo Needed',
          body,
          undefined,
          { isCritical: true },
        );
      } else if (afterStatus === 'rejected') {
        const body = reason
          ? `Your verification was not approved. Reason: ${reason}`
          : 'Your verification was not approved. Please try again.';
        await sendPushToUser(
          userId,
          'verification',
          'Verification Update',
          body,
          undefined,
          { isCritical: true },
        );
      }
    } catch (error) {
      logError('onVerificationStatusChange: Error', error);
    }
  }),
);
