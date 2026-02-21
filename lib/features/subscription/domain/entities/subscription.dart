import 'package:equatable/equatable.dart';

/// Subscription Tier
/// Point 148: Four-tier system (updated for MVP release) + Test tier
enum SubscriptionTier {
  basic,    // Free tier
  silver,   // $9.99/month
  gold,     // $19.99/month
  platinum, // $29.99/month - VIP tier
  test,     // Test user - bypasses countdown, admin-configured limits
}

extension SubscriptionTierExtension on SubscriptionTier {
  String get name {
    switch (this) {
      case SubscriptionTier.basic:
        return 'Basic';
      case SubscriptionTier.silver:
        return 'Silver';
      case SubscriptionTier.gold:
        return 'Gold';
      case SubscriptionTier.platinum:
        return 'Platinum';
      case SubscriptionTier.test:
        return 'Test';
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionTier.basic:
        return 'Basic (Free)';
      case SubscriptionTier.silver:
        return 'Silver Premium';
      case SubscriptionTier.gold:
        return 'Gold Premium';
      case SubscriptionTier.platinum:
        return 'Platinum VIP';
      case SubscriptionTier.test:
        return 'Tester';
    }
  }

  double get monthlyPrice {
    switch (this) {
      case SubscriptionTier.basic:
        return 0.0;
      case SubscriptionTier.silver:
        return 9.99;
      case SubscriptionTier.gold:
        return 19.99;
      case SubscriptionTier.platinum:
        return 29.99;
      case SubscriptionTier.test:
        return 0.0; // Free for testers
    }
  }

  /// Yearly price = monthly × 10 (~17% savings, 2 months free)
  double get yearlyPrice {
    return monthlyPrice * 10;
  }

  /// Monthly equivalent when buying yearly
  double get yearlyMonthlyEquivalent {
    if (yearlyPrice == 0) return 0;
    return yearlyPrice / 12;
  }

  /// Savings percentage when buying yearly vs monthly
  double get yearlySavingsPercent {
    if (monthlyPrice == 0) return 0;
    final monthlyTotal = monthlyPrice * 12;
    return ((monthlyTotal - yearlyPrice) / monthlyTotal) * 100;
  }

  /// Monthly product ID (for store lookup)
  String get monthlyProductId {
    switch (this) {
      case SubscriptionTier.basic:
        return 'greengo_base_membership';
      case SubscriptionTier.silver:
        return '1_month_silver';
      case SubscriptionTier.gold:
        return '1_month_gold';
      case SubscriptionTier.platinum:
        return '1_month_platinum';
      case SubscriptionTier.test:
        return 'test_user';
    }
  }

  /// Yearly product ID (for store lookup)
  String get yearlyProductId {
    switch (this) {
      case SubscriptionTier.basic:
        return 'greengo_base_membership'; // Base is one-time, no yearly variant
      case SubscriptionTier.silver:
        return '1_year_silver';
      case SubscriptionTier.gold:
        return '1_year_gold';
      case SubscriptionTier.platinum:
        return '1_year_platinum_membership';
      case SubscriptionTier.test:
        return 'test_user';
    }
  }

  /// Legacy getter for backwards compatibility
  String get productId => monthlyProductId;

  /// Check if this tier bypasses countdown restrictions
  bool get bypassesCountdown {
    return this == SubscriptionTier.test;
  }

  /// Check if this tier has early access (before April 14 official release)
  bool get hasEarlyAccess {
    return this == SubscriptionTier.platinum ||
           this == SubscriptionTier.gold ||
           this == SubscriptionTier.silver ||
           this == SubscriptionTier.test; // Test users always have access
  }

  /// Get the access date for this tier
  /// Platinum: March 14, Gold: March 28, Silver: April 7, Basic: April 14
  DateTime get accessDate {
    switch (this) {
      case SubscriptionTier.test:
        return DateTime.now().subtract(const Duration(days: 1)); // Immediate
      case SubscriptionTier.platinum:
        return DateTime(2026, 3, 14); // March 14, 2026
      case SubscriptionTier.gold:
        return DateTime(2026, 3, 28); // March 28, 2026
      case SubscriptionTier.silver:
        return DateTime(2026, 4, 7);  // April 7, 2026
      case SubscriptionTier.basic:
        return DateTime(2026, 4, 14); // April 14, 2026 (official release)
    }
  }

