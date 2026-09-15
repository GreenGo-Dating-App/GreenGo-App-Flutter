import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/e2e_keys.dart';
import 'package:greengo_chat/core/widgets/app_error_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/login_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/register_screen.dart';
import 'package:greengo_chat/features/authentication/presentation/screens/waiting_screen.dart';
import 'package:greengo_chat/features/main/presentation/screens/main_navigation_screen.dart';
import 'package:greengo_chat/features/profile/presentation/screens/onboarding_screen.dart';
import 'package:greengo_chat/main.dart' as app;

/// Screen- and control-level finders.
///
/// Two location strategies, in order of preference:
///  1. a [E2EKeys] key, for controls the suites drive constantly;
///  2. the screen's own widget type, which is stable regardless of layout.
///
/// Text is only ever matched against [AppLocalizations] values read from the
/// running app, never against an English literal typed into a test.
class F {
  const F._();

  // --- Screens --------------------------------------------------------------
  static final login = find.byType(LoginScreen);
  static final register = find.byType(RegisterScreen);
  static final splash = find.byType(app.SplashScreen);
  static final banned = find.byType(app.BannedScreen);
  static final waiting = find.byType(WaitingScreen);
  static final onboarding = find.byType(OnboardingScreen);
  static final mainNav = find.byType(MainNavigationScreen);
  static final errorScreen = find.byType(AppErrorScreen);

  /// True when the app is showing a real, usable screen rather than a splash,
  /// a crash screen, or nothing at all. This is the predicate BOOT-01 asserts.
  static bool get isRenderingSomethingReal =>
      login.evaluate().isNotEmpty ||
      mainNav.evaluate().isNotEmpty ||
      onboarding.evaluate().isNotEmpty ||
      waiting.evaluate().isNotEmpty ||
      banned.evaluate().isNotEmpty;

  /// Names whatever screen is currently mounted.
  ///
  /// "Timed out waiting for the main shell" says nothing about what went
  /// wrong; "...— currently showing: SplashScreen" says the gate never
  /// resolved, and "...— currently showing: AppErrorScreen" says something
  /// threw. Every timeout message carries this.
  static String describeCurrentScreen() {
    final showing = <String>[
      if (login.evaluate().isNotEmpty) 'LoginScreen',
      if (register.evaluate().isNotEmpty) 'RegisterScreen',
      if (splash.evaluate().isNotEmpty) 'SplashScreen',
      if (banned.evaluate().isNotEmpty) 'BannedScreen',
      if (waiting.evaluate().isNotEmpty) 'WaitingScreen',
      if (onboarding.evaluate().isNotEmpty) 'OnboardingScreen',
      if (mainNav.evaluate().isNotEmpty) 'MainNavigationScreen',
      if (errorScreen.evaluate().isNotEmpty) 'AppErrorScreen',
    ];
    if (showing.isEmpty) {
      // Nothing from the known list. Name whatever *is* mounted rather than
      // reporting a shrug: any widget whose type ends in "Screen" is one of
      // the app's own pages, so this identifies screens the suites have never
      // needed a finder for (the post-login splash, maintenance, 2FA).
      final found = <String>{};
      for (final element in find
          .byWidgetPredicate(
              (w) => w.runtimeType.toString().endsWith('Screen'))
          .evaluate()) {
        found.add(element.widget.runtimeType.toString());
      }
      if (found.isNotEmpty) return found.join(' + ');
      final scaffolds = find.byType(Scaffold).evaluate().length;
      return 'no screen widget at all ($scaffolds Scaffolds mounted)';
    }
    return showing.join(' + ');
  }

  // --- Auth controls --------------------------------------------------------
  static final loginEmail = find.byKey(E2EKeys.loginEmail);
  static final loginPassword = find.byKey(E2EKeys.loginPassword);
  static final loginSubmit = find.byKey(E2EKeys.loginSubmit);

  static final registerEmail = find.byKey(E2EKeys.registerEmail);
  static final registerPassword = find.byKey(E2EKeys.registerPassword);
  static final registerConfirm = find.byKey(E2EKeys.registerConfirmPassword);
  static final registerSubmit = find.byKey(E2EKeys.registerSubmit);

  // --- Generic controls -----------------------------------------------------

  /// A visible text, matched exactly. Pass the value from `E2E.l10n(tester)`.
  static Finder text(String value) => find.text(value);

  /// A text that merely contains [fragment] — for messages the app builds by
  /// interpolation, where the whole string is not a single ARB value.
  static Finder textContaining(String fragment) => find.textContaining(fragment);

  static Finder icon(IconData i) => find.byIcon(i);

  /// Any tappable carrying [label], whatever button widget the screen used.
  static Finder button(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) =>
            w is ButtonStyleButton ||
            w is InkWell ||
            w is GestureDetector ||
            w is TextButton),
      );

  /// The nth editable field on screen, for forms without keys yet.
  static Finder fieldAt(int index) => find.byType(TextField).at(index);

  /// Bottom-navigation destination carrying [label]. The culture build uses a
  /// custom glass nav and the full build a [BottomNavigationBar]; matching on
  /// the label covers both without the suites caring which shipped.
  static Finder navTab(String label) => find.text(label);

  /// A snackbar or dialog currently showing [message].
  static Finder message(String message) => find.descendant(
        of: find.byWidgetPredicate((w) => w is SnackBar || w is Dialog || w is AlertDialog),
        matching: find.text(message),
      );

  /// Any dialog at all.
  static final anyDialog =
      find.byWidgetPredicate((w) => w is Dialog || w is AlertDialog);

  /// A field currently showing a validation error. [TextFormField] renders its
  /// validator's return value as the decoration's errorText.
  static Finder validationError(String message) => find.descendant(
        of: find.byType(TextFormField),
        matching: find.text(message),
      );
}
