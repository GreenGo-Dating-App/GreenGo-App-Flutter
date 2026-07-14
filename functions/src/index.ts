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

// Group Chat ("Culture Circles") — isolated `groups` collection fan-out.
export {
  onGroupMessageCreated,
} from './group_chat/fanout';

export {
  onGroupCreated,
  onGroupParticipantsChanged,
  onGroupInfoChanged,
} from './group_chat/membership';

// External experiences (Viator) — scheduled ingester into `external_events`,
// plus a guarded manual-refresh endpoint. No-ops until VIATOR_API_KEY is set.
export {
  ingestExternalEvents,
  runIngestExternalEventsNow,
  runBackfillViatorCategoriesNow,
} from './external_events/ingest';

// Tiqets attractions ingester (deployed once TIQETS_API_KEY is set).
export {
  ingestTiqetsAttractions,
  runIngestTiqetsNow,
} from './external_events/tiqets';

// Geoapify attractions ingester — free, commercial-safe museums/attractions/
// theme parks (Wikipedia-enriched). Powers the Attractions tab. No-ops until
// GEOAPIFY_API_KEY is set.
// Attractions are static data — imported once via the manual trigger (no schedule).
export {
  runIngestGeoapifyNow,
  runBackfillGeoapifyWebsitesNow,
  runCleanupNoImageNow,
} from './external_events/geoapify';

// Ticketmaster live-events ingester.
export {
  ingestTicketmaster,
  runIngestTicketmasterNow,
} from './external_events/ticketmaster';

// External events — compact shard index (cheap whole-source loads for global
// in-app ordering by distance/date/stars/reviews).
export {
  runBuildExternalIndexNow,
} from './external_events/build_index';

// External events — geohash backfill (enables nearest-first server-ordered
// queries straight from the DB). Plus native-events geohash backfill.
export {
  runBackfillGeohashNow,
  runBackfillEventGeohashNow,
} from './external_events/geohash';


// Events — per-country aggregation for the globe.
export {
  onEventWriteUpdateCountryStats,
} from './events/country_aggregate';

// Events — admin broadcast + regular event-chat message push fan-out.
export {
  onEventBroadcastCreated,
  onEventMessageCreated,
} from './events/broadcast';

// Events — denormalized like counter (per-user likes subcollection → likeCount).
export {
  onEventLikeCreated,
  onEventLikeDeleted,
} from './events/likes';

// Events — business new-event → followers push fan-out (push-delivery filter
// part B). Notifies every follower of a business when it publishes an event.
export {
  onEventCreatedNotifyFollowers,
  onEventPublishedNotifyFollowers,
} from './events/business_new_event';

// Communities — announcement → members push fan-out.
export {
  onCommunityAnnouncementCreated,
} from './communities/announcementFanout';

// Communities — community event published → members push fan-out.
export {
  onCommunityEventCreated,
  onCommunityEventPublished,
} from './communities/eventFanout';

// Social notifications — actor-attributed (avatar + name) join/follow/rate/like.
export {
  onCommunityMemberJoined,
  onEventAttendeeJoined,
  onBusinessFollowed,
  onBusinessRated,
  onEventLiked,
} from './notifications/socialNotifications';

// Events — scheduled reminders.
export {
  sendEventReminders,
} from './events/reminders';

// Wallet passes (Apple .pkpass + Google Wallet) are REMOVED for now — the
// pass certificates / issuer secrets are not configured. Re-export from
// ./wallet/appleWallet & ./wallet/googleWallet once the wallet secrets
// (APPLE_PASS_CERT/KEY/..., GOOGLE_WALLET_*) are set to re-enable.

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

// Legacy Subscription Functions (webhooks disabled — using one-time purchases now)
// Webhook handlers are no longer needed for one-time purchase model.
// Expiration checks are now handled by ./subscription/index.ts
// export {
//   handlePlayStoreWebhook,
//   handleAppStoreWebhook,
//   checkExpiringSubscriptions,
//   handleExpiredGracePeriods,
// } from './subscriptions/subscriptionManager';

// Membership Purchase Verification & Expiration Management
export {
  verifyPurchase,
  checkExpiringSubscriptions as checkExpiringMemberships,
  handleExpiredMemberships,
} from './subscription/index';

// Auto-renewable subscription server notifications (renewals/cancel/refund/expiry).
// Inert until the store notification URLs are pointed at these endpoints.
export {
  appStoreNotificationsV2,
  playStoreNotifications,
} from './subscription/storeNotifications';

// Stripe Web Payments — coin packages + memberships via Stripe Checkout
// (web has no in-app-purchase plugin). Inert until STRIPE_SECRET_KEY is set.
export {
  createStripeCheckoutSession,
  stripeWebhook,
} from './payments/stripeCheckout';

// Coin Functions
export {
  verifyGooglePlayCoinPurchase,
  verifyAppStoreCoinPurchase,
  grantMonthlyAllowances,
  processExpiredCoins,
  sendExpirationWarnings,
  claimReward,
} from './coins/coinManager';

// Coupon Redemption + Admin Management
export { redeemCoupon } from './coupons/redeemCoupon';
export { validateCoupon } from './coupons/validateCoupon';
export { redeemReferral } from './referral/redeemReferral';
export {
  upsertCoupon,
  listCoupons,
  getCouponRedemptions,
  setCouponDisabled,
} from './coupons/adminCoupons';
export { applySignupGrants } from './coupons/applySignupGrants';

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
  adminBulkDeleteUsers,
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

// Push Notification Firestore Triggers (likes, matches, messages, support, verification, mode expiry)
export {
  onNewLikePush,
  onNewMatchPush,
  onNewMessagePush,
  onSupportMessagePush,
  checkExpiringModes,
  onVerificationStatusChange,
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

// Discovery / Candidate Pool Functions
export {
  precomputeCandidatePools,
  triggerPoolRecompute,
  getCandidatePoolStats,
} from './discovery/candidatePoolPrecompute';

// Presence / Location Enrichment Functions
export {
  onPresenceUpdate,
} from './presence/onPresenceUpdate';

// Presence Cleanup (Scheduled)
export { cleanupStalePresence } from './presence/cleanupStalePresence';

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

// Admin Panel Functions (2FA, password mgmt, user mgmt, AI support)
export {
  send2FACode,
  verify2FACode,
  adminChangeUserPassword,
  sendPasswordResetEmail,
  forcePasswordChange,
  adminDeleteUser,
  adminSetUserDisabled,
  sendTestEmail,
  processAISupportMessage,
  onSupportChatCreated,
  onSupportMessageCreated,
  cleanupOrphanedAuthUser,
  sendWelcomeEmail,
  sendPasswordResetViaResend,
  reverseGeocodeProfileLocation,
} from './admin/adminPanelFunctions';
