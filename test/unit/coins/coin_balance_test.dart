import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/domain/entities/coin_balance.dart';

/// Master Test Plan — Coins / balance math.
///
/// Since v4.0.0 (commit 3e92076, App Store Guideline 3.1.1) coins NEVER
/// expire: [CoinBatch] carries no expiration date and [CoinBalance] has no
/// expired / expiring-soon accounting. These tests pin the current rule:
///
///   availableCoins = max(totalCoins, sum of batch remainders)
///
/// so coins credited by Cloud Functions with a bare `totalCoins` increment
/// (no batch) are still spendable, and old batches are never withheld.
void main() {
  final now = DateTime.now();

  CoinBatch batch({
    required String id,
    required int remaining,
    DateTime? acquired,
    CoinSource source = CoinSource.purchase,
  }) =>
      CoinBatch(
        batchId: id,
        initialCoins: remaining,
        remainingCoins: remaining,
        source: source,
        acquiredDate: acquired ?? now.subtract(const Duration(days: 1)),
      );

  CoinBalance balance(List<CoinBatch> batches, {int totalCoins = 0}) =>
      CoinBalance(
        userId: 'u1',
        totalCoins: totalCoins,
        earnedCoins: 0,
        purchasedCoins: 0,
        giftedCoins: 0,
        spentCoins: 0,
        lastUpdated: now,
        coinBatches: batches,
      );

  group('CoinBalance.availableCoins', () {
    test('sums every batch remainder — no batch is withheld for age', () {
      final b = balance([
        batch(id: 'fresh', remaining: 100),
        batch(id: 'month', remaining: 50,
            acquired: now.subtract(const Duration(days: 30))),
        // Older than the removed 365-day expiry: must still count.
        batch(id: 'ancient', remaining: 999,
            acquired: now.subtract(const Duration(days: 800))),
      ]);
      expect(b.availableCoins, 1149);
    });

    test('falls back to totalCoins when there are no batches '
        '(Cloud Function bare increment)', () {
      expect(balance(const [], totalCoins: 320).availableCoins, 320);
    });

    test('unbatched coins in totalCoins above the batch sum are spendable', () {
      final b = balance([batch(id: 'b', remaining: 100)], totalCoins: 250);
      expect(b.availableCoins, 250);
    });

    test('batch sum wins when the document total lags behind', () {
      final b = balance([
        batch(id: 'a', remaining: 120),
        batch(id: 'b', remaining: 80),
      ], totalCoins: 150);
      expect(b.availableCoins, 200);
    });

    test('counts batches of every source', () {
      final b = balance([
        for (final s in CoinSource.values)
          batch(id: s.name, remaining: 10, source: s),
      ]);
      expect(b.availableCoins, 10 * CoinSource.values.length);
    });
  });

  group('CoinBalance.hasEnoughCoins', () {
    test('compares against availableCoins (old batches included)', () {
      final b = balance([
        batch(id: 'new', remaining: 40),
        batch(id: 'old', remaining: 1000,
            acquired: now.subtract(const Duration(days: 400))),
      ]);
      expect(b.hasEnoughCoins(1040), isTrue);
      expect(b.hasEnoughCoins(1041), isFalse);
    });

    test('uses totalCoins when no batch backs the balance', () {
      final b = balance(const [], totalCoins: 40);
      expect(b.hasEnoughCoins(40), isTrue);
      expect(b.hasEnoughCoins(41), isFalse);
    });

    test('an empty balance has zero available and cannot afford anything', () {
      final b = balance(const []);
      expect(b.availableCoins, 0);
      expect(b.hasEnoughCoins(0), isTrue);
      expect(b.hasEnoughCoins(1), isFalse);
    });
  });

  group('Equatable', () {
    test('batches with equal fields are equal', () {
      final at = DateTime(2026, 1, 1);
      expect(batch(id: 'x', remaining: 5, acquired: at),
          batch(id: 'x', remaining: 5, acquired: at));
      expect(batch(id: 'x', remaining: 5, acquired: at),
          isNot(batch(id: 'x', remaining: 6, acquired: at)));
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
