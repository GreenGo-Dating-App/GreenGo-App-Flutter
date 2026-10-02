import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/product_catalog.dart';
import 'package:greengo_chat/features/subscription/domain/entities/subscription.dart';
import 'package:greengo_chat/features/subscription/domain/membership_product_mapping.dart';

typedef _Expect = (MembershipProductTier, MembershipPeriod, String canonical);

void main() {
  const base = MembershipProductTier.base;
  const silver = MembershipProductTier.silver;
  const gold = MembershipProductTier.gold;
  const platinum = MembershipProductTier.platinum;
  const monthly = MembershipPeriod.monthly;
  const yearly = MembershipPeriod.yearly;

  // Every real product ID, written out literally (not derived from the
  // catalog) so a catalog edit can't silently change what we assert.
  final Map<String, _Expect> realIds = <String, _Expect>{
    // Canonical (app code, server PRODUCT_CONFIG, web/Stripe)
    'greengo_base_membership': (base, yearly, 'greengo_base_membership'),
    '1_month_silver': (silver, monthly, '1_month_silver'),
    '1_year_silver': (silver, yearly, '1_year_silver'),
    '1_month_gold': (gold, monthly, '1_month_gold'),
    '1_year_gold': (gold, yearly, '1_year_gold'),
    '1_month_platinum': (platinum, monthly, '1_month_platinum'),
    '1_year_platinum_membership':
        (platinum, yearly, '1_year_platinum_membership'),
    // iOS (App Store Connect)
    'subscription_greengo_base_membership':
        (base, yearly, 'greengo_base_membership'),
    'subscription_1_month_silver': (silver, monthly, '1_month_silver'),
    'subscription_1_year_silver': (silver, yearly, '1_year_silver'),
    'subscription_1_month_gold': (gold, monthly, '1_month_gold'),
    'subscription_1_year_gold': (gold, yearly, '1_year_gold'),
    'subscription_1_month_platinum': (platinum, monthly, '1_month_platinum'),
    'subscription_1_year_platinum_membership':
        (platinum, yearly, '1_year_platinum_membership'),
    // Android (Google Play)
    'silver_premium_monthly': (silver, monthly, '1_month_silver'),
    'greengo_silver_yearly': (silver, yearly, '1_year_silver'),
    'gold_premium_monthly': (gold, monthly, '1_month_gold'),
    'greengo_gold_yearly': (gold, yearly, '1_year_gold'),
    'platinum_vip_monthly': (platinum, monthly, '1_month_platinum'),
    'greengo_platinum_yearly': (platinum, yearly, '1_year_platinum_membership'),
  };

  group('ProductCatalog.classify — every real product ID', () {
    realIds.forEach((id, e) {
      test('$id -> ${e.$1.name} / ${e.$2.name}', () {
        final info = ProductCatalog.classify(id);
        expect(info.isKnown, isTrue);
        expect(info.tier, e.$1);
        expect(info.period, e.$2);
        expect(info.canonicalId, e.$3);
        expect(info.isBase, e.$1 == base);
      });
    });
  });

  test('the literal list covers every catalog ID on every platform', () {
    final catalogIds = <String>{
      ...ProductCatalog.canonicalIds,
      ...ProductCatalog.canonicalIds.map(ProductCatalog.iosStoreId),
      ...ProductCatalog.androidIds.values,
    };
    expect(catalogIds, realIds.keys.toSet());
    for (final c in ProductCatalog.canonicalIds) {
      final a = ProductCatalog.classify(ProductCatalog.androidIds[c]!);
      final i = ProductCatalog.classify(ProductCatalog.iosStoreId(c));
      final k = ProductCatalog.classify(c);
      expect((a.tier, a.period), (k.tier, k.period), reason: c);
      expect((i.tier, i.period), (k.tier, k.period), reason: c);
    }
  });

  test('Play IDs group correctly (regression: `1_month` substring missed them)',
      () {
    final playIds = ProductCatalog.androidIds.values.toList();
    final monthlyGroup = playIds
        .where((id) => !ProductCatalog.classify(id).isBase)
        .where((id) => ProductCatalog.classify(id).isMonthly)
        .toSet();
    final yearlyGroup = playIds
        .where((id) => !ProductCatalog.classify(id).isBase)
        .where((id) => ProductCatalog.classify(id).isYearly)
        .toSet();
    expect(monthlyGroup, {
      'silver_premium_monthly',
      'gold_premium_monthly',
      'platinum_vip_monthly',
    });
    expect(yearlyGroup, {
      'greengo_silver_yearly',
      'greengo_gold_yearly',
      'greengo_platinum_yearly',
    });
  });

  group('unknown IDs are kept and guessed, never dropped', () {
    test('tier and period inferred from text', () {
      final info = ProductCatalog.classify('gold_promo_annual');
      expect(info.isKnown, isFalse);
      expect(info.tier, gold);
      expect(info.period, yearly);
      expect(info.canonicalId, 'gold_promo_annual');
    });

    test('no hints -> base tier, monthly period, not known', () {
      final info = ProductCatalog.classify('mystery_sku');
      expect(info.isKnown, isFalse);
      expect(info.tier, base);
      expect(info.period, monthly);
    });

    test('unknown iOS-prefixed ID keeps its stripped canonical form', () {
      final info = ProductCatalog.classify('subscription_1_month_diamond');
      expect(info.isKnown, isFalse);
      expect(info.canonicalId, '1_month_diamond');
      expect(info.period, monthly);
    });
  });

  test('subscriptionTierForProduct matches legacy substring mapping for all '
      'real IDs (purchase tier unchanged)', () {
    SubscriptionTier legacy(String id) {
      if (id.contains('platinum')) return SubscriptionTier.platinum;
      if (id.contains('gold')) return SubscriptionTier.gold;
      if (id.contains('silver')) return SubscriptionTier.silver;
      return SubscriptionTier.basic;
    }

    for (final id in realIds.keys) {
      expect(subscriptionTierForProduct(id), legacy(id), reason: id);
    }
  });
}
