# GreenGo — Push Notifications Runbook (iPhone · Android · Web)

Concrete, do-this-in-order guide to finish and verify FCM push on all three platforms.
Backend: **Firebase Cloud Messaging (FCM)** + Cloud Functions. Client: `firebase_messaging` + `flutter_local_notifications` in `lib/core/services/push_notification_service.dart`, token/permission logic in `lib/features/notifications/data/datasources/notification_remote_datasource.dart`.

## Your values
| Thing | Value |
|---|---|
| Firebase project | `greengo-chat` |
| Android app ID | `1:666632803027:android:bcf985e83c267f199aba26` |
| Web app ID | `1:666632803027:web:36045de58c58a60f9aba26` |
| Apple Team ID | `9885DQB8RF` · Bundle `com.greengochat.greengochatapp` |
| Android notification channel (primary) | `greengo_notifications` |
| FCM token storage | `profiles/{uid}.fcmToken` **and** `users/{uid}.fcmToken` (+ `fcmTokenUpdatedAt`) |
| Web VAPID key | build-time `--dart-define=WEB_PUSH_VAPID_KEY=<key>` (see §3) |

## How it flows
```
 Event (new message / RSVP / announcement / like …)
   → Cloud Function (functions/src/notifications/*, communities/*Fanout.ts, group_chat/fanout.ts)
   → admin.messaging().sendEachForMulticast({ tokens, notification, data, android, apns })
   → FCM ─► Android (direct)   ─► APNs ─► iPhone   ─► Web push (service worker)
   → app: background/terminated = OS shows it · foreground = in-app sound only (no banner, by design)
   → tap = push_notification_service._navigateFromNotificationData(data) → deep-navigate
```

---

## Current status (verified 2026-07-17)
| Item | State |
|---|---|
| Android `google-services.json` present (`android/app/`) | ✅ |
| `POST_NOTIFICATIONS` permission declared (manifest) | ✅ |
| Manifest `default_notification_channel_id = greengo_notifications` | ✅ |
| Client creates channel `greengo_notifications` | ✅ |
| iOS `aps-environment` (Runner=development, RunnerRelease=production) | ✅ |
| Top-level background handler (`@pragma('vm:entry-point')`) | ✅ |
| Token save + `onTokenRefresh` upsert (profiles + users) | ✅ |
| Tap routing (cold/background/foreground → deep-nav) | ✅ wired, comprehensive |
| Web: FCM service worker (`web/firebase-messaging-sw.js`) + VAPID-gated `getToken` | ✅ present |
| **iOS APNs Auth Key (.p8) uploaded to Firebase** | ⚠️ **VERIFY — the step people miss** (see §2) |
| **Client registers ALL server channels** | 🔴 **gap** — only `greengo_notifications`; server also uses `greengo_broadcasts`, `bundled_notifications`, `video_calls`, `default` (see §1.4) |
| **Status-bar icon** | 🟡 uses `@drawable/ic_launcher_foreground` (colored) → shows as a white square; add a dedicated white icon (§1.5) |
| Web VAPID key actually set at build | ⚠️ empty unless `--dart-define` passed → web push inactive until then (§3) |

**Bottom line:** Android + iOS client + server are wired. The three things to close: (a) upload the **APNs .p8** to Firebase for iPhone delivery, (b) **register the extra channels** so broadcast/bundled pushes aren't dropped on Android 8+, (c) supply the **web VAPID key** if you want web push. Everything below is those, in order.

---

## 1. Android (FCM)

### 1.1 `google-services.json` ✅
Present at `android/app/google-services.json` (gitignored — restore from secrets; project `greengo-chat`). Google Services Gradle plugin applied.

### 1.2 Runtime permission (Android 13+) ✅ (verify UX)
`POST_NOTIFICATIONS` is declared. `NotificationRemoteDataSource.requestPermission()` calls `messaging.requestPermission(alert/badge/sound)` which triggers the OS prompt on Android 13+. Call it **after a relevant screen** (not cold on launch) for a better grant rate — confirm where it's invoked in your onboarding flow.

### 1.3 Primary channel ✅
`push_notification_service.dart` creates `greengo_notifications` (Importance.high, sound, vibration) and the manifest names it as the FCM default. Matches what the main triggers send.

### 1.4 🔴 Register the OTHER channels the server uses
The server sends on **more channels than the client creates**. On Android 8+ a notification to a **non-existent channel can be silently dropped**. Server currently uses:
`greengo_notifications` ✅ · `greengo_broadcasts` ❌ · `bundled_notifications` ❌ · `video_calls` ❌ (video calling disabled) · `default` ❌.

