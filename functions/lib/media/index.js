"use strict";
/**
 * Media Processing Service
 * 10 Cloud Functions for image/video compression, transcription, and cleanup
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.markMediaAsDisappearing = exports.cleanupDisappearingMedia = exports.batchTranscribe = exports.transcribeAudio = exports.transcribeVoiceMessage = exports.generateVideoThumbnail = exports.processUploadedVideo = exports.compressImage = exports.compressUploadedImage = void 0;
const storage_1 = require("firebase-functions/v2/storage");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const sharp_1 = __importDefault(require("sharp"));
const fluent_ffmpeg_1 = __importDefault(require("fluent-ffmpeg"));
const vision_1 = __importDefault(require("@google-cloud/vision"));
const speech_1 = __importDefault(require("@google-cloud/speech"));
const uuid_1 = require("uuid");
const utils_1 = require("../shared/utils");
const visionClient = new vision_1.default.ImageAnnotatorClient();
const speechClient = new speech_1.default.SpeechClient();
// ========== 1. COMPRESS UPLOADED IMAGE (Storage Trigger) ==========
exports.compressUploadedImage = (0, storage_1.onObjectFinalized)({
    bucket: '{your-project}-user-photos',
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;
    // Only process images
    if (!(contentType === null || contentType === void 0 ? void 0 : contentType.startsWith('image/'))) {
        return;
    }
    // Skip if already compressed
    if (filePath.includes('_compressed')) {
        return;
    }
    (0, utils_1.logInfo)(`Compressing image: ${filePath}`);
    try {
        const bucket = utils_1.storage.bucket(event.bucket);
        const file = bucket.file(filePath);
        // Download image
        const [buffer] = await file.download();
        // Compress image
        const compressedBuffer = await (0, sharp_1.default)(buffer)
            .resize(1920, 1080, { fit: 'inside', withoutEnlargement: true })
            .jpeg({ quality: 85, mozjpeg: true })
            .toBuffer();
        // Check if compression achieved <2MB
        const fileSizeMB = compressedBuffer.length / (1024 * 1024);
        if (fileSizeMB > 2) {
            // Further compress
            const furtherCompressed = await (0, sharp_1.default)(buffer)
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
        }
        else {
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
        (0, utils_1.logInfo)(`Image compressed successfully: ${filePath}`);
    }
    catch (error) {
        (0, utils_1.logError)('Error compressing image:', error);
        throw error;
    }
});
exports.compressImage = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 300,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { imageUrl, maxSizeMB = 2, quality = 85 } = request.data;
        if (!imageUrl) {
            throw new https_1.HttpsError('invalid-argument', 'imageUrl is required');
        }
        (0, utils_1.logInfo)(`Manual compression requested by ${uid} for ${imageUrl}`);
        // Download image from URL
        const response = await fetch(imageUrl);
        const buffer = Buffer.from(await response.arrayBuffer());
        // Compress
        const compressed = await (0, sharp_1.default)(buffer)
            .resize(1920, 1080, { fit: 'inside', withoutEnlargement: true })
            .jpeg({ quality, mozjpeg: true })
            .toBuffer();
        const fileSizeMB = compressed.length / (1024 * 1024);
        if (fileSizeMB > maxSizeMB) {
            // Reduce quality further
            const furtherCompressed = await (0, sharp_1.default)(buffer)
                .resize(1280, 720, { fit: 'inside' })
                .jpeg({ quality: quality - 10, mozjpeg: true })
                .toBuffer();
            // Upload to storage
            const fileName = `compressed/${uid}/${(0, uuid_1.v4)()}.jpg`;
            const bucket = utils_1.storage.bucket();
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
        const fileName = `compressed/${uid}/${(0, uuid_1.v4)()}.jpg`;
        const bucket = utils_1.storage.bucket();
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
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 3. PROCESS UPLOADED VIDEO (Storage Trigger) ==========
exports.processUploadedVideo = (0, storage_1.onObjectFinalized)({
    bucket: '{your-project}-profile-media',
    memory: '2GiB',
    timeoutSeconds: 540,
}, async (event) => {
    const filePath = event.data.name;
    const contentType = event.data.contentType;
    if (!(contentType === null || contentType === void 0 ? void 0 : contentType.startsWith('video/'))) {
        return;
    }
    (0, utils_1.logInfo)(`Processing video: ${filePath}`);
    try {
        const bucket = utils_1.storage.bucket(event.bucket);
        const file = bucket.file(filePath);
        const tempFilePath = `/tmp/${(0, uuid_1.v4)()}.mp4`;
        const thumbnailPath = `/tmp/${(0, uuid_1.v4)()}.jpg`;
        // Download video
        await file.download({ destination: tempFilePath });
        // Generate thumbnail at 1 second
        await new Promise((resolve, reject) => {
            (0, fluent_ffmpeg_1.default)(tempFilePath)
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
        const metadata = await new Promise((resolve, reject) => {
            fluent_ffmpeg_1.default.ffprobe(tempFilePath, (err, metadata) => {
                if (err)
                    reject(err);
                else
                    resolve(metadata);
            });
        });
        const duration = metadata.format.duration;
        if (duration > 60) {
            (0, utils_1.logError)(`Video too long: ${duration}s (max 60s)`);
            // Mark for review
            await utils_1.db.collection('moderation_queue').add({
                type: 'video_too_long',
                filePath,
                duration,
                uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        (0, utils_1.logInfo)(`Video processed successfully: ${filePath}`);
    }
    catch (error) {
        (0, utils_1.logError)('Error processing video:', error);
        throw error;
    }
});
exports.generateVideoThumbnail = (0, https_1.onCall)({
    memory: '2GiB',
    timeoutSeconds: 540,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { videoUrl, timestampSeconds = 1 } = request.data;
        if (!videoUrl) {
            throw new https_1.HttpsError('invalid-argument', 'videoUrl is required');
        }
        (0, utils_1.logInfo)(`Generating thumbnail for ${videoUrl} at ${timestampSeconds}s`);
        const tempVideoPath = `/tmp/${(0, uuid_1.v4)()}.mp4`;
        const thumbnailPath = `/tmp/${(0, uuid_1.v4)()}.jpg`;
        // Download video
        const response = await fetch(videoUrl);
        const buffer = Buffer.from(await response.arrayBuffer());
        const fs = require('fs');
        fs.writeFileSync(tempVideoPath, buffer);
        // Generate thumbnail
        await new Promise((resolve, reject) => {
            (0, fluent_ffmpeg_1.default)(tempVideoPath)
                .screenshots({
                timestamps: [timestampSeconds],
                filename: thumbnailPath,
                size: '1280x720',
            })
                .on('end', () => resolve())
                .on('error', (err) => reject(err));
        });
        // Upload thumbnail
        const fileName = `thumbnails/${uid}/${(0, uuid_1.v4)()}.jpg`;
        const bucket = utils_1.storage.bucket();
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
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 5. TRANSCRIBE VOICE MESSAGE (Storage Trigger) ==========
exports.transcribeVoiceMessage = (0, storage_1.onObjectFinalized)({
    bucket: '{your-project}-chat-attachments',
    memory: '1GiB',
    timeoutSeconds: 300,
}, async (event) => {
    var _a, _b, _c;
    const filePath = event.data.name;
    const contentType = event.data.contentType;
    // Only process audio files
    if (!(contentType === null || contentType === void 0 ? void 0 : contentType.startsWith('audio/'))) {
        return;
    }
    (0, utils_1.logInfo)(`Transcribing audio: ${filePath}`);
    try {
        const bucket = utils_1.storage.bucket(event.bucket);
        const gcsUri = `gs://${event.bucket}/${filePath}`;
        // Extract language from metadata or default to en-US
        const [metadata] = await bucket.file(filePath).getMetadata();
        const languageCode = String(((_a = metadata.metadata) === null || _a === void 0 ? void 0 : _a.languageCode) || 'en-US');
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
        const [response] = await operation[0].promise();
        const transcription = (_b = response.results) === null || _b === void 0 ? void 0 : _b.map((result) => result.alternatives[0].transcript).join('\n');
        // Save transcription to Firestore
        const messageId = String(((_c = metadata.metadata) === null || _c === void 0 ? void 0 : _c.messageId) || '');
        if (messageId) {
            await utils_1.db.collection('messages').doc(messageId).update({
                transcription,
                transcribedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
        (0, utils_1.logInfo)(`Audio transcribed successfully: ${filePath}`);
    }
    catch (error) {
        (0, utils_1.logError)('Error transcribing audio:', error);
        throw error;
    }
});
exports.transcribeAudio = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 300,
}, async (request) => {
    var _a, _b, _c, _d, _e;
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { audioUrl, languageCode = 'en-US' } = request.data;
        if (!audioUrl) {
            throw new https_1.HttpsError('invalid-argument', 'audioUrl is required');
        }
        (0, utils_1.logInfo)(`Transcribing audio for ${uid}: ${audioUrl}`);
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
        const transcription = (_a = speechResponse.results) === null || _a === void 0 ? void 0 : _a.map((result) => result.alternatives[0].transcript).join('\n');
        return {
            success: true,
            transcription,
            confidence: ((_e = (_d = (_c = (_b = speechResponse.results) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.alternatives) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.confidence) || 0,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
exports.batchTranscribe = (0, https_1.onCall)({
    memory: '1GiB',
    timeoutSeconds: 540,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { audioUrls, languageCode = 'en-US' } = request.data;
        if (!audioUrls || audioUrls.length === 0) {
            throw new https_1.HttpsError('invalid-argument', 'audioUrls is required');
        }
        (0, utils_1.logInfo)(`Batch transcribing ${audioUrls.length} audio files for ${uid}`);
        const transcriptions = await Promise.all(audioUrls.map(async (audioUrl) => {
            var _a, _b, _c, _d, _e;
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
            const transcription = (_a = speechResponse.results) === null || _a === void 0 ? void 0 : _a.map((result) => result.alternatives[0].transcript).join('\n');
            return {
                audioUrl,
                transcription,
                confidence: ((_e = (_d = (_c = (_b = speechResponse.results) === null || _b === void 0 ? void 0 : _b[0]) === null || _c === void 0 ? void 0 : _c.alternatives) === null || _d === void 0 ? void 0 : _d[0]) === null || _e === void 0 ? void 0 : _e.confidence) || 0,
            };
        }));
        return {
            success: true,
            transcriptions,
            totalProcessed: transcriptions.length,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 8. CLEANUP DISAPPEARING MEDIA (Scheduled - Hourly) ==========
exports.cleanupDisappearingMedia = (0, scheduler_1.onSchedule)({
    schedule: '0 * * * *', // Every hour
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
}, async () => {
    (0, utils_1.logInfo)('Starting cleanup of disappearing media');
    try {
        const cutoffTime = new Date(Date.now() - 24 * 60 * 60 * 1000); // 24 hours ago
        // Query messages marked as disappearing
        const snapshot = await utils_1.db
            .collection('messages')
            .where('disappearing', '==', true)
            .where('createdAt', '<', cutoffTime)
            .get();
        (0, utils_1.logInfo)(`Found ${snapshot.size} disappearing media files to delete`);
        const batch = utils_1.db.batch();
        const filesToDelete = [];
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
                const bucket = utils_1.storage.bucket();
                const fileName = fileUrl.split('/').pop();
                if (fileName) {
                    await bucket.file(fileName).delete();
                }
            }
            catch (error) {
                (0, utils_1.logError)(`Error deleting file ${fileUrl}:`, error);
            }
        }
        // Delete from Firestore
        await batch.commit();
        (0, utils_1.logInfo)(`Cleanup completed: ${snapshot.size} items deleted`);
    }
    catch (error) {
        (0, utils_1.logError)('Error during cleanup:', error);
        throw error;
    }
});
exports.markMediaAsDisappearing = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { messageId, disappearing } = request.data;
        if (!messageId) {
            throw new https_1.HttpsError('invalid-argument', 'messageId is required');
        }
        const messageRef = utils_1.db.collection('messages').doc(messageId);
        const messageDoc = await messageRef.get();
        if (!messageDoc.exists) {
            throw new https_1.HttpsError('not-found', 'Message not found');
        }
        const messageData = messageDoc.data();
        // Verify user owns the message
        if ((messageData === null || messageData === void 0 ? void 0 : messageData.senderId) !== uid) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized');
        }
        await messageRef.update({
            disappearing,
            markedDisappearingAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            message: `Message marked as ${disappearing ? 'disappearing' : 'permanent'}`,
        };
    }
    catch (error) {
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map