# Plan — Detailed Notification Settings + City Event Alerts

**Date:** 2026-07-17 · **Status:** Plan (approved to build pending final go-ahead)

Two features:
1. **Notification Settings** screen (Profile → Account Settings) — per-category control.
2. **City event alerts** — get notified about events happening in chosen cities.

Decisions: per-**category** toggles · **all** event kinds (community + business + external) · **multiple** cities · delivered as **push + in-app feed**.

---

## Current state (verified)
- `notification_preferences/{uid}` doc + full stack (model/entity/usecases/bloc/`notification_preferences_screen.dart`) exist but hold **dating-era fields** (`newMatch`/`newLike`/`superLike`/`matchExpiring`) and the screen is **not wired** into the UI.
- Entry point: Profile → Edit Profile → **"Account Settings"** accordion (`edit_profile_screen.dart:423`, `EditSectionCard` tiles).
- Senders (Cloud Functions) currently **don't consult** per-type prefs → toggles are inert until enforced.
- Events carry a `city` field (`event.dart:153`). Push catalog: `PUSH_NOTIFICATION_EVENTS.md`.

---

## Data model — extend `notification_preferences/{uid}`
```jsonc
{
  "pushEnabled": true,                 // master
  "categories": {
    "messages": true,                  // 1:1, group, business chat, event chat, support
    "events": true,                    // community/business events, reminders, RSVPs, broadcasts, city alerts
    "communities": true,               // announcements, new members
    "social": true,                    // profile views, business follow/rate, boosts
    "account": true                    // verification, admin broadcast, account-approved
  },
  "soundEnabled": true,
  "vibrationEnabled": true,
  "quietHoursEnabled": false,
  "quietHoursStart": "22:00",
  "quietHoursEnd": "08:00",
  "eventCities": ["rome", "lisbon"]    // normalized city keys
}
```
Remove the dating fields. Default (no doc / missing key) = **opt-in** (notify), so existing users aren't silenced.

### Category mapping (push type → category)
| Category | Push functions |
|---|---|
| messages | onNewMessagePush, onGroupMessageCreated, onSupportMessagePush, onEventMessageCreated |
| events | onCommunityEvent*, onEventCreated/PublishedNotifyFollowers, sendEventReminders, onEventAttendeeJoined, onEventBroadcastCreated, **city alerts** |
| communities | onCommunityAnnouncementCreated, onCommunityMemberJoined |
| social | onProfileViewed, onBusinessFollowed, onBusinessRated, on*BoostStarted, checkBoostExpiries |
| account | onVerificationStatusChange, admin broadcast, approveUser |

---

## Part A — Notification Settings screen

**A1. Model/entity/bloc** — rewrite `NotificationPreferences` to the shape above (category map + `eventCities`); update model `fromFirestore`/`toFirestore`, bloc events (toggle category, add/remove city), keep quiet-hours logic.

**A2. Screen** — grouped glass toggle sections (one per category) + Sound/Vibration + Quiet Hours + a **"Community events by city"** section with add/remove city chips (city picker — reuse the `web_location_picker`/Nominatim or a searchable city list). Master push toggle at top (also deep-links to OS settings if the OS permission is off — ties into the OS-status permission work).

**A3. Entry point** — add an `EditSectionCard("Notification Settings", Icons.notifications)` to the Account Settings accordion → opens the screen (wrapped in its bloc). i18n all strings (`app_en.arb` + `flutter gen-l10n`).

## Part B — Backend enforcement (makes toggles real)

**B1.** Shared helper `functions/src/notifications/prefs.ts`:
```ts
shouldNotify(uid, category): Promise<boolean>
// false if !pushEnabled, !categories[category], or within quiet hours; default true if no doc
```
**B2.** Call it in every sender before `brandPush`:
- Single-recipient senders (onNewMessagePush, pushParity, etc.) → `if (!await shouldNotify(uid, cat)) return;`
- Multicast fan-outs (events/communities/groups) → **filter the recipient list** by pref before building `tokens`.
- **Scale note:** filtering N recipients = N pref reads. Mitigate by denormalizing a compact `notify` flag map onto each user's token record, or batch-get prefs. Decide per fan-out size.

## Part C — City event alerts

**C1. Subscription writes** — when the user edits `eventCities`, also maintain a **per-city index** for efficient fan-out:
`event_city_subscribers/{cityKey}` → subcollection `users/{uid}` (or a token list). Avoids scanning all `notification_preferences` by `array-contains` at scale.

**C2. Triggers → notify city subscribers** (deduped against people already notified, e.g. community members):
- **Community & business events** (`onCommunityEvent*`, `onEvent*NotifyFollowers`): on create/publish with a `city`, fan out to `event_city_subscribers/{cityKey}` — **immediate** push + in-app feed doc.
- **External events** (`external_events` bulk ingest): **NOT per-event** (100+/ingest = storm). Instead a **scheduled digest** (`sendCityEventDigest`, e.g. daily) → "N new events in {city}" per subscribed city. One push + one feed doc per city per run.

**C3. Normalization** — a `normalizeCity()` (lowercase/trim/diacritics) shared by the subscription write and every event's `city` so keys match. Mirror the existing `normalizeCountryName` pattern.

**C4. Scale** — paginate subscribers, chunk FCM at 500/multicast, dedupe by uid, respect `shouldNotify(uid,'events')` + quiet hours.

## Part D — Ship
1. Client Phase A first (toggles save; harmless if backend not yet enforcing).
2. Backend B + C, `tsc`, **targeted** functions deploy (avoid the orphaned-function abort — deploy by name).
3. New APK/AAB + iOS TestFlight.
4. Live-test: toggle each category off → confirm suppressed; subscribe a city → create an event there → confirm alert + feed entry; verify external digest.

## Firestore indexes / rules
- Index for any `eventCities array-contains` fallback query (if used).
- Rules: user can read/write only their own `notification_preferences`; `event_city_subscribers` writable by the owner uid only; server writes feed docs.

## Open follow-ups
- Reuse or new city-picker widget? (recommend reuse Nominatim search from `web_location_picker`).
- External-event digest cadence: daily vs weekly (recommend daily, capped).
