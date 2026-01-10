import 'package:equatable/equatable.dart';

/// Video Coin Entity
/// Special coins used exclusively for video calling
/// Users can only make video calls if they have video coins
class VideoCoinBalance extends Equatable {
  final String userId;
  final int totalVideoCoins;
  final int usedVideoCoins;
  final DateTime lastUpdated;

  const VideoCoinBalance({
    required this.userId,
    required this.totalVideoCoins,
    required this.usedVideoCoins,
    required this.lastUpdated,
  });

  /// Get available video coins
  int get availableVideoCoins => totalVideoCoins - usedVideoCoins;

  /// Check if user has enough video coins for a call
  bool canMakeVideoCall({int minutesCost = 1}) {
    return availableVideoCoins >= minutesCost;
  }

  /// Create empty balance
  factory VideoCoinBalance.empty(String userId) {
    return VideoCoinBalance(
      userId: userId,
      totalVideoCoins: 0,
      usedVideoCoins: 0,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        totalVideoCoins,
        usedVideoCoins,
        lastUpdated,
      ];
}

/// Video Coin Package for purchase
class VideoCoinPackage extends Equatable {
  final String packageId;
  final String productId;
  final int videoMinutes; // Each video coin = 1 minute of video call
  final double price;
  final String currency;
  final int? bonusMinutes;
  final bool isPopular;
  final String? badge;

  const VideoCoinPackage({
    required this.packageId,
    required this.productId,
    required this.videoMinutes,
    required this.price,
    this.currency = 'USD',
    this.bonusMinutes,
    this.isPopular = false,
    this.badge,
  });

  /// Get total minutes including bonus
  int get totalMinutes => videoMinutes + (bonusMinutes ?? 0);

  /// Get price per minute
  double get pricePerMinute => price / totalMinutes;

  /// Get display price
  String get displayPrice {
    if (currency == 'USD') {
      return '\$${price.toStringAsFixed(2)}';
    }
    return '$currency ${price.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        packageId,
        productId,
        videoMinutes,
        price,
        currency,
        bonusMinutes,
        isPopular,
        badge,
      ];
}

/// Standard Video Coin Packages
class VideoCoinPackages {
  /// Starter: 10 minutes for $1.99
  static const VideoCoinPackage starter = VideoCoinPackage(
    packageId: 'video_starter_10',
    productId: 'greengo_video_10',
    videoMinutes: 10,
    price: 1.99,
  );

  /// Popular: 30 minutes for $4.99
  static const VideoCoinPackage popular = VideoCoinPackage(
    packageId: 'video_popular_30',
    productId: 'greengo_video_30',
    videoMinutes: 30,
    price: 4.99,
    bonusMinutes: 5,
    isPopular: true,
    badge: 'BEST VALUE',
  );

  /// Premium: 60 minutes for $8.99
  static const VideoCoinPackage premium = VideoCoinPackage(
    packageId: 'video_premium_60',
    productId: 'greengo_video_60',
    videoMinutes: 60,
    price: 8.99,
    bonusMinutes: 15,
  );

  /// Ultimate: 120 minutes for $14.99
  static const VideoCoinPackage ultimate = VideoCoinPackage(
    packageId: 'video_ultimate_120',
    productId: 'greengo_video_120',
    videoMinutes: 120,
    price: 14.99,
    bonusMinutes: 30,
    badge: 'SAVE 25%',
  );

  static List<VideoCoinPackage> get all => [
        starter,
        popular,
        premium,
        ultimate,
      ];

  static VideoCoinPackage? getByProductId(String productId) {
    try {
      return all.firstWhere((pkg) => pkg.productId == productId);
    } catch (e) {
      return null;
    }
  }
}

/// Video Coin Transaction
class VideoCoinTransaction extends Equatable {
  final String transactionId;
  final String userId;
  final VideoCoinTransactionType type;
  final int minutes;
  final int balanceAfter;
  final String? relatedUserId; // For calls
  final String? callId;
  final DateTime createdAt;

  const VideoCoinTransaction({
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.minutes,
    required this.balanceAfter,
    this.relatedUserId,
    this.callId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        transactionId,
        userId,
        type,
        minutes,
        balanceAfter,
        relatedUserId,
        callId,
        createdAt,
      ];
}

/// Video Coin Transaction Type
enum VideoCoinTransactionType {
  purchase, // Purchased video minutes
  gift,     // Received as gift
  used,     // Used for video call
  refund,   // Refunded from cancelled call
  bonus,    // Bonus from promotion or subscription
  expired,  // Expired unused minutes
}

extension VideoCoinTransactionTypeExtension on VideoCoinTransactionType {
  String get displayName {
    switch (this) {
      case VideoCoinTransactionType.purchase:
        return 'Purchase';
      case VideoCoinTransactionType.gift:
        return 'Gift Received';
      case VideoCoinTransactionType.used:
        return 'Video Call';
      case VideoCoinTransactionType.refund:
        return 'Refund';
      case VideoCoinTransactionType.bonus:
        return 'Bonus';
      case VideoCoinTransactionType.expired:
        return 'Expired';
    }
  }

  bool get isCredit {
    return this == VideoCoinTransactionType.purchase ||
        this == VideoCoinTransactionType.gift ||
        this == VideoCoinTransactionType.refund ||
        this == VideoCoinTransactionType.bonus;
  }
}
