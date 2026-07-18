# GreenGo — Deep Linking Runbook (make it work, step by step)

Concrete, do-this-in-order guide to turn on Universal Links (iOS) + App Links (Android) for GreenGo.
Client: `app_links ^6.3.2` in `lib/core/services/deep_link_service.dart`, wired in `lib/main.dart`.

## Your values (fill these everywhere)
| Thing | Value |
|---|---|
| Apple Team ID | `9885DQB8RF` |
| Bundle ID / Android package | `com.greengochat.greengochatapp` |
| iOS **appID** (AASA) | `9885DQB8RF.com.greengochat.greengochatapp` |
| Domain | `greengo-chat.web.app` |
| Routes | `/u/{userId}` → profile · `/e/{eventId}` → event |
| Keystore | `greengo-release.keystore` (alias `greengo`, at repo root) |

## Link kinds (they fail for different reasons)
| Kind | Example | Platform | Verification file |
|---|---|---|---|
| Universal Link | `https://greengo-chat.web.app/u/123` | iOS | AASA (Team ID) |
| App Link | `https://greengo-chat.web.app/e/456` | Android | assetlinks.json (SHA-256) |
| Custom scheme | `greengo://u/123`, `greengo://e/456` | both | none (works now, for testing) |

## Current status (updated 2026-07-17 — files filled & deployed ✅)
| Item | State |
|---|---|
| iOS entitlements `applinks:greengo-chat.web.app` (Runner + RunnerRelease) | ✅ present |
| iOS `CFBundleURLSchemes = greengo` (Info.plist) | ✅ present |
| Android `autoVerify` https intent-filter + `greengo://` scheme (Manifest) | ✅ present |
| `firebase.json` serves both `.well-known` files as `application/json`, no redirect | ✅ present |
| **`web/.well-known/apple-app-site-association`** | ✅ filled `9885DQB8RF...` + **deployed** (live 200, appID confirmed) |
| **`web/.well-known/assetlinks.json`** | ✅ both fingerprints + **deployed** (Google Asset Links API returns 2 statements) |
| Apple **Associated Domains** capability on the App ID | ⚠️ still verify enabled (see Step 4) |

**Recorded fingerprints (Android assetlinks):**
- Play App Signing SHA-256: `15:FA:81:23:F1:46:48:73:0D:9B:91:6D:A1:C8:A5:4D:6E:5B:51:C1:BE:E7:73:8A:06:9F:A7:34:67:88:FA:4C`
- Upload key SHA-256: `96:C5:A7:0E:01:2B:B2:A2:13:59:0D:F7:DF:5A:A0:08:52:1C:A0:5A:BA:34:AA:74:A3:A6:38:43:E7:ED:54:05`

**Bottom line:** the app side is wired **and** both hosted verification files are now filled and live (verified against the Google Digital Asset Links API + `curl`). Remaining to actually open the app: confirm Apple **Associated Domains** capability (Step 4), then **rebuild & install** the apps and test (Steps 7–8). Apple caches AASA on its CDN — allow propagation time or use `?mode=developer` for immediate iOS testing.

> ⚠️ **Edit + deploy from ONE repo.** Both `GreenGo-App-Flutter` (canonical) and `greengo-app-flutter-web` (the mirror) contain `web/.well-known/` and deploy to the **same** hosting target `app`. Do all edits below in **`GreenGo-App-Flutter`** and deploy web from there, so the two repos can't fight over `greengo-chat.web.app`.

---

## Step 1 — Get the Android SHA-256 fingerprint(s) ✅ DONE (2026-07-17)

Android verifies App Links against the SHA-256 of the cert that **actually signed the installed APK**. Two cases — include **both** in assetlinks so links verify whether the app was installed from Play or sideloaded:

**(a) Upload/release key** (your local keystore — used for sideloaded release APKs):
```bash
keytool -list -v -keystore greengo-release.keystore -alias greengo | grep -i "SHA256:"
# (storepass is in android/key.properties)
```

**(b) Play App Signing key** (Google re-signs your AAB — this is what real Play installs verify against):
- Play Console → your app → **Setup → App integrity → App signing** → **App signing key certificate** → copy the **SHA-256**.
- You are Account Holder/Admin (Team `9885DQB8RF`) so you have access.

> If you only add the upload key, Play-store installs will NOT verify. If you only add the Play key, sideloaded release builds won't. Add both.

## Step 2 — Fill `assetlinks.json` (Android) ✅ DONE (both fingerprints, deployed)

