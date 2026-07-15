# GreenGo — Mobile → Web Compatibility & Sync Plan

**Goal:** Make the GreenGo Flutter **Web** build (`greengo-chat.web.app`) fully compatible, error-free, and feature-synced with the mobile app, so a single Flutter codebase ships to Android, iOS, and Web without runtime crashes on the web target.

**Status:** Planning / investigation complete. This is a design document — no code changed, no commits/pushes made in either repo.

**Date:** 2026-07-13

**Repos investigated:**
| Role | Location | Version | Firebase project | Hosting target |
|------|----------|---------|------------------|----------------|
| Mobile source of truth (also the real web source) | `Desktop/Projects/GreenGo/GreenGo-App-Flutter` (local) | `greengo_chat 3.0.0+101` | `greengo-chat` | `app` → `greengo-chat.web.app` |
| Legacy web fork (cloned for comparison) | `GreenGo-Dating-App/greengo-app-flutter-web` (cloned to scratchpad `greengo-web/`) | `greengo_chat 1.8.0+53` | `greengo-chat` | `app` → `greengo-chat.web.app` |

---

## 1. Executive summary of findings

The framing "migrate mobile → separate web repo" does **not** match reality. The key finding:

1. **The mobile repo IS the web source.** `firebase.json` in the mobile repo declares `hosting` target `app` → `public: build/web`, `codemagic.yaml` has a `web-release` job (`flutter build web --release` → `firebase deploy --only hosting:app`), and `web/index.html` + `web/manifest.json` are already fully GreenGo-branded. The mobile repo already builds and deploys the production web app.
2. **`GreenGo-Dating-App/greengo-app-flutter-web` is a stale, diverged fork** (v1.8.0+53, 690 Dart files, 41 feature dirs) that is ~48 versions and 119 Dart files behind the mobile repo (v3.0.0+101, 809 Dart files, 48 feature dirs). It points at the **same** Firebase project and the **same** hosting target, so whichever repo deploys last wins `greengo-chat.web.app`. **This is a footgun and the fork should be retired as a deploy source.**
3. **Web payments (Stripe Checkout) already exist in the mobile repo** — `lib/core/services/stripe_web_checkout.dart` + `lib/features/coins/presentation/widgets/web_checkout_dialog.dart`, gated by `kIsWeb`.
4. **The FCM web push path is NOT wired.** There is **no** `web/firebase-messaging-sw.js`, `getFCMToken()` calls `messaging.getToken()` **without a `vapidKey`**, and `PushNotificationService.initialize()` early-returns on web. Web users will never receive push. This is the single biggest functional gap.
5. **38 files import `dart:io` unconditionally** and reference `File`, `Platform`, etc. Flutter web ships a `dart:io` shim so the **build compiles**, but any `File(...)` / `Platform.isX` reached on web throws `UnsupportedError` at runtime. Critical paths (photo/chat upload) are already `kIsWeb`-guarded; the audit below confirms which remain unguarded.

**Bottom line:** This is not a port — it is a *hardening + sync* job on one codebase. Retire the fork, close the FCM-web gap, finish the `kIsWeb` runtime guards, verify a clean `flutter build web`, and keep Stripe-on-web / IAP-on-mobile behind the existing payment seam.

---

## 2. Current state & divergence analysis

### 2.1 Structural comparison

| Aspect | Mobile repo (`GreenGo-App-Flutter`) | Legacy web fork (`greengo-app-flutter-web`) |
|--------|-------------------------------------|---------------------------------------------|
| pubspec version | `3.0.0+101` | `1.8.0+53` |
| Dart files in `lib/` | 809 | 690 |
| Feature dirs | 48 | 41 |
| `web/index.html` branding | GreenGo, `#0A0A0A`, rich description, PWA meta | GreenGo (older copy: "Learn from People around the World") |
| `web/manifest.json` | GreenGo w/ shortcuts (Events/Community/Messages) | GreenGo (older name) |
| `web/.well-known/` (deep-link assoc files) | Present (`apple-app-site-association`, `assetlinks.json`) | **Absent** |
| `web/u/index.html`, `web/e/index.html` | Present (deep-link landing) | **Absent** |
| `firebase.json` hosting rewrites | `/u/**`, `/e/**`, `**` | `**` only (no deep-link routes) |
| Stripe web checkout | `stripe_web_checkout.dart` present | `main.dart` references stripe (older) |
| `in_app_purchase` | `^3.3.0` (Billing 8) | `^3.2.0` (Billing older) |
| ML Kit pins | face `0.13.2` / image `0.14.2` (GDT 10 aligned) | face `^0.13.1` / image `^0.14.0` / **text `^0.15.0`** |

### 2.2 Features present in mobile but missing from the fork
`business`, `explore`, `glass_demo`, `passport`, `recommendations`, `referral`, `saved_searches` (7 feature dirs). Per project memory ("web fork diverged — never wholesale-copy the 4 big screens"), the fork's Discovery/Chat/Profile/Events screens diverged and must **not** be blindly copied back.

