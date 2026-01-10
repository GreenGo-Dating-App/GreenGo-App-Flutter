import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';
import 'test_app.dart';

/// Coins & Shop User Tests (6 tests)
/// Tests cover: Coin shop, purchases, transaction history
void main() {
  TestHelpers.initializeTests();

  group('Coins & Shop Tests', () {
    // Test 88: User can view coin shop
    testWidgets('Test 88: User can view coin shop', (tester) async {
      await pumpTestApp(tester, child: const TestMainScreen());

      // Navigate to Profile tab and tap coin shop
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      await TestHelpers.tapByKey(tester, 'coin_shop_button');
      await tester.pumpAndSettle();

      // Verify coin shop screen
      expect(find.text('Coin Shop'), findsOneWidget);
      expect(find.byKey(const Key('coin_packages_list')), findsOneWidget);
      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
    });

    // Test 89: User can see coin packages with prices
    testWidgets('Test 89: User can see coin packages with prices', (tester) async {
      await pumpTestApp(tester, child: const TestCoinShopScreen());

      // Verify coin packages are displayed
      expect(find.byKey(const Key('coin_package_0')), findsOneWidget);
      expect(find.byKey(const Key('coin_package_1')), findsOneWidget);
      expect(find.byKey(const Key('coin_package_2')), findsOneWidget);

      // Verify prices are shown
      expect(find.textContaining('\$'), findsWidgets);

      // Verify coin amounts are shown
      expect(find.textContaining('coins'), findsWidgets);
    });

    // Test 90: User can see active promotions
    testWidgets('Test 90: User can see active promotions', (tester) async {
      await pumpTestApp(tester, child: const TestCoinShopScreen());

      // Verify promotion banner
      expect(find.byKey(const Key('promotion_banner')), findsOneWidget);
      expect(find.textContaining('%'), findsWidgets);
    });

    // Test 91: User can see current coin balance
    testWidgets('Test 91: User can see current coin balance', (tester) async {
      await pumpTestApp(tester, child: const TestCoinShopScreen());

      // Verify coin balance display
      expect(find.byKey(const Key('coin_balance')), findsOneWidget);
      expect(find.textContaining('coins'), findsWidgets);
    });

    // Test 92: User can access transaction history
    testWidgets('Test 92: User can access transaction history', (tester) async {
      await pumpTestApp(tester, child: const TestCoinShopScreen());

      // Tap transaction history button
      await TestHelpers.tapByKey(tester, 'transaction_history_button');
      await tester.pumpAndSettle();

      // Verify transaction history screen
      expect(find.text('Transaction History'), findsOneWidget);
      expect(find.byKey(const Key('transactions_list')), findsOneWidget);
    });

    // Test 93: User can initiate a purchase
    testWidgets('Test 93: User can initiate a purchase', (tester) async {
      await pumpTestApp(tester, child: const TestCoinShopScreen());

      // Tap buy on first package
      await tester.tap(find.text('Buy').first);
      await tester.pumpAndSettle();

      // Verify purchase confirmation dialog
      expect(find.text('Confirm Purchase'), findsOneWidget);
    });
  });
}
