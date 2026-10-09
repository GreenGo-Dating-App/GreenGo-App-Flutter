/**
 * Push Notification Firestore Triggers
 * Auto-send push notifications when likes, matches, and messages are created
 */

import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { brandPush, messagePush } from './brand';
import { shouldNotify } from './prefs';
import { logInfo, logError } from '../shared/utils';
import { monitored } from '../shared/monitoring';
import { PUSH_MEMORY } from '../shared/pushRuntime';
import { AppLocale, LText, lt, notifTextFields, rawText, render, t } from '../shared/i18n';
import { mediaLabel, truncatePreview } from '../shared/i18n/chatPreview';
import { resolveLocale } from '../shared/i18n/recipientLocale';

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
  actorId?: string; // actor identity → in-app tile avatar + tappable name
  actorName?: string;
  /** Show [title]/[body] as they are (chat messages: sender name + text). */
  messageStyle?: boolean;
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
/**
 * Text for sendPushToUser: a catalog/raw LText, or a function of the
 * recipient's locale (chat previews: localized media labels).
 */
type PushText = LText | ((locale: AppLocale) => string);

function pushText(locale: AppLocale, v: PushText): string {
  return typeof v === 'function' ? v(locale) : render(locale, v);
}

/** Doc-storable form: functions are stored as their English rendering. */
function storable(v: PushText): LText {
  return typeof v === 'function' ? rawText(v('en')) : v;
}

