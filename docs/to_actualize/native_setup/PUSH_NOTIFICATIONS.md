# GreenGo — Native Push Notifications (iPhone + Android)

How push works in GreenGo and how to finish/verify it on both platforms.
Backend: **Firebase Cloud Messaging (FCM)**. Client: `firebase_messaging` + `flutter_local_notifications` in `lib/core/services/push_notification_service.dart`. Server: Cloud Functions.

> FCM delivers to **Android directly** and to **iOS via Apple's APNs**. Android works once `google-services.json` is in place; **iOS additionally requires an APNs auth key uploaded to Firebase** — that's the step people miss.

---

## 0. Architecture at a glance
```
 Event (new message / event RSVP / …)
        │
   Cloud Function  (functions/src/notifications/pushNotificationTriggers.ts,
        │           functions/src/group_chat/fanout.ts)
        │  admin.messaging().sendEachForMulticast({ tokens, notification, data })
        ▼
   FCM ──► Android device (direct)
       └─► APNs ──► iPhone
        │
   push_notification_service.dart  → foreground: flutter_local_notifications
                                    → tap: read data.route/data.id → deep_link_service → navigate
```
Each user's **FCM tokens** are stored in Firestore and used as the send target.

---

## 1. Android setup (FCM)
Mostly done; verify each:

1. **`google-services.json`** present at `android/app/google-services.json` (gitignored — restore from your secrets; it's for project `greengo-chat`, appId `1:666632803027:android:bcf985e83c267f199aba26`). The Google Services Gradle plugin must be applied.
2. **Runtime permission (Android 13+):** `POST_NOTIFICATIONS` is declared in the manifest — you must also **request it at runtime**. `firebase_messaging`'s `requestPermission()` triggers the OS prompt on Android 13+. Call it after a relevant screen (not cold on launch) for a better grant rate.
3. **Notification channel:** create a default channel with `flutter_local_notifications` (Android 8+ requires a channel or notifications are silently dropped). Match the channel id used in the payload.
4. **Default icon & color (manifest `<meta-data>`):**
   ```xml
   <meta-data android:name="com.google.firebase.messaging.default_notification_icon"
              android:resource="@drawable/ic_notification"/>
   <meta-data android:name="com.google.firebase.messaging.default_notification_color"
              android:resource="@color/notification_gold"/>
   <meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
              android:value="greengo_default"/>
   ```
   Use a **white, transparent-background** icon (Android tints it) — a full-color icon renders as a white square.
5. **Foreground display:** Android does NOT show a system notification while the app is foregrounded — that's why `flutter_local_notifications` is used to render it manually from `onMessage`.

## 2. iPhone setup (APNs) — the extra steps
The push capability is already enabled (`aps-environment` in both entitlements). What remains is the **Apple ↔ Firebase link**:

1. **Xcode capabilities:** Runner target → Signing & Capabilities → confirm **Push Notifications** and **Background Modes → Remote notifications** are on (they back the `aps-environment` entitlement).
2. **Create an APNs Auth Key (.p8):** Apple Developer → Certificates, Identifiers & Profiles → **Keys** → **+** → enable **Apple Push Notifications service (APNs)** → download the `.p8` (you can only download once). Note the **Key ID** and your **Team ID**.
3. **Upload to Firebase:** Firebase Console → Project `greengo-chat` → **Project Settings → Cloud Messaging → Apple app configuration → APNs Authentication Key** → upload the `.p8` + Key ID + Team ID. *(One key covers dev + prod for all your apps.)*
4. **Request permission on device:** call `FirebaseMessaging.instance.requestPermission()` (or provisional) — iOS shows the system prompt. On iOS you get the APNs token, and FCM maps it to an FCM token automatically.
5. **Foreground presentation:** call `setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true)` so banners appear while the app is open.
6. **Test on a REAL device.** The iOS Simulator supports push only in limited/newer setups; treat a physical iPhone as required.

## 3. Token management (in `push_notification_service.dart`)
- On login / permission grant: `getToken()` → store under the user (e.g. `users/{uid}/fcmTokens/{token}` or an array on the profile). Storing per-token in a subcollection avoids write hotspots and makes stale-token cleanup easy (ties into `plan_on_scale/G2`).
- Listen to `onTokenRefresh` → upsert the new token.
- On logout / account deletion: **delete the token** so the user stops receiving pushes on that device.
- On send failure (`messaging/registration-token-not-registered`): remove the dead token server-side.

## 4. Sending from Cloud Functions
```ts
// functions/src/notifications/pushNotificationTriggers.ts (pattern)
await admin.messaging().sendEachForMulticast({
  tokens,                                  // the recipient's stored FCM tokens
  notification: { title, body },           // shown by the OS when backgrounded
  data: { route: 'event', id: eventId },   // read on tap for deep-link routing (strings only)
  android: { priority: 'high', notification: { channelId: 'greengo_default' } },
  apns: { payload: { aps: { sound: 'default', badge: 1, 'content-available': 1 } } },
});
```
- **`notification` vs `data`:** `notification` is auto-displayed when backgrounded; **`data`** carries the routing keys you read on tap. Include both. Data values must be **strings**.
- **Topics** (e.g. `all`, `city_<id>`) are fine for broadcasts; **token multicast** for targeted sends. `sendEachForMulticast` handles ≤500 tokens/call — chunk beyond that (already done in `fanout.ts`).

## 5. Tap → deep link (routing)
Wire all three entry points to the same router:
- **Cold start from a tap:** `FirebaseMessaging.instance.getInitialMessage()` → route from `message.data`.
- **Background tap:** `FirebaseMessaging.onMessageOpenedApp` → route.
- **Foreground:** `FirebaseMessaging.onMessage` → render with `flutter_local_notifications`; route on its tap callback.

Map `data.route` + `data.id` to the same destinations as deep links (e.g. `route:'user'` → profile, `route:'event'` → event). Reuse `deep_link_service.dart` so notifications and links land on identical screens.

## 6. Testing
- **Firebase Console → Messaging → “Send test message”**, paste an FCM token → fastest smoke test.
- **HTTP v1 API** for scripted tests (OAuth token via service account; the legacy server-key API is deprecated).
- Verify: foreground banner (local notif), background system notification, **tap opens the correct screen**, badge/sound on iOS.

## 7. Common pitfalls
| Symptom | Cause / fix |
|---|---|
| iOS gets no push | APNs `.p8` not uploaded to Firebase, or Push capability off, or testing on Simulator. |
| Android 13+ gets no push | `POST_NOTIFICATIONS` runtime permission never requested/granted. |
| Notification icon is a white square | Icon isn't a white/transparent-alpha asset. |
| No banner in foreground | Android needs `flutter_local_notifications`; iOS needs `setForegroundNotificationPresentationOptions`. |
| Data-only message ignored when killed | iOS needs `content-available:1` + `priority high`; background handler must be a top-level function. |
| Tap opens home, not the target | `data.route/id` missing, or `getInitialMessage()` not handled on cold start. |
| User keeps getting pushes after logout | Token not deleted on logout/delete. |

*Companion: [DEEP_LINKING.md](./DEEP_LINKING.md) (shared routing) · `plan_on_scale/G2` (token storage without hotspots).*
