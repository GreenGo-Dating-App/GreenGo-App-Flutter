"use strict";
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
 * 512MB: the shared index.js needs ~200MB just to load, so 256MB instances are
 * OOM-killed on cold start.
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
exports.getSupportedLanguages = exports.batchTranslateMessages = exports.translateMessage = void 0;
const functions = __importStar(require("firebase-functions/v1"));
const admin = __importStar(require("firebase-admin"));
const monitoring_1 = require("../shared/monitoring");
const freeTranslate_1 = require("./freeTranslate");
const firestore = admin.firestore();
const MAX_CHARS = 5000;
const runtime = { memory: '512MB', timeoutSeconds: 60 };
/** The caller must be a participant of the conversation. */
async function assertParticipant(conversationId, uid) {
    const conv = await firestore.collection('conversations').doc(conversationId).get();
    const d = conv.data();
    const participants = Array.isArray(d === null || d === void 0 ? void 0 : d.participants) ? d.participants : [];
    if (!conv.exists || !((d === null || d === void 0 ? void 0 : d.userId1) === uid || (d === null || d === void 0 ? void 0 : d.userId2) === uid || participants.includes(uid))) {
        throw new functions.https.HttpsError('permission-denied', 'Not a participant of this conversation');
    }
}
function toHttpsError(error) {
    var _a;
    if (error instanceof functions.https.HttpsError)
        return error;
    if (error instanceof freeTranslate_1.FreeTranslateError) {
        return new functions.https.HttpsError(error.transient ? 'unavailable' : 'internal', 'Translation is temporarily unavailable');
    }
    return new functions.https.HttpsError('internal', (_a = error === null || error === void 0 ? void 0 : error.message) !== null && _a !== void 0 ? _a : 'Translation failed');
}
/**
 * Translate one message into the caller's target language.
 * Request: { messageId, conversationId, targetLanguage = 'en' }.
 */
exports.translateMessage = functions
    .runWith(runtime)
    .https.onCall((0, monitoring_1.monitored)("translateMessage", async (data, context) => {
    var _a, _b, _c, _d;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { messageId, conversationId } = data !== null && data !== void 0 ? data : {};
    const targetLanguage = (0, freeTranslate_1.normalizeTarget)(String((_a = data === null || data === void 0 ? void 0 : data.targetLanguage) !== null && _a !== void 0 ? _a : 'en'));
    if (!messageId || !conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'messageId and conversationId are required');
    }
    try {
        await assertParticipant(conversationId, context.auth.uid);
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
            throw new functions.https.HttpsError('invalid-argument', 'Only text messages can be translated');
        }
        const text = String((_b = message.content) !== null && _b !== void 0 ? _b : '').slice(0, MAX_CHARS);
        const result = await (0, freeTranslate_1.freeTranslate)(text, targetLanguage);
        if (result.sameLanguage) {
            return {
                success: true,
                translatedContent: text,
                detectedLanguage: (_c = result.detectedLanguage) !== null && _c !== void 0 ? _c : 'unknown',
                sameLanguage: true,
            };
        }
        return {
            success: true,
            translatedContent: result.text,
            detectedLanguage: (_d = result.detectedLanguage) !== null && _d !== void 0 ? _d : 'unknown',
            targetLanguage,
        };
    }
    catch (error) {
        console.error('Error translating message:', error);
        throw toHttpsError(error);
    }
}));
/**
 * Translate recent text messages of a conversation for the caller.
 * Request: { conversationId, targetLanguage = 'en', limit = 20 (max 50) }.
 * Returns the translations; nothing is written.
 */
exports.batchTranslateMessages = functions
    .runWith(runtime)
    .https.onCall((0, monitoring_1.monitored)("batchTranslateMessages", async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const conversationId = data === null || data === void 0 ? void 0 : data.conversationId;
    const targetLanguage = (0, freeTranslate_1.normalizeTarget)(String((_a = data === null || data === void 0 ? void 0 : data.targetLanguage) !== null && _a !== void 0 ? _a : 'en'));
    const limit = Math.min(Math.max(Number(data === null || data === void 0 ? void 0 : data.limit) || 20, 1), 50);
    if (!conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
    }
    try {
        await assertParticipant(conversationId, context.auth.uid);
        const messagesSnapshot = await firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('sentAt', 'desc') // single-field: no composite index needed
            .limit(limit)
            .get();
        const docs = messagesSnapshot.docs.filter((d) => d.data().type === 'text');
        const translations = await (0, freeTranslate_1.freeTranslateMany)(docs.map((d) => { var _a; return String((_a = d.data().content) !== null && _a !== void 0 ? _a : '').slice(0, MAX_CHARS); }), targetLanguage, { concurrency: 4, timeoutMs: 6000, deadlineMs: 40000 });
        const results = docs.map((doc, i) => {
            const t = translations[i];
            if (!t)
                return { messageId: doc.id, success: false, error: 'unavailable' };
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
    }
    catch (error) {
        console.error('Error in batchTranslateMessages:', error);
        throw toHttpsError(error);
    }
}));
/**
 * Get supported languages (static list; no API call).
 */
exports.getSupportedLanguages = functions
    .runWith(runtime)
    .https.onCall((0, monitoring_1.monitored)("getSupportedLanguages", async (_data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    return { success: true, languages: freeTranslate_1.SUPPORTED_LANGUAGES };
}));
//# sourceMappingURL=translation.js.map