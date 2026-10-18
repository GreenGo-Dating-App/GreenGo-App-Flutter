import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/stripe_billing_models.dart';
import 'package:greengo_chat/features/coins/data/datasources/coin_remote_datasource.dart';
import 'package:greengo_chat/features/profile/presentation/purchases_withdrawal.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  final opened = <Uri>[];
  var portalCalls = 0;
  var portalResult = true;
  WebBillingSummary summary = WebBillingSummary.empty;
  Object? loadError;

  setUp(() {
    opened.clear();
    portalCalls = 0;
    portalResult = true;
    summary = WebBillingSummary.empty;
    loadError = null;
    PurchasesWithdrawal.loadSummary = () async {
      if (loadError != null) throw loadError!;
      return summary;
    };
    PurchasesWithdrawal.openPortal = () async {
      portalCalls++;
      return portalResult;
    };
    PurchasesWithdrawal.openUrl = (u) async {
      opened.add(u);
      return true;
    };
  });
  tearDown(() {
    PurchasesWithdrawal.isWebOverride = null;
    PurchasesWithdrawal.platformOverride = null;
  });

  Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) =>
                TextButton(onPressed: () => PurchasesWithdrawal.open(context), child: const Text('go')),
          ),
        ),
      );

  Future<void> scrollTo(WidgetTester t, Key key) async {
    await t.scrollUntilVisible(find.byKey(key), 200,
        scrollable: find.descendant(
            of: find.byKey(const ValueKey('purchases-withdrawal-screen')), matching: find.byType(Scrollable)));
  }

  group('web', () {
    testWidgets('lists web purchases, withdrawal and the billing portal', (t) async {
      PurchasesWithdrawal.isWebOverride = true;
      summary = WebBillingSummary(
        subscriptions: const [
          WebSubscriptionInfo(
              name: 'Silver', amountCents: 999, currency: 'usd', interval: 'month', status: 'active', cancelAtPeriodEnd: false),
        ],
        orders: [
          WebOrderInfo(
            orderId: 'cs_1',
            name: '500 coins',
            withdrawable: true,
            amountCents: 399,
            currency: 'usd',
            createdAt: DateTime.utc(2026, 10, 10),
            withdrawalDeadline: DateTime.utc(2026, 10, 24),
          ),
        ],
      );
      await t.pumpWidget(app());
      await t.tap(find.text('go'));
      await t.pumpAndSettle();

      expect(find.byKey(const ValueKey('purchases-withdrawal-screen')), findsOneWidget);
      expect(find.text('Purchases & withdrawal'), findsOneWidget);
      expect(find.textContaining('Silver'), findsOneWidget);
      expect(find.textContaining('500 coins'), findsOneWidget);
      expect(find.textContaining('Withdraw by'), findsOneWidget);

      // "Withdraw from contract" opens the shared WithdrawalDialog.
      await scrollTo(t, const ValueKey('purchases-withdrawal-withdraw'));
      await t.tap(find.byKey(const ValueKey('purchases-withdrawal-withdraw')));
      await t.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Choose the purchase to withdraw from'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      await scrollTo(t, const ValueKey('purchases-withdrawal-portal'));
      await t.tap(find.byKey(const ValueKey('purchases-withdrawal-portal')));
      await t.pumpAndSettle();
      expect(portalCalls, 1);

      // Terms 9.4 / 9.5 summary + the store rows are always shown.
      await scrollTo(t, const ValueKey('purchases-withdrawal-apple'));
      expect(find.byKey(const ValueKey('purchases-withdrawal-rules')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('purchases-withdrawal-apple')));
      expect(opened.single.toString(), PurchasesWithdrawal.appleReportProblemUrl);
    });

    testWidgets('no web purchases: says so, withdrawal still reachable', (t) async {
      PurchasesWithdrawal.isWebOverride = true;
      await t.pumpWidget(app());
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('purchases-withdrawal-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('purchases-withdrawal-withdraw')), findsOneWidget);
    });

    testWidgets('portal failure shows a message', (t) async {
      PurchasesWithdrawal.isWebOverride = true;
      portalResult = false;
      await t.pumpWidget(app());
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('purchases-withdrawal-portal')));
      await t.pumpAndSettle();
      expect(find.text('Could not open the billing portal. Please try again.'), findsOneWidget);
    });

    testWidgets('load failure offers a retry', (t) async {
      PurchasesWithdrawal.isWebOverride = true;
      loadError = Exception('offline');
      await t.pumpWidget(app());
      await t.tap(find.text('go'));
      await t.pumpAndSettle();
      expect(find.text('Could not load your purchases. Please try again.'), findsOneWidget);
      loadError = null;
      await t.tap(find.text('Retry'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('purchases-withdrawal-empty')), findsOneWidget);
    });
  });

  testWidgets('Android / iOS: store purchases go through Google Play / Apple', (t) async {
    PurchasesWithdrawal.isWebOverride = false;
    await t.pumpWidget(app());
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('purchases-withdrawal-help')), findsOneWidget);
    expect(find.byKey(const ValueKey('purchases-withdrawal-screen')), findsNothing);
    await t.tap(find.byKey(const ValueKey('purchases-withdrawal-play')));
    await t.tap(find.byKey(const ValueKey('purchases-withdrawal-apple')));
    await t.tap(find.byKey(const ValueKey('purchases-withdrawal-email')));
    expect(opened.map((u) => u.toString()).toList(), [
      PurchasesWithdrawal.playOrderHistoryUrl,
      PurchasesWithdrawal.appleReportProblemUrl,
      'mailto:billing@greengochat.com',
    ]);
  });

  testWidgets('iOS: only Apple, never Google Play (App Review 2.3.10)', (t) async {
    PurchasesWithdrawal.isWebOverride = false;
    PurchasesWithdrawal.platformOverride = TargetPlatform.iOS;
    await t.pumpWidget(app());
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('purchases-withdrawal-play')), findsNothing);
    expect(find.byKey(const ValueKey('purchases-withdrawal-apple')), findsOneWidget);
    expect(find.textContaining('Google Play'), findsNothing);
    expect(find.textContaining('Android'), findsNothing);
    expect(find.text('Purchases made in the iPhone app were sold by Apple. Ask Apple for a refund or to withdraw:'),
        findsOneWidget);
  });

  group('Terms copy in every language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      test('$locale', () {
        final l = lookupAppLocalizations(locale);
        // Terms 9.4 d / 9.5 b: withdrawal contact is billing@.
        expect(l.withdrawalRequestFailed, contains('billing@greengochat.com'));
        expect(l.checkoutMembershipWithdrawalInfo, contains('billing@greengochat.com'));
        // Terms 28: NCII contact is safety@, info@ is gone.
        expect(l.nciiFormError, contains('safety@greengochat.com'));
        expect(l.nciiFormRateLimited, isNot(contains('info@')));
        // Terms 8.5 a.
        expect(l.coinsGiftAmountRange(CoinGiftLimits.minAmount, CoinGiftLimits.maxAmount), contains('1'));
        expect(l.deleteAccountConfirmation, isNotEmpty);
      });
    }

    test('English deletion dialog: coins, web, store, retention', () {
      final l = lookupAppLocalizations(const Locale('en'));
      final s = l.deleteAccountConfirmation;
      expect(s, contains('Coins left in your account are lost'));
      expect(s, contains('bought on the web is cancelled'));
      expect(s, contains('Google Play or the App Store is NOT cancelled'));
      expect(s, contains('Privacy Policy'));
      expect(s, isNot(contains('all your data will be permanently deleted')));
      expect(l.checkoutMembershipWithdrawalInfo, isNot(contains('full refund, using')));
      expect(l.checkoutMembershipWithdrawalInfo, contains('minus the days already used'));
    });

    test('client gift limits match Terms 8.5', () {
      expect(CoinGiftLimits.isValidAmount(9), isFalse);
      expect(CoinGiftLimits.isValidAmount(10), isTrue);
      expect(CoinGiftLimits.isValidAmount(1000), isTrue);
      expect(CoinGiftLimits.isValidAmount(1001), isFalse);
      expect(CoinGiftLimits.isValidAmount(null), isFalse);
    });
  });
}
