"use strict";
/**
 * Push Notification Firestore Triggers
 * Auto-send push notifications when likes, matches, and messages are created
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
exports.onVerificationStatusChange = exports.checkExpiringModes = exports.onSupportMessagePush = exports.onNewMessagePush = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const brand_1 = require("./brand");
const prefs_1 = require("./prefs");
const utils_1 = require("../shared/utils");
const monitoring_1 = require("../shared/monitoring");
const pushRuntime_1 = require("../shared/pushRuntime");
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
const PUSH_ELIGIBLE_TYPES = new Set(['newMessage']);
// Maps notification "type" to the flat boolean field used by the Flutter app.
const TYPE_TO_PREF_FIELD = {
    newMessage: 'newMessageNotifications',
    newMatch: 'newMatchNotifications',
    newLike: 'newLikeNotifications',
    superLike: 'superLikeNotifications',
    profileView: 'profileViewNotifications',
    matchExpiring: 'matchExpiringNotifications',
};
function isInQuietHours(prefs) {
    if (!(prefs === null || prefs === void 0 ? void 0 : prefs.quietHoursEnabled))
        return false;
    const start = prefs.quietHoursStart;
    const end = prefs.quietHoursEnd;
    if (!start || !end)
        return false;
    const now = new Date();
    // Note: quiet hours interpreted in UTC. Future improvement: honor user TZ.
    const cur = now.getUTCHours() * 60 + now.getUTCMinutes();
    const [sh, sm] = String(start).split(':').map(Number);
    const [eh, em] = String(end).split(':').map(Number);
    if ([sh, sm, eh, em].some((n) => Number.isNaN(n)))
        return false;
    const startMin = sh * 60 + sm;
    const endMin = eh * 60 + em;
    if (startMin === endMin)
        return false;
    if (startMin < endMin)
        return cur >= startMin && cur < endMin;
    // Crosses midnight
    return cur >= startMin || cur < endMin;
}
/**
 * Helper: Send FCM push notification to a user
 * Reads FCM token, checks notification preferences, sends via FCM, and writes in-app notification
 */
