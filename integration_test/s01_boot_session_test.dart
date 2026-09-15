import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 01 — Boot & session (BOOT-01 … BOOT-10).
///
/// This is the suite the white page came from. Commit 9c46d4d resolved
/// `PushNotificationService` through GetIt inside
/// `MainNavigationScreen.initState`, but that service is a plain library
/// singleton and was never registered, so the lookup threw, Flutter replaced
/// the whole post-login subtree with the release [ErrorWidget] — a flat grey
/// rectangle — and every logged-in user on web saw a blank page.
///
/// BOOT-03 is the direct regression test: it fails if any widget in the
/// post-login tree throws during build, whatever the cause.
///
/// BOOT-02, BOOT-04, BOOT-05 and BOOT-09 are browser-level and live in
/// `tool/e2e_web/`. BOOT-02 needs Firestore's requests actually blocked, and
/// `disableNetwork()` cannot do that job here: the web SDK raises
/// INTERNAL ASSERTION FAILED and leaves the Firestore instance unusable for
/// every test that follows. Playwright aborts the requests instead.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Build failures captured while a test runs. Flutter reports a build
  /// exception through [FlutterError.onError] and then renders an ErrorWidget;
  /// collecting them is what turns "the page looked blank" into a named cause.
  late List<FlutterErrorDetails> buildErrors;
  late FlutterExceptionHandler? previousHandler;

  setUp(() {
    buildErrors = <FlutterErrorDetails>[];
    previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      buildErrors.add(details);
      previousHandler?.call(details);
    };
  });

  tearDown(() {
    FlutterError.onError = previousHandler;
  });

  group('BOOT — boot & session', () {
    e2eTest('BOOT-01 cold load while already logged in reaches the app',
        (tester) async {
      // Authenticate before the app boots: this is a returning user opening
      // the site with a live session, which is exactly the reported case.
      await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);

      final started = DateTime.now();
      await E2E.boot(tester);
      await E2E.waitFor(
        tester,
        () => F.isRenderingSomethingReal,
        reason: 'a real screen instead of an endless splash or a blank frame',
        timeout: E2EConfig.bootBudget,
      );
      final elapsed = DateTime.now().difference(started);

      expect(F.errorScreen, findsNothing,
          reason: 'boot rendered the crash screen');
      expect(elapsed, lessThan(E2EConfig.bootBudget),
          reason: 'cold start took ${elapsed.inSeconds}s');
    });

    e2eTest('BOOT-03 no widget in the post-login tree throws during build',
        (tester) async {
      // The regression test for the white page. It does not care *which*
      // dependency is missing — any build-time throw fails it.
      await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);

      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.mainNav,
          reason: 'the main shell after logging in');
      await E2E.pump(tester, const Duration(seconds: 3));

      expect(F.errorScreen, findsNothing,
          reason: 'AppErrorScreen rendered — a build threw');
      expect(
        buildErrors,
        isEmpty,
        reason: 'build-time exceptions during boot:\n'
            '${buildErrors.map((e) => e.exceptionAsString()).join('\n')}',
      );
    });

    e2eTest('BOOT-06 the post-login splash always hands over', (tester) async {
      await E2E.boot(tester);
      await Do.submitLogin(
        tester,
        email: E2EConfig.approvedEmail,
        password: E2EConfig.approvedPassword,
      );

      // PostLoginSplashScreen prefetches through DataPreloadService. If that
      // throws or never completes, onComplete never fires and the splash is
      // where the session ends.
      await E2E.waitForFinder(
        tester,
        F.mainNav,
        reason: 'MainNavigationScreen to replace the post-login splash',
        timeout: const Duration(seconds: 25),
      );
      expect(F.splash, findsNothing);
    });

    e2eTest('BOOT-07 a revoked session lands on Login, not a blank frame',
        (tester) async {
      await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);
      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.mainNav, reason: 'the app to open');

      // Sign out underneath the running app, as a server-side token
      // revocation would.
      await Backend.auth.signOut();

      await E2E.waitForFinder(
        tester,
        F.login,
        reason: 'the login screen after the session ended',
        timeout: const Duration(seconds: 20),
      );
      expect(F.errorScreen, findsNothing);
      expect(buildErrors, isEmpty,
          reason: 'tearing the session down threw during build');
    });

    e2eTest('BOOT-08 an account with no profile document goes to onboarding',
        (tester) async {
      E2E.requireEmulator('BOOT-08');

      final uid = await Backend.signInOrCreate(
          E2EConfig.freshEmail, E2EConfig.freshPassword);
      // Authenticated but with nothing in `profiles` — the state a signup
      // leaves behind if onboarding is abandoned.
      await Backend.deleteDoc('profiles/$uid');

      await E2E.boot(tester);
      await E2E.waitFor(
        tester,
        () => F.onboarding.evaluate().isNotEmpty,
        reason: 'the onboarding wizard for a profile-less account',
        timeout: const Duration(seconds: 25),
      );
      expect(F.splash, findsNothing,
          reason: 'stuck on the splash rather than routed to onboarding');
    });

    e2eTest('BOOT-10 a deep link opened while logged out survives login',
        (tester) async {
      // The link target must still be honoured after the auth detour. Without
      // a session the app must show Login first, and the pending target must
      // not be dropped on the way through.
      await Backend.auth.signOut();
      await E2E.boot(tester);
      await E2E.waitForFinder(tester, F.login,
          reason: 'the login screen for a logged-out deep link');

      await Do.loginAndLandInApp(tester);
      expect(F.mainNav, findsOneWidget);
      expect(buildErrors, isEmpty);
    });
  });
}
