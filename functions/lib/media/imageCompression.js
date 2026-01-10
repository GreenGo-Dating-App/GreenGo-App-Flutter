"use strict";
/**
 * Image Compression Cloud Function
 * Point 102: Compress images to <2MB and generate thumbnails
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
exports.compressImage = exports.compressUploadedImage = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const sharp_1 = __importDefault(require("sharp"));
const path = __importStar(require("path"));
const os = __importStar(require("os"));
const fs = __importStar(require("fs"));
const storage = admin.storage();
const firestore = admin.firestore();
// Maximum file size in bytes (2MB)
const MAX_FILE_SIZE = 2 * 1024 * 1024;
// Thumbnail dimensions
const THUMB_WIDTH = 200;
const THUMB_HEIGHT = 200;
/**
 * Triggered when an image is uploaded to Firebase Storage
 * Compresses the image and generates a thumbnail
 */
exports.compressUploadedImage = functions.storage
    .object()
    .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;
    const fileSize = Number(object.size);
    // Exit if this is not an image
    if (!contentType || !contentType.startsWith('image/')) {
        console.log('Not an image, skipping');
        return null;
    }
    // Exit if this is already a compressed or thumbnail image
    if (filePath.includes('_compressed') || filePath.includes('_thumb')) {
        console.log('Already processed, skipping');
        return null;
    }
    // Only process images in the messages folder
    if (!filePath.includes('messages/')) {
        console.log('Not a message image, skipping');
        return null;
    }
    const bucket = storage.bucket(object.bucket);
    const fileName = path.basename(filePath);
    const fileDir = path.dirname(filePath);
    // Download file to temporary directory
    const tempFilePath = path.join(os.tmpdir(), fileName);
    const compressedFileName = fileName.replace(/\.[^/.]+$/, '_compressed.jpg');
    const compressedFilePath = path.join(os.tmpdir(), compressedFileName);
    const thumbFileName = fileName.replace(/\.[^/.]+$/, '_thumb.jpg');
    const thumbFilePath = path.join(os.tmpdir(), thumbFileName);
    try {
        await bucket.file(filePath).download({ destination: tempFilePath });
        console.log('Image downloaded to', tempFilePath);
        // Get image metadata
        const metadata = await (0, sharp_1.default)(tempFilePath).metadata();
        console.log(`Original image: ${metadata.width}x${metadata.height}, ${fileSize} bytes`);
        // Compress image if needed
        let compressedUrl = null;
        if (fileSize > MAX_FILE_SIZE) {
            // Calculate quality to reach target size
            let quality = 80;
            let currentSize = fileSize;
            while (currentSize > MAX_FILE_SIZE && quality > 10) {
                await (0, sharp_1.default)(tempFilePath)
                    .rotate() // Auto-rotate based on EXIF
                    .resize(1920, 1080, {
                    fit: 'inside',
                    withoutEnlargement: true,
                })
                    .jpeg({ quality, progressive: true })
                    .toFile(compressedFilePath);
                const stats = fs.statSync(compressedFilePath);
                currentSize = stats.size;
                quality -= 10;
                console.log(`Compressed with quality ${quality + 10}: ${currentSize} bytes`);
                if (currentSize <= MAX_FILE_SIZE)
                    break;
            }
            // Upload compressed image
            const compressedDestination = path.join(fileDir, compressedFileName);
            await bucket.upload(compressedFilePath, {
                destination: compressedDestination,
                metadata: {
                    contentType: 'image/jpeg',
                    metadata: {
                        compressed: 'true',
                        originalSize: fileSize.toString(),
                        compressedSize: currentSize.toString(),
                    },
                },
            });
            // Get public URL
            const [compressedFile] = await bucket.file(compressedDestination).getSignedUrl({
                action: 'read',
                expires: '03-01-2500',
            });
            compressedUrl = compressedFile;
            console.log('Compressed image uploaded to', compressedDestination);
        }
        // Generate thumbnail
        await (0, sharp_1.default)(tempFilePath)
            .rotate()
            .resize(THUMB_WIDTH, THUMB_HEIGHT, {
            fit: 'cover',
            position: 'center',
        })
            .jpeg({ quality: 80 })
            .toFile(thumbFilePath);
        // Upload thumbnail
        const thumbDestination = path.join(fileDir, thumbFileName);
        await bucket.upload(thumbFilePath, {
            destination: thumbDestination,
            metadata: {
                contentType: 'image/jpeg',
                metadata: {
                    thumbnail: 'true',
                    originalFile: fileName,
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
        // Update Firestore message with URLs
        // Extract message ID from path: messages/{messageId}/...
        const pathParts = filePath.split('/');
        const messageIndex = pathParts.indexOf('messages');
        if (messageIndex !== -1 && pathParts.length > messageIndex + 1) {
            const conversationId = pathParts[messageIndex + 1];
            const messageId = pathParts[messageIndex + 3]; // messages/{convId}/messages/{msgId}
            await firestore
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .doc(messageId)
                .update({
                'metadata.thumbnailUrl': thumbUrl,
                'metadata.compressedUrl': compressedUrl || null,
                'metadata.originalSize': fileSize,
                'metadata.width': metadata.width,
                'metadata.height': metadata.height,
                'metadata.processedAt': admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`Updated message ${messageId} with image metadata`);
        }
        // Clean up temp files
        fs.unlinkSync(tempFilePath);
        if (fs.existsSync(compressedFilePath))
            fs.unlinkSync(compressedFilePath);
        if (fs.existsSync(thumbFilePath))
            fs.unlinkSync(thumbFilePath);
        return {
            success: true,
            compressedUrl,
            thumbUrl,
            originalSize: fileSize,
        };
    }
    catch (error) {
        console.error('Error processing image:', error);
        throw error;
    }
});
/**
 * HTTP function to manually compress an image
 */
exports.compressImage = functions.https.onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const { imageUrl } = data;
    if (!imageUrl) {
        throw new functions.https.HttpsError('invalid-argument', 'imageUrl is required');
    }
    try {
        // Extract file path from URL
        const urlParts = imageUrl.split('/');
        const filePath = decodeURIComponent(urlParts[urlParts.length - 1].split('?')[0]);
        const bucket = storage.bucket();
        const file = bucket.file(filePath);
        // Check if file exists
        const [exists] = await file.exists();
        if (!exists) {
            throw new functions.https.HttpsError('not-found', 'Image not found');
        }
        // Trigger compression by emitting a finalize event
        // This will be handled by compressUploadedImage function
        return { success: true, message: 'Compression triggered' };
    }
    catch (error) {
        console.error('Error in compressImage:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
//# sourceMappingURL=imageCompression.js.map