# GreenGo — Android Push Notifications Setup (FCM)

**Scope:** Everything **outside the code** needed for Android push: Firebase/FCM linkage, the notification channel + status-bar icon, the Android-13+ runtime permission, server sending, and testing. The Flutter client is **already wired** (`push_notification_service.dart`, manifest permissions/meta) — this guide connects it and verifies end-to-end.

## What's already done in the repo (don't redo)

| Piece | Where | Status |
|---|---|---|
| FCM handlers + channel `greengo_notifications` (Importance.high) | `push_notification_service.dart` | ✅ |
| `POST_NOTIFICATIONS` permission | `AndroidManifest.xml` (line ~28) | ✅ |
| `default_notification_channel_id = greengo_notifications` | `AndroidManifest.xml` (~98) | ✅ |
| `default_notification_icon = @drawable/ic_launcher_foreground` | `AndroidManifest.xml` (~104) | ⚠️ full-color icon — see §4 (white-square fix) |
| `firebase_messaging` plugin | `pubspec.yaml` | ✅ |
| `google-services.json` | `android/app/` | ⚠️ gitignored — must be present locally (see §1) |

**Project facts:** applicationId `com.greengochat.greengochatapp` · Firebase `greengo-chat` (#666632803027) · minSdk 24.

> Android FCM needs **no APNs-style key** — delivery works as soon as `google-services.json` is in place and the app is registered in Firebase. Most of this guide is verification + the two easy-to-miss items (Android 13 permission, the status-bar icon).

---

## Step 1 — Confirm FCM linkage (`google-services.json`)

1. **Firebase Console → `greengo-chat` → Project Settings → Your apps → Android** (`com.greengochat.greengochatapp`).
2. Download **`google-services.json`** and place it at `android/app/google-services.json` (it's gitignored — keep it out of commits; per your build note it's one of the 3 restored configs).
3. Confirm the Google Services Gradle plugin is applied (it already builds, so this is in place). A successful `flutter build apk` implicitly validates the JSON matches the applicationId.

No "server key" is required for the modern **FCM v1** API used by the Firebase Admin SDK in your Cloud Functions.

---

## Step 2 — The notification channel

FCM on Android **O+ (26+)** requires a channel. The app creates `greengo_notifications` at startup (`push_notification_service.dart`), and the manifest sets it as the default for messages that arrive without an explicit channel.

- Channel id **must match** in three places (they already do): the Dart `AndroidNotificationChannel`, the manifest `default_notification_channel_id`, and any `android.notification.channel_id` your server sends.
- Importance is **high** → heads-up banners. If you change importance later, you must **uninstall/reinstall** (channel settings are locked after first creation).

---

## Step 3 — Android 13+ runtime permission (`POST_NOTIFICATIONS`)

Since Android 13 (API 33), notifications require a **runtime permission** — the manifest declaration alone is not enough.

- The app requests it via the notification-permission flow (`request_notification_permission` usecase / `firebase_messaging` `requestPermission`).
- **Verify on a real Android 13+ device / emulator:** fresh install → at the point the app asks, the system dialog *"Allow GreenGo to send you notifications?"* appears → **Allow**.
- If the user denied it earlier: Settings → Apps → GreenGo → Notifications → enable. (Android stops re-prompting after denials.)
- On Android ≤12 the permission is auto-granted (no dialog) — this is expected.

---

## Step 4 — Fix the status-bar icon (recommended)

**Problem:** `default_notification_icon` currently points at `@drawable/ic_launcher_foreground`, a **full-color** adaptive-icon layer. Android renders the small status-bar icon as a **silhouette using only the alpha channel** — a full-color image shows up as a **solid white square** (or a muddy blob) in the status bar.

**Fix (asset + one manifest line — apply if you see a white square):**
1. Create a **monochrome, transparent** icon: white/opaque GG glyph on a fully transparent background (only alpha matters). Export as `ic_stat_greengo.png` at:
   - `drawable-mdpi` 24×24, `drawable-hdpi` 36×36, `drawable-xhdpi` 48×48, `drawable-xxhdpi` 72×72, `drawable-xxxhdpi` 96×96.
   - (Android Studio → *Image Asset → Notification Icons* generates all sizes correctly.)
2. Point the manifest at it:
   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_icon"
       android:resource="@drawable/ic_stat_greengo" />
   ```
3. (Optional) set an accent color for the icon tint:
   ```xml
   <meta-data
       android:name="com.google.firebase.messaging.default_notification_color"
       android:resource="@color/ic_launcher_background" />
   ```
> This is the single most common "my Android notifications look broken" cause. The gold GG can't be the status-bar icon as-is — it must be a flat alpha silhouette. The *large* icon / big-picture can stay full color.

---

## Step 5 — Send a test push

**A. Firebase Console (quickest):**
1. Console → **Messaging → New campaign → Notification** (or **Send test message**).
2. Get the device **FCM token**: `FirebaseMessaging.instance.getToken()` (logged as `[FCM]`), or read `profiles/{uid}.fcmToken` in Firestore.
3. **Send test message** → paste the token → send.
4. Background the app → heads-up banner appears → tap → deep-link fires (`_navigateFromNotificationData`).

**B. Real path via Cloud Functions:**
Your `functions/src/**` already sends through `admin.messaging()` (chat, `eventFanout`, `announcementFanout`, reminders…). Trigger the underlying action (e.g., message the demo user, or publish a community event) and confirm delivery.

Recommended server payload shape for Android:
```jsonc
{
  "notification": { "title": "…", "body": "…" },          // shown by OS when backgrounded
  "data": { "type": "newMessage", "conversationId": "…" }, // deep-link keys client expects
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "greengo_notifications",
      "sound": "default"
    }
  }
}
```

---

## Step 6 — Foreground vs background behavior (expected)

- **Background / killed:** the OS displays the `notification` payload automatically. Tapping routes via `getInitialMessage` / `onMessageOpenedApp`.
- **Foreground:** by design GreenGo does **not** show an OS banner while you're using the app — it plays an in-app sound and updates the in-app notifications list (`_handleForegroundMessage`). This is intentional (WhatsApp-style), not a bug.
- **Data-only messages** (no `notification` block) are handled by the background isolate `firebaseMessagingBackgroundHandler`; for a visible heads-up while backgrounded, always include a `notification` block.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| White square icon in status bar | Full-color `default_notification_icon` | Add monochrome `ic_stat_greengo` (§4) |
| No permission dialog on Android 13+ | Not requested, or previously denied | Trigger request flow; else enable in Settings |
| No banner while backgrounded | Data-only message (no `notification`) | Add `notification:{title,body}` server-side |
| Nothing arrives at all | `google-services.json` missing/mismatched | Re-download for `com.greengochat.greengochatapp` (§1) |
| No heads-up (only silent) | Channel importance too low / battery optimization | Channel is `high`; check device battery-optimization / Doze allowlist |
| Delivered late when idle | Doze mode batching | Use `android.priority: "high"` for time-sensitive pushes |
| Tap doesn't deep-link | `data` lacks `type`/ids | Include the keys the client routes on (`type`, `conversationId`, `eventId`, `communityId`, `groupId`) |
| Emulator gets no push | No Google Play services image | Use an emulator image **with Play Store**, signed into a Google account |

## Android push readiness checklist

- [ ] `google-services.json` present at `android/app/` (matches applicationId)
- [ ] Channel id `greengo_notifications` consistent across Dart / manifest / server
- [ ] Android 13+ permission dialog shown and allowed on a real/emulated device
- [ ] Monochrome `ic_stat_greengo` icon set (no white square) — §4
- [ ] Console test push received (background + killed) and deep-links on tap
- [ ] Cloud Functions send path verified with a real action
- [ ] Foreground behavior confirmed as in-app sound (by design)
