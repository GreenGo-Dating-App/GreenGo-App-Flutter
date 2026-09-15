
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:greengo_chat/core/config/app_config.dart';
import 'package:greengo_chat/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:greengo_chat/main.dart' as app;

import 'e2e_config.dart';
import 'e2e_finders.dart';

/// Boot, pumping and waiting primitives shared by every suite.
///
/// The one rule that shapes all of this: **never call `pumpAndSettle` on this
/// app.** GreenGo runs permanent animations (the starfield behind the login
/// screen, the splash's 3-second message rotator, the collapsible bottom nav),
/// so the frame queue never drains and `pumpAndSettle` throws after its
/// timeout instead of proceeding. Everything below pumps in fixed slices and
/// polls for a condition, which is also what makes the waits assert something.
class E2E {
  const E2E._();

  /// Brings Firebase up before any test touches it.
  ///
  /// `app.main()` is what calls `Firebase.initializeApp`, but several tests
  /// have to establish a session *before* booting — BOOT-01 is "open the app
  /// with a live session", which is meaningless if the sign-in happens after
  /// the boot it is supposed to precede. Without this, those tests threw
  /// "No Firebase App '[DEFAULT]' has been created" on their first line.
  ///
  /// Idempotent, and it wires the emulators itself: a test suite that silently
  /// fell through to production would ban, reject and delete real accounts.
  static Future<void> ensureFirebase() async {
    if (_firebaseReady) return;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
    }
    if (AppConfig.useLocalEmulators) {
      await FirebaseAuth.instance
          .useAuthEmulator(AppConfig.emulatorHost, AppConfig.authEmulatorPort);
      FirebaseFirestore.instance.useFirestoreEmulator(
          AppConfig.emulatorHost, AppConfig.firestoreEmulatorPort);
    } else if (E2EConfig.useEmulator) {
      fail('The suites are configured for the emulator '
          '(E2E_USE_EMULATOR=true) but the app resolved to PRODUCTION. '
          'Pass --dart-define=USE_EMULATORS=true and run in debug or profile '
          'mode — release builds can never use an emulator.');
    }
    _firebaseReady = true;
  }

  static bool _firebaseReady = false;

  /// Launches the app.
  ///
  /// `main()` runs exactly once per process, on the first boot. It is not
  /// re-entrant: among other one-shot work it calls `di.init()`, and
  /// registering an already-registered type throws. Because `main()` is async
  /// and deliberately not awaited, that throw surfaces as an unhandled
  /// asynchronous error — outside any test's try/catch — so the test fails
  /// with no message and reports nothing. Every test after the first was
  /// dying this way.
  ///
  /// Subsequent boots pump a fresh [app.GreenGoChatApp] instead, which is what
  /// "relaunch the app" actually means for the widget tree: a new root, the
  /// same already-initialized services underneath.
  static Future<void> boot(WidgetTester tester) async {
    await ensureFirebase();
    if (_mainRan) {
      // A unique key on every boot. Pumping the same widget type would reuse
      // the existing element tree, and AuthWrapper's State would come with
      // it — carrying the previous test's `_accessData`, so a signed-out app
      // still rendered MainNavigationScreen, and the login form kept stale
      // controllers so typing into it went nowhere.
      await tester.pumpWidget(
          app.GreenGoChatApp(key: ValueKey('e2e-boot-${++_bootCount}')));
    } else {
      _mainRan = true;
      app.main();
    }
    await pump(tester, const Duration(seconds: 3));
  }

  static bool _mainRan = false;
  static int _bootCount = 0;

  /// Pumps for [duration] in ~100ms slices, letting timers and streams run.
  static Future<void> pump(WidgetTester tester, Duration duration) async {
    final slices = (duration.inMilliseconds / 100).ceil();
    for (var i = 0; i < slices; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Pumps until [condition] holds, or fails the test with [reason].
  ///
  /// This is the workhorse assertion: "the app reaches state X within N
  /// seconds". It fails loudly on timeout — a wait that silently gives up
  /// turns every downstream expectation into a check that cannot fail.
  static Future<void> waitFor(
    WidgetTester tester,
    bool Function() condition, {
    required String reason,
    Duration? timeout,
  }) async {
    final limit = timeout ?? E2EConfig.screenTimeout;
    final deadline = DateTime.now().add(limit);
    var polls = 0;
    while (DateTime.now().isBefore(deadline)) {
      if (condition()) return;
      // Clear anything the app puts in front of the screen on first run.
      // Checked periodically rather than every poll: it walks the tree.
      if (polls++ % 12 == 0) await acceptOneTimeGates(tester);
      await tester.pump(const Duration(milliseconds: 150));
    }
    final user = FirebaseAuth.instance.currentUser;
    fail('Timed out after ${limit.inSeconds}s waiting for: $reason '
        '— currently showing: ${F.describeCurrentScreen()}'
        '; auth: ${user == null ? 'signed out' : 'signed in as ${user.uid}'}');
  }

  /// Accepts the one-time gates the app shows a fresh session.
  ///
  /// `CommunityGuidelinesScreen` is pushed over the shell on first run per
  /// account and blocks everything behind it — a test waiting for
  /// MainNavigationScreen waits forever with the guidelines sitting on top.
  /// That is correct app behaviour, so the harness clears it rather than every
  /// test having to know about it. A test that is *about* the gate asserts on
  /// it before calling any wait.
  ///
  /// Never fails: if the gate is not showing there is nothing to do.
  static Future<void> acceptOneTimeGates(WidgetTester tester) async {
    if (find.byType(Navigator).evaluate().isEmpty) return;
    final AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(
          tester.element(find.byType(Navigator).first));
    } catch (_) {
      return;
    }
    if (l10n == null) return;

    for (final label in <String>[
      l10n.guidelinesAccept,
      l10n.notificationDialogNotNow,
    ]) {
      final target = find.text(label);
      if (target.evaluate().isNotEmpty) {
        try {
          await tester.tap(target.first, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 600));
        } catch (_) {
          // The gate moved or was dismissed between finding and tapping.
        }
      }
    }
  }

  /// Convenience: wait until [finder] matches at least once.
  static Future<void> waitForFinder(
    WidgetTester tester,
    Finder finder, {
    required String reason,
    Duration? timeout,
  }) =>
      waitFor(tester, () => finder.evaluate().isNotEmpty,
          reason: reason, timeout: timeout);

  /// Convenience: wait until [finder] matches nothing.
  static Future<void> waitForGone(
    WidgetTester tester,
    Finder finder, {
    required String reason,
    Duration? timeout,
  }) =>
      waitFor(tester, () => finder.evaluate().isEmpty,
          reason: reason, timeout: timeout);

  /// The app's own localizations, read from the live widget tree.
  ///
  /// Suites locate controls by the exact string the app renders, taken from
  /// the same ARB file — never by a hardcoded English literal, which would
  /// break the moment the suite runs in another locale.
  static AppLocalizations l10n(WidgetTester tester) {
    final ctx = tester.element(find.byType(Navigator).first);
    final l = AppLocalizations.of(ctx);
    if (l == null) fail('AppLocalizations unavailable — the app did not boot.');
    return l;
  }

  /// Taps [finder] and pumps briefly. Fails with a readable message when the
  /// target is missing, rather than the framework's bare "zero widgets".
  static Future<void> tap(
    WidgetTester tester,
    Finder finder, {
    required String label,
    Duration settle = const Duration(milliseconds: 900),
  }) async {
    if (finder.evaluate().isEmpty) {
      fail('Cannot tap "$label" — no matching widget on screen.');
    }
    // ensureVisible first, and let the framework warn on a missed hit test:
    // `warnIfMissed: false` hid taps that landed on nothing, which read as a
    // control that does not work rather than as a test that never pressed it.
    try {
      await tester.ensureVisible(finder.first);
    } catch (_) {
      // Not inside a scrollable; tapping directly is still valid.
    }
    await tester.tap(finder.first);
    await pump(tester, settle);
  }

  /// Enters [text] into [finder], clearing whatever was there.
  static Future<void> type(
    WidgetTester tester,
    Finder finder,
    String text, {
    required String label,
  }) async {
    if (finder.evaluate().isEmpty) {
      fail('Cannot type into "$label" — no matching field on screen.');
    }
    // Focus the field first — this is also what a user does.
    try {
      await tester.tap(finder.first);
      await tester.pump(const Duration(milliseconds: 300));
    } catch (_) {
      // Not tappable at its centre; the fallback below still applies.
    }
    await tester.enterText(finder.first, text);
    await pump(tester, const Duration(milliseconds: 400));

    // `enterText` delivers through the *fake* text input, which only exists
    // when the binding registers one. `integration_test` runs on the live
    // binding and does not, so on web the keystrokes go to the browser and the
    // widget's controller stays empty. Fall back to setting the controller,
    // which is what the field would hold had the keystrokes landed.
    //
    // What this does NOT cover is the keystroke path itself — IME, autofill,
    // the browser's own input element. That is asserted at browser level in
    // `tool/e2e_web/web_suite.py`, which types into the real login form.
    final widget = tester.widget(finder.first);
    if (widget is TextFormField) {
      final controller = widget.controller;
      if (controller == null) {
        fail('"$label" has no controller, so its value cannot be set or read.');
      }
      if (controller.text != text) {
        controller.text = text;
        await pump(tester, const Duration(milliseconds: 300));
      }
      if (controller.text != text) {
        fail('Setting "$label" did not take: the field holds '
            '"${controller.text}" instead of "$text".');
      }
    }
  }

  /// Scrolls [scrollable] until [target] is visible, then returns.
  static Future<void> scrollTo(
    WidgetTester tester,
    Finder target, {
    Finder? scrollable,
    required String label,
    int maxSwipes = 12,
  }) async {
    final view = scrollable ?? find.byType(Scrollable).first;
    for (var i = 0; i < maxSwipes; i++) {
      if (target.evaluate().isNotEmpty) {
        await tester.ensureVisible(target.first);
        await pump(tester, const Duration(milliseconds: 300));
        return;
      }
      await tester.drag(view, const Offset(0, -320));
      await pump(tester, const Duration(milliseconds: 400));
    }
    fail('Scrolled $maxSwipes times without reaching "$label".');
  }

  /// Signs whoever is logged in out at the Firebase layer and pumps the app
  /// back to a stable state. Used in `tearDown` so one test's session never
  /// decides the next test's starting screen.
  static Future<void> hardSignOut(WidgetTester tester) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Firebase never came up; nothing to sign out of.
      return;
    }
    // Wait for it to actually land. Swallowing this was how a signed-in
    // session survived into the next test, which then sat waiting for a login
    // screen the app had no reason to show.
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (FirebaseAuth.instance.currentUser != null &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    await pump(tester, const Duration(seconds: 1));
  }

  /// Guard for tests that write data. Against production they must not run.
  static void requireEmulator(String testId) {
    if (!E2EConfig.useEmulator) {
      fail('$testId writes data and must run against the Firebase emulator. '
          'Re-run with --dart-define=E2E_USE_EMULATOR=true.');
    }
  }
}

/// Unique-per-run suffix so seeded documents never collide between runs and
/// a failed run's leftovers are identifiable.
String e2eStamp() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
