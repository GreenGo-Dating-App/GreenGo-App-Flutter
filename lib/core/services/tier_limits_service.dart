import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/membership/domain/entities/membership.dart';
import 'effective_tier.dart';
import 'entitlement_usage.dart';
import 'tier_entitlements.dart';

/// Result of a tier-limit check.
class TierLimitResult {
  const TierLimitResult({
    required this.allowed,
    required this.tier,
    required this.current,
    required this.max,
  });

  final bool allowed;
  final MembershipTier tier;
  final int current;

  /// null = unlimited.
  final int? max;
}

/// Per-tier caps on how many events / groups a user can create.
///
/// Caps ([TierEntitlements]):
///   free (base): 1 ongoing event, 1 group
///   silver:      3 ongoing events, unlimited groups
///   gold:        5 ongoing events, unlimited groups
///   platinum/test: unlimited events, unlimited groups
///
/// "Ongoing" = the event has not ended (or been cancelled); a recurring series
/// counts once. The counts come from the SERVER-owned counters in
/// `entitlement_usage/{uid}` (functions/src/entitlements/usage.ts) - the same
/// numbers the Firestore rules check when the event / group is created, so
/// the app can't show "allowed" for a create the server will refuse. (The old
/// count() over `groups` was denied by the rules and always read 0.)
class TierLimitsService {
  TierLimitsService({FirebaseFirestore? firestore})
      : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  /// Max events a tier may create (null = unlimited).
  ///
  /// Delegates to [TierEntitlements] so there is exactly ONE definition of
  /// the per-tier cap (no divergence between config and enforcement).
  static int? maxEvents(MembershipTier tier) => TierEntitlements.maxEvents(tier);

  /// Max groups a tier may create (null = unlimited).
  ///
  /// Delegates to [TierEntitlements] so there is exactly ONE definition of
  /// the per-tier cap (no divergence between config and enforcement).
  static int? maxGroups(MembershipTier tier) => TierEntitlements.maxGroups(tier);

  Future<MembershipTier> _tierOf(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      // Effective tier: an expired paid tier counts as free.
      return effectiveTierFromDoc(doc.data());
    } catch (_) {
      return MembershipTier.free;
    }
  }

  Future<Map<String, dynamic>?> _usage(String userId) async {
    try {
      final doc = await _firestore
          .collection(kEntitlementUsageCollection)
          .doc(userId)
          .get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// Whether [userId] may create another ONGOING event under their tier
  /// (a paid extra-event credit not used yet also allows one).
  Future<TierLimitResult> canCreateEvent(String userId) async {
    final tier = await _tierOf(userId);
    final max = maxEvents(tier);
    if (max == null) {
      return TierLimitResult(
          allowed: true, tier: tier, current: 0, max: null);
    }
    final usage = await _usage(userId);
    final current = ongoingEventSlotsFrom(usage, DateTime.now());
    return TierLimitResult(
      allowed: current < max || extraEventCreditsLeftFrom(usage) > 0,
      tier: tier,
      current: current,
      max: max,
    );
  }

  /// Whether [userId] may create another group under their tier.
  Future<TierLimitResult> canCreateGroup(String userId) async {
    final tier = await _tierOf(userId);
    final max = maxGroups(tier);
    if (max == null) {
      return TierLimitResult(
          allowed: true, tier: tier, current: 0, max: null);
    }
    final current = groupsCreatedFrom(await _usage(userId));
    return TierLimitResult(
      allowed: current < max,
      tier: tier,
      current: current,
      max: max,
    );
  }
}