### 2.3 Decision
**Adopt the mobile repo as the single source for web.** Do all web-hardening work in `GreenGo-App-Flutter`. The fork is reference-only; either archive it or repoint its Firebase target to a preview channel so it can never overwrite production.

---

## 3. Compatibility workstream (CORE)

### 3.1 How web currently survives `dart:io`
There are **no** conditional-import stubs (`import ... if (dart.library.io)`) and **no** `*_io.dart`/`*_web.dart` split files in the mobile `lib/`. Instead, `dart:io` is imported unconditionally in 38 files and dangerous calls are wrapped in **runtime** `if (kIsWeb)` branches. Flutter web provides a `dart:io` that compiles but throws `UnsupportedError` when `File`/`Platform`/`Directory` members are actually invoked. So:

- **Build breaks:** No (import compiles).
- **Runtime breaks:** Yes, wherever a `File(...)`/`Platform.isX` is reached on web without a `kIsWeb` guard.

The mobile repo already guards the critical media paths (`readAsBytes`/`putData`/`XFile` appear in `photo_validation_service.dart`, `image_compression.dart`, `chat_screen.dart`). The compatibility task is to **audit the remaining `dart:io` sites and add `kIsWeb` guards + `XFile.readAsBytes()` upload branches** where the web user can reach them.

### 3.2 Web-incompatible dependency / API matrix

| Dependency / API | Where (real paths) | Web behavior | Fix / strategy |
|---|---|---|---|
| `dart:io` `File`, `Platform`, `Directory` | 38 files incl. `features/chat/.../chat_screen.dart` (L858 `File(image.path)`), `features/profile/data/datasources/profile_remote_data_source.dart`, `features/business/.../storefront_editor_screen.dart`, `features/stories/.../stories_screen.dart`, `core/utils/image_compression.dart`, `core/services/photo_validation_service.dart` | Compiles; throws `UnsupportedError` at runtime if reached | Wrap every `File`/`Platform` call in `if (kIsWeb) { …XFile.readAsBytes() + putData… } else { …File + putFile… }`. Upload via `Reference.putData(Uint8List)` on web. Audit each of the 38 files; guard the ones on a web-reachable path. |
| `image_picker` returns `XFile`; then `File(x.path)` | `chat_screen.dart`, `onboarding/step2_photo_upload_screen.dart`, `photo_management_screen.dart`, `reverification_screen.dart` | `image_picker` **works** on web (file input), but `File(xfile.path)` throws — `path` is a blob URL | Web branch: `final bytes = await xfile.readAsBytes(); ref.putData(bytes);` Never construct `File` from an `XFile.path` on web. |
| `flutter_local_notifications` `^18.0.1` | `core/services/push_notification_service.dart` | **No web support**; plugin no-ops / unregistered on web | Already handled: `initialize()` early-returns on web. Keep. Web notifications come from the FCM service worker (see §5), not this plugin. |
| `firebase_messaging` `getToken()` (no VAPID) | `notifications/data/datasources/notification_remote_datasource.dart` L244 | On web `getToken()` **requires** `vapidKey:` + a registered `firebase-messaging-sw.js`, else throws / returns null | Add `getToken(vapidKey: kIsWeb ? <VAPID> : null)` and register the SW. See §5. |
| `mobile_scanner` `^7.0.0` | `features/events/.../event_scanner_screen.dart`, `features/explore/.../qr_hub_screen.dart` | Has partial web support (getUserMedia) but camera QR scan is unreliable in-browser and needs HTTPS + camera permission | Gate scanner entry behind `if (!kIsWeb)`; on web show "scan on the mobile app" or a manual code-entry fallback. QR *generation* (`qr_flutter`) is fine on web. |
| `google_maps_flutter` `^2.5.0` | `features/events/.../event_location_picker_screen.dart`, `event_map_card.dart`, `profile/.../traveler_location_picker_screen.dart` | Web needs the Maps JS API key injected in `index.html`; without it tiles render broken | Already handled: `core/widgets/web_map_placeholder.dart` swaps `GoogleMap` for a clean placeholder on web. Keep; optionally wire a JS Maps key later. |
| `geolocator` `^10.1.0` | 6 sites incl. location pickers, discovery | Works on web via browser geolocation, but requires HTTPS + permission prompt; some APIs (background) unsupported | Keep for foreground `getCurrentPosition`; guard any settings/background calls with `kIsWeb`. |
| `record` `^5.2.1` (audio) | `core/widgets/voice_record_send_button.dart`, `profile/.../edit_voice_screen.dart` | Web supported via MediaRecorder but MIME/codec differs; needs HTTPS + mic permission | Verify web recording produces an uploadable blob; guard file-path assumptions with `kIsWeb` and use bytes upload. |
| `flutter_tts` `^4.2.0` | (declared; no direct `FlutterTts` refs found in `lib/`) | Web supported via SpeechSynthesis (voice availability varies) | Low risk; verify voices load, else no-op. |
| `path_provider` `^2.1.1` | via caching/temp file helpers | **No meaningful web support** (no filesystem) | Ensure Hive/cache init doesn't call it on web; `cacheService.initialize()` must tolerate web (uses IndexedDB). Guard any `getTemporary/ApplicationDocumentsDirectory` with `kIsWeb`. |
| `permission_handler` `^11.1.0` | permission flows | Most permissions are **no-ops** on web (browser handles prompts) | Guard permission requests with `kIsWeb`; rely on browser prompts for camera/mic/geo. |
| `flutter_local_notifications`, `device_info_plus`, `package_info_plus` | version checks, device info | Partial web support; `Platform.isX` throws | `version_check_service.dart` imports `dart:io` — ensure platform branch uses `kIsWeb`/`defaultTargetPlatform`, not `Platform.isAndroid`. |
| `agora_rtc_engine` | commented out in pubspec | N/A (disabled) | Video calling stays mobile-only; leave disabled. |
| `firebase_app_check` | `main.dart` L162 | Web needs reCAPTCHA Enterprise setup | Already skipped on web (`!kIsWeb`). Keep; optionally add reCAPTCHA v3 provider later. |
| `firebase_performance` / `firebase_crashlytics` | `main.dart` | Crashlytics has **no web** support; Performance is limited | Verify these are not initialized in a way that throws on web (Crashlytics calls should be `kIsWeb`-guarded). |
| Firestore offline persistence | `main.dart` L108 | Web uses IndexedDB; fails in private mode / multi-tab | Already wrapped in try/catch. Keep. |

