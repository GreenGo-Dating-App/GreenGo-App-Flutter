import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/launch_promo.dart';
import 'package:greengo_chat/core/constants/product_catalog.dart';
import 'package:greengo_chat/core/services/display_prices.dart';
import 'package:greengo_chat/core/widgets/launch_promo_price.dart';
import 'package:greengo_chat/features/subscription/domain/entities/subscription.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

PricingPhaseWrapper _phase(int micros, String formatted, String period,
        {int cycles = 0}) =>
    PricingPhaseWrapper(
      billingCycleCount: cycles,
      billingPeriod: period,
      formattedPrice: formatted,
      priceAmountMicros: micros,
      priceCurrencyCode: 'BRL',
      recurrenceMode: cycles > 0
          ? RecurrenceMode.finiteRecurring
          : RecurrenceMode.infiniteRecurring,
    );

/// One Play subscription; each inner list is one offer's phases. The first
/// offer is the base plan (no offer id), the others get ids.
List<GooglePlayProductDetails> _play(List<List<PricingPhaseWrapper>> offers,
        {List<String?>? ids}) =>
    GooglePlayProductDetails.fromProductDetails(ProductDetailsWrapper(
      description: 'd',
      name: 'Silver',
      productId: 'silver_premium_monthly',
      productType: ProductType.subs,
      title: 'Silver (GreenGo)',
      subscriptionOfferDetails: [
        for (var i = 0; i < offers.length; i++)
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'monthly',
            offerId: ids != null ? ids[i] : (i == 0 ? null : 'offer$i'),
            offerTags: const [],
            offerIdToken: 'tok$i',
            pricingPhases: offers[i],
          ),
      ],
    ));

