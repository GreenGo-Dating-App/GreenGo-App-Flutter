/**
 * GreenGoChat Cloud Functions
 * Entry point for all Firebase Cloud Functions
 */

// IMPORTANT: Import firebaseAdmin first to ensure initialization
import './shared/firebaseAdmin';
// v2 default memory 512MiB (M-27) - must stay before every function module.
import './shared/globalOptions';

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

// P1-3: membership-checked short-lived URLs for private chat media.
export { getMediaUrl } from './media/mediaAccess';

export {
  cleanupDisappearingMedia,
  markMediaAsDisappearing,
} from './media/disappearingMedia';

// Messaging Functions
export {
  translateMessage,
  // autoTranslateMessage removed (see messaging/translation.ts): delete the
  // deployed copy with `firebase functions:delete autoTranslateMessage`.
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

// Group cascade cleanup when an admin permanently deletes a group.
export {
  onGroupDeleted,
} from './group_chat/groupCleanup';

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

// Geoapify attractions ingester REMOVED — the app now serves curated
// attractions from the GreenGo dataset (see tools/attractions).
export { runCleanupNoImageNow } from './external_events/ingest';

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
  onCommunityEventChanged,
} from './communities/eventFanout';

// Communities — searchKeywords for server-side community search (onCreate fill).
export { onCommunityCreatedSearchKeywords } from './communities/searchKeywords';

// H3: debug/seed HTTP endpoints (backfillCommunityCreatorMembers, seedMockData,
// removeMockData, diagLiveEvents, diagCommunityEvents) REMOVED — they were
// guarded only by a committed static token (unauthenticated data-delete/spam).
// Deleted from prod via `firebase functions:delete` by name.

// H5: keep the orphaned-but-still-used gamification functions exported so a full
// `deploy --only functions` doesn't prune them (the app calls refreshMyStats and
// relies on the onMessageCreatedVocabulary trigger). NOTE: `getDisplayPrices` is
// prod-only (no source) — keep deploying by name until it is rebuilt in source.
export { refreshMyStats, onMessageCreatedVocabulary } from './gamification';
// P1-9: computeDailyUserStats was exported ONLY by the web repo (live source is
// byte-identical to this gamification/index.ts). The app repo is now its single
// source of truth; the web repo no longer exports it.
export { computeDailyUserStats } from './gamification';

// Account deletion cascade — on profiles/{uid} delete, fix stale counts, purge
// orphaned memberships/attendees/followers, delete the Auth user + Storage.
export {
  onProfileDeleted,
} from './admin/accountCleanup';

// Social notifications — actor-attributed (avatar + name) join/follow/rate/like.
export {
  onCommunityMemberJoined,
  onEventAttendeeJoined,
  onBusinessFollowed,
  onBusinessRated,
  onEventLiked,
} from './notifications/socialNotifications';

// Push parity — every in-app notifications doc without its own push gets one.
export {
  onNotificationCreatedPush,
} from './notifications/pushParity';
export {
  syncCitySubscribers,
  onEventCityAlert,
} from './notifications/cityAlerts';

// Engagement notifications — profile view (throttled), QR scan, boost start/end.
export {
  onProfileViewed,
  onTicketScanned,
  onProfileBoostStarted,
  onEventBoostStarted,
  checkBoostExpiries,
} from './notifications/engagementNotifications';

// Events — scheduled reminders.
export {
  sendEventReminders,
} from './events/reminders';

// Events — auto-publish due scheduled events (triggers follower/community fan-out).
export {
  autoPublishScheduledEvents,
} from './events/autoPublish';

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
  handleExpiredBaseMemberships,
} from './subscription/index';

// One-off membership tier migration ('BASIC' → 'FREE', expired paid tiers →
// FREE, Base fields repaired). Token from MEMBERSHIP_MIGRATION_TOKEN in the
// gitignored functions/.env; dry run unless ?dryRun=0. Delete after use.
export { runMembershipTierMigrationNow } from './subscription/membershipMigration';

// Auto-renewable subscription server notifications (renewals/cancel/refund/expiry).
// Inert until the store notification URLs are pointed at these endpoints.
export {
  appStoreNotificationsV2,
  playStoreNotifications,
} from './subscription/storeNotifications';

