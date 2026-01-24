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

  String get productId {
    switch (this) {
      case SubscriptionTier.basic:
        return 'basic_free';
      case SubscriptionTier.silver:
        return 'silver_premium_monthly';
      case SubscriptionTier.gold:
        return 'gold_premium_monthly';
      case SubscriptionTier.platinum:
        return 'platinum_vip_monthly';
      case SubscriptionTier.test:
        return 'test_user';
    }
  }

  /// Check if this tier bypasses countdown restrictions
  bool get bypassesCountdown {
    return this == SubscriptionTier.test;
  }

  /// Check if this tier has early access (March 1st, 2026)
  bool get hasEarlyAccess {
    return this == SubscriptionTier.platinum ||
           this == SubscriptionTier.gold ||
           this == SubscriptionTier.silver ||
           this == SubscriptionTier.test; // Test users always have access
  }

  /// Get the access date for this tier
  DateTime get accessDate {
    // Test users have immediate access (bypass countdown)
    if (this == SubscriptionTier.test) {
      return DateTime.now().subtract(const Duration(days: 1)); // Always in the past
    }
    if (hasEarlyAccess) {
      return DateTime(2026, 3, 1); // March 1st, 2026 for Platinum, Gold, Silver
    }
    return DateTime(2026, 3, 15); // March 15th, 2026 for Basic users
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
          'adFree': false,
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
          'adFree': true,
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
          'adFree': true,
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
          'adFree': true,
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
          'adFree': true,
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
/// Represents a user's subscription to premium features
class Subscription extends Equatable {
  final String subscriptionId;
  final String userId;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? nextBillingDate;
  final bool autoRenew;
  final String? cancellationReason;
  final DateTime? cancelledAt;

  // Payment information
  final String? platform; // 'android', 'ios', 'web'
  final String? purchaseToken;
  final String? transactionId;
  final String? orderId;

  // Grace period (Point 153)
  final bool inGracePeriod;
  final DateTime? gracePeriodEndDate;

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
    this.nextBillingDate,
    this.autoRenew = true,
    this.cancellationReason,
    this.cancelledAt,
    this.platform,
    this.purchaseToken,
    this.transactionId,
    this.orderId,
    this.inGracePeriod = false,
    this.gracePeriodEndDate,
    required this.price,
    this.currency = 'USD',
    required this.createdAt,
    this.updatedAt,
  });

  /// Check if subscription is currently active
  bool get isActive {
    if (status != SubscriptionStatus.active &&
        status != SubscriptionStatus.cancelled) {
      return false;
    }

    if (endDate == null) return true;

    return DateTime.now().isBefore(endDate!);
  }

  /// Check if subscription will expire soon (within 3 days)
  /// Point 152: Renewal notifications
  bool get willExpireSoon {
    if (endDate == null) return false;

    final daysUntilExpiry = endDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 3 && daysUntilExpiry >= 0;
  }

  /// Check if currently in grace period
  /// Point 153: Grace period handling
  bool get isInGracePeriod {
    if (!inGracePeriod || gracePeriodEndDate == null) return false;

    return DateTime.now().isBefore(gracePeriodEndDate!);
  }

  /// Days remaining in subscription
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
    DateTime? nextBillingDate,
    bool? autoRenew,
    String? cancellationReason,
    DateTime? cancelledAt,
    String? platform,
    String? purchaseToken,
    String? transactionId,
    String? orderId,
    bool? inGracePeriod,
    DateTime? gracePeriodEndDate,
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
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      autoRenew: autoRenew ?? this.autoRenew,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      platform: platform ?? this.platform,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      transactionId: transactionId ?? this.transactionId,
      orderId: orderId ?? this.orderId,
      inGracePeriod: inGracePeriod ?? this.inGracePeriod,
      gracePeriodEndDate: gracePeriodEndDate ?? this.gracePeriodEndDate,
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
        nextBillingDate,
        autoRenew,
        cancellationReason,
        cancelledAt,
        platform,
        purchaseToken,
        transactionId,
        orderId,
        inGracePeriod,
        gracePeriodEndDate,
        price,
        currency,
        createdAt,
        updatedAt,
      ];
}
