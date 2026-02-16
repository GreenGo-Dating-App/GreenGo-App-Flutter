"use strict";
/**
 * Shared TypeScript types for all microservices
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChallengeType = exports.AchievementType = exports.CallStatusExtended = exports.CallType = exports.UserRole = exports.NotificationType = exports.ReportStatus = exports.ReportReason = exports.ModerationAction = exports.ModerationCategory = exports.VideoQuality = exports.CallStatus = exports.CoinSource = exports.SubscriptionStatus = exports.MessageType = exports.ApprovalStatus = exports.SubscriptionTier = void 0;
var SubscriptionTier;
(function (SubscriptionTier) {
    SubscriptionTier["BASIC"] = "basic";
    SubscriptionTier["SILVER"] = "silver";
    SubscriptionTier["GOLD"] = "gold";
    SubscriptionTier["PLATINUM"] = "platinum";
})(SubscriptionTier || (exports.SubscriptionTier = SubscriptionTier = {}));
// MVP Release Access Control
var ApprovalStatus;
(function (ApprovalStatus) {
    ApprovalStatus["PENDING"] = "pending";
    ApprovalStatus["APPROVED"] = "approved";
    ApprovalStatus["REJECTED"] = "rejected";
})(ApprovalStatus || (exports.ApprovalStatus = ApprovalStatus = {}));
var MessageType;
(function (MessageType) {
    MessageType["TEXT"] = "text";
    MessageType["IMAGE"] = "image";
    MessageType["VIDEO"] = "video";
    MessageType["VOICE"] = "voice";
    MessageType["GIF"] = "gif";
})(MessageType || (exports.MessageType = MessageType = {}));
var SubscriptionStatus;
(function (SubscriptionStatus) {
    SubscriptionStatus["ACTIVE"] = "active";
    SubscriptionStatus["CANCELED"] = "canceled";
    SubscriptionStatus["EXPIRED"] = "expired";
    SubscriptionStatus["ON_HOLD"] = "on_hold";
    SubscriptionStatus["IN_GRACE_PERIOD"] = "in_grace_period";
    SubscriptionStatus["PAUSED"] = "paused";
})(SubscriptionStatus || (exports.SubscriptionStatus = SubscriptionStatus = {}));
var CoinSource;
(function (CoinSource) {
    CoinSource["PURCHASED"] = "purchased";
    CoinSource["EARNED"] = "earned";
    CoinSource["GIFTED"] = "gifted";
    CoinSource["ALLOWANCE"] = "allowance";
    CoinSource["REFUND"] = "refund";
})(CoinSource || (exports.CoinSource = CoinSource = {}));
var CallStatus;
(function (CallStatus) {
    CallStatus["INITIATING"] = "initiating";
    CallStatus["RINGING"] = "ringing";
    CallStatus["ONGOING"] = "ongoing";
    CallStatus["ENDED"] = "ended";
    CallStatus["MISSED"] = "missed";
    CallStatus["REJECTED"] = "rejected";
    CallStatus["ACTIVE"] = "active";
    CallStatus["SCHEDULED"] = "scheduled";
})(CallStatus || (exports.CallStatus = CallStatus = {}));
var VideoQuality;
(function (VideoQuality) {
    VideoQuality["HD_1080P"] = "1080p";
    VideoQuality["HD_720P"] = "720p";
    VideoQuality["SD_480P"] = "480p";
    VideoQuality["SD_360P"] = "360p";
})(VideoQuality || (exports.VideoQuality = VideoQuality = {}));
var ModerationCategory;
(function (ModerationCategory) {
    ModerationCategory["ADULT"] = "adult";
    ModerationCategory["VIOLENCE"] = "violence";
    ModerationCategory["SPAM"] = "spam";
    ModerationCategory["HATE_SPEECH"] = "hate_speech";
    ModerationCategory["SCAM"] = "scam";
    ModerationCategory["FAKE_PROFILE"] = "fake_profile";
})(ModerationCategory || (exports.ModerationCategory = ModerationCategory = {}));
var ModerationAction;
(function (ModerationAction) {
    ModerationAction["APPROVED"] = "approved";
    ModerationAction["REJECTED"] = "rejected";
    ModerationAction["PENDING_REVIEW"] = "pending_review";
    ModerationAction["AUTO_APPROVED"] = "auto_approved";
    ModerationAction["AUTO_REJECTED"] = "auto_rejected";
})(ModerationAction || (exports.ModerationAction = ModerationAction = {}));
var ReportReason;
(function (ReportReason) {
    ReportReason["INAPPROPRIATE_CONTENT"] = "inappropriate_content";
    ReportReason["HARASSMENT"] = "harassment";
    ReportReason["SPAM"] = "spam";
    ReportReason["FAKE_PROFILE"] = "fake_profile";
    ReportReason["SCAM"] = "scam";
    ReportReason["UNDERAGE"] = "underage";
    ReportReason["OTHER"] = "other";
})(ReportReason || (exports.ReportReason = ReportReason = {}));
var ReportStatus;
(function (ReportStatus) {
    ReportStatus["PENDING"] = "pending";
    ReportStatus["UNDER_REVIEW"] = "under_review";
    ReportStatus["RESOLVED"] = "resolved";
    ReportStatus["DISMISSED"] = "dismissed";
})(ReportStatus || (exports.ReportStatus = ReportStatus = {}));
var NotificationType;
(function (NotificationType) {
    NotificationType["NEW_MATCH"] = "new_match";
    NotificationType["NEW_MESSAGE"] = "new_message";
    NotificationType["PROFILE_VIEW"] = "profile_view";
    NotificationType["SUPER_LIKE"] = "super_like";
    NotificationType["VIDEO_CALL"] = "video_call";
    NotificationType["SUBSCRIPTION_EXPIRING"] = "subscription_expiring";
    NotificationType["COINS_EXPIRING"] = "coins_expiring";
    NotificationType["ACHIEVEMENT_UNLOCKED"] = "achievement_unlocked";
})(NotificationType || (exports.NotificationType = NotificationType = {}));
// ========== ADMIN TYPES ==========
var UserRole;
(function (UserRole) {
    UserRole["USER"] = "user";
    UserRole["MODERATOR"] = "moderator";
    UserRole["ADMIN"] = "admin";
    UserRole["SUPER_ADMIN"] = "super_admin";
})(UserRole || (exports.UserRole = UserRole = {}));
// ========== ADDITIONAL CALL TYPES ==========
var CallType;
(function (CallType) {
    CallType["ONE_TO_ONE"] = "one_to_one";
    CallType["GROUP"] = "group";
    CallType["SCHEDULED"] = "scheduled";
})(CallType || (exports.CallType = CallType = {}));
// Add missing call statuses
exports.CallStatusExtended = Object.assign(Object.assign({}, CallStatus), { ACTIVE: 'active', SCHEDULED: 'scheduled' });
// ========== GAMIFICATION ADDITIONAL TYPES ==========
var AchievementType;
(function (AchievementType) {
    AchievementType["MESSAGES_SENT"] = "messages_sent";
    AchievementType["MATCHES_MADE"] = "matches_made";
    AchievementType["PROFILE_COMPLETE"] = "profile_complete";
    AchievementType["VERIFICATION_COMPLETE"] = "verification_complete";
    AchievementType["STREAKS"] = "streaks";
    AchievementType["COINS_EARNED"] = "coins_earned";
    AchievementType["LESSONS_COMPLETE"] = "lessons_complete";
})(AchievementType || (exports.AchievementType = AchievementType = {}));
var ChallengeType;
(function (ChallengeType) {
    ChallengeType["DAILY"] = "daily";
    ChallengeType["WEEKLY"] = "weekly";
    ChallengeType["MONTHLY"] = "monthly";
    ChallengeType["SPECIAL"] = "special";
})(ChallengeType || (exports.ChallengeType = ChallengeType = {}));
//# sourceMappingURL=types.js.map