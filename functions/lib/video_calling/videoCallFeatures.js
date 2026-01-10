"use strict";
/**
 * Video Call Features Cloud Functions
 * Points 131-140: Virtual backgrounds, AR filters, screen sharing, etc.
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
exports.cleanupExpiredReactions = exports.getCallStatistics = exports.getCallHistory = exports.uploadCustomBackground = exports.sendInCallReaction = exports.toggleEchoCancellation = exports.toggleNoiseSuppression = exports.stopScreenSharing = exports.startScreenSharing = exports.enablePictureInPicture = exports.toggleBeautyMode = exports.applyARFilter = exports.enableVirtualBackground = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const firestore = admin.firestore();
const storage = admin.storage();
/**
 * Enable Virtual Background
 * Point 132: ML Kit image segmentation
 */
exports.enableVirtualBackground = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, backgroundType, customImageUrl } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Validate background type (Point 132)
        const validTypes = ['blur', 'office', 'livingRoom', 'nature', 'abstract', 'custom'];
        if (!validTypes.includes(backgroundType)) {
            throw new Error('Invalid background type');
        }
        if (backgroundType === 'custom' && !customImageUrl) {
            throw new Error('Custom background requires image URL');
        }
        // Update call features
        await callRef.update({
            'features.virtualBackgroundEnabled': true,
            'features.virtualBackgroundType': backgroundType,
            'features.customBackgroundUrl': customImageUrl || null,
        });
        console.log(`Virtual background enabled for call ${callId}: ${backgroundType}`);
        return { success: true, backgroundType };
    }
    catch (error) {
        console.error('Error enabling virtual background:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Apply AR Filter
 * Point 133: Face filters (beauty mode, face effects)
 */
exports.applyARFilter = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, filterType, intensity } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Check if user has premium subscription (Point 133: Premium feature)
        const userDoc = await firestore.collection('users').doc(userId).get();
        const userData = userDoc.data();
        if (userData.subscriptionTier === 'free') {
            throw new Error('AR filters require a premium subscription');
        }
        // Validate filter type
        const validFilters = ['none', 'beauty', 'cat', 'dog', 'bunny', 'crown', 'glasses'];
        if (!validFilters.includes(filterType)) {
            throw new Error('Invalid filter type');
        }
        // Validate intensity (0.0 - 1.0)
        const filterIntensity = Math.max(0, Math.min(1, intensity || 0.5));
        // Update call features
        await callRef.update({
            'features.arFiltersEnabled': filterType !== 'none',
            'features.currentARFilter': filterType,
            'features.arFilterIntensity': filterIntensity,
        });
        console.log(`AR filter applied for call ${callId}: ${filterType}`);
        return { success: true, filterType, intensity: filterIntensity };
    }
    catch (error) {
        console.error('Error applying AR filter:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Toggle Beauty Mode
 * Point 133: Skin smoothing and enhancement
 */
exports.toggleBeautyMode = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, enabled, settings } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Default beauty settings (Point 133)
        const beautySettings = {
            smoothing: (settings === null || settings === void 0 ? void 0 : settings.smoothing) || 0.5,
            brightening: (settings === null || settings === void 0 ? void 0 : settings.brightening) || 0.3,
            eyeEnhancement: (settings === null || settings === void 0 ? void 0 : settings.eyeEnhancement) || 0.4,
            faceSlimming: (settings === null || settings === void 0 ? void 0 : settings.faceSlimming) || 0.2,
        };
        // Update call features
        await callRef.update({
            'features.beautyModeEnabled': enabled,
            'features.beautySettings': beautySettings,
        });
        console.log(`Beauty mode ${enabled ? 'enabled' : 'disabled'} for call ${callId}`);
        return { success: true, enabled, settings: beautySettings };
    }
    catch (error) {
        console.error('Error toggling beauty mode:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Enable Picture-in-Picture Mode
 * Point 134: PiP for multitasking
 */
exports.enablePictureInPicture = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, enabled } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Update call features
        await callRef.update({
            'features.pictureInPictureEnabled': enabled,
        });
        console.log(`Picture-in-Picture ${enabled ? 'enabled' : 'disabled'} for call ${callId}`);
        return { success: true, enabled };
    }
    catch (error) {
        console.error('Error enabling picture-in-picture:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Start Screen Sharing
 * Point 135: Premium screen sharing
 */
exports.startScreenSharing = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Check if user has premium subscription (Point 135)
        const userDoc = await firestore.collection('users').doc(userId).get();
        const userData = userDoc.data();
        if (userData.subscriptionTier === 'free') {
            throw new Error('Screen sharing requires a premium subscription');
        }
        // Check if someone is already sharing
        if (((_a = callData.features) === null || _a === void 0 ? void 0 : _a.screenSharingUserId) && callData.features.screenSharingUserId !== userId) {
            throw new Error('Another participant is already sharing their screen');
        }
        // Update call features
        await callRef.update({
            'features.screenSharingEnabled': true,
            'features.screenSharingUserId': userId,
            'features.screenSharingStartedAt': admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Screen sharing started by ${userId} for call ${callId}`);
        return { success: true };
    }
    catch (error) {
        console.error('Error starting screen sharing:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Stop Screen Sharing
 * Point 135: End screen sharing
 */
exports.stopScreenSharing = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (((_a = callData.features) === null || _a === void 0 ? void 0 : _a.screenSharingUserId) !== userId) {
            throw new Error('You are not currently sharing your screen');
        }
        // Update call features
        await callRef.update({
            'features.screenSharingEnabled': false,
            'features.screenSharingUserId': null,
            'features.screenSharingStartedAt': null,
        });
        console.log(`Screen sharing stopped for call ${callId}`);
        return { success: true };
    }
    catch (error) {
        console.error('Error stopping screen sharing:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Toggle Noise Suppression
 * Point 136: AI noise cancellation
 */
exports.toggleNoiseSuppression = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, enabled } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Update call features (Point 136)
        await callRef.update({
            'features.noiseSuppression': enabled,
        });
        console.log(`Noise suppression ${enabled ? 'enabled' : 'disabled'} for call ${callId}`);
        return { success: true, enabled };
    }
    catch (error) {
        console.error('Error toggling noise suppression:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Toggle Echo Cancellation
 * Point 136: Echo cancellation
 */
exports.toggleEchoCancellation = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, enabled } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Update call features
        await callRef.update({
            'features.echoCancellation': enabled,
        });
        console.log(`Echo cancellation ${enabled ? 'enabled' : 'disabled'} for call ${callId}`);
        return { success: true, enabled };
    }
    catch (error) {
        console.error('Error toggling echo cancellation:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Send In-Call Reaction
 * Point 137: Emoji reactions during calls
 */
exports.sendInCallReaction = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { callId, emoji } = data;
    try {
        const callRef = firestore.collection('video_calls').doc(callId);
        const callDoc = await callRef.get();
        if (!callDoc.exists) {
            throw new Error('Call not found');
        }
        const callData = callDoc.data();
        if (callData.callerId !== userId && callData.receiverId !== userId) {
            throw new Error('Unauthorized');
        }
        // Valid reaction emojis (Point 137)
        const validEmojis = ['❤️', '😂', '👍', '👎', '🎉', '😮', '👏', '🔥'];
        if (!validEmojis.includes(emoji)) {
            throw new Error('Invalid emoji reaction');
        }
        // Create reaction document
        const reactionRef = firestore.collection('video_calls').doc(callId)
            .collection('reactions').doc();
        await reactionRef.set({
            reactionId: reactionRef.id,
            userId,
            emoji,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 3000), // 3 seconds
        });
        console.log(`Reaction sent in call ${callId}: ${emoji}`);
        return { success: true, emoji };
    }
    catch (error) {
        console.error('Error sending in-call reaction:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Upload Custom Virtual Background
 * Point 132: Custom background images
 */
exports.uploadCustomBackground = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { imageData, fileName } = data;
    try {
        // Check if user has premium subscription
        const userDoc = await firestore.collection('users').doc(userId).get();
        const userData = userDoc.data();
        if (userData.subscriptionTier === 'free') {
            throw new Error('Custom backgrounds require a premium subscription');
        }
        // Validate image size (max 5MB)
        const maxSize = 5 * 1024 * 1024;
        const imageSize = Buffer.from(imageData, 'base64').length;
        if (imageSize > maxSize) {
            throw new Error('Image size exceeds 5MB limit');
        }
        // Upload to Cloud Storage
        const bucket = storage.bucket();
        const file = bucket.file(`virtual_backgrounds/${userId}/${fileName}`);
        await file.save(Buffer.from(imageData, 'base64'), {
            metadata: {
                contentType: 'image/jpeg',
                metadata: {
                    userId,
                    uploadedAt: new Date().toISOString(),
                },
            },
        });
        // Make file publicly accessible
        await file.makePublic();
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;
        // Save background reference in Firestore
        const backgroundRef = firestore.collection('users').doc(userId)
            .collection('virtual_backgrounds').doc();
        await backgroundRef.set({
            backgroundId: backgroundRef.id,
            fileName,
            url: publicUrl,
            uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Custom background uploaded: ${backgroundRef.id}`);
        return {
            success: true,
            backgroundId: backgroundRef.id,
            url: publicUrl,
        };
    }
    catch (error) {
        console.error('Error uploading custom background:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get Call History
 * Point 128: Retrieve user's call history
 */
exports.getCallHistory = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    const { limit, offset } = data;
    try {
        const historyLimit = Math.min(limit || 20, 100);
        const historyOffset = offset || 0;
        const historySnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('call_history')
            .orderBy('endedAt', 'desc')
            .limit(historyLimit)
            .offset(historyOffset)
            .get();
        const history = historySnapshot.docs.map(doc => (Object.assign({ callId: doc.id }, doc.data())));
        return { success: true, history };
    }
    catch (error) {
        console.error('Error getting call history:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Get Call Statistics
 * Point 130: User call statistics dashboard
 */
exports.getCallStatistics = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    const userId = context.auth.uid;
    try {
        const statsDoc = await firestore
            .collection('users')
            .doc(userId)
            .collection('statistics')
            .doc('calls')
            .get();
        if (!statsDoc.exists) {
            return {
                success: true,
                statistics: {
                    totalCalls: 0,
                    successfulCalls: 0,
                    missedCalls: 0,
                    totalDuration: 0,
                    averageDuration: 0,
                    callsByType: { audio: 0, video: 0 },
                },
            };
        }
        return {
            success: true,
            statistics: statsDoc.data(),
        };
    }
    catch (error) {
        console.error('Error getting call statistics:', error);
        throw new functions.https.HttpsError('internal', error.message);
    }
});
/**
 * Cleanup Expired Call Reactions
 * Scheduled function to remove old reactions
 */
exports.cleanupExpiredReactions = functions.pubsub
    .schedule('every 5 minutes')
    .onRun(async (context) => {
    try {
        const now = admin.firestore.Timestamp.now();
        // Get all active calls
        const activeCallsSnapshot = await firestore
            .collection('video_calls')
            .where('status', '==', 'active')
            .get();
        for (const callDoc of activeCallsSnapshot.docs) {
            const reactionsSnapshot = await callDoc.ref
                .collection('reactions')
                .where('expiresAt', '<=', now)
                .get();
            // Delete expired reactions
            const batch = firestore.batch();
            reactionsSnapshot.docs.forEach(doc => {
                batch.delete(doc.ref);
            });
            if (reactionsSnapshot.size > 0) {
                await batch.commit();
            }
        }
        console.log('Expired reactions cleaned up');
    }
    catch (error) {
        console.error('Error cleaning up expired reactions:', error);
    }
});
//# sourceMappingURL=videoCallFeatures.js.map