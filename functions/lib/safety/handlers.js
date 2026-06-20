"use strict";
/**
 * Safety & Moderation Handlers
 * Business logic for all 11 safety functions
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
exports.handleModeratePhoto = handleModeratePhoto;
exports.handleModerateText = handleModerateText;
exports.handleDetectSpam = handleDetectSpam;
exports.handleDetectFakeProfile = handleDetectFakeProfile;
exports.handleDetectScam = handleDetectScam;
exports.handleSubmitReport = handleSubmitReport;
exports.handleReviewReport = handleReviewReport;
exports.handleSubmitAppeal = handleSubmitAppeal;
exports.handleBlockUser = handleBlockUser;
exports.handleUnblockUser = handleUnblockUser;
exports.handleGetBlockList = handleGetBlockList;
const https_1 = require("firebase-functions/v2/https");
const vision_1 = require("@google-cloud/vision");
const language_1 = require("@google-cloud/language");
const utils_1 = require("../shared/utils");
const types_1 = require("../shared/types");
const admin = __importStar(require("firebase-admin"));
const visionClient = new vision_1.ImageAnnotatorClient();
const languageClient = new language_1.LanguageServiceClient();
// ========== HELPER FUNCTIONS ==========
function getLikelihoodScore(likelihood) {
    const scores = {
        VERY_UNLIKELY: 1,
        UNLIKELY: 2,
        POSSIBLE: 3,
        LIKELY: 4,
        VERY_LIKELY: 5,
    };
    return scores[likelihood || 'VERY_UNLIKELY'] || 1;
}
async function handleModeratePhoto(params) {
    const { photoUrl, userId, requestingUid, context = 'profile' } = params;
    if (!photoUrl) {
        throw new https_1.HttpsError('invalid-argument', 'photoUrl is required');
    }
    (0, utils_1.logInfo)(`Moderating photo for user ${userId}: ${photoUrl}`);
    // Verify user owns the photo or is admin (caller should verify admin if needed)
    if (requestingUid !== userId) {
        // Admin verification should be done by caller
        (0, utils_1.logInfo)(`Admin ${requestingUid} moderating photo for user ${userId}`);
    }
    // Use Cloud Vision API for safe search detection
    const [result] = await visionClient.safeSearchDetection(photoUrl);
    const safeSearch = result.safeSearchAnnotation;
    const scores = {
        adult: getLikelihoodScore(safeSearch.adult),
        violence: getLikelihoodScore(safeSearch.violence),
        racy: getLikelihoodScore(safeSearch.racy),
        medical: getLikelihoodScore(safeSearch.medical),
    };
    // Determine if photo should be flagged
    const flagged = scores.adult >= 4 || scores.violence >= 4;
    const categories = [];
    if (scores.adult >= 4)
        categories.push(types_1.ModerationCategory.ADULT);
    if (scores.violence >= 4)
        categories.push(types_1.ModerationCategory.VIOLENCE);
    // Determine action
    let action;
    if (flagged) {
        action = scores.adult >= 5 || scores.violence >= 5
            ? types_1.ModerationAction.AUTO_REJECTED
            : types_1.ModerationAction.PENDING_REVIEW;
    }
    else {
        action = types_1.ModerationAction.AUTO_APPROVED;
    }
    // Save moderation result
    const moderationRef = await utils_1.db.collection('moderation_results').add({
        targetType: 'photo',
        targetId: photoUrl,
        userId,
        context,
        flagged,
        categories,
        scores,
        action,
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    // If auto-rejected, remove photo
    if (action === types_1.ModerationAction.AUTO_REJECTED) {
        (0, utils_1.logInfo)(`Photo auto-rejected: ${photoUrl}`);
    }
    // If pending review, add to moderation queue
    if (action === types_1.ModerationAction.PENDING_REVIEW) {
        await utils_1.db.collection('moderation_queue').add({
            type: 'photo',
            targetId: photoUrl,
            userId,
            moderationId: moderationRef.id,
            priority: 'high',
            status: 'pending',
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
    }
    return {
        success: true,
        moderationId: moderationRef.id,
        flagged,
        action,
        categories,
        scores,
    };
}
async function handleModerateText(params) {
    var _a;
    const { text, userId, requestingUid, context = 'message' } = params;
    if (!text) {
        throw new https_1.HttpsError('invalid-argument', 'text is required');
    }
    if (requestingUid !== userId) {
        (0, utils_1.logInfo)(`Admin ${requestingUid} moderating text for user ${userId}`);
    }
    (0, utils_1.logInfo)(`Moderating text for user ${userId}`);
    // Check for profanity (simple keyword filter)
    const profanityPatterns = [
        /\b(fuck|shit|damn|ass|bitch|cunt|dick)/gi,
        /\b(sex|nude|porn|xxx)/gi,
    ];
    let hasProfanity = false;
    let toxicityScore = 0;
    for (const pattern of profanityPatterns) {
        if (pattern.test(text)) {
            hasProfanity = true;
            toxicityScore += 0.3;
        }
    }
    // Use Cloud Natural Language API for sentiment/toxicity
    try {
        const document = {
            content: text,
            type: 'PLAIN_TEXT',
        };
        const [sentiment] = await languageClient.analyzeSentiment({ document });
        const sentimentScore = ((_a = sentiment.documentSentiment) === null || _a === void 0 ? void 0 : _a.score) || 0;
        // Negative sentiment might indicate toxic content
        if (sentimentScore < -0.5) {
            toxicityScore += 0.2;
        }
    }
    catch (error) {
        (0, utils_1.logError)('Error analyzing sentiment:', error);
    }
    const flagged = hasProfanity || toxicityScore > 0.5;
    const categories = [];
    if (hasProfanity)
        categories.push(types_1.ModerationCategory.HATE_SPEECH);
    if (toxicityScore > 0.7)
        categories.push(types_1.ModerationCategory.SPAM);
    const action = flagged
        ? toxicityScore > 0.8
            ? types_1.ModerationAction.AUTO_REJECTED
            : types_1.ModerationAction.PENDING_REVIEW
        : types_1.ModerationAction.AUTO_APPROVED;
    const moderationRef = await utils_1.db.collection('moderation_results').add({
        targetType: 'text',
        targetId: text.substring(0, 100),
        userId,
        context,
        flagged,
        categories,
        scores: { toxicity: toxicityScore, profanity: hasProfanity ? 1 : 0 },
        action,
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    if (action === types_1.ModerationAction.PENDING_REVIEW) {
        await utils_1.db.collection('moderation_queue').add({
            type: 'text',
            targetId: moderationRef.id,
            userId,
            moderationId: moderationRef.id,
            content: text,
            priority: 'medium',
            status: 'pending',
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
    }
    return {
        success: true,
        moderationId: moderationRef.id,
        flagged,
        action,
        categories,
        toxicityScore,
    };
}
async function handleDetectSpam(params) {
    const { content, userId, type } = params;
    if (!content) {
        throw new https_1.HttpsError('invalid-argument', 'content is required');
    }
    (0, utils_1.logInfo)(`Detecting spam for user ${userId}`);
    let spamScore = 0;
    const indicators = [];
    // Check for excessive links
    const linkPattern = /(https?:\/\/|www\.)/gi;
    const linkMatches = content.match(linkPattern);
    if (linkMatches && linkMatches.length > 2) {
        spamScore += 0.4;
        indicators.push('excessive_links');
    }
    // Check for promotional keywords
    const promoKeywords = [
        'buy now', 'click here', 'limited offer', 'act now', 'visit my',
        'check out my', 'follow me', 'subscribe', 'cashapp', 'venmo', 'paypal',
    ];
    for (const keyword of promoKeywords) {
        if (content.toLowerCase().includes(keyword)) {
            spamScore += 0.2;
            indicators.push(`promo_keyword_${keyword.replace(' ', '_')}`);
        }
    }
    // Check for repetitive characters
    if (/(.)\1{4,}/.test(content)) {
        spamScore += 0.2;
        indicators.push('repetitive_characters');
    }
    // Check for ALL CAPS
    const capsRatio = (content.match(/[A-Z]/g) || []).length / content.length;
    if (capsRatio > 0.7 && content.length > 20) {
        spamScore += 0.3;
        indicators.push('excessive_caps');
    }
    const isSpam = spamScore >= 0.5;
    await utils_1.db.collection('spam_detections').add({
        userId,
        content: content.substring(0, 200),
        type,
        isSpam,
        spamScore,
        indicators,
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    if (isSpam) {
        await utils_1.db.collection('moderation_queue').add({
            type: 'spam',
            userId,
            content: content.substring(0, 200),
            spamScore,
            indicators,
            priority: 'medium',
            status: 'pending',
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
    }
    return {
        success: true,
        isSpam,
        spamScore,
        indicators,
    };
}
async function handleDetectFakeProfile(params) {
    const { userId } = params;
    if (!userId) {
        throw new https_1.HttpsError('invalid-argument', 'userId is required');
    }
    (0, utils_1.logInfo)(`Detecting fake profile for user ${userId}`);
    const userDoc = await utils_1.db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
        throw new https_1.HttpsError('not-found', 'User not found');
    }
    const userData = userDoc.data();
    let suspicionScore = 0;
    const indicators = [];
    // Check profile completeness
    if (!userData.bio || userData.bio.length < 20) {
        suspicionScore += 0.2;
        indicators.push('incomplete_bio');
    }
    if (!userData.photos || userData.photos.length < 2) {
        suspicionScore += 0.3;
        indicators.push('few_photos');
    }
    // Check account age
    const accountAgeDays = (Date.now() - userData.createdAt.toMillis()) / (24 * 60 * 60 * 1000);
    if (accountAgeDays < 1) {
        suspicionScore += 0.2;
        indicators.push('new_account');
    }
    // Check activity patterns
    const messagesSnapshot = await utils_1.db
        .collection('messages')
        .where('senderId', '==', userId)
        .limit(10)
        .get();
    if (accountAgeDays > 7 && messagesSnapshot.size === 0) {
        suspicionScore += 0.2;
        indicators.push('no_activity');
    }
    const isFake = suspicionScore >= 0.6;
    await utils_1.db.collection('fake_profile_detections').add({
        userId,
        isFake,
        suspicionScore,
        indicators,
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    if (isFake) {
        await utils_1.db.collection('moderation_queue').add({
            type: 'fake_profile',
            userId,
            suspicionScore,
            indicators,
            priority: 'high',
            status: 'pending',
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
    }
    return {
        success: true,
        isFake,
        suspicionScore,
        indicators,
    };
}
async function handleDetectScam(params) {
    const { conversationId, messageContent } = params;
    if (!messageContent) {
        throw new https_1.HttpsError('invalid-argument', 'messageContent is required');
    }
    (0, utils_1.logInfo)(`Detecting scam in conversation ${conversationId}`);
    let scamScore = 0;
    const indicators = [];
    // Money request patterns
    const moneyPatterns = [
        /send\s+(me\s+)?money/i,
        /need\s+\$\d+/i,
        /emergency.*help/i,
        /stuck.*need.*cash/i,
        /wire.*transfer/i,
        /western\s+union/i,
        /gift\s+card/i,
    ];
    for (const pattern of moneyPatterns) {
        if (pattern.test(messageContent)) {
            scamScore += 0.4;
            indicators.push('money_request');
            break;
        }
    }
    // Urgency language
    const urgencyPatterns = [
        /urgent/i,
        /asap/i,
        /right\s+now/i,
        /immediately/i,
        /emergency/i,
    ];
    for (const pattern of urgencyPatterns) {
        if (pattern.test(messageContent)) {
            scamScore += 0.2;
            indicators.push('urgency_language');
            break;
        }
    }
    // External communication requests
    const externalPatterns = [
        /text\s+me\s+at/i,
        /call\s+me\s+at/i,
        /whatsapp/i,
        /telegram/i,
        /kik/i,
    ];
    for (const pattern of externalPatterns) {
        if (pattern.test(messageContent)) {
            scamScore += 0.3;
            indicators.push('external_communication');
            break;
        }
    }
    const isScam = scamScore >= 0.5;
    await utils_1.db.collection('scam_detections').add({
        conversationId,
        content: messageContent.substring(0, 200),
        isScam,
        scamScore,
        indicators,
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    if (isScam) {
        await utils_1.db.collection('moderation_queue').add({
            type: 'scam',
            conversationId,
            content: messageContent.substring(0, 200),
            scamScore,
            indicators,
            priority: 'critical',
            status: 'pending',
            createdAt: utils_1.FieldValue.serverTimestamp(),
        });
    }
    return {
        success: true,
        isScam,
        scamScore,
        indicators,
    };
}
async function handleSubmitReport(params) {
    const { reporterId, reportedUserId, reason, description, reportedContentId } = params;
    if (!reportedUserId || !reason || !description) {
        throw new https_1.HttpsError('invalid-argument', 'reportedUserId, reason, and description are required');
    }
    (0, utils_1.logInfo)(`User ${reporterId} reporting user ${reportedUserId} for ${reason}`);
    const reportRef = await utils_1.db.collection('reports').add({
        reporterId,
        reportedUserId,
        reportedContentId,
        reason,
        description,
        status: types_1.ReportStatus.PENDING,
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    // Add to moderation queue
    await utils_1.db.collection('moderation_queue').add({
        type: 'user_report',
        reportId: reportRef.id,
        reportedUserId,
        reason,
        priority: reason === types_1.ReportReason.SCAM || reason === types_1.ReportReason.UNDERAGE ? 'critical' : 'high',
        status: 'pending',
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        reportId: reportRef.id,
        message: 'Report submitted successfully',
    };
}
async function handleReviewReport(params) {
    const { adminUid, reportId, action, notes } = params;
    if (!reportId || !action) {
        throw new https_1.HttpsError('invalid-argument', 'reportId and action are required');
    }
    (0, utils_1.logInfo)(`Admin ${adminUid} reviewing report ${reportId} with action ${action}`);
    const reportDoc = await utils_1.db.collection('reports').doc(reportId).get();
    if (!reportDoc.exists) {
        throw new https_1.HttpsError('not-found', 'Report not found');
    }
    const reportData = reportDoc.data();
    // Update report
    await reportDoc.ref.update({
        status: types_1.ReportStatus.RESOLVED,
        action,
        reviewedBy: adminUid,
        reviewedAt: utils_1.FieldValue.serverTimestamp(),
        notes,
    });
    // Take action on reported user
    const userRef = utils_1.db.collection('users').doc(reportData.reportedUserId);
    switch (action) {
        case 'warn':
            await userRef.update({
                warnings: utils_1.FieldValue.increment(1),
                lastWarningAt: utils_1.FieldValue.serverTimestamp(),
            });
            break;
        case 'suspend':
            await userRef.update({
                suspended: true,
                suspendedAt: utils_1.FieldValue.serverTimestamp(),
                suspendedUntil: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
                ),
                suspensionReason: reportData.reason,
            });
            break;
        case 'ban':
            await userRef.update({
                banned: true,
                bannedAt: utils_1.FieldValue.serverTimestamp(),
                banReason: reportData.reason,
            });
            // Disable auth account
            await admin.auth().updateUser(reportData.reportedUserId, { disabled: true });
            break;
        case 'dismiss':
            // No action on user
            break;
    }
    // Log admin action
    await utils_1.db.collection('admin_audit_log').add({
        adminUid,
        action: 'review_report',
        targetUserId: reportData.reportedUserId,
        reportId,
        moderationAction: action,
        timestamp: utils_1.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        message: `Report ${action}ed successfully`,
    };
}
async function handleSubmitAppeal(params) {
    const { userId, reportId, suspensionId, appealText } = params;
    if (!appealText) {
        throw new https_1.HttpsError('invalid-argument', 'appealText is required');
    }
    (0, utils_1.logInfo)(`User ${userId} submitting appeal`);
    const appealRef = await utils_1.db.collection('appeals').add({
        userId,
        reportId,
        suspensionId,
        appealText,
        status: 'pending',
        createdAt: utils_1.FieldValue.serverTimestamp(),
    });
    return {
        success: true,
        appealId: appealRef.id,
        message: 'Appeal submitted for review',
    };
}
async function handleBlockUser(params) {
    const { userId, blockedUserId } = params;
    if (!blockedUserId) {
        throw new https_1.HttpsError('invalid-argument', 'blockedUserId is required');
    }
    (0, utils_1.logInfo)(`User ${userId} blocking user ${blockedUserId}`);
    const userRef = utils_1.db.collection('users').doc(userId);
    await userRef.update({
        blockedUsers: utils_1.FieldValue.arrayUnion(blockedUserId),
    });
    return {
        success: true,
        message: 'User blocked successfully',
    };
}
async function handleUnblockUser(params) {
    const { userId, blockedUserId } = params;
    if (!blockedUserId) {
        throw new https_1.HttpsError('invalid-argument', 'blockedUserId is required');
    }
    const userRef = utils_1.db.collection('users').doc(userId);
    await userRef.update({
        blockedUsers: utils_1.FieldValue.arrayRemove(blockedUserId),
    });
    return {
        success: true,
        message: 'User unblocked successfully',
    };
}
async function handleGetBlockList(params) {
    const { userId } = params;
    const userDoc = await utils_1.db.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const blockedUsers = (userData === null || userData === void 0 ? void 0 : userData.blockedUsers) || [];
    return {
        success: true,
        blockedUsers,
        total: blockedUsers.length,
    };
}
//# sourceMappingURL=handlers.js.map