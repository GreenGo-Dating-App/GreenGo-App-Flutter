import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Whether the one-time onboarding UI (page tours, welcome carousel,
/// "What's new") may run.
///
/// Off under `flutter test` so the existing screen tests are not covered by a
/// tour overlay; the tour tests switch it on with [debugOverride].
class TourEnvironment {
  TourEnvironment._();

  @visibleForTesting
  static bool? debugOverride;

  static final bool _underTest = !kIsWeb &&
      (() {
        try {
          return Platform.environment.containsKey('FLUTTER_TEST');
        } catch (_) {
          return false;
        }
      })();

  static bool get enabled => debugOverride ?? !_underTest;

  /// The signed-in user's id for a page tour, or null when tours are off or
  /// Firebase is not available (never throws).
  static String? currentUid() {
    if (!enabled) return null;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }
}
