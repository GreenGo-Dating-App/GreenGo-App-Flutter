import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'authentication_test.dart' as authentication;
import 'onboarding_test.dart' as onboarding;
import 'profile_editing_test.dart' as profile_editing;
import 'discovery_test.dart' as discovery;
import 'matching_test.dart' as matching;
import 'chat_test.dart' as chat;
import 'notifications_test.dart' as notifications;
import 'gamification_test.dart' as gamification;
import 'coins_test.dart' as coins;
import 'subscription_test.dart' as subscription;
import 'settings_test.dart' as settings;
import 'new_features_test.dart' as new_features;

/// Main entry point for running all 120 user tests
///
/// Run with: flutter test test/userTests/all_user_test.dart
void main() {
  group('GreenGo Chat App - All User Tests (120 tests)', () {
    // Authentication Tests (15 tests) - Tests 1-15
    authentication.main();

    // Onboarding Tests (12 tests) - Tests 16-27
    onboarding.main();

    // Profile Editing Tests (10 tests) - Tests 28-37
    profile_editing.main();

    // Discovery & Swiping Tests (12 tests) - Tests 38-49
    discovery.main();

    // Matching Tests (8 tests) - Tests 50-57
    matching.main();

    // Chat & Messaging Tests (12 tests) - Tests 58-69
    chat.main();

    // Notifications Tests (8 tests) - Tests 70-77
    notifications.main();

    // Gamification Tests (10 tests) - Tests 78-87
    gamification.main();

    // Coins & Shop Tests (6 tests) - Tests 88-93
    coins.main();

    // Subscription Tests (4 tests) - Tests 94-97
    subscription.main();

    // Settings Tests (3 tests) - Tests 98-100
    settings.main();

    // New Features Tests (20 tests) - Tests 101-120
    // Includes: Consent Checkboxes, Chat Translation, Message Actions
    new_features.main();
  });
}
