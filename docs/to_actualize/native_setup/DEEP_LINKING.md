# GreenGo — Deep Linking (Universal Links · App Links · Custom Scheme)

How GreenGo's links open the app on iOS and Android, and how to finish + verify them.
Client: `app_links ^6.3.2` in `lib/core/services/deep_link_service.dart`, wired in `lib/main.dart`. Domain: `greengo-chat.web.app`.

> GreenGo supports **three** link kinds. Get them straight — they fail for different reasons:
> | Kind | Example | Platform | Needs verification file |
> |---|---|---|---|
> | **Universal Link** | `https://greengo-chat.web.app/u/123` | iOS | AASA (Team ID) |
> | **App Link** | `https://greengo-chat.web.app/e/456` | Android | assetlinks.json (SHA-256) |
> | **Custom scheme** | `greengo://u/123`, `greengo://e/456` | both | none (works for testing) |

**Routes today:** `/u/{userId}` → user profile · `/e/{eventId}` → event. (Both https and `greengo://` forms.)

---

## 🔴 0. Do this first — fill the two verification files
Both currently hold placeholders, so https links fall back to the browser:

- `web/.well-known/apple-app-site-association` → replace `TODO_FILL_APPLE_TEAM_ID` with your **Apple Team ID**:
  ```json
  { "applinks": { "apps": [], "details": [
    { "appID": "ABCDE12345.com.greengochat.greengochatapp", "paths": ["/u/*", "/e/*"] } ] } }
  ```
- `web/.well-known/assetlinks.json` → replace `TODO_FILL_RELEASE_KEYSTORE_SHA256_FINGERPRINT` with the **signing cert SHA-256** (see §4).

Then **redeploy hosting** (§5). Apple caches AASA on its CDN — allow time or use developer mode (§6).

---

## 1. iOS — Universal Links
Already wired: `applinks:greengo-chat.web.app` in `ios/Runner/Runner.entitlements` **and** `RunnerRelease.entitlements`.

To complete:
1. **Apple Developer:** enable the **Associated Domains** capability on the App ID `com.greengochat.greengochatapp`; confirm it's in the provisioning profile. In Xcode it's already reflected by the entitlements.
2. **AASA hosted** at `https://greengo-chat.web.app/.well-known/apple-app-site-association`:
   - Served as `application/json` (firebase.json already sets this header) ✅
   - **No redirect**, valid HTTPS/TLS, HTTP 200 ✅ (Firebase Hosting)
   - `appID` = `TeamID.bundleID`, `paths` = `["/u/*","/e/*"]`
3. Universal Links open the app only from a **real tap** (a link in Messages, Notes, Safari results) — **not** by typing the URL in Safari's address bar.

## 2. Android — App Links
Already wired in `AndroidManifest.xml`: an `autoVerify="true"` intent-filter for `https` host `greengo-chat.web.app`, plus a custom-scheme filter for `greengo://u` and `greengo://e`.

To complete:
1. **assetlinks.json hosted** at `https://greengo-chat.web.app/.well-known/assetlinks.json` (Content-Type header already set) with the **correct SHA-256** (§4).
2. On install, Android's auto-verification checks assetlinks; if it matches, https links open the app directly. Verify with §6.
3. The custom scheme (`greengo://…`) works regardless of assetlinks — handy for testing before verification is live.

## 3. Custom scheme (both platforms)
- iOS: `CFBundleURLSchemes = greengo` (URL name `com.greengochat.greengochatapp.deeplink`) in `Info.plist` ✅
- Android: intent-filter for `greengo://u`, `greengo://e` ✅
- Use for internal links, QR codes, and testing. Downside vs https links: any app can claim a custom scheme, and it won't open a web fallback — so prefer https Universal/App Links for shared/marketing links.

## 4. Getting the SHA-256 (the Android blocker)
- **Upload keystore** (`greengo-release.keystore` at repo root):
  ```bash
  keytool -list -v -keystore greengo-release.keystore -alias <your-alias>   # SHA256 line
  ```