  /// Features for each tier
  Map<String, dynamic> get features {
    switch (this) {
      case SubscriptionTier.basic:
        return {
          'dailyLikes': 10,
          'superLikes': 1,
          'rewinds': 0,
          'boosts': 0,
          'seeWhoLikesYou': false,
          'unlimitedLikes': false,
          'advancedFilters': false,
          'readReceipts': false,
          'prioritySupport': false,

          'profileBoost': 0,
          'incognitoMode': false,
        };
      case SubscriptionTier.silver:
        return {
          'dailyLikes': 100,
          'superLikes': 5,
          'rewinds': 5,
          'boosts': 1,
          'seeWhoLikesYou': true,
          'unlimitedLikes': false,
          'advancedFilters': true,
          'readReceipts': true,
          'prioritySupport': false,

          'profileBoost': 1,
          'incognitoMode': false,
        };
      case SubscriptionTier.gold:
        return {
          'dailyLikes': -1, // unlimited
          'superLikes': 10,
          'rewinds': -1, // unlimited
          'boosts': 3,
          'seeWhoLikesYou': true,
          'unlimitedLikes': true,
          'advancedFilters': true,
          'readReceipts': true,
          'prioritySupport': true,

          'profileBoost': 5,
          'incognitoMode': true,
        };
      case SubscriptionTier.platinum:
        return {
          'dailyLikes': -1, // unlimited
          'superLikes': -1, // unlimited
          'rewinds': -1, // unlimited
          'boosts': -1, // unlimited
          'seeWhoLikesYou': true,
          'unlimitedLikes': true,
          'advancedFilters': true,
          'readReceipts': true,
          'prioritySupport': true,

          'profileBoost': -1, // unlimited
          'incognitoMode': true,
          'vipBadge': true,
          'priorityMatching': true,
          'exclusiveEvents': true,
        };
      case SubscriptionTier.test:
        // Test tier - all features enabled, limits configurable from admin panel
        return {
          'dailyLikes': -1, // unlimited (admin configurable)
          'superLikes': -1, // unlimited (admin configurable)
          'rewinds': -1, // unlimited (admin configurable)
          'boosts': -1, // unlimited (admin configurable)
          'seeWhoLikesYou': true,
          'unlimitedLikes': true,
          'advancedFilters': true,
          'readReceipts': true,
          'prioritySupport': true,

          'profileBoost': -1, // unlimited
          'incognitoMode': true,
          'testBadge': true,
          'bypassCountdown': true, // Key feature for test users
          'priorityMatching': true,
        };
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'silver':
        return SubscriptionTier.silver;
      case 'gold':
        return SubscriptionTier.gold;
      case 'platinum':
        return SubscriptionTier.platinum;
      case 'test':
        return SubscriptionTier.test;
      case 'basic':
      default:
        return SubscriptionTier.basic;
    }
  }

  /// Get the upgrade offer ID for Play Store/App Store
  String? getUpgradeOfferId(SubscriptionTier currentTier) {
    // Can only upgrade to higher tiers
    if (index <= currentTier.index) return null;

    switch (this) {
      case SubscriptionTier.silver:
        return 'upgrade_to_silver';
      case SubscriptionTier.gold:
        if (currentTier == SubscriptionTier.silver) {
          return 'upgrade_silver_to_gold';
        }
        return 'upgrade_to_gold';
      case SubscriptionTier.platinum:
        if (currentTier == SubscriptionTier.gold) {
          return 'upgrade_gold_to_platinum';
        } else if (currentTier == SubscriptionTier.silver) {
          return 'upgrade_silver_to_platinum';
        }
        return 'upgrade_to_platinum';
      default:
        return null;
    }
  }

