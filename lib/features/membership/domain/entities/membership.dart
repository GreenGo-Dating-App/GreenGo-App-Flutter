import 'package:equatable/equatable.dart';

/// Membership Tier Enum
/// Defines the different VIP membership levels
enum MembershipTier {
  free('FREE'),
  silver('SILVER'),
  gold('GOLD'),
  platinum('PLATINUM'),
  test('TEST');

  final String value;
  const MembershipTier(this.value);

  static MembershipTier fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BASIC':
      case 'SILVER':
        return MembershipTier.silver;
      case 'GOLD':
        return MembershipTier.gold;
      case 'PLATINUM':
        return MembershipTier.platinum;
      case 'TEST':
        return MembershipTier.test;
      default:
        return MembershipTier.free;
    }
  }

  String get displayName {
    switch (this) {
      case MembershipTier.free:
        return 'Free';
      case MembershipTier.silver:
        return 'Silver VIP';
      case MembershipTier.gold:
        return 'Gold VIP';
      case MembershipTier.platinum:
        return 'Platinum VIP';
      case MembershipTier.test:
        return 'Tester';
    }
  }

  int get priority {
    switch (this) {
      case MembershipTier.free:
        return 0;
      case MembershipTier.silver:
        return 1;
      case MembershipTier.gold:
        return 2;
      case MembershipTier.platinum:
        return 3;
      case MembershipTier.test:
        return 99; // Highest priority for testers
    }
  }

  /// Check if this tier bypasses countdown restrictions
  bool get bypassesCountdown {
    return this == MembershipTier.test;
  }
}

/// Membership Rules
/// Configurable limits and permissions for each membership tier
class MembershipRules extends Equatable {
  /// Maximum messages per day (-1 for unlimited)
  final int dailyMessageLimit;

  /// Maximum swipes per day (-1 for unlimited) — legacy, kept for backwards compat
  final int dailySwipeLimit;

  /// Maximum super likes per day — legacy, kept for backwards compat
  final int dailySuperLikeLimit;

  /// Maximum likes (right swipe) per hour (-1 for unlimited)
  final int hourlyLikeLimit;

  /// Maximum nopes (left swipe) per hour (-1 for unlimited)
  final int hourlyNopeLimit;

  /// Maximum super likes (up swipe) per hour (-1 for unlimited)
  final int hourlySuperLikeLimit;

  /// Can see who liked them
  final bool canSeeWhoLiked;

  /// Can use advanced filters (age, distance, interests, etc.)
  final bool canUseAdvancedFilters;

  /// Can use location filter
  final bool canFilterByLocation;

  /// Can use interest filter
  final bool canFilterByInterests;

  /// Can use language filter
  final bool canFilterByLanguage;

  /// Can use verification status filter
  final bool canFilterByVerification;

  /// Can boost profile visibility
  final bool canBoostProfile;

  /// Number of free boosts per month
  final int monthlyFreeBoosts;

  /// Can send media (images/videos) in chat
  final bool canSendMedia;

  /// Can see read receipts
  final bool canSeeReadReceipts;

  /// Can use incognito mode
  final bool canUseIncognitoMode;

  /// Priority in matching queue (higher = shown first)
  final int matchPriority;

  /// Can see profile visitors
  final bool canSeeProfileVisitors;

  /// Can use video chat
  final bool canUseVideoChat;

  /// Maximum media sends per day (-1 for unlimited, 0 for none)
  final int dailyMediaSendLimit;

  /// Profile badge/icon displayed
  final String? badgeIcon;

  const MembershipRules({
    this.dailyMessageLimit = 10,
    this.dailySwipeLimit = 20,
    this.dailySuperLikeLimit = 0,
    this.hourlyLikeLimit = 5,
    this.hourlyNopeLimit = 10,
    this.hourlySuperLikeLimit = 0,
    this.canSeeWhoLiked = false,
    this.canUseAdvancedFilters = false,
    this.canFilterByLocation = false,
    this.canFilterByInterests = false,
    this.canFilterByLanguage = false,
    this.canFilterByVerification = false,
    this.canBoostProfile = false,
    this.monthlyFreeBoosts = 0,
    this.canSendMedia = false,
    this.canSeeReadReceipts = false,
    this.canUseIncognitoMode = false,
    this.matchPriority = 0,
    this.canSeeProfileVisitors = false,
    this.canUseVideoChat = false,
    this.dailyMediaSendLimit = 0,
    this.badgeIcon,
  });