void main() {
  final before = DateTime.utc(2027, 4, 1, 2, 59, 59); // still 31 Mar in Brazil
  final after = DateTime.utc(2027, 4, 1, 3); // 1 Apr 2027 00:00 in Brazil
  final regular = _phase(34900000, r'R$ 34,90', 'P1M');
  final launch = _phase(16900000, r'R$ 16,90', 'P1M', cycles: 3);

  tearDown(() => LaunchPromo.clock = DateTime.now);

  group('promo window', () {
    test('ends at the end of 31 Mar 2027, Brazil time (extended from 31 Dec 2026)', () {
      expect(LaunchPromo.isActive(before), isTrue);
      expect(LaunchPromo.isActive(after), isFalse);
      // The old end date no longer ends the offer.
      expect(LaunchPromo.isActive(DateTime.utc(2027, 1, 1, 3)), isTrue);
      expect(LaunchPromo.isActive(DateTime.utc(2027, 3, 31, 12)), isTrue);
      expect(LaunchPromo.percentOff, 50);
    });

    test('every plan is half price or a little less (BRL ends in ,90)', () {
      const regularPrices = {
        'greengo_base_membership': (9.99, 29.90),
        '1_month_silver': (9.99, 34.90),
        '1_month_gold': (19.99, 59.90),
        '1_month_platinum': (29.99, 89.90),
        '1_year_silver': (69.99, 249.90),
        '1_year_gold': (119.99, 399.90),
        '1_year_platinum_membership': (179.99, 599.90),
      };
      expect(LaunchPromo.launchPrices.keys.toSet(), regularPrices.keys.toSet());
      LaunchPromo.launchPrices.forEach((id, p) {
        final r = regularPrices[id]!;
        expect(p.$1, lessThanOrEqualTo(r.$1 / 2 + 0.005), reason: id);
        expect(p.$2, lessThanOrEqualTo(r.$2 / 2 + 0.005), reason: id);
        expect(p.$1, greaterThan(r.$1 * 0.45), reason: id);
        expect(((p.$2 * 100).round() % 100), 90, reason: id);
      });
    });
  });

  group('Android offers', () {
    test('the launch offer is picked over the base plan', () {
      final entries = _play([
        [regular],
        [launch, regular],
      ], ids: [null, LaunchPromo.id]);
      final picked = ProductCatalog.pickOffer(entries);
      expect(ProductCatalog.introPhase(picked), isNotNull);
      final intro = ProductCatalog.introPhase(picked)!;
      expect(intro.label, r'R$ 16,90');
      expect(intro.amount, closeTo(16.90, 1e-9));
      expect(intro.cycles, 3);
      expect(intro.billingPeriod, 'P1M');
      expect(ProductCatalog.recurringPriceLabel(picked), r'R$ 34,90');
    });

    test('a free trial is never picked: the launch offer wins (no trials, '
        'owner 2026-10-17)', () {
      final entries = _play([
        [regular],
        [launch, regular],
        [_phase(0, 'Free', 'P7D', cycles: 1), regular],
      ]);
      final picked = ProductCatalog.pickOffer(entries);
      expect(ProductCatalog.freeTrialPeriod(picked), isNull);
      expect(ProductCatalog.introPhase(picked), isNotNull);
    });

    test('trial + base only: the base plan, never the trial', () {
      final entries = _play([
        [_phase(0, 'Free', 'P7D', cycles: 1), regular],
        [regular],
      ], ids: ['trial7', null]);
      final picked = ProductCatalog.pickOffer(entries);
      expect(ProductCatalog.freeTrialPeriod(picked), isNull);
      expect(ProductCatalog.promoPrice(picked, yearly: false, now: before),
          isNull, reason: 'no launch offer from Play: no offer line');
    });

    test('launch2026 is preferred over another discount offer', () {
      final other = _phase(24900000, r'R$ 24,90', 'P1M', cycles: 1);
      final entries = _play([
        [regular],
        [other, regular],
        [launch, regular],
      ], ids: [null, 'winback', LaunchPromo.id]);
      expect(ProductCatalog.introPhase(ProductCatalog.pickOffer(entries))!.label,
          r'R$ 16,90');
    });

    test('a first phase that is not cheaper is not an intro price', () {
      final same = _play([
        [_phase(34900000, r'R$ 34,90', 'P1M', cycles: 3), regular],
      ]).single;
      expect(ProductCatalog.introPhase(same), isNull);
      expect(ProductCatalog.introPhase(_play([[regular]]).single), isNull);
    });

    test('promoPrice: launch + regular while the promo runs, nothing after', () {
      final offer = _play([
        [launch, regular],
      ]).single;
      final p = ProductCatalog.promoPrice(offer, yearly: false, now: before)!;
      expect(p.isGeneric, isFalse);
      expect(p.launchLabel, r'R$ 16,90');
      expect(p.regularLabel, r'R$ 34,90');
      expect(p.periods, 3);
      expect(ProductCatalog.promoPrice(offer, yearly: false, now: after), isNull);
      // A base plan alone (user not eligible / offer not set up): no promo.
      expect(
          ProductCatalog.promoPrice(_play([[regular]]).single,
              yearly: false, now: before),
          isNull);
    });
  });

  group('yearly launch savings never overstate', () {
    test('smaller of USD and BRL, rounded down', () {
      // Silver: USD 34.99 vs 119.88 = 70.8%, BRL 124.90 vs 418.80 = 70.2%.
      expect(SubscriptionTier.silver.yearlyLaunchSavingsPercent, 70);
      // Gold / Platinum: USD 74.99%, BRL 72.2%.
      expect(SubscriptionTier.gold.yearlyLaunchSavingsPercent, 72);
      expect(SubscriptionTier.platinum.yearlyLaunchSavingsPercent, 72);
      expect(SubscriptionTier.basic.yearlyLaunchSavingsPercent, 0);
    });

    test('no claim above what a USD or BRL buyer saves', () {
      for (final t in [
        SubscriptionTier.silver,
        SubscriptionTier.gold,
        SubscriptionTier.platinum,
      ]) {
        final launch = LaunchPromo.launchPrices[t.yearlyProductId]!;
        final usd = (1 - launch.$1 / (t.monthlyPrice * 12)) * 100;
        expect(t.yearlyLaunchSavingsPercent, lessThanOrEqualTo(usd));
      }
    });
  });

  group('web promo from getDisplayPrices', () {
    Map<String, dynamic> response({String? endsAt}) => {
          'prices': {
            'greengo_coins_100': {'display': r'R$ 5,90', 'currency': 'brl', 'amountCents': 590},
            '1_year_silver': {
              'display': r'R$ 249,90',
              'currency': 'brl',
              'amountCents': 24990,
              'promo': {
                'id': 'launch2026',
                'display': r'R$ 124,90',
                'amountCents': 12490,
                'percentOff': 50,
                'periods': 1,
                'interval': 'year',
                'endsAt': endsAt ?? '2027-04-01T03:00:00.000Z',
              },
            },
          },
        };

    test('parses the launch price next to the regular one', () {
      final m = parseDisplayPromos(response(), now: before);
      expect(m.keys, ['1_year_silver']);
      final p = m['1_year_silver']!;
      expect(p.launchLabel, r'R$ 124,90');
      expect(p.launchAmount, closeTo(124.90, 1e-9));
      expect(p.regularLabel, r'R$ 249,90');
      expect(p.yearly, isTrue);
      expect(p.periods, 1);
      // The regular labels are unchanged for the existing parser.
      expect(parseDisplayPrices(response())['1_year_silver'], r'R$ 249,90');
    });

    test('nothing after the end date, the server end date, or from an old server', () {
      expect(parseDisplayPromos(response(), now: after), isEmpty);
      expect(
          parseDisplayPromos(response(endsAt: '2026-11-01T00:00:00Z'),
              now: DateTime.utc(2026, 11, 2)),
          isEmpty);
      expect(
          parseDisplayPromos({
            'prices': {
              '1_year_silver': {'display': r'R$ 249,90', 'amountCents': 24990},
            },
          }, now: before),
          isEmpty);
      expect(parseDisplayPromos(null, now: before), isEmpty);
    });
  });

  group('LaunchPromoPrice widget (same wording on every platform)', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Widget host(PromoPrice p) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: LaunchPromoPrice(promo: p, accent: Colors.amber),
          ),
        );

    const yearly = PromoPrice(
      yearly: true,
      launchLabel: r'$34.99',
      launchAmount: 34.99,
      regularLabel: r'$69.99',
      regularAmount: 69.99,
    );

    testWidgets('iOS: 50% first year, regular renewal price, App Store line',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(host(yearly));
      expect(find.text('2026 launch price'), findsOneWidget);
      expect(find.text(r'$34.99'), findsOneWidget);
      expect(
          find.text(r'50% off your first year for new subscribers: $34.99, '
              r'then $69.99/year.'),
          findsOneWidget);
      expect(
          find.text('Renews automatically; cancel anytime in App Store settings.'),
          findsOneWidget);
      expect(find.textContaining('Google Play'), findsNothing);
      expect(find.textContaining('free'), findsNothing);
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        expect(t.style?.decoration, isNot(TextDecoration.lineThrough));
      }
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Android: same offer line, Google Play renewal line',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(host(yearly));
      expect(
          find.text(r'50% off your first year for new subscribers: $34.99, '
              r'then $69.99/year.'),
          findsOneWidget);
      expect(find.textContaining('Google Play subscriptions'), findsOneWidget);
      expect(find.textContaining('App Store'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('monthly plans say first 3 months', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(host(const PromoPrice(
        yearly: false,
        launchLabel: r'$4.99',
        regularLabel: r'$9.99',
      )));
      expect(
          find.text(r'50% off your first 3 months for new subscribers: '
              r'$4.99/month, then $9.99/month.'),
          findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('no launch amount (StoreKit 2, other currency): percent only',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(
          host(const PromoPrice.generic(yearly: true, regularLabel: r'$69.99')));
      expect(find.text(r'$69.99'), findsOneWidget);
      expect(
          find.text(r'50% off your first year for new subscribers, then '
              r'$69.99/year.'),
          findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('no regular price: nothing is claimed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(host(const PromoPrice.generic(yearly: true)));
      expect(find.text('2026 launch price'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('iOS StoreKit 2 launch price', () {
    AppStoreProduct2Details sk2(String id, double price, String display,
            {String currency = 'USD', String symbol = r'$'}) =>
        AppStoreProduct2Details.fromSK2Product(SK2Product(
          id: id,
          displayName: 'n',
          displayPrice: display,
          description: 'd',
          price: price,
          type: SK2ProductType.autoRenewable,
          priceLocale:
              SK2PriceLocale(currencyCode: currency, currencySymbol: symbol),
        ));

    tearDown(() {
      ProductCatalog.resetIntroEligibility();
      ProductCatalog.introEligibilityCheck = (_) async => true;
    });

    test('catalogue launch price in the storefront format (USD, BRL)', () {
      final usd = ProductCatalog.promoPrice(
          sk2('subscription_1_year_silver', 69.99, r'$69.99'),
          yearly: true,
          now: before)!;
      expect(usd.launchLabel, r'$34.99');
      expect(usd.regularLabel, r'$69.99');
      final brl = ProductCatalog.promoPrice(
          sk2('subscription_1_month_gold', 59.90, r'R$ 59,90',
              currency: 'BRL', symbol: r'R$'),
          yearly: false,
          now: before)!;
      expect(brl.launchLabel, r'R$ 29,90');
      expect(brl.periods, 3);
    });

    test('other currency: percent-only line, never an invented amount', () {
      final p = ProductCatalog.promoPrice(
          sk2('subscription_1_year_gold', 18000, 'JPY 18,000',
              currency: 'JPY', symbol: 'JPY'),
          yearly: true,
          now: before)!;
      expect(p.isGeneric, isTrue);
      expect(p.regularLabel, 'JPY 18,000');
    });

    test('Apple ID not eligible for the intro offer: no offer shown', () async {
      final silver = sk2('subscription_1_year_silver', 69.99, r'$69.99');
      final gold = sk2('subscription_1_year_gold', 119.99, r'$119.99');
      ProductCatalog.introEligibilityCheck =
          (id) async => id != 'subscription_1_year_silver';
      await ProductCatalog.loadIntroEligibility([silver, gold]);
      expect(ProductCatalog.promoPrice(silver, yearly: true, now: before), isNull);
      expect(ProductCatalog.promoPrice(gold, yearly: true, now: before), isNotNull);
    });

    test('eligibility check failing keeps the offer (wording says new '
        'subscribers)', () async {
      final silver = sk2('subscription_1_year_silver', 69.99, r'$69.99');
      ProductCatalog.introEligibilityCheck = (_) async => throw Exception('x');
      await ProductCatalog.loadIntroEligibility([silver]);
      expect(ProductCatalog.promoPrice(silver, yearly: true, now: before),
          isNotNull);
    });

    test('formatLike keeps symbol position and decimal separator', () {
      expect(ProductCatalog.formatLike(r'R$ 29,90', 14.9), r'R$ 14,90');
      expect(ProductCatalog.formatLike(r'$9.99', 4.99), r'$4.99');
      expect(ProductCatalog.formatLike('9,99 EUR', 4.99), '4,99 EUR');
    });
  });

  test('a cached launch price reads back the same (painted with the prices)', () {
    const p = PromoPrice(
      yearly: true,
      launchLabel: 'R\$ 14,90',
      launchAmount: 14.9,
      regularLabel: 'R\$ 29,90',
      regularAmount: 29.9,
    );
    final back = PromoPrice.fromJson(p.toJson())!;
    expect(back.yearly, isTrue);
    expect(back.launchLabel, 'R\$ 14,90');
    expect(back.launchAmount, 14.9);
    expect(back.regularLabel, 'R\$ 29,90');
    expect(back.regularAmount, 29.9);
    final generic = PromoPrice.fromJson(
        const PromoPrice.generic(yearly: false, regularLabel: r'$9.99').toJson())!;
    expect(generic.isGeneric, isTrue);
    expect(PromoPrice.fromJson('junk'), isNull);
    expect(PromoPrice.fromJson({'l': 'x'}), isNull);
  });
}
