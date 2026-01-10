"use strict";
/**
 * Message Translation Cloud Function
 * Points 111-113: Real-time translation using Cloud Translation API
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
exports.getSupportedLanguages = exports.batchTranslateMessages = exports.autoTranslateMessage = exports.translateMessage = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const translate_1 = require("@google-cloud/translate");
const firestore = admin.firestore();
const translationClient = new translate_1.TranslationServiceClient();
// Your Google Cloud project ID
const projectId = process.env.GCLOUD_PROJECT;
/**
 * Translate a message to the target language
 */
exports.translateMessage = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d, _e, _f, _g;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { messageId, conversationId, targetLanguage = 'en' } = data;
    if (!messageId || !conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'messageId and conversationId are required');
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
            throw new functions.https.HttpsError('invalid-argument', 'Only text messages can be translated');
        }
        const text = message.content;
        // Check if already translated to this language
        if (message.translatedContent &&
            ((_a = message.metadata) === null || _a === void 0 ? void 0 : _a.translatedLanguage) === targetLanguage) {
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
        const detectedLanguage = ((_c = (_b = detection.languages) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.languageCode) || 'unknown';
        const confidence = ((_e = (_d = detection.languages) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.confidence) || 0;
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
        const translatedContent = ((_g = (_f = translation.translations) === null || _f === void 0 ? void 0 : _f[0]) === null || _g === void 0 ? void 0 : _g.translatedText) || text;
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
    }
    catch (error) {
        console.error('Error translating message:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Auto-translate messages based on user preferences
 */
exports.autoTranslateMessage = functions.firestore
    .document('conversations/{conversationId}/messages/{messageId}')
    .onCreate(async (snapshot, context) => {
    var _a, _b, _c, _d;
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
        const preferredLanguage = userData === null || userData === void 0 ? void 0 : userData.preferredLanguage;
        const autoTranslate = userData === null || userData === void 0 ? void 0 : userData.autoTranslateMessages;
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
        const detectedLanguage = ((_b = (_a = detection.languages) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.languageCode) || 'unknown';
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
        const translatedContent = ((_d = (_c = translation.translations) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.translatedText) || message.content;
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
    }
    catch (error) {
        console.error('Error in auto-translate:', error);
        return null; // Don't fail message creation
    }
});
/**
 * Batch translate multiple messages
 */
exports.batchTranslateMessages = functions.https.onCall(async (data, context) => {
    var _a, _b, _c, _d;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId, targetLanguage = 'en', limit = 20 } = data;
    if (!conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
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
                const detectedLanguage = ((_b = (_a = detection.languages) === null || _a === void 0 ? void 0 : _a[0]) === null || _b === void 0 ? void 0 : _b.languageCode) || 'unknown';
                if (detectedLanguage !== targetLanguage) {
                    const [translation] = await translationClient.translateText({
                        parent,
                        contents: [message.content],
                        targetLanguageCode: targetLanguage,
                        sourceLanguageCode: detectedLanguage,
                    });
                    const translatedContent = ((_d = (_c = translation.translations) === null || _c === void 0 ? void 0 : _c[0]) === null || _d === void 0 ? void 0 : _d.translatedText) || message.content;
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
                }
                else {
                    results.push({
                        messageId: doc.id,
                        success: true,
                        sameLanguage: true,
                    });
                }
            }
            catch (error) {
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
    }
    catch (error) {
        console.error('Error in batchTranslateMessages:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get supported languages
 */
exports.getSupportedLanguages = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    try {
        const parent = `projects/${projectId}/locations/global`;
        const [response] = await translationClient.getSupportedLanguages({
            parent,
            displayLanguageCode: data.displayLanguage || 'en',
        });
        const languages = ((_a = response.languages) === null || _a === void 0 ? void 0 : _a.map((lang) => ({
            code: lang.languageCode,
            name: lang.displayName,
        }))) || [];
        return {
            success: true,
            languages,
        };
    }
    catch (error) {
        console.error('Error getting supported languages:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=translation.js.map