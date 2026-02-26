import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages online presence status for the current user.
/// A user is considered online only if they performed an action in the last 5 minutes.
/// Writes `isOnline` and `lastSeen` fields to the user's profile document.
class PresenceService {
  final FirebaseFirestore _firestore;
  final String userId;

  /// Static instance for easy access from anywhere
  static PresenceService? _instance;
  static PresenceService? get instance => _instance;

  /// Duration of inactivity before user is marked offline
  static const _inactivityTimeout = Duration(minutes: 5);

  /// How often to check for inactivity
  static const _checkInterval = Duration(minutes: 1);

  Timer? _inactivityTimer;
  Timer? _periodicCheck;
  DateTime _lastActivity = DateTime.now();
  bool _isCurrentlyOnline = false;
  bool _isAppInForeground = true;

  PresenceService({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance {
    _instance = this;
  }

  /// Record user activity — resets the inactivity timer.
  /// Call this on taps, swipes, messages, navigation changes, etc.
  void recordActivity() {
    _lastActivity = DateTime.now();
    if (_isAppInForeground && !_isCurrentlyOnline) {
      _setOnline();
    }
  }

  /// Called when app comes to foreground
  Future<void> onAppResumed() async {
    _isAppInForeground = true;
    _lastActivity = DateTime.now();
    await _setOnline();
    _startInactivityCheck();
  }

  /// Called when app goes to background
  Future<void> onAppPaused() async {
    _isAppInForeground = false;
    _stopInactivityCheck();
    await _setOffline();
  }

  /// Start periodic inactivity checking
  void _startInactivityCheck() {
    _stopInactivityCheck();
    _periodicCheck = Timer.periodic(_checkInterval, (_) {
      _checkInactivity();
    });
  }

  /// Stop periodic inactivity checking
  void _stopInactivityCheck() {
    _periodicCheck?.cancel();
    _periodicCheck = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Check if user has been inactive for too long
  void _checkInactivity() {
    final elapsed = DateTime.now().difference(_lastActivity);
    if (elapsed >= _inactivityTimeout && _isCurrentlyOnline) {
      _setOffline();
    }
  }

  /// Mark the user as online in Firestore
  Future<void> _setOnline() async {
    if (_isCurrentlyOnline) return;
    _isCurrentlyOnline = true;
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
  Future<void> _setOffline() async {
    if (!_isCurrentlyOnline) return;
    _isCurrentlyOnline = false;
    try {
      await _firestore.collection('profiles').doc(userId).update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Presence] Failed to set offline: $e');
    }
  }

  /// Clean up timers
  void dispose() {
    _stopInactivityCheck();
    if (_isCurrentlyOnline) {
      _setOffline();
    }
  }
}
