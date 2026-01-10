import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/coupon_code.dart';
import '../models/membership_model.dart';
import '../models/coupon_code_model.dart';

abstract class MembershipRemoteDataSource {
  /// Get user's current membership
  Future<MembershipModel?> getMembership(String userId);

  /// Create or update membership
  Future<MembershipModel> saveMembership(MembershipModel membership);

  /// Validate and get coupon code details
  Future<CouponCodeModel?> getCouponCode(String code);

  /// Redeem a coupon code for a user
  Future<MembershipModel> redeemCouponCode({
    required String userId,
    required String couponCode,
  });

  /// Check if user has already redeemed a specific coupon
  Future<bool> hasRedeemedCoupon({
    required String userId,
    required String couponCode,
  });

  /// Get all coupon codes (admin only)
  Future<List<CouponCodeModel>> getAllCouponCodes();

  /// Create a new coupon code (admin only)
  Future<CouponCodeModel> createCouponCode(CouponCodeModel coupon);

  /// Update a coupon code (admin only)
  Future<CouponCodeModel> updateCouponCode(CouponCodeModel coupon);

  /// Delete a coupon code (admin only)
  Future<void> deleteCouponCode(String code);

  /// Get membership rules configuration for a tier
  Future<MembershipRulesModel?> getTierRulesConfig(MembershipTier tier);

  /// Update membership rules configuration (admin only)
  Future<void> updateTierRulesConfig(MembershipTier tier, MembershipRulesModel rules);

  /// Get all redemption history for a coupon
  Future<List<CouponRedemptionModel>> getCouponRedemptions(String couponCode);
}

class MembershipRemoteDataSourceImpl implements MembershipRemoteDataSource {
  final FirebaseFirestore firestore;

  MembershipRemoteDataSourceImpl({required this.firestore});

