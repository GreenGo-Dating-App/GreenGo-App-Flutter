import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Feature Flags Service
///
/// Manages app-wide feature flags from Firestore.
/// Provides real-time updates when admins toggle features.
class FeatureFlagsService extends ChangeNotifier {
  static final FeatureFlagsService _instance = FeatureFlagsService._internal();
  factory FeatureFlagsService() => _instance;
  FeatureFlagsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _subscription;

  // Cache of feature flags
  Map<String, bool> _flags = {};
  bool _isLoaded = false;

  // Default values (used as fallback if Firestore fails)
  static const Map<String, bool> _defaults = {
    // Core Features
    'discovery': true,
    'matches': true,
    'profiles': true,

    // Communication Features
    'messaging': true,
    'videoCalls': false,
    'voiceMessages': false,

    // Monetization Features
    'coins': true,
    'shop': true,
    'subscriptions': true,
    'inAppPurchases': true,

    // Social Features
    'superLikes': true,
    'profileBoosts': true,
    'advancedFilters': true,

    // Extended Features
    'languageLearning': false,
    'gamification': false,
    'achievements': false,
    'dailyChallenges': false,
    'streaks': false,

    // System Features
    'analytics': true,
    'crashReporting': true,
    'performanceMonitoring': true,
    'pushNotifications': true,
    'emailNotifications': true,
  };

  /// Initialize the service and start listening for updates
  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      // First, try to get the document
      final docRef = _firestore.doc('app_config/feature_flags');
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        _updateFlags(docSnap);
      } else {
        // Use defaults if document doesn't exist
        _flags = Map.from(_defaults);
      }

      _isLoaded = true;

      // Start listening for real-time updates
      _subscription = docRef.snapshots().listen(
        (snapshot) {
          if (snapshot.exists) {
            _updateFlags(snapshot);
            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('Feature flags stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error initializing feature flags: $e');
      // Use defaults on error
      _flags = Map.from(_defaults);
      _isLoaded = true;
    }
  }

  void _updateFlags(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data != null && data['flags'] != null) {
      final flagsData = data['flags'] as Map<String, dynamic>;
      _flags = flagsData.map((key, value) => MapEntry(key, value as bool));
    }
  }

  /// Check if a feature is enabled
  bool isEnabled(String feature) {
    return _flags[feature] ?? _defaults[feature] ?? false;
  }

  /// Get all flags
  Map<String, bool> get allFlags => Map.unmodifiable(_flags);

  /// Whether flags have been loaded
  bool get isLoaded => _isLoaded;

  // Convenience getters for commonly used flags

  // Core Features
  bool get discoveryEnabled => isEnabled('discovery');
  bool get matchesEnabled => isEnabled('matches');
  bool get profilesEnabled => isEnabled('profiles');

  // Communication Features
  bool get messagingEnabled => isEnabled('messaging');
  bool get videoCallsEnabled => isEnabled('videoCalls');
  bool get voiceMessagesEnabled => isEnabled('voiceMessages');

  // Monetization Features
  bool get coinsEnabled => isEnabled('coins');
  bool get shopEnabled => isEnabled('shop');
  bool get subscriptionsEnabled => isEnabled('subscriptions');
  bool get inAppPurchasesEnabled => isEnabled('inAppPurchases');

  // Social Features
  bool get superLikesEnabled => isEnabled('superLikes');
  bool get profileBoostsEnabled => isEnabled('profileBoosts');
  bool get advancedFiltersEnabled => isEnabled('advancedFilters');

  // Extended Features
  bool get languageLearningEnabled => isEnabled('languageLearning');
  bool get gamificationEnabled => isEnabled('gamification');
  bool get achievementsEnabled => isEnabled('achievements');
  bool get dailyChallengesEnabled => isEnabled('dailyChallenges');
  bool get streaksEnabled => isEnabled('streaks');

  // System Features
  bool get analyticsEnabled => isEnabled('analytics');
  bool get crashReportingEnabled => isEnabled('crashReporting');
  bool get performanceMonitoringEnabled => isEnabled('performanceMonitoring');
  bool get pushNotificationsEnabled => isEnabled('pushNotifications');
  bool get emailNotificationsEnabled => isEnabled('emailNotifications');

  /// Dispose of resources
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Global instance for easy access
final featureFlags = FeatureFlagsService();
