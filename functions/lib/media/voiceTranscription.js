"use strict";
/**
 * Voice Transcription Cloud Function
 * Point 107: Transcribe voice messages using Cloud Speech-to-Text API
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
exports.batchTranscribe = exports.transcribeAudio = exports.transcribeVoiceMessage = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const speech_1 = require("@google-cloud/speech");
const storage = admin.storage();
const firestore = admin.firestore();
const speechClient = new speech_1.SpeechClient();
/**
 * Triggered when an audio file is uploaded
 * Transcribes the voice message
 */
exports.transcribeVoiceMessage = functions
    .runWith({ memory: '1GB', timeoutSeconds: 300 })
    .storage.object()
    .onFinalize(async (object) => {
    var _a, _b;
    const filePath = object.name;
    const contentType = object.contentType;
    // Exit if this is not an audio file
    if (!contentType || !contentType.startsWith('audio/')) {
        console.log('Not an audio file, skipping');
        return null;
    }
    // Only process audio in the voice_notes folder
    if (!filePath.includes('voice_notes/')) {
        console.log('Not a voice note, skipping');
        return null;
    }
    // Exit if already transcribed
    if (filePath.includes('_transcribed')) {
        console.log('Already transcribed, skipping');
        return null;
    }
    try {
        console.log('Transcribing audio file:', filePath);
        // Construct the GCS URI
        const gcsUri = `gs://${object.bucket}/${filePath}`;
        // Configure the transcription request
        const audio = {
            uri: gcsUri,
        };
        const config = {
            encoding: 'OGG_OPUS', // Common format for voice messages
            sampleRateHertz: 48000,
            languageCode: 'en-US',
            alternativeLanguageCodes: ['es-ES', 'fr-FR', 'de-DE', 'pt-BR', 'it-IT'],
            enableAutomaticPunctuation: true,
            enableWordTimeOffsets: false,
            model: 'default',
            useEnhanced: true,
        };
        const request = {
            audio,
            config,
        };
        // Perform the transcription
        const [operation] = await speechClient.longRunningRecognize(request);
        const [response] = await operation.promise();
        if (!response.results || response.results.length === 0) {
            console.log('No transcription results');
            return null;
        }
        // Extract the transcript
        const transcription = response.results
            .map((result) => { var _a; return ((_a = result.alternatives[0]) === null || _a === void 0 ? void 0 : _a.transcript) || ''; })
            .join('\n')
            .trim();
        // Get confidence score
        const confidence = ((_b = (_a = response.results[0]) === null || _a === void 0 ? void 0 : _a.alternatives[0]) === null || _b === void 0 ? void 0 : _b.confidence) || 0;
        console.log('Transcription:', transcription);
        console.log('Confidence:', confidence);
        // Update Firestore message with transcription
        const pathParts = filePath.split('/');
        const messageIndex = pathParts.indexOf('voice_notes');
        if (messageIndex !== -1 && pathParts.length > messageIndex + 1) {
            const conversationId = pathParts[messageIndex + 1];
            const messageId = pathParts[messageIndex + 3];
            await firestore
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .doc(messageId)
                .update({
                'metadata.transcription': transcription,
                'metadata.transcriptionConfidence': confidence,
                'metadata.transcribedAt': admin.firestore.FieldValue.serverTimestamp(),
                'metadata.detectedLanguage': config.languageCode,
            });
            console.log(`Updated message ${messageId} with transcription`);
        }
        return {
            success: true,
            transcription,
            confidence,
        };
    }
    catch (error) {
        console.error('Error transcribing audio:', error);
        // Log error to message metadata
        const pathParts = filePath.split('/');
        const messageIndex = pathParts.indexOf('voice_notes');
        if (messageIndex !== -1) {
            const conversationId = pathParts[messageIndex + 1];
            const messageId = pathParts[messageIndex + 3];
            await firestore
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .doc(messageId)
                .update({
                'metadata.transcriptionError': error.message,
                'metadata.transcriptionAttemptedAt': admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        throw error;
    }
});
/**
 * HTTP function to manually transcribe a voice message
 */
exports.transcribeAudio = functions
    .runWith({ memory: '1GB', timeoutSeconds: 300 })
    .https.onCall(async (data, context) => {
    var _a, _b, _c, _d;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { audioUrl, languageCode = 'en-US' } = data;
    if (!audioUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'audioUrl is required');
    }
    try {
        // Extract file path from URL
        const urlParts = audioUrl.split('/');
        const filePath = decodeURIComponent(urlParts[urlParts.length - 1].split('?')[0]);
        // Verify file exists
        const bucket = storage.bucket();
        const file = bucket.file(filePath);
        const [exists] = await file.exists();
        if (!exists) {
            throw new functions.https.HttpsError('not-found', 'Audio file not found');
        }
        // Construct the GCS URI
        const gcsUri = `gs://${bucket.name}/${filePath}`;
        // Configure and perform transcription
        const audio = { uri: gcsUri };
        const config = {
            encoding: 'OGG_OPUS',
            sampleRateHertz: 48000,
            languageCode,
            enableAutomaticPunctuation: true,
        };
        const [response] = await speechClient.recognize({ audio, config });
        const transcription = ((_a = response.results) === null || _a === void 0 ? void 0 : _a.map((result) => { var _a; return ((_a = result.alternatives[0]) === null || _a === void 0 ? void 0 : _a.transcript) || ''; }).join('\n').trim()) || '';
        const confidence = ((_d = (_c = (_b = response.results) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.alternatives[0]) === null || _d === void 0 ? void 0 : _d.confidence) || 0;
        return {
            success: true,
            transcription,
            confidence,
        };
    }
    catch (error) {
        console.error('Error in transcribeAudio:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Batch transcription for multiple voice messages
 */
exports.batchTranscribe = functions
    .runWith({ memory: '2GB', timeoutSeconds: 540 })
    .https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { conversationId, limit = 10 } = data;
    if (!conversationId) {
        throw new functions.https.HttpsError('invalid-argument', 'conversationId is required');
    }
    try {
        // Get voice messages without transcriptions
        const messagesSnapshot = await firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .where('type', '==', 'voice_note')
            .where('metadata.transcription', '==', null)
            .limit(limit)
            .get();
        const results = [];
        for (const doc of messagesSnapshot.docs) {
            const message = doc.data();
            const audioUrl = message.content;
            try {
                // Extract file path and transcribe
                const urlParts = audioUrl.split('/');
                const filePath = decodeURIComponent(urlParts[urlParts.length - 1].split('?')[0]);
                const bucket = storage.bucket();
                const gcsUri = `gs://${bucket.name}/${filePath}`;
                const [response] = await speechClient.recognize({
                    audio: { uri: gcsUri },
                    config: {
                        encoding: 'OGG_OPUS',
                        sampleRateHertz: 48000,
                        languageCode: 'en-US',
                        enableAutomaticPunctuation: true,
                    },
                });
                const transcription = ((_a = response.results) === null || _a === void 0 ? void 0 : _a.map((result) => { var _a; return ((_a = result.alternatives[0]) === null || _a === void 0 ? void 0 : _a.transcript) || ''; }).join('\n').trim()) || '';
                // Update message
                await doc.ref.update({
                    'metadata.transcription': transcription,
                    'metadata.transcribedAt': admin.firestore.FieldValue.serverTimestamp(),
                });
                results.push({
                    messageId: doc.id,
                    success: true,
                    transcription,
                });
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
        console.error('Error in batchTranscribe:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=voiceTranscription.js.map