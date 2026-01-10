"use strict";
/**
 * Scheduled Messages Cloud Function
 * Point 116: Send scheduled messages automatically
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
exports.getScheduledMessages = exports.cancelScheduledMessage = exports.scheduleMessage = exports.sendScheduledMessages = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
/**
 * Scheduled function that runs every minute to send scheduled messages
 */
exports.sendScheduledMessages = functions.pubsub
    .schedule('every 1 minutes')
    .onRun(async (context) => {
    console.log('Checking for scheduled messages to send...');
    const now = new Date();
    try {
        // Find messages scheduled to be sent now or in the past
        const scheduledMessagesSnapshot = await firestore
            .collectionGroup('messages')
            .where('isScheduled', '==', true)
            .where('status', '==', 'sending')
            .where('scheduledFor', '<=', now)
            .limit(50)
            .get();
        console.log(`Found ${scheduledMessagesSnapshot.size} messages to send`);
        const batch = firestore.batch();
        for (const doc of scheduledMessagesSnapshot.docs) {
            const message = doc.data();
            // Update message status to sent
            batch.update(doc.ref, {
                isScheduled: false,
                status: 'sent',
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Update conversation with last message
            const conversationId = message.conversationId;
            const conversationRef = firestore.collection('conversations').doc(conversationId);
            batch.update(conversationRef, {
                lastMessage: {
                    messageId: doc.id,
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    content: message.content,
                    type: message.type,
                    sentAt: admin.firestore.FieldValue.serverTimestamp(),
                },
                lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
                unreadCount: admin.firestore.FieldValue.increment(1),
            });
            // Create notification for receiver
            const notificationRef = firestore.collection('notifications').doc();
            batch.set(notificationRef, {
                userId: message.receiverId,
                type: 'new_message',
                title: 'New Message',
                message: message.content.substring(0, 100),
                data: {
                    conversationId: conversationId,
                    messageId: doc.id,
                    senderId: message.senderId,
                },
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                actionUrl: `/chat/${conversationId}`,
            });
            console.log(`Scheduled message ${doc.id} will be sent`);
        }
        await batch.commit();
        console.log(`Successfully sent ${scheduledMessagesSnapshot.size} scheduled messages`);
        return {
            success: true,
            messagesSent: scheduledMessagesSnapshot.size,
        };
    }
    catch (error) {
        console.error('Error sending scheduled messages:', error);
        throw error;
    }
});
/**
 * Schedule a message for later delivery
 */
exports.scheduleMessage = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId, matchId, senderId, receiverId, content, type = 'text', scheduledFor, } = data;
    if (!conversationId ||
        !matchId ||
        !senderId ||
        !receiverId ||
        !content ||
        !scheduledFor) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    // Verify sender is authenticated user
    if (senderId !== context.auth.uid) {
        throw new functions.https.HttpsError('permission-denied', 'Cannot schedule messages on behalf of other users');
    }
    try {
        const scheduledTime = new Date(scheduledFor);
        // Validate scheduled time is in the future
        if (scheduledTime <= new Date()) {
            throw new functions.https.HttpsError('invalid-argument', 'Scheduled time must be in the future');
        }
        // Validate scheduled time is within 30 days
        const maxFutureTime = new Date();
        maxFutureTime.setDate(maxFutureTime.getDate() + 30);
        if (scheduledTime > maxFutureTime) {
            throw new functions.https.HttpsError('invalid-argument', 'Cannot schedule messages more than 30 days in advance');
        }
        // Create the scheduled message
        const messageRef = firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc();
        await messageRef.set({
            messageId: messageRef.id,
            matchId,
            conversationId,
            senderId,
            receiverId,
            content,
            type,
            sentAt: admin.firestore.FieldValue.serverTimestamp(), // Original creation time
            status: 'sending',
            isScheduled: true,
            scheduledFor: admin.firestore.Timestamp.fromDate(scheduledTime),
            metadata: {
                scheduled: true,
                scheduledBy: senderId,
                scheduledAt: admin.firestore.FieldValue.serverTimestamp(),
            },
        });
        console.log(`Message scheduled for ${scheduledTime.toISOString()}`);
        return {
            success: true,
            messageId: messageRef.id,
            scheduledFor: scheduledTime.toISOString(),
        };
    }
    catch (error) {
        console.error('Error scheduling message:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Cancel a scheduled message
 */
exports.cancelScheduledMessage = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId, messageId } = data;
    if (!conversationId || !messageId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId and messageId are required');
    }
    try {
        const messageRef = firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId);
        const messageDoc = await messageRef.get();
        if (!messageDoc.exists) {
            throw new functions.https.HttpsError('not-found', 'Message not found');
        }
        const message = messageDoc.data();
        // Verify user owns the message
        if (message.senderId !== context.auth.uid) {
            throw new functions.https.HttpsError('permission-denied', 'Can only cancel your own scheduled messages');
        }
        // Verify message is still scheduled
        if (!message.isScheduled || message.status !== 'sending') {
            throw new functions.https.HttpsError('failed-precondition', 'Message is not scheduled or has already been sent');
        }
        // Delete the message
        await messageRef.delete();
        console.log(`Cancelled scheduled message ${messageId}`);
        return {
            success: true,
            messageId,
        };
    }
    catch (error) {
        console.error('Error cancelling scheduled message:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get all scheduled messages for a conversation
 */
exports.getScheduledMessages = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId } = data;
    if (!conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
    }
    try {
        const userId = context.auth.uid;
        const scheduledMessagesSnapshot = await firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .where('isScheduled', '==', true)
            .where('status', '==', 'sending')
            .where('senderId', '==', userId)
            .orderBy('scheduledFor', 'asc')
            .get();
        const messages = scheduledMessagesSnapshot.docs.map((doc) => {
            var _a;
            return (Object.assign(Object.assign({ messageId: doc.id }, doc.data()), { scheduledFor: (_a = doc.data().scheduledFor) === null || _a === void 0 ? void 0 : _a.toDate().toISOString() }));
        });
        return {
            success: true,
            messages,
            count: messages.length,
        };
    }
    catch (error) {
        console.error('Error getting scheduled messages:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=scheduledMessages.js.map