- **⚠️ With Play App Signing (you use it):** the fingerprint Android verifies against is **Google's re-signed cert**, not your upload key. Copy it from **Play Console → your app → Setup → App integrity → App signing key certificate → SHA-256**. Put **that** in assetlinks.json.
- Add your **debug** SHA-256 too if you want App Links to verify on debug builds during testing (assetlinks accepts multiple fingerprints in the array).

## 5. Hosting & deploy
`firebase.json` (target `app`) already handles the web side:
- Rewrites `/u/**` → `/u/index.html`, `/e/**` → `/e/index.html`, `**` → `/index.html` (so the domain returns a real page for links, and the PWA can route them too).
- Correct `Content-Type: application/json` for both `.well-known` files.

`flutter build web` copies everything under `web/` (including `web/.well-known/`) into `build/web/`. Deploy:
```bash
flutter build web --release
# proxy workaround for this machine's corp TLS (see project memory):
NODE_TLS_REJECT_UNAUTHORIZED=0 firebase deploy --only hosting:app
```
After deploy, confirm both files are live and JSON:
```bash
curl -sI https://greengo-chat.web.app/.well-known/apple-app-site-association   # 200 + application/json, no redirect
curl -s  https://greengo-chat.web.app/.well-known/assetlinks.json
```

## 6. Testing & verification
**Android:**
```bash
# App Link (https)
adb shell am start -a android.intent.action.VIEW -d "https://greengo-chat.web.app/u/123"
# Custom scheme
adb shell am start -a android.intent.action.VIEW -d "greengo://e/456"
# Check verification status
adb shell pm get-app-links com.greengochat.greengochatapp
```
Also use Google's **Statement List Generator and Tester** (Digital Asset Links API) on the assetlinks URL.

**iOS (real device):**
- Put `https://greengo-chat.web.app/u/123` in Notes/Messages and **tap** it.
- Custom scheme in Simulator: `xcrun simctl openurl booted "greengo://u/123"`.
- Validate AASA with Apple's **App Search API validation** / an AASA validator; on device use developer mode: add `applinks:greengo-chat.web.app?mode=developer` to entitlements for a debug build to bypass the CDN cache during testing.

## 7. In-app handling (`deep_link_service.dart`)
Handle both cold start and warm links, then route:
```dart
final appLinks = AppLinks();
final initial = await appLinks.getInitialLink();      // cold start
if (initial != null) _route(initial);
appLinks.uriLinkStream.listen(_route);                // while running

void _route(Uri uri) {
  final seg = uri.pathSegments;                         // https: [u,123] | scheme greengo://u/123 → host 'u'
  final kind = uri.scheme == 'greengo' ? uri.host : (seg.isNotEmpty ? seg[0] : '');
  final id   = uri.scheme == 'greengo' ? seg.first    : (seg.length > 1 ? seg[1] : '');
  switch (kind) {
    case 'u': _nav.pushProfile(id); break;
    case 'e': _nav.pushEvent(id);   break;
  }
}
```
Keep this the **same router** notifications use (see [PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md) §5) so a link and a notification tap land identically.

## 8. Adding a new deep-link type (e.g. `/g/{groupId}`)
1. AASA `paths` += `"/g/*"` and assetlinks stays as-is (host-level).
2. Android manifest: add `greengo://g` data + the https path is already covered by the host filter.
3. `firebase.json`: add rewrite `/g/**` → `/g/index.html` (and a hosted fallback page).
4. `deep_link_service.dart`: add a `case 'g':` route.
5. Redeploy hosting; re-test per §6.

## 9. Common pitfalls
| Symptom | Cause / fix |
|---|---|
| https link opens browser, not app | AASA/assetlinks still `TODO`, wrong Team ID/SHA, or Apple CDN not refreshed. |
| Android App Link not verifying | assetlinks uses upload-key SHA instead of **Play re-signed** SHA; check `pm get-app-links`. |
| Works from Notes, not Safari address bar (iOS) | Expected — UL need a real tap, not manual URL entry. |
| Link opens home screen | `getInitialLink()` not handled on cold start, or route parsing wrong for scheme vs https. |
| AASA "invalid" | Served with a redirect or wrong Content-Type, or `appID` format wrong (must be `TeamID.bundleID`). |

*Companion: [PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md) · deploy note uses the `NODE_TLS_REJECT_UNAUTHORIZED=0` workaround from project memory.*
