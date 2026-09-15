import 'package:flutter_test/flutter_test.dart';

import 'e2e_config.dart';
import 'e2e_finders.dart';
import 'e2e_harness.dart';

/// User-level actions, composed from the primitives in [E2E].
///
/// A test should read like a description of what a person did, so the suites
/// call these rather than repeating tap/type sequences. Each one asserts that
/// it actually arrived where it was going.
class Do {
  const Do._();

  /// Fills the login form and submits. Does not assert the outcome — the
  /// caller decides whether it expected the app or an error.
  static Future<void> submitLogin(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await E2E.waitForFinder(tester, F.login,
        reason: 'the login screen to appear');
    await E2E.type(tester, F.loginEmail, email, label: 'email');
    await E2E.type(tester, F.loginPassword, password, label: 'password');
    await E2E.tap(tester, F.loginSubmit, label: 'Login');
  }

  /// Logs in and waits until the app is past every gate and rendering the
  /// main shell. The workhorse precondition for most suites.
  static Future<void> loginAndLandInApp(
    WidgetTester tester, {
    String? email,
    String? password,
  }) async {
    await submitLogin(
      tester,
      email: email ?? E2EConfig.approvedEmail,
      password: password ?? E2EConfig.approvedPassword,
    );
    await E2E.waitForFinder(
      tester,
      F.mainNav,
      reason: 'the main navigation shell after logging in',
      timeout: E2EConfig.screenTimeout,
    );
  }

  /// Moves to a bottom-navigation destination by its localized label.
  static Future<void> openTab(WidgetTester tester, String label) async {
    await E2E.tap(tester, F.navTab(label), label: label);
    await E2E.pump(tester, const Duration(seconds: 1));
  }

  static Future<void> openExplore(WidgetTester tester) =>
      openTab(tester, E2E.l10n(tester).exploreTitle);

  static Future<void> openEvents(WidgetTester tester) =>
      openTab(tester, E2E.l10n(tester).eventsTitle);

  static Future<void> openCommunities(WidgetTester tester) =>
      openTab(tester, E2E.l10n(tester).communityTabTitle);

  static Future<void> openMessages(WidgetTester tester) =>
      openTab(tester, E2E.l10n(tester).messages);

  static Future<void> openProfile(WidgetTester tester) =>
      openTab(tester, E2E.l10n(tester).profile);

  /// Dismisses whatever one-off gate the app puts in front of a fresh session
  /// (community guidelines, notification pre-prompt, update notice) so a test
  /// about chat is not derailed by an unrelated modal. Returns how many it
  /// cleared, which a test may assert on when the gate *is* the subject.
  static Future<int> dismissInterstitials(WidgetTester tester) async {
    final l10n = E2E.l10n(tester);
    var cleared = 0;
    final candidates = <String>[
      l10n.notificationDialogNotNow,
      l10n.guidelinesAccept,
    ];
    for (var round = 0; round < 4; round++) {
      var acted = false;
      for (final label in candidates) {
        final f = F.text(label);
        if (f.evaluate().isNotEmpty) {
          await E2E.tap(tester, f, label: label);
          cleared++;
          acted = true;
        }
      }
      if (!acted) break;
    }
    return cleared;
  }
}