// Daily Google Play Voided Purchases API poll: refund/chargeback clawback
// backstop for the RTDN voidedPurchaseNotification (security audit H-10).
export { pollPlayVoidedPurchases } from './subscription/voidedPurchasesPoll';

// Stripe Web Payments — coin packages + memberships via Stripe Checkout
// (web has no in-app-purchase plugin). Inert until STRIPE_SECRET_KEY is set.
export {
  // createStripeCheckoutSession — deploys ONLY from greengo-app-flutter-web (this copy is stale)
  // stripeWebhook — deploys ONLY from greengo-app-flutter-web (this copy is stale)
} from './payments/stripeCheckout';

// Stripe reconciliation (every 12h) + token-guarded HTTP twin (dry run by
// default; token from STRIPE_RECONCILE_TOKEN in the gitignored functions/.env).
// payments/stripeReconcile.ts + payments/stripeCore.ts are byte-identical in
// both repos, so deploying these from either repo is equivalent.
export {
  // reconcileStripeMemberships — deploys ONLY from greengo-app-flutter-web (this copy is stale)
  // runStripeReconcileNow — deploys ONLY from greengo-app-flutter-web (this copy is stale)
} from './payments/stripeReconcile';

// Coin Functions
// Use the REAL coin functions (server-side receipt verification) from
// coins/index.ts — NOT coinManager.ts, whose verify was a `verified = true`
// stub (live free-coins exploit). coinManager.ts is deleted.
export {
  verifyGooglePlayCoinPurchase,
  verifyAppStoreCoinPurchase,
  claimReward,
  giftCoins,
  declineGift,
  // Security P1-1 (C-03/H-11/H-12): server-authoritative spending + escrow gifts.
  spendCoins,
  sendGift,
  acceptGift,
} from './coins';

// Coupon Redemption + Admin Management
export { redeemCoupon } from './coupons/redeemCoupon';
export { redeemReferral } from './referral/redeemReferral';
export {
  upsertCoupon,
  listCoupons,
  getCouponRedemptions,
} from './coupons/adminCoupons';
export { applySignupGrants } from './coupons/applySignupGrants';

// Tells the registration form what an email will receive (grants nothing).
export { checkPreRegistrationOffer } from './coupons/preRegistrationOffer';

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

// Server-side NSFW moderation of every user upload (Storage trigger).
export { moderateUploadedImage } from './safety/moderateUploadedImage';

// P2-8b: keyword screen of community / group / event chat messages ->
// moderation_queue (flag-for-review only, no automatic action).
export {
  screenCommunityMessage,
  screenGroupMessage,
  screenEventMessage,
} from './safety/autoTextModeration';

export {
  submitReport,
  reviewReport,
  submitAppeal,
  blockUser,
  unblockUser,
  getBlockList,
} from './safety/reportingSystem';

// Safety — maintain reportCount on reported users (Admin SDK).
export {
  onUserReportCreated,
} from './safety/reportCountTrigger';

// Safety — P1-12: every report (user_reports / message_reports / reports) becomes
// one moderation_queue item; P0 admin alert; reporter feedback on resolution.
export {
  onUserReportQueued,
  onMessageReportQueued,
  onContentReportQueued,
  onModerationQueueResolved,
} from './safety/reportPipeline';

// P2-6 / BIPA: startPhotoVerification, verifyPhotoSelfie (selfie face
// comparison via Cloud Vision) and verifyIDDocument (ID OCR without the
// retention controls of submitAgeDocument) were never called by any app,
// web or admin-panel version. Their exports are REMOVED; delete them from
// production with `firebase functions:delete` (coordinator).
export {
  calculateTrustScore,
} from './safety/identityVerification';

// Age Assurance Functions (Guidelines 2.3.6, 1.2.1, 4.7.5)
// Declared age for everyone; document verification on top; mandatory for
// phone-auth accounts; required to publish in Communities.
export {
  getAgeVerificationState,
  submitAgeDocument,
  reviewAgeVerification,
  getAgeVerificationDetails,
  backfillDeclaredAge,
} from './safety/ageAssurance';

// ID-document retention (fraud prevention; DRAFT — lawyer review): documents
// kept server-only, 30 days after replacement / account deletion, then purged.
export {
  purgeRetainedIdDocuments,
  setIdDocumentLegalHold,
  backfillIdVerifiedFlags,
} from './safety/idDocumentRetention';

