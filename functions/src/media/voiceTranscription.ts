/**
 * Voice Transcription Cloud Function
 * Point 107: Transcribe voice messages using Cloud Speech-to-Text API
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { SpeechClient } from '@google-cloud/speech';
import { monitored } from '../shared/monitoring';

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

// ---------------------------------------------------------------------------
// H-14 (security Phase 1): transcribeAudio accepted ANY bucket path and
// batchTranscribe ANY conversationId with an unbounded limit, so any signed-in
// user could transcribe other people's voice messages and run up Speech-to-Text
// cost. Now: (1) only chat-voice prefixes, (2) the caller must be a member of
// the conversation / group the audio belongs to, (3) batch limit capped,
// (4) per-user daily quota (transcription_quota/{uid}_{yyyy-mm-dd}).
// ---------------------------------------------------------------------------
export const BATCH_TRANSCRIBE_MAX = 20;
export const DAILY_TRANSCRIPTION_QUOTA = 60;
const SEGMENT = /^[A-Za-z0-9_-]{1,128}$/;

/** Storage object path from a download URL, gs:// URI or plain path. */
export function storagePathFromAudioUrl(audioUrl: unknown): string | null {
  if (typeof audioUrl !== 'string' || !audioUrl || audioUrl.length > 2048) return null;
  let path: string;
  try {
    if (audioUrl.startsWith('gs://')) {
      path = audioUrl.replace(/^gs:\/\/[^/]+\//, '');
    } else if (/^https?:\/\//.test(audioUrl)) {
      const u = new URL(audioUrl);
      const m = u.pathname.match(/\/o\/(.+)$/); // Firebase Storage download URL
      path = decodeURIComponent(m ? m[1] : u.pathname.split('/').slice(2).join('/'));
    } else {
      path = decodeURIComponent(audioUrl.split('?')[0]);
    }
  } catch {
    return null;
  }
  if (!path || path.includes('..') || path.startsWith('/') || path.includes('\\')) return null;
  return path;
}

type AudioOwner = { kind: 'conversation' | 'match' | 'group'; id: string };

/** Which conversation / match / group an audio path belongs to; null = not allowed. */
export function audioOwnerFromPath(path: string): AudioOwner | null {
  const parts = path.split('/');
  if (parts.length < 3 || parts.some((p) => !p)) return null;
  const [root, id] = parts;
  if (!SEGMENT.test(id)) return null;
  if (root === 'chat_voice') return { kind: 'match', id };
  if (root === 'voice_notes') return { kind: 'conversation', id };
  if (root === 'group_voice') return { kind: 'group', id };
  return null;
}

function isConversationMember(c: FirebaseFirestore.DocumentData | undefined, uid: string): boolean {
  if (!c) return false;
  return c.userId1 === uid || c.userId2 === uid || c.supportAgentId === uid ||
    (Array.isArray(c.participants) && c.participants.includes(uid));
}

async function callerOwnsAudio(owner: AudioOwner, uid: string): Promise<boolean> {
  if (owner.kind === 'group') {
    const g = await firestore.collection('groups').doc(owner.id).get();
    const p = g.data()?.participants;
    return Array.isArray(p) && p.includes(uid);
  }
  // chat_voice/{matchId}: the app keys 1:1 media by matchId and conversations
  // carry `matchId`. A conversation id is accepted directly too.
  const direct = await firestore.collection('conversations').doc(owner.id).get();
  if (direct.exists && isConversationMember(direct.data(), uid)) return true;
  if (owner.kind === 'match') {
    for (const field of ['userId1', 'userId2']) {
      const q = await firestore.collection('conversations')
        .where('matchId', '==', owner.id).where(field, '==', uid).limit(1).get();
      if (!q.empty) return true;
    }
  }
  return false;
}

/** Reserves up to `wanted` transcriptions from today's quota; returns how many. */
async function reserveQuota(uid: string, wanted: number): Promise<number> {
  const day = new Date().toISOString().slice(0, 10);
  const ref = firestore.collection('transcription_quota').doc(`${uid}_${day}`);
  return firestore.runTransaction(async (tx) => {
    const used = Number((await tx.get(ref)).data()?.count) || 0;
    const granted = Math.max(0, Math.min(wanted, DAILY_TRANSCRIPTION_QUOTA - used));
    if (granted > 0) {
      tx.set(ref, {
        userId: uid, day, count: used + granted,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    return granted;
  });
}

/**
 * HTTP function to manually transcribe a voice message
 */
export const transcribeAudio = functions
  .runWith({ memory: '1GB', timeoutSeconds: 300 })
  .https.onCall(monitored("transcribeAudio", async (data, context) => {
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
    if (typeof languageCode !== 'string' || !/^[A-Za-z]{2,3}(-[A-Za-z0-9]{2,8})?$/.test(languageCode)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid languageCode');
    }
    const filePath = storagePathFromAudioUrl(audioUrl);
    const owner = filePath ? audioOwnerFromPath(filePath) : null;
    if (!filePath || !owner) {
      throw new functions.https.HttpsError('invalid-argument', 'Not a chat voice message');
    }
    if (!(await callerOwnsAudio(owner, context.auth.uid))) {
      throw new functions.https.HttpsError('permission-denied', 'Not a participant of this conversation');
    }

    // Verify file exists (before spending quota)
    const bucket = storage.bucket();
    const file = bucket.file(filePath);
    const [exists] = await file.exists();
    if (!exists) {
      throw new functions.https.HttpsError('not-found', 'Audio file not found');
    }
    if ((await reserveQuota(context.auth.uid, 1)) < 1) {
      throw new functions.https.HttpsError('resource-exhausted', 'Daily transcription limit reached');
    }

    try {
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
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError('internal', error.message);
    }
  }));

/**
 * Batch transcription for multiple voice messages
 */
export const batchTranscribe = functions
  .runWith({ memory: '2GB', timeoutSeconds: 540 })
  .https.onCall(monitored("batchTranscribe", async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { conversationId } = data;

    if (!conversationId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'conversationId is required'
      );
    }
    if (typeof conversationId !== 'string' || !SEGMENT.test(conversationId)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid conversationId');
    }
    const requested = Number(data.limit ?? 10);
    const limit = Math.max(1, Math.min(BATCH_TRANSCRIBE_MAX,
      Number.isFinite(requested) ? Math.floor(requested) : 10));

    const conv = await firestore.collection('conversations').doc(conversationId).get();
    const convData = conv.data();
    if (!conv.exists || !isConversationMember(convData, context.auth.uid)) {
      throw new functions.https.HttpsError('permission-denied', 'Not a participant of this conversation');
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

      const allowed = messagesSnapshot.empty
        ? 0
        : await reserveQuota(context.auth.uid, messagesSnapshot.size);
      if (!messagesSnapshot.empty && allowed < 1) {
        throw new functions.https.HttpsError('resource-exhausted', 'Daily transcription limit reached');
      }

      const results = [];

      for (const doc of messagesSnapshot.docs.slice(0, allowed)) {
        const message = doc.data();
        const audioUrl = message.content;

        try {
          // Only audio under a chat-voice prefix of THIS conversation (or its
          // match): a message must not point us at arbitrary bucket objects.
          const filePath = storagePathFromAudioUrl(audioUrl);
          const owner = filePath ? audioOwnerFromPath(filePath) : null;
          if (!filePath || !owner || owner.kind === 'group' ||
              (owner.id !== conversationId && owner.id !== convData?.matchId)) {
            throw new Error('Audio is not part of this conversation');
          }

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
      if (error instanceof functions.https.HttpsError) throw error;
      throw new functions.https.HttpsError('internal', error.message);
    }
  }));
