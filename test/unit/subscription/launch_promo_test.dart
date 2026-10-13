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
  final before = DateTime.utc(2026, 12, 31, 23); // still 31 Dec in Brazil
  final after = DateTime.utc(2027, 1, 1, 3);
  final regular = _phase(34900000, r'R$ 34,90', 'P1M');
  final launch = _phase(16900000, r'R$ 16,90', 'P1M', cycles: 3);

  tearDown(() => LaunchPromo.clock = DateTime.now);

  group('promo window', () {
    test('ends at the end of 31 Dec 2026, Brazil time', () {
      expect(LaunchPromo.isActive(before), isTrue);
      expect(LaunchPromo.isActive(after), isFalse);
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

    test('a free trial still wins over the launch offer', () {
      final entries = _play([
        [regular],
        [launch, regular],
        [_phase(0, 'Free', 'P7D', cycles: 1), regular],
      ]);
      expect(ProductCatalog.freeTrialPeriod(ProductCatalog.pickOffer(entries)),
          'P7D');
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
                'endsAt': endsAt ?? '2027-01-01T03:00:00.000Z',
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

  group('LaunchPromoPrice widget', () {
    Widget host(PromoPrice p) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: LaunchPromoPrice(promo: p, accent: Colors.amber),
          ),
        );

    testWidgets('launch price, then the regular price; no strikethrough',
        (tester) async {
      await tester.pumpWidget(host(const PromoPrice(
        yearly: true,
        launchLabel: r'$34.99',
        launchAmount: 34.99,
        regularLabel: r'$69.99',
        regularAmount: 69.99,
      )));
      expect(find.text('2026 launch price'), findsOneWidget);
      expect(find.text(r'$34.99'), findsOneWidget);
      expect(find.text(r'First year, then $69.99/year'), findsOneWidget);
      for (final t in tester.widgetList<Text>(find.byType(Text))) {
        expect(t.style?.decoration, isNot(TextDecoration.lineThrough));
      }
    });

    testWidgets('monthly plans say first 3 months', (tester) async {
      await tester.pumpWidget(host(const PromoPrice(
        yearly: false,
        launchLabel: r'$4.99',
        regularLabel: r'$9.99',
      )));
      expect(find.text(r'First 3 months, then $9.99/month'), findsOneWidget);
    });

    testWidgets('iOS without the offer details: regular price + generic line',
        (tester) async {
      await tester.pumpWidget(
          host(const PromoPrice.generic(yearly: true, regularLabel: r'$69.99')));
      expect(find.text(r'$69.99'), findsOneWidget);
      expect(find.textContaining('50% off your first period'), findsOneWidget);
    });
  });
}
