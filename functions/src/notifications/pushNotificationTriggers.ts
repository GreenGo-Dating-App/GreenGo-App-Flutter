/**
 * Push Notification Firestore Triggers
 * Auto-send push notifications when likes, matches, and messages are created
 */

import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { brandPush } from './brand';
import { shouldNotify } from './prefs';
import { logInfo, logError } from '../shared/utils';
import { monitored } from '../shared/monitoring';

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * PUSH-DELIVERY FILTER.
 *
 * A real push (APNs on iOS / FCM on Android) is sent ONLY for:
 *   (A) a NEW MESSAGE — direct 1:1 exchange (this file, type `newMessage`),
 *       community group chat (group_chat/fanout.ts) and event group chat
 *       (events/broadcast.ts) each handle their own multicast; and
 *   (B) a business a user follows publishing a new event
 *       (events/business_new_event.ts).
 *
 * Every OTHER notification type routed through `sendPushToUser` (likes,
 * super-likes, matches, support replies, mode-expiry, verification, streaks,
 * referrals, missions, system, generic, etc.) is written to the in-app
 * `notifications` collection ONLY — never pushed. This set is the single
 * enforcement point for that rule for this module.
 */
const PUSH_ELIGIBLE_TYPES = new Set<string>(['newMessage']);

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
    // PUSH-DELIVERY FILTER: non-message types are in-app only (no APNs/FCM).
    // Everything still lands on the in-app notifications page unchanged.
    if (!PUSH_ELIGIBLE_TYPES.has(type)) {
      await writeInAppNotification(userId, type, title, body, data);
      return false;
    }

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
      notification: brandPush(title, body, options?.imageUrl),
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
  actor?: { imageUrl?: string; actorId?: string; actorName?: string },
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
      // Only when THIS module actually pushed (fcmMessageId present) do we set
      // pushSent so the parity trigger skips it. When no push was sent (in-app
      // only: non-eligible type, muted, quiet hours, no token) we leave it unset
      // so onNotificationCreatedPush delivers the parity push.
      ...(fcmMessageId ? { sentAt: admin.firestore.FieldValue.serverTimestamp(), fcmMessageId, pushSent: true } : {}),
      ...(data ? { data } : {}),
      // Actor identity — drives the left avatar + the tappable bold name in the
      // Flutter notification tile.
      ...(actor?.imageUrl ? { imageUrl: actor.imageUrl } : {}),
      ...(actor?.actorId ? { actorId: actor.actorId } : {}),
      ...(actor?.actorName ? { actorName: actor.actorName } : {}),
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

// onNewLikePush and onNewMatchPush were REMOVED — GreenGo is a cross-cultural
// networking app, not a dating app, so it never pushes "new like / super like /
// new match" notifications. The underlying likes/matches collections remain for
// the connection mechanic; they simply no longer generate a push.

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

          // Per-category notification preference (messages).
          if (!(await shouldNotify(recipientId, 'messages'))) return;

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
