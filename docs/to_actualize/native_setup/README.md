# GreenGo — Native Setup: Push Notifications & Deep Links

Practical setup + verification guides for the two native integrations, grounded in the actual repo wiring.
**App:** GreenGo · `com.greengochat.greengochatapp` · v3.0.0+101 · Firebase project `greengo-chat` · Domain `greengo-chat.web.app` · Date: 2026-07-13

## Documents
- **[PUSH_NOTIFICATIONS.md](./PUSH_NOTIFICATIONS.md)** — native push for iPhone (APNs) and Android (FCM), token handling, sending, tap→route.
- **[DEEP_LINKING.md](./DEEP_LINKING.md)** — Universal Links (iOS), App Links (Android), and the `greengo://` custom scheme.

## What's already wired (don't rebuild it)
| Piece | Where |
|---|---|
| Messaging + local notifications | `firebase_messaging ^15.0.0`, `flutter_local_notifications ^18.0.1` (pubspec) |
| Push service | `lib/core/services/push_notification_service.dart` |
| Deep-link service | `lib/core/services/deep_link_service.dart` (`app_links ^6.3.2`), wired in `lib/main.dart` |
| iOS push capability | `aps-environment` in `ios/Runner/Runner.entitlements` + `RunnerRelease.entitlements` |
| iOS Universal Links | `applinks:greengo-chat.web.app` in both entitlements; custom scheme `greengo` in `Info.plist` |
| Android App Links + scheme | `AndroidManifest.xml`: `autoVerify` https intent-filter + `greengo://u`, `greengo://e` |
| Link verification files | `web/.well-known/apple-app-site-association`, `web/.well-known/assetlinks.json` |
| Hosting | `firebase.json` target `app`: rewrites `/u/**`,`/e/**`, correct `Content-Type` headers for the two files |
| Server send | `functions/src/notifications/pushNotificationTriggers.ts`, `functions/src/group_chat/fanout.ts` |

## 🔴 The two blockers to fix first (both are TODO placeholders in the repo)
1. **`web/.well-known/apple-app-site-association`** contains `TODO_FILL_APPLE_TEAM_ID.com.greengochat.greengochatapp` → replace `TODO_FILL_APPLE_TEAM_ID` with your **Apple Team ID** (App Store Connect → Membership).
2. **`web/.well-known/assetlinks.json`** contains `TODO_FILL_RELEASE_KEYSTORE_SHA256_FINGERPRINT` → replace with the **SHA-256 of the app-signing cert** (see DEEP_LINKING.md §4 — with Play App Signing this is Google's cert, not your upload key).

Until these are real values, **iOS Universal Links and Android App Links will silently fall back to the browser.** The `greengo://` custom scheme works without them (good for testing), but https links won't open the app.

*Linked from [`../../INDEX.md`](../../INDEX.md).*
