import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/domain/entities/coin_balance.dart';

/// Master Test Plan — Coins / balance & expiration math.
/// Pure tests for [CoinBalance] batch accounting: available vs expired coins,
/// the 30-day "expiring soon" window, and the affordability check.
void main() {
  final now = DateTime.now();

  CoinBatch batch({
    required String id,
    required int remaining,
    required DateTime expiration,
    CoinSource source = CoinSource.purchase,
  }) =>
      CoinBatch(
        batchId: id,
        initialCoins: remaining,
        remainingCoins: remaining,
        source: source,
        acquiredDate: now.subtract(const Duration(days: 1)),
        expirationDate: expiration,
      );

  CoinBalance balance(List<CoinBatch> batches) => CoinBalance(
        userId: 'u1',
        totalCoins: 0,
        earnedCoins: 0,
        purchasedCoins: 0,
        giftedCoins: 0,
        spentCoins: 0,
        lastUpdated: now,
        coinBatches: batches,
      );

  group('CoinBatch', () {
    test('isExpired is true only after the expiration instant', () {
      final b = batch(
          id: 'b', remaining: 10, expiration: now.add(const Duration(days: 1)));
      expect(b.isExpired(now), isFalse);
      expect(b.isExpired(now.add(const Duration(days: 2))), isTrue);
    });

    test('daysUntilExpiration is 0 for an already-expired batch', () {
      final b = batch(
          id: 'b',
          remaining: 10,
          expiration: now.subtract(const Duration(days: 1)));
      expect(b.daysUntilExpiration(), 0);
    });
  });

  group('CoinBalance batch accounting', () {
    test('availableCoins sums only non-expired batches', () {
      final b = balance([
        batch(
            id: 'live1',
            remaining: 100,
            expiration: now.add(const Duration(days: 40))),
        batch(
            id: 'live2',
            remaining: 50,
            expiration: now.add(const Duration(days: 10))),
        batch(
            id: 'dead',
            remaining: 999,
            expiration: now.subtract(const Duration(days: 1))),
      ]);
      expect(b.availableCoins, 150);
    });

    test('expiredCoins sums only expired batches', () {
      final b = balance([
        batch(
            id: 'live',
            remaining: 100,
            expiration: now.add(const Duration(days: 40))),
        batch(
            id: 'dead',
            remaining: 25,
            expiration: now.subtract(const Duration(days: 5))),
      ]);
      expect(b.expiredCoins, 25);
    });

    test('getCoinsExpiringSoon counts live batches inside the 30-day window',
        () {
      final b = balance([
        batch(
            id: 'soon',
            remaining: 30,
            expiration: now.add(const Duration(days: 10))),
        batch(
            id: 'later',
            remaining: 70,
            expiration: now.add(const Duration(days: 90))),
        batch(
            id: 'dead',
            remaining: 5,
            expiration: now.subtract(const Duration(days: 1))),
      ]);
      expect(b.getCoinsExpiringSoon(), 30);
    });

    test('hasEnoughCoins compares against availableCoins', () {
      final b = balance([
        batch(
            id: 'live',
            remaining: 40,
            expiration: now.add(const Duration(days: 5))),
        batch(
            id: 'dead',
            remaining: 1000,
            expiration: now.subtract(const Duration(days: 1))),
      ]);
      expect(b.hasEnoughCoins(40), isTrue);
      expect(b.hasEnoughCoins(41), isFalse,
          reason: 'expired coins do not count toward affordability');
    });

    test('an empty balance has zero everywhere', () {
      final b = balance(const []);
      expect(b.availableCoins, 0);
      expect(b.expiredCoins, 0);
      expect(b.getCoinsExpiringSoon(), 0);
      expect(b.hasEnoughCoins(1), isFalse);
    });
  });

  group('CoinSource wire mapping', () {
    test('fromString round-trips every enum name', () {
      for (final s in CoinSource.values) {
        expect(CoinSourceExtension.fromString(s.name), s);
      }
    });

    test('fromString is case-insensitive and falls back to purchase', () {
      expect(CoinSourceExtension.fromString('GIFT'), CoinSource.gift);
      expect(CoinSourceExtension.fromString('garbage'), CoinSource.purchase);
    });
  });
}
