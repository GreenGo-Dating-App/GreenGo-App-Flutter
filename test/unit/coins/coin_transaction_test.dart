import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/domain/entities/coin_transaction.dart';

/// Master Test Plan — Coins / transaction model + feature pricing.
/// Pure tests for the signed display amount, reason wire round-trip, and the
/// static coin feature price table.
void main() {
  CoinTransaction tx({
    required CoinTransactionType type,
    int amount = 50,
    CoinTransactionReason reason = CoinTransactionReason.coinPurchase,
    Map<String, dynamic>? metadata,
  }) =>
      CoinTransaction(
        transactionId: 't1',
        userId: 'u1',
        type: type,
        amount: amount,
        balanceAfter: 100,
        reason: reason,
        createdAt: DateTime(2026, 7, 15),
        metadata: metadata,
      );

  group('displayAmount sign', () {
    test('credit is prefixed with +', () {
      expect(tx(type: CoinTransactionType.credit, amount: 25).displayAmount,
          '+25');
    });

    test('debit is prefixed with -', () {
      expect(tx(type: CoinTransactionType.debit, amount: 25).displayAmount,
          '-25');
    });
  });

  group('description delegates to the reason', () {
    test('coinPurchase description includes the amount', () {
      final t = tx(
          type: CoinTransactionType.credit,
          amount: 500,
          reason: CoinTransactionReason.coinPurchase);
      expect(t.description, contains('500'));
    });

    test('dailyLoginStreakReward uses the streak from metadata', () {
      final t = tx(
        type: CoinTransactionType.credit,
        amount: 10,
        reason: CoinTransactionReason.dailyLoginStreakReward,
        metadata: const {'streak': 7},
      );
      expect(t.description, contains('Day 7'));
    });
  });

  group('CoinTransactionReason wire mapping', () {
    test('fromString round-trips every reason', () {
      for (final r in CoinTransactionReason.values) {
        final wire = r.toString().split('.').last;
        expect(CoinTransactionReasonExtension.fromString(wire), r);
      }
    });

    test('unknown reason falls back to featurePurchase', () {
      expect(CoinTransactionReasonExtension.fromString('nope'),
          CoinTransactionReason.featurePurchase);
    });

    test('every reason has a non-empty displayName', () {
      for (final r in CoinTransactionReason.values) {
        expect(r.displayName, isNotEmpty);
      }
    });
  });

  group('CoinFeaturePrices.getPrice', () {
    test('resolves known features (incl. alias spellings)', () {
      expect(CoinFeaturePrices.getPrice('superlike'),
          CoinFeaturePrices.superLike);
      expect(CoinFeaturePrices.getPrice('super_like'),
          CoinFeaturePrices.superLike);
      expect(CoinFeaturePrices.getPrice('boost'), CoinFeaturePrices.boost);
      expect(CoinFeaturePrices.getPrice('traveler'),
          CoinFeaturePrices.traveler);
      expect(CoinFeaturePrices.getPrice('location_switch'),
          CoinFeaturePrices.traveler);
    });

    test('is case-insensitive', () {
      expect(CoinFeaturePrices.getPrice('BOOST'), CoinFeaturePrices.boost);
    });

    test('unknown feature costs 0', () {
      expect(CoinFeaturePrices.getPrice('teleport'), 0);
    });

    test('gift prices resolve', () {
      expect(CoinFeaturePrices.getPrice('gift_rose'),
          CoinFeaturePrices.giftRose);
      expect(CoinFeaturePrices.getPrice('gift_diamond'),
          CoinFeaturePrices.giftDiamond);
    });
  });
}
