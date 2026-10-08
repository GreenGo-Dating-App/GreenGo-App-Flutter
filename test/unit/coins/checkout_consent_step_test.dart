import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/purchase_consent.dart';
import 'package:greengo_chat/features/coins/presentation/widgets/checkout_consent_step.dart';
import 'package:greengo_chat/features/coins/presentation/widgets/web_checkout_dialog.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Plan P2-9: the web checkout cannot start a coin purchase until the EU
/// immediate-delivery waiver is ticked; memberships show the withdrawal
/// information instead and never ask for a waiver.
void main() {
  Future<List<CheckoutConsent>> pump(
    WidgetTester tester,
    String productId, {
    Locale locale = const Locale('en'),
  }) async {
    final got = <CheckoutConsent>[];
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CheckoutConsentStep(
            productId: productId,
            onContinue: got.add,
            onCancel: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return got;
  }

  ElevatedButton continueButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byKey(const Key('checkoutContinueButton')));

  testWidgets('coins: continue is disabled until the waiver box is ticked', (tester) async {
    final got = await pump(tester, 'greengo_coins_500');
    final checkbox = find.byKey(const Key('checkoutWaiverCheckbox'));
    expect(checkbox, findsOneWidget);
    expect(tester.widget<CheckboxListTile>(checkbox).value, isFalse); // never pre-ticked
    expect(continueButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const Key('checkoutContinueButton')));
    await tester.pump();
    expect(got, isEmpty);

    await tester.tap(checkbox);
    await tester.pump();
    expect(continueButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('checkoutContinueButton')));
    await tester.pump();
    expect(got, hasLength(1));
    expect(got.single.waiverAccepted, isTrue);
    expect(got.single.toPayload(), {
      'waiverAccepted': true,
      'waiverVersion': kCoinWaiverVersion,
    });
  });

  testWidgets('coins: unticking the box disables continue again', (tester) async {
    await pump(tester, 'greengo_coins_100');
    final checkbox = find.byKey(const Key('checkoutWaiverCheckbox'));
    await tester.tap(checkbox);
    await tester.pump();
    await tester.tap(checkbox);
    await tester.pump();
    expect(continueButton(tester).onPressed, isNull);
  });

  testWidgets('membership: withdrawal info, no waiver, continue enabled', (tester) async {
    final got = await pump(tester, '1_month_gold');
    expect(find.byKey(const Key('checkoutWaiverCheckbox')), findsNothing);
    expect(find.byKey(const Key('checkoutWithdrawalInfo')), findsOneWidget);
    expect(continueButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('checkoutContinueButton')));
    await tester.pump();
    expect(got.single.waiverAccepted, isFalse);
    expect(got.single.toPayload(), {
      'withdrawalNoticeVersion': kMembershipWithdrawalNoticeVersion,
    });
  });

  for (final locale in const [
    Locale('de'), Locale('es'), Locale('fr'), Locale('it'), Locale('pt'), Locale('pt', 'BR'),
  ]) {
    testWidgets('waiver text is localized ($locale)', (tester) async {
      await pump(tester, 'greengo_coins_500', locale: locale);
      final l10n = AppLocalizations.of(tester.element(find.byType(CheckoutConsentStep)))!;
      expect(find.text(l10n.checkoutCoinWaiverCheckbox), findsOneWidget);
      expect(l10n.checkoutCoinWaiverCheckbox, isNot(contains('I agree')));
    });
  }

  testWidgets('the checkout dialog opens on the consent step, not on Stripe', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: WebCheckoutDialog(productId: 'greengo_coins_500')),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CheckoutConsentStep), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(continueButton(tester).onPressed, isNull);
  });

  test('only coin packages need the waiver', () {
    expect(isCoinProduct('greengo_coins_5000'), isTrue);
    expect(isCoinProduct('greengo_base_membership'), isFalse);
    expect(isCoinProduct('1_year_platinum_membership'), isFalse);
  });
}
