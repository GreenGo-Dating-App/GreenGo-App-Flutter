import 'package:equatable/equatable.dart';
import 'membership.dart';

/// Coupon Code Entity
/// Represents a redeemable code for membership activation
class CouponCode extends Equatable {
  /// Unique coupon code (the actual code users enter)
  final String code;

  /// Display name/description for the coupon
  final String name;

  /// Membership tier this coupon grants
  final MembershipTier tier;

  /// Duration in days (null for lifetime)
  final int? durationDays;

  /// Maximum number of times this code can be used (null for unlimited)
  final int? maxUses;

  /// Current number of times this code has been used
  final int currentUses;

  /// When this coupon becomes valid
  final DateTime validFrom;

  /// When this coupon expires (null for no expiration)
  final DateTime? validUntil;

  /// Whether the coupon is currently active
  final bool isActive;

  /// Custom rules override (optional)
  final MembershipRules? customRules;

  /// Admin who created this coupon
  final String createdBy;

  /// When the coupon was created
  final DateTime createdAt;

  /// Notes/description for admin reference
  final String? notes;

  const CouponCode({
    required this.code,
    required this.name,
    required this.tier,
    this.durationDays,
    this.maxUses,
    required this.currentUses,
    required this.validFrom,
    this.validUntil,
    required this.isActive,
    this.customRules,
    required this.createdBy,
    required this.createdAt,
    this.notes,
  });

  /// Check if the coupon is still valid and can be used
  bool get isValid {
    if (!isActive) return false;

    final now = DateTime.now();

    // Check if coupon has started
    if (now.isBefore(validFrom)) return false;

    // Check if coupon has expired
    if (validUntil != null && now.isAfter(validUntil!)) return false;

    // Check max uses
    if (maxUses != null && currentUses >= maxUses!) return false;

    return true;
  }

  /// Check remaining uses (null if unlimited)
  int? get remainingUses {
    if (maxUses == null) return null;
    return maxUses! - currentUses;
  }

  /// Get duration display text
  String get durationText {
    if (durationDays == null) return 'Lifetime';
    if (durationDays! == 30) return '1 month';
    if (durationDays! == 90) return '3 months';
    if (durationDays! == 180) return '6 months';
    if (durationDays! == 365) return '1 year';
    return '$durationDays days';
  }

  @override
  List<Object?> get props => [
        code,
        name,
        tier,
        durationDays,
        maxUses,
        currentUses,
        validFrom,
        validUntil,
        isActive,
        customRules,
        createdBy,
        createdAt,
        notes,
      ];
}

/// Coupon Redemption Record
/// Tracks when a user redeems a coupon
class CouponRedemption extends Equatable {
  /// Unique redemption ID
  final String redemptionId;

  /// The coupon code that was redeemed
  final String couponCode;

  /// User who redeemed the coupon
  final String userId;

  /// Membership ID that was created from this redemption
  final String membershipId;

  /// When the redemption occurred
  final DateTime redeemedAt;

  /// IP address for fraud detection (optional)
  final String? ipAddress;

  const CouponRedemption({
    required this.redemptionId,
    required this.couponCode,
    required this.userId,
    required this.membershipId,
    required this.redeemedAt,
    this.ipAddress,
  });

  @override
  List<Object?> get props => [
        redemptionId,
        couponCode,
        userId,
        membershipId,
        redeemedAt,
        ipAddress,
      ];
}
