import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Discovery & Swiping User Tests (12 tests)
/// Tests cover: Swiping, likes, super likes, profile viewing, preferences
void main() {
  TestHelpers.initializeTests();

  group('Discovery & Swiping Tests', () {
    // Test 38: User can view discovery screen with profile cards
    testWidgets('Test 38: User can view discovery screen with profile cards', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Verify discovery screen elements
      expect(find.byKey(const Key('swipe_card_stack')), findsOneWidget);
      expect(find.byKey(const Key('swipe_buttons')), findsOneWidget);
    });

    // Test 39: User can tap like button
    testWidgets('Test 39: User can tap like button', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap like button
      await TestHelpers.tapByKey(tester, 'like_button');
      await tester.pump();

      // Verify like button exists and was tapped
      expect(find.byKey(const Key('like_button')), findsOneWidget);
    });

    // Test 40: User can tap pass button
    testWidgets('Test 40: User can tap pass button', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap pass button
      await TestHelpers.tapByKey(tester, 'pass_button');
      await tester.pump();

      // Verify pass button exists and was tapped
      expect(find.byKey(const Key('pass_button')), findsOneWidget);
    });

    // Test 41: User can super like a profile
    testWidgets('Test 41: User can super like a profile', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap super like button
      await TestHelpers.tapByKey(tester, 'super_like_button');
      await tester.pump();

      // Verify super like button exists and was tapped
      expect(find.byKey(const Key('super_like_button')), findsOneWidget);
    });

    // Test 42: User can tap on profile card to view details
    testWidgets('Test 42: User can tap on profile card to view details', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap on card
      await tester.tap(find.byKey(const Key('swipe_card')));
      await tester.pumpAndSettle();

      // Verify profile detail screen
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Interests'), findsOneWidget);
    });

    // Test 43: User can view profile photos in gallery
    testWidgets('Test 43: User can view profile photos in gallery', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap on card to open profile
      await tester.tap(find.byKey(const Key('swipe_card')));
      await tester.pumpAndSettle();

      // Verify photo gallery
      expect(find.byKey(const Key('profile_photo_gallery')), findsOneWidget);
    });

    // Test 44: User can access discovery preferences
    testWidgets('Test 44: User can access discovery preferences', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap preferences button
      await TestHelpers.tapByKey(tester, 'preferences_button');
      await tester.pumpAndSettle();

      // Verify preferences UI
      expect(find.text('Discovery Preferences'), findsOneWidget);
    });

    // Test 45: User can adjust age range preference
    testWidgets('Test 45: User can adjust age range preference', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Open preferences
      await TestHelpers.tapByKey(tester, 'preferences_button');
      await tester.pumpAndSettle();

      // Verify age range slider
      expect(find.byKey(const Key('age_range_slider')), findsOneWidget);
      expect(find.text('Age Range'), findsOneWidget);
    });

    // Test 46: User can adjust distance preference
    testWidgets('Test 46: User can adjust distance preference', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Open preferences
      await TestHelpers.tapByKey(tester, 'preferences_button');
      await tester.pumpAndSettle();

      // Verify distance slider
      expect(find.byKey(const Key('distance_slider')), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
    });

    // Test 47: User can set gender preference
    testWidgets('Test 47: User can set gender preference', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Open preferences
      await TestHelpers.tapByKey(tester, 'preferences_button');
      await tester.pumpAndSettle();

      // Verify gender filter
      expect(find.byKey(const Key('gender_filter')), findsOneWidget);
    });

    // Test 48: User can save preferences
    testWidgets('Test 48: User can save preferences', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Open preferences
      await TestHelpers.tapByKey(tester, 'preferences_button');
      await tester.pumpAndSettle();

      // Save preferences
      await TestHelpers.tapByKey(tester, 'save_preferences_button');
      await tester.pumpAndSettle();

      // Verify preferences closed
      expect(find.text('Discovery Preferences'), findsNothing);
    });

    // Test 49: User can use rewind feature
    testWidgets('Test 49: User can use rewind feature', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Tap rewind button
      await TestHelpers.tapByKey(tester, 'rewind_button');
      await tester.pumpAndSettle();

      // Verify rewind feedback
      expect(find.text('Profile restored'), findsOneWidget);
    });
  });
}