  @override
  Future<MembershipModel?> getMembership(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return MembershipModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to get membership: $e');
    }
  }

  @override
  Future<MembershipModel> saveMembership(MembershipModel membership) async {
    try {
      final docRef = membership.membershipId.isEmpty
          ? firestore.collection('memberships').doc()
          : firestore.collection('memberships').doc(membership.membershipId);

      final membershipToSave = MembershipModel(
        membershipId: docRef.id,
        userId: membership.userId,
        tier: membership.tier,
        couponCode: membership.couponCode,
        startDate: membership.startDate,
        endDate: membership.endDate,
        customRules: membership.customRules,
        isActive: membership.isActive,
        createdAt: membership.createdAt,
        updatedAt: DateTime.now(),
        activatedBy: membership.activatedBy,
      );

      await docRef.set(membershipToSave.toJson());

      // Also update the user's profile with membership info
      await firestore.collection('profiles').doc(membership.userId).update({
        'membershipTier': membership.tier.value,
        'membershipStartDate': Timestamp.fromDate(membership.startDate),
        'membershipEndDate': membership.endDate != null
            ? Timestamp.fromDate(membership.endDate!)
            : null,
      });

      return membershipToSave;
    } catch (e) {
      throw Exception('Failed to save membership: $e');
    }
  }

  @override
  Future<CouponCodeModel?> getCouponCode(String code) async {
    try {
      final docSnapshot = await firestore
          .collection('coupon_codes')
          .doc(code.toUpperCase())
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      return CouponCodeModel.fromFirestore(docSnapshot);
    } catch (e) {
      throw Exception('Failed to get coupon code: $e');
    }
  }

  @override
  Future<MembershipModel> redeemCouponCode({
    required String userId,
    required String couponCode,
  }) async {
    try {
      final code = couponCode.toUpperCase();

      // Get the coupon
      final coupon = await getCouponCode(code);
      if (coupon == null) {
        throw Exception('Invalid coupon code');
      }

      // Validate coupon
      if (!coupon.isValid) {
        if (!coupon.isActive) {
          throw Exception('This coupon is no longer active');
        }
        if (coupon.validUntil != null && DateTime.now().isAfter(coupon.validUntil!)) {
          throw Exception('This coupon has expired');
        }
        if (coupon.maxUses != null && coupon.currentUses >= coupon.maxUses!) {
          throw Exception('This coupon has reached its usage limit');
        }
        throw Exception('This coupon is not valid');
      }

      // Check if user already redeemed this coupon
      final hasRedeemed = await hasRedeemedCoupon(userId: userId, couponCode: code);
      if (hasRedeemed) {
        throw Exception('You have already used this coupon');
      }

      // Deactivate any existing active membership
      final existingMembership = await getMembership(userId);
      if (existingMembership != null && existingMembership.tier != MembershipTier.free) {
        await firestore
            .collection('memberships')
            .doc(existingMembership.membershipId)
            .update({'isActive': false});
      }

      // Calculate end date
      DateTime? endDate;
      if (coupon.durationDays != null) {
        endDate = DateTime.now().add(Duration(days: coupon.durationDays!));
      }

      // Create new membership
      final now = DateTime.now();
      final membershipRef = firestore.collection('memberships').doc();
      final newMembership = MembershipModel(
        membershipId: membershipRef.id,
        userId: userId,
        tier: coupon.tier,
        couponCode: code,
        startDate: now,
        endDate: endDate,
        customRules: coupon.customRules,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      await membershipRef.set(newMembership.toJson());

      // Record redemption
      final redemptionRef = firestore.collection('coupon_redemptions').doc();
      await redemptionRef.set({
        'redemptionId': redemptionRef.id,
        'couponCode': code,
        'userId': userId,
        'membershipId': membershipRef.id,
        'redeemedAt': Timestamp.fromDate(now),
      });

      // Increment coupon usage count
      await firestore.collection('coupon_codes').doc(code).update({
        'currentUses': FieldValue.increment(1),
      });

      // Update user's profile with new membership
      await firestore.collection('profiles').doc(userId).update({
        'membershipTier': coupon.tier.value,
        'membershipStartDate': Timestamp.fromDate(now),
        'membershipEndDate': endDate != null ? Timestamp.fromDate(endDate) : null,
      });

      return newMembership;
    } catch (e) {
      throw Exception('Failed to redeem coupon: $e');
    }
  }

  @override
  Future<bool> hasRedeemedCoupon({
    required String userId,
    required String couponCode,
  }) async {
    try {
      final querySnapshot = await firestore
          .collection('coupon_redemptions')
          .where('userId', isEqualTo: userId)
          .where('couponCode', isEqualTo: couponCode.toUpperCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<CouponCodeModel>> getAllCouponCodes() async {
    try {
      final querySnapshot = await firestore
          .collection('coupon_codes')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CouponCodeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get coupon codes: $e');
    }
  }

  @override
  Future<CouponCodeModel> createCouponCode(CouponCodeModel coupon) async {
    try {
      final code = coupon.code.toUpperCase();
      final docRef = firestore.collection('coupon_codes').doc(code);

      // Check if code already exists
      final existing = await docRef.get();
      if (existing.exists) {
        throw Exception('Coupon code already exists');
      }

      final couponToSave = CouponCodeModel(
        code: code,
        name: coupon.name,
        tier: coupon.tier,
        durationDays: coupon.durationDays,
        maxUses: coupon.maxUses,
        currentUses: 0,
        validFrom: coupon.validFrom,
        validUntil: coupon.validUntil,
        isActive: coupon.isActive,
        customRules: coupon.customRules,
        createdBy: coupon.createdBy,
        createdAt: DateTime.now(),
        notes: coupon.notes,
      );

      await docRef.set(couponToSave.toJson());
      return couponToSave;
    } catch (e) {
      throw Exception('Failed to create coupon code: $e');
    }
  }

  @override
  Future<CouponCodeModel> updateCouponCode(CouponCodeModel coupon) async {
    try {
      final code = coupon.code.toUpperCase();
      await firestore.collection('coupon_codes').doc(code).update(coupon.toJson());
      return coupon;
    } catch (e) {
      throw Exception('Failed to update coupon code: $e');
    }
  }

  @override
  Future<void> deleteCouponCode(String code) async {
    try {
      await firestore.collection('coupon_codes').doc(code.toUpperCase()).delete();
    } catch (e) {
      throw Exception('Failed to delete coupon code: $e');
    }
  }

  @override
  Future<MembershipRulesModel?> getTierRulesConfig(MembershipTier tier) async {
    try {
      final docSnapshot = await firestore
          .collection('membership_config')
          .doc(tier.value)
          .get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data();
      if (data == null || data['rules'] == null) {
        return null;
      }

      return MembershipRulesModel.fromJson(data['rules'] as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateTierRulesConfig(MembershipTier tier, MembershipRulesModel rules) async {
    try {
      await firestore.collection('membership_config').doc(tier.value).set({
        'tier': tier.value,
        'rules': rules.toJson(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update tier rules config: $e');
    }
  }

  @override
  Future<List<CouponRedemptionModel>> getCouponRedemptions(String couponCode) async {
    try {
      final querySnapshot = await firestore
          .collection('coupon_redemptions')
          .where('couponCode', isEqualTo: couponCode.toUpperCase())
          .orderBy('redeemedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CouponRedemptionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get coupon redemptions: $e');
    }
  }
}
