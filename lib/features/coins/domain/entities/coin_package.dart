import 'package:equatable/equatable.dart';

/// Coin Package Entity
/// Point 157: Coin packages with various amounts and prices
class CoinPackage extends Equatable {
  final String packageId;
  final String productId; // For in-app purchases
  final int coinAmount;
  final double price;
  final String currency;
  final int? bonusCoins;
  final double? discountPercentage;
  final bool isPromotional;
  final DateTime? promotionStartDate;
  final DateTime? promotionEndDate;
  final String? promotionLabel;

  const CoinPackage({
    required this.packageId,
    required this.productId,
    required this.coinAmount,
    required this.price,
    this.currency = 'USD',
    this.bonusCoins,
    this.discountPercentage,
    this.isPromotional = false,
    this.promotionStartDate,
    this.promotionEndDate,
    this.promotionLabel,
  });

  /// Get total coins including bonus
  int get totalCoins => coinAmount + (bonusCoins ?? 0);

  /// Get coins per dollar value
  double get coinsPerDollar => totalCoins / price;

  /// Check if promotion is active
  bool get isPromotionActive {
    if (!isPromotional) return false;
    final now = DateTime.now();
    if (promotionStartDate != null && now.isBefore(promotionStartDate!)) {
      return false;
    }
    if (promotionEndDate != null && now.isAfter(promotionEndDate!)) {
      return false;
    }
    return true;
  }

  /// Get display price
  String get displayPrice {
    if (currency == 'USD') {
      return '\$${price.toStringAsFixed(2)}';
    }
    return '$currency ${price.toStringAsFixed(2)}';
  }

  /// Get savings text for promotional packages
  String? get savingsText {
    if (bonusCoins != null && bonusCoins! > 0) {
      return '+${bonusCoins} bonus coins';
    }
    if (discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toInt()}% off';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        packageId,
        productId,
        coinAmount,
        price,
        currency,
        bonusCoins,
        discountPercentage,
        isPromotional,
        promotionStartDate,
        promotionEndDate,
        promotionLabel,
      ];
}

/// Standard coin packages (Point 157)
class CoinPackages {
  /// Starter package: 100 coins for $0.99
  static const CoinPackage starter = CoinPackage(
    packageId: 'starter_100',
    productId: 'greengo_coins_100',
    coinAmount: 100,
    price: 0.99,
  );

  /// Popular package: 500 coins for $3.99
  static const CoinPackage popular = CoinPackage(
    packageId: 'popular_500',
    productId: 'greengo_coins_500',
    coinAmount: 500,
    price: 3.99,
  );

  /// Value package: 1000 coins for $6.99
  static const CoinPackage value = CoinPackage(
    packageId: 'value_1000',
    productId: 'greengo_coins_1000',
    coinAmount: 1000,
    price: 6.99,
  );

  /// Premium package: 5000 coins for $29.99
  static const CoinPackage premium = CoinPackage(
    packageId: 'premium_5000',
    productId: 'greengo_coins_5000',
    coinAmount: 5000,
    price: 29.99,
  );

  /// Get all standard packages
  static List<CoinPackage> get standardPackages => [
        starter,
        popular,
        value,
        premium,
      ];

