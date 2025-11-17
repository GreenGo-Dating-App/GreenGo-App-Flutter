/**
 * User Management Entity
 * Points 236-245: Admin user management tools
 */

import 'package:equatable/equatable.dart';

/// Admin user search result (Point 236)
class UserSearchResult extends Equatable {
  final String userId;
  final String displayName;
  final String email;
  final int age;
  final String? photoUrl;
  final String accountStatus;
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final String? subscriptionTier;
  final double matchScore; // Relevance to search query

  const UserSearchResult({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.age,
    this.photoUrl,
    required this.accountStatus,
    required this.createdAt,
    this.lastActiveAt,
    this.subscriptionTier,
    required this.matchScore,
  });

  @override
  List<Object?> get props => [
        userId,
        displayName,
        email,
        age,
        photoUrl,
        accountStatus,
        createdAt,
        lastActiveAt,
        subscriptionTier,
        matchScore,
      ];
}

/// Detailed user profile for admin view (Point 237)
class AdminUserProfile extends Equatable {
  final String userId;
  final UserBasicInfo basicInfo;
  final UserAccountInfo accountInfo;
  final UserSubscriptionInfo? subscriptionInfo;
  final UserCoinInfo coinInfo;
  final UserActivityInfo activityInfo;
  final UserModerationInfo moderationInfo;
  final UserVerificationInfo verificationInfo;
  final List<UserFlag> flags;
  final List<String> tags;

  const AdminUserProfile({
    required this.userId,
    required this.basicInfo,
    required this.accountInfo,
    this.subscriptionInfo,
    required this.coinInfo,
    required this.activityInfo,
    required this.moderationInfo,
    required this.verificationInfo,
    required this.flags,
    required this.tags,
  });

  @override
  List<Object?> get props => [
        userId,
        basicInfo,
        accountInfo,
        subscriptionInfo,
        coinInfo,
        activityInfo,
        moderationInfo,
        verificationInfo,
        flags,
        tags,
      ];
}

/// User basic info
class UserBasicInfo extends Equatable {
  final String displayName;
  final String email;
  final String? phoneNumber;
  final int age;
  final String gender;
  final List<String> photoUrls;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;

  const UserBasicInfo({
    required this.displayName,
    required this.email,
    this.phoneNumber,
    required this.age,
    required this.gender,
    required this.photoUrls,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        displayName,
        email,
        phoneNumber,
        age,
        gender,
        photoUrls,
        bio,
        location,
        latitude,
        longitude,
      ];
}

/// User account info
class UserAccountInfo extends Equatable {
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String accountStatus; // active, suspended, banned, deleted
  final String? suspensionReason;
  final DateTime? suspendedUntil;
  final DateTime? bannedAt;
  final String? banReason;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String devicePlatform;
  final String appVersion;

  const UserAccountInfo({
    required this.createdAt,
    this.lastLoginAt,
    required this.accountStatus,
    this.suspensionReason,
    this.suspendedUntil,
    this.bannedAt,
    this.banReason,
    required this.isEmailVerified,
    required this.isPhoneVerified,
    required this.devicePlatform,
    required this.appVersion,
  });

  @override
  List<Object?> get props => [
        createdAt,
        lastLoginAt,
        accountStatus,
        suspensionReason,
        suspendedUntil,
        bannedAt,
        banReason,
        isEmailVerified,
        isPhoneVerified,
        devicePlatform,
        appVersion,
      ];
}

/// User subscription info (Point 240)
class UserSubscriptionInfo extends Equatable {
  final String subscriptionId;
  final String tier; // Silver, Gold, Platinum
  final String status; // active, canceled, expired, in_grace_period
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final DateTime? canceledAt;
  final bool autoRenew;
  final String platform; // google_play, app_store
  final double price;
  final String currency;
  final int renewalCount;

  const UserSubscriptionInfo({
    required this.subscriptionId,
    required this.tier,
    required this.status,
    required this.purchaseDate,
    required this.expirationDate,
    this.canceledAt,
    required this.autoRenew,
    required this.platform,
    required this.price,
    required this.currency,
    required this.renewalCount,
  });

  @override
  List<Object?> get props => [
        subscriptionId,
        tier,
        status,
        purchaseDate,
        expirationDate,
        canceledAt,
        autoRenew,
        platform,
        price,
        currency,
        renewalCount,
      ];
}

/// User coin info (Point 241)
class UserCoinInfo extends Equatable {
  final int totalCoins;
  final int lifetimePurchased;
  final int lifetimeSpent;
  final int lifetimeEarned;
  final DateTime? lastPurchaseAt;
  final List<CoinBatchInfo> batches;

  const UserCoinInfo({
    required this.totalCoins,
    required this.lifetimePurchased,
    required this.lifetimeSpent,
    required this.lifetimeEarned,
    this.lastPurchaseAt,
    required this.batches,
  });

  @override
  List<Object?> get props => [
        totalCoins,
        lifetimePurchased,
        lifetimeSpent,
        lifetimeEarned,
        lastPurchaseAt,
        batches,
      ];
}

/// Coin batch info
class CoinBatchInfo extends Equatable {
  final String batchId;
  final int initialCoins;
  final int remainingCoins;
  final String source;
  final DateTime acquiredAt;
  final DateTime expirationDate;

  const CoinBatchInfo({
    required this.batchId,
    required this.initialCoins,
    required this.remainingCoins,
    required this.source,
    required this.acquiredAt,
    required this.expirationDate,
  });

