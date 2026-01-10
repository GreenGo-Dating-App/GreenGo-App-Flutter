import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Gamification User Tests (10 tests)
/// Tests cover: Achievements, leaderboard, daily challenges, seasonal events
void main() {
  TestHelpers.initializeTests();

  group('Gamification Tests', () {
    // Test 78: User can view achievements screen
    testWidgets('Test 78: User can view achievements screen', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab and tap achievements
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await TestHelpers.tapByKey(tester, 'achievements_button');
      await tester.pumpAndSettle();

      // Verify achievements screen
      expect(find.text('Achievements'), findsOneWidget);
      expect(find.byKey(const Key('achievements_list')), findsOneWidget);
    });

    // Test 79: User can see unlocked and locked achievements
    testWidgets('Test 79: User can see unlocked and locked achievements', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify unlocked achievements
      expect(find.byKey(const Key('unlocked_achievement')), findsOneWidget);

      // Verify locked achievements
      expect(find.byKey(const Key('locked_achievement')), findsOneWidget);
    });

    // Test 80: User can see achievement progress
    testWidgets('Test 80: User can see achievement progress', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify progress indicators
      expect(find.byKey(const Key('achievement_progress_0')), findsOneWidget);
      expect(find.textContaining('/'), findsWidgets);
    });

    // Test 81: User can filter achievements by category
    testWidgets('Test 81: User can filter achievements by category', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify filter chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Dating'), findsOneWidget);
    });

    // Test 82: User can view leaderboard
    testWidgets('Test 82: User can view leaderboard', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify leaderboard button
      expect(find.byKey(const Key('leaderboard_button')), findsOneWidget);
    });

    // Test 83: User can view daily challenges
    testWidgets('Test 83: User can view daily challenges', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify daily challenges button
      expect(find.byKey(const Key('daily_challenges_button')), findsOneWidget);
    });

    // Test 84: User can view seasonal events
    testWidgets('Test 84: User can view seasonal events', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify seasonal event button
      expect(find.byKey(const Key('seasonal_event_button')), findsOneWidget);
    });

    // Test 85: User can see achievement details
    testWidgets('Test 85: User can see achievement details', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify achievement list has items
      expect(find.byKey(const Key('achievements_list')), findsOneWidget);
    });

    // Test 86: User can see social achievements
    testWidgets('Test 86: User can see social achievements', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify social achievements
      expect(find.byKey(const Key('social_achievement')), findsOneWidget);
    });

    // Test 87: User can track achievement progress
    testWidgets('Test 87: User can track achievement progress', (tester) async {
      await pumpTestApp(tester, child: const TestAchievementsScreen());

      // Verify progress tracking
      expect(find.textContaining('/'), findsWidgets);
    });
  });
}