  /// Get package by product ID
  static CoinPackage? getByProductId(String productId) {
    try {
      return standardPackages.firstWhere(
        (pkg) => pkg.productId == productId,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Coin Spend Item
/// Defines what users can spend coins on (admin-configurable)
class CoinSpendItem extends Equatable {
  final String itemId;
  final String name;
  final String description;
  final int coinCost;
  final String iconAsset;
  final CoinSpendCategory category;
  final bool isActive;
  final int sortOrder;

  const CoinSpendItem({
    required this.itemId,
    required this.name,
    required this.description,
    required this.coinCost,
    required this.iconAsset,
    required this.category,
    this.isActive = true,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props => [
        itemId,
        name,
        description,
        coinCost,
        iconAsset,
        category,
        isActive,
        sortOrder,
      ];
}

enum CoinSpendCategory {
  matching,
  messaging,
  profile,
  gifts,
}

extension CoinSpendCategoryExtension on CoinSpendCategory {
  String get displayName {
    switch (this) {
      case CoinSpendCategory.matching:
        return 'Matching';
      case CoinSpendCategory.messaging:
        return 'Messaging';
      case CoinSpendCategory.profile:
        return 'Profile';
      case CoinSpendCategory.gifts:
        return 'Virtual Gifts';
    }
  }
}

/// Predefined Coin Spend Items
class CoinSpendItems {
  static const CoinSpendItem superLike = CoinSpendItem(
    itemId: 'super_like',
    name: 'Super Like',
    description: 'Send a super like to stand out',
    coinCost: 5,
    iconAsset: 'assets/icons/super_like.png',
    category: CoinSpendCategory.matching,
    sortOrder: 1,
  );

  static const CoinSpendItem boost = CoinSpendItem(
    itemId: 'profile_boost',
    name: 'Profile Boost',
    description: 'Be seen by more people for 30 mins',
    coinCost: 50,
    iconAsset: 'assets/icons/boost.png',
    category: CoinSpendCategory.profile,
    sortOrder: 2,
  );

  static const CoinSpendItem undo = CoinSpendItem(
    itemId: 'undo_swipe',
    name: 'Undo Swipe',
    description: 'Undo your last swipe',
    coinCost: 3,
    iconAsset: 'assets/icons/undo.png',
    category: CoinSpendCategory.matching,
    sortOrder: 3,
  );

  static const CoinSpendItem seeWhoLiked = CoinSpendItem(
    itemId: 'see_who_liked',
    name: 'See Who Liked',
    description: 'See who liked your profile',
    coinCost: 20,
    iconAsset: 'assets/icons/see_likes.png',
    category: CoinSpendCategory.matching,
    sortOrder: 4,
  );

  static const CoinSpendItem readReceipts = CoinSpendItem(
    itemId: 'read_receipts_day',
    name: 'Read Receipts (1 Day)',
    description: 'See when messages are read',
    coinCost: 10,
    iconAsset: 'assets/icons/read_receipts.png',
    category: CoinSpendCategory.messaging,
    sortOrder: 5,
  );

  static const CoinSpendItem virtualGiftRose = CoinSpendItem(
    itemId: 'gift_rose',
    name: 'Rose',
    description: 'Send a virtual rose',
    coinCost: 15,
    iconAsset: 'assets/icons/rose.png',
    category: CoinSpendCategory.gifts,
    sortOrder: 6,
  );

  static const CoinSpendItem virtualGiftTeddy = CoinSpendItem(
    itemId: 'gift_teddy',
    name: 'Teddy Bear',
    description: 'Send a cute teddy bear',
    coinCost: 50,
    iconAsset: 'assets/icons/teddy.png',
    category: CoinSpendCategory.gifts,
    sortOrder: 7,
  );

  static const CoinSpendItem virtualGiftDiamond = CoinSpendItem(
    itemId: 'gift_diamond',
    name: 'Diamond',
    description: 'Send a sparkling diamond',
    coinCost: 100,
    iconAsset: 'assets/icons/diamond.png',
    category: CoinSpendCategory.gifts,
    sortOrder: 8,
  );

  static const List<CoinSpendItem> all = [
    superLike,
    boost,
    undo,
    seeWhoLiked,
    readReceipts,
    virtualGiftRose,
    virtualGiftTeddy,
    virtualGiftDiamond,
  ];

  static List<CoinSpendItem> getByCategory(CoinSpendCategory category) {
    return all.where((item) => item.category == category).toList();
  }

  static CoinSpendItem? getById(String itemId) {
    try {
      return all.firstWhere((item) => item.itemId == itemId);
    } catch (e) {
      return null;
    }
  }
}
