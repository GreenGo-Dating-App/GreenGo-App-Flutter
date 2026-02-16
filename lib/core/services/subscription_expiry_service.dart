import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../features/membership/domain/entities/membership.dart';

/// Service to check and handle subscription/membership expiry.
///
/// On app start, checks if the user's active membership has expired.
/// If expired, rolls back to the free tier and creates a downgrade notification.
class SubscriptionExpiryService {
  final FirebaseFirestore _firestore;

  SubscriptionExpiryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if the user's membership has expired and handle downgrade.
  /// Returns the previous tier name if a downgrade occurred, or null if no change.
  Future<String?> checkAndHandleExpiry(String userId) async {
    try {
      // Get active membership
      final membershipQuery = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (membershipQuery.docs.isEmpty) return null;

      final membershipDoc = membershipQuery.docs.first;
      final data = membershipDoc.data();

      final tierString = data['tier'] as String? ?? 'FREE';
      final endDateTimestamp = data['endDate'] as Timestamp?;

      // If no end date, membership is permanent (e.g., admin/test)
      if (endDateTimestamp == null) return null;

      final endDate = endDateTimestamp.toDate();
      final tier = MembershipTier.fromString(tierString);

      // If free tier, nothing to downgrade
      if (tier == MembershipTier.free) return null;

      // If test tier, don't expire
      if (tier == MembershipTier.test) return null;

      // Check if expired
      if (DateTime.now().isAfter(endDate)) {
        debugPrint('Membership expired for user $userId (was ${tier.displayName})');
        await _downgradeToFree(userId, membershipDoc.id, tier);
        return tier.displayName;
      }

      // Also check subscription collection for expired subscriptions
      await _checkSubscriptionExpiry(userId);

      return null;
    } catch (e) {
      debugPrint('Error checking membership expiry: $e');
      return null;
    }
  }

  /// Downgrade user to free tier
  Future<void> _downgradeToFree(String userId, String membershipId, MembershipTier previousTier) async {
    final batch = _firestore.batch();

    // 1. Deactivate expired membership
    batch.update(
      _firestore.collection('memberships').doc(membershipId),
      {
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      },
    );

    // 2. Update profile to free tier
    batch.update(
      _firestore.collection('profiles').doc(userId),
      {
        'membershipTier': 'FREE',
        'membershipEndDate': null,
      },
    );

    // 3. Update users collection tier
    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'membershipTier': 'basic',
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // 4. Update subscription status to expired if exists
    final subQuery = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final subDoc in subQuery.docs) {
      batch.update(subDoc.reference, {
        'status': 'expired',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // 5. Create downgrade notification
    await _createDowngradeNotification(userId, previousTier);
  }

  /// Create a notification informing the user of the downgrade
  Future<void> _createDowngradeNotification(String userId, MembershipTier previousTier) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'system',
        'title': 'Subscription Expired',
        'message': 'Your ${previousTier.displayName} subscription has expired. '
            'You have been moved to the Free tier. '
            'Upgrade anytime to restore your premium features!',
        'data': {
          'previousTier': previousTier.value,
          'action': 'subscription_expired',
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Failed to create downgrade notification: $e');
    }
  }

  /// Grant 1 bonus month on official release to users with active memberships.
  /// Called once per user when they first open the app after the release date.
  /// Stores a flag so it only applies once.
  Future<void> grantReleaseBonusMonth(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      // Check if bonus was already granted
      final bonusGranted = userDoc.data()?['releaseBonusGranted'] as bool? ?? false;
      if (bonusGranted) return;

      // Get active membership
      final membershipQuery = await _firestore
          .collection('memberships')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (membershipQuery.docs.isEmpty) return;

      final membershipDoc = membershipQuery.docs.first;
      final data = membershipDoc.data();
      final endDateTimestamp = data['endDate'] as Timestamp?;
      final tierString = data['tier'] as String? ?? 'FREE';
      final tier = MembershipTier.fromString(tierString);

      // Don't add bonus to free or test tier
      if (tier == MembershipTier.free || tier == MembershipTier.test) return;

      // Extend end date by 1 month
      final currentEndDate = endDateTimestamp?.toDate() ?? DateTime.now();
      final newEndDate = DateTime(
        currentEndDate.year,
        currentEndDate.month + 1,
        currentEndDate.day,
        currentEndDate.hour,
        currentEndDate.minute,
      );

      await membershipDoc.reference.update({
        'endDate': Timestamp.fromDate(newEndDate),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update profile end date
      await _firestore.collection('profiles').doc(userId).update({
        'membershipEndDate': Timestamp.fromDate(newEndDate),
      });

      // Mark bonus as granted
      await _firestore.collection('users').doc(userId).update({
        'releaseBonusGranted': true,
      });

      // Notify user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'system',
        'title': 'Release Bonus!',
        'message': 'Congratulations! You received 1 bonus month on your '
            '${tier.displayName} membership as a launch celebration!',
        'data': {
          'action': 'release_bonus',
          'newEndDate': Timestamp.fromDate(newEndDate),
        },
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
      });

      debugPrint('Release bonus month granted to user $userId (new end: $newEndDate)');
    } catch (e) {
      debugPrint('Error granting release bonus: $e');
    }
  }

  /// Check and expire any active subscriptions that have passed their end date
  Future<void> _checkSubscriptionExpiry(String userId) async {
    try {
      final subQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in subQuery.docs) {
        final data = doc.data();
        final endDate = data['endDate'] as Timestamp?;
        if (endDate != null && DateTime.now().isAfter(endDate.toDate())) {
          await doc.reference.update({
            'status': 'expired',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription expiry: $e');
    }
  }
}
