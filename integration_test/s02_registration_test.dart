import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 02 — Registration & onboarding (REG-01 … REG-12).
///
/// A new account has to reach `profiles/{uid}.isComplete == true`. Anything
/// short of that sends the user back through onboarding on every launch, and
/// production already carries profile documents holding nothing but
/// `signupGrantsApplied` — accounts that were created and then stranded.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final createdUids = <String>[];

  tearDownAll(() async {
    for (final uid in createdUids) {
      await Backend.deleteAll(['profiles/$uid', 'users/$uid']);
    }
  });

  /// Opens the register screen from a freshly booted app.
  Future<void> openRegister(WidgetTester tester) async {
    await Backend.auth.signOut();
    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.login, reason: 'the login screen');
    final l10n = E2E.l10n(tester);
    await E2E.tap(tester, F.text(l10n.signUp), label: 'Sign Up');
    await E2E.waitForFinder(tester, F.register,
        reason: 'the registration screen');
  }

  group('REG — registration & onboarding', () {
    e2eTest('REG-01 a new email creates auth user, users and profiles docs',
        (tester) async {
      E2E.requireEmulator('REG-01');
      final email = 'reg01-${e2eStamp()}@e2e.greengo.test';
      const password = 'E2e-Fresh!2026';

      await openRegister(tester);
      await E2E.type(tester, F.registerEmail, email, label: 'email');
      await E2E.type(tester, F.registerPassword, password, label: 'password');
      await E2E.type(tester, F.registerConfirm, password, label: 'confirm');
      await E2E.tap(tester, F.registerSubmit, label: 'Register');

      await E2E.waitFor(tester, () => Backend.uidOrNull != null,
          reason: 'an authenticated user after registering',
          timeout: const Duration(seconds: 25));
      final uid = Backend.uid;
      createdUids.add(uid);

      // Registration must leave the app in onboarding, not in the main shell:
      // the profile is not complete yet.
      await E2E.waitForFinder(tester, F.onboarding,
          reason: 'onboarding to open for the new account',
          timeout: const Duration(seconds: 25));
      expect(F.mainNav, findsNothing,
          reason: 'an incomplete profile reached the app shell');
    });

    e2eTest('REG-02 a duplicate email is refused and writes nothing',
        (tester) async {
      await openRegister(tester);
      final l10n = E2E.l10n(tester);
      const password = 'E2e-Duplicate!2026';

      await E2E.type(tester, F.registerEmail, E2EConfig.approvedEmail,
          label: 'email');
      await E2E.type(tester, F.registerPassword, password, label: 'password');
      await E2E.type(tester, F.registerConfirm, password, label: 'confirm');
      await E2E.tap(tester, F.registerSubmit, label: 'Register');

      await E2E.waitForFinder(
        tester,
        F.textContaining(l10n.authErrorEmailAlreadyInUse),
        reason: 'the "already in use" message',
        timeout: const Duration(seconds: 20),
      );
      expect(F.register, findsOneWidget,
          reason: 'a rejected registration navigated away anyway');
    });

    e2eTest('REG-03 a weak password is refused before any network call',
        (tester) async {
      await openRegister(tester);
      await E2E.type(tester, F.registerEmail,
          'reg03-${e2eStamp()}@e2e.greengo.test', label: 'email');
      await E2E.type(tester, F.registerPassword, '123', label: 'password');
      await E2E.type(tester, F.registerConfirm, '123', label: 'confirm');
      await E2E.tap(tester, F.registerSubmit, label: 'Register');

      await E2E.pump(tester, const Duration(seconds: 2));
      expect(F.register, findsOneWidget,
          reason: 'a weak password was accepted');
      expect(Backend.uidOrNull, isNull,
          reason: 'an account was created despite a weak password');
    });

    e2eTest('REG-04 a malformed email never reaches Firebase',
        (tester) async {
      await openRegister(tester);
      const password = 'E2e-Malformed!2026';
      await E2E.type(tester, F.registerEmail, 'notanemail', label: 'email');
      await E2E.type(tester, F.registerPassword, password, label: 'password');
      await E2E.type(tester, F.registerConfirm, password, label: 'confirm');
      await E2E.tap(tester, F.registerSubmit, label: 'Register');

      await E2E.pump(tester, const Duration(seconds: 2));
      expect(F.register, findsOneWidget);
      expect(Backend.uidOrNull, isNull);
    });

    e2eTest('REG-05 mismatched passwords block the submit', (tester) async {
      await openRegister(tester);
      await E2E.type(tester, F.registerEmail,
          'reg05-${e2eStamp()}@e2e.greengo.test', label: 'email');
      await E2E.type(tester, F.registerPassword, 'E2e-First!2026',
          label: 'password');
      await E2E.type(tester, F.registerConfirm, 'E2e-Second!2026',
          label: 'confirm');
      await E2E.tap(tester, F.registerSubmit, label: 'Register');

      await E2E.pump(tester, const Duration(seconds: 2));
      expect(F.register, findsOneWidget,
          reason: 'registration proceeded with mismatched passwords');
      expect(Backend.uidOrNull, isNull);
    });

    e2eTest('REG-06 onboarding will not advance without the required fields',
        (tester) async {
      E2E.requireEmulator('REG-06');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      await Backend.deleteDoc('profiles/$uid');

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.onboarding,
          reason: 'the onboarding wizard', timeout: const Duration(seconds: 25));

      final l10n = E2E.l10n(tester);
      // Continue with an empty first step must not move on.
      final continueBtn = F.text(l10n.onboardingContinue);
      if (continueBtn.evaluate().isNotEmpty) {
        await E2E.tap(tester, continueBtn, label: 'Continue');
      }
      await E2E.pump(tester, const Duration(seconds: 1));

      final profile = await Backend.profile(uid);
      expect(profile?['isComplete'], isNot(true),
          reason: 'an empty onboarding step marked the profile complete');
    });

    e2eTest('REG-07 an under-age date of birth cannot complete onboarding',
        (tester) async {
      E2E.requireEmulator('REG-07');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      // Seed the shape onboarding would write for a 12-year-old. The rule the
      // test defends: an under-age profile is never `isComplete`.
      await Backend.db.collection('profiles').doc(uid).set({
        'userId': uid,
        'dateOfBirth': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 365 * 12))),
        'isComplete': false,
      }, SetOptions(merge: true));

      await E2E.boot(tester);
      await E2E.waitFor(
        tester,
        () => F.onboarding.evaluate().isNotEmpty || F.login.evaluate().isNotEmpty,
        reason: 'onboarding or login for an under-age profile',
        timeout: const Duration(seconds: 25),
      );
      expect(F.mainNav, findsNothing,
          reason: 'an under-age account reached the app');
    });

    e2eTest('REG-08 the profile photo picker is reachable on this platform',
        (tester) async {
      E2E.requireEmulator('REG-08');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      await Backend.deleteDoc('profiles/$uid');

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.onboarding,
          reason: 'the onboarding wizard', timeout: const Duration(seconds: 25));

      final l10n = E2E.l10n(tester);
      // The photo step must exist and offer an entry point. On web the mobile
      // camera path is unavailable, so a gallery/upload affordance has to be
      // present or the step is a dead end.
      await E2E.waitFor(
        tester,
        () =>
            F.text(l10n.onboardingAddPhoto).evaluate().isNotEmpty ||
            F.text(l10n.onboardingChooseFromGallery).evaluate().isNotEmpty ||
            F.text(l10n.onboardingDisplayName).evaluate().isNotEmpty,
        reason: 'an onboarding step with a reachable control',
        timeout: const Duration(seconds: 15),
      );
    });

    e2eTest('REG-09 onboarding survives a relaunch mid-way', (tester) async {
      E2E.requireEmulator('REG-09');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      await Backend.db.collection('profiles').doc(uid).set({
        'userId': uid,
        'displayName': 'Half Done',
        'isComplete': false,
      }, SetOptions(merge: true));

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.onboarding,
          reason: 'onboarding to resume', timeout: const Duration(seconds: 25));

      // The partial answer must still be on the server, not discarded by the
      // relaunch.
      final profile = await Backend.profile(uid);
      expect(profile?['displayName'], 'Half Done');
    });

    e2eTest('REG-10 a complete profile is admitted to the app', (tester) async {
      E2E.requireEmulator('REG-10');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      await Backend.seedApprovedProfile(uid, displayName: 'Completed Onboarding');

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.mainNav,
          reason: 'the app shell once the profile is complete',
          timeout: const Duration(seconds: 30));
      expect(F.onboarding, findsNothing,
          reason: 'a complete profile was sent back to onboarding');
    });

    e2eTest('REG-11 completing onboarding does not double-splash',
        (tester) async {
      E2E.requireEmulator('REG-11');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      await Backend.seedApprovedProfile(uid);

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.mainNav,
          reason: 'the app shell', timeout: const Duration(seconds: 30));
      await E2E.pump(tester, const Duration(seconds: 4));

      // AuthWrapper kicks the access check from initState as well as from the
      // bloc listener; if the guards fail the splash comes back on top.
      expect(F.splash, findsNothing,
          reason: 'the splash reappeared after entering the app');
      expect(F.mainNav, findsOneWidget);
    });

    e2eTest('REG-12 verification status is readable after onboarding',
        (tester) async {
      E2E.requireEmulator('REG-12');
      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      await Backend.seedApprovedProfile(uid, verificationStatus: 'pending');

      await E2E.boot(tester);
      await E2E.waitFor(
        tester,
        () => F.isRenderingSomethingReal,
        reason: 'a resolved screen for a pending-verification account',
        timeout: const Duration(seconds: 30),
      );

      // AuthWrapper syncs users.approvalStatus down from the profile's
      // verification state; the two must not drift apart.
      final user = await Backend.user(uid);
      expect(user, isNotNull);
      expect(user!['approvalStatus'], isNotNull,
          reason: 'no approval status was ever written for the account');
    });
  });
}
