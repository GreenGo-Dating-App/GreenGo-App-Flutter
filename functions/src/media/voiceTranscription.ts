/**
 * Voice Transcription Cloud Function
 * Point 107: Transcribe voice messages using Cloud Speech-to-Text API
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { SpeechClient } from '@google-cloud/speech';

const storage = admin.storage();
const firestore = admin.firestore();
const speechClient = new SpeechClient();

/**
 * Triggered when an audio file is uploaded
 * Transcribes the voice message
 */
export const transcribeVoiceMessage = functions
  .runWith({ memory: '1GB', timeoutSeconds: 300 })
  .storage.object()
  .onFinalize(async (object) => {
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
        encoding: 'OGG_OPUS' as const, // Common format for voice messages
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
        .map((result) => result.alternatives[0]?.transcript || '')
        .join('\n')
        .trim();

      // Get confidence score
      const confidence =
        response.results[0]?.alternatives[0]?.confidence || 0;

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
    } catch (error) {
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
            'metadata.transcriptionAttemptedAt':
              admin.firestore.FieldValue.serverTimestamp(),
          });
      }

      throw error;
    }
  });

/**
 * HTTP function to manually transcribe a voice message
 */
export const transcribeAudio = functions
  .runWith({ memory: '1GB', timeoutSeconds: 300 })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
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
        encoding: 'OGG_OPUS' as const,
        sampleRateHertz: 48000,
        languageCode,
        enableAutomaticPunctuation: true,
      };

      const [response] = await speechClient.recognize({ audio, config });

      const transcription = response.results
        ?.map((result) => result.alternatives[0]?.transcript || '')
        .join('\n')
        .trim() || '';

      const confidence = response.results?.[0]?.alternatives[0]?.confidence || 0;

      return {
        success: true,
        transcription,
        confidence,
      };
    } catch (error) {
      console.error('Error in transcribeAudio:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });

/**
 * Batch transcription for multiple voice messages
 */
export const batchTranscribe = functions
  .runWith({ memory: '2GB', timeoutSeconds: 540 })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { conversationId, limit = 10 } = data;

    if (!conversationId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'conversationId is required'
      );
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
          const filePath = decodeURIComponent(
            urlParts[urlParts.length - 1].split('?')[0]
          );

          const bucket = storage.bucket();
          const gcsUri = `gs://${bucket.name}/${filePath}`;

          const [response] = await speechClient.recognize({
            audio: { uri: gcsUri },
            config: {
              encoding: 'OGG_OPUS' as const,
              sampleRateHertz: 48000,
              languageCode: 'en-US',
              enableAutomaticPunctuation: true,
            },
          });

          const transcription =
            response.results
              ?.map((result) => result.alternatives[0]?.transcript || '')
              .join('\n')
              .trim() || '';

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
      console.error('Error in batchTranscribe:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });
