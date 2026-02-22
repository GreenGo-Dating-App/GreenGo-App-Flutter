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
exports.onVerificationStatusChange = exports.checkExpiringModes = exports.onSupportMessagePush = exports.onNewMessagePush = exports.onNewMatchPush = exports.onNewLikePush = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const utils_1 = require("../shared/utils");
const db = admin.firestore();
const messaging = admin.messaging();
/**
 * Helper: Send FCM push notification to a user
 * Reads FCM token, checks notification preferences, sends via FCM, and writes in-app notification
 */
async function sendPushToUser(userId, type, title, body, data) {
    try {
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            (0, utils_1.logError)(`sendPushToUser: User ${userId} not found`);
            return false;
        }
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        if (!fcmToken) {
            (0, utils_1.logInfo)(`sendPushToUser: No FCM token for user ${userId}`);
            // Still write in-app notification even without FCM token
            await db.collection('notifications').add(Object.assign({ userId,
                type,
                title,
                body, createdAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false }, (data || {})));
            return false;
        }
        // Check notification preferences
        const prefsDoc = await db.collection('notification_preferences').doc(userId).get();
        if (prefsDoc.exists) {
            const prefs = prefsDoc.data();
            if (prefs.enabledTypes && prefs.enabledTypes[type] === false) {
                (0, utils_1.logInfo)(`sendPushToUser: Notification type ${type} disabled for user ${userId}`);
                return false;
            }
        }
        // Send FCM notification
        const message = {
            token: fcmToken,
            notification: {
                title,
                body,
            },
            data: Object.assign({ type, timestamp: new Date().toISOString() }, (data || {})),
            android: {
                priority: 'high',
                notification: {
                    sound: 'gold_chime',
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
        const response = await messaging.send(message);
        // Write in-app notification
        await db.collection('notifications').add(Object.assign({ userId,
            type,
            title,
            body, createdAt: admin.firestore.FieldValue.serverTimestamp(), sentAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false, fcmMessageId: response }, (data || {})));
        (0, utils_1.logInfo)(`sendPushToUser: Sent ${type} notification to user ${userId}`);
        return true;
    }
    catch (error) {
        // Handle invalid/expired FCM tokens gracefully
        if (error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered') {
            (0, utils_1.logInfo)(`sendPushToUser: Clearing stale FCM token for user ${userId}`);
            await db.collection('users').doc(userId).update({ fcmToken: null });
        }
        else {
            (0, utils_1.logError)(`sendPushToUser: Error sending to user ${userId}`, error);
        }
        return false;
    }
}
/**
 * onNewLikePush - Trigger on likes/{likeId} create
 * Sends "Someone liked your profile!" or "You received a Super Like!" depending on type
 */
exports.onNewLikePush = (0, firestore_1.onDocumentCreated)({
    document: 'likes/{likeId}',
    memory: '256MiB',
}, async (event) => {
    var _a, _b;
    try {
        const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!data)
            return;
        const likedUserId = data.likedUserId;
        const likerId = data.likerId;
        const likeType = data.type; // 'like' or 'super_like'
        if (!likedUserId || !likerId) {
            (0, utils_1.logError)('onNewLikePush: Missing likedUserId or likerId');
            return;
        }
        // Get liker's display name for the notification
        const likerDoc = await db.collection('users').doc(likerId).get();
        const likerName = ((_b = likerDoc.data()) === null || _b === void 0 ? void 0 : _b.displayName) || 'Someone';
        if (likeType === 'super_like') {
            await sendPushToUser(likedUserId, 'superLike', 'You received a Super Like!', `${likerName} sent you a Super Like!`, { fromUserId: likerId });
        }
        else {
            await sendPushToUser(likedUserId, 'newLike', 'Someone liked your profile!', `${likerName} liked your profile`, { fromUserId: likerId });
        }
    }
    catch (error) {
        (0, utils_1.logError)('onNewLikePush: Error', error);
    }
});
/**
 * onNewMatchPush - Trigger on matches/{matchId} create
 * Sends "You have a new match!" to BOTH matched users
 */
exports.onNewMatchPush = (0, firestore_1.onDocumentCreated)({
    document: 'matches/{matchId}',
    memory: '256MiB',
}, async (event) => {
    var _a, _b, _c;
    try {
        const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!data)
            return;
        // matches typically store users as an array or as user1Id/user2Id
        const users = data.users || [];
        const user1Id = data.user1Id || users[0];
        const user2Id = data.user2Id || users[1];
        if (!user1Id || !user2Id) {
            (0, utils_1.logError)('onNewMatchPush: Missing user IDs in match document');
            return;
        }
        // Get both users' names
        const [user1Doc, user2Doc] = await Promise.all([
            db.collection('users').doc(user1Id).get(),
            db.collection('users').doc(user2Id).get(),
        ]);
        const user1Name = ((_b = user1Doc.data()) === null || _b === void 0 ? void 0 : _b.displayName) || 'Someone';
        const user2Name = ((_c = user2Doc.data()) === null || _c === void 0 ? void 0 : _c.displayName) || 'Someone';
        const matchId = event.params.matchId;
        // Notify both users in parallel
        await Promise.all([
            sendPushToUser(user1Id, 'newMatch', 'You have a new match!', `You matched with ${user2Name}!`, { matchId, matchedUserId: user2Id }),
            sendPushToUser(user2Id, 'newMatch', 'You have a new match!', `You matched with ${user1Name}!`, { matchId, matchedUserId: user1Id }),
        ]);
    }
    catch (error) {
        (0, utils_1.logError)('onNewMatchPush: Error', error);
    }
});
/**
 * onNewMessagePush - Trigger on conversations/{convId}/messages/{msgId} create
 * Sends "New message from {senderName}" to the recipient
 */
