import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/entities/membership.dart';
import '../models/membership_model.dart';

/// Membership data source.
///
/// Coupon administration lives entirely in the admin panel + Cloud Functions.
/// There is NO client-side redemption path: App Store Review Guideline 3.1.1
/// forbids unlocking paid functionality by any mechanism other than In-App
/// Purchase, so the code-entry surfaces were removed in v4.0.0. Entitlements
/// are granted server-side instead.
/// Firestore — so max-redemption caps, email gates, and per-user one-shot
/// enforcement happen server-side.
abstract class MembershipRemoteDataSource {
  Future<MembershipModel?> getMembership(String userId);
  Future<MembershipModel> saveMembership(MembershipModel membership);

  Future<MembershipRulesModel?> getTierRulesConfig(MembershipTier tier);
  Future<void> updateTierRulesConfig(MembershipTier tier, MembershipRulesModel rules);
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
