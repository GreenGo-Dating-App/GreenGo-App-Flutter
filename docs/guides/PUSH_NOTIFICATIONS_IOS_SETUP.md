# GreenGo — iOS Push Notifications Setup (APNs + FCM)

**Scope:** Everything **outside the code** needed to make push notifications work on iOS: Apple Developer portal, Firebase Console, Xcode capabilities, and testing. The Flutter client is **already wired** (`lib/core/services/push_notification_service.dart`, entitlements, `UIBackgroundModes`) — this guide connects the backend and verifies it end-to-end.

## What's already done in the repo (don't redo)

| Piece | Where | Status |
|---|---|---|
| FCM foreground/background/tap handling, token persistence, deep-link nav | `push_notification_service.dart` | ✅ |
| `aps-environment` (development) + associated domains | `ios/Runner/Runner.entitlements` | ✅ (dev) |
| Release entitlement file | `ios/Runner/RunnerRelease.entitlements` | ⚠️ verify it says `production` — see §4 |
| `UIBackgroundModes: remote-notification`, `fetch` | `ios/Runner/Info.plist` | ✅ |
| Firebase iOS app | `ios/Runner/GoogleService-Info.plist` | ⚠️ must exist (gitignored) — see §3 |
| `firebase_messaging` plugin | `pubspec.yaml` | ✅ |

