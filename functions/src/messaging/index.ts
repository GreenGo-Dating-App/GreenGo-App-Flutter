/**
 * Messaging Service
 * 8 Cloud Functions for message translation and scheduling
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { TranslationServiceClient } from '@google-cloud/translate';
import { verifyAuth, handleError, logInfo, logError, db } from '../shared/utils';
import * as admin from 'firebase-admin';

const translationClient = new TranslationServiceClient();

// Supported languages
const SUPPORTED_LANGUAGES = [
  'en', 'es', 'fr', 'de', 'pt', 'it', 'ar', 'zh', 'ja', 'ko', 'ru',
  'hi', 'nl', 'sv', 'pl', 'tr', 'vi', 'id', 'th', 'cs', 'ro'
];

// ========== 1. TRANSLATE MESSAGE (HTTP Callable) ==========

interface TranslateMessageRequest {
  messageId: string;
  targetLanguage: string;
}

export const translateMessage = onCall<TranslateMessageRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { messageId, targetLanguage } = request.data;

      if (!messageId || !targetLanguage) {
        throw new HttpsError('invalid-argument', 'messageId and targetLanguage are required');
      }

      if (!SUPPORTED_LANGUAGES.includes(targetLanguage)) {
        throw new HttpsError('invalid-argument', `Language ${targetLanguage} not supported`);
      }

      logInfo(`Translating message ${messageId} to ${targetLanguage} for user ${uid}`);

      // Get message
      const messageDoc = await db.collection('messages').doc(messageId).get();
      if (!messageDoc.exists) {
        throw new HttpsError('not-found', 'Message not found');
      }

      const messageData = messageDoc.data()!;

      // Check if user is participant
      const conversationDoc = await db.collection('conversations').doc(messageData.conversationId).get();
      const conversationData = conversationDoc.data();

      if (!conversationData?.participants.includes(uid)) {
        throw new HttpsError('permission-denied', 'Not authorized to access this message');
      }

      // Check if already translated
      if (messageData.translations?.[targetLanguage]) {
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

      const translation = response.translations?.[0]?.translatedText || '';

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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 2. AUTO-TRANSLATE MESSAGE (Firestore Trigger) ==========

export const autoTranslateMessage = onDocumentCreated(
  {
    document: 'messages/{messageId}',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (event) => {
    const messageData = event.data?.data();
    if (!messageData) return;

    const messageId = event.params.messageId;
    const conversationId = messageData.conversationId;

    logInfo(`Auto-translating message ${messageId}`);

    try {
      // Get conversation participants
      const conversationDoc = await db.collection('conversations').doc(conversationId).get();
      const conversationData = conversationDoc.data();

      if (!conversationData) return;

      // Get receiver's preferred language
      const receiverId = conversationData.participants.find((p: string) => p !== messageData.senderId);
      if (!receiverId) return;

      const receiverDoc = await db.collection('users').doc(receiverId).get();
      const receiverData = receiverDoc.data();

      if (!receiverData?.preferredLanguage || receiverData.preferredLanguage === 'en') {
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

      const translation = response.translations?.[0]?.translatedText || '';

      // Save translation
      await db.collection('messages').doc(messageId).update({
        [`translations.${targetLanguage}`]: translation,
        autoTranslated: true,
      });

      logInfo(`Auto-translated message ${messageId} to ${targetLanguage}`);
    } catch (error) {
      logError(`Error auto-translating message ${messageId}:`, error);
    }
  }
);

// ========== 3. BATCH TRANSLATE MESSAGES (HTTP Callable) ==========

interface BatchTranslateRequest {
  messageIds: string[];
  targetLanguage: string;
}

export const batchTranslateMessages = onCall<BatchTranslateRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { messageIds, targetLanguage } = request.data;

      if (!messageIds || messageIds.length === 0) {
        throw new HttpsError('invalid-argument', 'messageIds is required');
      }

      if (!targetLanguage) {
        throw new HttpsError('invalid-argument', 'targetLanguage is required');
      }

      if (!SUPPORTED_LANGUAGES.includes(targetLanguage)) {
        throw new HttpsError('invalid-argument', `Language ${targetLanguage} not supported`);
      }

      logInfo(`Batch translating ${messageIds.length} messages to ${targetLanguage}`);

      // Get all messages
      const messagePromises = messageIds.map(id => db.collection('messages').doc(id).get());
      const messageDocs = await Promise.all(messagePromises);

      // Filter messages that need translation
      const toTranslate = messageDocs
        .filter(doc => doc.exists && !doc.data()?.translations?.[targetLanguage])
        .map(doc => ({ id: doc.id, content: doc.data()!.content }));

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
      const batch = db.batch();
      response.translations?.forEach((translation, index) => {
        const messageId = toTranslate[index].id;
        const ref = db.collection('messages').doc(messageId);
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 4. GET SUPPORTED LANGUAGES (HTTP Callable) ==========

export const getSupportedLanguages = onCall(
  {
    memory: '128MiB',
    timeoutSeconds: 10,
  },
  async () => {
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
  }
);

// ========== 5. SCHEDULE MESSAGE (HTTP Callable) ==========

interface ScheduleMessageRequest {
  conversationId: string;
  content: string;
  scheduledFor: string; // ISO timestamp
  type?: string;
  mediaUrl?: string;
}

export const scheduleMessage = onCall<ScheduleMessageRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { conversationId, content, scheduledFor, type = 'text', mediaUrl } = request.data;

      if (!conversationId || !content || !scheduledFor) {
        throw new HttpsError('invalid-argument', 'conversationId, content, and scheduledFor are required');
      }

      // Validate scheduled time is in future
      const scheduledDate = new Date(scheduledFor);
      if (scheduledDate <= new Date()) {
        throw new HttpsError('invalid-argument', 'scheduledFor must be in the future');
      }

      // Verify user is participant
      const conversationDoc = await db.collection('conversations').doc(conversationId).get();
      if (!conversationDoc.exists) {
        throw new HttpsError('not-found', 'Conversation not found');
      }

      const conversationData = conversationDoc.data()!;
      if (!conversationData.participants.includes(uid)) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      // Create scheduled message
      const scheduledMessageRef = await db.collection('scheduled_messages').add({
        conversationId,
        senderId: uid,
        content,
        type,
        mediaUrl,
        scheduledFor: admin.firestore.Timestamp.fromDate(scheduledDate),
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logInfo(`Message scheduled: ${scheduledMessageRef.id} for ${scheduledFor}`);

      return {
        success: true,
        scheduledMessageId: scheduledMessageRef.id,
        scheduledFor,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 6. SEND SCHEDULED MESSAGES (Scheduled - Every Minute) ==========

export const sendScheduledMessages = onSchedule(
  {
    schedule: '* * * * *', // Every minute
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async () => {
    logInfo('Checking for scheduled messages to send');

    try {
      const now = admin.firestore.Timestamp.now();

      // Query messages that should be sent
      const snapshot = await db
        .collection('scheduled_messages')
        .where('status', '==', 'pending')
        .where('scheduledFor', '<=', now)
        .limit(100)
        .get();

      if (snapshot.empty) {
        logInfo('No scheduled messages to send');
        return;
      }

      logInfo(`Sending ${snapshot.size} scheduled messages`);

      const batch = db.batch();

      for (const doc of snapshot.docs) {
        const data = doc.data();

        // Create the actual message
        const messageRef = db.collection('messages').doc();
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
        const conversationRef = db.collection('conversations').doc(data.conversationId);
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

      logInfo(`Successfully sent ${snapshot.size} scheduled messages`);
    } catch (error) {
      logError('Error sending scheduled messages:', error);
      throw error;
    }
  }
);

// ========== 7. CANCEL SCHEDULED MESSAGE (HTTP Callable) ==========

interface CancelScheduledMessageRequest {
  scheduledMessageId: string;
}

export const cancelScheduledMessage = onCall<CancelScheduledMessageRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { scheduledMessageId } = request.data;

      if (!scheduledMessageId) {
        throw new HttpsError('invalid-argument', 'scheduledMessageId is required');
      }

      const scheduledMessageDoc = await db.collection('scheduled_messages').doc(scheduledMessageId).get();

      if (!scheduledMessageDoc.exists) {
        throw new HttpsError('not-found', 'Scheduled message not found');
      }

      const data = scheduledMessageDoc.data()!;

      // Verify user owns the message
      if (data.senderId !== uid) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      // Check if already sent
      if (data.status === 'sent') {
        throw new HttpsError('failed-precondition', 'Message already sent');
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
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 8. GET SCHEDULED MESSAGES (HTTP Callable) ==========

interface GetScheduledMessagesRequest {
  conversationId?: string;
  status?: 'pending' | 'sent' | 'cancelled';
}

export const getScheduledMessages = onCall<GetScheduledMessagesRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { conversationId, status = 'pending' } = request.data;

      let query = db.collection('scheduled_messages')
        .where('senderId', '==', uid)
        .where('status', '==', status)
        .orderBy('scheduledFor', 'asc');

      if (conversationId) {
        query = query.where('conversationId', '==', conversationId) as any;
      }

      const snapshot = await query.limit(50).get();

      const scheduledMessages = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        scheduledFor: doc.data().scheduledFor.toDate().toISOString(),
        createdAt: doc.data().createdAt?.toDate().toISOString(),
      }));

      return {
        success: true,
        scheduledMessages,
        total: scheduledMessages.length,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);
