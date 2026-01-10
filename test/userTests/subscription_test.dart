import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Subscription User Tests (4 tests)
/// Tests cover: View subscription plans, purchase, access premium features
void main() {
  TestHelpers.initializeTests();

  group('Subscription Tests', () {
    // Test 94: User can view subscription plans
    testWidgets('Test 94: User can view subscription plans', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab and tap subscription/premium
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await TestHelpers.tapByKey(tester, 'subscription_button');
      await tester.pumpAndSettle();

      // Verify subscription selection screen
      expect(find.text('Premium Plans'), findsOneWidget);
      expect(find.byKey(const Key('subscription_tiers')), findsOneWidget);

      // Verify all tiers are displayed
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('Gold'), findsOneWidget);
    });

    // Test 95: User can see premium features for each tier
    testWidgets('Test 95: User can see premium features for each tier', (tester) async {
      await pumpTestApp(tester, child: const TestSubscriptionScreen());

      // Verify features are listed
      expect(find.text('Unlimited Likes'), findsAtLeast(1));
      expect(find.text('See Who Liked You'), findsAtLeast(1));
      expect(find.text('Super Likes'), findsAtLeast(1));
      expect(find.text('Rewind'), findsOneWidget);
      expect(find.text('Boost'), findsOneWidget);
    });

    // Test 96: User can initiate subscription
    testWidgets('Test 96: User can initiate subscription', (tester) async {
      await pumpTestApp(tester, child: const TestSubscriptionScreen());

      // Tap subscribe button
      await TestHelpers.tapByKey(tester, 'subscribe_button');
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Confirm Subscription'), findsOneWidget);
    });

    // Test 97: User can compare subscription tiers
    testWidgets('Test 97: User can compare subscription tiers', (tester) async {
      await pumpTestApp(tester, child: const TestSubscriptionScreen());

      // Verify different tiers are visible
      expect(find.byKey(const Key('silver_tier')), findsOneWidget);
      expect(find.byKey(const Key('gold_tier')), findsOneWidget);
    });
  });
}