// Banned / suspended hosts: hide their user experiences (restore on unban).
export { onProfileBanStateChanged } from './user_experiences/hostBan';

// Account deletion cascade (Guideline 5.1.1(v), GDPR Art. 17)
// Fires on auth deletion however it is triggered — app, admin panel, console.
export { onUserDeletedCleanup } from './auth/deleteUserData';

// Server-side account deletion (P1-10, audit H-15): website link flow
// (greengochat.com/delete-account) + app callable. One routine with the
// trigger above: ./auth/accountDeletion.ts.
export {
  requestAccountDeletion,
  confirmAccountDeletion,
  deleteMyAccount,
} from './auth/accountDeletionEndpoints';

// Data-subject access / portability (P3-2; GDPR Art. 15/20, LGPD Art. 18):
// ZIP of the caller's data in private exports/{uid}/, 24 h signed link,
// 1 per 24 h; exports deleted after 7 days.
export { exportMyData, cleanupDataExports } from './auth/dataExport';

// Server-side AI gateway (C-08 follow-up, H-17, P2-10): Gemini, Cloud TTS,
// Cloud Translation and image lookups with server-held keys, consent check,
// input caps and per-user daily quotas; AI-processing consent record.
export {
  aiAssist,
  synthesizeSpeech,
  translatePrivateText,
  getVocabularyImages,
  recordConsent,
} from './ai/aiGateway';

// Neutral age gate, interim (H-21). The profile-trigger backstop runs inside
// reverseGeocodeProfileLocation.
export { declareAge } from './auth/ageGate';

// Regional strong age assurance (P3-1, H-21): BR / GB / US-TX when
// app_config/feature_flags.ageAssuranceEnforced is on.
export {
  getAgeAssuranceStatus,
  recordStoreAgeSignal,
  setAgeAssuranceOverride,
} from './safety/ageAssuranceGate';

// Release bonus. Moved off the client when the profile rules stopped
// allowing users to write their own entitlement fields.
export { claimReleaseBonus } from './subscription/claimReleaseBonus';

// Direct entitlement grants — the Guideline 3.1.1-safe replacement for coupon
// codes. An admin gives the entitlement; the user redeems nothing.
export {
  grantEntitlement,
  listEntitlementGrants,
} from './admin/grantEntitlement';

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

// Push Notification Firestore Triggers (messages, support, verification, mode expiry).
// Dating triggers onNewLikePush / onNewMatchPush removed (networking app).
export {
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
  onPurchaseCreated,
  sendBrevoWeeklyDigest,
  sendBrevoReEngagement,
  sendBrevoStreakReminder,
} from './notifications/brevoEmailService';

// P2-5b: one-click unsubscribe from marketing e-mail (link + List-Unsubscribe).
export { unsubscribeMarketing } from './notifications/marketingUnsubscribe';




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

// Discovery: profile geohash backfill (admin-only callable; no onWrite trigger)
export { backfillProfileGeohash } from './discovery/profileGeohash';
// Private profile split (audit C-07 / C-10, plan P1-4).
export {
  mirrorPrivateProfileFields,
  syncCoarseFromPrivateProfile,
  refreshBirthdayAges,
  getVerificationPhotoUrl,
  getSharedAlbum,
} from './profiles/privateProfileTriggers';

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

// Admin custom claims (P1-6): admin_users/{uid}.role -> `adminRole` claim.
export { onAdminUserWritten, resyncAllAdminClaims } from './admin/adminClaims';

// Admin-panel user actions (H-29): replace the panel's direct coinBalances /
// profiles / admin_actions writes with audited, role-checked callables.
export {
  adminAdjustUserCoins,
  adminUpdateUserProfile,
  adminSetUserStatus,
  adminBulkApproveVerification,
  adminOverrideSubscription,
  adminToggleTestUser,
  adminSendUserNotification,
} from './admin/panelUserActions';

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

// Link previews (Open Graph) for shared events + communities, served on
// /e/**, /c/** and /og/** via Firebase Hosting rewrites.
export { sharePreview } from './share/sharePreview';

// Events — notify people when they are added as a co-owner of an event.
export { onEventCoOwnersChanged } from './events/coOwnerNotify';

