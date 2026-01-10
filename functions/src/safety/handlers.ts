/**
 * Safety & Moderation Handlers
 * Business logic for all 11 safety functions
 */

import { HttpsError } from 'firebase-functions/v2/https';
import { ImageAnnotatorClient } from '@google-cloud/vision';
import { LanguageServiceClient } from '@google-cloud/language';
import { db, logInfo, logError, FieldValue, verifyAdminAuth } from '../shared/utils';
import { ModerationCategory, ModerationAction, ReportReason, ReportStatus } from '../shared/types';
import * as admin from 'firebase-admin';

const visionClient = new ImageAnnotatorClient();
const languageClient = new LanguageServiceClient();

// ========== HELPER FUNCTIONS ==========

function getLikelihoodScore(likelihood: string | null | undefined): number {
  const scores: Record<string, number> = {
    VERY_UNLIKELY: 1,
    UNLIKELY: 2,
    POSSIBLE: 3,
    LIKELY: 4,
    VERY_LIKELY: 5,
  };
  return scores[likelihood || 'VERY_UNLIKELY'] || 1;
}

// ========== 1. MODERATE PHOTO HANDLER ==========

export interface ModeratePhotoParams {
  photoUrl: string;
  userId: string;
  requestingUid: string;
  context?: 'profile' | 'message' | 'verification';
}

export interface ModeratePhotoResult {
  success: boolean;
  moderationId: string;
  flagged: boolean;
  action: ModerationAction;
  categories: ModerationCategory[];
  scores: {
    adult: number;
    violence: number;
    racy: number;
    medical: number;
  };
}

