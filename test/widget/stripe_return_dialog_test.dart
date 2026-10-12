import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/stripe_billing_models.dart';
import 'package:greengo_chat/features/coins/presentation/widgets/stripe_return_notice.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Future<Completer<bool>> _pump(WidgetTester tester, StripeReturn r) async {
  final done = Completer<bool>();
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: StripeReturnDialog(
        result: r,
        confirmFor: const Duration(seconds: 1),
        waitForOrder: (known, _) => done.future,
      ),
    ),
  ));
  return done;
}

void main() {
  testWidgets('coins: confirming, then "coins added"', (tester) async {
    final done = await _pump(tester, const StripeReturn(success: true, productId: 'greengo_coins_500'));
    expect(find.text('Confirming your payment…'), findsOneWidget);
    done.complete(true);
    await tester.pump();
    expect(find.text('Payment complete. Your coins have been added.'), findsOneWidget);
  });

  testWidgets('membership confirmed: "membership is active"', (tester) async {
    final done = await _pump(tester, const StripeReturn(success: true, productId: '1_month_gold'));
    done.complete(true);
    await tester.pump();
    expect(find.text('Payment complete. Your membership is active.'), findsOneWidget);
  });

  testWidgets('not confirmed in time (e.g. PIX): added automatically', (tester) async {
    final done = await _pump(tester, const StripeReturn(success: true, productId: 'greengo_coins_100'));
    done.complete(false);
    await tester.pump();
    expect(find.textContaining('added automatically'), findsOneWidget);
  });
}
