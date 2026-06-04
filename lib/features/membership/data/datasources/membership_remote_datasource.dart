import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/membership.dart';
import '../models/membership_model.dart';

/// Membership data source.
///
/// Coupon admin operations (create / update / delete / list) live in the
/// admin panel + Cloud Functions for security. Coupon redemption is
/// performed via the `redeemCoupon` callable — never directly against
/// Firestore — so max-redemption caps, email gates, and per-user one-shot
/// enforcement happen server-side.
abstract class MembershipRemoteDataSource {
  Future<MembershipModel?> getMembership(String userId);
  Future<MembershipModel> saveMembership(MembershipModel membership);

  /// Redeem a coupon code via the secure server callable.
  /// Throws a [CouponFailure] subclass on any validation failure.
  Future<CouponRedeemResult> redeemCouponCode({
    required String userId,
    required String couponCode,
  });

  Future<MembershipRulesModel?> getTierRulesConfig(MembershipTier tier);
  Future<void> updateTierRulesConfig(MembershipTier tier, MembershipRulesModel rules);
}

/// Lightweight result returned by the server when redemption succeeds.
class CouponRedeemResult {

  const CouponRedeemResult({
    required this.type,
    required this.durationDays,
    required this.grantSummary,
    this.tier,
    this.coinAmount,
    this.newEndDate,
  });
  final String type; // 'membership' | 'base_membership' | 'coins'
  final MembershipTier? tier;
  final int? coinAmount;
  final int durationDays;
  final DateTime? newEndDate;
  final String grantSummary;
}

/// Base class for all coupon-redemption failures. UI layer should switch on
/// the runtimeType to pick a localized message.
sealed class CouponFailure implements Exception {
  const CouponFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class CouponNotFoundFailure extends CouponFailure {
  const CouponNotFoundFailure([super.message = 'Coupon code not found']);
}

class CouponExpiredFailure extends CouponFailure {
  const CouponExpiredFailure([super.message = 'This coupon has expired']);
}

class CouponMaxReachedFailure extends CouponFailure {
  const CouponMaxReachedFailure([super.message = 'This coupon has reached its usage limit']);
}

class CouponDisabledFailure extends CouponFailure {
  const CouponDisabledFailure([super.message = 'This coupon is no longer active']);
}

class CouponEmailMismatchFailure extends CouponFailure {
  const CouponEmailMismatchFailure([super.message = 'This coupon is restricted to a different account']);
}

class CouponAlreadyRedeemedFailure extends CouponFailure {
  const CouponAlreadyRedeemedFailure([super.message = 'You have already used this coupon']);
}

class CouponGenericFailure extends CouponFailure {
  const CouponGenericFailure([super.message = 'Could not redeem coupon']);
}

class MembershipRemoteDataSourceImpl implements MembershipRemoteDataSource {

  MembershipRemoteDataSourceImpl({
    required this.firestore,
    FirebaseFunctions? functions,
  }) : functions = functions ?? FirebaseFunctions.instance;
  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

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
    try {
      final callable = functions.httpsCallable('redeemCoupon');
      final response = await callable.call<Map<String, dynamic>>({
        'code': couponCode.trim().toUpperCase(),
      });
      final data = response.data;
      final type = data['type'] as String;
      MembershipTier? tier;
      final tierStr = data['tier'] as String?;
      if (tierStr != null) {
        tier = MembershipTier.values.firstWhere(
          (t) => t.value == tierStr,
          orElse: () => MembershipTier.silver,
        );
      }
      DateTime? newEndDate;
      final newEndIso = data['newEndDate'] as String?;
      if (newEndIso != null) {
        newEndDate = DateTime.tryParse(newEndIso);
      }

      return CouponRedeemResult(
        type: type,
        tier: tier,
        coinAmount: (data['coinAmount'] as num?)?.toInt(),
        durationDays: (data['durationDays'] as num).toInt(),
        newEndDate: newEndDate,
        grantSummary: data['grantSummary'] as String? ?? '',
      );
    } on FirebaseFunctionsException catch (e) {
      throw _mapFunctionException(e);
    } catch (e) {
      throw const CouponGenericFailure();
    }
  }

  CouponFailure _mapFunctionException(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'not-found':
        return CouponNotFoundFailure(e.message ?? 'Coupon code not found');
      case 'failed-precondition':
        final msg = e.message ?? '';
        if (msg.contains('expired')) return CouponExpiredFailure(msg);
        if (msg.contains('limit')) return CouponMaxReachedFailure(msg);
        if (msg.contains('active')) return CouponDisabledFailure(msg);
        return CouponGenericFailure(msg.isEmpty ? 'Coupon validation failed' : msg);
      case 'permission-denied':
        return CouponEmailMismatchFailure(e.message ?? 'This coupon is restricted to a different account');
      case 'already-exists':
        return CouponAlreadyRedeemedFailure(e.message ?? 'You have already used this coupon');
      case 'unauthenticated':
        return CouponGenericFailure(e.message ?? 'Please sign in to redeem');
      default:
        return CouponGenericFailure(e.message ?? 'Could not redeem coupon');
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
}