export async function handleModeratePhoto(params: ModeratePhotoParams): Promise<ModeratePhotoResult> {
  const { photoUrl, userId, requestingUid, context = 'profile' } = params;

  if (!photoUrl) {
    throw new HttpsError('invalid-argument', 'photoUrl is required');
  }

  logInfo(`Moderating photo for user ${userId}: ${photoUrl}`);

  // Verify user owns the photo or is admin (caller should verify admin if needed)
  if (requestingUid !== userId) {
    // Admin verification should be done by caller
    logInfo(`Admin ${requestingUid} moderating photo for user ${userId}`);
  }

  // Use Cloud Vision API for safe search detection
  const [result] = await visionClient.safeSearchDetection(photoUrl);
  const safeSearch = result.safeSearchAnnotation!;

  const scores = {
    adult: getLikelihoodScore(safeSearch.adult as any),
    violence: getLikelihoodScore(safeSearch.violence as any),
    racy: getLikelihoodScore(safeSearch.racy as any),
    medical: getLikelihoodScore(safeSearch.medical as any),
  };

  // Determine if photo should be flagged
  const flagged = scores.adult >= 4 || scores.violence >= 4;
  const categories: ModerationCategory[] = [];

  if (scores.adult >= 4) categories.push(ModerationCategory.ADULT);
  if (scores.violence >= 4) categories.push(ModerationCategory.VIOLENCE);

  // Determine action
  let action: ModerationAction;
  if (flagged) {
    action = scores.adult >= 5 || scores.violence >= 5
      ? ModerationAction.AUTO_REJECTED
      : ModerationAction.PENDING_REVIEW;
  } else {
    action = ModerationAction.AUTO_APPROVED;
  }

  // Save moderation result
  const moderationRef = await db.collection('moderation_results').add({
    targetType: 'photo',
    targetId: photoUrl,
    userId,
    context,
    flagged,
    categories,
    scores,
    action,
    createdAt: FieldValue.serverTimestamp(),
  });

  // If auto-rejected, remove photo
  if (action === ModerationAction.AUTO_REJECTED) {
    logInfo(`Photo auto-rejected: ${photoUrl}`);
  }

  // If pending review, add to moderation queue
  if (action === ModerationAction.PENDING_REVIEW) {
    await db.collection('moderation_queue').add({
      type: 'photo',
      targetId: photoUrl,
      userId,
      moderationId: moderationRef.id,
      priority: 'high',
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
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

// ========== 2. MODERATE TEXT HANDLER ==========

export interface ModerateTextParams {
  text: string;
  userId: string;
  requestingUid: string;
  context?: 'message' | 'profile' | 'bio';
}

export interface ModerateTextResult {
  success: boolean;
  moderationId: string;
  flagged: boolean;
  action: ModerationAction;
  categories: ModerationCategory[];
  toxicityScore: number;
}

export async function handleModerateText(params: ModerateTextParams): Promise<ModerateTextResult> {
  const { text, userId, requestingUid, context = 'message' } = params;

  if (!text) {
    throw new HttpsError('invalid-argument', 'text is required');
  }

  if (requestingUid !== userId) {
    logInfo(`Admin ${requestingUid} moderating text for user ${userId}`);
  }

  logInfo(`Moderating text for user ${userId}`);

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
      type: 'PLAIN_TEXT' as const,
    };

    const [sentiment] = await languageClient.analyzeSentiment({ document });
    const sentimentScore = sentiment.documentSentiment?.score || 0;

    // Negative sentiment might indicate toxic content
    if (sentimentScore < -0.5) {
      toxicityScore += 0.2;
    }
  } catch (error) {
    logError('Error analyzing sentiment:', error);
  }

  const flagged = hasProfanity || toxicityScore > 0.5;
  const categories: ModerationCategory[] = [];

  if (hasProfanity) categories.push(ModerationCategory.HATE_SPEECH);
  if (toxicityScore > 0.7) categories.push(ModerationCategory.SPAM);

  const action = flagged
    ? toxicityScore > 0.8
      ? ModerationAction.AUTO_REJECTED
      : ModerationAction.PENDING_REVIEW
    : ModerationAction.AUTO_APPROVED;

  const moderationRef = await db.collection('moderation_results').add({
    targetType: 'text',
    targetId: text.substring(0, 100),
    userId,
    context,
    flagged,
    categories,
    scores: { toxicity: toxicityScore, profanity: hasProfanity ? 1 : 0 },
    action,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (action === ModerationAction.PENDING_REVIEW) {
    await db.collection('moderation_queue').add({
      type: 'text',
      targetId: moderationRef.id,
      userId,
      moderationId: moderationRef.id,
      content: text,
      priority: 'medium',
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
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

// ========== 3. DETECT SPAM HANDLER ==========

export interface DetectSpamParams {
  content: string;
  userId: string;
  type: 'message' | 'profile';
}

export interface DetectSpamResult {
  success: boolean;
  isSpam: boolean;
  spamScore: number;
  indicators: string[];
}

export async function handleDetectSpam(params: DetectSpamParams): Promise<DetectSpamResult> {
  const { content, userId, type } = params;

  if (!content) {
    throw new HttpsError('invalid-argument', 'content is required');
  }

  logInfo(`Detecting spam for user ${userId}`);

  let spamScore = 0;
  const indicators: string[] = [];

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

  await db.collection('spam_detections').add({
    userId,
    content: content.substring(0, 200),
    type,
    isSpam,
    spamScore,
    indicators,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (isSpam) {
    await db.collection('moderation_queue').add({
      type: 'spam',
      userId,
      content: content.substring(0, 200),
      spamScore,
      indicators,
      priority: 'medium',
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  return {
    success: true,
    isSpam,
    spamScore,
    indicators,
  };
}

// ========== 4. DETECT FAKE PROFILE HANDLER ==========

export interface DetectFakeProfileParams {
  userId: string;
}

export interface DetectFakeProfileResult {
  success: boolean;
  isFake: boolean;
  suspicionScore: number;
  indicators: string[];
}

export async function handleDetectFakeProfile(params: DetectFakeProfileParams): Promise<DetectFakeProfileResult> {
  const { userId } = params;

  if (!userId) {
    throw new HttpsError('invalid-argument', 'userId is required');
  }

  logInfo(`Detecting fake profile for user ${userId}`);

  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    throw new HttpsError('not-found', 'User not found');
  }

  const userData = userDoc.data()!;
  let suspicionScore = 0;
  const indicators: string[] = [];

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
  const messagesSnapshot = await db
    .collection('messages')
    .where('senderId', '==', userId)
    .limit(10)
    .get();

  if (accountAgeDays > 7 && messagesSnapshot.size === 0) {
    suspicionScore += 0.2;
    indicators.push('no_activity');
  }

  const isFake = suspicionScore >= 0.6;

  await db.collection('fake_profile_detections').add({
    userId,
    isFake,
    suspicionScore,
    indicators,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (isFake) {
    await db.collection('moderation_queue').add({
      type: 'fake_profile',
      userId,
      suspicionScore,
      indicators,
      priority: 'high',
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  return {
    success: true,
    isFake,
    suspicionScore,
    indicators,
  };
}

// ========== 5. DETECT SCAM HANDLER ==========

export interface DetectScamParams {
  conversationId: string;
  messageContent: string;
}

export interface DetectScamResult {
  success: boolean;
  isScam: boolean;
  scamScore: number;
  indicators: string[];
}

export async function handleDetectScam(params: DetectScamParams): Promise<DetectScamResult> {
  const { conversationId, messageContent } = params;

  if (!messageContent) {
    throw new HttpsError('invalid-argument', 'messageContent is required');
  }

  logInfo(`Detecting scam in conversation ${conversationId}`);

  let scamScore = 0;
  const indicators: string[] = [];

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

  await db.collection('scam_detections').add({
    conversationId,
    content: messageContent.substring(0, 200),
    isScam,
    scamScore,
    indicators,
    createdAt: FieldValue.serverTimestamp(),
  });

  if (isScam) {
    await db.collection('moderation_queue').add({
      type: 'scam',
      conversationId,
      content: messageContent.substring(0, 200),
      scamScore,
      indicators,
      priority: 'critical',
      status: 'pending',
      createdAt: FieldValue.serverTimestamp(),
    });
  }

  return {
    success: true,
    isScam,
    scamScore,
    indicators,
  };
}

// ========== 6. SUBMIT REPORT HANDLER ==========

export interface SubmitReportParams {
  reporterId: string;
  reportedUserId: string;
  reason: ReportReason;
  description: string;
  reportedContentId?: string;
}

export interface SubmitReportResult {
  success: boolean;
  reportId: string;
  message: string;
}

export async function handleSubmitReport(params: SubmitReportParams): Promise<SubmitReportResult> {
  const { reporterId, reportedUserId, reason, description, reportedContentId } = params;

  if (!reportedUserId || !reason || !description) {
    throw new HttpsError('invalid-argument', 'reportedUserId, reason, and description are required');
  }

  logInfo(`User ${reporterId} reporting user ${reportedUserId} for ${reason}`);

  const reportRef = await db.collection('reports').add({
    reporterId,
    reportedUserId,
    reportedContentId,
    reason,
    description,
    status: ReportStatus.PENDING,
    createdAt: FieldValue.serverTimestamp(),
  });

  // Add to moderation queue
  await db.collection('moderation_queue').add({
    type: 'user_report',
    reportId: reportRef.id,
    reportedUserId,
    reason,
    priority: reason === ReportReason.SCAM || reason === ReportReason.UNDERAGE ? 'critical' : 'high',
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    reportId: reportRef.id,
    message: 'Report submitted successfully',
  };
}

// ========== 7. REVIEW REPORT HANDLER ==========

export interface ReviewReportParams {
  adminUid: string;
  reportId: string;
  action: 'dismiss' | 'warn' | 'suspend' | 'ban';
  notes?: string;
}

export interface ReviewReportResult {
  success: boolean;
  message: string;
}

export async function handleReviewReport(params: ReviewReportParams): Promise<ReviewReportResult> {
  const { adminUid, reportId, action, notes } = params;

  if (!reportId || !action) {
    throw new HttpsError('invalid-argument', 'reportId and action are required');
  }

  logInfo(`Admin ${adminUid} reviewing report ${reportId} with action ${action}`);

  const reportDoc = await db.collection('reports').doc(reportId).get();
  if (!reportDoc.exists) {
    throw new HttpsError('not-found', 'Report not found');
  }

  const reportData = reportDoc.data()!;

  // Update report
  await reportDoc.ref.update({
    status: ReportStatus.RESOLVED,
    action,
    reviewedBy: adminUid,
    reviewedAt: FieldValue.serverTimestamp(),
    notes,
  });

  // Take action on reported user
  const userRef = db.collection('users').doc(reportData.reportedUserId);

  switch (action) {
    case 'warn':
      await userRef.update({
        warnings: FieldValue.increment(1),
        lastWarningAt: FieldValue.serverTimestamp(),
      });
      break;

    case 'suspend':
      await userRef.update({
        suspended: true,
        suspendedAt: FieldValue.serverTimestamp(),
        suspendedUntil: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) // 7 days
        ),
        suspensionReason: reportData.reason,
      });
      break;

    case 'ban':
      await userRef.update({
        banned: true,
        bannedAt: FieldValue.serverTimestamp(),
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
  await db.collection('admin_audit_log').add({
    adminUid,
    action: 'review_report',
    targetUserId: reportData.reportedUserId,
    reportId,
    moderationAction: action,
    timestamp: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    message: `Report ${action}ed successfully`,
  };
}

// ========== 8. SUBMIT APPEAL HANDLER ==========

export interface SubmitAppealParams {
  userId: string;
  reportId?: string;
  suspensionId?: string;
  appealText: string;
}

export interface SubmitAppealResult {
  success: boolean;
  appealId: string;
  message: string;
}

export async function handleSubmitAppeal(params: SubmitAppealParams): Promise<SubmitAppealResult> {
  const { userId, reportId, suspensionId, appealText } = params;

  if (!appealText) {
    throw new HttpsError('invalid-argument', 'appealText is required');
  }

  logInfo(`User ${userId} submitting appeal`);

  const appealRef = await db.collection('appeals').add({
    userId,
    reportId,
    suspensionId,
    appealText,
    status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    success: true,
    appealId: appealRef.id,
    message: 'Appeal submitted for review',
  };
}

// ========== 9. BLOCK USER HANDLER ==========

export interface BlockUserParams {
  userId: string;
  blockedUserId: string;
}

export interface BlockUserResult {
  success: boolean;
  message: string;
}

export async function handleBlockUser(params: BlockUserParams): Promise<BlockUserResult> {
  const { userId, blockedUserId } = params;

  if (!blockedUserId) {
    throw new HttpsError('invalid-argument', 'blockedUserId is required');
  }

  logInfo(`User ${userId} blocking user ${blockedUserId}`);

  const userRef = db.collection('users').doc(userId);

  await userRef.update({
    blockedUsers: FieldValue.arrayUnion(blockedUserId),
  });

  return {
    success: true,
    message: 'User blocked successfully',
  };
}

// ========== 10. UNBLOCK USER HANDLER ==========

export interface UnblockUserParams {
  userId: string;
  blockedUserId: string;
}

export interface UnblockUserResult {
  success: boolean;
  message: string;
}

export async function handleUnblockUser(params: UnblockUserParams): Promise<UnblockUserResult> {
  const { userId, blockedUserId } = params;

  if (!blockedUserId) {
    throw new HttpsError('invalid-argument', 'blockedUserId is required');
  }

  const userRef = db.collection('users').doc(userId);

  await userRef.update({
    blockedUsers: FieldValue.arrayRemove(blockedUserId),
  });

  return {
    success: true,
    message: 'User unblocked successfully',
  };
}

// ========== 11. GET BLOCK LIST HANDLER ==========

export interface GetBlockListParams {
  userId: string;
}

export interface GetBlockListResult {
  success: boolean;
  blockedUsers: string[];
  total: number;
}

export async function handleGetBlockList(params: GetBlockListParams): Promise<GetBlockListResult> {
  const { userId } = params;

  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();

  const blockedUsers = userData?.blockedUsers || [];

  return {
    success: true,
    blockedUsers,
    total: blockedUsers.length,
  };
}
