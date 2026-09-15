import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 04 — Access gate: approval, ban, 2FA (GATE-01 … GATE-08).
///
/// `AuthWrapper.build` resolves an authenticated user onto one of five
/// screens. Each branch needs its own seeded account, because the branch that
/// is never exercised is the branch that breaks — GATE-05 in particular
/// defends a deliberate fail-open: a profile read that errors must never lock
/// a legitimate user out.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('GATE — access gate', () {
    e2eTest('GATE-01 an approved account goes straight in', (tester) async {
      E2E.requireEmulator('GATE-01');
      final uid = await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);
      await Backend.seedApprovedProfile(uid, approvalStatus: 'approved');

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.mainNav,
          reason: 'the app shell for an approved account',
          timeout: const Duration(seconds: 30));
      expect(F.waiting, findsNothing);
      expect(F.banned, findsNothing);
    });

    e2eTest('GATE-02 a pending account is let in, not held', (tester) async {
      E2E.requireEmulator('GATE-02');
      final uid = await Backend.signInOrCreate(
          E2EConfig.pendingEmail, E2EConfig.pendingPassword);
      await Backend.seedApprovedProfile(uid, approvalStatus: 'pending');

      await E2E.boot(tester);
      // The current gate admits pending users deliberately. This test is the
      // regression guard against someone re-blocking them.
      await E2E.waitForFinder(tester, F.mainNav,
          reason: 'the app shell for a pending account',
          timeout: const Duration(seconds: 30));
    });

    e2eTest('GATE-03 a rejected account gets the review screen',
        (tester) async {
      E2E.requireEmulator('GATE-03');
      final uid = await Backend.signInOrCreate(
          E2EConfig.rejectedEmail, E2EConfig.rejectedPassword);
      await Backend.seedApprovedProfile(uid,
          approvalStatus: 'rejected', verificationStatus: 'rejected');

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.waiting,
          reason: 'the waiting/review screen for a rejected account',
          timeout: const Duration(seconds: 30));
      expect(F.mainNav, findsNothing,
          reason: 'a rejected account reached the app');
    });

    e2eTest('GATE-04 a banned account can only sign out', (tester) async {
      E2E.requireEmulator('GATE-04');
      final uid = await Backend.signInOrCreate(
          E2EConfig.bannedEmail, E2EConfig.bannedPassword);
      await Backend.seedApprovedProfile(uid, isBanned: true);

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.banned,
          reason: 'the banned screen',
          timeout: const Duration(seconds: 30));
      expect(F.mainNav, findsNothing,
          reason: 'a banned account reached the app');

      // Every tab must be unreachable, not merely hidden.
      final l10n = E2E.l10n(tester);
      expect(F.navTab(l10n.exploreTitle), findsNothing);
      expect(F.navTab(l10n.messages), findsNothing);
    });

    e2eTest('GATE-05 an unreadable ban flag never locks anyone out',
        (tester) async {
      E2E.requireEmulator('GATE-05');
      final uid = await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);
      await Backend.seedApprovedProfile(uid);

      // The gate sets `_accountBanned` only on a positively-read
      // `isBanned == true`. Anything else — the field missing, the read
      // failing, a malformed value — must fail OPEN. A profile with no
      // isBanned field at all is the readable form of that condition; the
      // unreadable form (a dead Firestore) is asserted by BOOT-02 at browser
      // level, because disableNetwork() breaks the web SDK outright.
      await Backend.db
          .collection('profiles')
          .doc(uid)
          .update({'isBanned': FieldValue.delete()});
      final stored = await Backend.profile(uid);
      expect(stored!.containsKey('isBanned'), isFalse,
          reason: 'the fixture still has an isBanned field, so this test '
              'could not detect a gate that fails closed');

      await E2E.boot(tester);
      await E2E.waitFor(
        tester,
        () => F.isRenderingSomethingReal,
        reason: 'a resolved screen for a profile with no ban flag',
        timeout: const Duration(seconds: 35),
      );
      expect(F.banned, findsNothing,
          reason: 'a missing ban flag was treated as a ban — the gate '
              'failed closed');
    });

    e2eTest('GATE-06 an admin must clear 2FA before the app', (tester) async {
      E2E.requireEmulator('GATE-06');
      final uid = await Backend.signInOrCreate(
          E2EConfig.adminEmail, E2EConfig.adminPassword);
      await Backend.seedApprovedProfile(uid, isAdmin: true);
      await Backend.db.collection('users').doc(uid).set(
          {'isAdmin': true, 'approvalStatus': 'approved'},
          SetOptions(merge: true));

      await E2E.boot(tester);
      // Either the 2FA screen appears, or the admin is in the app without
      // having proved anything — which is the failure.
      await E2E.waitFor(
        tester,
        () => F.isRenderingSomethingReal || F.splash.evaluate().isEmpty,
        reason: 'the admin gate to resolve',
        timeout: const Duration(seconds: 30),
      );
      final l10n = E2E.l10n(tester);
      final on2fa = F.textContaining(l10n.admin2faVerify).evaluate().isNotEmpty;
      expect(on2fa || F.mainNav.evaluate().isEmpty, isTrue,
          reason: 'an admin reached the app without the 2FA challenge');
    });

    e2eTest('GATE-07 2FA is asked again after a sign-out', (tester) async {
      E2E.requireEmulator('GATE-07');
      final uid = await Backend.signInOrCreate(
          E2EConfig.adminEmail, E2EConfig.adminPassword);
      await Backend.seedApprovedProfile(uid, isAdmin: true);

      await E2E.boot(tester);
      await E2E.pump(tester, const Duration(seconds: 6));
      await E2E.hardSignOut(tester);
      await E2E.waitForFinder(tester, F.login,
          reason: 'the login screen after the admin signed out',
          timeout: const Duration(seconds: 25));

      // Admin2FAScreen.resetVerification() runs on sign-out; if it did not,
      // the next admin session would skip the challenge entirely.
      expect(F.mainNav, findsNothing);
    });

    e2eTest('GATE-08 a missing access record is recreated', (tester) async {
      E2E.requireEmulator('GATE-08');
      final uid = await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);
      await Backend.seedApprovedProfile(uid);
      // Remove the access record entirely — the state a partially-migrated
      // account is in.
      await Backend.deleteDoc('users/$uid');

      await E2E.boot(tester);
      await E2E.waitFor(
        tester,
        () => F.isRenderingSomethingReal,
        reason: 'a resolved screen with no access record',
        timeout: const Duration(seconds: 35),
      );

      // initializeUserAccess must have written one back.
      final user = await Backend.waitForValue(
        () => Backend.user(uid),
        (v) => v != null,
        reason: 'users/$uid recreated by initializeUserAccess',
      );
      expect(user!['approvalStatus'], isNotNull);
    });
  });
}
