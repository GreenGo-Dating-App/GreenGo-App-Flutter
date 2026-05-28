import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/membership.dart';
import '../models/membership_model.dart';

/// Membership data source.
///
/// Coupon admin operations (create / update / delete / list) have moved to
/// the admin panel + Cloud Functions for security. Coupon redemption is
/// performed via the `redeemCoupon` callable — see the next commit for the
/// implementation; this commit leaves a guarded stub so the legacy
/// Firestore-direct path is gone but the widget continues to compile.
abstract class MembershipRemoteDataSource {
  Future<MembershipModel?> getMembership(String userId);
  Future<MembershipModel> saveMembership(MembershipModel membership);

  /// Redeem a coupon code via the secure server callable.
  /// Throws on any validation failure (expired, limit reached, wrong email,
  /// already redeemed, not found, disabled).
  Future<CouponRedeemResult> redeemCouponCode({
    required String userId,
    required String couponCode,
  });

  Future<MembershipRulesModel?> getTierRulesConfig(MembershipTier tier);
  Future<void> updateTierRulesConfig(MembershipTier tier, MembershipRulesModel rules);
}

/// Lightweight result returned by the server when redemption succeeds.
class CouponRedeemResult {
  final String type; // 'membership' | 'base_membership' | 'coins'
  final MembershipTier? tier;
  final int? coinAmount;
  final int durationDays;
  final DateTime? newEndDate;
  final String grantSummary;

  const CouponRedeemResult({
    required this.type,
    required this.durationDays,
    required this.grantSummary,
    this.tier,
    this.coinAmount,
    this.newEndDate,
  });
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
  Future<CouponRedeemResult> redeemCouponCode({
    required String userId,
    required String couponCode,
  }) async {
    // Stubbed — wired to the redeemCoupon callable in the next commit.
    // The legacy client-side path that wrote to Firestore directly has been
    // removed in this commit because it bypassed max-use and email gates.
    throw UnimplementedError(
      'redeemCouponCode is being rewired to the redeemCoupon callable',
    );
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
}
