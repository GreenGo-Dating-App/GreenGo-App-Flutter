# GreenGo — Store Compliance Answer Sheet (Data Safety / App Privacy)

Exact values to enter in the **Play Console → Data safety** and **App Store Connect → App Privacy** forms. Verify each against your actual backend before submitting; this is derived from the app's permissions + features (auth, profiles, chat, photos/voice/video, location, events, coins/subscriptions, push, analytics).

Backends that receive data: **Firebase/Google** (Auth, Firestore, Storage, FCM, Functions), **Stripe** (web payments), **Google Play / Apple** (IAP), **Brevo** (transactional email), **Nominatim/Geoapify** (geocoding), **Ticketmaster/Viator/Tiqets** (event data — outbound queries).

Global answers:
- **Encrypted in transit:** YES (HTTPS / Firestore/Storage TLS).
- **Users can request deletion:** YES (in-app account deletion → `onProfileDeleted` server cascade). Provide the deletion path + a web deletion URL in the listing.
- **Data used for tracking (Apple ATT):** default **NO** — unless you run ad attribution/3rd-party ad SDKs. Confirm you have none.

---

## 1. Google Play — Data safety (per data type: Collected? Shared? Purpose · Required/Optional)

| Data type | Collected | Shared | Purpose | Req/Opt |
|---|---|---|---|---|
| **Email address** | Yes | No | Account management, auth | Required |
| **Name** (display name/nickname) | Yes | No | App functionality (profile/discovery) | Required |
| **User photos** (profile/chat) | Yes | No | App functionality | Optional |
| **Voice/audio** (voice messages) | Yes | No | App functionality | Optional |
| **Videos** (video profiles/chat) | Yes | No | App functionality | Optional |
| **Messages / other user content** | Yes | No | App functionality (chat) | Optional |
| **Approximate location** | Yes | No | App functionality (discovery/events) | Optional |
| **Precise location** | Yes | No | App functionality (nearby people/events) | Optional |
| **Purchase history** | Yes | No* | App functionality (coins/membership) | Optional |
| **App interactions / other usage** | Yes | No | Analytics, personalization (recommendations) | Optional |
| **Device / other IDs** (FCM token) | Yes | No | App functionality (push notifications) | Optional |
| **Crash logs / diagnostics** | Yes (if Crashlytics on) | No | Analytics/app stability | — |

\* Payments go to Stripe/Play/Apple as **processors**, not "shared for their own use." Declare as processing, not sharing.
- For every "Optional" row where the user grants a runtime permission, mark accordingly.
- **Security section:** encrypted in transit = Yes; users can request deletion = Yes; committed to Play Families policy = per your audience.

### Play — Photo & Video Permissions declaration (required because you request READ_MEDIA_IMAGES/VIDEO)
- Use case: **"one-time and frequent"** access — users pick profile/chat photos and videos regularly (core feature). Justify broad access, OR migrate one-off pickers to the Android Photo Picker to avoid the declaration. `READ_MEDIA_AUDIO` was removed (not needed).

### Play — Content rating (IARC questionnaire)
- Category **Social/Communication**, user-generated content + user interaction = **Yes**. **NOT** a dating app. Expect Teen/Mature-17 depending on UGC answers; answer honestly about chat/UGC moderation (you have block/report + community guidelines).

---

## 2. Apple — App Privacy (per category: Linked to user? Used for tracking?)

Mark **Linked to the user = Yes** for all below (tied to an account), **Used for tracking = No** (unless ad attribution).

| Apple category → type | Purpose |
|---|---|
| **Contact Info → Email Address** | App Functionality, Account |
| **Contact Info → Name** | App Functionality |
| **User Content → Photos or Videos** | App Functionality |
| **User Content → Audio Data** (voice msgs) | App Functionality |
| **User Content → Customer Support / Other** (messages) | App Functionality |
| **Location → Coarse Location** | App Functionality |
| **Location → Precise Location** | App Functionality |
| **Identifiers → User ID** (uid) | App Functionality |
| **Identifiers → Device ID** (FCM token) | App Functionality |
| **Purchases → Purchase History** | App Functionality |
| **Usage Data → Product Interaction** | Analytics, App Functionality |
| **Diagnostics → Crash / Performance** (if enabled) | App Functionality |

- **Data Not Collected**: only if truly none — not applicable here.
- Keep these labels **in sync** with the Play table and the privacy policy.

---

## 3. Privacy policy (required by both stores)
- Live, public URL (and localized ideally). Must disclose: what you collect (above), why, third parties (Firebase/Stripe/Brevo/geocoding/event APIs), retention, deletion process, contact.
- Add the **account-deletion URL** to both consoles (Play requires an external deletion request path even though in-app deletion exists).

---

## 4. Pre-submit checklist
- [ ] Play Data Safety completed (table §1) + Photo/Video declaration.
- [ ] Apple App Privacy completed (§2) — matches Play.
- [ ] Privacy policy URL live + linked in both consoles; account-deletion URL added.
- [ ] Content rating (IARC) done — non-dating, UGC honest.
- [ ] Age rating set (Apple) consistent with content.
- [ ] Store listing (name/subtitle/keywords/desc/screenshots) — see `ASO_TODO.md`.
- [ ] Upload fresh **AAB** (built from main today) + **iOS build** (TestFlight → submit).
- [ ] Export compliance (Apple): uses standard encryption (HTTPS) → usually "exempt"; answer the encryption question.
