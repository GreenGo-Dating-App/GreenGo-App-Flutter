import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coin_promotion.dart';

/// Coin Promotion Model for Firestore serialization
class CoinPromotionModel extends CoinPromotion {
  const CoinPromotionModel({
    required super.promotionId,
    required super.name,
    required super.description,
    required super.type,
    super.bonusPercentage,
    super.bonusCoins,
    required super.startDate,
    required super.endDate,
    super.isActive,
    super.applicablePackageIds,
    super.minPurchaseAmount,
    super.bannerImageUrl,
    super.promoCode,
  });

  /// Create from Firestore document
  factory CoinPromotionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CoinPromotionModel(
      promotionId: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      type: _parseType(data['type'] as String),
      bonusPercentage: (data['bonusPercentage'] as num?)?.toInt(),
      bonusCoins: (data['bonusCoins'] as num?)?.toInt(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      applicablePackageIds: (data['applicablePackageIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      minPurchaseAmount: (data['minPurchaseAmount'] as num?)?.toInt(),
      bannerImageUrl: data['bannerImageUrl'] as String?,
      promoCode: data['promoCode'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'bonusPercentage': bonusPercentage,
      'bonusCoins': bonusCoins,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'applicablePackageIds': applicablePackageIds,
      'minPurchaseAmount': minPurchaseAmount,
      'bannerImageUrl': bannerImageUrl,
      'promoCode': promoCode,
    };
  }

  /// Parse promotion type
  static PromotionType _parseType(String value) {
    switch (value.toLowerCase()) {
      case 'percentagebonus':
        return PromotionType.percentageBonus;
      case 'flatbonus':
        return PromotionType.flatBonus;
      case 'firstpurchase':
        return PromotionType.firstPurchase;
      case 'seasonal':
        return PromotionType.seasonal;
      case 'flashsale':
        return PromotionType.flashSale;
      case 'bulkdiscount':
        return PromotionType.bulkDiscount;
      default:
        return PromotionType.percentageBonus;
    }
  }
}
