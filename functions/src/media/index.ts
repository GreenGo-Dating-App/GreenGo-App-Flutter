/**
 * Media Processing Service
 * 10 Cloud Functions for image/video compression, transcription, and cleanup
 */

import { onObjectFinalized } from 'firebase-functions/v2/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import sharp from 'sharp';
import ffmpeg from 'fluent-ffmpeg';
import vision from '@google-cloud/vision';
import speech from '@google-cloud/speech';
import { v4 as uuidv4 } from 'uuid';
import { verifyAuth, handleError, logInfo, logError, db, storage } from '../shared/utils';

const visionClient = new vision.ImageAnnotatorClient();
const speechClient = new speech.SpeechClient();

// ========== 1. COMPRESS UPLOADED IMAGE (Storage Trigger) ==========

export const compressUploadedImage = onObjectFinalized(
  {
    bucket: '{your-project}-user-photos',
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // Only process images
    if (!contentType?.startsWith('image/')) {
      return;
    }

    // Skip if already compressed
    if (filePath.includes('_compressed')) {
      return;
    }

    logInfo(`Compressing image: ${filePath}`);

    try {
      const bucket = storage.bucket(event.bucket);
      const file = bucket.file(filePath);

      // Download image
      const [buffer] = await file.download();

      // Compress image
      const compressedBuffer = await sharp(buffer)
        .resize(1920, 1080, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 85, mozjpeg: true })
        .toBuffer();

      // Check if compression achieved <2MB
      const fileSizeMB = compressedBuffer.length / (1024 * 1024);

      if (fileSizeMB > 2) {
        // Further compress
        const furtherCompressed = await sharp(buffer)
          .resize(1280, 720, { fit: 'inside' })
          .jpeg({ quality: 75, mozjpeg: true })
          .toBuffer();

        const newFilePath = filePath.replace(/(\.[^.]+)$/, '_compressed$1');
        await bucket.file(newFilePath).save(furtherCompressed, {
          contentType: 'image/jpeg',
          metadata: {
            metadata: {
              originalFile: filePath,
              compressed: true,
              originalSize: buffer.length,
              compressedSize: furtherCompressed.length,
            },
          },
        });
      } else {
        const newFilePath = filePath.replace(/(\.[^.]+)$/, '_compressed$1');
        await bucket.file(newFilePath).save(compressedBuffer, {
          contentType: 'image/jpeg',
          metadata: {
            metadata: {
              originalFile: filePath,
              compressed: true,
              originalSize: buffer.length,
              compressedSize: compressedBuffer.length,
            },
          },
        });
      }

      // Update Firestore with compressed URL
      const [publicUrl] = await bucket
        .file(filePath.replace(/(\.[^.]+)$/, '_compressed$1'))
        .makePublic();

      logInfo(`Image compressed successfully: ${filePath}`);
    } catch (error) {
      logError('Error compressing image:', error);
      throw error;
    }
  }
);

// ========== 2. COMPRESS IMAGE (HTTP Callable) ==========

interface CompressImageRequest {
  imageUrl: string;
  maxSizeMB?: number;
  quality?: number;
}