async function sendPushToUser(userId, type, title, body, data, options) {
    // Actor identity for the in-app tile (avatar + tappable name). Threaded into
    // every writeInAppNotification branch below so the feed doc always names who
    // acted, exactly like the push does.
    const actor = (options === null || options === void 0 ? void 0 : options.actorId) || (options === null || options === void 0 ? void 0 : options.actorName) || (options === null || options === void 0 ? void 0 : options.imageUrl)
        ? { imageUrl: options === null || options === void 0 ? void 0 : options.imageUrl, actorId: options === null || options === void 0 ? void 0 : options.actorId, actorName: options === null || options === void 0 ? void 0 : options.actorName }
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
            (0, utils_1.logError)(`sendPushToUser: User ${userId} not found`);
            return false;
        }
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        // Notification preferences
        const prefsDoc = await db.collection('notification_preferences').doc(userId).get();
        if (prefsDoc.exists) {
            const prefs = prefsDoc.data();
            // Master toggle (only blocks push, not in-app)
            if (prefs.pushNotificationsEnabled === false) {
                (0, utils_1.logInfo)(`sendPushToUser: Push disabled (master) for user ${userId}`);
                await writeInAppNotification(userId, type, title, body, data, undefined, actor);
                return false;
            }
            // Per-type toggle (flat field shape used by Flutter app)
            const fieldName = TYPE_TO_PREF_FIELD[type];
            if (fieldName && prefs[fieldName] === false) {
                (0, utils_1.logInfo)(`sendPushToUser: Type ${type} disabled for user ${userId}`);
                await writeInAppNotification(userId, type, title, body, data, undefined, actor);
                return false;
            }
            // Legacy enabledTypes map shape (backward compat)
            if (prefs.enabledTypes && prefs.enabledTypes[type] === false) {
                await writeInAppNotification(userId, type, title, body, data, undefined, actor);
                return false;
            }
            // Quiet hours (skip suppression for critical notifications)
            if (!(options === null || options === void 0 ? void 0 : options.isCritical) && isInQuietHours(prefs)) {
                (0, utils_1.logInfo)(`sendPushToUser: In quiet hours for user ${userId}`);
                await writeInAppNotification(userId, type, title, body, data, undefined, actor);
                return false;
            }
        }
        if (!fcmToken) {
            (0, utils_1.logInfo)(`sendPushToUser: No FCM token for user ${userId}`);
            await writeInAppNotification(userId, type, title, body, data, undefined, actor);
            return false;
        }
        // Build FCM message
        const message = {
            token: fcmToken,
            notification: (0, brand_1.brandPush)(title, body, options === null || options === void 0 ? void 0 : options.imageUrl),
            data: Object.assign(Object.assign(Object.assign({ type, timestamp: new Date().toISOString() }, (data || {})), ((actor === null || actor === void 0 ? void 0 : actor.actorId) ? { actorId: actor.actorId } : {})), ((actor === null || actor === void 0 ? void 0 : actor.actorName) ? { actorName: actor.actorName } : {})),
            android: Object.assign(Object.assign({ priority: 'high' }, ((options === null || options === void 0 ? void 0 : options.collapseKey) ? { collapseKey: options.collapseKey } : {})), { notification: Object.assign(Object.assign({ sound: 'default', channelId: 'greengo_notifications', priority: 'high' }, ((options === null || options === void 0 ? void 0 : options.collapseKey) ? { tag: options.collapseKey } : {})), ((options === null || options === void 0 ? void 0 : options.imageUrl) ? { imageUrl: options.imageUrl } : {})) }),
            apns: Object.assign(Object.assign({}, ((options === null || options === void 0 ? void 0 : options.collapseKey)
                ? { headers: { 'apns-collapse-id': options.collapseKey } }
                : {})), { payload: {
                    aps: Object.assign(Object.assign({ sound: 'default', badge: 1 }, ((options === null || options === void 0 ? void 0 : options.threadId) ? { 'thread-id': options.threadId } : {})), ((options === null || options === void 0 ? void 0 : options.isCritical) ? { 'interruption-level': 'time-sensitive' } : {})),
                } }),
        };
        const response = await messaging.send(message);
        await writeInAppNotification(userId, type, title, body, data, response, actor);
        (0, utils_1.logInfo)(`sendPushToUser: Sent ${type} notification to user ${userId}`);
        return true;
    }
    catch (error) {
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
            (0, utils_1.logInfo)(`sendPushToUser: Clearing stale FCM token for user ${userId}`);
            await db.collection('users').doc(userId).update({ fcmToken: null }).catch(() => { });
        }
        else {
            (0, utils_1.logError)(`sendPushToUser: Error sending to user ${userId}`, error);
        }
        return false;
    }
}
async function writeInAppNotification(userId, type, title, body, data, fcmMessageId, actor) {
    try {
        await db.collection('notifications').add(Object.assign(Object.assign(Object.assign(Object.assign(Object.assign({ userId,
            type,
            title, message: body, // Flutter NotificationModel reads `message`
            body, createdAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false }, (fcmMessageId ? { sentAt: admin.firestore.FieldValue.serverTimestamp(), fcmMessageId, pushSent: true } : {})), (data ? { data } : {})), ((actor === null || actor === void 0 ? void 0 : actor.imageUrl) ? { imageUrl: actor.imageUrl } : {})), ((actor === null || actor === void 0 ? void 0 : actor.actorId) ? { actorId: actor.actorId } : {})), ((actor === null || actor === void 0 ? void 0 : actor.actorName) ? { actorName: actor.actorName } : {})));
    }
    catch (e) {
        (0, utils_1.logError)('writeInAppNotification error', e);
    }
}
/**
 * Bidirectional block check between two users.
 * Returns true if either has blocked the other.
 */
