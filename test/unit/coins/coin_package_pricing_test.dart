import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/domain/entities/coin_package.dart';

/// Master Test Plan — Coins / package pricing math + spend catalog.
/// Covers E2E matrix item #239 (coin packages: prices, coins/$ ratio, bonus
/// badges) and #240 (active promotion window). Pure tests against the real
/// [CoinPackage], [CoinPackages] and [CoinSpendItems].
void main() {
  CoinPackage pkg({
    int coinAmount = 100,
    double price = 0.99,
    int? bonusCoins,
    double? discountPercentage,
    bool isPromotional = false,
    DateTime? start,
    DateTime? end,
    String currency = 'USD',
  }) =>
      CoinPackage(
        packageId: 'p',
        productId: 'greengo_p',
        coinAmount: coinAmount,
        price: price,
        bonusCoins: bonusCoins,
        discountPercentage: discountPercentage,
        isPromotional: isPromotional,
        promotionStartDate: start,
        promotionEndDate: end,
        currency: currency,
      );

  group('totalCoins & coinsPerDollar', () {
    test('totalCoins adds the bonus (or nothing when null)', () {
      expect(pkg(coinAmount: 500).totalCoins, 500);
      expect(pkg(coinAmount: 500, bonusCoins: 100).totalCoins, 600);
    });

    test('coinsPerDollar divides total coins by price', () {
      final p = pkg(coinAmount: 1000, price: 5.0);
      expect(p.coinsPerDollar, 200.0);
    });

    test('bonus coins improve the coins/dollar ratio', () {
      final noBonus = pkg(coinAmount: 1000, price: 5.0);
      final withBonus = pkg(coinAmount: 1000, price: 5.0, bonusCoins: 500);
      expect(withBonus.coinsPerDollar, greaterThan(noBonus.coinsPerDollar));
    });
  });

  group('savingsText', () {
    test('prefers bonus coins wording when a bonus exists', () {
      expect(pkg(bonusCoins: 250).savingsText, '+250 bonus coins');
    });

    test('falls back to discount percentage when no bonus', () {
      expect(pkg(discountPercentage: 20).savingsText, '20% off');
    });

    test('is null when neither bonus nor discount applies', () {
      expect(pkg().savingsText, isNull);
      expect(pkg(bonusCoins: 0, discountPercentage: 0).savingsText, isNull);
    });
  });

  group('displayPrice', () {
    test('USD uses a dollar sign with two decimals', () {
      expect(pkg(price: 3.99).displayPrice, r'$3.99');
    });

    test('non-USD prefixes the currency code', () {
      expect(pkg(price: 4.5, currency: 'EUR').displayPrice, 'EUR 4.50');
    });
  });

  group('isPromotionActive window', () {
    final now = DateTime.now();
    test('non-promotional packages are never active', () {
      expect(pkg().isPromotionActive, isFalse);
    });

    test('promotional with no dates is always active', () {
      expect(pkg(isPromotional: true).isPromotionActive, isTrue);
    });

    test('active only inside [start, end]', () {
      final live = pkg(
        isPromotional: true,
        start: now.subtract(const Duration(days: 1)),
        end: now.add(const Duration(days: 1)),
      );
      final notYet = pkg(
        isPromotional: true,
        start: now.add(const Duration(days: 1)),
      );
      final ended = pkg(
        isPromotional: true,
        end: now.subtract(const Duration(days: 1)),
      );
      expect(live.isPromotionActive, isTrue);
      expect(notYet.isPromotionActive, isFalse);
      expect(ended.isPromotionActive, isFalse);
    });
  });

  group('CoinPackages catalog', () {
    test('exposes the four standard packages', () {
      expect(CoinPackages.standardPackages.length, 4);
    });

    test('getByProductId resolves a known product and null for unknown', () {
      expect(CoinPackages.getByProductId('greengo_coins_500'),
          CoinPackages.popular);
      expect(CoinPackages.getByProductId('nope'), isNull);
    });

    test('every standard package has a positive price and coin amount', () {
      for (final p in CoinPackages.standardPackages) {
        expect(p.price, greaterThan(0));
        expect(p.coinAmount, greaterThan(0));
        expect(p.coinsPerDollar, greaterThan(0));
      }
    });
  });

  group('CoinSpendItems catalog', () {
    test('getById resolves a known item and null for unknown', () {
      expect(CoinSpendItems.getById('super_like'), CoinSpendItems.superLike);
      expect(CoinSpendItems.getById('teleport'), isNull);
    });

    test('getByCategory returns only items of that category', () {
      final gifts = CoinSpendItems.getByCategory(CoinSpendCategory.gifts);
      expect(gifts, isNotEmpty);
      expect(gifts.every((i) => i.category == CoinSpendCategory.gifts), isTrue);
    });

    test('every spend item has a positive coin cost', () {
      for (final i in CoinSpendItems.all) {
        expect(i.coinCost, greaterThan(0), reason: i.itemId);
      }
    });

    test('every spend category has a non-empty displayName', () {
      for (final c in CoinSpendCategory.values) {
        expect(c.displayName, isNotEmpty);
      }
    });
  });
}