exports.onNewMessagePush = (0, firestore_1.onDocumentCreated)({
    document: 'conversations/{convId}/messages/{msgId}',
    memory: '256MiB',
}, async (event) => {
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
        // Get conversation to find participants
        const convDoc = await db.collection('conversations').doc(convId).get();
        if (!convDoc.exists) {
            (0, utils_1.logError)(`onNewMessagePush: Conversation ${convId} not found`);
            return;
        }
        const convData = convDoc.data();
        const participants = convData.participants || [];
        // Get sender name
        const senderDoc = await db.collection('users').doc(senderId).get();
        const senderName = ((_b = senderDoc.data()) === null || _b === void 0 ? void 0 : _b.displayName) || 'Someone';
        // Message preview (truncate long messages)
        const messageText = data.text || data.content || '';
        const messageType = data.type || 'text';
        let preview;
        if (messageType === 'image') {
            preview = 'Sent a photo';
        }
        else if (messageType === 'voice') {
            preview = 'Sent a voice message';
        }
        else if (messageType === 'video') {
            preview = 'Sent a video';
        }
        else if (messageText.length > 100) {
            preview = messageText.substring(0, 97) + '...';
        }
        else {
            preview = messageText;
        }
        // Notify all participants except the sender
        const recipients = participants.filter((id) => id !== senderId);
        await Promise.all(recipients.map((recipientId) => sendPushToUser(recipientId, 'newMessage', `New message from ${senderName}`, preview, { conversationId: convId, fromUserId: senderId })));
    }
    catch (error) {
        (0, utils_1.logError)('onNewMessagePush: Error', error);
    }
});
/**
 * onSupportMessagePush - Trigger on support_messages/{msgId} create
 * Notifies user when admin replies, and admin when user sends a message
 */
exports.onSupportMessagePush = (0, firestore_1.onDocumentCreated)({
    document: 'support_messages/{msgId}',
    memory: '256MiB',
}, async (event) => {
    var _a;
    try {
        const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
        if (!data)
            return;
        const senderType = data.senderType; // 'admin' or 'user'
        const conversationId = data.conversationId;
        if (!conversationId) {
            (0, utils_1.logError)('onSupportMessagePush: Missing conversationId');
            return;
        }
        // Read the support_chats document to get user/admin info
        const chatDoc = await db.collection('support_chats').doc(conversationId).get();
        if (!chatDoc.exists) {
            (0, utils_1.logError)(`onSupportMessagePush: support_chats/${conversationId} not found`);
            return;
        }
        const chatData = chatDoc.data();
        if (senderType === 'admin') {
            // Admin replied → notify the user
            const userId = chatData.userId;
            if (!userId) {
                (0, utils_1.logError)('onSupportMessagePush: No userId in support_chats doc');
                return;
            }
            await sendPushToUser(userId, 'supportReply', 'Support replied to your ticket', data.text || 'You have a new reply from support.', { conversationId });
        }
        else if (senderType === 'user') {
            // User sent a message → notify the assigned agent
            const agentId = chatData.supportAgentId || chatData.assignedTo;
            if (!agentId) {
                (0, utils_1.logInfo)('onSupportMessagePush: No assigned agent for this ticket');
                return;
            }
            await sendPushToUser(agentId, 'supportMessage', 'New message on support ticket', data.text || 'A user sent a new message.', { conversationId });
        }
    }
    catch (error) {
        (0, utils_1.logError)('onSupportMessagePush: Error', error);
    }
});
/**
 * checkExpiringModes - Scheduled every 15 minutes
 * Warns users whose Incognito or Traveler mode expires within 1 hour
 */
exports.checkExpiringModes = (0, scheduler_1.onSchedule)({
    schedule: 'every 15 minutes',
    memory: '256MiB',
    timeZone: 'UTC',
}, async () => {
    try {
        const now = admin.firestore.Timestamp.now();
        const oneHourFromNow = admin.firestore.Timestamp.fromMillis(now.toMillis() + 60 * 60 * 1000);
        // --- Incognito mode expiry warnings ---
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
        // --- Traveler mode expiry warnings ---
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
});
/**
 * onVerificationStatusChange - Trigger on profiles/{userId} update
 * Sends notification when verificationStatus changes (approved, needsResubmission, rejected)
 */
exports.onVerificationStatusChange = (0, firestore_1.onDocumentUpdated)({
    document: 'profiles/{userId}',
    memory: '256MiB',
}, async (event) => {
    var _a, _b, _c, _d;
    try {
        const beforeData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data();
        const afterData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.data();
        if (!beforeData || !afterData)
            return;
        const beforeStatus = beforeData.verificationStatus;
        const afterStatus = afterData.verificationStatus;
        // Only act when verificationStatus actually changed
        if (beforeStatus === afterStatus)
            return;
        const userId = event.params.userId;
        const reason = afterData.verificationReason || afterData.verificationNote || '';
        if (afterStatus === 'approved') {
            await sendPushToUser(userId, 'verification', 'Profile Verified!', 'Your profile has been verified! You now have a verified badge.');
        }
        else if (afterStatus === 'needsResubmission') {
            const body = reason
                ? `Please submit a new verification photo. Reason: ${reason}`
                : 'Please submit a new verification photo.';
            await sendPushToUser(userId, 'verification', 'New Verification Photo Needed', body);
        }
        else if (afterStatus === 'rejected') {
            const body = reason
                ? `Your verification was not approved. Reason: ${reason}`
                : 'Your verification was not approved. Please try again.';
            await sendPushToUser(userId, 'verification', 'Verification Update', body);
        }
    }
    catch (error) {
        (0, utils_1.logError)('onVerificationStatusChange: Error', error);
    }
});
//# sourceMappingURL=pushNotificationTriggers.js.map