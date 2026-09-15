# GreenGo end-to-end suites

One hundred scenarios a real account must survive. Ninety-five run as Flutter
`integration_test` widget tests; five are browser-level and run under
Playwright, because a service worker, a page reload, a second tab, a real
notification grant and the viewport are things only a browser can be asked
about.

## Why this exists

Commit `9c46d4d` resolved `PushNotificationService` through GetIt inside
`MainNavigationScreen.initState`. That service is a plain library singleton and
was never registered, so the lookup threw, Flutter replaced the entire
post-login subtree with the release `ErrorWidget` — a flat grey rectangle — and
every logged-in web user saw a blank page. Nothing in the repository could have
caught it: no test ever logged in and looked at the resulting screen.

`BOOT-03` is now that test. It fails if any widget in the post-login tree
throws during build, whatever the reason.

## Layout

```
integration_test/
  all_tests.dart              runs all 95 widget-level scenarios
  support/
    e2e_config.dart           fixture accounts and timing budgets (--dart-define)
    e2e_harness.dart          boot, pump, wait-for primitives
    e2e_finders.dart          screen and control finders
    e2e_actions.dart          user-level actions (log in, open a tab)
    e2e_backend.dart          seeding and server-side assertions
  suites/
    s01_boot_session_test.dart        BOOT-01,02,03,06,07,08,10
    s02_registration_test.dart        REG-01 … REG-12
    s03_auth_test.dart                AUTH-01 … AUTH-10
    s04_access_gate_test.dart         GATE-01 … GATE-08
    s05_discovery_test.dart           DISC-01 … DISC-08
    s06_chat_test.dart                CHAT-01 … CHAT-10
    s07_groups_communities_test.dart  GRP-01 … GRP-08
    s08_events_test.dart              EVT-01 … EVT-12
    s09_payments_test.dart            PAY-01 … PAY-08
    s10_notifications_test.dart       NOTIF-01,02,04,05,06
    s11_profile_settings_test.dart    PROF-01 … PROF-07
tool/
  e2e_seed.js                 seeds the seven fixture accounts (emulator only)
  e2e_web/web_suite.py        BOOT-04, BOOT-05, BOOT-09, NOTIF-03, PROF-08
```

## Running them

### 1. Start the emulators and seed

```bash
firebase emulators:start --only auth,firestore,storage,functions
node tool/e2e_seed.js            # add --reset to clear a dirty run first
```

If port 8080 is already taken — it commonly is — start the Firestore emulator
elsewhere and tell the app where to look. Host and ports are `--dart-define`
overridable, defaults unchanged:

```bash
--dart-define=EMULATOR_HOST=127.0.0.1        # 10.0.2.2 only means "host" inside an Android emulator
--dart-define=EMULATOR_FIRESTORE_PORT=8085
```

`EMULATOR_HOST=127.0.0.1` is required for every web and iOS-simulator run.

The seeder refuses to run against anything but a local emulator. Every fixture
it creates is one a test later bans, rejects or deletes.

### 2. Widget-level suites

```bash
# Android
flutter test integration_test/all_tests.dart -d emulator-5554 \
  --dart-define=E2E_USE_EMULATOR=true

# Web (needs the driver; web tests run in the browser, the driver on the host)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/all_tests.dart \
  -d chrome --dart-define=E2E_USE_EMULATOR=true
```

One suite at a time: swap `all_tests.dart` for
`suites/s01_boot_session_test.dart`.

### 3. Browser-level suite

```bash
flutter build web --release
firebase emulators:start --only hosting      # serves build/web on :5000
python tool/e2e_web/web_suite.py \
  --base-url http://127.0.0.1:5000 \
  --email approved@e2e.greengo.test --password 'E2e-Approved!2026'
```

Serve it through Firebase Hosting (the emulator above, or `firebase serve`),
**not** `python -m http.server`. A naive static server sends none of the
cache headers `flutter_service_worker.js` expects, and BOOT-04 then fails
against a build that is perfectly healthy: the first load paints, the
service worker registers, and the cached reload comes back as a flat
`#0A0A0A` frame with no console error. Verified both ways — the same build
that fails on `http.server` passes on real hosting.

It exits with the number of failures, so CI can gate on it. It drives the
installed Chrome (`channel="chrome"`), never a downloaded Chromium — the point
is the browser users actually run.

The login-driven tests click the form by coordinate, because Flutter web
draws it into a canvas. The constants at the top of `web_suite.py` are the hit
points for a 1280x900 viewport and need updating if the login layout moves.

## Rules the suites follow

**Never `pumpAndSettle`.** GreenGo animates permanently — the starfield behind
the login screen, the splash's message rotator, the collapsible bottom nav — so
the frame queue never drains and `pumpAndSettle` throws on timeout instead of
proceeding. `E2E.waitFor` pumps in slices and polls a condition, which is also
what makes each wait an assertion.

**Every wait fails loudly.** A wait that silently gives up turns every
assertion after it into a check that cannot fail.

**Find by key, then by localized label.** Controls the suites drive constantly
carry an `E2EKeys` key. Everything else is located by the exact string the app
renders, read from `AppLocalizations` at runtime — never an English literal
typed into a test, which would break the moment the suite runs in another
locale.

**Assert the document as well as the screen.** A label reading "20 coins" does
not prove twenty coins were persisted. Where a regression would hide in that
gap — a double-credited purchase, an RSVP counted twice, a block the rules
rejected — the test checks both.

**Credentials come from `--dart-define`.** A password committed to git is a
password that has to be rotated. The defaults in `e2e_config.dart` are
emulator-only fixtures.

## Adding a control the suites need

Add a key to `lib/core/constants/e2e_keys.dart` and attach it in the widget.
`AuthTextField` takes `fieldKey`, which it forwards to the inner
`TextFormField` so `tester.enterText` resolves to the editable itself rather
than the wrapper.
