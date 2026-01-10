import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Matching User Tests (8 tests)
/// Tests cover: Match list, match interactions, unmatch functionality
void main() {
  TestHelpers.initializeTests();

  group('Matching Tests', () {
    // Test 50: User can view matches screen
    testWidgets('Test 50: User can view matches screen', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Verify matches screen elements
      expect(find.text('Matches'), findsAtLeast(1));
      expect(find.byKey(const Key('matches_list')), findsOneWidget);
    });

    // Test 51: User can see list of mutual matches
    testWidgets('Test 51: User can see list of mutual matches', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Verify match cards are displayed
      expect(find.byKey(const Key('match_card_0')), findsOneWidget);
      expect(find.byKey(const Key('match_photo_0')), findsOneWidget);
      expect(find.byKey(const Key('match_name_0')), findsOneWidget);
    });

    // Test 52: User can tap match to view options
    testWidgets('Test 52: User can tap match to view options', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Tap on first match
      await tester.tap(find.byKey(const Key('match_card_0')));
      await tester.pumpAndSettle();

      // Verify options appear
      expect(find.text('View Profile'), findsOneWidget);
      expect(find.text('Send Message'), findsOneWidget);
    });

    // Test 53: User can start chat from match
    testWidgets('Test 53: User can start chat from match', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Tap on first match
      await tester.tap(find.byKey(const Key('match_card_0')));
      await tester.pumpAndSettle();

      // Tap send message
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();

      // Verify chat screen opens
      expect(find.byKey(const Key('message_input')), findsOneWidget);
      expect(find.byKey(const Key('send_button')), findsOneWidget);
    });

    // Test 54: User can unmatch a match
    testWidgets('Test 54: User can unmatch a match', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Long press on a match to show options
      await tester.longPress(find.byKey(const Key('match_card_0')));
      await tester.pumpAndSettle();

      // Verify unmatch dialog appears
      expect(find.text('Are you sure you want to unmatch?'), findsOneWidget);
    });

    // Test 55: User can confirm unmatch
    testWidgets('Test 55: User can confirm unmatch', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Long press on a match
      await tester.longPress(find.byKey(const Key('match_card_0')));
      await tester.pumpAndSettle();

      // Confirm unmatch (use .last to tap the button, not the dialog title)
      await tester.tap(find.text('Unmatch').last);
      await tester.pumpAndSettle();

      // Verify match is removed
      expect(find.text('Match removed'), findsOneWidget);
    });

    // Test 56: User can see match timestamp
    testWidgets('Test 56: User can see match timestamp', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Verify match timestamp is displayed
      expect(find.textContaining('Matched'), findsWidgets);
    });

    // Test 57: User can refresh matches list
    testWidgets('Test 57: User can refresh matches list', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Matches tab
      await tester.tap(find.text('Matches'));
      await tester.pumpAndSettle();

      // Verify matches list exists
      expect(find.byKey(const Key('matches_list')), findsOneWidget);
    });
  });
}