  /// Get the upgrade discount percentage based on current tier
  double getUpgradeDiscount(SubscriptionTier currentTier) {
    // No discount if not upgrading
    if (index <= currentTier.index) return 0.0;

    // Calculate prorated discount based on tier difference
    switch (currentTier) {
      case SubscriptionTier.silver:
        // Silver users get 10% off Gold, 15% off Platinum
        if (this == SubscriptionTier.gold) return 0.10;
        if (this == SubscriptionTier.platinum) return 0.15;
        return 0.0;
      case SubscriptionTier.gold:
        // Gold users get 10% off Platinum
        if (this == SubscriptionTier.platinum) return 0.10;
        return 0.0;
      case SubscriptionTier.basic:
        // Basic users get no discount
        return 0.0;
      default:
        return 0.0;
    }
  }
}

/// Subscription Status
enum SubscriptionStatus {
  active,       // Currently active subscription
  expired,      // Subscription has expired
  cancelled,    // User cancelled (but may still be active until end date)
  suspended,    // Payment failed, in grace period
  pending,      // Purchase initiated but not confirmed
  refunded,     // Subscription was refunded
}

extension SubscriptionStatusExtension on SubscriptionStatus {
  String get value {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.cancelled:
        return 'cancelled';
      case SubscriptionStatus.suspended:
        return 'suspended';
      case SubscriptionStatus.pending:
        return 'pending';
      case SubscriptionStatus.refunded:
        return 'refunded';
    }
  }

  static SubscriptionStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return SubscriptionStatus.active;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'cancelled':
        return SubscriptionStatus.cancelled;
      case 'suspended':
        return SubscriptionStatus.suspended;
      case 'pending':
        return SubscriptionStatus.pending;
      case 'refunded':
        return SubscriptionStatus.refunded;
      default:
        return SubscriptionStatus.expired;
    }
  }
}

/// Subscription Entity
/// Represents a user's one-time membership purchase
class Subscription extends Equatable {
  final String subscriptionId;
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final int durationDays; // 30 or 365

  // Payment information
  final String? platform; // 'android', 'ios', 'web'
  final String? purchaseToken;
  final String? transactionId;
  final String? orderId;

  // Pricing
  final double price;
  final String currency;

  // Tracking
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Subscription({
    required this.subscriptionId,
    required this.userId,
    required this.tier,
    required this.status,
    required this.startDate,
    this.endDate,
    this.durationDays = 30,
    this.platform,
    this.purchaseToken,
    this.transactionId,
    this.orderId,
    required this.price,
    this.currency = 'USD',
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if membership is currently active
  bool get isActive {
    if (status != SubscriptionStatus.active) {
      return false;
    }

    if (endDate == null) return true;

    return DateTime.now().isBefore(endDate!);
  }

  /// Check if membership will expire soon (within 3 days)
  bool get willExpireSoon {
    if (endDate == null) return false;

    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  /// Days remaining in membership
  int get daysRemaining {
    if (endDate == null) return -1; // Unlimited

    final remaining = endDate!.difference(DateTime.now()).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// Get feature value for this subscription
  T getFeature<T>(String featureName, T defaultValue) {
    final features = tier.features;
    return features[featureName] as T? ?? defaultValue;
  }

  /// Check if user has access to feature
  bool hasFeature(String featureName) {
    return getFeature<bool>(featureName, false);
  }

  /// Get numeric limit for feature (-1 = unlimited)
  int getLimit(String featureName) {
    return getFeature<int>(featureName, 0);
  }

  Subscription copyWith({
    String? subscriptionId,
    String? userId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    String? platform,
    String? purchaseToken,
    String? transactionId,
    String? orderId,
    double? price,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      platform: platform ?? this.platform,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      transactionId: transactionId ?? this.transactionId,
      orderId: orderId ?? this.orderId,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        subscriptionId,
        userId,
        tier,
        status,
        startDate,
        endDate,
        durationDays,
        platform,
        purchaseToken,
        transactionId,
        orderId,
        price,
        currency,
        createdAt,
        updatedAt,
      ];
}