// Monthly coin allowance per membership tier (app: TierEntitlements.monthlyCoins).
export {
  grantMonthlyCoinAllowances,
  runMonthlyCoinAllowancesNow,
} from './coins/monthlyAllowance';

// Follow graph — server-maintained followersCount / followingCount, the
// 'new_follower' notification, and the admin backfill for legacy edges.
export {
  onUserFollowCreated,
  onUserFollowDeleted,
  onFollowCleanupJob,
  backfillFollowCounts,
} from './social/follows';

// Attraction page views — unique viewers per day → attraction_stats.viewCount.
export { onAttractionViewRecorded } from './attractions/attractionStats';
// Attraction user ratings → attraction_stats.ratingSum/Count/Avg/Dist.
export { onAttractionRatingWritten } from './attractions/attractionRatings';

// Shared, persistent translations of public content (events/attractions/experiences).
export { translateTexts } from './messaging/sharedTranslations';
// Client-contributed translations of public content, shared after 3 qualified users agree (or an admin).
export { submitSharedTranslations } from './messaging/submitSharedTranslations';

// User-created experiences (member-hosted) with reviews, replies + '@' mentions.
export {
  createUserExperience,
  backfillHostRatings,
  setExperienceFeatured,
  publishUserExperience,
  acceptHostAgreement,
  onExperienceReportCreated,
  onUserExperienceWritten,
  onExperienceReviewWritten,
  onExperienceReplyCreated,
  // Community deleted -> its experiences are kept and unlinked.
  onCommunityDeletedUnlinkExperiences,
} from './user_experiences';

// Experience bookings: slots, bookings (free / cash / host link — no money
// moves through GreenGo), cancellation refund obligations, check-in, no-show,
// disputes, reminders, two-way double-blind reviews (experience_bookings/).
export {
  createBooking,
  getSlotAvailability,
  respondToBookingRequest,
  cancelBooking,
  cancelExperienceSlot,
  getBookingCheckInCode,
  checkInBooking,
  markBookingNoShow,
  markBookingPaid,
  confirmCashReceived,
  openBookingDispute,
  resolveBookingDispute,
  getExperienceAvailability,
  updateExperienceAvailability,
  sendBookingReminders,
  expireBookingRequests,
  completeBookings,
  revealBlindReviews,
  onGuestReviewWritten,
  onPendingExperienceReviewCreated,
  onBookableExperienceDeleted,
} from './experience_bookings';

// QR check-in for events: signed tickets verified by the server, and the
// shared "met in person" record (checkin/).
export { getEventTicketCode, checkInEventAttendee, checkInTicket } from './checkin/eventCheckin';

// Paid tickets for events + experiences (docs/payments/ticket-payments.md):
// link mode (organizer confirms) + instant mode (Stripe Connect Standard /
// Mercado Pago OAuth). Money goes straight to the organizer; no GreenGo fee.
export {
  getTicketPaymentsConfig,
  startStripeOnboarding,
  startMercadoPagoOnboarding,
  refreshPaymentAccount,
  createTicketCheckout,
  syncTicketOrder,
  cancelTicketOrder,
  markTicketPaymentSent,
  confirmTicketPayment,
  rejectTicketPayment,
  stripeConnectWebhook,
  mercadoPagoWebhook,
  mpOAuthCallback,
  ticketCheckoutReturn,
  expireTicketOrders,
  remindTicketConfirmations,
  refreshMercadoPagoTokens,
} from './ticket_payments';

// P3-5 security-event alerts (email to SECURITY_ALERT_EMAILS)
export {
  alertOnAdminAudit,
  alertOnAdminUsersChange,
  alertOnFraudFlag,
  alertOnModerationP0,
} from './security/securityEventAlerts';

// Transactional emails (emails/): ID-verification submitted -> reviewers
// (ADMIN_VERIFICATION_EMAILS), ticket / booking QR -> buyer, participants
// list CSV -> organizer (1 h before start + on demand).
export { emailOnIdVerificationSubmitted } from './emails/verificationSubmittedEmail';
export { emailTicketsOnOrderPaid, emailBookingQrOnConfirm } from './emails/ticketEmails';
export { sendParticipantListsDue, sendParticipantsList } from './emails/participantsList';