  /// Default rules for FREE tier
  static const MembershipRules freeDefaults = MembershipRules(
    dailyMessageLimit: 10,
    dailySwipeLimit: 20,
    dailySuperLikeLimit: 1,
    hourlyLikeLimit: 5,
    hourlyNopeLimit: 10,
    hourlySuperLikeLimit: 1,
    canSeeWhoLiked: false,
    canUseAdvancedFilters: false,
    canFilterByLocation: false,
    canFilterByInterests: false,
    canFilterByLanguage: false,
    canFilterByVerification: false,
    canBoostProfile: false,
    monthlyFreeBoosts: 0,
    canSendMedia: true,
    canSeeReadReceipts: false,
    canUseIncognitoMode: false,
    matchPriority: 0,
    canSeeProfileVisitors: false,
    canUseVideoChat: false,
    dailyMediaSendLimit: 10,
    badgeIcon: null,
  );

  /// Default rules for SILVER tier
  static const MembershipRules silverDefaults = MembershipRules(
    dailyMessageLimit: 50,
    dailySwipeLimit: 100,
    dailySuperLikeLimit: 3,
    hourlyLikeLimit: 10,
    hourlyNopeLimit: 25,
    hourlySuperLikeLimit: 2,
    canSeeWhoLiked: false,
    canUseAdvancedFilters: true,
    canFilterByLocation: true,
    canFilterByInterests: true,
    canFilterByLanguage: false,
    canFilterByVerification: false,
    canBoostProfile: true,
    monthlyFreeBoosts: 1,
    canSendMedia: true,
    canSeeReadReceipts: true,
    canUseIncognitoMode: false,
    matchPriority: 1,
    canSeeProfileVisitors: false,
    canUseVideoChat: false,
    dailyMediaSendLimit: 50,
    badgeIcon: 'silver_badge',
  );

  /// Default rules for GOLD tier
  static const MembershipRules goldDefaults = MembershipRules(
    dailyMessageLimit: -1, // Unlimited
    dailySwipeLimit: -1, // Unlimited
    dailySuperLikeLimit: 5,
    hourlyLikeLimit: 15,
    hourlyNopeLimit: 40,
    hourlySuperLikeLimit: 4,
    canSeeWhoLiked: true,
    canUseAdvancedFilters: true,
    canFilterByLocation: true,
    canFilterByInterests: true,
    canFilterByLanguage: true,
    canFilterByVerification: true,
    canBoostProfile: true,
    monthlyFreeBoosts: 3,
    canSendMedia: true,
    canSeeReadReceipts: true,
    canUseIncognitoMode: true,
    matchPriority: 2,
    canSeeProfileVisitors: true,
    canUseVideoChat: false,
    dailyMediaSendLimit: 500,
    badgeIcon: 'gold_badge',
  );

  /// Default rules for PLATINUM tier
  static const MembershipRules platinumDefaults = MembershipRules(
    dailyMessageLimit: -1, // Unlimited
    dailySwipeLimit: -1, // Unlimited
    dailySuperLikeLimit: -1, // Unlimited
    hourlyLikeLimit: 20,
    hourlyNopeLimit: 50,
    hourlySuperLikeLimit: 5,
    canSeeWhoLiked: true,
    canUseAdvancedFilters: true,
    canFilterByLocation: true,
    canFilterByInterests: true,
    canFilterByLanguage: true,
    canFilterByVerification: true,
    canBoostProfile: true,
    monthlyFreeBoosts: 5,
    canSendMedia: true,
    canSeeReadReceipts: true,
    canUseIncognitoMode: true,
    matchPriority: 3,
    canSeeProfileVisitors: true,
    canUseVideoChat: true,
    dailyMediaSendLimit: -1, // Unlimited
    badgeIcon: 'platinum_badge',
  );