Edit `web/.well-known/assetlinks.json` → put the fingerprint(s) from Step 1 in the array:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.greengochat.greengochatapp",
      "sha256_cert_fingerprints": [
        "AA:BB:CC:...:upload-key-sha256",
        "11:22:33:...:play-signing-sha256"
      ]
    }
  }
]
```

## Step 3 — Fill `apple-app-site-association` (iOS) ✅ DONE (Team ID `9885DQB8RF`, deployed)

Edit `web/.well-known/apple-app-site-association` → replace `TODO_FILL_APPLE_TEAM_ID` with `9885DQB8RF`:
```json
{
  "applinks": {
    "apps": [],
    "details": [
      { "appID": "9885DQB8RF.com.greengochat.greengochatapp", "paths": ["/u/*", "/e/*"] }
    ]
  }
}
```
- File name has **no extension**, served as `application/json` (already configured), no redirect.
- `appID` **must** be `TeamID.bundleID` exactly.

## Step 4 — Enable Associated Domains on the Apple App ID

[developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles → Identifiers →** `com.greengochat.greengochatapp`:
1. Check **Associated Domains** capability → Save.
2. Regenerate the **provisioning profile** if you build without automatic signing (Xcode automatic signing refreshes it for you).
3. The entitlements already declare `applinks:greengo-chat.web.app`, so nothing to change in the app — just make sure the capability is on the App ID and in the profile you ship with.

## Step 5 — Deploy the two files to hosting ✅ DONE (deployed from GreenGo-App-Flutter, 2026-07-17)

From **`GreenGo-App-Flutter`** (`flutter build web` copies `web/.well-known/` into `build/web/`):
```bash
flutter build web --release
NODE_TLS_REJECT_UNAUTHORIZED=0 firebase deploy --only hosting:app --project greengo-chat
```
(`NODE_TLS_REJECT_UNAUTHORIZED=0` is the corp-TLS/AVG workaround for this machine only.)

## Step 6 — Confirm the files are live and correct ✅ DONE (AASA 200/appID OK; Google Asset Links API = 2 statements)

```bash
# iOS AASA: expect HTTP 200, application/json, no redirect, Team ID filled
curl -skI https://greengo-chat.web.app/.well-known/apple-app-site-association | grep -i "http/\|content-type\|location"
curl -sk  https://greengo-chat.web.app/.well-known/apple-app-site-association

# Android assetlinks: expect your SHA-256(s), package com.greengochat.greengochatapp
curl -sk  https://greengo-chat.web.app/.well-known/assetlinks.json
```
Also run Google's **Statement List Tester**:
`https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://greengo-chat.web.app&relation=delegate_permission/common.handle_all_urls`

## Step 7 — Rebuild & (re)install the apps

- **Android:** `flutter build appbundle --release` → upload to Play (auto-verification runs on install). For a local test build, `flutter build apk --release` then **uninstall first** (`adb uninstall com.greengochat.greengochatapp`) before installing — a stale signature makes `adb install` fail silently.
- **iOS:** build a release/TestFlight build signed with the profile that has Associated Domains. (Universal Links do **not** work in a plain debug build unless you use developer mode — Step 8.)

## Step 8 — Test

**Android:**
```bash
adb shell am start -a android.intent.action.VIEW -d "https://greengo-chat.web.app/u/123"   # App Link
adb shell am start -a android.intent.action.VIEW -d "greengo://e/456"                        # custom scheme
adb shell pm get-app-links com.greengochat.greengochatapp                                     # expect: verified
```
**iOS (real device):**
- Paste `https://greengo-chat.web.app/u/123` into **Notes/Messages** and **tap** it (NOT Safari's address bar — UL need a real tap).
- Simulator custom scheme: `xcrun simctl openurl booted "greengo://u/123"`.
- Debug bypass of Apple's AASA CDN cache: temporarily add `applinks:greengo-chat.web.app?mode=developer` to the entitlements for a debug build, enable Developer Mode on the device.

## Step 9 — In-app routing (already implemented)

`deep_link_service.dart` handles cold start + warm links and routes to the same target as a notification tap:
```dart
final appLinks = AppLinks();
final initial = await appLinks.getInitialLink();   // cold start
if (initial != null) _route(initial);
appLinks.uriLinkStream.listen(_route);             // running

void _route(Uri uri) {
  final seg  = uri.pathSegments;
  final kind = uri.scheme == 'greengo' ? uri.host : (seg.isNotEmpty ? seg[0] : '');
  final id   = uri.scheme == 'greengo' ? seg.first : (seg.length > 1 ? seg[1] : '');
  switch (kind) { case 'u': _nav.pushProfile(id); break; case 'e': _nav.pushEvent(id); break; }
}
```

## Adding a new link type later (e.g. `/g/{groupId}`)
1. AASA `paths` += `"/g/*"` (assetlinks is host-level, no change).
2. Android manifest: add `<data android:scheme="greengo" android:host="g" />` (https host filter already covers it).
3. `firebase.json`: add rewrite `/g/**` → `/g/index.html` + a hosted fallback page.
4. `deep_link_service.dart`: add `case 'g':`.
5. Redeploy hosting; re-test (Step 8).

## Troubleshooting
| Symptom | Cause / fix |
|---|---|
| https link opens the browser, not the app | Verification file still placeholder, wrong Team ID/SHA, or Apple's AASA CDN not refreshed yet (can take hours — use `?mode=developer`). |
| Android App Link won't verify (`pm get-app-links` shows not verified) | assetlinks missing the **Play App Signing** SHA-256; add it (Step 1b). |
| Works from Notes, not Safari address bar (iOS) | Expected — Universal Links need a real tap. |
| Link opens the home screen, ignores the path | Cold-start `getInitialLink()` not handled, or scheme-vs-https parsing wrong. |
| AASA reported "invalid" | Served via redirect, wrong Content-Type, or `appID` not `TeamID.bundleID`. |
| `adb install` fails after signing change | `adb uninstall com.greengochat.greengochatapp` first. |

---
*Values verified against the repo on 2026-07-17. Companion: `PUSH_NOTIFICATIONS.md` — keep the deep-link router and the notification-tap router identical so a link and a push land on the same screen.*