**Project facts:** Bundle ID `com.greengochat.greengochatapp` · Firebase `greengo-chat` (#666632803027) · iOS min 15.5.

---

## Step 1 — Create the APNs Authentication Key (.p8)

Do this **once per Apple Developer account**. One key works for all your apps and for both sandbox + production (preferred over per-app certificates).

1. Go to **developer.apple.com → Certificates, Identifiers & Profiles → Keys**.
2. Click **➕ (Create a key)**.
3. Name: `GreenGo APNs Key`.
4. Tick **Apple Push Notifications service (APNs)**.
5. Continue → Register → **Download** the `AuthKey_XXXXXXXXXX.p8`.
   - ⚠️ You can only download it **once**. Store it in your secure credentials location (per your project standard, e.g. the GreenGo credentials file area — **never commit it**).
6. Note the **Key ID** (the `XXXXXXXXXX`) and your **Team ID** (top-right of the portal / Membership page).

---

## Step 2 — Enable Push Notifications on the App ID

1. **Identifiers → App IDs →** `com.greengochat.greengochatapp`.
2. Under **Capabilities**, tick **Push Notifications** → Save.
3. (If you use automatic signing in Xcode, provisioning profiles regenerate automatically. If manual, regenerate the profile after enabling.)

---

## Step 3 — Upload the APNs key to Firebase

1. **Firebase Console → project `greengo-chat` → Project Settings (gear) → Cloud Messaging** tab.
2. Under **Apple app configuration** for `com.greengochat.greengochatapp` → **APNs Authentication Key → Upload**.
3. Upload the `.p8`, enter the **Key ID** and **Team ID** from Step 1 → Upload.
4. Confirm the iOS app is registered in Firebase with the correct bundle ID and that `GoogleService-Info.plist` in `ios/Runner/` matches this Firebase iOS app. If missing, download it from Project Settings → Your apps → iOS → `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist` (it's gitignored).

> This single APNs key removes the old "sandbox vs production certificate" headache — Firebase uses it for both.

---

## Step 4 — Xcode capabilities & the production entitlement (the #1 trap)

Open `ios/Runner.xcworkspace` in Xcode → **Runner** target → **Signing & Capabilities**:

1. Ensure **Push Notifications** capability is present (adds/uses the entitlement).
2. Ensure **Background Modes** is present with **Remote notifications** ticked.
3. **Associated Domains** already lists `applinks:greengo-chat.web.app` — leave it.
4. **The trap:** `aps-environment` must be **`development`** for debug/TestFlight-from-Xcode and **`production`** for App Store / release. Push "works on my phone in debug but not in TestFlight/App Store" almost always means the **release** build shipped with `development`.
   - Confirm `ios/Runner/Runner.entitlements` → `aps-environment` = `development` (debug).
   - Confirm `ios/Runner/RunnerRelease.entitlements` → `aps-environment` = **`production`**.
   - Confirm the **Release** build configuration points at `RunnerRelease.entitlements` (Build Settings → *Code Signing Entitlements* → Release row).

```xml
<!-- RunnerRelease.entitlements MUST contain -->
<key>aps-environment</key>
<string>production</string>
```

> Note: APNs (real device) does **not** work on the iOS Simulator for remote pushes. Test remote push on a **physical iPhone/iPad**. (Local notifications do work on simulator.)

---

## Step 5 — Verify the permission + token flow

The client requests permission and registers the token (`FirebaseMessaging` + `push_notification_service.dart`). To verify on a **real device**:

1. Fresh install → the OS should show the **"GreenGo would like to send you notifications"** prompt at the point the app calls `requestPermission` (during onboarding/login). Tap **Allow**.
2. In Firestore, the user's `profiles/{uid}` and `users/{uid}` docs should get an `fcmToken` field (written by `_handleTokenRefresh`).
3. If the token is missing:
   - Ensure APNs token resolves first. FCM needs the APNs token before it returns an FCM token. On a real device with the key uploaded, this is automatic via the Firebase method-swizzling proxy (`FirebaseAppDelegateProxyEnabled` is not disabled → good).
   - Check the device has network + the build is signed with a profile that has Push enabled.

---

## Step 6 — Send a test push

**A. From Firebase Console (quickest):**
1. Console → **Messaging → Create your first campaign → Firebase Notification messages**.
2. **Send test message** → paste the device's **FCM token** (log it via `FirebaseMessaging.instance.getToken()` or read it from the Firestore `fcmToken`).
3. Send. Background the app first — a banner should appear. Tap it → the app should deep-link (handled by `_navigateFromNotificationData`).

**B. From your Cloud Functions (real path):**
GreenGo already sends via `admin.messaging()` in `functions/src/**` (chat, events, communities fanout). To test the real flow, trigger the underlying action (e.g., send a chat message to the demo user from another account) and confirm the push arrives.

To match the client, server payloads should include:
- `notification: { title, body }` (so iOS shows it when backgrounded), and
- `data: { type, conversationId, ... }` for deep-linking, plus
- iOS `apns: { payload: { aps: { sound: "default", badge, "content-available": 1 } } }` when needed.

> ⚠️ 4.3(b) note: the client still routes `type: newMatch/newLike/superLike`. For the App Store (de-dated) audience, make sure the **server does not send** those dating types, or that their destination is the neutral profile/connection screen. See `APPLE_4.3b_RESPONSE_KIT.md` §5.

---

## Step 7 — TestFlight validation before store submit

1. Upload the release build (`flutter build ipa --release`, see the Submission Runbook).
2. Install via **TestFlight** on a real device.
3. Confirm a push (Console test to that device's token) shows **while the app is backgrounded and killed**. This is what proves the `production` entitlement + APNs key are correct — debug-only testing hides the classic release failure.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| No permission prompt | `requestPermission` not reached, or previously denied | Reset: Settings → GreenGo → Notifications, or reinstall |
| FCM token null | APNs token not yet available / key not uploaded | Real device + key uploaded (Step 3); ensure proxy not disabled |
| Works in debug, not TestFlight/App Store | Release entitlement is `development` | Set `RunnerRelease.entitlements` → `production` (Step 4) |
| Delivered but no banner when backgrounded | Missing `notification` payload | Include `notification:{title,body}` server-side |
| Tap does nothing | `data` payload lacks `type`/ids | Add deep-link keys the client expects (`type`, `conversationId`, `eventId`, …) |
| Simulator never receives push | Remote APNs unsupported on simulator | Test on a physical device |
| Push stops after a while | Token rotated, not persisted | `onTokenRefresh` persists it (already wired) — confirm Firestore write succeeds |

## iOS push readiness checklist

- [ ] APNs `.p8` key created + stored securely (not committed)
- [ ] Push Notifications enabled on the App ID
- [ ] `.p8` uploaded to Firebase (Key ID + Team ID) for `greengo-chat`
- [ ] `GoogleService-Info.plist` present in `ios/Runner/`
- [ ] Xcode: Push Notifications + Background Modes (Remote notifications) capabilities
- [ ] `RunnerRelease.entitlements` → `aps-environment = production`
- [ ] Real-device: permission prompt shown, `fcmToken` written to Firestore
- [ ] Console test push received (background + killed)
- [ ] TestFlight build receives push
