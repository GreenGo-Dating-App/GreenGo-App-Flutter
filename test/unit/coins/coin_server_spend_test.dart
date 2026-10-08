// Security P1-1 (audit C-03 / H-11 / H-12 / M-13): coins are spent and gifted
// through server callables only. These tests pin the client side of that
// contract: what the app sends (never a price), how refusals are surfaced,
// that client debits are refused, and that restore never acknowledges an
// unverified purchase.

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/user_error.dart';
import 'package:greengo_chat/features/coins/data/datasources/coin_remote_datasource.dart';
import 'package:greengo_chat/features/coins/data/repositories/coin_repository_impl.dart';
import 'package:greengo_chat/features/coins/domain/entities/coin_transaction.dart';
import 'package:greengo_chat/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<Object?> {}

class _MockIap extends Mock implements InAppPurchase {}

class _FakePurchase extends Fake implements PurchaseDetails {
  _FakePurchase(this.status);
  @override
  final PurchaseStatus status;
  @override
  String get productID => '1_month_silver';
  @override
  bool get pendingCompletePurchase => true;
}

class _FakeProduct extends Fake implements ProductDetails {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;
  late CoinRemoteDataSource ds;
  final calls = <String, Object?>{};

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(_FakePurchase(PurchaseStatus.purchased));
  });

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    calls.clear();
    ds = CoinRemoteDataSource(
      firestore: FakeFirebaseFirestore(),
      inAppPurchase: _MockIap(),
      functions: functions,
    );
  });

  void stubCallable(String name, Map<String, dynamic> response) {
    final result = _MockResult();
    when(() => result.data).thenReturn(response);
    when(() => functions.httpsCallable(name)).thenReturn(callable);
    when(() => callable.call<Object?>(any())).thenAnswer((inv) async {
      calls[name] = inv.positionalArguments.first;
      return result;
    });
  }

  void stubRefusal(String name, String code, String reason) {
    when(() => functions.httpsCallable(name)).thenReturn(callable);
    when(() => callable.call<Object?>(any())).thenThrow(FirebaseFunctionsException(
      code: code,
      message: '$reason: refused',
      details: {'reason': reason},
    ));
  }

  group('spendCoins', () {
    test('sends featureId + requestId, never a price', () async {
      stubCallable('spendCoins', {
        'featureId': 'boost',
        'charged': 50,
        'newBalance': 150,
        'transactionId': 't1',
        'effect': {'boostExpiry': 1700000000000},
      });
      final r = await ds.spendCoins(featureId: 'boost', relatedId: 'x', option: 6);
      final sent = calls['spendCoins']! as Map;
      expect(sent['featureId'], 'boost');
      expect(sent['relatedId'], 'x');
      expect(sent['option'], 6);
      expect((sent['requestId'] as String).length, greaterThanOrEqualTo(8));
      expect(sent.containsKey('cost'), isFalse);
      expect(sent.containsKey('price'), isFalse);
      expect(r.charged, 50);
      expect(r.newBalance, 150);
      expect(r.effectTime('boostExpiry'),
          DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('a refusal becomes CoinRefusalException with the reason code', () async {
      stubRefusal('spendCoins', 'failed-precondition', 'insufficient-coins');
      await expectLater(
        ds.spendCoins(featureId: 'superlike'),
        throwsA(isA<CoinRefusalException>()
            .having((e) => e.isInsufficientCoins, 'insufficient', isTrue)),
      );
    });

    test('repository purchaseFeature maps the receipt and keeps the effect', () async {
      stubCallable('spendCoins', {
        'featureId': 'incognito',
        'charged': 30,
        'newBalance': 70,
        'transactionId': 't2',
        'effect': {'incognitoExpiry': 1},
      });
      final repo = CoinRepositoryImpl(remoteDataSource: ds);
      final res = await repo.purchaseFeature(
          userId: 'u1', featureName: 'incognito', cost: 999);
      final txn = res.getOrElse(() => throw StateError('left'));
      expect(txn.amount, 30); // server price, not the client's 999
      expect(txn.balanceAfter, 70);
      expect(txn.reason, CoinTransactionReason.incognitoPurchase);
      expect((txn.metadata!['effect'] as Map)['incognitoExpiry'], 1);
    });

    test('repository failure text still carries the refusal reason', () async {
      stubRefusal('spendCoins', 'failed-precondition', 'insufficient-coins');
      final repo = CoinRepositoryImpl(remoteDataSource: ds);
      final res = await repo.purchaseFeature(
          userId: 'u1', featureName: 'boost', cost: 50);
      final failure = res.fold((f) => f, (_) => null)!;
      expect(CoinRefusalException.reasonIn(failure.message),
          CoinRefusalException.insufficientCoins);
      expect(classifyUserError(failure), UserErrorKind.insufficientCoins);
    });
  });

  group('gifts', () {
    test('Shop send uses giftCoins; hold / velocity refusals are typed', () async {
      stubCallable('giftCoins', {'giftId': 'g1', 'senderNewBalance': 10});
      final r = await ds.giftCoins(receiverId: 'bob', amount: 40);
      expect(r.senderNewBalance, 10);
      expect((calls['giftCoins']! as Map)['receiverId'], 'bob');

      stubRefusal('giftCoins', 'failed-precondition', 'gift-purchase-hold');
      Object? err;
      try {
        await ds.giftCoins(receiverId: 'bob', amount: 40);
      } catch (e) {
        err = e;
      }
      expect(classifyUserError(err), UserErrorKind.giftPurchaseHold);

      stubRefusal('giftCoins', 'resource-exhausted', 'gift-velocity-limit');
      err = null;
      try {
        await ds.giftCoins(receiverId: 'bob', amount: 40);
      } catch (e) {
        err = e;
      }
      expect(classifyUserError(err), UserErrorKind.giftVelocityLimit);
    });

    test('acceptGift goes through the callable', () async {
      stubCallable('acceptGift', {'success': true});
      await ds.acceptGift(giftId: 'g9', userId: 'bob');
      expect((calls['acceptGift']! as Map)['giftId'], 'g9');
    });
  });

  test('client-side debits are refused (only server spends)', () async {
    expect(
      () => ds.updateBalance(
        userId: 'u1',
        amount: 10,
        type: CoinTransactionType.debit,
        reason: CoinTransactionReason.superLikePurchase,
      ),
      throwsUnsupportedError,
    );
  });

  test('refundClawback ledger entries parse to their own reason', () {
    expect(CoinTransactionReasonExtension.fromString('refundClawback'),
        CoinTransactionReason.refundClawback);
  });

  test('M-13: restore never acknowledges; it routes to server verification', () async {
    final iap = _MockIap();
    final controller = StreamController<List<PurchaseDetails>>();
    when(() => iap.purchaseStream).thenAnswer((_) => controller.stream);
    when(() => iap.restorePurchases()).thenAnswer((_) async {});
    when(() => iap.queryProductDetails(any())).thenAnswer((_) async =>
        ProductDetailsResponse(productDetails: [_FakeProduct()], notFoundIDs: []));
    final verified = <PurchaseDetails>[];
    final sub = SubscriptionRemoteDataSource(
      firestore: FakeFirebaseFirestore(),
      inAppPurchase: iap,
      functions: _MockFunctions(),
      verifyAndFinish: (p) async => verified.add(p),
    );

    final future = sub.restorePurchases();
    await Future<void>.delayed(Duration.zero);
    final fresh = _FakePurchase(PurchaseStatus.purchased);
    controller.add([fresh]);
    final restored = await future;

    expect(restored, [fresh]);
    expect(verified, [fresh]);
    verifyNever(() => iap.completePurchase(any()));
    await controller.close();
  });
}
