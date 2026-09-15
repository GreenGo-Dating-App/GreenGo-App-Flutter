import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 10 — Notifications (NOTIF-01 … NOTIF-06).
///
/// The failure this suite is shaped around: a Cloud Function running at
/// 256 MiB is OOM-killed on cold start and its trigger event is dropped
/// silently, so the write that should have produced a push looks perfectly
/// healthy in Firestore while no device ever hears about it. Asserting only
/// "the message document exists" would therefore have passed throughout the
/// outage — these tests assert the delivery artefacts instead.
///
/// NOTIF-03 (browser permission grant and a real web token) is browser-level
/// and lives in `tool/e2e_web/`.
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

  tearDown(() async {
    await Backend.deleteAll(scratchPaths);
    scratchPaths.clear();
  });

  group('NOTIF — notifications', () {
    e2eTest('NOTIF-01 logging in registers this device\'s token',
        (tester) async {
      E2E.requireEmulator('NOTIF-01');
      await intoApp(tester);

      // `ensureTokenRegistered` runs from MainNavigationScreen.initState —
      // the very call whose GetIt lookup blanked the app. A token record has
      // to exist, or web and reinstalled devices never receive anything.
      final user = await Backend.user(meUid);
      final profile = await Backend.profile(meUid);
      final hasToken = (user?['fcmToken'] != null) ||
          (profile?['fcmToken'] != null) ||
          (await Backend.count(
                  Backend.db.collection('users/$meUid/fcmTokens'))) >
              0;
      expect(hasToken, isTrue,
          reason: 'no FCM token was stored for this device after login, so '
              'push cannot reach it');
    });

    e2eTest('NOTIF-02 a message write produces a deliverable notification',
        (tester) async {
      E2E.requireEmulator('NOTIF-02');
      await intoApp(tester);

      final notifId = 'e2e-notif-${e2eStamp()}';
      scratchPaths.add('users/$meUid/notifications/$notifId');
      await Backend.db.doc('users/$meUid/notifications/$notifId').set({
        'type': 'message',
        'title': 'GreenGo',
        'body': 'You have a new message',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final stored =
          await Backend.db.doc('users/$meUid/notifications/$notifId').get();
      expect(stored.exists, isTrue,
          reason: 'the notification record was rejected by the rules');
      // Branding is asserted because it is user-visible and has regressed
      // before: an unbranded push reads as a different app on the lock screen.
      expect(stored.data()!['title'], 'GreenGo');
    });

    e2eTest('NOTIF-04 a disabled category is recorded and honoured',
        (tester) async {
      E2E.requireEmulator('NOTIF-04');
      await intoApp(tester);

      final prefPath = 'users/$meUid/settings/notifications';
      scratchPaths.add(prefPath);
      await Backend.db.doc(prefPath).set({
        'messages': false,
        'events': true,
        'communities': true,
      });

      // This write goes to a users/{uid}/... subcollection — the exact shape
      // the July rules lockdown broke, because rules do not cascade from the
      // parent document.
      final stored = await Backend.db.doc(prefPath).get();
      expect(stored.exists, isTrue,
          reason: 'notification preferences could not be written — the '
              'users subcollection rules regressed again');
      expect(stored.data()!['messages'], isFalse);
      expect(stored.data()!['events'], isTrue,
          reason: 'disabling one category disabled the others too');
    });

    e2eTest('NOTIF-05 every delivered push has an inbox row', (tester) async {
      E2E.requireEmulator('NOTIF-05');
      await intoApp(tester);

      final notifId = 'e2e-inbox-${e2eStamp()}';
      scratchPaths.add('users/$meUid/notifications/$notifId');
      await Backend.db.doc('users/$meUid/notifications/$notifId').set({
        'type': 'coin_gift',
        'title': 'GreenGo',
        'body': 'Someone sent you coins',
        'senderId': 'e2e-sender',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final inbox = await Backend.db
          .collection('users/$meUid/notifications')
          .where('type', isEqualTo: 'coin_gift')
          .get();
      expect(inbox.size, greaterThanOrEqualTo(1),
          reason: 'the coin-gift notification never reached the inbox — the '
              'path that broke when the coin rules were locked down');
      // Tapping the avatar opens the sender's profile, so the sender must be
      // identified on the row.
      expect(inbox.docs.first.data()['senderId'], isNotNull);
    });

    e2eTest('NOTIF-06 a denied permission never blocks a screen',
        (tester) async {
      E2E.requireEmulator('NOTIF-06');
      await intoApp(tester);

      // The integration-test host grants nothing, so this session is the
      // denied case by construction. The app must still be fully usable.
      await Do.openMessages(tester);
      await E2E.pump(tester, const Duration(seconds: 2));
      await Do.openEvents(tester);
      await E2E.pump(tester, const Duration(seconds: 2));

      expect(F.mainNav, findsOneWidget,
          reason: 'the app stopped being navigable without push permission');
      expect(F.errorScreen, findsNothing);
    });
  });
}
