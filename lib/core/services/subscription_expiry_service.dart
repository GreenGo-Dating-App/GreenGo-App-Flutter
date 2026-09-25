import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/membership/domain/entities/membership.dart';
import 'effective_tier.dart';

/// Detects a lapsed membership so the app can tell the user about it.
///
/// It does NOT write anything. The downgrade itself is owned by the server
/// (scheduled expiry job + store notifications): the client used to deactivate
/// `memberships/*`, rewrite `profiles/{uid}` and mark `subscriptions/*`
/// expired in one batch, but the rules refuse the `subscriptions` update, so
/// the whole batch always failed. Entitlements no longer depend on that write
/// anyway — every gate resolves the EFFECTIVE tier ([effectiveTierFromDoc]),
/// which already treats a paid tier past its `membershipEndDate` as free.
class SubscriptionExpiryService {
  SubscriptionExpiryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  static const String _notifiedKeyPrefix = 'membership_lapse_notified_';

  /// Returns the display name of a PAID tier that has lapsed but is still
  /// stored on `profiles/{userId}` (i.e. the server downgrade has not run
  /// yet), or null when nothing lapsed.
  ///
  /// Reports each lapse once per device: the (tier, end date) pair is
  /// remembered so the "your membership expired" dialog is not shown on every
  /// launch until the server job catches up.
  Future<String?> checkAndHandleExpiry(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      final data = doc.data();
      if (data == null) return null;

      final stored = MembershipTier.fromString(data['membershipTier'] as String?);
      final endDate = tierDateFromValue(data['membershipEndDate']);
      if (stored == MembershipTier.free ||
          stored == MembershipTier.test ||
          data['isAdmin'] == true ||
          endDate == null) {
        return null;
      }
      // Still active → nothing to report.
      if (effectiveTierFromDoc(data) != MembershipTier.free) return null;

      final marker = '${stored.value}@${endDate.millisecondsSinceEpoch}';
      final prefs = await SharedPreferences.getInstance();
      final key = '$_notifiedKeyPrefix$userId';
      if (prefs.getString(key) == marker) return null;
      await prefs.setString(key, marker);

      debugPrint('Membership lapsed for user $userId (was ${stored.displayName})');
      return stored.displayName;
    } catch (e) {
      debugPrint('Error checking membership expiry: $e');
      return null;
    }
  }

  /// Grant 1 bonus month on official release to users with active memberships.
  /// Called once per user when they first open the app after the release date.
  ///
  /// The grant itself runs server-side in the `claimReleaseBonus` callable; a
  /// client should not be deciding its own entitlements.
  Future<void> grantReleaseBonusMonth(String userId) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('claimReleaseBonus')
          .call<dynamic>();
    } catch (e) {
      // Best effort: a missed bonus is not worth interrupting app start.
      debugPrint('[ReleaseBonus] claim failed: $e');
    }
  }
}
