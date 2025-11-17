import 'package:equatable/equatable.dart';

/// Coin Promotion Entity
/// Point 165: Promotional campaigns with bonus percentages
class CoinPromotion extends Equatable {
  final String promotionId;
  final String name;
  final String description;
  final PromotionType type;
  final int? bonusPercentage;
  final int? bonusCoins;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<String>? applicablePackageIds;
  final int? minPurchaseAmount;
  final String? bannerImageUrl;
  final String? promoCode;

  const CoinPromotion({
    required this.promotionId,
    required this.name,
    required this.description,
    required this.type,
    this.bonusPercentage,
    this.bonusCoins,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.applicablePackageIds,
    this.minPurchaseAmount,
    this.bannerImageUrl,
    this.promoCode,
  });

  /// Check if promotion is currently active
  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Check if package is applicable
  bool isPackageApplicable(String packageId) {
    if (applicablePackageIds == null || applicablePackageIds!.isEmpty) {
      return true; // Applies to all packages
    }
    return applicablePackageIds!.contains(packageId);
  }

  /// Calculate bonus coins for a purchase
  int calculateBonus(int baseCoins, double purchasePrice) {
    if (bonusPercentage != null) {
      return (baseCoins * bonusPercentage! / 100).round();
    }
    if (bonusCoins != null) {
      return bonusCoins!;
    }
    return 0;
  }

  /// Get promotion display text
  String get displayText {
    if (bonusPercentage != null) {
      return '+$bonusPercentage% Bonus Coins';
    }
    if (bonusCoins != null) {
      return '+$bonusCoins Bonus Coins';
    }
    return description;
  }

  @override
  List<Object?> get props => [
        promotionId,
        name,
        description,
        type,
        bonusPercentage,
        bonusCoins,
        startDate,
        endDate,
        isActive,
        applicablePackageIds,
        minPurchaseAmount,
        bannerImageUrl,
        promoCode,
      ];
}

/// Type of promotion
enum PromotionType {
  percentageBonus,  // X% extra coins
  flatBonus,        // Fixed amount of extra coins
  firstPurchase,    // First-time purchase bonus
  seasonal,         // Holiday/seasonal promotion
  flashSale,        // Limited time flash sale
  bulkDiscount,     // Discount on larger packages
}

extension PromotionTypeExtension on PromotionType {
  String get displayName {
    switch (this) {
      case PromotionType.percentageBonus:
        return 'Percentage Bonus';
      case PromotionType.flatBonus:
        return 'Bonus Coins';
      case PromotionType.firstPurchase:
        return 'First Purchase Bonus';
      case PromotionType.seasonal:
        return 'Seasonal Offer';
      case PromotionType.flashSale:
        return 'Flash Sale';
      case PromotionType.bulkDiscount:
        return 'Bulk Discount';
    }
  }
}

/// Standard promotional campaigns
class CoinPromotions {
  /// Black Friday: 50% bonus coins
  static CoinPromotion blackFriday({
    required int year,
  }) {
    return CoinPromotion(
      promotionId: 'black_friday_$year',
      name: 'Black Friday Sale',
      description: 'Get 50% extra coins on all packages!',
      type: PromotionType.seasonal,
      bonusPercentage: 50,
      startDate: DateTime(year, 11, 24), // Black Friday
      endDate: DateTime(year, 11, 28),   // Cyber Monday
    );
  }

  /// New Year: 40% bonus
  static CoinPromotion newYear({
    required int year,
  }) {
    return CoinPromotion(
      promotionId: 'new_year_$year',
      name: 'New Year Bonus',
      description: 'Start the year with 40% extra coins!',
      type: PromotionType.seasonal,
      bonusPercentage: 40,
      startDate: DateTime(year, 1, 1),
      endDate: DateTime(year, 1, 7),
    );
  }

  /// Valentine's Day: 30% bonus
  static CoinPromotion valentines({
    required int year,
  }) {
    return CoinPromotion(
      promotionId: 'valentines_$year',
      name: "Valentine's Day Special",
      description: 'Find love with 30% extra coins!',
      type: PromotionType.seasonal,
      bonusPercentage: 30,
      startDate: DateTime(year, 2, 10),
      endDate: DateTime(year, 2, 15),
    );
  }

  /// First purchase bonus: 100 coins
  static const CoinPromotion firstPurchase = CoinPromotion(
    promotionId: 'first_purchase_bonus',
    name: 'First Purchase Bonus',
    description: 'Get 100 bonus coins on your first purchase!',
    type: PromotionType.firstPurchase,
    bonusCoins: 100,
    startDate: null, // Always active
    endDate: null,   // Never expires
    isActive: true,
  );

  /// Weekend flash sale: 25% bonus
  static CoinPromotion weekendFlash({
    required DateTime weekendStart,
  }) {
    return CoinPromotion(
      promotionId: 'weekend_flash_${weekendStart.millisecondsSinceEpoch}',
      name: 'Weekend Flash Sale',
      description: '48 hours only - 25% extra coins!',
      type: PromotionType.flashSale,
      bonusPercentage: 25,
      startDate: weekendStart,
      endDate: weekendStart.add(const Duration(hours: 48)),
    );
  }
}

extension CoinPromotionNullable on CoinPromotion? {
  static CoinPromotion? fromStartAndEndDate(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return CoinPromotions.firstPurchase;
    }
    return null;
  }
}