export const compressImage = onCall<CompressImageRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { imageUrl, maxSizeMB = 2, quality = 85 } = request.data;

      if (!imageUrl) {
        throw new HttpsError('invalid-argument', 'imageUrl is required');
      }

      logInfo(`Manual compression requested by ${uid} for ${imageUrl}`);

      // Download image from URL
      const response = await fetch(imageUrl);
      const buffer = Buffer.from(await response.arrayBuffer());

      // Compress
      const compressed = await sharp(buffer)
        .resize(1920, 1080, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality, mozjpeg: true })
        .toBuffer();

      const fileSizeMB = compressed.length / (1024 * 1024);

      if (fileSizeMB > maxSizeMB) {
        // Reduce quality further
        const furtherCompressed = await sharp(buffer)
          .resize(1280, 720, { fit: 'inside' })
          .jpeg({ quality: quality - 10, mozjpeg: true })
          .toBuffer();

        // Upload to storage
        const fileName = `compressed/${uid}/${uuidv4()}.jpg`;
        const bucket = storage.bucket();
        await bucket.file(fileName).save(furtherCompressed, {
          contentType: 'image/jpeg',
        });

        const [url] = await bucket.file(fileName).getSignedUrl({
          action: 'read',
          expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
        });

        return {
          success: true,
          compressedUrl: url,
          originalSize: buffer.length,
          compressedSize: furtherCompressed.length,
          compressionRatio: (1 - furtherCompressed.length / buffer.length) * 100,
        };
      }

      // Upload to storage
      const fileName = `compressed/${uid}/${uuidv4()}.jpg`;
      const bucket = storage.bucket();
      await bucket.file(fileName).save(compressed, {
        contentType: 'image/jpeg',
      });

      const [url] = await bucket.file(fileName).getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
      });

      return {
        success: true,
        compressedUrl: url,
        originalSize: buffer.length,
        compressedSize: compressed.length,
        compressionRatio: (1 - compressed.length / buffer.length) * 100,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 3. PROCESS UPLOADED VIDEO (Storage Trigger) ==========

export const processUploadedVideo = onObjectFinalized(
  {
    bucket: '{your-project}-profile-media',
    memory: '2GiB',
    timeoutSeconds: 540,
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    if (!contentType?.startsWith('video/')) {
      return;
    }

    logInfo(`Processing video: ${filePath}`);

    try {
      const bucket = storage.bucket(event.bucket);
      const file = bucket.file(filePath);

      const tempFilePath = `/tmp/${uuidv4()}.mp4`;
      const thumbnailPath = `/tmp/${uuidv4()}.jpg`;

      // Download video
      await file.download({ destination: tempFilePath });

      // Generate thumbnail at 1 second
      await new Promise<void>((resolve, reject) => {
        ffmpeg(tempFilePath)
          .screenshots({
            timestamps: ['00:00:01'],
            filename: thumbnailPath,
            size: '1280x720',
          })
          .on('end', () => resolve())
          .on('error', (err) => reject(err));
      });

      // Upload thumbnail
      const thumbnailFileName = filePath.replace(/\.[^.]+$/, '_thumbnail.jpg');
      await bucket.upload(thumbnailPath, {
        destination: thumbnailFileName,
        contentType: 'image/jpeg',
      });

      // Validate video duration (max 60 seconds)
      const metadata: any = await new Promise((resolve, reject) => {
        ffmpeg.ffprobe(tempFilePath, (err, metadata) => {
          if (err) reject(err);
          else resolve(metadata);
        });
      });

      const duration = metadata.format.duration;

      if (duration > 60) {
        logError(`Video too long: ${duration}s (max 60s)`);
        // Mark for review
        await db.collection('moderation_queue').add({
          type: 'video_too_long',
          filePath,
          duration,
          uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      logInfo(`Video processed successfully: ${filePath}`);
    } catch (error) {
      logError('Error processing video:', error);
      throw error;
    }
  }
);

// ========== 4. GENERATE VIDEO THUMBNAIL (HTTP Callable) ==========

interface GenerateThumbnailRequest {
  videoUrl: string;
  timestampSeconds?: number;
}

export const generateVideoThumbnail = onCall<GenerateThumbnailRequest>(
  {
    memory: '2GiB',
    timeoutSeconds: 540,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { videoUrl, timestampSeconds = 1 } = request.data;

      if (!videoUrl) {
        throw new HttpsError('invalid-argument', 'videoUrl is required');
      }

      logInfo(`Generating thumbnail for ${videoUrl} at ${timestampSeconds}s`);

      const tempVideoPath = `/tmp/${uuidv4()}.mp4`;
      const thumbnailPath = `/tmp/${uuidv4()}.jpg`;

      // Download video
      const response = await fetch(videoUrl);
      const buffer = Buffer.from(await response.arrayBuffer());
      const fs = require('fs');
      fs.writeFileSync(tempVideoPath, buffer);

      // Generate thumbnail
      await new Promise<void>((resolve, reject) => {
        ffmpeg(tempVideoPath)
          .screenshots({
            timestamps: [timestampSeconds],
            filename: thumbnailPath,
            size: '1280x720',
          })
          .on('end', () => resolve())
          .on('error', (err) => reject(err));
      });

      // Upload thumbnail
      const fileName = `thumbnails/${uid}/${uuidv4()}.jpg`;
      const bucket = storage.bucket();
      const thumbnailBuffer = fs.readFileSync(thumbnailPath);

      await bucket.file(fileName).save(thumbnailBuffer, {
        contentType: 'image/jpeg',
      });

      const [url] = await bucket.file(fileName).getSignedUrl({
        action: 'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
      });

      return {
        success: true,
        thumbnailUrl: url,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 5. TRANSCRIBE VOICE MESSAGE (Storage Trigger) ==========

export const transcribeVoiceMessage = onObjectFinalized(
  {
    bucket: '{your-project}-chat-attachments',
    memory: '1GiB',
    timeoutSeconds: 300,
  },
  async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;

    // Only process audio files
    if (!contentType?.startsWith('audio/')) {
      return;
    }

    logInfo(`Transcribing audio: ${filePath}`);

    try {
      const bucket = storage.bucket(event.bucket);
      const gcsUri = `gs://${event.bucket}/${filePath}`;

      // Extract language from metadata or default to en-US
      const [metadata] = await bucket.file(filePath).getMetadata();
      const languageCode = String(metadata.metadata?.languageCode || 'en-US');

      // Transcribe
      const operation = await speechClient.longRunningRecognize({
        config: {
          encoding: 'LINEAR16',
          sampleRateHertz: 16000,
          languageCode,
          enableAutomaticPunctuation: true,
        },
        audio: {
          uri: gcsUri,
        },
      });

      const [response] = await (operation as any)[0].promise();
      const transcription = response.results
        ?.map((result: any) => result.alternatives![0].transcript)
        .join('\n');

      // Save transcription to Firestore
      const messageId = String(metadata.metadata?.messageId || '');
      if (messageId) {
        await db.collection('messages').doc(messageId).update({
          transcription,
          transcribedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      logInfo(`Audio transcribed successfully: ${filePath}`);
    } catch (error) {
      logError('Error transcribing audio:', error);
      throw error;
    }
  }
);

// ========== 6. TRANSCRIBE AUDIO (HTTP Callable) ==========

interface TranscribeAudioRequest {
  audioUrl: string;
  languageCode?: string;
}

export const transcribeAudio = onCall<TranscribeAudioRequest>(
  {
    memory: '1GiB',
    timeoutSeconds: 300,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { audioUrl, languageCode = 'en-US' } = request.data;

      if (!audioUrl) {
        throw new HttpsError('invalid-argument', 'audioUrl is required');
      }

      logInfo(`Transcribing audio for ${uid}: ${audioUrl}`);

      // Download audio
      const response = await fetch(audioUrl);
      const buffer = Buffer.from(await response.arrayBuffer());

      // Transcribe
      const [speechResponse] = await speechClient.recognize({
        config: {
          encoding: 'LINEAR16',
          sampleRateHertz: 16000,
          languageCode,
          enableAutomaticPunctuation: true,
        },
        audio: {
          content: buffer.toString('base64'),
        },
      });

      const transcription = speechResponse.results
        ?.map((result) => result.alternatives![0].transcript)
        .join('\n');

      return {
        success: true,
        transcription,
        confidence: speechResponse.results?.[0]?.alternatives?.[0]?.confidence || 0,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 7. BATCH TRANSCRIBE (HTTP Callable) ==========

interface BatchTranscribeRequest {
  audioUrls: string[];
  languageCode?: string;
}

export const batchTranscribe = onCall<BatchTranscribeRequest>(
  {
    memory: '1GiB',
    timeoutSeconds: 540,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { audioUrls, languageCode = 'en-US' } = request.data;

      if (!audioUrls || audioUrls.length === 0) {
        throw new HttpsError('invalid-argument', 'audioUrls is required');
      }

      logInfo(`Batch transcribing ${audioUrls.length} audio files for ${uid}`);

      const transcriptions = await Promise.all(
        audioUrls.map(async (audioUrl) => {
          const response = await fetch(audioUrl);
          const buffer = Buffer.from(await response.arrayBuffer());

          const [speechResponse] = await speechClient.recognize({
            config: {
              encoding: 'LINEAR16',
              sampleRateHertz: 16000,
              languageCode,
              enableAutomaticPunctuation: true,
            },
            audio: {
              content: buffer.toString('base64'),
            },
          });

          const transcription = speechResponse.results
            ?.map((result) => result.alternatives![0].transcript)
            .join('\n');

          return {
            audioUrl,
            transcription,
            confidence: speechResponse.results?.[0]?.alternatives?.[0]?.confidence || 0,
          };
        })
      );

      return {
        success: true,
        transcriptions,
        totalProcessed: transcriptions.length,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);

// ========== 8. CLEANUP DISAPPEARING MEDIA (Scheduled - Hourly) ==========

export const cleanupDisappearingMedia = onSchedule(
  {
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async () => {
    logInfo('Starting cleanup of disappearing media');

    try {
      const cutoffTime = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago

      // Query messages marked as disappearing
      const snapshot = await db
        .collection('messages')
        .where('disappearing', '==', true)
        .where('createdAt', '<', cutoffTime)
        .get();

      logInfo(`Found ${snapshot.size} disappearing media files to delete`);

      const batch = db.batch();
      const filesToDelete: string[] = [];

      snapshot.forEach((doc) => {
        const data = doc.data();
        if (data.mediaUrl) {
          filesToDelete.push(data.mediaUrl);
        }
        batch.delete(doc.ref);
      });

      // Delete from Storage
      for (const fileUrl of filesToDelete) {
        try {
          const bucket = storage.bucket();
          const fileName = fileUrl.split('/').pop();
          if (fileName) {
            await bucket.file(fileName).delete();
          }
        } catch (error) {
          logError(`Error deleting file ${fileUrl}:`, error);
        }
      }

      // Delete from Firestore
      await batch.commit();

      logInfo(`Cleanup completed: ${snapshot.size} items deleted`);
    } catch (error) {
      logError('Error during cleanup:', error);
      throw error;
    }
  }
);

// ========== 9. MARK MEDIA AS DISAPPEARING (HTTP Callable) ==========

interface MarkDisappearingRequest {
  messageId: string;
  disappearing: boolean;
}

export const markMediaAsDisappearing = onCall<MarkDisappearingRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { messageId, disappearing } = request.data;

      if (!messageId) {
        throw new HttpsError('invalid-argument', 'messageId is required');
      }

      const messageRef = db.collection('messages').doc(messageId);
      const messageDoc = await messageRef.get();

      if (!messageDoc.exists) {
        throw new HttpsError('not-found', 'Message not found');
      }

      const messageData = messageDoc.data();

      // Verify user owns the message
      if (messageData?.senderId !== uid) {
        throw new HttpsError('permission-denied', 'Not authorized');
      }

      await messageRef.update({
        disappearing,
        markedDisappearingAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: `Message marked as ${disappearing ? 'disappearing' : 'permanent'}`,
      };
    } catch (error) {
      throw handleError(error);
    }
  }
);
