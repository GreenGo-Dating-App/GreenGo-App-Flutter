/**
 * GreenGoChat Cloud Functions
 * Entry point for all Firebase Cloud Functions
 */

// IMPORTANT: Import firebaseAdmin first to ensure initialization
import './shared/firebaseAdmin';

// Media Processing Functions
export {
  compressUploadedImage,
  compressImage,
} from './media/imageCompression';

export {
  processUploadedVideo,
  generateVideoThumbnail,
} from './media/videoProcessing';

export {
  transcribeVoiceMessage,
  transcribeAudio,
  batchTranscribe,
} from './media/voiceTranscription';

export {
  cleanupDisappearingMedia,
  markMediaAsDisappearing,
} from './media/disappearingMedia';

// Messaging Functions
export {
  translateMessage,
  autoTranslateMessage,
  batchTranslateMessages,
  getSupportedLanguages,
} from './messaging/translation';

export {
  sendScheduledMessages,
  scheduleMessage,
  cancelScheduledMessage,
  getScheduledMessages,
} from './messaging/scheduledMessages';

// Backup and Export Functions
export {
  backupConversation,
  restoreConversation,
  listBackups,
  deleteBackup,
  autoBackupConversations,
} from './backup/conversationBackup';

export {
  exportConversationToPDF,
  listPDFExports,
  cleanupExpiredExports,
} from './backup/pdfExport';

// Subscription Functions
export {
  handlePlayStoreWebhook,
  handleAppStoreWebhook,
  checkExpiringSubscriptions,
  handleExpiredGracePeriods,
} from './subscriptions/subscriptionManager';

// Coin Functions
export {
  verifyGooglePlayCoinPurchase,
  verifyAppStoreCoinPurchase,
  grantMonthlyAllowances,
  processExpiredCoins,
  sendExpirationWarnings,
  claimReward,
} from './coins/coinManager';

// Analytics Functions
export {
  getRevenueDashboard,
  exportRevenueData,
} from './analytics/revenueAnalytics';

export {
  getCohortAnalysis,
} from './analytics/cohortAnalytics';

export {
  trainChurnModel,
  predictChurnDaily,
  getUserChurnPrediction,
  getAtRiskUsers,
} from './analytics/churnPrediction';

export {
  createABTest,
  assignUserToTest,
  recordConversion,
  getABTestResults,
  detectFraud,
  forecastMRR,
  getARPU,
  getRefundAnalytics,
  calculateTax,
  getTaxReport,
} from './analytics/advancedAnalytics';

// Gamification Functions
export {
  grantXP,
  trackAchievementProgress,
  unlockAchievementReward,
  claimLevelRewards,
  trackChallengeProgress,
  claimChallengeReward,
  resetDailyChallenges,
  updateLeaderboardRankings,
} from './gamification/gamificationManager';

// Safety & Moderation Functions
export {
  moderatePhoto,
  moderateText,
  detectSpam,
  detectFakeProfile,
  detectScam,
} from './safety/contentModeration';

export {
  submitReport,
  reviewReport,
  submitAppeal,
  blockUser,
  unblockUser,
  getBlockList,
} from './safety/reportingSystem';

export {
  startPhotoVerification,
  verifyPhotoSelfie,
  verifyIDDocument,
  calculateTrustScore,
} from './safety/identityVerification';

// Admin Panel Functions
export {
  getUserActivityMetrics,
  getUserGrowthChart,
  getRevenueMetrics,
  getEngagementMetrics,
  getGeographicHeatmap,
  getSystemHealthMetrics,
  createSystemAlert,
  resolveSystemAlert,
  getAdminAuditLog,
} from './admin/adminDashboard';

export {
  createAdminUser,
  updateAdminRole,
  updateAdminPermissions,
  deactivateAdminUser,
  getAdminUsers,
  recordAdminLogin,
} from './admin/roleManagement';

