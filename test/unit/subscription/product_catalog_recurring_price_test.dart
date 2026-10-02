import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/product_catalog.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

PricingPhaseWrapper _phase(int micros, String formatted, String period) =>
    PricingPhaseWrapper(
      billingCycleCount: micros == 0 ? 1 : 0,
      billingPeriod: period,
      formattedPrice: formatted,
      priceAmountMicros: micros,
      priceCurrencyCode: 'BRL',
      recurrenceMode: micros == 0
          ? RecurrenceMode.finiteRecurring
          : RecurrenceMode.infiniteRecurring,
    );

/// One Play subscription whose offers are given as phase lists; returns one
/// GooglePlayProductDetails per offer, exactly like the plugin does.
List<GooglePlayProductDetails> _play(List<List<PricingPhaseWrapper>> offers,
        {String id = 'greengo_silver_yearly', bool baseFirst = true}) =>
    GooglePlayProductDetails.fromProductDetails(ProductDetailsWrapper(
      description: 'd',
      name: 'Silver',
      productId: id,
      productType: ProductType.subs,
      title: 'Silver (GreenGo)',
      subscriptionOfferDetails: [
        for (var i = 0; i < offers.length; i++)
          SubscriptionOfferDetailsWrapper(
            basePlanId: 'yearly',
            offerId: (i == 0) == baseFirst ? null : 'offer$i',
            offerTags: const [],
            offerIdToken: 'tok$i',
            pricingPhases: offers[i],
          ),
      ],
    ));

