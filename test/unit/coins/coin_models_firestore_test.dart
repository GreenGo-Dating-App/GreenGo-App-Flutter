import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/coins/data/models/coin_balance_model.dart';
import 'package:greengo_chat/features/coins/data/models/coin_transaction_model.dart';
import 'package:greengo_chat/features/coins/domain/entities/coin_balance.dart';
import 'package:greengo_chat/features/coins/domain/entities/coin_transaction.dart';

/// Master Test Plan — Coins / Firestore serialization round-trips.
/// Writes each model with `toFirestore()` and reads it back through
/// `fromFirestore()` over a fake Firestore, guarding the wire codec.
void main() {
  final now = DateTime(2026, 7, 15, 9, 30);

  group('CoinBalanceModel round-trip', () {
    test('toFirestore -> fromFirestore preserves scalars and a batch',
        () async {
      final db = FakeFirebaseFirestore();
      final model = CoinBalanceModel(
        userId: 'u1',
        totalCoins: 500,
        earnedCoins: 100,
        purchasedCoins: 400,
        giftedCoins: 0,
        spentCoins: 25,
        lastUpdated: now,
        coinBatches: [
          CoinBatch(
            batchId: 'b1',
            initialCoins: 400,
            remainingCoins: 375,
            source: CoinSource.purchase,
            acquiredDate: now,
            expirationDate: now.add(const Duration(days: 365)),
          ),
        ],
      );

      await db.collection('balances').doc('u1').set(model.toFirestore());
      final doc = await db.collection('balances').doc('u1').get();
      final read = CoinBalanceModel.fromFirestore(doc);

      expect(read.userId, 'u1');
      expect(read.totalCoins, 500);
      expect(read.purchasedCoins, 400);
      expect(read.spentCoins, 25);
      expect(read.lastUpdated, now);
      expect(read.coinBatches.length, 1);
      expect(read.coinBatches.single.batchId, 'b1');
      expect(read.coinBatches.single.remainingCoins, 375);
      expect(read.coinBatches.single.source, CoinSource.purchase);
    });

    test('empty() factory produces a zeroed balance', () {
      final b = CoinBalanceModel.empty('u9');
      expect(b.userId, 'u9');
      expect(b.totalCoins, 0);
      expect(b.coinBatches, isEmpty);
    });
  });

  group('CoinTransactionModel round-trip', () {
    test('uses the doc id as transactionId and preserves fields', () async {
      final db = FakeFirebaseFirestore();
      final model = CoinTransactionModel(
        transactionId: 'ignored-on-write',
        userId: 'u1',
        type: CoinTransactionType.debit,
        amount: 50,
        balanceAfter: 450,
        reason: CoinTransactionReason.directMessagePurchase,
        createdAt: now,
        relatedUserId: 'u2',
        metadata: const {'feature': 'direct_message'},
      );

      final ref =
          await db.collection('transactions').add(model.toFirestore());
      final doc = await ref.get();
      final read = CoinTransactionModel.fromFirestore(doc);

      expect(read.transactionId, ref.id);
      expect(read.userId, 'u1');
      expect(read.type, CoinTransactionType.debit);
      expect(read.amount, 50);
      expect(read.balanceAfter, 450);
      expect(read.reason, CoinTransactionReason.directMessagePurchase);
      expect(read.relatedUserId, 'u2');
      expect(read.metadata?['feature'], 'direct_message');
      expect(read.createdAt, now);
    });

    test('type is serialized as its lowercase enum name', () async {
      final db = FakeFirebaseFirestore();
      final model = CoinTransactionModel(
        transactionId: 't',
        userId: 'u1',
        type: CoinTransactionType.credit,
        amount: 10,
        balanceAfter: 10,
        reason: CoinTransactionReason.referralBonus,
        createdAt: now,
      );
      final ref =
          await db.collection('transactions').add(model.toFirestore());
      final raw = (await ref.get()).data() as Map<String, dynamic>;
      expect(raw['type'], 'credit');
      expect(raw['reason'], 'referralBonus');
    });
  });
}
