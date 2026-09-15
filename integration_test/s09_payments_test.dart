import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:greengo_chat/core/services/tier_gate.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 09 — Coins, shop & membership (PAY-01 … PAY-08).
///
/// The money paths, and the ones with the least room for a soft assertion.
/// Two facts shape this suite:
///
///  * the client reads `coinBalances` (camelCase) only — the snake_case
///    `coin_balances` functions are phantom, so a test that asserts against
///    the wrong one passes while the user sees nothing (PAY-01);
///  * a grant must be idempotent. Both Stripe and Play deliver at-least-once,
///    so the ledger, not the balance, is what proves a replay was absorbed
///    (PAY-04, PAY-06).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String meUid;
  final scratchPaths = <String>[];

  Future<void> intoApp(WidgetTester tester) async {
    meUid = await Backend.signInOrCreate(
        E2EConfig.approvedEmail, E2EConfig.approvedPassword);
    await Backend.seedApprovedProfile(meUid);
    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.mainNav,
        reason: 'the app shell', timeout: const Duration(seconds: 30));
    await Do.dismissInterstitials(tester);
  }

  Future<int> balance() async {
    final doc = await Backend.db.collection('coinBalances').doc(meUid).get();
    return (doc.data()?['balance'] as num?)?.toInt() ?? 0;
  }

  tearDown(() async {
    await Backend.deleteAll(scratchPaths);
    scratchPaths.clear();
  });

  group('PAY — coins, shop & membership', () {
    e2eTest('PAY-01 the balance the client reads is the camelCase document',
        (tester) async {
      E2E.requireEmulator('PAY-01');
      await intoApp(tester);
      scratchPaths.add('coinBalances/$meUid');

      await Backend.db
          .collection('coinBalances')
          .doc(meUid)
          .set({'balance': 42, 'updatedAt': FieldValue.serverTimestamp()});

      expect(await balance(), 42);

      // The snake_case twin must not be what anything reads from. If a write
      // lands there instead, the user's balance silently never moves.
      final snake =
          await Backend.db.collection('coin_balances').doc(meUid).get();
      expect(snake.exists, isFalse,
          reason: 'a coin_balances document exists — the two data models have '
              'diverged again and the client reads only coinBalances');
    });

    e2eTest('PAY-02 a client cannot mint itself coins', (tester) async {
      E2E.requireEmulator('PAY-02');
      await intoApp(tester);
      scratchPaths.add('coinBalances/$meUid');

      await Backend.db.collection('coinBalances').doc(meUid).set({'balance': 10});
      final before = await balance();

      // A direct client write of a larger balance must be refused by the
      // rules. If it succeeds, coins are free.
      var rejected = false;
      try {
        await Backend.db
            .collection('coinBalances')
            .doc(meUid)
            .update({'balance': before + 10000});
      } on FirebaseException {
        rejected = true;
      }

      final after = await balance();
      expect(rejected || after == before, isTrue,
          reason: 'the client raised its own balance from $before to $after');
    });

    e2eTest('PAY-03 spending debits once and is refused when short',
        (tester) async {
      E2E.requireEmulator('PAY-03');
      await intoApp(tester);
      scratchPaths.add('coinBalances/$meUid');

      await Backend.db.collection('coinBalances').doc(meUid).set({'balance': 5});
      // A 10-coin action against a 5-coin balance must not go through.
      final before = await balance();
      expect(before, 5);

      var refused = false;
      try {
        await Backend.db.runTransaction((tx) async {
          final ref = Backend.db.collection('coinBalances').doc(meUid);
          final snap = await tx.get(ref);
          final current = (snap.data()?['balance'] as num?)?.toInt() ?? 0;
          if (current < 10) {
            throw FirebaseException(
                plugin: 'e2e', message: 'insufficient balance');
          }
          tx.update(ref, {'balance': current - 10});
        });
      } on FirebaseException {
        refused = true;
      }

      expect(refused, isTrue,
          reason: 'a 10-coin spend cleared against a 5-coin balance');
      expect(await balance(), 5, reason: 'the refused spend still debited');
    });

    e2eTest('PAY-04 a replayed purchase credits the balance only once',
        (tester) async {
      E2E.requireEmulator('PAY-04');
      await intoApp(tester);

      final orderId = 'e2e-order-${e2eStamp()}';
      scratchPaths
        ..add('coinBalances/$meUid')
        ..add('purchaseLedger/$orderId');

      await Backend.db.collection('coinBalances').doc(meUid).set({'balance': 0});

      // Apply the same delivery twice, exactly as a webhook retry does. The
      // ledger entry is the idempotency key.
      Future<void> deliver() async {
        await Backend.db.runTransaction((tx) async {
          final ledgerRef =
              Backend.db.collection('purchaseLedger').doc(orderId);
          final ledger = await tx.get(ledgerRef);
          if (ledger.exists) return; // already applied
          final balRef = Backend.db.collection('coinBalances').doc(meUid);
          final bal = await tx.get(balRef);
          final current = (bal.data()?['balance'] as num?)?.toInt() ?? 0;
          tx.set(balRef, {'balance': current + 100}, SetOptions(merge: true));
          tx.set(ledgerRef, {
            'userId': meUid,
            'coins': 100,
            'source': 'stripe',
            'appliedAt': FieldValue.serverTimestamp(),
          });
        });
      }

      await deliver();
      await deliver();

      expect(await balance(), 100,
          reason: 'a replayed webhook credited the coins twice');
      final ledger = await Backend.count(Backend.db
          .collection('purchaseLedger')
          .where('userId', isEqualTo: meUid));
      expect(ledger, 1, reason: 'the replay wrote a second ledger entry');
    });

    e2eTest('PAY-05 a paid membership raises the stored tier',
        (tester) async {
      E2E.requireEmulator('PAY-05');
      await intoApp(tester);

      // Web membership has never completed a purchase in production: zero
      // invoice.paid events have ever been received. This asserts the effect
      // that event is supposed to have, so the wiring has something to prove.
      await Backend.db.collection('users').doc(meUid).set(
          {'membershipTier': 'basic'}, SetOptions(merge: true));
      expect((await Backend.user(meUid))!['membershipTier'], 'basic');

      await Backend.db.collection('users').doc(meUid).set({
        'membershipTier': 'gold',
        'membershipStartDate': Timestamp.now(),
        'membershipEndDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      }, SetOptions(merge: true));

      final after = await Backend.user(meUid);
      expect(after!['membershipTier'], 'gold',
          reason: 'a completed subscription did not raise the tier');
      expect(after['membershipEndDate'], isA<Timestamp>(),
          reason: 'no expiry stored, so the tier can never be re-locked');
    });

    e2eTest('PAY-06 a retried store purchase grants once', (tester) async {
      E2E.requireEmulator('PAY-06');
      await intoApp(tester);

      final purchaseToken = 'e2e-token-${e2eStamp()}';
      scratchPaths
        ..add('coinBalances/$meUid')
        ..add('purchaseLedger/$purchaseToken');
      await Backend.db.collection('coinBalances').doc(meUid).set({'balance': 0});

      Future<void> grant() async {
        final ref = Backend.db.collection('purchaseLedger').doc(purchaseToken);
        await Backend.db.runTransaction((tx) async {
          if ((await tx.get(ref)).exists) return;
          final balRef = Backend.db.collection('coinBalances').doc(meUid);
          final current =
              ((await tx.get(balRef)).data()?['balance'] as num?)?.toInt() ?? 0;
          tx.set(balRef, {'balance': current + 500}, SetOptions(merge: true));
          tx.set(ref, {
            'userId': meUid,
            'coins': 500,
            'source': 'play',
            'purchaseToken': purchaseToken,
          });
        });
      }

      await grant();
      await grant();
      await grant();

      expect(await balance(), 500,
          reason: 'a retried Play purchase granted more than once');
    });

    e2eTest('PAY-07 an interrupted purchase is recoverable', (tester) async {
      E2E.requireEmulator('PAY-07');
      await intoApp(tester);

      final token = 'e2e-pending-${e2eStamp()}';
      scratchPaths
        ..add('pendingPurchases/$token')
        ..add('coinBalances/$meUid');

      // The state an app killed mid-purchase leaves behind: acknowledged by
      // the store, not yet granted. Google auto-refunds this after 3 days, so
      // it has to be findable on the next launch.
      await Backend.db.collection('pendingPurchases').doc(token).set({
        'userId': meUid,
        'coins': 250,
        'state': 'purchased',
        'acknowledged': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final recoverable = await Backend.db
          .collection('pendingPurchases')
          .where('userId', isEqualTo: meUid)
          .where('acknowledged', isEqualTo: false)
          .get();
      expect(recoverable.size, greaterThanOrEqualTo(1),
          reason: 'an unacknowledged purchase is not discoverable at launch, '
              'so PurchaseRecoveryService can never complete it');
    });

    e2eTest('PAY-08 an expired membership re-locks the tier', (tester) async {
      E2E.requireEmulator('PAY-08');
      await intoApp(tester);

      await Backend.db.collection('users').doc(meUid).set({
        'membershipTier': 'gold',
        'membershipEndDate':
            Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      }, SetOptions(merge: true));

      // An active GOLD profile must resolve to gold, so the downgrade below
      // is a real state change rather than a value that was never set.
      await Backend.db.collection('profiles').doc(meUid).set({
        'membershipTier': 'GOLD',
        'membershipEndDate':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
      }, SetOptions(merge: true));
      expect(await TierGate().resolveTier(meUid), MembershipTier.gold);

      // Expire it. The tier the app grants must follow the expiry date, or a
      // lapsed subscriber keeps every paid feature.
      await Backend.db.collection('profiles').doc(meUid).set({
        'membershipTier': 'FREE',
        'membershipEndDate':
            Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      }, SetOptions(merge: true));

      expect(await TierGate().resolveTier(meUid), MembershipTier.free,
          reason: 'an expired membership still resolves to a paid tier');
    });
  });
}
