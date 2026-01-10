"use strict";
/**
 * Safety & Moderation Service
 * 11 Cloud Functions for content moderation, reporting, and user safety
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getBlockList = exports.unblockUser = exports.blockUser = exports.submitAppeal = exports.reviewReport = exports.submitReport = exports.detectScam = exports.detectFakeProfile = exports.detectSpam = exports.moderateText = exports.moderatePhoto = void 0;
const https_1 = require("firebase-functions/v2/https");
const utils_1 = require("../shared/utils");
const handlers_1 = require("./handlers");
exports.moderatePhoto = (0, https_1.onCall)({
    memory: '512MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { photoUrl, userId, context } = request.data;
        // Verify user owns the photo or is admin
        if (uid !== userId) {
            await (0, utils_1.verifyAdminAuth)(request.auth);
        }
        return await (0, handlers_1.handleModeratePhoto)({
            photoUrl,
            userId,
            requestingUid: uid,
            context,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error moderating photo:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.moderateText = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { text, userId, context } = request.data;
        // Verify user owns the content or is admin
        if (uid !== userId) {
            await (0, utils_1.verifyAdminAuth)(request.auth);
        }
        return await (0, handlers_1.handleModerateText)({
            text,
            userId,
            requestingUid: uid,
            context,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error moderating text:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.detectSpam = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        await (0, utils_1.verifyAuth)(request.auth);
        const { content, userId, type } = request.data;
        return await (0, handlers_1.handleDetectSpam)({
            content,
            userId,
            type,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error detecting spam:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.detectFakeProfile = (0, https_1.onCall)({
    memory: '256MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        await (0, utils_1.verifyAdminAuth)(request.auth);
        const { userId } = request.data;
        return await (0, handlers_1.handleDetectFakeProfile)({ userId });
    }
    catch (error) {
        (0, utils_1.logError)('Error detecting fake profile:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.detectScam = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        await (0, utils_1.verifyAuth)(request.auth);
        const { conversationId, messageContent } = request.data;
        return await (0, handlers_1.handleDetectScam)({
            conversationId,
            messageContent,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error detecting scam:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.submitReport = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { reportedUserId, reason, description, reportedContentId } = request.data;
        return await (0, handlers_1.handleSubmitReport)({
            reporterId: uid,
            reportedUserId,
            reason,
            description,
            reportedContentId,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error submitting report:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.reviewReport = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 60,
}, async (request) => {
    try {
        const adminUid = await (0, utils_1.verifyAdminAuth)(request.auth);
        const { reportId, action, notes } = request.data;
        return await (0, handlers_1.handleReviewReport)({
            adminUid,
            reportId,
            action,
            notes,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error reviewing report:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.submitAppeal = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { reportId, suspensionId, appealText } = request.data;
        return await (0, handlers_1.handleSubmitAppeal)({
            userId: uid,
            reportId,
            suspensionId,
            appealText,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error submitting appeal:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.blockUser = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { blockedUserId } = request.data;
        return await (0, handlers_1.handleBlockUser)({
            userId: uid,
            blockedUserId,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error blocking user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
exports.unblockUser = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        const { blockedUserId } = request.data;
        return await (0, handlers_1.handleUnblockUser)({
            userId: uid,
            blockedUserId,
        });
    }
    catch (error) {
        (0, utils_1.logError)('Error unblocking user:', error);
        throw (0, utils_1.handleError)(error);
    }
});
// ========== 11. GET BLOCK LIST (HTTP Callable) ==========
exports.getBlockList = (0, https_1.onCall)({
    memory: '128MiB',
    timeoutSeconds: 30,
}, async (request) => {
    try {
        const uid = await (0, utils_1.verifyAuth)(request.auth);
        return await (0, handlers_1.handleGetBlockList)({ userId: uid });
    }
    catch (error) {
        (0, utils_1.logError)('Error getting block list:', error);
        throw (0, utils_1.handleError)(error);
    }
});
//# sourceMappingURL=index.js.map