  @override
  List<Object?> get props => [
        batchId,
        initialCoins,
        remainingCoins,
        source,
        acquiredAt,
        expirationDate,
      ];
}

/// User activity info
class UserActivityInfo extends Equatable {
  final int totalMatches;
  final int totalMessages;
  final int totalLikes;
  final int totalSuperLikes;
  final int totalBoosts;
  final DateTime? lastActiveAt;
  final int daysActive; // Days with activity
  final double avgSessionDuration; // Minutes
  final int totalSessions;

  const UserActivityInfo({
    required this.totalMatches,
    required this.totalMessages,
    required this.totalLikes,
    required this.totalSuperLikes,
    required this.totalBoosts,
    this.lastActiveAt,
    required this.daysActive,
    required this.avgSessionDuration,
    required this.totalSessions,
  });

  @override
  List<Object?> get props => [
        totalMatches,
        totalMessages,
        totalLikes,
        totalSuperLikes,
        totalBoosts,
        lastActiveAt,
        daysActive,
        avgSessionDuration,
        totalSessions,
      ];
}

/// User moderation info
class UserModerationInfo extends Equatable {
  final int reportCount; // Times reported by others
  final int warningCount;
  final int suspensionCount;
  final DateTime? lastWarningAt;
  final DateTime? lastSuspensionAt;
  final bool isShadowBanned;
  final double? visibilityReduction;
  final List<String> appliedRestrictions;

  const UserModerationInfo({
    required this.reportCount,
    required this.warningCount,
    required this.suspensionCount,
    this.lastWarningAt,
    this.lastSuspensionAt,
    required this.isShadowBanned,
    this.visibilityReduction,
    required this.appliedRestrictions,
  });

  @override
  List<Object?> get props => [
        reportCount,
        warningCount,
        suspensionCount,
        lastWarningAt,
        lastSuspensionAt,
        isShadowBanned,
        visibilityReduction,
        appliedRestrictions,
      ];
}

/// User verification info
class UserVerificationInfo extends Equatable {
  final bool isPhotoVerified;
  final bool isIdVerified;
  final DateTime? photoVerifiedAt;
  final DateTime? idVerifiedAt;
  final double trustScore; // 0-100
  final String trustLevel; // veryLow, low, medium, high, veryHigh

  const UserVerificationInfo({
    required this.isPhotoVerified,
    required this.isIdVerified,
    this.photoVerifiedAt,
    this.idVerifiedAt,
    required this.trustScore,
    required this.trustLevel,
  });

  @override
  List<Object?> get props => [
        isPhotoVerified,
        isIdVerified,
        photoVerifiedAt,
        idVerifiedAt,
        trustScore,
        trustLevel,
      ];
}

/// User flag (admin-added notes)
class UserFlag extends Equatable {
  final String flagId;
  final FlagType type;
  final String description;
  final String addedBy;
  final DateTime addedAt;

  const UserFlag({
    required this.flagId,
    required this.type,
    required this.description,
    required this.addedBy,
    required this.addedAt,
  });

  @override
  List<Object?> get props => [
        flagId,
        type,
        description,
        addedBy,
        addedAt,
      ];
}

/// Flag types
enum FlagType {
  suspicious,
  watchlist,
  vip,
  problematic,
  reviewer,
  other,
}

/// Mass action operation (Point 242)
class MassActionOperation extends Equatable {
  final String operationId;
  final MassActionType type;
  final List<String> targetUserIds;
  final Map<String, dynamic> parameters;
  final String initiatedBy;
  final DateTime initiatedAt;
  final MassActionStatus status;
  final int totalTargets;
  final int successCount;
  final int failureCount;
  final List<MassActionResult> results;

  const MassActionOperation({
    required this.operationId,
    required this.type,
    required this.targetUserIds,
    required this.parameters,
    required this.initiatedBy,
    required this.initiatedAt,
    required this.status,
    required this.totalTargets,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  @override
  List<Object?> get props => [
        operationId,
        type,
        targetUserIds,
        parameters,
        initiatedBy,
        initiatedAt,
        status,
        totalTargets,
        successCount,
        failureCount,
        results,
      ];
}

/// Mass action types
enum MassActionType {
  massNotification,
  massSuspension,
  massBan,
  massTagging,
  massCoinGrant,
  massSubscriptionOverride,
}

/// Mass action status
enum MassActionStatus {
  pending,
  inProgress,
  completed,
  failed,
  partialSuccess,
}

/// Mass action result
class MassActionResult extends Equatable {
  final String userId;
  final bool success;
  final String? errorMessage;

  const MassActionResult({
    required this.userId,
    required this.success,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [userId, success, errorMessage];
}

/// User communication message (Point 243)
class UserCommunicationMessage extends Equatable {
  final String messageId;
  final String userId;
  final String subject;
  final String body;
  final CommunicationType type;
  final String sentBy;
  final DateTime sentAt;
  final bool isRead;
  final DateTime? readAt;

  const UserCommunicationMessage({
    required this.messageId,
    required this.userId,
    required this.subject,
    required this.body,
    required this.type,
    required this.sentBy,
    required this.sentAt,
    required this.isRead,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        messageId,
        userId,
        subject,
        body,
        type,
        sentBy,
        sentAt,
        isRead,
        readAt,
      ];
}

/// Communication types
enum CommunicationType {
  inAppNotification,
  email,
  pushNotification,
  sms,
}
