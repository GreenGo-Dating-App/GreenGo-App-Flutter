import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/membership/domain/entities/membership.dart';

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

/// Enforces per-tier caps on how many events / groups a user can create.
///
/// Caps (active items created by the user):
///   free (base): 1 event, 1 group
///   silver:      5 events, unlimited groups
///   gold:        50 events, unlimited groups
///   platinum/test: unlimited events, unlimited groups
///
/// Counts use Firestore count() aggregation (cheap, server-side) so this scales.
class TierLimitsService {
  TierLimitsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Max events a tier may create (null = unlimited).
  static int? maxEvents(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return 1;
      case MembershipTier.silver:
        return 5;
      case MembershipTier.gold:
        return 50;
      case MembershipTier.platinum:
      case MembershipTier.test:
        return null;
    }
  }

  /// Max groups a tier may create (null = unlimited).
  static int? maxGroups(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return 1;
      case MembershipTier.silver:
      case MembershipTier.gold:
      case MembershipTier.platinum:
      case MembershipTier.test:
        return null;
    }
  }

  Future<MembershipTier> _tierOf(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      final raw = doc.data()?['membershipTier'] as String?;
      if (raw == null) return MembershipTier.free;
      return MembershipTier.fromString(raw);
    } catch (_) {
      return MembershipTier.free;
    }
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    try {
      final snap = await query.count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Whether [userId] may create another event under their tier.
  Future<TierLimitResult> canCreateEvent(String userId) async {
    final tier = await _tierOf(userId);
    final max = maxEvents(tier);
    if (max == null) {
      return TierLimitResult(
          allowed: true, tier: tier, current: 0, max: null);
    }
    final current = await _count(
      _firestore.collection('events').where('organizerId', isEqualTo: userId),
    );
    return TierLimitResult(
      allowed: current < max,
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
    final current = await _count(
      _firestore.collection('groups').where('createdBy', isEqualTo: userId),
    );
    return TierLimitResult(
      allowed: current < max,
      tier: tier,
      current: current,
      max: max,
    );
  }
}