async function isBlocked(userA, userB) {
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
    }
    catch (e) {
        (0, utils_1.logError)('isBlocked error', e);
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
exports.onNewMessagePush = (0, firestore_1.onDocumentCreated)({
    document: 'conversations/{convId}/messages/{msgId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)("onNewMessagePush", async (event) => {
    var _a, _b;
    try {
        const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!data)
            return;
        const senderId = data.senderId;
        const convId = event.params.convId;
        if (!senderId) {
            (0, utils_1.logError)('onNewMessagePush: Missing senderId');
            return;
        }
        const convDoc = await db.collection('conversations').doc(convId).get();
        if (!convDoc.exists) {
            (0, utils_1.logError)(`onNewMessagePush: Conversation ${convId} not found`);
            return;
        }
        const convData = convDoc.data();
        const participants = convData.participants || [];
        const mutedBy = convData.mutedBy || {};
        const globallyMuted = convData.isMuted === true &&
            (!convData.mutedUntil || convData.mutedUntil.toMillis() > Date.now());
        // Sender info for title + avatar
        const senderDoc = await db.collection('users').doc(senderId).get();
        const senderData = senderDoc.data() || {};
        const senderName = senderData.displayName || 'Someone';
        let senderAvatar;
        try {
            const profDoc = await db.collection('profiles').doc(senderId).get();
            const profData = profDoc.data();
            senderAvatar = (profData === null || profData === void 0 ? void 0 : profData.profilePhotoUrl) || ((_b = profData === null || profData === void 0 ? void 0 : profData.photos) === null || _b === void 0 ? void 0 : _b[0]);
        }
        catch (_c) { }
        // Build message preview
        const messageText = data.text || data.content || '';
        const messageType = data.type || 'text';
        let preview;
        if (messageType === 'image')
            preview = '📷 Photo';
        else if (messageType === 'voice')
            preview = '🎤 Voice message';
        else if (messageType === 'video')
            preview = '🎥 Video';
        else if (messageText.length > 100)
            preview = messageText.substring(0, 97) + '...';
        else
            preview = messageText;
        const recipients = participants.filter((id) => id !== senderId);
        const now = Date.now();
        await Promise.all(recipients.map(async (recipientId) => {
            // Per-user mute (mutedBy map: 0 = forever, > 0 = epoch ms expiry)
            const mutedExpiry = mutedBy[recipientId];
            if (mutedExpiry !== undefined) {
                if (mutedExpiry === 0 || mutedExpiry > now) {
                    (0, utils_1.logInfo)(`onNewMessagePush: conv ${convId} muted for ${recipientId}, skip`);
                    return;
                }
            }
            // Legacy global mute (per-conversation)
            if (globallyMuted) {
                (0, utils_1.logInfo)(`onNewMessagePush: conv ${convId} globally muted, skip`);
                return;
            }
            // Bidirectional block list
            if (await isBlocked(senderId, recipientId)) {
                (0, utils_1.logInfo)(`onNewMessagePush: ${senderId} <-> ${recipientId} blocked, skip`);
                return;
            }
            // Per-category notification preference (messages).
            if (!(await (0, prefs_1.shouldNotify)(recipientId, 'messages')))
                return;
            await sendPushToUser(recipientId, 'newMessage', senderName, preview, {
                conversationId: convId,
                fromUserId: senderId,
                senderName,
                messageType,
            }, {
                imageUrl: senderAvatar,
                collapseKey: convId, // Replaces previous notif from same conversation
                threadId: convId, // iOS groups them
            });
        }));
    }
    catch (error) {
        (0, utils_1.logError)('onNewMessagePush: Error', error);
    }
}));
/**
 * onSupportMessagePush - Trigger on support_messages/{msgId} create
 */
exports.onSupportMessagePush = (0, firestore_1.onDocumentCreated)({
    document: 'support_messages/{msgId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)("onSupportMessagePush", async (event) => {
    var _a;
    try {
        const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!data)
            return;
        const senderType = data.senderType;
        const conversationId = data.conversationId;
        if (!conversationId) {
            (0, utils_1.logError)('onSupportMessagePush: Missing conversationId');
            return;
        }
        const chatDoc = await db.collection('support_chats').doc(conversationId).get();
        if (!chatDoc.exists) {
            (0, utils_1.logError)(`onSupportMessagePush: support_chats/${conversationId} not found`);
            return;
        }
        const chatData = chatDoc.data();
        if (senderType === 'admin') {
            const userId = chatData.userId;
            if (!userId) {
                (0, utils_1.logError)('onSupportMessagePush: No userId in support_chats doc');
                return;
            }
            await sendPushToUser(userId, 'supportReply', 'Support replied to your ticket', data.text || 'You have a new reply from support.', { conversationId, action: 'support_message' }, { collapseKey: `support_${conversationId}`, threadId: `support_${conversationId}` });
        }
        else if (senderType === 'user') {
            const agentId = chatData.supportAgentId || chatData.assignedTo;
            if (!agentId) {
                (0, utils_1.logInfo)('onSupportMessagePush: No assigned agent for this ticket');
                return;
            }
            await sendPushToUser(agentId, 'supportMessage', 'New message on support ticket', data.text || 'A user sent a new message.', { conversationId, action: 'support_message' }, { collapseKey: `support_${conversationId}`, threadId: `support_${conversationId}` });
        }
    }
    catch (error) {
        (0, utils_1.logError)('onSupportMessagePush: Error', error);
    }
}));
/**
 * checkExpiringModes - Scheduled every 15 minutes
 */
