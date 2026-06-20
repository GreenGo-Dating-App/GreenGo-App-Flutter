"use strict";
/**
 * Messaging Service
 * 8 Cloud Functions for message translation and scheduling
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
exports.getScheduledMessages = exports.cancelScheduledMessage = exports.sendScheduledMessages = exports.scheduleMessage = exports.getSupportedLanguages = exports.batchTranslateMessages = exports.autoTranslateMessage = exports.translateMessage = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const translate_1 = require("@google-cloud/translate");
const utils_1 = require("../shared/utils");
const admin = __importStar(require("firebase-admin"));
const translationClient = new translate_1.TranslationServiceClient();
// Supported languages
const SUPPORTED_LANGUAGES = [
    'en', 'es', 'fr', 'de', 'pt', 'it', 'ar', 'zh', 'ja', 'ko', 'ru',
    'hi', 'nl', 'sv', 'pl', 'tr', 'vi', 'id', 'th', 'cs', 'ro'
];
exports.translateMessage = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    var _a, _b, _c;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { messageId, targetLanguage } = request.data;
        if (!messageId || !targetLanguage) {
            throw new https_1.HttpsError('invalid-argument', 'messageId and targetLanguage are required');
        }
        if (!SUPPORTED_LANGUAGES.includes(targetLanguage)) {
            throw new https_1.HttpsError('invalid-argument', `Language ${targetLanguage} not supported`);
        }
        (0, utils_1.logInfo)(`Translating message ${messageId} to ${targetLanguage} for user ${uid}`);
        // Get message
        const messageDoc = await utils_1.db.collection('messages').doc(messageId).get();
        if (!messageDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Message not found');
        }
        const messageData = messageDoc.data();
        // Check if user is participant
        const conversationDoc = await utils_1.db.collection('conversations').doc(messageData.conversationId).get();
        const conversationData = conversationDoc.data();
        if (!(conversationData === null || conversationData === void 0 ? void 0 : conversationData.participants.includes(uid))) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized to access this message');
        }
        // Check if already translated
        if ((_a = messageData.translations) === null || _a === void 0 ? void 0 : _a[targetLanguage]) {
            return {
                success: true,
                translation: messageData.translations[targetLanguage],
                cached: true,
            };
        }
        // Translate
        const [response] = await translationClient.translateText({
            parent: `projects/${process.env.PROJECT_ID}/locations/global`,
            contents: [messageData.content],
            mimeType: 'text/plain',
            targetLanguageCode: targetLanguage,
        });
        const translation = ((_c = (_b = response.translations) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.translatedText) || '';
        // Save translation to message
        await messageDoc.ref.update({
            [`translations.${targetLanguage}`]: translation,
            translatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            translation,
            cached: false,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 2. AUTO-TRANSLATE MESSAGE (Firestore Trigger) ==========
exports.autoTranslateMessage = (0, firestore_1.onDocumentCreated)({
    document: 'messages/{messageId}',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (event) => {
    var _a, _b, _c;
    const messageData = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!messageData)
        return;
    const messageId = event.params.messageId;
    const conversationId = messageData.conversationId;
    (0, utils_1.logInfo)(`Auto-translating message ${messageId}`);
    try {
        // Get conversation participants
        const conversationDoc = await utils_1.db.collection('conversations').doc(conversationId).get();
        const conversationData = conversationDoc.data();
        if (!conversationData)
            return;
        // Get receiver's preferred language
        const receiverId = conversationData.participants.find((p) => p !== messageData.senderId);
        if (!receiverId)
            return;
        const receiverDoc = await utils_1.db.collection('users').doc(receiverId).get();
        const receiverData = receiverDoc.data();
        if (!(receiverData === null || receiverData === void 0 ? void 0 : receiverData.preferredLanguage) || receiverData.preferredLanguage === 'en') {
            return; // No translation needed
        }
        const targetLanguage = receiverData.preferredLanguage;
        // Translate
        const [response] = await translationClient.translateText({
            parent: `projects/${process.env.PROJECT_ID}/locations/global`,
            contents: [messageData.content],
            mimeType: 'text/plain',
            targetLanguageCode: targetLanguage,
        });
        const translation = ((_c = (_b = response.translations) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.translatedText) || '';
        // Save translation
        await utils_1.db.collection('messages').doc(messageId).update({
            [`translations.${targetLanguage}`]: translation,
            autoTranslated: true,
        });
        (0, utils_1.logInfo)(`Auto-translated message ${messageId} to ${targetLanguage}`);
    }
    catch (error) {
        (0, utils_1.logError)(`Error auto-translating message ${messageId}:`, error);
    }
});
exports.batchTranslateMessages = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    var _a;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { messageIds, targetLanguage } = request.data;
        if (!messageIds || messageIds.length === 0) {
            throw new https_1.HttpsError('invalid-argument', 'messageIds is required');
        }
        if (!targetLanguage) {
            throw new https_1.HttpsError('invalid-argument', 'targetLanguage is required');
        }
        if (!SUPPORTED_LANGUAGES.includes(targetLanguage)) {
            throw new https_1.HttpsError('invalid-argument', `Language ${targetLanguage} not supported`);
        }
        (0, utils_1.logInfo)(`Batch translating ${messageIds.length} messages to ${targetLanguage}`);
        // Get all messages
        const messagePromises = messageIds.map(id => utils_1.db.collection('messages').doc(id).get());
        const messageDocs = await Promise.all(messagePromises);
        // Filter messages that need translation
        const toTranslate = messageDocs
            .filter(doc => { var _a, _b; return doc.exists && !((_b = (_a = doc.data()) === null || _a === void 0 ? void 0 : _a.translations) === null || _b === void 0 ? void 0 : _b[targetLanguage]); })
            .map(doc => ({ id: doc.id, content: doc.data().content }));
        if (toTranslate.length === 0) {
            return {
                success: true,
                translated: 0,
                cached: messageIds.length,
            };
        }
        // Batch translate
        const [response] = await translationClient.translateText({
            parent: `projects/${process.env.PROJECT_ID}/locations/global`,
            contents: toTranslate.map(m => m.content),
            mimeType: 'text/plain',
            targetLanguageCode: targetLanguage,
        });
        // Update all messages
        const batch = utils_1.db.batch();
        (_a = response.translations) === null || _a === void 0 ? void 0 : _a.forEach((translation, index) => {
            const messageId = toTranslate[index].id;
            const ref = utils_1.db.collection('messages').doc(messageId);
            batch.update(ref, {
                [`translations.${targetLanguage}`]: translation.translatedText,
                translatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        });
        await batch.commit();
        return {
            success: true,
            translated: toTranslate.length,
            cached: messageIds.length - toTranslate.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 4. GET SUPPORTED LANGUAGES (HTTP Callable) ==========
exports.getSupportedLanguages = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 10,
}, async () => {
    return {
        success: true,
        languages: SUPPORTED_LANGUAGES,
        total: SUPPORTED_LANGUAGES.length,
        languageNames: {
            en: 'English',
            es: 'Spanish',
            fr: 'French',
            de: 'German',
            pt: 'Portuguese',
            it: 'Italian',
            ar: 'Arabic',
            zh: 'Chinese',
            ja: 'Japanese',
            ko: 'Korean',
            ru: 'Russian',
            hi: 'Hindi',
            nl: 'Dutch',
            sv: 'Swedish',
            pl: 'Polish',
            tr: 'Turkish',
            vi: 'Vietnamese',
            id: 'Indonesian',
            th: 'Thai',
            cs: 'Czech',
            ro: 'Romanian',
        },
    };
});
exports.scheduleMessage = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { conversationId, content, scheduledFor, type = 'text', mediaUrl } = request.data;
        if (!conversationId || !content || !scheduledFor) {
            throw new https_1.HttpsError('invalid-argument', 'conversationId, content, and scheduledFor are required');
        }
        // Validate scheduled time is in future
        const scheduledDate = new Date(scheduledFor);
        if (scheduledDate <= new Date()) {
            throw new https_1.HttpsError('invalid-argument', 'scheduledFor must be in the future');
        }
        // Verify user is participant
        const conversationDoc = await utils_1.db.collection('conversations').doc(conversationId).get();
        if (!conversationDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Conversation not found');
        }
        const conversationData = conversationDoc.data();
        if (!conversationData.participants.includes(uid)) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        // Create scheduled message
        const scheduledMessageRef = await utils_1.db.collection('scheduled_messages').add({
            conversationId,
            senderId: uid,
            content,
            type,
            mediaUrl,
            scheduledFor: admin.firestore.Timestamp.fromDate(scheduledDate),
            status: 'pending',
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        (0, utils_1.logInfo)(`Message scheduled: ${scheduledMessageRef.id} for ${scheduledFor}`);
        return {
            success: true,
            scheduledMessageId: scheduledMessageRef.id,
            scheduledFor,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 6. SEND SCHEDULED MESSAGES (Scheduled - Every Minute) ==========
exports.sendScheduledMessages = (0, scheduler_1.onSchedule)({
    schedule: '* * * * *', // Every minute
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
}, async () => {
    (0, utils_1.logInfo)('Checking for scheduled messages to send');
    try {
        const now = admin.firestore.Timestamp.now();
        // Query messages that should be sent
        const snapshot = await utils_1.db
            .collection('scheduled_messages')
            .where('status', '==', 'pending')
            .where('scheduledFor', '<=', now)
            .limit(100)
            .get();
        if (snapshot.empty) {
            (0, utils_1.logInfo)('No scheduled messages to send');
            return;
        }
        (0, utils_1.logInfo)(`Sending ${snapshot.size} scheduled messages`);
        const batch = utils_1.db.batch();
        for (const doc of snapshot.docs) {
            const data = doc.data();
            // Create the actual message
            const messageRef = utils_1.db.collection('messages').doc();
            batch.set(messageRef, {
                conversationId: data.conversationId,
                senderId: data.senderId,
                content: data.content,
                type: data.type,
                mediaUrl: data.mediaUrl,
                scheduled: true,
                scheduledMessageId: doc.id,
                timestamp: admin.firestore.FieldValue.serverTimestamp(),
                read: false,
                disappearing: false,
            });
            // Update conversation
            const conversationRef = utils_1.db.collection('conversations').doc(data.conversationId);
            batch.update(conversationRef, {
                lastMessageTimestamp: admin.firestore.FieldValue.serverTimestamp(),
            });
            // Mark scheduled message as sent
            batch.update(doc.ref, {
                status: 'sent',
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                actualMessageId: messageRef.id,
            });
        }
        await batch.commit();
        (0, utils_1.logInfo)(`Successfully sent ${snapshot.size} scheduled messages`);
    }
    catch (error) {
        (0, utils_1.logError)('Error sending scheduled messages:', error);
        throw error;
    }
});
exports.cancelScheduledMessage = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { scheduledMessageId } = request.data;
        if (!scheduledMessageId) {
            throw new https_1.HttpsError('invalid-argument', 'scheduledMessageId is required');
        }
        const scheduledMessageDoc = await utils_1.db.collection('scheduled_messages').doc(scheduledMessageId).get();
        if (!scheduledMessageDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Scheduled message not found');
        }
        const data = scheduledMessageDoc.data();
        // Verify user owns the message
        if (data.senderId !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        // Check if already sent
        if (data.status === 'sent') {
            throw new https_1.HttpsError('failed-precondition', 'Message already sent');
        }
        // Cancel the message
        await scheduledMessageDoc.ref.update({
            status: 'cancelled',
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            message: 'Scheduled message cancelled',
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.getScheduledMessages = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { conversationId, status = 'pending' } = request.data;
        let query = utils_1.db.collection('scheduled_messages')
            .where('senderId', '==', uid)
            .where('status', '==', status)
            .orderBy('scheduledFor', 'asc');
        if (conversationId) {
            query = query.where('conversationId', '==', conversationId);
        }
        const snapshot = await query.limit(50).get();
        const scheduledMessages = snapshot.docs.map(doc => {
            var _a;
            return (Object.assign(Object.assign({ id: doc.id }, doc.data()), { scheduledFor: doc.data().scheduledFor.toDate().toISOString(), createdAt: (_a = doc.data().createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString() }));
        });
        return {
            success: true,
            scheduledMessages,
            total: scheduledMessages.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map