/**
 * Message Translation Cloud Function
 * Points 111-113: Real-time translation using Cloud Translation API
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { TranslationServiceClient } from '@google-cloud/translate';

const firestore = admin.firestore();
const translationClient = new TranslationServiceClient();

// Your Google Cloud project ID
const projectId = process.env.GCLOUD_PROJECT;

/**
 * Translate a message to the target language
 */
export const translateMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { messageId, conversationId, targetLanguage = 'en' } = data;

  if (!messageId || !conversationId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'messageId and conversationId are required'
    );
  }

  try {
    // Get the message
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

    if (!message || message.type !== 'text') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Only text messages can be translated'
      );
    }

    const text = message.content;

    // Check if already translated to this language
    if (
      message.translatedContent &&
      message.metadata?.translatedLanguage === targetLanguage
    ) {
      return {
        success: true,
        translatedContent: message.translatedContent,
        detectedLanguage: message.detectedLanguage,
        cached: true,
      };
    }

    // Detect language and translate
    const parent = `projects/${projectId}/locations/global`;

    // Detect language
    const [detection] = await translationClient.detectLanguage({
      parent,
      content: text,
    });

    const detectedLanguage =
      detection.languages?.[0]?.languageCode || 'unknown';
    const confidence = detection.languages?.[0]?.confidence || 0;

    console.log(`Detected language: ${detectedLanguage} (confidence: ${confidence})`);

    // If already in target language, don't translate
    if (detectedLanguage === targetLanguage) {
      return {
        success: true,
        translatedContent: text,
        detectedLanguage,
        sameLanguage: true,
      };
    }

    // Translate the text
    const [translation] = await translationClient.translateText({
      parent,
      contents: [text],
      targetLanguageCode: targetLanguage,
      sourceLanguageCode: detectedLanguage,
    });

    const translatedContent = translation.translations?.[0]?.translatedText || text;

    console.log(`Translated from ${detectedLanguage} to ${targetLanguage}`);

    // Update message with translation
    await messageRef.update({
      translatedContent,
      detectedLanguage,
      'metadata.translatedLanguage': targetLanguage,
      'metadata.translationConfidence': confidence,
      'metadata.translatedAt': admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      translatedContent,
      detectedLanguage,
      targetLanguage,
      confidence,
    };
  } catch (error) {
    console.error('Error translating message:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Auto-translate messages based on user preferences
 */
export const autoTranslateMessage = functions.firestore
  .document('conversations/{conversationId}/messages/{messageId}')
  .onCreate(async (snapshot, context) => {
    const message = snapshot.data();

    // Only auto-translate text messages
    if (message.type !== 'text') {
      return null;
    }

    try {
      // Get receiver's language preference
      const receiverId = message.receiverId;
      const userDoc = await firestore.collection('users').doc(receiverId).get();

      if (!userDoc.exists) {
        return null;
      }

      const userData = userDoc.data();
      const preferredLanguage = userData?.preferredLanguage;
      const autoTranslate = userData?.autoTranslateMessages;

      // If auto-translate is not enabled, skip
      if (!autoTranslate || !preferredLanguage) {
        console.log('Auto-translate not enabled for user');
        return null;
      }

      const parent = `projects/${projectId}/locations/global`;

      // Detect source language
      const [detection] = await translationClient.detectLanguage({
        parent,
        content: message.content,
      });

      const detectedLanguage = detection.languages?.[0]?.languageCode || 'unknown';

      // If already in preferred language, skip
      if (detectedLanguage === preferredLanguage) {
        console.log('Message already in preferred language');
        return null;
      }

      // Translate
      const [translation] = await translationClient.translateText({
        parent,
        contents: [message.content],
        targetLanguageCode: preferredLanguage,
        sourceLanguageCode: detectedLanguage,
      });

      const translatedContent = translation.translations?.[0]?.translatedText || message.content;

      // Update message
      await snapshot.ref.update({
        translatedContent,
        detectedLanguage,
        'metadata.autoTranslated': true,
        'metadata.translatedLanguage': preferredLanguage,
        'metadata.translatedAt': admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Auto-translated message from ${detectedLanguage} to ${preferredLanguage}`);

      return null;
    } catch (error) {
      console.error('Error in auto-translate:', error);
      return null; // Don't fail message creation
    }
  });

/**
 * Batch translate multiple messages
 */
export const batchTranslateMessages = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { conversationId, targetLanguage = 'en', limit = 20 } = data;

  if (!conversationId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'conversationId is required'
    );
  }

  try {
    // Get text messages without translation
    const messagesSnapshot = await firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .where('type', '==', 'text')
      .where('translatedContent', '==', null)
      .limit(limit)
      .get();

    const parent = `projects/${projectId}/locations/global`;
    const results = [];

    for (const doc of messagesSnapshot.docs) {
      const message = doc.data();

      try {
        // Detect and translate
        const [detection] = await translationClient.detectLanguage({
          parent,
          content: message.content,
        });

        const detectedLanguage = detection.languages?.[0]?.languageCode || 'unknown';

        if (detectedLanguage !== targetLanguage) {
          const [translation] = await translationClient.translateText({
            parent,
            contents: [message.content],
            targetLanguageCode: targetLanguage,
            sourceLanguageCode: detectedLanguage,
          });

          const translatedContent = translation.translations?.[0]?.translatedText || message.content;

          await doc.ref.update({
            translatedContent,
            detectedLanguage,
            'metadata.translatedLanguage': targetLanguage,
            'metadata.translatedAt': admin.firestore.FieldValue.serverTimestamp(),
          });

          results.push({
            messageId: doc.id,
            success: true,
            detectedLanguage,
          });
        } else {
          results.push({
            messageId: doc.id,
            success: true,
            sameLanguage: true,
          });
        }
      } catch (error) {
        results.push({
          messageId: doc.id,
          success: false,
          error: error.message,
        });
      }
    }

    return {
      success: true,
      processed: results.length,
      results,
    };
  } catch (error) {
    console.error('Error in batchTranslateMessages:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * Get supported languages
 */
export const getSupportedLanguages = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  try {
    const parent = `projects/${projectId}/locations/global`;

    const [response] = await translationClient.getSupportedLanguages({
      parent,
      displayLanguageCode: data.displayLanguage || 'en',
    });

    const languages = response.languages?.map((lang) => ({
      code: lang.languageCode,
      name: lang.displayName,
    })) || [];

    return {
      success: true,
      languages,
    };
  } catch (error) {
    console.error('Error getting supported languages:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
