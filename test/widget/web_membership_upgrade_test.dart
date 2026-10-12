import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/product_catalog.dart';
import 'package:greengo_chat/features/subscription/domain/entities/subscription.dart';
import 'package:greengo_chat/features/subscription/presentation/screens/membership_screen.dart';
import 'package:greengo_chat/features/subscription/presentation/screens/subscription_selection_screen.dart';
import 'package:greengo_chat/features/subscription/presentation/web_membership_upgrade.dart';

/// Stand-in for the Shop's Stripe membership tab (the real one needs DI and
/// Firebase). Records which user it was opened for.
class _StripeShopStub extends StatelessWidget {
  const _StripeShopStub(this.userId);
  final String userId;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Text('stripe-shop:$userId'));
}

void main() {
  late bool Function() originalIsWeb;
  late Widget Function(String) originalBuilder;

  setUp(() {
    originalIsWeb = membershipUpgradeIsWeb;
    originalBuilder = webMembershipShopBuilder;
    webMembershipShopBuilder = _StripeShopStub.new;
  });

  tearDown(() {
    membershipUpgradeIsWeb = originalIsWeb;
    webMembershipShopBuilder = originalBuilder;
  });

  group('platform decision', () {
    test('defaults to kIsWeb (false on the VM)', () {
      expect(membershipUpgradeIsWeb(), kIsWeb);
    });

    test('native keeps the IAP screen (no web destination)', () {
      membershipUpgradeIsWeb = () => false;
      expect(webMembershipUpgradeDestination('u1'), isNull);
    });

    test('web routes to the Stripe shop for that user', () {
      membershipUpgradeIsWeb = () => true;
      final w = webMembershipUpgradeDestination('u1');
      expect(w, isA<_StripeShopStub>());
      expect((w! as _StripeShopStub).userId, 'u1');
    });

    test('the real web destination is the Shop on its Membership tab', () {
      final shop = webMembershipShopScreen('u1');
      expect(shop.userId, 'u1');
      expect(shop.initialTab, kShopMembershipTabIndex);
      expect(kShopMembershipTabIndex, 1);
    });

    test('membership product IDs sold there are server-canonical', () {
      expect(ProductCatalog.canonicalIds, contains(ProductCatalog.baseMembership));
      for (final t in [
        SubscriptionTier.silver,
        SubscriptionTier.gold,
        SubscriptionTier.platinum,
      ]) {
        expect(ProductCatalog.canonicalIds, contains(t.monthlyProductId));
        expect(ProductCatalog.canonicalIds, contains(t.yearlyProductId));
      }
    });
  });

  group('on web the upgrade screens offer Stripe, not an IAP error', () {
    setUp(() => membershipUpgradeIsWeb = () => true);

    // Neither screen gets a SubscriptionBloc or DI here: if either still
    // touched the in-app-purchase path it would throw instead of rendering.
    testWidgets('MembershipScreen (chat / Base gates)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MembershipScreen(currentUserId: 'u1')),
      );
      expect(find.text('stripe-shop:u1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MembershipSelectionScreen (tier gate)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MembershipSelectionScreen(currentUserId: 'u2'),
        ),
      );
      expect(find.text('stripe-shop:u2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('pushed the way BaseMembershipGate pushes it', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MembershipScreen(currentUserId: 'u3'),
              ),
            ),
            child: const Text('join'),
          ),
        ),
      ));
      await tester.tap(find.text('join'));
      await tester.pumpAndSettle();
      expect(find.text('stripe-shop:u3'), findsOneWidget);
    });
  });
}
