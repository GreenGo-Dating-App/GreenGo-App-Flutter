import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Settings User Tests (3 tests)
/// Tests cover: Language settings, app preferences, help/about
void main() {
  TestHelpers.initializeTests();

  group('Settings Tests', () {
    // Test 98: User can access settings
    testWidgets('Test 98: User can access settings', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab and tap settings
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Scroll to settings button if needed
      await tester.ensureVisible(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      await TestHelpers.tapByKey(tester, 'settings_button');
      await tester.pumpAndSettle();

      // Verify settings screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    // Test 99: User can view app version and info
    testWidgets('Test 99: User can view app version and info', (tester) async {
      await pumpTestApp(tester, child: const TestSettingsScreen());

      // Tap About section
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      // Verify about information is displayed
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    // Test 100: User can access help and support
    testWidgets('Test 100: User can access help and support', (tester) async {
      await pumpTestApp(tester, child: const TestSettingsScreen());

      // Tap Help & Support
      await tester.tap(find.text('Help & Support'));
      await tester.pumpAndSettle();

      // Verify help options
      expect(find.text('FAQ'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      expect(find.text('Report a Problem'), findsOneWidget);
    });
  });
}
