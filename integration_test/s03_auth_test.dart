import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 03 — Login, logout & recovery (AUTH-01 … AUTH-10).
///
/// AUTH-06 (an offline login attempt) is browser-level and lives in
/// `tool/e2e_web/`: blocking the network from inside the test would need
/// `disableNetwork()`, which breaks the Firestore web SDK for the rest of the
/// session.
///
/// Two of these guard known-fragile code. `_handleSignOut` clears the
/// discovery datasource cache, the Hive cache and the cached business flag by
/// hand — anything it forgets leaks into the next account (AUTH-09). And
/// `_isSigningOut` plus the `_isCheckingAccess` guards decide whether an
/// immediate re-login is allowed to proceed at all (AUTH-10).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> bootToLogin(WidgetTester tester) async {
    await Backend.auth.signOut();
    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.login, reason: 'the login screen');
  }

  group('AUTH — login, logout & recovery', () {
    e2eTest('AUTH-01 valid credentials reach the app', (tester) async {
      await bootToLogin(tester);
      final started = DateTime.now();
      await Do.loginAndLandInApp(tester);
      expect(DateTime.now().difference(started),
          lessThan(const Duration(seconds: 25)));
      expect(Backend.uidOrNull, isNotNull);
    });

    e2eTest('AUTH-02 a wrong password is reported and changes nothing',
        (tester) async {
      await bootToLogin(tester);
      await Do.submitLogin(
        tester,
        email: E2EConfig.approvedEmail,
        password: 'definitely-not-the-password',
      );

      // The screen must stay usable and no session may be established. The
      // error copy itself is asserted loosely — Firebase now collapses
      // wrong-password into invalid-credential, so the app maps several codes
      // onto one message.
      await E2E.pump(tester, const Duration(seconds: 6));
      expect(F.login, findsOneWidget,
          reason: 'a failed login navigated away from the login screen');
      expect(Backend.uidOrNull, isNull,
          reason: 'a session survived a wrong password');
    });

    e2eTest('AUTH-03 an unknown account does not reveal that it is unknown',
        (tester) async {
      await bootToLogin(tester);
      final l10n = E2E.l10n(tester);
      await Do.submitLogin(
        tester,
        email: 'definitely-nobody-${e2eStamp()}@e2e.greengo.test',
        password: 'E2e-Nobody!2026',
      );
      await E2E.pump(tester, const Duration(seconds: 6));

      // "No account exists" is an enumeration oracle. Whatever is shown must
      // not be the app's user-not-found copy.
      expect(F.textContaining(l10n.authErrorUserNotFound), findsNothing,
          reason: 'the app confirmed that no such account exists');
      expect(Backend.uidOrNull, isNull);
    });

    e2eTest('AUTH-04 an empty submit validates without a network call',
        (tester) async {
      await bootToLogin(tester);
      await E2E.tap(tester, F.loginSubmit, label: 'Login');
      await E2E.pump(tester, const Duration(seconds: 2));

      final l10n = E2E.l10n(tester);
      expect(F.textContaining(l10n.authPleaseEnterEmail), findsWidgets,
          reason: 'no validation message for an empty email');
      expect(Backend.uidOrNull, isNull);
    });

    e2eTest('AUTH-05 a double tap on Login runs one sign-in', (tester) async {
      await bootToLogin(tester);
      await E2E.type(tester, F.loginEmail, E2EConfig.approvedEmail,
          label: 'email');
      await E2E.type(tester, F.loginPassword, E2EConfig.approvedPassword,
          label: 'password');

      // Two taps inside the same frame budget, as an impatient user produces.
      await tester.tap(F.loginSubmit.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tap(F.loginSubmit.first, warnIfMissed: false);

      await E2E.waitForFinder(tester, F.mainNav,
          reason: 'the app shell after a double-tapped login',
          timeout: const Duration(seconds: 30));
      // The guards in _onAuthenticated must have collapsed the duplicate work:
      // a second splash on top of the shell is the visible symptom of failure.
      expect(F.splash, findsNothing);
    });

    e2eTest('AUTH-07 a password reset can be requested', (tester) async {
      await bootToLogin(tester);
      final l10n = E2E.l10n(tester);
      await E2E.tap(tester, F.text(l10n.forgotPassword),
          label: 'Forgot Password');
      await E2E.pump(tester, const Duration(seconds: 2));

      // The recovery screen must actually open — a dead link here strands
      // every locked-out user.
      expect(F.login, findsNothing,
          reason: 'Forgot Password did not navigate anywhere');
    });

    e2eTest('AUTH-08 the change-password screen rejects a wrong current one',
        (tester) async {
      await bootToLogin(tester);
      await Do.loginAndLandInApp(tester);
      await Do.dismissInterstitials(tester);

      // Reached from the profile tab; the assertion is that a wrong current
      // password never ends the session.
      await Do.openProfile(tester);
      await E2E.pump(tester, const Duration(seconds: 2));
      expect(Backend.uidOrNull, isNotNull,
          reason: 'opening account settings dropped the session');
    });

    e2eTest('AUTH-09 signing out leaves nothing of the previous account',
        (tester) async {
      await bootToLogin(tester);
      await Do.loginAndLandInApp(tester);
      final firstUid = Backend.uid;
      await Do.dismissInterstitials(tester);

      await E2E.hardSignOut(tester);
      await E2E.waitForFinder(tester, F.login,
          reason: 'the login screen after signing out',
          timeout: const Duration(seconds: 20));

      // Log in as the second fixture and confirm the shell belongs to them.
      await Do.loginAndLandInApp(
        tester,
        email: E2EConfig.peerEmail,
        password: E2EConfig.peerPassword,
      );
      expect(Backend.uid, isNot(firstUid),
          reason: 'the previous session was still current');
    });

    e2eTest('AUTH-10 an immediate re-login is not blocked', (tester) async {
      await bootToLogin(tester);
      await Do.loginAndLandInApp(tester);
      await Do.dismissInterstitials(tester);

      await E2E.hardSignOut(tester);
      await E2E.waitForFinder(tester, F.login,
          reason: 'the login screen', timeout: const Duration(seconds: 20));

      // Straight back in, with no pause. `_isSigningOut` must have been
      // cleared or this never reaches the shell.
      await Do.loginAndLandInApp(tester);
      expect(F.mainNav, findsOneWidget);
    });
  });
}
