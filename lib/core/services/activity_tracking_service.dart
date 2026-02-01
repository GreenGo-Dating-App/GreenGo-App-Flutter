import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track user activity for re-engagement notifications
/// Updates lastActiveAt field periodically when user is active
class ActivityTrackingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Timer? _heartbeatTimer;
  DateTime? _lastUpdate;

  /// Minimum interval between updates (5 minutes)
  static const Duration _updateInterval = Duration(minutes: 5);

  ActivityTrackingService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Start tracking user activity
  /// Call this when the app becomes active
  void startTracking() {
    _updateLastActive();

    // Set up periodic heartbeat
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      _updateInterval,
      (_) => _updateLastActive(),
    );
  }

  /// Stop tracking user activity
  /// Call this when the app goes to background
  void stopTracking() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Record user activity immediately
  /// Call this on significant user actions (swipe, message, etc.)
  Future<void> recordActivity() async {
    // Debounce updates to avoid excessive writes
    if (_lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < _updateInterval) {
      return;
    }
    await _updateLastActive();
  }

  /// Update the lastActiveAt field in Firestore
  Future<void> _updateLastActive() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      _lastUpdate = DateTime.now();
    } catch (e) {
      // Silently fail - this is non-critical functionality
      // The user document might not exist yet during onboarding
    }
  }

  /// Dispose the service
  void dispose() {
    stopTracking();
  }
}
