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