**Fix:** in `push_notification_service.dart initialize()`, create every channel you actually send to. Example:
```dart
const channels = [
  AndroidNotificationChannel('greengo_notifications', 'GreenGo Notifications',
      description: 'Messages, likes, events', importance: Importance.high),
  AndroidNotificationChannel('greengo_broadcasts', 'Announcements',
      description: 'Broadcasts from GreenGo', importance: Importance.high),
  AndroidNotificationChannel('bundled_notifications', 'Activity summary',
      description: 'Bundled activity', importance: Importance.defaultImportance),
  // add 'video_calls' only if/when video calling is re-enabled
];
final android = _localNotifications.resolvePlatformSpecificImplementation<
    AndroidFlutterLocalNotificationsPlugin>();
for (final c in channels) { await android?.createNotificationChannel(c); }
```
Then either standardize server sends on these IDs, or make sure each `channelId` the server emits has a matching channel here. (Simplest: collapse the server to `greengo_notifications` + `greengo_broadcasts`.)

### 1.5 🟡 Status-bar icon
Manifest `default_notification_icon = @drawable/ic_launcher_foreground` — a **colored** asset, so Android (which tints the status-bar icon to a solid mask) renders it as a **white square**. Add a **white, transparent-background** icon (e.g. `ic_stat_greengo`) and point the meta-data at it:
```xml
<meta-data android:name="com.google.firebase.messaging.default_notification_icon"
           android:resource="@drawable/ic_stat_greengo"/>
<meta-data android:name="com.google.firebase.messaging.default_notification_color"
           android:resource="@color/notification_green"/>
```

### 1.6 Foreground behavior (by design)
Android does not show a system notification while the app is foregrounded. GreenGo intentionally shows **no banner in foreground** — it plays an in-app sound (`AppSoundService`) and the in-app notifications list updates. Nothing to change unless you *want* foreground banners (then render via `flutter_local_notifications` in `_handleForegroundMessage`).

---

## 2. iPhone (APNs) — the one manual step that's easy to miss

The push capability is already set: `aps-environment` = `development` (Runner) / `production` (RunnerRelease). What remains is the **Apple ↔ Firebase link**.

**Step 2.1 — Confirm Xcode capabilities.** Runner target → Signing & Capabilities → **Push Notifications** present, **Background Modes → Remote notifications** on. (They back the entitlement above.)

