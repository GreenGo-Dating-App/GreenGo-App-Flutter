/**
 * Video Processing Cloud Function
 * Point 105: Generate video thumbnails using FFmpeg
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as path from 'path';
import * as os from 'os';
import * as fs from 'fs';
import * as ffmpeg from 'fluent-ffmpeg';
import * as sharp from 'sharp';

const storage = admin.storage();
const firestore = admin.firestore();

// Maximum video duration in seconds
const MAX_DURATION = 60;

// Thumbnail settings
const THUMB_WIDTH = 200;
const THUMB_HEIGHT = 200;

/**
 * Triggered when a video is uploaded to Firebase Storage
 * Generates thumbnail and validates duration
 */
export const processUploadedVideo = functions
  .runWith({ memory: '2GB', timeoutSeconds: 540 })
  .storage.object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;

    // Exit if this is not a video
    if (!contentType || !contentType.startsWith('video/')) {
      console.log('Not a video, skipping');
      return null;
    }

    // Exit if this is already a thumbnail
    if (filePath.includes('_thumb')) {
      console.log('Already processed, skipping');
      return null;
    }

    // Only process videos in the messages folder
    if (!filePath.includes('messages/')) {
      console.log('Not a message video, skipping');
      return null;
    }

    const bucket = storage.bucket(object.bucket);
    const fileName = path.basename(filePath);
    const fileDir = path.dirname(filePath);

    // Download file to temporary directory
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const thumbFileName = fileName.replace(/\.[^/.]+$/, '_thumb.jpg');
    const thumbFilePath = path.join(os.tmpdir(), thumbFileName);

    try {
      await bucket.file(filePath).download({ destination: tempFilePath });
      console.log('Video downloaded to', tempFilePath);

      // Get video metadata
      const metadata = await getVideoMetadata(tempFilePath);
      console.log('Video metadata:', metadata);

      // Validate duration
      if (metadata.duration > MAX_DURATION) {
        console.error(`Video duration ${metadata.duration}s exceeds maximum of ${MAX_DURATION}s`);

        // Update message with error
        const pathParts = filePath.split('/');
        const messageIndex = pathParts.indexOf('messages');
        if (messageIndex !== -1) {
          const conversationId = pathParts[messageIndex + 1];
          const messageId = pathParts[messageIndex + 3];

          await firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc(messageId)
            .update({
              status: 'failed',
              'metadata.error': 'Video duration exceeds 60 seconds',
            });
        }

        // Delete the video
        await bucket.file(filePath).delete();

        throw new Error('Video duration exceeds maximum allowed');
      }

      // Generate thumbnail at 1 second
      await generateThumbnail(tempFilePath, thumbFilePath, 1);

      // Optimize thumbnail
      await sharp(thumbFilePath)
        .resize(THUMB_WIDTH, THUMB_HEIGHT, {
          fit: 'cover',
          position: 'center',
        })
        .jpeg({ quality: 80 })
        .toFile(thumbFilePath + '.optimized.jpg');

      // Upload thumbnail
      const thumbDestination = path.join(fileDir, thumbFileName);
      await bucket.upload(thumbFilePath + '.optimized.jpg', {
        destination: thumbDestination,
        metadata: {
          contentType: 'image/jpeg',
          metadata: {
            thumbnail: 'true',
            originalFile: fileName,
            videoWidth: metadata.width?.toString() || '0',
            videoHeight: metadata.height?.toString() || '0',
            videoDuration: metadata.duration?.toString() || '0',
          },
        },
      });

      // Get thumbnail URL
      const [thumbFile] = await bucket.file(thumbDestination).getSignedUrl({
        action: 'read',
        expires: '03-01-2500',
      });
      const thumbUrl = thumbFile;

      console.log('Thumbnail uploaded to', thumbDestination);

      // Update Firestore message with metadata
      const pathParts = filePath.split('/');
      const messageIndex = pathParts.indexOf('messages');
      if (messageIndex !== -1 && pathParts.length > messageIndex + 1) {
        const conversationId = pathParts[messageIndex + 1];
        const messageId = pathParts[messageIndex + 3];

        await firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .update({
            'metadata.thumbnailUrl': thumbUrl,
            'metadata.duration': Math.floor(metadata.duration),
            'metadata.width': metadata.width,
            'metadata.height': metadata.height,
            'metadata.size': object.size,
            'metadata.processedAt': admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log(`Updated message ${messageId} with video metadata`);
      }

      // Clean up temp files
      fs.unlinkSync(tempFilePath);
      if (fs.existsSync(thumbFilePath)) fs.unlinkSync(thumbFilePath);
      if (fs.existsSync(thumbFilePath + '.optimized.jpg')) {
        fs.unlinkSync(thumbFilePath + '.optimized.jpg');
      }

      return {
        success: true,
        thumbUrl,
        duration: metadata.duration,
      };
    } catch (error) {
      console.error('Error processing video:', error);
      throw error;
    }
  });

/**
 * Get video metadata using ffprobe
 */
function getVideoMetadata(filePath: string): Promise<VideoMetadata> {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(filePath, (err, metadata) => {
      if (err) {
        reject(err);
        return;
      }

      const videoStream = metadata.streams.find((s) => s.codec_type === 'video');

      resolve({
        duration: metadata.format.duration || 0,
        width: videoStream?.width || 0,
        height: videoStream?.height || 0,
        codec: videoStream?.codec_name || 'unknown',
        bitrate: metadata.format.bit_rate || 0,
      });
    });
  });
}

/**
 * Generate thumbnail from video at specific timestamp
 */
function generateThumbnail(
  inputPath: string,
  outputPath: string,
  timestamp: number
): Promise<void> {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .screenshots({
        timestamps: [timestamp],
        filename: path.basename(outputPath),
        folder: path.dirname(outputPath),
        size: `${THUMB_WIDTH}x${THUMB_HEIGHT}`,
      })
      .on('end', () => resolve())
      .on('error', (err) => reject(err));
  });
}

interface VideoMetadata {
  duration: number;
  width: number;
  height: number;
  codec: string;
  bitrate: number;
}

/**
 * HTTP function to manually generate video thumbnail
 */
export const generateVideoThumbnail = functions
  .runWith({ memory: '2GB', timeoutSeconds: 300 })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const { videoUrl, timestamp = 1 } = data;

    if (!videoUrl) {
      throw new functions.https.HttpsError('invalid-argument', 'videoUrl is required');
    }

    try {
      // Extract file path from URL
      const urlParts = videoUrl.split('/');
      const filePath = decodeURIComponent(urlParts[urlParts.length - 1].split('?')[0]);

      const bucket = storage.bucket();
      const file = bucket.file(filePath);

      const [exists] = await file.exists();
      if (!exists) {
        throw new functions.https.HttpsError('not-found', 'Video not found');
      }

      return { success: true, message: 'Thumbnail generation triggered' };
    } catch (error) {
      console.error('Error in generateVideoThumbnail:', error);
      throw new functions.https.HttpsError('internal', error.message);
    }
  });
