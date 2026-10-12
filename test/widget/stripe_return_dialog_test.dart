import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/stripe_billing_models.dart';
import 'package:greengo_chat/core/widgets/purchase_success_dialog.dart';
import 'package:greengo_chat/core/widgets/subscription_celebration_screen.dart';
import 'package:greengo_chat/features/coins/presentation/widgets/stripe_return_notice.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Opens the return flow for [r] the way [StripeReturnNotice.check] does, with
/// the order wait controlled by the returned completer.
Future<Completer<bool>> _pump(WidgetTester tester, StripeReturn r) async {
  final done = Completer<bool>();
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => StripeReturnNotice.show(
            context,
            r,
            confirmFor: const Duration(seconds: 1),
            waitForOrder: (known, _) => done.future,
          ),
          child: const Text('return'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('return'));
  await tester.pump();
  return done;
}

void main() {
  testWidgets('coins: confirming, then the mobile success dialog', (tester) async {
    final done = await _pump(tester, const StripeReturn(success: true, productId: 'greengo_coins_500'));
    expect(find.text('Confirming your payment…'), findsOneWidget);
    done.complete(true);
    await tester.pump(); // order confirmed -> confirming dialog closes
    await tester.pump(const Duration(milliseconds: 500)); // success dialog opens
    expect(find.byKey(const ValueKey('stripe-return-dialog')), findsNothing);
    expect(find.byType(PurchaseSuccessDialog), findsOneWidget);
    expect(find.text('Purchase Successful!'), findsOneWidget);
    expect(find.textContaining('coins added to your account'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // auto-dismiss
    await tester.pumpAndSettle();
    expect(find.byType(PurchaseSuccessDialog), findsNothing);
  });

  testWidgets('tier membership confirmed: the mobile celebration', (tester) async {
    // The full-screen celebration is laid out for a phone, not 800x600.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final done = await _pump(tester, const StripeReturn(success: true, productId: '1_month_gold'));
    done.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('stripe-return-dialog')), findsNothing);
    expect(find.byType(SubscriptionCelebrationScreen), findsOneWidget);
    // Let the celebration's staged animations finish, then tear it down.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('base membership confirmed: success dialog, membership active', (tester) async {
    final done = await _pump(tester, const StripeReturn(success: true, productId: 'greengo_base_membership'));
    done.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PurchaseSuccessDialog), findsOneWidget);
    expect(find.text('Payment complete. Your membership is active.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('not confirmed in time (e.g. PIX): added automatically', (tester) async {
    final done = await _pump(tester, const StripeReturn(success: true, productId: 'greengo_coins_100'));
    done.complete(false);
    await tester.pump();
    expect(find.textContaining('added automatically'), findsOneWidget);
    expect(find.byType(PurchaseSuccessDialog), findsNothing);
  });

  testWidgets('cancelled: "not charged" snackbar, no dialog', (tester) async {
    await _pump(tester, const StripeReturn(success: false));
    expect(find.text('Payment cancelled. You have not been charged.'), findsOneWidget);
    expect(find.byKey(const ValueKey('stripe-return-dialog')), findsNothing);
  });
}
