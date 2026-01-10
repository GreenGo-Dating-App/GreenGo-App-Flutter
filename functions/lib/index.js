"use strict";
/**
 * GreenGoChat Cloud Functions
 * Entry point for all Firebase Cloud Functions
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRefundAnalytics = exports.getARPU = exports.forecastMRR = exports.detectFraud = exports.getABTestResults = exports.recordConversion = exports.assignUserToTest = exports.createABTest = exports.getAtRiskUsers = exports.getUserChurnPrediction = exports.predictChurnDaily = exports.trainChurnModel = exports.getCohortAnalysis = exports.exportRevenueData = exports.getRevenueDashboard = exports.claimReward = exports.sendExpirationWarnings = exports.processExpiredCoins = exports.grantMonthlyAllowances = exports.verifyAppStoreCoinPurchase = exports.verifyGooglePlayCoinPurchase = exports.handleExpiredGracePeriods = exports.checkExpiringSubscriptions = exports.handleAppStoreWebhook = exports.handlePlayStoreWebhook = exports.cleanupExpiredExports = exports.listPDFExports = exports.exportConversationToPDF = exports.autoBackupConversations = exports.deleteBackup = exports.listBackups = exports.restoreConversation = exports.backupConversation = exports.getScheduledMessages = exports.cancelScheduledMessage = exports.scheduleMessage = exports.sendScheduledMessages = exports.getSupportedLanguages = exports.batchTranslateMessages = exports.autoTranslateMessage = exports.translateMessage = exports.markMediaAsDisappearing = exports.cleanupDisappearingMedia = exports.batchTranscribe = exports.transcribeAudio = exports.transcribeVoiceMessage = exports.generateVideoThumbnail = exports.processUploadedVideo = exports.compressImage = exports.compressUploadedImage = void 0;
exports.adjustUserCoins = exports.overrideUserSubscription = exports.deleteUserAccount = exports.unbanUserAccount = exports.banUserAccount = exports.unsuspendUserAccount = exports.suspendUserAccount = exports.editUserProfile = exports.getDetailedUserProfile = exports.searchUsers = exports.recordAdminLogin = exports.getAdminUsers = exports.deactivateAdminUser = exports.updateAdminPermissions = exports.updateAdminRole = exports.createAdminUser = exports.getAdminAuditLog = exports.resolveSystemAlert = exports.createSystemAlert = exports.getSystemHealthMetrics = exports.getGeographicHeatmap = exports.getEngagementMetrics = exports.getRevenueMetrics = exports.getUserGrowthChart = exports.getUserActivityMetrics = exports.calculateTrustScore = exports.verifyIDDocument = exports.verifyPhotoSelfie = exports.startPhotoVerification = exports.getBlockList = exports.unblockUser = exports.blockUser = exports.submitAppeal = exports.reviewReport = exports.submitReport = exports.detectScam = exports.detectFakeProfile = exports.detectSpam = exports.moderateText = exports.moderatePhoto = exports.updateLeaderboardRankings = exports.resetDailyChallenges = exports.claimChallengeReward = exports.trackChallengeProgress = exports.claimLevelRewards = exports.unlockAchievementReward = exports.trackAchievementProgress = exports.grantXP = exports.getTaxReport = exports.calculateTax = void 0;
exports.toggleNoiseSuppression = exports.stopScreenSharing = exports.startScreenSharing = exports.enablePictureInPicture = exports.toggleBeautyMode = exports.applyARFilter = exports.enableVirtualBackground = exports.startCallRecording = exports.updateCallQuality = exports.handleCallSignal = exports.endVideoCall = exports.answerVideoCall = exports.initiateVideoCall = exports.sendBrevoStreakReminder = exports.sendBrevoReEngagement = exports.sendBrevoWeeklyDigest = exports.onPurchaseCreated = exports.onNewMatch = exports.onAchievementUnlocked = exports.onPhotoModerationUpdated = exports.onSubscriptionUpdated = exports.onUserCreatedSendWelcome = exports.getBrevoEmailAnalytics = exports.getBrevoEmailLogs = exports.updateBrevoEmailTemplate = exports.getBrevoEmailTemplates = exports.sendBrevoEmailFunction = exports.sendReEngagementCampaign = exports.sendWeeklyDigestEmails = exports.processWelcomeEmailSeries = exports.startWelcomeEmailSeries = exports.sendTransactionalEmail = exports.getNotificationAnalytics = exports.trackNotificationOpened = exports.sendBundledNotifications = exports.sendPushNotification = exports.batchChurnPrediction = exports.predictUserChurn = exports.calculateCohortRetention = exports.createUserCohort = exports.calculateUserSegment = exports.getModerationStatistics = exports.executeBulkModeration = exports.takeModerationAction = exports.assignModerationItem = exports.getModerationReviewItem = exports.getModerationQueue = exports.executeMassAction = exports.impersonateUser = exports.sendUserNotification = void 0;
exports.getLessonStats = exports.updateLesson = exports.deleteLesson = exports.seedLessons = exports.getAdminLessons = exports.getTeacherAnalytics = exports.getUserProgressReport = exports.getLearningAnalytics = exports.updateLessonProgress = exports.purchaseLesson = exports.publishLesson = exports.createLesson = exports.reviewTeacherApplication = exports.submitTeacherApplication = exports.cleanupOldAuditReports = exports.listSecurityAuditReports = exports.getSecurityAuditReport = exports.scheduledSecurityAudit = exports.runSecurityAudit = exports.closeBreakoutRoom = exports.joinBreakoutRoom = exports.createBreakoutRoom = exports.changeGroupCallLayout = exports.manageGroupParticipant = exports.leaveGroupVideoCall = exports.joinGroupVideoCall = exports.createGroupVideoCall = exports.cleanupExpiredReactions = exports.getCallStatistics = exports.getCallHistory = exports.uploadCustomBackground = exports.sendInCallReaction = exports.toggleEchoCancellation = void 0;
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
// Subscription Functions
var subscriptionManager_1 = require("./subscriptions/subscriptionManager");
Object.defineProperty(exports, "handlePlayStoreWebhook", { enumerable: true, get: function () { return subscriptionManager_1.handlePlayStoreWebhook; } });
Object.defineProperty(exports, "handleAppStoreWebhook", { enumerable: true, get: function () { return subscriptionManager_1.handleAppStoreWebhook; } });
Object.defineProperty(exports, "checkExpiringSubscriptions", { enumerable: true, get: function () { return subscriptionManager_1.checkExpiringSubscriptions; } });
Object.defineProperty(exports, "handleExpiredGracePeriods", { enumerable: true, get: function () { return subscriptionManager_1.handleExpiredGracePeriods; } });
// Coin Functions
var coinManager_1 = require("./coins/coinManager");
Object.defineProperty(exports, "verifyGooglePlayCoinPurchase", { enumerable: true, get: function () { return coinManager_1.verifyGooglePlayCoinPurchase; } });
Object.defineProperty(exports, "verifyAppStoreCoinPurchase", { enumerable: true, get: function () { return coinManager_1.verifyAppStoreCoinPurchase; } });
Object.defineProperty(exports, "grantMonthlyAllowances", { enumerable: true, get: function () { return coinManager_1.grantMonthlyAllowances; } });
Object.defineProperty(exports, "processExpiredCoins", { enumerable: true, get: function () { return coinManager_1.processExpiredCoins; } });
Object.defineProperty(exports, "sendExpirationWarnings", { enumerable: true, get: function () { return coinManager_1.sendExpirationWarnings; } });
Object.defineProperty(exports, "claimReward", { enumerable: true, get: function () { return coinManager_1.claimReward; } });
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
//# sourceMappingURL=index.js.map