export {
  searchUsers,
  getDetailedUserProfile,
  editUserProfile,
  suspendUserAccount,
  unsuspendUserAccount,
  banUserAccount,
  unbanUserAccount,
  deleteUserAccount,
  overrideUserSubscription,
  adjustUserCoins,
  sendUserNotification,
  impersonateUser,
  executeMassAction,
} from './admin/userManagement';

export {
  getModerationQueue,
  getModerationReviewItem,
  assignModerationItem,
  takeModerationAction,
  executeBulkModeration,
  getModerationStatistics,
} from './admin/moderationQueue';

// User Segmentation Functions
export {
  calculateUserSegment,
  createUserCohort,
  calculateCohortRetention,
  predictUserChurn,
  batchChurnPrediction,
} from './analytics/userSegmentation';

// Notification Functions
export {
  sendPushNotification,
  sendBundledNotifications,
  trackNotificationOpened,
  getNotificationAnalytics,
} from './notifications/pushNotifications';

// Push Notification Firestore Triggers (likes, matches, messages)
export {
  onNewLikePush,
  onNewMatchPush,
  onNewMessagePush,
} from './notifications/pushNotificationTriggers';

// Email Communication Functions (Legacy - SendGrid)
export {
  sendTransactionalEmail,
  startWelcomeEmailSeries,
  processWelcomeEmailSeries,
  sendWeeklyDigestEmails,
  sendReEngagementCampaign,
} from './notifications/emailCommunication';

// Brevo Email Service (Primary)
export {
  sendBrevoEmailFunction,
  getBrevoEmailTemplates,
  updateBrevoEmailTemplate,
  getBrevoEmailLogs,
  getBrevoEmailAnalytics,
  onUserCreatedSendWelcome,
  onSubscriptionUpdated,
  onPhotoModerationUpdated,
  onAchievementUnlocked,
  onNewMatch,
  onPurchaseCreated,
  sendBrevoWeeklyDigest,
  sendBrevoReEngagement,
  sendBrevoStreakReminder,
} from './notifications/brevoEmailService';

// Video Calling Functions
export {
  initiateVideoCall,
  answerVideoCall,
  endVideoCall,
  handleCallSignal,
  updateCallQuality,
  startCallRecording,
} from './video_calling/videoCalling';

// Video Call Features Functions
export {
  enableVirtualBackground,
  applyARFilter,
  toggleBeautyMode,
  enablePictureInPicture,
  startScreenSharing,
  stopScreenSharing,
  toggleNoiseSuppression,
  toggleEchoCancellation,
  sendInCallReaction,
  uploadCustomBackground,
  getCallHistory,
  getCallStatistics,
  cleanupExpiredReactions,
} from './video_calling/videoCallFeatures';

// Group Video Call Functions
export {
  createGroupVideoCall,
  joinGroupVideoCall,
  leaveGroupVideoCall,
  manageGroupParticipant,
  changeGroupCallLayout,
  createBreakoutRoom,
  joinBreakoutRoom,
  closeBreakoutRoom,
} from './video_calling/groupVideoCalls';

// Security Audit Functions
export {
  runSecurityAudit,
  scheduledSecurityAudit,
  getSecurityAuditReport,
  listSecurityAuditReports,
  cleanupOldAuditReports,
} from './security/securityAudit';

// Language Learning Functions
export {
  submitTeacherApplication,
  reviewTeacherApplication,
  createLesson,
  publishLesson,
  purchaseLesson,
  updateLessonProgress,
  getLearningAnalytics,
  getUserProgressReport,
  getTeacherAnalytics,
  // Admin API
  getAdminLessons,
  seedLessons,
  deleteLesson,
  updateLesson,
  getLessonStats,
} from './language_learning/languageLearningManager';

// MVP Access Control Functions
export {
  approveUser,
  rejectUser,
  updateUserTier,
  getPendingUsers,
  bulkApproveUsers,
  sendBroadcastNotification,
  sendNotificationToUser,
  getMvpAccessStats,
} from './admin/mvp_access';