  /// Default rules for TEST tier (configurable from admin panel)
  /// Test users bypass countdown and have configurable limits
  static const MembershipRules testDefaults = MembershipRules(
    dailyMessageLimit: -1, // Unlimited by default, admin configurable
    dailySwipeLimit: -1, // Unlimited by default, admin configurable
    dailySuperLikeLimit: -1, // Unlimited by default, admin configurable
    hourlyLikeLimit: 20, // Same as Platinum max
    hourlyNopeLimit: 50, // Same as Platinum max
    hourlySuperLikeLimit: 5, // Same as Platinum max
    canSeeWhoLiked: true,
    canUseAdvancedFilters: true,
    canFilterByLocation: true,
    canFilterByInterests: true,
    canFilterByLanguage: true,
    canFilterByVerification: true,
    canBoostProfile: true,
    monthlyFreeBoosts: 10,
    canSendMedia: true,
    canSeeReadReceipts: true,
    canUseIncognitoMode: true,
    matchPriority: 99, // Highest priority
    canSeeProfileVisitors: true,
    canUseVideoChat: true,
    dailyMediaSendLimit: -1, // Unlimited
    badgeIcon: 'test_badge',
  );

  /// Get default rules for a specific tier
  static MembershipRules getDefaultsForTier(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return freeDefaults;
      case MembershipTier.silver:
        return silverDefaults;
      case MembershipTier.gold:
        return goldDefaults;
      case MembershipTier.platinum:
        return platinumDefaults;
      case MembershipTier.test:
        return testDefaults;
    }
  }

  /// Check if a limit is unlimited
  bool isUnlimited(int limit) => limit == -1;

  @override
  List<Object?> get props => [
        dailyMessageLimit,
        dailySwipeLimit,
        dailySuperLikeLimit,
        hourlyLikeLimit,
        hourlyNopeLimit,
        hourlySuperLikeLimit,
        canSeeWhoLiked,
        canUseAdvancedFilters,
        canFilterByLocation,
        canFilterByInterests,
        canFilterByLanguage,
        canFilterByVerification,
        canBoostProfile,
        monthlyFreeBoosts,
        canSendMedia,
        canSeeReadReceipts,
        canUseIncognitoMode,
        matchPriority,
        canSeeProfileVisitors,
        canUseVideoChat,
        dailyMediaSendLimit,
        badgeIcon,
      ];
}

/// User Membership
/// Represents a user's current membership status
class Membership extends Equatable {
  /// Unique membership ID
  final String membershipId;

  /// User ID this membership belongs to
  final String userId;

  /// Current membership tier
  final MembershipTier tier;

  /// Coupon code used to activate this membership (if any)
  final String? couponCode;

  /// When this membership started
  final DateTime startDate;

  /// When this membership expires (null for lifetime/free)
  final DateTime? endDate;

  /// Custom rules (overrides defaults if set)
  final MembershipRules? customRules;

  /// Whether membership is currently active
  final bool isActive;

  /// When membership was created
  final DateTime createdAt;

  /// When membership was last updated
  final DateTime updatedAt;

  /// Admin who activated/modified this membership (if any)
  final String? activatedBy;

  const Membership({
    required this.membershipId,
    required this.userId,
    required this.tier,
    this.couponCode,
    required this.startDate,
    this.endDate,
    this.customRules,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.activatedBy,
  });

  /// Get the effective rules (custom or default for tier)
  MembershipRules get rules =>
      customRules ?? MembershipRules.getDefaultsForTier(tier);

  /// Check if membership is expired
  bool get isExpired {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!);
  }

  /// Check if membership is valid (active and not expired)
  bool get isValid => isActive && !isExpired;

  /// Get remaining days until expiration
  int? get remainingDays {
    if (endDate == null) return null;
    final remaining = endDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Check if membership is about to expire (within 7 days)
  bool get isExpiringShow {
    if (endDate == null) return false;
    final remaining = remainingDays;
    return remaining != null && remaining <= 7 && remaining > 0;
  }

  @override
  List<Object?> get props => [
        membershipId,
        userId,
        tier,
        couponCode,
        startDate,
        endDate,
        customRules,
        isActive,
        createdAt,
        updatedAt,
        activatedBy,
      ];
}