async function sendPushToUser(
  userId: string,
  type: string,
  titleText: PushText,
  bodyText: PushText,
  data?: Record<string, string>,
  options?: SendOptions,
): Promise<boolean> {
  const title = storable(titleText);
  const body = storable(bodyText);
  // Actor identity for the in-app tile (avatar + tappable name). Threaded into
  // every writeInAppNotification branch below so the feed doc always names who
  // acted, exactly like the push does.
  const actor =
    options?.actorId || options?.actorName || options?.imageUrl
      ? { imageUrl: options?.imageUrl, actorId: options?.actorId, actorName: options?.actorName }
      : undefined;
  try {
    // PUSH-DELIVERY FILTER: non-message types are in-app only (no APNs/FCM).
    // Everything still lands on the in-app notifications page unchanged.
    if (!PUSH_ELIGIBLE_TYPES.has(type)) {
      await writeInAppNotification(userId, type, title, body, data, undefined, actor);
      return false;
    }

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      logError(`sendPushToUser: User ${userId} not found`);
      return false;
    }

    const userData = userDoc.data()!;
    const fcmToken = userData.fcmToken;
    const locale = fcmToken ? await resolveLocale(userId, { userData }) : 'en';
    const pushTitle = pushText(locale, titleText);
    const pushBody = pushText(locale, bodyText);

    // Notification preferences
    const prefsDoc = await db.collection('notification_preferences').doc(userId).get();
    if (prefsDoc.exists) {
      const prefs = prefsDoc.data()!;

      // Master toggle (only blocks push, not in-app)
      if (prefs.pushNotificationsEnabled === false) {
        logInfo(`sendPushToUser: Push disabled (master) for user ${userId}`);
        await writeInAppNotification(userId, type, title, body, data, undefined, actor);
        return false;
      }

      // Per-type toggle (flat field shape used by Flutter app)
      const fieldName = TYPE_TO_PREF_FIELD[type];
      if (fieldName && prefs[fieldName] === false) {
        logInfo(`sendPushToUser: Type ${type} disabled for user ${userId}`);
        await writeInAppNotification(userId, type, title, body, data, undefined, actor);
        return false;
      }

      // Legacy enabledTypes map shape (backward compat)
      if (prefs.enabledTypes && prefs.enabledTypes[type] === false) {
        await writeInAppNotification(userId, type, title, body, data, undefined, actor);
        return false;
      }

      // Quiet hours (skip suppression for critical notifications)
      if (!options?.isCritical && isInQuietHours(prefs)) {
        logInfo(`sendPushToUser: In quiet hours for user ${userId}`);
        await writeInAppNotification(userId, type, title, body, data, undefined, actor);
        return false;
      }
    }

    if (!fcmToken) {
      logInfo(`sendPushToUser: No FCM token for user ${userId}`);
      await writeInAppNotification(userId, type, title, body, data, undefined, actor);
      return false;
    }

    // Build FCM message
    const message: admin.messaging.Message = {
      token: fcmToken,
      notification: options?.messageStyle
        ? messagePush(pushTitle, pushBody, options?.imageUrl)
        : brandPush(pushTitle, pushBody, options?.imageUrl),
      data: {
        type,
        timestamp: new Date().toISOString(),
        ...(data || {}),
        // Actor identity in the push data so the background handler can name +
        // link who acted.
        ...(actor?.actorId ? { actorId: actor.actorId } : {}),
        ...(actor?.actorName ? { actorName: actor.actorName } : {}),
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
    await writeInAppNotification(userId, type, title, body, data, response, actor);
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
  title: LText,
  body: LText,
  data?: Record<string, string>,
  fcmMessageId?: string,
  actor?: { imageUrl?: string; actorId?: string; actorName?: string },
): Promise<void> {
  try {
    await db.collection('notifications').add({
      userId,
      type,
      // English title/message/body (+ titleKey/bodyKey/params when keyed).
      ...notifTextFields(title, body),
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
    memory: PUSH_MEMORY,
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
      // Empty when unknown: the push shows a localized "Unknown user".
      const senderName = ((senderData.displayName as string) || '').trim();

      let senderAvatar: string | undefined;
      try {
        const profDoc = await db.collection('profiles').doc(senderId).get();
        const profData = profDoc.data();
        senderAvatar = profData?.profilePhotoUrl || profData?.photos?.[0];
      } catch {}

      // Build message preview
      const messageText = data.text || data.content || '';
      const messageType = data.type || 'text';
      // Media label in the RECIPIENT's language, else the text itself.
      const preview = (locale: AppLocale): string =>
        mediaLabel(locale, messageType) ?? truncatePreview(messageText, 100);
      const titleFor = (locale: AppLocale): string =>
        senderName || t(locale, 'srvUnknownUser');

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

          // BOTH normal 1:1 and business-inquiry conversations notify under the
          // always-on 'exchanges' channel. Business chats must ALWAYS be visible
          // to everyone, so a message from/to a business is delivered exactly
          // like a message from/to a normal person — never separately gated.
          if (!(await shouldNotify(recipientId, 'exchanges'))) return;

          // Title = the sender's name, body = the message itself (product
          // decision 2026-10-03; see messagePush).
          await sendPushToUser(
            recipientId,
            'newMessage',
            titleFor,
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
              messageStyle: true,
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
    memory: PUSH_MEMORY,
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
          lt('notifServerSupportReplied'),
          data.text ? rawText(data.text) : lt('notifServerSupportNewReply'),
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
          lt('srvSupportNewMessageOnTicket'),
          data.text ? rawText(data.text) : lt('srvSupportUserSentMessage'),
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
    memory: PUSH_MEMORY,
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
          lt('notifServerIncognitoExpiring'),
          lt('notifServerIncognitoExpiringBody'),
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
          lt('notifServerTravelerExpiring'),
          lt('notifServerTravelerExpiringBody'),
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
    memory: PUSH_MEMORY,
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
          lt('notifServerProfileVerified'),
          lt('notifServerProfileVerifiedBody'),
          undefined,
          { isCritical: true },
        );
      } else if (afterStatus === 'needsResubmission') {
        const body = reason
          ? lt('srvVerificationResubmitReason', { reason: String(reason) })
          : lt('srvVerificationResubmit');
        await sendPushToUser(
          userId,
          'verification',
          lt('notifServerNewVerificationPhoto'),
          body,
          undefined,
          { isCritical: true },
        );
      } else if (afterStatus === 'rejected') {
        const body = reason
          ? lt('srvVerificationRejectedReason', { reason: String(reason) })
          : lt('srvVerificationRejected');
        await sendPushToUser(
          userId,
          'verification',
          lt('notifServerVerificationUpdate'),
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