void main() {
  final recurring = _phase(119990000, r'R$ 119,99', 'P1Y');

  test('free-trial offer: plugin price is the trial, catalog shows recurring',
      () {
    final trial = _play([
      [_phase(0, 'Free', 'P7D'), recurring],
    ]).single;
    // The bug: ProductDetails.price/rawPrice come from the first phase.
    expect(trial.rawPrice, 0);
    expect(trial.price, 'Free');

    final r = ProductCatalog.recurringPrice(trial)!;
    expect(r.label, r'R$ 119,99');
    expect(r.amount, closeTo(119.99, 1e-9));
    expect(r.currencySymbol, r'R$');
    expect(ProductCatalog.recurringPriceLabel(trial), r'R$ 119,99');
    expect(ProductCatalog.freeTrialPeriod(trial), 'P7D');
    expect(ProductCatalog.hasSevenDayFreeTrial(trial), isTrue);
  });

  test('intro-price offer: recurring (last non-zero) phase wins, no trial', () {
    final intro = _play([
      [_phase(59990000, r'R$ 59,99', 'P1Y'), recurring],
    ]).single;
    expect(intro.price, r'R$ 59,99');
    expect(ProductCatalog.recurringPriceLabel(intro), r'R$ 119,99');
    expect(ProductCatalog.freeTrialPeriod(intro), isNull);
    expect(ProductCatalog.hasSevenDayFreeTrial(intro), isFalse);
  });

  test('base plan without offers: price unchanged, no trial', () {
    final plain = _play([
      [recurring],
    ]).single;
    expect(ProductCatalog.recurringPriceLabel(plain), plain.price);
    expect(ProductCatalog.recurringPrice(plain)!.amount, plain.rawPrice);
    expect(ProductCatalog.freeTrialPeriod(plain), isNull);
  });

  test('a trial of a different length does not claim "7 days free"', () {
    final p = _play([
      [_phase(0, 'Free', 'P14D'), recurring],
    ]).single;
    expect(ProductCatalog.freeTrialPeriod(p), 'P14D');
    expect(ProductCatalog.hasSevenDayFreeTrial(p), isFalse);
    expect(ProductCatalog.recurringPriceLabel(p), r'R$ 119,99');
  });

  test('every offer of one product shows the same recurring price', () {
    final offers = _play([
      [recurring],
      [_phase(0, 'Free', 'P7D'), recurring],
    ]);
    expect(offers, hasLength(2));
    expect(offers.map(ProductCatalog.recurringPriceLabel).toSet(),
        {r'R$ 119,99'});
  });

  test('non-Play product (iOS/web): uses ProductDetails.price', () {
    final ios = ProductDetails(
      id: 'subscription_1_year_silver',
      title: 'Silver',
      description: 'd',
      price: r'$119.99',
      rawPrice: 119.99,
      currencyCode: 'USD',
      currencySymbol: r'$',
    );
    final r = ProductCatalog.recurringPrice(ios)!;
    expect(r.label, r'$119.99');
    expect(r.currencySymbol, r'$');
    expect(ProductCatalog.freeTrialPeriod(ios), isNull);
  });

  test('zero-priced non-Play product: recurringPrice null, label falls back',
      () {
    final free = ProductDetails(
      id: 'x',
      title: 't',
      description: 'd',
      price: 'Free',
      rawPrice: 0,
      currencyCode: 'USD',
    );
    expect(ProductCatalog.recurringPrice(free), isNull);
    expect(ProductCatalog.recurringPriceLabel(free), 'Free');
  });

  String? offerIdOf(ProductDetails p) {
    final g = p as GooglePlayProductDetails;
    return g.productDetails.subscriptionOfferDetails![g.subscriptionIndex!]
        .offerId;
  }

  group('pickOffer / onePerProduct', () {
    final trialPhases = [_phase(0, 'Free', 'P7D'), recurring];
    final introPhases = [_phase(59990000, r'R$ 59,99', 'P1Y'), recurring];

    test('trial + base -> the free-trial offer (wherever it is listed)', () {
      for (final baseFirst in [true, false]) {
        final entries = baseFirst
            ? _play([[recurring], trialPhases])
            : _play([trialPhases, [recurring]], baseFirst: false);
        final picked = ProductCatalog.pickOffer(entries);
        expect(ProductCatalog.freeTrialPeriod(picked), 'P7D',
            reason: 'baseFirst=$baseFirst');
        expect(offerIdOf(picked), isNotNull);
      }
    });

    test('intro + base -> the base plan (no offer id)', () {
      // Intro offer listed first, so "first returned" would be wrong.
      final entries = _play([introPhases, [recurring]], baseFirst: false);
      final picked = ProductCatalog.pickOffer(entries);
      expect(offerIdOf(picked), isNull);
      expect(picked.price, r'R$ 119,99');
    });

    test('ambiguous (two offers, no base plan) -> single-phase offer, '
        'else first', () {
      final entries = GooglePlayProductDetails.fromProductDetails(
          ProductDetailsWrapper(
        description: 'd',
        name: 'n',
        productId: 'p',
        productType: ProductType.subs,
        title: 't',
        subscriptionOfferDetails: [
          SubscriptionOfferDetailsWrapper(
              basePlanId: 'b', offerId: 'intro', offerTags: const [],
              offerIdToken: 't0', pricingPhases: introPhases),
          SubscriptionOfferDetailsWrapper(
              basePlanId: 'b', offerId: 'plain', offerTags: const [],
              offerIdToken: 't1', pricingPhases: [recurring]),
        ],
      ));
      expect(offerIdOf(ProductCatalog.pickOffer(entries)), 'plain');
      expect(ProductCatalog.pickOffer(entries.sublist(0, 1)), entries.first);
    });

    test('base only -> that entry', () {
      final entries = _play([[recurring]]);
      expect(ProductCatalog.pickOffer(entries), same(entries.single));
    });

    test('iOS (single non-Play entry) -> returned as-is', () {
      final ios = ProductDetails(
        id: 'subscription_1_year_silver',
        title: 'Silver',
        description: 'd',
        price: r'$119.99',
        rawPrice: 119.99,
        currencyCode: 'USD',
      );
      expect(ProductCatalog.pickOffer([ios]), same(ios));
      expect(ProductCatalog.onePerProduct([ios]), [ios]);
    });

    test('onePerProduct: one card per id, first-appearance order kept', () {
      final silver = _play([[recurring], trialPhases]);
      final base = _play([[recurring], trialPhases],
          id: 'greengo_base_membership');
      final gold = _play([introPhases, [recurring]],
          id: 'gold_premium_monthly', baseFirst: false);
      final out = ProductCatalog.onePerProduct([...silver, ...base, ...gold]);
      expect(out.map((p) => p.id), [
        'greengo_silver_yearly',
        'greengo_base_membership',
        'gold_premium_monthly',
      ]);
      expect(ProductCatalog.freeTrialPeriod(out[0]), 'P7D');
      expect(ProductCatalog.freeTrialPeriod(out[1]), 'P7D');
      expect(offerIdOf(out[2]), isNull);
    });
  });
}
