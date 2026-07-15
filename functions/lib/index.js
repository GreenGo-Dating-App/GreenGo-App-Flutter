"use strict";
/**
 * GreenGoChat Cloud Functions
 * Entry point for all Firebase Cloud Functions
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.onBusinessFollowed = exports.onEventAttendeeJoined = exports.onCommunityMemberJoined = exports.backfillCommunityCreatorMembers = exports.onCommunityEventChanged = exports.onCommunityEventPublished = exports.onCommunityEventCreated = exports.onCommunityAnnouncementCreated = exports.onEventPublishedNotifyFollowers = exports.onEventCreatedNotifyFollowers = exports.onEventLikeDeleted = exports.onEventLikeCreated = exports.onEventMessageCreated = exports.onEventBroadcastCreated = exports.onEventWriteUpdateCountryStats = exports.runBackfillEventGeohashNow = exports.runBackfillGeohashNow = exports.runBuildExternalIndexNow = exports.runIngestTicketmasterNow = exports.ingestTicketmaster = exports.runCleanupNoImageNow = exports.runBackfillGeoapifyWebsitesNow = exports.runIngestGeoapifyNow = exports.runIngestTiqetsNow = exports.ingestTiqetsAttractions = exports.runBackfillViatorCategoriesNow = exports.runIngestExternalEventsNow = exports.ingestExternalEvents = exports.onGroupDeleted = exports.onGroupInfoChanged = exports.onGroupParticipantsChanged = exports.onGroupCreated = exports.onGroupMessageCreated = exports.getScheduledMessages = exports.cancelScheduledMessage = exports.scheduleMessage = exports.sendScheduledMessages = exports.getSupportedLanguages = exports.batchTranslateMessages = exports.autoTranslateMessage = exports.translateMessage = exports.markMediaAsDisappearing = exports.cleanupDisappearingMedia = exports.batchTranscribe = exports.transcribeAudio = exports.transcribeVoiceMessage = exports.generateVideoThumbnail = exports.processUploadedVideo = exports.compressImage = exports.compressUploadedImage = void 0;
exports.getABTestResults = exports.recordConversion = exports.assignUserToTest = exports.createABTest = exports.getAtRiskUsers = exports.getUserChurnPrediction = exports.predictChurnDaily = exports.trainChurnModel = exports.getCohortAnalysis = exports.exportRevenueData = exports.getRevenueDashboard = exports.applySignupGrants = exports.setCouponDisabled = exports.getCouponRedemptions = exports.listCoupons = exports.upsertCoupon = exports.redeemReferral = exports.validateCoupon = exports.redeemCoupon = exports.claimReward = exports.sendExpirationWarnings = exports.processExpiredCoins = exports.grantMonthlyAllowances = exports.verifyAppStoreCoinPurchase = exports.verifyGooglePlayCoinPurchase = exports.stripeWebhook = exports.createStripeCheckoutSession = exports.playStoreNotifications = exports.appStoreNotificationsV2 = exports.handleExpiredMemberships = exports.checkExpiringMemberships = exports.verifyPurchase = exports.cleanupExpiredExports = exports.listPDFExports = exports.exportConversationToPDF = exports.autoBackupConversations = exports.deleteBackup = exports.listBackups = exports.restoreConversation = exports.backupConversation = exports.autoPublishScheduledEvents = exports.sendEventReminders = exports.checkBoostExpiries = exports.onEventBoostStarted = exports.onProfileBoostStarted = exports.onTicketScanned = exports.onProfileViewed = exports.onNotificationCreatedPush = exports.onEventLiked = exports.onBusinessRated = void 0;
exports.unsuspendUserAccount = exports.suspendUserAccount = exports.editUserProfile = exports.getDetailedUserProfile = exports.searchUsers = exports.recordAdminLogin = exports.getAdminUsers = exports.deactivateAdminUser = exports.updateAdminPermissions = exports.updateAdminRole = exports.createAdminUser = exports.getAdminAuditLog = exports.resolveSystemAlert = exports.createSystemAlert = exports.getSystemHealthMetrics = exports.getGeographicHeatmap = exports.getEngagementMetrics = exports.getRevenueMetrics = exports.getUserGrowthChart = exports.getUserActivityMetrics = exports.calculateTrustScore = exports.verifyIDDocument = exports.verifyPhotoSelfie = exports.startPhotoVerification = exports.onUserReportCreated = exports.getBlockList = exports.unblockUser = exports.blockUser = exports.submitAppeal = exports.reviewReport = exports.submitReport = exports.detectScam = exports.detectFakeProfile = exports.detectSpam = exports.moderateText = exports.moderatePhoto = exports.updateLeaderboardRankings = exports.resetDailyChallenges = exports.claimChallengeReward = exports.trackChallengeProgress = exports.claimLevelRewards = exports.unlockAchievementReward = exports.trackAchievementProgress = exports.grantXP = exports.getTaxReport = exports.calculateTax = exports.getRefundAnalytics = exports.getARPU = exports.forecastMRR = exports.detectFraud = void 0;
exports.initiateVideoCall = exports.sendBrevoStreakReminder = exports.sendBrevoReEngagement = exports.sendBrevoWeeklyDigest = exports.onPurchaseCreated = exports.onNewMatch = exports.onAchievementUnlocked = exports.onPhotoModerationUpdated = exports.onSubscriptionUpdated = exports.onUserCreatedSendWelcome = exports.getBrevoEmailAnalytics = exports.getBrevoEmailLogs = exports.updateBrevoEmailTemplate = exports.getBrevoEmailTemplates = exports.sendBrevoEmailFunction = exports.sendReEngagementCampaign = exports.sendWeeklyDigestEmails = exports.processWelcomeEmailSeries = exports.startWelcomeEmailSeries = exports.sendTransactionalEmail = exports.onVerificationStatusChange = exports.checkExpiringModes = exports.onSupportMessagePush = exports.onNewMessagePush = exports.onNewMatchPush = exports.onNewLikePush = exports.getNotificationAnalytics = exports.trackNotificationOpened = exports.sendBundledNotifications = exports.sendPushNotification = exports.batchChurnPrediction = exports.predictUserChurn = exports.calculateCohortRetention = exports.createUserCohort = exports.calculateUserSegment = exports.getModerationStatistics = exports.executeBulkModeration = exports.takeModerationAction = exports.assignModerationItem = exports.getModerationReviewItem = exports.getModerationQueue = exports.adminBulkDeleteUsers = exports.executeMassAction = exports.impersonateUser = exports.sendUserNotification = exports.adjustUserCoins = exports.overrideUserSubscription = exports.deleteUserAccount = exports.unbanUserAccount = exports.banUserAccount = void 0;
exports.cleanupStalePresence = exports.onPresenceUpdate = exports.getCandidatePoolStats = exports.triggerPoolRecompute = exports.precomputeCandidatePools = exports.getLessonStats = exports.updateLesson = exports.deleteLesson = exports.seedLessons = exports.getAdminLessons = exports.getTeacherAnalytics = exports.getUserProgressReport = exports.getLearningAnalytics = exports.updateLessonProgress = exports.purchaseLesson = exports.publishLesson = exports.createLesson = exports.reviewTeacherApplication = exports.submitTeacherApplication = exports.cleanupOldAuditReports = exports.listSecurityAuditReports = exports.getSecurityAuditReport = exports.scheduledSecurityAudit = exports.runSecurityAudit = exports.closeBreakoutRoom = exports.joinBreakoutRoom = exports.createBreakoutRoom = exports.changeGroupCallLayout = exports.manageGroupParticipant = exports.leaveGroupVideoCall = exports.joinGroupVideoCall = exports.createGroupVideoCall = exports.cleanupExpiredReactions = exports.getCallStatistics = exports.getCallHistory = exports.uploadCustomBackground = exports.sendInCallReaction = exports.toggleEchoCancellation = exports.toggleNoiseSuppression = exports.stopScreenSharing = exports.startScreenSharing = exports.enablePictureInPicture = exports.toggleBeautyMode = exports.applyARFilter = exports.enableVirtualBackground = exports.startCallRecording = exports.updateCallQuality = exports.handleCallSignal = exports.endVideoCall = exports.answerVideoCall = void 0;
exports.reverseGeocodeProfileLocation = exports.sendPasswordResetViaResend = exports.sendWelcomeEmail = exports.cleanupOrphanedAuthUser = exports.onSupportMessageCreated = exports.onSupportChatCreated = exports.processAISupportMessage = exports.sendTestEmail = exports.adminSetUserDisabled = exports.adminDeleteUser = exports.forcePasswordChange = exports.sendPasswordResetEmail = exports.adminChangeUserPassword = exports.verify2FACode = exports.send2FACode = exports.getMvpAccessStats = exports.sendNotificationToUser = exports.sendBroadcastNotification = exports.bulkApproveUsers = exports.getPendingUsers = exports.updateUserTier = exports.rejectUser = exports.approveUser = void 0;
// IMPORTANT: Import firebaseAdmin first to ensure initialization
require("./shared/firebaseAdmin");
// Media Processing Functions
var imageCompression_1 = require("./media/imageCompression");
Object.defineProperty(exports, "compressUploadedImage", { enumerable: true, get: function () { return imageCompression_1.compressUploadedImage; } });
Object.defineProperty(exports, "compressImage", { enumerable: true, get: function () { return imageCompression_1.compressImage; } });
var videoProcessing_1 = require("./media/videoProcessing");
Object.defineProperty(exports, "processUploadedVideo", { enumerable: true, get: function () { return videoProcessing_1.processUploadedVideo; } });
Object.defineProperty(exports, "generateVideoThumbnail", { enumerable: true, get: function () { return videoProcessing_1.generateVideoThumbnail; } });
var voiceTranscription_1 = require("./media/voiceTranscription");
Object.defineProperty(exports, "transcribeVoiceMessage", { enumerable: true, get: function () { return voiceTranscription_1.transcribeVoiceMessage; } });
Object.defineProperty(exports, "transcribeAudio", { enumerable: true, get: function () { return voiceTranscription_1.transcribeAudio; } });
Object.defineProperty(exports, "batchTranscribe", { enumerable: true, get: function () { return voiceTranscription_1.batchTranscribe; } });
var disappearingMedia_1 = require("./media/disappearingMedia");
Object.defineProperty(exports, "cleanupDisappearingMedia", { enumerable: true, get: function () { return disappearingMedia_1.cleanupDisappearingMedia; } });
Object.defineProperty(exports, "markMediaAsDisappearing", { enumerable: true, get: function () { return disappearingMedia_1.markMediaAsDisappearing; } });
// Messaging Functions
var translation_1 = require("./messaging/translation");
Object.defineProperty(exports, "translateMessage", { enumerable: true, get: function () { return translation_1.translateMessage; } });
Object.defineProperty(exports, "autoTranslateMessage", { enumerable: true, get: function () { return translation_1.autoTranslateMessage; } });
Object.defineProperty(exports, "batchTranslateMessages", { enumerable: true, get: function () { return translation_1.batchTranslateMessages; } });
Object.defineProperty(exports, "getSupportedLanguages", { enumerable: true, get: function () { return translation_1.getSupportedLanguages; } });
var scheduledMessages_1 = require("./messaging/scheduledMessages");
Object.defineProperty(exports, "sendScheduledMessages", { enumerable: true, get: function () { return scheduledMessages_1.sendScheduledMessages; } });
Object.defineProperty(exports, "scheduleMessage", { enumerable: true, get: function () { return scheduledMessages_1.scheduleMessage; } });
Object.defineProperty(exports, "cancelScheduledMessage", { enumerable: true, get: function () { return scheduledMessages_1.cancelScheduledMessage; } });
Object.defineProperty(exports, "getScheduledMessages", { enumerable: true, get: function () { return scheduledMessages_1.getScheduledMessages; } });
// Group Chat ("Culture Circles") — isolated `groups` collection fan-out.
var fanout_1 = require("./group_chat/fanout");
Object.defineProperty(exports, "onGroupMessageCreated", { enumerable: true, get: function () { return fanout_1.onGroupMessageCreated; } });
var membership_1 = require("./group_chat/membership");
Object.defineProperty(exports, "onGroupCreated", { enumerable: true, get: function () { return membership_1.onGroupCreated; } });
Object.defineProperty(exports, "onGroupParticipantsChanged", { enumerable: true, get: function () { return membership_1.onGroupParticipantsChanged; } });
Object.defineProperty(exports, "onGroupInfoChanged", { enumerable: true, get: function () { return membership_1.onGroupInfoChanged; } });
// Group cascade cleanup when an admin permanently deletes a group.
var groupCleanup_1 = require("./group_chat/groupCleanup");
Object.defineProperty(exports, "onGroupDeleted", { enumerable: true, get: function () { return groupCleanup_1.onGroupDeleted; } });
// External experiences (Viator) — scheduled ingester into `external_events`,
// plus a guarded manual-refresh endpoint. No-ops until VIATOR_API_KEY is set.
var ingest_1 = require("./external_events/ingest");
Object.defineProperty(exports, "ingestExternalEvents", { enumerable: true, get: function () { return ingest_1.ingestExternalEvents; } });
Object.defineProperty(exports, "runIngestExternalEventsNow", { enumerable: true, get: function () { return ingest_1.runIngestExternalEventsNow; } });
Object.defineProperty(exports, "runBackfillViatorCategoriesNow", { enumerable: true, get: function () { return ingest_1.runBackfillViatorCategoriesNow; } });
// Tiqets attractions ingester (deployed once TIQETS_API_KEY is set).
var tiqets_1 = require("./external_events/tiqets");
Object.defineProperty(exports, "ingestTiqetsAttractions", { enumerable: true, get: function () { return tiqets_1.ingestTiqetsAttractions; } });
Object.defineProperty(exports, "runIngestTiqetsNow", { enumerable: true, get: function () { return tiqets_1.runIngestTiqetsNow; } });
// Geoapify attractions ingester — free, commercial-safe museums/attractions/
// theme parks (Wikipedia-enriched). Powers the Attractions tab. No-ops until
// GEOAPIFY_API_KEY is set.
// Attractions are static data — imported once via the manual trigger (no schedule).
var geoapify_1 = require("./external_events/geoapify");
Object.defineProperty(exports, "runIngestGeoapifyNow", { enumerable: true, get: function () { return geoapify_1.runIngestGeoapifyNow; } });
Object.defineProperty(exports, "runBackfillGeoapifyWebsitesNow", { enumerable: true, get: function () { return geoapify_1.runBackfillGeoapifyWebsitesNow; } });
Object.defineProperty(exports, "runCleanupNoImageNow", { enumerable: true, get: function () { return geoapify_1.runCleanupNoImageNow; } });
// Ticketmaster live-events ingester.
var ticketmaster_1 = require("./external_events/ticketmaster");
Object.defineProperty(exports, "ingestTicketmaster", { enumerable: true, get: function () { return ticketmaster_1.ingestTicketmaster; } });
Object.defineProperty(exports, "runIngestTicketmasterNow", { enumerable: true, get: function () { return ticketmaster_1.runIngestTicketmasterNow; } });
// External events — compact shard index (cheap whole-source loads for global
// in-app ordering by distance/date/stars/reviews).
var build_index_1 = require("./external_events/build_index");
Object.defineProperty(exports, "runBuildExternalIndexNow", { enumerable: true, get: function () { return build_index_1.runBuildExternalIndexNow; } });
// External events — geohash backfill (enables nearest-first server-ordered
// queries straight from the DB). Plus native-events geohash backfill.
var geohash_1 = require("./external_events/geohash");
Object.defineProperty(exports, "runBackfillGeohashNow", { enumerable: true, get: function () { return geohash_1.runBackfillGeohashNow; } });
Object.defineProperty(exports, "runBackfillEventGeohashNow", { enumerable: true, get: function () { return geohash_1.runBackfillEventGeohashNow; } });
// Events — per-country aggregation for the globe.
var country_aggregate_1 = require("./events/country_aggregate");
Object.defineProperty(exports, "onEventWriteUpdateCountryStats", { enumerable: true, get: function () { return country_aggregate_1.onEventWriteUpdateCountryStats; } });
// Events — admin broadcast + regular event-chat message push fan-out.
var broadcast_1 = require("./events/broadcast");
Object.defineProperty(exports, "onEventBroadcastCreated", { enumerable: true, get: function () { return broadcast_1.onEventBroadcastCreated; } });
Object.defineProperty(exports, "onEventMessageCreated", { enumerable: true, get: function () { return broadcast_1.onEventMessageCreated; } });
// Events — denormalized like counter (per-user likes subcollection → likeCount).
var likes_1 = require("./events/likes");
Object.defineProperty(exports, "onEventLikeCreated", { enumerable: true, get: function () { return likes_1.onEventLikeCreated; } });
Object.defineProperty(exports, "onEventLikeDeleted", { enumerable: true, get: function () { return likes_1.onEventLikeDeleted; } });
// Events — business new-event → followers push fan-out (push-delivery filter
// part B). Notifies every follower of a business when it publishes an event.
var business_new_event_1 = require("./events/business_new_event");
Object.defineProperty(exports, "onEventCreatedNotifyFollowers", { enumerable: true, get: function () { return business_new_event_1.onEventCreatedNotifyFollowers; } });
Object.defineProperty(exports, "onEventPublishedNotifyFollowers", { enumerable: true, get: function () { return business_new_event_1.onEventPublishedNotifyFollowers; } });
// Communities — announcement → members push fan-out.
var announcementFanout_1 = require("./communities/announcementFanout");
Object.defineProperty(exports, "onCommunityAnnouncementCreated", { enumerable: true, get: function () { return announcementFanout_1.onCommunityAnnouncementCreated; } });
// Communities — community event published → members push fan-out.
var eventFanout_1 = require("./communities/eventFanout");
Object.defineProperty(exports, "onCommunityEventCreated", { enumerable: true, get: function () { return eventFanout_1.onCommunityEventCreated; } });
Object.defineProperty(exports, "onCommunityEventPublished", { enumerable: true, get: function () { return eventFanout_1.onCommunityEventPublished; } });
Object.defineProperty(exports, "onCommunityEventChanged", { enumerable: true, get: function () { return eventFanout_1.onCommunityEventChanged; } });
// Communities — ONE-TIME backfill: add creator owner-member docs to legacy
// communities. Invoke once via URL (?token=...), then it can be removed.
var backfillCreatorMembers_1 = require("./communities/backfillCreatorMembers");
Object.defineProperty(exports, "backfillCommunityCreatorMembers", { enumerable: true, get: function () { return backfillCreatorMembers_1.backfillCommunityCreatorMembers; } });
// Social notifications — actor-attributed (avatar + name) join/follow/rate/like.
var socialNotifications_1 = require("./notifications/socialNotifications");
Object.defineProperty(exports, "onCommunityMemberJoined", { enumerable: true, get: function () { return socialNotifications_1.onCommunityMemberJoined; } });
Object.defineProperty(exports, "onEventAttendeeJoined", { enumerable: true, get: function () { return socialNotifications_1.onEventAttendeeJoined; } });
Object.defineProperty(exports, "onBusinessFollowed", { enumerable: true, get: function () { return socialNotifications_1.onBusinessFollowed; } });
Object.defineProperty(exports, "onBusinessRated", { enumerable: true, get: function () { return socialNotifications_1.onBusinessRated; } });
Object.defineProperty(exports, "onEventLiked", { enumerable: true, get: function () { return socialNotifications_1.onEventLiked; } });
// Push parity — every in-app notifications doc without its own push gets one.
var pushParity_1 = require("./notifications/pushParity");
Object.defineProperty(exports, "onNotificationCreatedPush", { enumerable: true, get: function () { return pushParity_1.onNotificationCreatedPush; } });
// Engagement notifications — profile view (throttled), QR scan, boost start/end.
var engagementNotifications_1 = require("./notifications/engagementNotifications");
Object.defineProperty(exports, "onProfileViewed", { enumerable: true, get: function () { return engagementNotifications_1.onProfileViewed; } });
Object.defineProperty(exports, "onTicketScanned", { enumerable: true, get: function () { return engagementNotifications_1.onTicketScanned; } });
Object.defineProperty(exports, "onProfileBoostStarted", { enumerable: true, get: function () { return engagementNotifications_1.onProfileBoostStarted; } });
Object.defineProperty(exports, "onEventBoostStarted", { enumerable: true, get: function () { return engagementNotifications_1.onEventBoostStarted; } });
Object.defineProperty(exports, "checkBoostExpiries", { enumerable: true, get: function () { return engagementNotifications_1.checkBoostExpiries; } });
// Events — scheduled reminders.
var reminders_1 = require("./events/reminders");
Object.defineProperty(exports, "sendEventReminders", { enumerable: true, get: function () { return reminders_1.sendEventReminders; } });
// Events — auto-publish due scheduled events (triggers follower/community fan-out).
var autoPublish_1 = require("./events/autoPublish");
Object.defineProperty(exports, "autoPublishScheduledEvents", { enumerable: true, get: function () { return autoPublish_1.autoPublishScheduledEvents; } });
// Wallet passes (Apple .pkpass + Google Wallet) are REMOVED for now — the
// pass certificates / issuer secrets are not configured. Re-export from
// ./wallet/appleWallet & ./wallet/googleWallet once the wallet secrets
// (APPLE_PASS_CERT/KEY/..., GOOGLE_WALLET_*) are set to re-enable.
// Backup and Export Functions
var conversationBackup_1 = require("./backup/conversationBackup");
Object.defineProperty(exports, "backupConversation", { enumerable: true, get: function () { return conversationBackup_1.backupConversation; } });
Object.defineProperty(exports, "restoreConversation", { enumerable: true, get: function () { return conversationBackup_1.restoreConversation; } });
Object.defineProperty(exports, "listBackups", { enumerable: true, get: function () { return conversationBackup_1.listBackups; } });
Object.defineProperty(exports, "deleteBackup", { enumerable: true, get: function () { return conversationBackup_1.deleteBackup; } });
Object.defineProperty(exports, "autoBackupConversations", { enumerable: true, get: function () { return conversationBackup_1.autoBackupConversations; } });
var pdfExport_1 = require("./backup/pdfExport");
Object.defineProperty(exports, "exportConversationToPDF", { enumerable: true, get: function () { return pdfExport_1.exportConversationToPDF; } });
Object.defineProperty(exports, "listPDFExports", { enumerable: true, get: function () { return pdfExport_1.listPDFExports; } });
Object.defineProperty(exports, "cleanupExpiredExports", { enumerable: true, get: function () { return pdfExport_1.cleanupExpiredExports; } });
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
var index_1 = require("./subscription/index");
Object.defineProperty(exports, "verifyPurchase", { enumerable: true, get: function () { return index_1.verifyPurchase; } });
Object.defineProperty(exports, "checkExpiringMemberships", { enumerable: true, get: function () { return index_1.checkExpiringSubscriptions; } });
Object.defineProperty(exports, "handleExpiredMemberships", { enumerable: true, get: function () { return index_1.handleExpiredMemberships; } });
// Auto-renewable subscription server notifications (renewals/cancel/refund/expiry).
// Inert until the store notification URLs are pointed at these endpoints.
var storeNotifications_1 = require("./subscription/storeNotifications");
Object.defineProperty(exports, "appStoreNotificationsV2", { enumerable: true, get: function () { return storeNotifications_1.appStoreNotificationsV2; } });
Object.defineProperty(exports, "playStoreNotifications", { enumerable: true, get: function () { return storeNotifications_1.playStoreNotifications; } });
// Stripe Web Payments — coin packages + memberships via Stripe Checkout
// (web has no in-app-purchase plugin). Inert until STRIPE_SECRET_KEY is set.
var stripeCheckout_1 = require("./payments/stripeCheckout");
Object.defineProperty(exports, "createStripeCheckoutSession", { enumerable: true, get: function () { return stripeCheckout_1.createStripeCheckoutSession; } });
Object.defineProperty(exports, "stripeWebhook", { enumerable: true, get: function () { return stripeCheckout_1.stripeWebhook; } });
// Coin Functions
var coinManager_1 = require("./coins/coinManager");
Object.defineProperty(exports, "verifyGooglePlayCoinPurchase", { enumerable: true, get: function () { return coinManager_1.verifyGooglePlayCoinPurchase; } });
Object.defineProperty(exports, "verifyAppStoreCoinPurchase", { enumerable: true, get: function () { return coinManager_1.verifyAppStoreCoinPurchase; } });
Object.defineProperty(exports, "grantMonthlyAllowances", { enumerable: true, get: function () { return coinManager_1.grantMonthlyAllowances; } });
Object.defineProperty(exports, "processExpiredCoins", { enumerable: true, get: function () { return coinManager_1.processExpiredCoins; } });
Object.defineProperty(exports, "sendExpirationWarnings", { enumerable: true, get: function () { return coinManager_1.sendExpirationWarnings; } });
Object.defineProperty(exports, "claimReward", { enumerable: true, get: function () { return coinManager_1.claimReward; } });
// Coupon Redemption + Admin Management
var redeemCoupon_1 = require("./coupons/redeemCoupon");
Object.defineProperty(exports, "redeemCoupon", { enumerable: true, get: function () { return redeemCoupon_1.redeemCoupon; } });
var validateCoupon_1 = require("./coupons/validateCoupon");
Object.defineProperty(exports, "validateCoupon", { enumerable: true, get: function () { return validateCoupon_1.validateCoupon; } });
var redeemReferral_1 = require("./referral/redeemReferral");
Object.defineProperty(exports, "redeemReferral", { enumerable: true, get: function () { return redeemReferral_1.redeemReferral; } });
var adminCoupons_1 = require("./coupons/adminCoupons");
Object.defineProperty(exports, "upsertCoupon", { enumerable: true, get: function () { return adminCoupons_1.upsertCoupon; } });
Object.defineProperty(exports, "listCoupons", { enumerable: true, get: function () { return adminCoupons_1.listCoupons; } });
Object.defineProperty(exports, "getCouponRedemptions", { enumerable: true, get: function () { return adminCoupons_1.getCouponRedemptions; } });
Object.defineProperty(exports, "setCouponDisabled", { enumerable: true, get: function () { return adminCoupons_1.setCouponDisabled; } });
var applySignupGrants_1 = require("./coupons/applySignupGrants");
Object.defineProperty(exports, "applySignupGrants", { enumerable: true, get: function () { return applySignupGrants_1.applySignupGrants; } });
// Analytics Functions
var revenueAnalytics_1 = require("./analytics/revenueAnalytics");
Object.defineProperty(exports, "getRevenueDashboard", { enumerable: true, get: function () { return revenueAnalytics_1.getRevenueDashboard; } });
Object.defineProperty(exports, "exportRevenueData", { enumerable: true, get: function () { return revenueAnalytics_1.exportRevenueData; } });
var cohortAnalytics_1 = require("./analytics/cohortAnalytics");
Object.defineProperty(exports, "getCohortAnalysis", { enumerable: true, get: function () { return cohortAnalytics_1.getCohortAnalysis; } });
var churnPrediction_1 = require("./analytics/churnPrediction");
Object.defineProperty(exports, "trainChurnModel", { enumerable: true, get: function () { return churnPrediction_1.trainChurnModel; } });
Object.defineProperty(exports, "predictChurnDaily", { enumerable: true, get: function () { return churnPrediction_1.predictChurnDaily; } });
Object.defineProperty(exports, "getUserChurnPrediction", { enumerable: true, get: function () { return churnPrediction_1.getUserChurnPrediction; } });
Object.defineProperty(exports, "getAtRiskUsers", { enumerable: true, get: function () { return churnPrediction_1.getAtRiskUsers; } });
var advancedAnalytics_1 = require("./analytics/advancedAnalytics");
Object.defineProperty(exports, "createABTest", { enumerable: true, get: function () { return advancedAnalytics_1.createABTest; } });
Object.defineProperty(exports, "assignUserToTest", { enumerable: true, get: function () { return advancedAnalytics_1.assignUserToTest; } });
Object.defineProperty(exports, "recordConversion", { enumerable: true, get: function () { return advancedAnalytics_1.recordConversion; } });
Object.defineProperty(exports, "getABTestResults", { enumerable: true, get: function () { return advancedAnalytics_1.getABTestResults; } });
Object.defineProperty(exports, "detectFraud", { enumerable: true, get: function () { return advancedAnalytics_1.detectFraud; } });
Object.defineProperty(exports, "forecastMRR", { enumerable: true, get: function () { return advancedAnalytics_1.forecastMRR; } });
Object.defineProperty(exports, "getARPU", { enumerable: true, get: function () { return advancedAnalytics_1.getARPU; } });
Object.defineProperty(exports, "getRefundAnalytics", { enumerable: true, get: function () { return advancedAnalytics_1.getRefundAnalytics; } });
Object.defineProperty(exports, "calculateTax", { enumerable: true, get: function () { return advancedAnalytics_1.calculateTax; } });
Object.defineProperty(exports, "getTaxReport", { enumerable: true, get: function () { return advancedAnalytics_1.getTaxReport; } });
// Gamification Functions
var gamificationManager_1 = require("./gamification/gamificationManager");
Object.defineProperty(exports, "grantXP", { enumerable: true, get: function () { return gamificationManager_1.grantXP; } });
Object.defineProperty(exports, "trackAchievementProgress", { enumerable: true, get: function () { return gamificationManager_1.trackAchievementProgress; } });
Object.defineProperty(exports, "unlockAchievementReward", { enumerable: true, get: function () { return gamificationManager_1.unlockAchievementReward; } });
Object.defineProperty(exports, "claimLevelRewards", { enumerable: true, get: function () { return gamificationManager_1.claimLevelRewards; } });
Object.defineProperty(exports, "trackChallengeProgress", { enumerable: true, get: function () { return gamificationManager_1.trackChallengeProgress; } });
Object.defineProperty(exports, "claimChallengeReward", { enumerable: true, get: function () { return gamificationManager_1.claimChallengeReward; } });
Object.defineProperty(exports, "resetDailyChallenges", { enumerable: true, get: function () { return gamificationManager_1.resetDailyChallenges; } });
Object.defineProperty(exports, "updateLeaderboardRankings", { enumerable: true, get: function () { return gamificationManager_1.updateLeaderboardRankings; } });
// Safety & Moderation Functions
var contentModeration_1 = require("./safety/contentModeration");
Object.defineProperty(exports, "moderatePhoto", { enumerable: true, get: function () { return contentModeration_1.moderatePhoto; } });
Object.defineProperty(exports, "moderateText", { enumerable: true, get: function () { return contentModeration_1.moderateText; } });
Object.defineProperty(exports, "detectSpam", { enumerable: true, get: function () { return contentModeration_1.detectSpam; } });
Object.defineProperty(exports, "detectFakeProfile", { enumerable: true, get: function () { return contentModeration_1.detectFakeProfile; } });
Object.defineProperty(exports, "detectScam", { enumerable: true, get: function () { return contentModeration_1.detectScam; } });
var reportingSystem_1 = require("./safety/reportingSystem");
Object.defineProperty(exports, "submitReport", { enumerable: true, get: function () { return reportingSystem_1.submitReport; } });
Object.defineProperty(exports, "reviewReport", { enumerable: true, get: function () { return reportingSystem_1.reviewReport; } });
Object.defineProperty(exports, "submitAppeal", { enumerable: true, get: function () { return reportingSystem_1.submitAppeal; } });
Object.defineProperty(exports, "blockUser", { enumerable: true, get: function () { return reportingSystem_1.blockUser; } });
Object.defineProperty(exports, "unblockUser", { enumerable: true, get: function () { return reportingSystem_1.unblockUser; } });
Object.defineProperty(exports, "getBlockList", { enumerable: true, get: function () { return reportingSystem_1.getBlockList; } });
// Safety — maintain reportCount on reported users (Admin SDK).
var reportCountTrigger_1 = require("./safety/reportCountTrigger");
Object.defineProperty(exports, "onUserReportCreated", { enumerable: true, get: function () { return reportCountTrigger_1.onUserReportCreated; } });
var identityVerification_1 = require("./safety/identityVerification");
Object.defineProperty(exports, "startPhotoVerification", { enumerable: true, get: function () { return identityVerification_1.startPhotoVerification; } });
Object.defineProperty(exports, "verifyPhotoSelfie", { enumerable: true, get: function () { return identityVerification_1.verifyPhotoSelfie; } });
Object.defineProperty(exports, "verifyIDDocument", { enumerable: true, get: function () { return identityVerification_1.verifyIDDocument; } });
Object.defineProperty(exports, "calculateTrustScore", { enumerable: true, get: function () { return identityVerification_1.calculateTrustScore; } });
// Admin Panel Functions
var adminDashboard_1 = require("./admin/adminDashboard");
Object.defineProperty(exports, "getUserActivityMetrics", { enumerable: true, get: function () { return adminDashboard_1.getUserActivityMetrics; } });
Object.defineProperty(exports, "getUserGrowthChart", { enumerable: true, get: function () { return adminDashboard_1.getUserGrowthChart; } });
Object.defineProperty(exports, "getRevenueMetrics", { enumerable: true, get: function () { return adminDashboard_1.getRevenueMetrics; } });
Object.defineProperty(exports, "getEngagementMetrics", { enumerable: true, get: function () { return adminDashboard_1.getEngagementMetrics; } });
Object.defineProperty(exports, "getGeographicHeatmap", { enumerable: true, get: function () { return adminDashboard_1.getGeographicHeatmap; } });
Object.defineProperty(exports, "getSystemHealthMetrics", { enumerable: true, get: function () { return adminDashboard_1.getSystemHealthMetrics; } });
Object.defineProperty(exports, "createSystemAlert", { enumerable: true, get: function () { return adminDashboard_1.createSystemAlert; } });
Object.defineProperty(exports, "resolveSystemAlert", { enumerable: true, get: function () { return adminDashboard_1.resolveSystemAlert; } });
Object.defineProperty(exports, "getAdminAuditLog", { enumerable: true, get: function () { return adminDashboard_1.getAdminAuditLog; } });
var roleManagement_1 = require("./admin/roleManagement");
Object.defineProperty(exports, "createAdminUser", { enumerable: true, get: function () { return roleManagement_1.createAdminUser; } });
Object.defineProperty(exports, "updateAdminRole", { enumerable: true, get: function () { return roleManagement_1.updateAdminRole; } });
Object.defineProperty(exports, "updateAdminPermissions", { enumerable: true, get: function () { return roleManagement_1.updateAdminPermissions; } });
Object.defineProperty(exports, "deactivateAdminUser", { enumerable: true, get: function () { return roleManagement_1.deactivateAdminUser; } });
Object.defineProperty(exports, "getAdminUsers", { enumerable: true, get: function () { return roleManagement_1.getAdminUsers; } });
Object.defineProperty(exports, "recordAdminLogin", { enumerable: true, get: function () { return roleManagement_1.recordAdminLogin; } });
var userManagement_1 = require("./admin/userManagement");
Object.defineProperty(exports, "searchUsers", { enumerable: true, get: function () { return userManagement_1.searchUsers; } });
Object.defineProperty(exports, "getDetailedUserProfile", { enumerable: true, get: function () { return userManagement_1.getDetailedUserProfile; } });
Object.defineProperty(exports, "editUserProfile", { enumerable: true, get: function () { return userManagement_1.editUserProfile; } });
Object.defineProperty(exports, "suspendUserAccount", { enumerable: true, get: function () { return userManagement_1.suspendUserAccount; } });
Object.defineProperty(exports, "unsuspendUserAccount", { enumerable: true, get: function () { return userManagement_1.unsuspendUserAccount; } });
Object.defineProperty(exports, "banUserAccount", { enumerable: true, get: function () { return userManagement_1.banUserAccount; } });
Object.defineProperty(exports, "unbanUserAccount", { enumerable: true, get: function () { return userManagement_1.unbanUserAccount; } });
Object.defineProperty(exports, "deleteUserAccount", { enumerable: true, get: function () { return userManagement_1.deleteUserAccount; } });
Object.defineProperty(exports, "overrideUserSubscription", { enumerable: true, get: function () { return userManagement_1.overrideUserSubscription; } });
Object.defineProperty(exports, "adjustUserCoins", { enumerable: true, get: function () { return userManagement_1.adjustUserCoins; } });
Object.defineProperty(exports, "sendUserNotification", { enumerable: true, get: function () { return userManagement_1.sendUserNotification; } });
Object.defineProperty(exports, "impersonateUser", { enumerable: true, get: function () { return userManagement_1.impersonateUser; } });
Object.defineProperty(exports, "executeMassAction", { enumerable: true, get: function () { return userManagement_1.executeMassAction; } });
Object.defineProperty(exports, "adminBulkDeleteUsers", { enumerable: true, get: function () { return userManagement_1.adminBulkDeleteUsers; } });
var moderationQueue_1 = require("./admin/moderationQueue");
Object.defineProperty(exports, "getModerationQueue", { enumerable: true, get: function () { return moderationQueue_1.getModerationQueue; } });
Object.defineProperty(exports, "getModerationReviewItem", { enumerable: true, get: function () { return moderationQueue_1.getModerationReviewItem; } });
Object.defineProperty(exports, "assignModerationItem", { enumerable: true, get: function () { return moderationQueue_1.assignModerationItem; } });
Object.defineProperty(exports, "takeModerationAction", { enumerable: true, get: function () { return moderationQueue_1.takeModerationAction; } });
Object.defineProperty(exports, "executeBulkModeration", { enumerable: true, get: function () { return moderationQueue_1.executeBulkModeration; } });
Object.defineProperty(exports, "getModerationStatistics", { enumerable: true, get: function () { return moderationQueue_1.getModerationStatistics; } });
// User Segmentation Functions
var userSegmentation_1 = require("./analytics/userSegmentation");
Object.defineProperty(exports, "calculateUserSegment", { enumerable: true, get: function () { return userSegmentation_1.calculateUserSegment; } });
Object.defineProperty(exports, "createUserCohort", { enumerable: true, get: function () { return userSegmentation_1.createUserCohort; } });
Object.defineProperty(exports, "calculateCohortRetention", { enumerable: true, get: function () { return userSegmentation_1.calculateCohortRetention; } });
Object.defineProperty(exports, "predictUserChurn", { enumerable: true, get: function () { return userSegmentation_1.predictUserChurn; } });
Object.defineProperty(exports, "batchChurnPrediction", { enumerable: true, get: function () { return userSegmentation_1.batchChurnPrediction; } });
// Notification Functions
var pushNotifications_1 = require("./notifications/pushNotifications");
Object.defineProperty(exports, "sendPushNotification", { enumerable: true, get: function () { return pushNotifications_1.sendPushNotification; } });
Object.defineProperty(exports, "sendBundledNotifications", { enumerable: true, get: function () { return pushNotifications_1.sendBundledNotifications; } });
Object.defineProperty(exports, "trackNotificationOpened", { enumerable: true, get: function () { return pushNotifications_1.trackNotificationOpened; } });
Object.defineProperty(exports, "getNotificationAnalytics", { enumerable: true, get: function () { return pushNotifications_1.getNotificationAnalytics; } });
// Push Notification Firestore Triggers (likes, matches, messages, support, verification, mode expiry)
var pushNotificationTriggers_1 = require("./notifications/pushNotificationTriggers");
Object.defineProperty(exports, "onNewLikePush", { enumerable: true, get: function () { return pushNotificationTriggers_1.onNewLikePush; } });
Object.defineProperty(exports, "onNewMatchPush", { enumerable: true, get: function () { return pushNotificationTriggers_1.onNewMatchPush; } });
Object.defineProperty(exports, "onNewMessagePush", { enumerable: true, get: function () { return pushNotificationTriggers_1.onNewMessagePush; } });
Object.defineProperty(exports, "onSupportMessagePush", { enumerable: true, get: function () { return pushNotificationTriggers_1.onSupportMessagePush; } });
Object.defineProperty(exports, "checkExpiringModes", { enumerable: true, get: function () { return pushNotificationTriggers_1.checkExpiringModes; } });
Object.defineProperty(exports, "onVerificationStatusChange", { enumerable: true, get: function () { return pushNotificationTriggers_1.onVerificationStatusChange; } });
// Email Communication Functions (Legacy - SendGrid)
var emailCommunication_1 = require("./notifications/emailCommunication");
Object.defineProperty(exports, "sendTransactionalEmail", { enumerable: true, get: function () { return emailCommunication_1.sendTransactionalEmail; } });
Object.defineProperty(exports, "startWelcomeEmailSeries", { enumerable: true, get: function () { return emailCommunication_1.startWelcomeEmailSeries; } });
Object.defineProperty(exports, "processWelcomeEmailSeries", { enumerable: true, get: function () { return emailCommunication_1.processWelcomeEmailSeries; } });
Object.defineProperty(exports, "sendWeeklyDigestEmails", { enumerable: true, get: function () { return emailCommunication_1.sendWeeklyDigestEmails; } });
Object.defineProperty(exports, "sendReEngagementCampaign", { enumerable: true, get: function () { return emailCommunication_1.sendReEngagementCampaign; } });
// Brevo Email Service (Primary)
var brevoEmailService_1 = require("./notifications/brevoEmailService");
Object.defineProperty(exports, "sendBrevoEmailFunction", { enumerable: true, get: function () { return brevoEmailService_1.sendBrevoEmailFunction; } });
Object.defineProperty(exports, "getBrevoEmailTemplates", { enumerable: true, get: function () { return brevoEmailService_1.getBrevoEmailTemplates; } });
Object.defineProperty(exports, "updateBrevoEmailTemplate", { enumerable: true, get: function () { return brevoEmailService_1.updateBrevoEmailTemplate; } });
Object.defineProperty(exports, "getBrevoEmailLogs", { enumerable: true, get: function () { return brevoEmailService_1.getBrevoEmailLogs; } });
Object.defineProperty(exports, "getBrevoEmailAnalytics", { enumerable: true, get: function () { return brevoEmailService_1.getBrevoEmailAnalytics; } });
Object.defineProperty(exports, "onUserCreatedSendWelcome", { enumerable: true, get: function () { return brevoEmailService_1.onUserCreatedSendWelcome; } });
Object.defineProperty(exports, "onSubscriptionUpdated", { enumerable: true, get: function () { return brevoEmailService_1.onSubscriptionUpdated; } });
Object.defineProperty(exports, "onPhotoModerationUpdated", { enumerable: true, get: function () { return brevoEmailService_1.onPhotoModerationUpdated; } });
Object.defineProperty(exports, "onAchievementUnlocked", { enumerable: true, get: function () { return brevoEmailService_1.onAchievementUnlocked; } });
Object.defineProperty(exports, "onNewMatch", { enumerable: true, get: function () { return brevoEmailService_1.onNewMatch; } });
Object.defineProperty(exports, "onPurchaseCreated", { enumerable: true, get: function () { return brevoEmailService_1.onPurchaseCreated; } });
Object.defineProperty(exports, "sendBrevoWeeklyDigest", { enumerable: true, get: function () { return brevoEmailService_1.sendBrevoWeeklyDigest; } });
Object.defineProperty(exports, "sendBrevoReEngagement", { enumerable: true, get: function () { return brevoEmailService_1.sendBrevoReEngagement; } });
Object.defineProperty(exports, "sendBrevoStreakReminder", { enumerable: true, get: function () { return brevoEmailService_1.sendBrevoStreakReminder; } });
// Video Calling Functions
var videoCalling_1 = require("./video_calling/videoCalling");
Object.defineProperty(exports, "initiateVideoCall", { enumerable: true, get: function () { return videoCalling_1.initiateVideoCall; } });
Object.defineProperty(exports, "answerVideoCall", { enumerable: true, get: function () { return videoCalling_1.answerVideoCall; } });
Object.defineProperty(exports, "endVideoCall", { enumerable: true, get: function () { return videoCalling_1.endVideoCall; } });
Object.defineProperty(exports, "handleCallSignal", { enumerable: true, get: function () { return videoCalling_1.handleCallSignal; } });
Object.defineProperty(exports, "updateCallQuality", { enumerable: true, get: function () { return videoCalling_1.updateCallQuality; } });
Object.defineProperty(exports, "startCallRecording", { enumerable: true, get: function () { return videoCalling_1.startCallRecording; } });
// Video Call Features Functions
var videoCallFeatures_1 = require("./video_calling/videoCallFeatures");
Object.defineProperty(exports, "enableVirtualBackground", { enumerable: true, get: function () { return videoCallFeatures_1.enableVirtualBackground; } });
Object.defineProperty(exports, "applyARFilter", { enumerable: true, get: function () { return videoCallFeatures_1.applyARFilter; } });
Object.defineProperty(exports, "toggleBeautyMode", { enumerable: true, get: function () { return videoCallFeatures_1.toggleBeautyMode; } });
Object.defineProperty(exports, "enablePictureInPicture", { enumerable: true, get: function () { return videoCallFeatures_1.enablePictureInPicture; } });
Object.defineProperty(exports, "startScreenSharing", { enumerable: true, get: function () { return videoCallFeatures_1.startScreenSharing; } });
Object.defineProperty(exports, "stopScreenSharing", { enumerable: true, get: function () { return videoCallFeatures_1.stopScreenSharing; } });
Object.defineProperty(exports, "toggleNoiseSuppression", { enumerable: true, get: function () { return videoCallFeatures_1.toggleNoiseSuppression; } });
Object.defineProperty(exports, "toggleEchoCancellation", { enumerable: true, get: function () { return videoCallFeatures_1.toggleEchoCancellation; } });
Object.defineProperty(exports, "sendInCallReaction", { enumerable: true, get: function () { return videoCallFeatures_1.sendInCallReaction; } });
Object.defineProperty(exports, "uploadCustomBackground", { enumerable: true, get: function () { return videoCallFeatures_1.uploadCustomBackground; } });
Object.defineProperty(exports, "getCallHistory", { enumerable: true, get: function () { return videoCallFeatures_1.getCallHistory; } });
Object.defineProperty(exports, "getCallStatistics", { enumerable: true, get: function () { return videoCallFeatures_1.getCallStatistics; } });
Object.defineProperty(exports, "cleanupExpiredReactions", { enumerable: true, get: function () { return videoCallFeatures_1.cleanupExpiredReactions; } });
// Group Video Call Functions
var groupVideoCalls_1 = require("./video_calling/groupVideoCalls");
Object.defineProperty(exports, "createGroupVideoCall", { enumerable: true, get: function () { return groupVideoCalls_1.createGroupVideoCall; } });
Object.defineProperty(exports, "joinGroupVideoCall", { enumerable: true, get: function () { return groupVideoCalls_1.joinGroupVideoCall; } });
Object.defineProperty(exports, "leaveGroupVideoCall", { enumerable: true, get: function () { return groupVideoCalls_1.leaveGroupVideoCall; } });
Object.defineProperty(exports, "manageGroupParticipant", { enumerable: true, get: function () { return groupVideoCalls_1.manageGroupParticipant; } });
Object.defineProperty(exports, "changeGroupCallLayout", { enumerable: true, get: function () { return groupVideoCalls_1.changeGroupCallLayout; } });
Object.defineProperty(exports, "createBreakoutRoom", { enumerable: true, get: function () { return groupVideoCalls_1.createBreakoutRoom; } });
Object.defineProperty(exports, "joinBreakoutRoom", { enumerable: true, get: function () { return groupVideoCalls_1.joinBreakoutRoom; } });
Object.defineProperty(exports, "closeBreakoutRoom", { enumerable: true, get: function () { return groupVideoCalls_1.closeBreakoutRoom; } });
// Security Audit Functions
var securityAudit_1 = require("./security/securityAudit");
Object.defineProperty(exports, "runSecurityAudit", { enumerable: true, get: function () { return securityAudit_1.runSecurityAudit; } });
Object.defineProperty(exports, "scheduledSecurityAudit", { enumerable: true, get: function () { return securityAudit_1.scheduledSecurityAudit; } });
Object.defineProperty(exports, "getSecurityAuditReport", { enumerable: true, get: function () { return securityAudit_1.getSecurityAuditReport; } });
Object.defineProperty(exports, "listSecurityAuditReports", { enumerable: true, get: function () { return securityAudit_1.listSecurityAuditReports; } });
Object.defineProperty(exports, "cleanupOldAuditReports", { enumerable: true, get: function () { return securityAudit_1.cleanupOldAuditReports; } });
// Language Learning Functions
var languageLearningManager_1 = require("./language_learning/languageLearningManager");
Object.defineProperty(exports, "submitTeacherApplication", { enumerable: true, get: function () { return languageLearningManager_1.submitTeacherApplication; } });
Object.defineProperty(exports, "reviewTeacherApplication", { enumerable: true, get: function () { return languageLearningManager_1.reviewTeacherApplication; } });
Object.defineProperty(exports, "createLesson", { enumerable: true, get: function () { return languageLearningManager_1.createLesson; } });
Object.defineProperty(exports, "publishLesson", { enumerable: true, get: function () { return languageLearningManager_1.publishLesson; } });
Object.defineProperty(exports, "purchaseLesson", { enumerable: true, get: function () { return languageLearningManager_1.purchaseLesson; } });
Object.defineProperty(exports, "updateLessonProgress", { enumerable: true, get: function () { return languageLearningManager_1.updateLessonProgress; } });
Object.defineProperty(exports, "getLearningAnalytics", { enumerable: true, get: function () { return languageLearningManager_1.getLearningAnalytics; } });
Object.defineProperty(exports, "getUserProgressReport", { enumerable: true, get: function () { return languageLearningManager_1.getUserProgressReport; } });
Object.defineProperty(exports, "getTeacherAnalytics", { enumerable: true, get: function () { return languageLearningManager_1.getTeacherAnalytics; } });
// Admin API
Object.defineProperty(exports, "getAdminLessons", { enumerable: true, get: function () { return languageLearningManager_1.getAdminLessons; } });
Object.defineProperty(exports, "seedLessons", { enumerable: true, get: function () { return languageLearningManager_1.seedLessons; } });
Object.defineProperty(exports, "deleteLesson", { enumerable: true, get: function () { return languageLearningManager_1.deleteLesson; } });
Object.defineProperty(exports, "updateLesson", { enumerable: true, get: function () { return languageLearningManager_1.updateLesson; } });
Object.defineProperty(exports, "getLessonStats", { enumerable: true, get: function () { return languageLearningManager_1.getLessonStats; } });
// Discovery / Candidate Pool Functions
var candidatePoolPrecompute_1 = require("./discovery/candidatePoolPrecompute");
Object.defineProperty(exports, "precomputeCandidatePools", { enumerable: true, get: function () { return candidatePoolPrecompute_1.precomputeCandidatePools; } });
Object.defineProperty(exports, "triggerPoolRecompute", { enumerable: true, get: function () { return candidatePoolPrecompute_1.triggerPoolRecompute; } });
Object.defineProperty(exports, "getCandidatePoolStats", { enumerable: true, get: function () { return candidatePoolPrecompute_1.getCandidatePoolStats; } });
// Presence / Location Enrichment Functions
var onPresenceUpdate_1 = require("./presence/onPresenceUpdate");
Object.defineProperty(exports, "onPresenceUpdate", { enumerable: true, get: function () { return onPresenceUpdate_1.onPresenceUpdate; } });
// Presence Cleanup (Scheduled)
var cleanupStalePresence_1 = require("./presence/cleanupStalePresence");
Object.defineProperty(exports, "cleanupStalePresence", { enumerable: true, get: function () { return cleanupStalePresence_1.cleanupStalePresence; } });
// MVP Access Control Functions
var mvp_access_1 = require("./admin/mvp_access");
Object.defineProperty(exports, "approveUser", { enumerable: true, get: function () { return mvp_access_1.approveUser; } });
Object.defineProperty(exports, "rejectUser", { enumerable: true, get: function () { return mvp_access_1.rejectUser; } });
Object.defineProperty(exports, "updateUserTier", { enumerable: true, get: function () { return mvp_access_1.updateUserTier; } });
Object.defineProperty(exports, "getPendingUsers", { enumerable: true, get: function () { return mvp_access_1.getPendingUsers; } });
Object.defineProperty(exports, "bulkApproveUsers", { enumerable: true, get: function () { return mvp_access_1.bulkApproveUsers; } });
Object.defineProperty(exports, "sendBroadcastNotification", { enumerable: true, get: function () { return mvp_access_1.sendBroadcastNotification; } });
Object.defineProperty(exports, "sendNotificationToUser", { enumerable: true, get: function () { return mvp_access_1.sendNotificationToUser; } });
Object.defineProperty(exports, "getMvpAccessStats", { enumerable: true, get: function () { return mvp_access_1.getMvpAccessStats; } });
// Admin Panel Functions (2FA, password mgmt, user mgmt, AI support)
var adminPanelFunctions_1 = require("./admin/adminPanelFunctions");
Object.defineProperty(exports, "send2FACode", { enumerable: true, get: function () { return adminPanelFunctions_1.send2FACode; } });
Object.defineProperty(exports, "verify2FACode", { enumerable: true, get: function () { return adminPanelFunctions_1.verify2FACode; } });
Object.defineProperty(exports, "adminChangeUserPassword", { enumerable: true, get: function () { return adminPanelFunctions_1.adminChangeUserPassword; } });
Object.defineProperty(exports, "sendPasswordResetEmail", { enumerable: true, get: function () { return adminPanelFunctions_1.sendPasswordResetEmail; } });
Object.defineProperty(exports, "forcePasswordChange", { enumerable: true, get: function () { return adminPanelFunctions_1.forcePasswordChange; } });
Object.defineProperty(exports, "adminDeleteUser", { enumerable: true, get: function () { return adminPanelFunctions_1.adminDeleteUser; } });
Object.defineProperty(exports, "adminSetUserDisabled", { enumerable: true, get: function () { return adminPanelFunctions_1.adminSetUserDisabled; } });
Object.defineProperty(exports, "sendTestEmail", { enumerable: true, get: function () { return adminPanelFunctions_1.sendTestEmail; } });
Object.defineProperty(exports, "processAISupportMessage", { enumerable: true, get: function () { return adminPanelFunctions_1.processAISupportMessage; } });
Object.defineProperty(exports, "onSupportChatCreated", { enumerable: true, get: function () { return adminPanelFunctions_1.onSupportChatCreated; } });
Object.defineProperty(exports, "onSupportMessageCreated", { enumerable: true, get: function () { return adminPanelFunctions_1.onSupportMessageCreated; } });
Object.defineProperty(exports, "cleanupOrphanedAuthUser", { enumerable: true, get: function () { return adminPanelFunctions_1.cleanupOrphanedAuthUser; } });
Object.defineProperty(exports, "sendWelcomeEmail", { enumerable: true, get: function () { return adminPanelFunctions_1.sendWelcomeEmail; } });
Object.defineProperty(exports, "sendPasswordResetViaResend", { enumerable: true, get: function () { return adminPanelFunctions_1.sendPasswordResetViaResend; } });
Object.defineProperty(exports, "reverseGeocodeProfileLocation", { enumerable: true, get: function () { return adminPanelFunctions_1.reverseGeocodeProfileLocation; } });
//# sourceMappingURL=index.js.map