### 3.3 Recommended long-term pattern
For anything heavier than a `kIsWeb` branch (e.g. file abstraction), introduce a conditional-import seam so web never even links `dart:io`:

```dart
// lib/core/platform/file_upload.dart
export 'file_upload_io.dart' if (dart.library.html) 'file_upload_web.dart';
```
`file_upload_io.dart` uses `File.putFile`; `file_upload_web.dart` uses `putData(await xfile.readAsBytes())`. Migrate the highest-traffic upload sites (chat media, profile photo, stories) to this seam first.

---

## 4. Payments workstream — keep Stripe on web

### 4.1 The provider-abstraction seam (already present)
- **Mobile** buys coins/membership via native IAP: `in_app_purchase` + `in_app_purchase_android` (Billing 8) + `in_app_purchase_storekit`. The IAP plugin is only instantiated off-web — `coin_shop_screen.dart` L118: `if (kIsWeb) return; // no IAP plugin on web`.
- **Web** buys via **Stripe Checkout**: `lib/core/services/stripe_web_checkout.dart` (`isSupported => kIsWeb`). Flow:
  1. `startCheckout(productId)` → callable Cloud Function `createStripeCheckoutSession` (passes `successUrl=$origin/?payment=success`, `cancelUrl=$origin/?payment=cancel`, `userCountry`), then `launchUrl(url, webOnlyWindowName:'_blank')`.
  2. Cloud Function `stripeWebhook` credits coins / activates membership and writes `stripe_orders`.
  3. `waitForCompletion()` polls `stripe_orders` (status `completed`) in the original tab; `payment_result_screen.dart` reads `?payment=success|cancel`.
- **Branch points:** `coin_shop_screen.dart` at L1341 / L1630 / L2106 all guard `if (kIsWeb || _inAppPurchase == null)` → route to `web_checkout_dialog.dart` → `StripeWebCheckout`. `base_membership_dialog.dart` and `subscription/data/datasources/subscription_remote_datasource.dart` also carry the Stripe branch.

### 4.2 What to build / verify
| Item | Action |
|---|---|
| Cloud Functions live | Confirm `createStripeCheckoutSession` + `stripeWebhook` are deployed in project `greengo-chat` and product IDs in `core/constants/product_catalog.dart` match Stripe price IDs. |
| Keys location | Stripe secret + webhook signing secret live in Cloud Functions config / Secret Manager — **not** in the client and **not** in this doc. Client only calls the callable. Reference: `E:\Projects\GreenGo\credentials\greengo-credentials.txt`. |
| Country/tax | `_resolveCountry()` reads `profiles/{uid}.location.country`; verify tax handling in the Function. |
| Result UX | Verify `payment_result_screen.dart` renders success/cancel and the polled coin credit lands. |
| Membership on web | Confirm membership (Base) purchase also routes through Stripe on web (not only coin packs). |
| No IAP on web | Confirm `in_app_purchase*` is never `import`-reached in a way that breaks the web build (guards are runtime; imports compile as no-ops on web). |

**Rule:** web = Stripe Checkout only; mobile = IAP/Billing only. The seam already enforces this via `kIsWeb`; keep it.

---

## 5. Notifications workstream — FCM web push (BIGGEST GAP)

### 5.1 What's missing (confirmed)
- ❌ No `web/firebase-messaging-sw.js` service worker.
- ❌ `web/index.html` does not register any messaging service worker.
- ❌ `getFCMToken()` (`notification_remote_datasource.dart` L244) calls `messaging.getToken()` with **no `vapidKey`** → on web returns null / throws.
- ✅ Token storage exists: `saveFCMToken()` writes `fcmToken` to both `profiles/{uid}` and `users/{uid}` (Cloud Functions read `profiles` for push). Token-refresh persistence also exists in `push_notification_service.dart`.

