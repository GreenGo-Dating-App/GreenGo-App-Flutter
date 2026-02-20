import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages online presence status for the current user.
/// Writes `isOnline` and `lastSeen` fields to the user's profile document.
class PresenceService {
  final FirebaseFirestore _firestore;
  final String userId;

  PresenceService({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mark the user as online
  Future<void> setOnline() async {
    try {
      await _firestore.collection('profiles').doc(userId).update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Presence] Failed to set online: $e');
    }
  }

  /// Mark the user as offline and update lastSeen
  Future<void> setOffline() async {
    try {
      await _firestore.collection('profiles').doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Presence] Failed to set offline: $e');
    }
  }
}