exports.checkExpiringModes = (0, scheduler_1.onSchedule)({
    schedule: 'every 15 minutes',
    memory: pushRuntime_1.PUSH_MEMORY,
    timeZone: 'UTC',
}, (0, monitoring_1.monitored)("checkExpiringModes", async () => {
    try {
        const now = admin.firestore.Timestamp.now();
        const oneHourFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 60 * 60 * 1000);
        const incognitoSnap = await db
            .collection('profiles')
            .where('isIncognito', '==', true)
            .where('incognitoExpiry', '>', now)
            .where('incognitoExpiry', '<=', oneHourFromNow)
            .get();
        for (const doc of incognitoSnap.docs) {
            const data = doc.data();
            if (data.incognitoWarningNotified)
                continue;
            await sendPushToUser(doc.id, 'modeExpiry', 'Incognito Mode Expiring Soon', 'Your Incognito Mode expires in less than 1 hour!');
            await doc.ref.update({ incognitoWarningNotified: true });
            (0, utils_1.logInfo)(`checkExpiringModes: Warned ${doc.id} about incognito expiry`);
        }
        const travelerSnap = await db
            .collection('profiles')
            .where('isTraveler', '==', true)
            .where('travelerExpiry', '>', now)
            .where('travelerExpiry', '<=', oneHourFromNow)
            .get();
        for (const doc of travelerSnap.docs) {
            const data = doc.data();
            if (data.travelerWarningNotified)
                continue;
            await sendPushToUser(doc.id, 'modeExpiry', 'Traveler Mode Expiring Soon', 'Your Traveler Mode expires in less than 1 hour!');
            await doc.ref.update({ travelerWarningNotified: true });
            (0, utils_1.logInfo)(`checkExpiringModes: Warned ${doc.id} about traveler expiry`);
        }
    }
    catch (error) {
        (0, utils_1.logError)('checkExpiringModes: Error', error);
    }
}));
/**
 * onVerificationStatusChange - Trigger on profiles/{userId} update
 */
exports.onVerificationStatusChange = (0, firestore_1.onDocumentUpdated)({
    document: 'profiles/{userId}',
    memory: pushRuntime_1.PUSH_MEMORY,
}, (0, monitoring_1.monitored)("onVerificationStatusChange", async (event) => {
    var _a, _b, _c, _d;
    try {
        const beforeData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data();
        const afterData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.data();
        if (!beforeData || !afterData)
            return;
        const beforeStatus = beforeData.verificationStatus;
        const afterStatus = afterData.verificationStatus;
        if (beforeStatus === afterStatus)
            return;
        const userId = event.params.userId;
        const reason = afterData.verificationReason || afterData.verificationNote || '';
        if (afterStatus === 'approved') {
            await sendPushToUser(userId, 'verification', 'Profile Verified!', 'Your profile has been verified! You now have a verified badge.', undefined, { isCritical: true });
        }
        else if (afterStatus === 'needsResubmission') {
            const body = reason
                ? `Please submit a new verification photo. Reason: ${reason}`
                : 'Please submit a new verification photo.';
            await sendPushToUser(userId, 'verification', 'New Verification Photo Needed', body, undefined, { isCritical: true });
        }
        else if (afterStatus === 'rejected') {
            const body = reason
                ? `Your verification was not approved. Reason: ${reason}`
                : 'Your verification was not approved. Please try again.';
            await sendPushToUser(userId, 'verification', 'Verification Update', body, undefined, { isCritical: true });
        }
    }
    catch (error) {
        (0, utils_1.logError)('onVerificationStatusChange: Error', error);
    }
}));
//# sourceMappingURL=pushNotificationTriggers.js.map