/**
 * Message translation callables (kept for API compatibility).
 *
 * The app translates chat messages ON THE DEVICE with the free Google
 * endpoint (TranslationService.translateDetailed); these callables are not
 * called by the current app. They exist so any older client keeps working,
 * and they use the same FREE endpoint (./freeTranslate) — nothing here
 * depends on the paid Cloud Translation API, which is being switched off.
 *
 * Chat translations are PRIVATE: they are returned to the caller only, never
 * written to the shared `translations/` store or into the message document
 * (a translation in one reader's language written onto the shared message was
 * also shown to the other participant).
 *
 * The former `autoTranslateMessage` Firestore trigger was removed: it ran on
 * every message create, no user has `autoTranslateMessages` set (0 of 65 on
 * 2026-10-04), and the app already auto-translates every message for each
 * reader in their own language. Delete the deployed copy with
 * `firebase functions:delete autoTranslateMessage`.
 *
 * Both callables send private chat text to Google, so they require the
 * caller's AI-processing consent (the "AI services" switch), like
 * translatePrivateText.
 *
 * 512MB: the shared index.js needs ~200MB just to load, so 256MB instances are
 * OOM-killed on cold start.
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { monitored } from '../shared/monitoring';
import { requireAiConsent } from '../shared/aiConsent';
import { AppError, handleError } from '../shared/utils';
import {
  freeTranslate,
  freeTranslateMany,
  FreeTranslateError,
  normalizeTarget,
  SUPPORTED_LANGUAGES,
} from './freeTranslate';

const firestore = admin.firestore();
const MAX_CHARS = 5000;
const runtime = { memory: '512MB' as const, timeoutSeconds: 60 };

/** The caller must be a participant of the conversation. */
async function assertParticipant(conversationId: string, uid: string) {
  const conv = await firestore.collection('conversations').doc(conversationId).get();
  const d = conv.data();
  const participants: unknown[] = Array.isArray(d?.participants) ? d!.participants : [];
  if (!conv.exists || !(d?.userId1 === uid || d?.userId2 === uid || participants.includes(uid))) {
    throw new functions.https.HttpsError('permission-denied', 'Not a participant of this conversation');
  }
}

function toHttpsError(error: unknown): functions.https.HttpsError {
  if (error instanceof functions.https.HttpsError) return error;
  if (error instanceof AppError) return handleError(error); // AI_CONSENT_REQUIRED
  if (error instanceof FreeTranslateError) {
    return new functions.https.HttpsError(
      error.transient ? 'unavailable' : 'internal',
      'Translation is temporarily unavailable',
    );
  }
  return new functions.https.HttpsError('internal', (error as Error)?.message ?? 'Translation failed');
}

/**
 * Translate one message into the caller's target language.
 * Request: { messageId, conversationId, targetLanguage = 'en' }.
 */
export const translateMessage = functions
  .runWith(runtime)
  .https.onCall(monitored("translateMessage", async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { messageId, conversationId } = data ?? {};
  const targetLanguage = normalizeTarget(String(data?.targetLanguage ?? 'en'));

  if (!messageId || !conversationId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'messageId and conversationId are required'
    );
  }

  try {
    await assertParticipant(conversationId, context.auth.uid);
    // Private chat text goes to Google: only with AI services ON (consent).
    await requireAiConsent(context.auth.uid);

    const messageDoc = await firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .doc(messageId)
      .get();

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

    const text = String(message.content ?? '').slice(0, MAX_CHARS);
    const result = await freeTranslate(text, targetLanguage);

    if (result.sameLanguage) {
      return {
        success: true,
        translatedContent: text,
        detectedLanguage: result.detectedLanguage ?? 'unknown',
        sameLanguage: true,
      };
    }

    return {
      success: true,
      translatedContent: result.text,
      detectedLanguage: result.detectedLanguage ?? 'unknown',
      targetLanguage,
    };
  } catch (error) {
    console.error('Error translating message:', error);
    throw toHttpsError(error);
  }
}));

/**
 * Translate recent text messages of a conversation for the caller.
 * Request: { conversationId, targetLanguage = 'en', limit = 20 (max 50) }.
 * Returns the translations; nothing is written.
 */
export const batchTranslateMessages = functions
  .runWith(runtime)
  .https.onCall(monitored("batchTranslateMessages", async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const conversationId = data?.conversationId;
  const targetLanguage = normalizeTarget(String(data?.targetLanguage ?? 'en'));
  const limit = Math.min(Math.max(Number(data?.limit) || 20, 1), 50);

  if (!conversationId) {
    throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
  }

  try {
    await assertParticipant(conversationId, context.auth.uid);
    // Private chat text goes to Google: only with AI services ON (consent).
    await requireAiConsent(context.auth.uid);

    const messagesSnapshot = await firestore
      .collection('conversations')
      .doc(conversationId)
      .collection('messages')
      .orderBy('sentAt', 'desc') // single-field: no composite index needed
      .limit(limit)
      .get();

    const docs = messagesSnapshot.docs.filter((d) => d.data().type === 'text');
    const translations = await freeTranslateMany(
      docs.map((d) => String(d.data().content ?? '').slice(0, MAX_CHARS)),
      targetLanguage,
      { concurrency: 4, timeoutMs: 6000, deadlineMs: 40000 },
    );

    const results = docs.map((doc, i) => {
      const t = translations[i];
      if (!t) return { messageId: doc.id, success: false, error: 'unavailable' };
      return t.sameLanguage
        ? { messageId: doc.id, success: true, sameLanguage: true, detectedLanguage: t.detectedLanguage }
        : {
            messageId: doc.id,
            success: true,
            translatedContent: t.text,
            detectedLanguage: t.detectedLanguage,
          };
    });

    return { success: true, processed: results.length, results };
  } catch (error) {
    console.error('Error in batchTranslateMessages:', error);
    throw toHttpsError(error);
  }
}));

/**
 * Get supported languages (static list; no API call).
 */
export const getSupportedLanguages = functions
  .runWith(runtime)
  .https.onCall(monitored("getSupportedLanguages", async (_data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  return { success: true, languages: SUPPORTED_LANGUAGES };
}));