### 5.2 Exact pieces to add
1. **Create `web/firebase-messaging-sw.js`** (served at site root; imports the compat SDK and initializes with the web app config — public Firebase web config, not a secret):
```js
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');
firebase.initializeApp({
  apiKey: '…', authDomain: 'greengo-chat.firebaseapp.com',
  projectId: 'greengo-chat', messagingSenderId: '666632803027',
  appId: '1:666632803027:web:36045de58c58a60f9aba26',
});
const messaging = firebase.messaging();
messaging.onBackgroundMessage((m) => {
  self.registration.showNotification(m.notification?.title ?? 'GreenGo', {
    body: m.notification?.body, icon: '/icons/Icon-192.png', data: m.data,
  });
});
self.addEventListener('notificationclick', (e) => {
  e.notification.close();
  e.waitUntil(clients.openWindow('/'));
});
```
   (CSP note: Firebase Hosting allows these gstatic imports; the values above are the app's public web config already present in `firebase_options.dart`.)
2. **Generate a Web Push VAPID key** in Firebase Console → Cloud Messaging → Web configuration → "Web Push certificates". Store the public key in a web-only config constant (public — safe to ship in client); keep it out of this doc.
3. **Pass the VAPID key** in `getFCMToken()`:
```dart
Future<String?> getFCMToken() async {
  if (kIsWeb) {
    return messaging.getToken(vapidKey: WebPushConfig.vapidPublicKey);
  }
  return messaging.getToken();
}
```
4. **Register the SW & wire foreground handlers on web** in `PushNotificationService.initialize()`: instead of early-returning on web, on web still `requestPermission()`, get the token (triggers SW registration), and `FirebaseMessaging.onMessage.listen(...)` for foreground toasts. Background/closed-tab notifications are shown by the SW.
5. **Permission UX:** the existing `_maybeShowNotificationPrompt` dialog already drives `requestPermission()` — on web this maps to the browser Notification prompt. Ensure it fires on web too.
6. **Verify Cloud Function push** targets the stored `profiles/{uid}.fcmToken` for web tokens the same as mobile (web tokens are just FCM tokens — no code change server-side beyond ensuring web tokens aren't filtered out).

### 5.3 Acceptance
On `greengo-chat.web.app`: grant notifications → token saved to `profiles/{uid}` → send a chat message from another account → a browser notification arrives (tab closed) and a foreground toast (tab open) with correct deep-navigation on click.

---

## 6. Branding / PWA workstream

**Good news:** the mobile repo `web/` is already GreenGo-branded (title `GreenGo`, `theme_color`/`background_color` `#0A0A0A`, correct description & PWA meta, apple-touch-icon). The Flutter-default branding problem applies to the **legacy fork**, not the mobile repo. Remaining polish items:

| Item | File | Current | Action |
|---|---|---|---|
| Favicon | `web/favicon.png` | present (917 B) | Confirm it is the GreenGo gold mark, not Flutter default; regenerate at 32×32 + 16×16. |
| PWA icons | `web/icons/Icon-{120,152,180,192,512}.png`, `Icon-maskable-{192,512}.png` | present | Confirm all are the GreenGo brand mark on `#0A0A0A`; regenerate maskable with safe-zone padding (gold logo, deep-black bg). |
| iOS PWA splash | `web/index.html` L34-58 (TODO block) | **not generated** | Generate `apple-touch-startup-image` PNGs for the ~14 listed iPhone/iPad sizes (deep-black `#0A0A0A` bg + gold logo) and wire the `<link media=...>` tags. |
| Manifest shortcuts | `web/manifest.json` | Events/Community/Messages | Verify shortcut URLs resolve under the SPA router (they currently deep-link paths the router must handle — see §7). |
| Loading/splash image | uses `assets/images/greengo_logo.png` (Dart splash) | present | Optionally add an HTML pre-Flutter loader in `index.html` so first paint shows the gold logo instead of a white flash. |
| Social/OG tags | `web/index.html` | has description | Add `og:title`/`og:image`/`twitter:card` with a branded share image for `/u/*` and `/e/*` link previews. |

**No secrets** — all icon/manifest assets are public.

---

## 7. Deep-linking + routing on web

- **Hosting rewrites (present in mobile `firebase.json`):** `/u/**` → `/u/index.html`, `/e/**` → `/e/index.html`, `**` → `/index.html`. The `web/u/index.html` and `web/e/index.html` landing pages exist (fork lacks both).
- **Association files:** `web/.well-known/apple-app-site-association` + `assetlinks.json` are served with `Content-Type: application/json` headers (present in mobile `firebase.json`). Keep for iOS/Android universal links.
- **In-app routing gap:** `main.dart` L567 disables `DeepLinkService` on web (`if (!kIsWeb)`), because `app_links` platform plumbing differs. So a user landing on `greengo-chat.web.app/u/<id>` gets the SPA but the **Flutter router does not parse the `/u/<id>` or `/e/<id>` path** into a profile/event screen.
- **Action:** Add a web-only initial-route parser: read `Uri.base.path` on web at startup, and if it matches `/u/<id>` or `/e/<id>`, push the profile/event screen after auth. Either a small `if (kIsWeb)` block in `AuthWrapper.initState` using `Uri.base`, or adopt a `RouteInformationParser`. Ensure the manifest shortcut URLs (`/events`, `/community`, `/messages`) also map to real routes (they currently rely on `onGenerateRoute`; `/community` vs `/communities` naming must be reconciled).

---

## 8. Feature parity matrix

| Feature | Web target | Notes |
|---|---|---|
| Auth (email/password, forgot-password) | ✅ Must work | `firebase_auth` full web support. |
| Discovery / profiles / Network | ✅ Must work | Firestore + cached images; verify grid/filter overlay. |
| Chat (1:1 + group) | ✅ Must work | Text ✅; media upload needs web bytes-upload branch (§3.2). |
| Events / external_events / Attractions | ✅ Must work | Firestore cache-first; map → `WebMapPlaceholder`. |
| Coins shop | ✅ via Stripe | §4. |
| Base membership / subscription | ✅ via Stripe | §4. |
| Notifications | ⚠️ Needs SW + VAPID | §5 — currently non-functional on web. |
| Groups / user_group_tags | ✅ Must work | Firestore. |
| Stories | ⚠️ Upload path | Needs web bytes-upload guard. |
| Voice messages / TTS pronunciation | ⚠️ Verify | `record`/`flutter_tts` web behavior + mic permission. |
| Maps (pickers, event map) | ⚠️ Degraded | Placeholder on web unless Maps JS key wired. |
| QR check-in scanner | ❌ Mobile-only | `mobile_scanner` camera unreliable on web; QR *display* fine. |
| Selfie/photo verification (ML Kit) | ❌ Mobile-only | `google_mlkit_*` are native; guard entry on web or use manual review. |
| Video calling / video profiles | ❌ Mobile-only | Agora disabled; dating-adjacent, flag-off. |
| Dating features (`matches`, blind_date, etc.) | 🚩 Flag-off | Keep OFF on web (`FlavorConfig.enableVideoProfiles` etc.), per Apple repositioning. |

Legend: ✅ full · ⚠️ works with fix · ❌ mobile-only (graceful degrade) · 🚩 intentionally disabled.

---

## 9. Build, test & deploy

### 9.1 Build
```bash
flutter pub get
flutter gen-l10n
flutter analyze                 # must be clean (0 errors)
flutter build web --release     # must complete with no compile errors
```

### 9.2 Error-free criteria
- `flutter analyze` → 0 errors (warnings triaged).
- `flutter build web --release` completes; `build/web/` produced.
- Load `greengo-chat.web.app` (or `firebase hosting:channel:deploy preview`) with DevTools console open: **no uncaught `UnsupportedError`**, no red errors, no missing-asset 404s.
- Smoke path: register/login → onboarding photo upload (web bytes path) → discovery loads → open chat, send text + image → open coin shop, launch Stripe test checkout → grant notifications, receive a test push.

### 9.3 Deploy
```bash
flutter build web --release
# Corp-TLS MITM (AVG) on this machine breaks Node TLS during firebase deploy:
NODE_TLS_REJECT_UNAUTHORIZED=0 firebase deploy --only hosting:app
```
- CI: `codemagic.yaml` `web-release` job runs `flutter build web --release` then `firebase deploy --only hosting:app` with `$FIREBASE_TOKEN`.
- **Retire the fork as a deploy source:** the legacy fork's `firebase.json` targets the *same* `app` host — ensure only the mobile repo (or CI from it) deploys to `greengo-chat`, or repoint the fork to a preview channel.

---

## 10. Phased rollout

| Phase | Scope | Acceptance criteria |
|---|---|---|
| **P0 — Build & load** | Confirm `flutter build web --release` is green from the mobile repo; deploy to a **preview channel** (not prod). Audit the 38 `dart:io` sites for any unguarded web-reachable `File`/`Platform` call. | Web build compiles; preview URL loads to login with **zero** console errors; no `UnsupportedError` on the unauthenticated path. |
| **P1 — Auth + core** | Login/register/forgot-password; onboarding photo upload via web bytes path; discovery, network, chat (text), events browsing. | A web user can register, complete onboarding (photo uploads succeed), browse discovery/events, and send/receive **text** chat. |
| **P2 — Payments + notifications** | Verify Stripe Checkout end-to-end on web (coins + membership); implement FCM web SW + VAPID + token + foreground/background handlers; chat **media** upload. | Stripe test purchase credits coins; web push arrives (tab open & closed) and deep-navigates on click; image/video message upload works. |
| **P3 — Branding + PWA polish** | Confirm/regenerate favicon + maskable icons; generate iOS PWA splash images; OG tags; pre-Flutter HTML loader; deep-link `/u/*` `/e/*` route parsing. | Installable PWA with correct GreenGo branding; `/u/<id>` and `/e/<id>` open the right screen; share previews render. |
| **P4 — Parity & degrade** | Gate mobile-only features on web (scanner, ML Kit verification, video); verify maps placeholder; confirm dating flags OFF on web; reconcile manifest shortcut routes. | No dead/crashing entry points on web; mobile-only features are hidden or show a graceful "use the app" message; dating features invisible. |

---

## 11. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Fork and mobile repo both deploy to `greengo-chat` hosting `app` | A stale fork deploy silently rolls prod web back to v1.8.0 | Retire fork as deploy source; only CI-from-mobile deploys to prod; fork → preview channel. |
| Unguarded `dart:io` `File`/`Platform` reached on web | Runtime `UnsupportedError`, white screen | Audit all 38 files; add `kIsWeb` guards + bytes-upload; introduce conditional-import seam for hot paths. |
| FCM web never delivered | Web users miss messages/matches | P2 SW + VAPID; verify server sends to web tokens. |
| Stripe Functions not deployed / price-ID mismatch | Web purchases fail | Verify `createStripeCheckoutSession`/`stripeWebhook` live; reconcile `product_catalog.dart` ↔ Stripe price IDs. |
| Maps JS key absent | Degraded map UX on web | `WebMapPlaceholder` already covers; optionally wire Maps JS key later. |
| `mobile_scanner`/ML Kit on web | Crash or broken camera | Gate behind `!kIsWeb`; manual fallback. |
| IndexedDB persistence in private/multi-tab | Boot without cache | Already try/caught in `main.dart`; keep. |
| Corp-TLS (AVG) breaks `firebase deploy` | Deploy fails locally | `NODE_TLS_REJECT_UNAUTHORIZED=0` prefix (documented). |
| Divergent fork screens copied back | Regressions | Do NOT wholesale-copy the fork's Discovery/Chat/Profile/Events screens (memory). Sync forward only within mobile repo. |

---

## 12. Open questions / decisions for the user

1. **Retire the fork?** Confirm `GreenGo-Dating-App/greengo-app-flutter-web` should be archived (or repointed to a preview channel) so it can never overwrite `greengo-chat.web.app`. The mobile repo is the source of truth.
2. **VAPID key** — generate in Firebase Console (Cloud Messaging → Web Push certificates); confirm where to store the *public* key in-client (a web-only config constant is fine to commit; keys stay out of this doc).
3. **Google Maps JS key on web** — provision a browser-restricted Maps JS key, or keep the `WebMapPlaceholder` degrade permanently?
4. **Stripe Functions status** — confirm `createStripeCheckoutSession` + `stripeWebhook` are deployed to `greengo-chat` and product/price IDs are reconciled.
5. **Web scope of media/voice** — are chat media + voice messages in-scope for web P2, or defer voice to mobile-only initially?
6. **iOS PWA splash images** — approve generating the ~14 device-size splash PNGs (gold logo on `#0A0A0A`) as a design task.
7. **Dating flags** — confirm all dating features stay OFF on web (aligns with the Apple v3.0.0 repositioning).

---

---

## 13. AMPLIFIED — full mobile→web parity per feature area

> Added after a screen-level audit of the 3.0.0 code. §8's matrix is architecture-level; this section makes **Explore, Events, Communities, and Business** parity concrete, with the exact web-breaking call sites (verified by line number) and the fix for each. **Goal: the web build behaves identically to mobile for every non-native feature.**

### 13.0 The one pattern that fixes most of it
Every crash below is the same bug: `File(xfile.path)` on web. `image_picker` works on web (it returns an `XFile` backed by a `blob:` URL), but `File(...)` from that path throws `UnsupportedError`, and `Reference.putFile(File)` has no web implementation. The universal fix:

```dart
// BEFORE (crashes on web)
await ref.putFile(File(picked.path));

// AFTER (works on web + mobile)
if (kIsWeb) {
  final bytes = await picked.readAsBytes();
  await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
} else {
  await ref.putFile(File(picked.path));
}
```
For hot paths, migrate to the conditional-import seam in §3.3 (`file_upload.dart`) so web never links `dart:io` at all. Same fix applies to every site in the table below.

### 13.1 EXPLORE — parity status: ✅ nearly ready
- **Screens:** `explore_screen`, `network_discovery_screen`, `universal_search_screen`, `qr_hub_screen`.
- **`dart:io` sites:** **0** — Explore is clean, no upload/File paths.
- **Web concerns:**
  - `qr_hub_screen` → QR **scanning** uses `mobile_scanner` (unreliable on web) → gate the scan entry behind `!kIsWeb` and offer manual code entry; QR **display** (`qr_flutter`) is fine on web.
  - Explore carousel + Network grid → responsive audit (W3): 2/3/4 columns must scale to desktop widths; hover, mouse-wheel scroll, keyboard focus.
  - `universal_search_screen` → pure Firestore/text, works on web; verify debounce + empty states at desktop width.
- **Action:** responsive pass + scanner gate. No upload fixes needed.

### 13.2 EVENTS — parity status: ⚠️ upload + scanner + maps
- **Screens:** `events_screen`, `event_detail_loader`, `event_attendance`, `event_chat`, `event_ticket`, `event_location_picker`, `event_scanner`.
- **🔴 Web-breaking upload (VERIFIED):** `events_screen.dart:3058` `File(x.path)` (event main photo) and `:3067` `File(x.path)` (extra photos) — **unguarded**, crashes when a web user creates/edits an event with images. → apply the 13.0 bytes-upload fix.
- **Maps:** `event_location_picker` + `event_map_card` → already swap to `WebMapPlaceholder` on web (keep; optionally wire a Maps JS key later).
- **QR:** `event_scanner_screen` (check-in) → `mobile_scanner`, gate behind `!kIsWeb`. `event_ticket_screen` shows a QR (**display is fine on web**).
- **Rest:** `event_attendance`, `event_chat`, external_events/Attractions browsing → Firestore, work on web. Verify the "Going" tab attendee list and event chat media (same bytes-upload rule).
- **Action:** fix the 2 `File()` sites, gate the scanner, keep the map placeholder.

### 13.3 COMMUNITIES — parity status: ⚠️ upload + routing (Core sub-features work)
- **Screens:** `communities_screen`, `community_detail_screen` (tabbed: Chat / Tips / Announcements / Events), `create_community_screen`. Plus roles/moderation, join-approval, community events, translation — all **Firestore/Cloud-Function driven → work on web** once media upload is fixed.
- **🔴 Web-breaking upload (VERIFIED):** `create_community_screen.dart:712` `File(picked.path)` (cover image) + `:724` `putFile(...)` — **unguarded**, crashes when a web user creates a community with a cover image. → apply the 13.0 fix.
- **`community_detail_screen`:** no direct `File()` — the tabbed Chat/Tips/Announcements post paths reuse the shared chat/media widgets; ensure any image attach there also goes through the bytes branch (covered by the §3 chat-media guard).
- **🟡 Routing:** reconcile the `/community` vs `/communities` naming (§7) so the manifest shortcut + deep links resolve. Verify moderation actions (approve/kick/role change) and translation toggle on web — they are callable/Firestore, so expected ✅, but smoke-test.
- **Action:** fix the create-community upload, reconcile the route name, smoke-test moderation + translation on web.

### 13.4 BUSINESS — parity status: 🔴 was absent from the plan; now specified
Business is a full 3.0.0 pillar (9 screens) that §8 never covered. Screens: `business_hub`, `business_account`, `business_storefront`, `storefront_editor`, `business_events`, `business_leads`, `followers`, `promote`, `business_verification_request`.

- **✅ Payments — NO new work (VERIFIED):** `promote_screen` spends **GreenGoCoins, not real money** ("in-economy, never real money"; routes to `CoinShopScreen`). Buying coins already Stripe-branches on web (§4). So business promotion works on web **for free** — no separate Stripe path. *(This corrects the earlier worry that promote needed its own web payment path.)*
- **🔴 Web-breaking uploads (VERIFIED, unguarded):**
  - `storefront_editor_screen.dart:148` — `photo: File(image.path)` (storefront gallery image).
  - `business_verification_request_screen.dart:104` — `ref.putFile(File(picked.path))` (verification document). *(No ML Kit here — it's a plain document upload, so the bytes fix fully solves it; verification stays available on web.)*
  - → apply the 13.0 bytes-upload fix to both.
- **Rest:** `business_hub`, `business_account`, `business_storefront` (view), `business_events`, `business_leads`, `followers` → Firestore/read paths, work on web. `business_events` overlaps with §13.2 (same event-photo upload rule if it creates events).
- **Action:** fix the 2 `File()` sites; add the Business rows to the parity matrix (below); confirm the "business membership exclusion" server rule doesn't behave differently on web (it's server-side → same for web).

### 13.5 Consolidated web-breaking upload sites (the P0 fix-list for these 4 areas)
| File:line | Feature | Call | Fix |
|---|---|---|---|
| `events_screen.dart:3058` | Events (create) | `File(x.path)` main photo | 13.0 bytes branch |
| `events_screen.dart:3067` | Events (create) | `File(x.path)` extra photos | 13.0 bytes branch |
| `create_community_screen.dart:712/724` | Communities (create) | `File(picked.path)` + `putFile` cover | 13.0 bytes branch |
| `storefront_editor_screen.dart:148` | Business | `File(image.path)` gallery | 13.0 bytes branch |
| `business_verification_request_screen.dart:104` | Business | `putFile(File(picked.path))` doc | 13.0 bytes branch |

*(These are additional to the chat/profile/stories sites already in §3.2. Explore contributes none.)*

### 13.6 Amended feature-parity matrix (replaces/extends §8 for these areas)
| Feature | Web target | Fix required |
|---|---|---|
| Explore carousel / Network / Universal search | ✅ full | responsive only |
| Explore QR hub (scan) | ❌ mobile-only | gate `!kIsWeb`, QR display OK |
| Events browse / attendance / chat / ticket | ✅ full | ticket QR displays fine |
| Events **create** (photos) | ⚠️ fix | 2 `File()` → bytes |
| Events map picker | ⚠️ degraded | `WebMapPlaceholder` (kept) |
| Events check-in scanner | ❌ mobile-only | gate `!kIsWeb` |
| Communities view / Chat/Tips/Announcements / moderation / roles / join-approval / translation | ✅ full | smoke-test; media via chat guard |
| Communities **create** (cover) | ⚠️ fix | `File()` → bytes |
| Community routing `/community(ies)` | ⚠️ fix | reconcile name + deep route |
| Business hub / account / storefront view / events / leads / followers | ✅ full | Firestore reads |
| Business **promote** (boost) | ✅ full | coins→Stripe seam (already) |
| Business storefront **editor** (upload) | ⚠️ fix | `File()` → bytes |
| Business **verification** (doc upload) | ⚠️ fix | `File()` → bytes (no ML Kit) |

### 13.7 Amended rollout — where this parity work lands
- **P0 (Build & audit):** add the **5 upload sites in §13.5** to the `dart:io` audit fix-list — these are the concrete web-reachable crashes.
- **P1 (Auth + core):** add **Explore responsive** + **Communities/Business read paths** to the smoke test.
- **P2 (Payments + media):** confirm **promote=coins→Stripe** works end-to-end on web; fix the 5 upload sites so create-event / create-community / storefront / verification succeed on web.
- **P4 (Parity & degrade):** gate **QR scan** (explore hub + event check-in) mobile-only; reconcile **community route naming**; smoke-test **community moderation + translation** on web.

**Net:** with the 5 bytes-upload fixes + scanner gating + route reconciliation (all small, localized changes on top of the §5 FCM work), the web build reaches **feature parity with mobile** for Explore, Events, Communities, and Business — no screens are missing, only these upload/scanner/route seams need the web branch.

---

## 14. IMPLEMENTATION STATUS (in progress)

Increment 1 — landed in the working tree, `flutter analyze` clean on all changed files, mobile behavior unchanged:

**✅ Done**
- **Reusable web-safe media seam** — `lib/core/platform/web_media.dart`: `WebMedia.uploadXFile(ref, xfile)` (web→`putData(bytes)`, mobile→`putFile`) + `WebMedia.imageProviderFor(xfile)` (web→`NetworkImage(blob)`, mobile→`FileImage`). Use this everywhere instead of `File(xfile.path)`.
- **Community create-cover upload** — `create_community_screen.dart` now holds an `XFile` (not `File`), previews via the seam, uploads via the seam; `dart:io` import removed. No longer crashes on web.
- **Business verification doc upload** — `business_verification_request_screen.dart` uploads via the seam; `dart:io` removed. Verification stays available on web (no ML Kit involved — it's a plain document upload).
- **FCM web push wiring** — `web/firebase-messaging-sw.js` (public web config), `lib/core/config/web_push_config.dart` (VAPID constant, env-overridable, graceful-skip when empty), `getFCMToken()` passes `vapidKey` on web, `PushNotificationService.initialize()` now wires foreground/tap/refresh listeners on web instead of early-returning. The existing `main.dart` token-save flow registers web tokens automatically once the VAPID key is set.
- **Event check-in scanner** — web fallback screen (mobile-only camera) instead of a broken camera view; new l10n key `eventScanUseMobileApp` added to `app_en.arb` + `flutter gen-l10n` run.

**⏳ Remaining (needs a decision or a bigger refactor)**
- 🔴 **Profile-photo pipeline** (shared by `storefront_editor`, `photo_management`, onboarding **and** event-create photos via `ds.uploadPhoto(File)`): `File`-typed through event→bloc→usecase→repo→datasource **and** `Image.file` previews **and** native **ML Kit** face/NSFW validation. Making it web-safe needs (a) an `XFile`/bytes pipeline refactor and (b) a **decision: skip face validation on web, or move it server-side?** → this blocks event-create photos + storefront gallery on web. **Needs user input.**
- 🟡 **Explore QR-hub scan button** — gate the scan sub-action `!kIsWeb` (QR display already fine). Not yet done.
- 🟡 **Set the real VAPID key** — generate in Firebase Console → Cloud Messaging → Web Push certificates, then set `WEB_PUSH_VAPID_KEY` (or paste into `web_push_config.dart`). Until then web push stays inactive (build still runs).
- 🟡 **Deep-link route parsing** (`/u/*`, `/e/*`), **iOS PWA splash images**, **Explore responsive pass**, **`/community` vs `/communities` route reconcile** — per §5–§7 & §13.
- **Verify:** `flutter build web --release` end-to-end + preview-channel smoke test (analyze passes, but a full web build/runtime pass is still pending).

---

*Investigation grounded in: `GreenGo-App-Flutter` (local, v3.0.0+101) and `GreenGo-Dating-App/greengo-app-flutter-web` (cloned, v1.8.0+53). No secrets included; keys reside in `E:\Projects\GreenGo\credentials\greengo-credentials.txt` and Firebase/Functions config. No commits or pushes were made in either repo. §13 amplified from a screen-level audit; upload sites verified by line number.*