**Step 2.2 — Create an APNs Auth Key (.p8).**
[developer.apple.com](https://developer.apple.com/account/resources/authkeys/list) → Certificates, Identifiers & Profiles → **Keys** → **+** → name it, enable **Apple Push Notifications service (APNs)** → **Continue → Register → Download** the `.p8` (⚠️ downloadable **once**). Note the **Key ID** and your **Team ID `9885DQB8RF`**.

**Step 2.3 — Upload to Firebase.**
[Firebase Console](https://console.firebase.google.com/project/greengo-chat/settings/cloudmessaging) → Project `greengo-chat` → **Project settings → Cloud Messaging → Apple app configuration → APNs Authentication Key → Upload** → attach the `.p8`, enter **Key ID** + **Team ID `9885DQB8RF`**. *One key covers dev + prod for all your apps.*

**Step 2.4 — Permission on device.** `requestPermission()` (already implemented) shows the iOS system prompt; FCM maps the APNs token to an FCM token automatically.

**Step 2.5 — Test on a REAL iPhone.** Treat a physical device as required (Simulator push is limited/newer-only).

> Until 2.2–2.3 are done, **iPhones receive no push** even though the code is correct. This is almost always the missing piece — verify it in the Firebase console.

---

## 3. Web push (optional — currently inactive)

Web delivery needs a VAPID key at **build time**; without it `getFCMToken()` returns null and web push degrades gracefully.

**Step 3.1 — Generate the key.** Firebase Console → project `greengo-chat` → **Cloud Messaging → Web configuration → Web Push certificates → Generate key pair** → copy the **public key**.

**Step 3.2 — Build web with the key.**
```bash
flutter build web --release --dart-define=WEB_PUSH_VAPID_KEY=<public-key>
NODE_TLS_REJECT_UNAUTHORIZED=0 firebase deploy --only hosting:app --project greengo-chat
```
`web/firebase-messaging-sw.js` (service worker, already present) handles background/closed-tab notifications; foreground uses the same `onMessage` listeners. Verify `WebPushConfig.isConfigured` is true in the built app.

> Wire this into your CI (Codemagic `web-release` job) as a `--dart-define` so every web build ships push, not just local builds.

---

## 4. Token management (implemented — how it works)
- On login / permission grant → `getFCMToken()` → `saveFCMToken()` writes `{fcmToken, fcmTokenUpdatedAt}` (merge) to **both** `profiles/{uid}` and `users/{uid}`. Cloud Functions read `profiles/{uid}.fcmToken`.
- `onTokenRefresh` → `_handleTokenRefresh` upserts the rotated token to both docs.
- **On logout / account deletion → delete the token** so pushes stop on that device. *(Verify this is called in your sign-out + delete flows — it's the usual leak.)*
- On send failure (`messaging/registration-token-not-registered`) → remove the dead token server-side. *(Add to the fanout error handling if not present.)*

> This is a **single-token-per-user** model. If a user has multiple devices, the last one to write wins. If you need multi-device push, migrate to a token **array/subcollection** and send to all.

---

## 5. Sending from Cloud Functions (pattern in use)
```ts
await admin.messaging().sendEachForMulticast({
  tokens,                                    // recipient's stored FCM token(s)
  notification: { title, body },             // OS-displayed when backgrounded
  data: { action: 'event', eventId },        // read on TAP for routing — strings only
  android: { priority: 'high',
             notification: { channelId: 'greengo_notifications' } },  // must match a registered channel (§1.4)
  apns: { payload: { aps: { sound: 'default', badge: 1, 'content-available': 1 } } },
});
```
- **`notification` vs `data`:** `notification` auto-displays when backgrounded; **`data`** carries the routing keys read on tap. Include both; data values must be **strings**.
- `sendEachForMulticast` handles ≤500 tokens/call — chunk beyond that (done in the fanout files).
- Keep the **`data` keys aligned with the tap router** (§6): `action`/`type` + one of `eventId`, `communityId`, `groupId`, `conversationId`, `actorId`/`profileId`, `matchId`.

---

## 6. Tap → deep-navigate (implemented)
`_navigateFromNotificationData(data)` handles all three entry points via the same router (cold start `getInitialMessage`, background `onMessageOpenedApp`, foreground local-notif tap). It maps:
| data | opens |
|---|---|
| `type=newMessage` + `conversationId` (or `newMatch`+`matchId`) | Chat |
| `support_message` + `conversationId` | Support chat |
| `eventId` / `action=event` | Event detail |
| `communityId` / `action=community` | Community detail |
| `groupId` / `action=group` | Group chat |
| `actorId`/`profileId`/`likerId`/… (like, superLike, profileView, business_*) | Profile |
Keep this identical to `deep_link_service.dart` so a push tap and a deep link land on the same screen.

---

## 7. Testing
- **Fastest smoke test:** Firebase Console → **Messaging → Send test message** → paste an FCM token (log it from `getFCMToken()` on a real device).
- **Scripted:** FCM **HTTP v1 API** (OAuth via service account; legacy server-key API is deprecated).
- **Verify the matrix:** backgrounded → OS notification appears · tap → correct screen · foreground → in-app sound (no banner, expected) · iOS → badge/sound · Android → correct icon (not a white square once §1.5 done) · each **channel** displays (§1.4).
- **Android verify channels:** `adb shell dumpsys notification | grep -A2 greengo` (or open App info → Notifications → categories) to confirm each channel exists on the device.

---

## 8. Troubleshooting
| Symptom | Cause / fix |
|---|---|
| **iPhone gets no push** | APNs `.p8` not uploaded to Firebase (§2.3), or Push capability off, or testing on Simulator. |
| Android 13+ gets no push | `POST_NOTIFICATIONS` runtime permission never granted (§1.2). |
| **Some Android pushes never show (e.g. broadcasts)** | Sent on a channel the client didn't create (§1.4). Register it. |
| Notification icon is a white square | Icon isn't white/transparent-alpha; add `ic_stat_greengo` (§1.5). |
| No banner in foreground | Expected — GreenGo shows in-app sound only in foreground (§1.6). |
| Data-only message ignored when app killed | Needs `content-available:1` + `priority high`; background handler must be top-level (it is). |
| Tap opens home, not the target | `data` keys missing or not matching the §6 router, or `getInitialMessage()` not handled (it is). |
| Web gets no push | VAPID key not passed at build (`--dart-define`, §3) or SW not registered. |
| User keeps getting pushes after logout | Token not deleted on logout/delete (§4). |
| Token overwritten across devices | Single-token model (§4) — expected; migrate to multi-token if needed. |

---
*Verified against the repo on 2026-07-17. Companion: `DEEP_LINKING.md` — the push tap router and the deep-link router must stay identical so links and notifications land on the same screen.*
