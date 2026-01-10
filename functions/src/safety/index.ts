/**
 * Safety & Moderation Service
 * 11 Cloud Functions for content moderation, reporting, and user safety
 */

import { onCall } from 'firebase-functions/v2/https';
import { verifyAuth, verifyAdminAuth, handleError, logError } from '../shared/utils';
import { ReportReason } from '../shared/types';
import {
  handleModeratePhoto,
  handleModerateText,
  handleDetectSpam,
  handleDetectFakeProfile,
  handleDetectScam,
  handleSubmitReport,
  handleReviewReport,
  handleSubmitAppeal,
  handleBlockUser,
  handleUnblockUser,
  handleGetBlockList,
} from './handlers';

// ========== 1. MODERATE PHOTO (HTTP Callable) ==========

interface ModeratePhotoRequest {
  photoUrl: string;
  userId: string;
  context?: 'profile' | 'message' | 'verification';
}

export const moderatePhoto = onCall<ModeratePhotoRequest>(
  {
    memory: '512MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { photoUrl, userId, context } = request.data;

      // Verify user owns the photo or is admin
      if (uid !== userId) {
        await verifyAdminAuth(request.auth);
      }

      return await handleModeratePhoto({
        photoUrl,
        userId,
        requestingUid: uid,
        context,
      });
    } catch (error) {
      logError('Error moderating photo:', error);
      throw handleError(error);
    }
  }
);

// ========== 2. MODERATE TEXT (HTTP Callable) ==========

interface ModerateTextRequest {
  text: string;
  userId: string;
  context?: 'message' | 'profile' | 'bio';
}

export const moderateText = onCall<ModerateTextRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { text, userId, context } = request.data;

      // Verify user owns the content or is admin
      if (uid !== userId) {
        await verifyAdminAuth(request.auth);
      }

      return await handleModerateText({
        text,
        userId,
        requestingUid: uid,
        context,
      });
    } catch (error) {
      logError('Error moderating text:', error);
      throw handleError(error);
    }
  }
);

// ========== 3. DETECT SPAM (HTTP Callable) ==========

interface DetectSpamRequest {
  content: string;
  userId: string;
  type: 'message' | 'profile';
}

export const detectSpam = onCall<DetectSpamRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { content, userId, type } = request.data;

      return await handleDetectSpam({
        content,
        userId,
        type,
      });
    } catch (error) {
      logError('Error detecting spam:', error);
      throw handleError(error);
    }
  }
);

// ========== 4. DETECT FAKE PROFILE (HTTP Callable) ==========

interface DetectFakeProfileRequest {
  userId: string;
}

export const detectFakeProfile = onCall<DetectFakeProfileRequest>(
  {
    memory: '256MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      await verifyAdminAuth(request.auth);
      const { userId } = request.data;

      return await handleDetectFakeProfile({ userId });
    } catch (error) {
      logError('Error detecting fake profile:', error);
      throw handleError(error);
    }
  }
);

// ========== 5. DETECT SCAM (HTTP Callable) ==========

interface DetectScamRequest {
  conversationId: string;
  messageContent: string;
}

export const detectScam = onCall<DetectScamRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      await verifyAuth(request.auth);
      const { conversationId, messageContent } = request.data;

      return await handleDetectScam({
        conversationId,
        messageContent,
      });
    } catch (error) {
      logError('Error detecting scam:', error);
      throw handleError(error);
    }
  }
);

// ========== 6. SUBMIT REPORT (HTTP Callable) ==========

interface SubmitReportRequest {
  reportedUserId: string;
  reason: ReportReason;
  description: string;
  reportedContentId?: string;
}

export const submitReport = onCall<SubmitReportRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { reportedUserId, reason, description, reportedContentId } = request.data;

      return await handleSubmitReport({
        reporterId: uid,
        reportedUserId,
        reason,
        description,
        reportedContentId,
      });
    } catch (error) {
      logError('Error submitting report:', error);
      throw handleError(error);
    }
  }
);

// ========== 7. REVIEW REPORT (HTTP Callable) ==========

interface ReviewReportRequest {
  reportId: string;
  action: 'dismiss' | 'warn' | 'suspend' | 'ban';
  notes?: string;
}

export const reviewReport = onCall<ReviewReportRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 60,
  },
  async (request) => {
    try {
      const adminUid = await verifyAdminAuth(request.auth);
      const { reportId, action, notes } = request.data;

      return await handleReviewReport({
        adminUid,
        reportId,
        action,
        notes,
      });
    } catch (error) {
      logError('Error reviewing report:', error);
      throw handleError(error);
    }
  }
);

// ========== 8. SUBMIT APPEAL (HTTP Callable) ==========

interface SubmitAppealRequest {
  reportId?: string;
  suspensionId?: string;
  appealText: string;
}

export const submitAppeal = onCall<SubmitAppealRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { reportId, suspensionId, appealText } = request.data;

      return await handleSubmitAppeal({
        userId: uid,
        reportId,
        suspensionId,
        appealText,
      });
    } catch (error) {
      logError('Error submitting appeal:', error);
      throw handleError(error);
    }
  }
);

// ========== 9. BLOCK USER (HTTP Callable) ==========

interface BlockUserRequest {
  blockedUserId: string;
}

export const blockUser = onCall<BlockUserRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { blockedUserId } = request.data;

      return await handleBlockUser({
        userId: uid,
        blockedUserId,
      });
    } catch (error) {
      logError('Error blocking user:', error);
      throw handleError(error);
    }
  }
);

// ========== 10. UNBLOCK USER (HTTP Callable) ==========

interface UnblockUserRequest {
  blockedUserId: string;
}

export const unblockUser = onCall<UnblockUserRequest>(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);
      const { blockedUserId } = request.data;

      return await handleUnblockUser({
        userId: uid,
        blockedUserId,
      });
    } catch (error) {
      logError('Error unblocking user:', error);
      throw handleError(error);
    }
  }
);

// ========== 11. GET BLOCK LIST (HTTP Callable) ==========

export const getBlockList = onCall(
  {
    memory: '128MiB',
    timeoutSeconds: 30,
  },
  async (request) => {
    try {
      const uid = await verifyAuth(request.auth);

      return await handleGetBlockList({ userId: uid });
    } catch (error) {
      logError('Error getting block list:', error);
      throw handleError(error);
    }
  }
);
