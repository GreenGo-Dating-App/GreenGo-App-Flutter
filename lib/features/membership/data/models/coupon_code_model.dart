import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/coupon_code.dart';
import 'membership_model.dart';

/// Coupon Code Model
/// Firestore serialization for CouponCode
class CouponCodeModel extends CouponCode {
  const CouponCodeModel({
    required super.code,
    required super.name,
    required super.tier,
    super.durationDays,
    super.maxUses,
    required super.currentUses,
    required super.validFrom,
    super.validUntil,
    required super.isActive,
    super.customRules,
    required super.createdBy,
    required super.createdAt,
    super.notes,
  });

  factory CouponCodeModel.fromJson(Map<String, dynamic> json) {
    return CouponCodeModel(
      code: json['code'] as String,
      name: json['name'] as String,
      tier: MembershipTier.fromString(json['tier'] as String),
      durationDays: json['durationDays'] as int?,
      maxUses: json['maxUses'] as int?,
      currentUses: json['currentUses'] as int? ?? 0,
      validFrom: (json['validFrom'] as Timestamp).toDate(),
      validUntil: json['validUntil'] != null
          ? (json['validUntil'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] as bool? ?? true,
      customRules: json['customRules'] != null
          ? MembershipRulesModel.fromJson(
              json['customRules'] as Map<String, dynamic>)
          : null,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      notes: json['notes'] as String?,
    );
  }

  factory CouponCodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponCodeModel.fromJson({...data, 'code': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'tier': tier.value,
      'durationDays': durationDays,
      'maxUses': maxUses,
      'currentUses': currentUses,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'isActive': isActive,
      'customRules': customRules != null
          ? MembershipRulesModel.fromEntity(customRules!).toJson()
          : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
    };
  }

  factory CouponCodeModel.fromEntity(CouponCode coupon) {
    return CouponCodeModel(
      code: coupon.code,
      name: coupon.name,
      tier: coupon.tier,
      durationDays: coupon.durationDays,
      maxUses: coupon.maxUses,
      currentUses: coupon.currentUses,
      validFrom: coupon.validFrom,
      validUntil: coupon.validUntil,
      isActive: coupon.isActive,
      customRules: coupon.customRules,
      createdBy: coupon.createdBy,
      createdAt: coupon.createdAt,
      notes: coupon.notes,
    );
  }

  /// Create a copy with incremented use count
  CouponCodeModel incrementUseCount() {
    return CouponCodeModel(
      code: code,
      name: name,
      tier: tier,
      durationDays: durationDays,
      maxUses: maxUses,
      currentUses: currentUses + 1,
      validFrom: validFrom,
      validUntil: validUntil,
      isActive: isActive,
      customRules: customRules,
      createdBy: createdBy,
      createdAt: createdAt,
      notes: notes,
    );
  }
}

/// Coupon Redemption Model
/// Firestore serialization for CouponRedemption
class CouponRedemptionModel extends CouponRedemption {
  const CouponRedemptionModel({
    required super.redemptionId,
    required super.couponCode,
    required super.userId,
    required super.membershipId,
    required super.redeemedAt,
    super.ipAddress,
  });

  factory CouponRedemptionModel.fromJson(Map<String, dynamic> json) {
    return CouponRedemptionModel(
      redemptionId: json['redemptionId'] as String,
      couponCode: json['couponCode'] as String,
      userId: json['userId'] as String,
      membershipId: json['membershipId'] as String,
      redeemedAt: (json['redeemedAt'] as Timestamp).toDate(),
      ipAddress: json['ipAddress'] as String?,
    );
  }

  factory CouponRedemptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CouponRedemptionModel.fromJson({...data, 'redemptionId': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'redemptionId': redemptionId,
      'couponCode': couponCode,
      'userId': userId,
      'membershipId': membershipId,
      'redeemedAt': Timestamp.fromDate(redeemedAt),
      'ipAddress': ipAddress,
    };
  }
}
