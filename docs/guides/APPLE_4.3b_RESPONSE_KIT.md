# GreenGo — Apple Guideline 4.3(b) Response & Reviewer Kit

**Purpose:** Everything you need to *beat the dating-spam rejection* and, if it happens again, *escalate*. Use this alongside `APPLE_SUBMISSION_RUNBOOK.md`.

**Last updated:** 2026-07-21 · verified against `main` @ `68cd890`

- **Rejected build:** 2.2.4 (90) · Submission ID `9ce01678-d37f-4ed6-9b6f-0c111d8e57e4` · Review device iPad Air 11" (M3)
- **Rejection:** Guideline **4.3(b) – Design – Spam** (perceived as a dating-app duplicate)
- **New build:** `3.0.0 (105)` — product repositioned to cultural exchange (see `APPLE_APPROVAL_PLAN_v3.0.0.md`)

> ⚠️ 4.3(b) is **subjective**. There is no guaranteed approval. This kit maximises odds: (1) prove no dating signal reaches the reviewer — **in the app, in the OS prompts, and in email**, (2) give them a demo account that lands on cultural content, (3) send a clear reviewer note, (4) have an appeal + PWA fallback ready.

---

## 0. What changed since 3.0.0 (101) — and why it matters to the reviewer

| Change | Commit | 4.3(b) impact |
|---|---|---|
| **Culture flavor is the universal default** on web, iOS *and* Android (`flavor_config.dart:40`; dating lives only in the opt-in `main_full.dart`) | — | **Strongest single argument.** You are no longer shipping "the dating app with an iOS mask" — the shipping product on every platform has no swipe deck, no matching, no virtual gifts, no video profiles. |
| **Dating notifications suppressed from the in-app feed** — `new_like`/`newLike`/`new_match`/`newMatch`/`super_like`/`superLike`/`match_expiring` are filtered out, including legacy Firestore docs (`notification_remote_datasource.dart:117-129`) | `37e8230` | Closes the "old account has a Likes notification" leak. |
| **Communities "Core" shipped** — every community has Chat · Tips · Announcements · Events tabs, plus rules, roles, moderation and join approval (`community_detail_screen.dart:364-367`) | `44e621d` | Turns the Community tab from a stub into real, demonstrable cultural-exchange product. Feature this in the demo. |
| **Explore has real content** — Featured = 3 nearest, Happening-soon fills to 20 live events, sorted by distance | `51f2ef4` | The reviewer's first screen is no longer sparse. Empty screens read as "shell app". |
| **Safety hardened** — block hides the user everywhere instantly, report auto-blocks, blocked users gone from search/community chat/event chat | `502d6de`, `f79d3b6`, `534f9a9` | Pre-answers the Guideline **1.2** UGC questions that usually ride along with a 4.3(b) reply. |
| **Universal Links / App Links live** — AASA filled with Team `9885DQB8RF`, appID `9885DQB8RF.com.greengochat.greengochatapp` | `ebe89c7` | Deep links now *actually resolve on device*. §5 deep-link trap is no longer theoretical — it must be tested. |
| **Collapsible bottom menu** — swipe the bar down to hide it; a centered gold hamburger pill restores it | `b485466` | New usability risk: a reviewer who hides the menu and doesn't spot the pill sees a "broken" app (Guideline 2.1). Test it deliberately. |
| **iOS app icon replaced** — gold GG, alpha channel flattened via `remove_alpha_ios` | `68cd890` | App Store Connect rejects icons with an alpha channel at upload. Already fixed. |
| Notification settings (paid-tier per-category prefs + city alerts), emoji reactions, 89 P0 unit tests, 423-item E2E matrix | several | Depth evidence — a spam-clone doesn't have these. |

**Also new and worth reading:** `docs/to_actualize/store_metadata/STORE_COMPLIANCE.md` (exact App Privacy answers), `docs/to_actualize/store_metadata/ASO_TODO.md` (listing copy), `docs/to_actualize/testing/E2E_TEST_MATRIX.md`.

---

## 0.1 🔴 OPEN BLOCKER — fix before you archive

**The iOS permission prompts still say "people near you".** Verified still present in `ios/Runner/Info.plist:54-57`:

> "GreenGo needs your location to show **people near you** and calculate **distances**."

The OS renders that string verbatim, full-screen, on the reviewer's device. It is the single most literal dating signal in the whole submission, and it fires before they have seen any of your cultural content. `APPLE_RISK_CLEANUP_PLAN.md` §1.1 flagged this — **it has not been applied yet.**

| Key | Current | Change to |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | "…show people near you and calculate distances." | "GreenGo uses your location to show local events, cultural experiences and language partners in your area." |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | present (same dating text) | **Delete the key** — the app only ever calls one-shot `getCurrentPosition`; advertising Always invites a 5.1.1 question. |
| `NSCameraUsageDescription` | "…take photos for your profile." | "GreenGo uses the camera to take profile photos and scan QR codes." |
| `NSPhotoLibraryUsageDescription` | "…upload profile pictures." | "GreenGo accesses your photos so you can upload profile and event pictures." |

String literals only — zero behavior change, but it needs a rebuild, so do it **first**.

---

## 1. Pre-submission verification — "no dating signal is reachable"

Run this on the **actual build you're about to upload**, on an **iPad** (the review device was an iPad Air 11") *and* an iPhone, using the **demo account** you'll give Apple. Every box must be checked. If any fails, fix before archiving.

**Before the app even opens**
- [ ] Location permission prompt reads the **new** cultural wording (§0.1) — not "people near you".
- [ ] Camera / photo / mic prompts read as profile-and-events, never dating.
- [ ] App icon shows the gold GG and uploaded to App Store Connect without an alpha-channel error.

**First impression (the reviewer's first 10 seconds)**
- [ ] First screen after login is **Explore** (cultural feed), not a swipe deck.
- [ ] Explore is **populated** — Featured shows 3 nearby items, Happening-soon has events. An empty Explore reads as a shell app.
- [ ] No card you can swipe left/right on faces anywhere in the default flow.
- [ ] No "like / super-like / nope" buttons visible.
- [ ] No "It's a Match!" screen, animation, or nav badge.

**Navigation**
- [ ] Bottom tabs read: **Explore · Events · Community · Messages · Profile** (`main_navigation_screen.dart:1814-1841`) — no "Discover/Matches".
- [ ] **Swipe the bottom bar down** → the gold hamburger pill appears centered and restores the menu on tap. Confirm the reviewer cannot get stranded on a page with no navigation.
- [ ] Sub-pages (Explore "See all", community detail) keep the bottom menu; the back button pops in-tab first.
- [ ] No tab or deep link reaches `discovery_screen` swipe UI, `matches_screen`, `match_detail`, `blind_date`, `date_scheduler`, `second_chance`, `share_my_date`, `special_modes`, `virtual_gifts`, `video_profiles`.

**Community tab (your best evidence — show it off)**
- [ ] Opening a community shows the four tabs: **Chat · Tips · Announcements · Events**.
- [ ] Rules screen renders; join-approval flow works; a moderator action is demonstrable.

**Notifications & feed**
- [ ] The in-app notification feed contains **no** like/match/super-like entries, even on an old account (filter at `notification_remote_datasource.dart:117-129`).
- [ ] The notification permission pre-prompt copy talks about messages, events and community alerts — not matches.

**Deep links (now live — test on device)**
- [ ] `https://greengo-chat.web.app/u/{userId}` opens the **de-dated profile view**, not a match/like screen.
- [ ] `https://greengo-chat.web.app/e/{eventId}` opens the event.
- [ ] `greengo://u/…` and `greengo://e/…` behave the same.

**Copy / vocabulary** (search the running UI, not just code)
- [ ] No "match", "singles", "date", "flirt", "hookup", "nearby singles" strings in visible UI.
- [ ] "Connect / Say hi / Skip" replace "Like / Super Like / Nope".
- [ ] Onboarding talks about languages/culture/events, not "find people near you".

**Preferences / filters**
- [ ] No age-range or distance-targeting filter. Filters are language / interest / city.

**Demo account is actually usable**
- [ ] The account is **approved** (not stuck on the waiting/approval gate) and fully onboarded.
- [ ] Since the July security lockdowns (`47150af`, `1db6bd9`, `3a0f5d0`), re-verify on a **fresh** account that photos upload, chat sends, and community media loads. A rules regression that only bites new accounts will look like a broken app to the reviewer.

**Store-side (from the Runbook)**
- [ ] Category Travel/Education, screenshots show Explore/Events/Community, keywords have no dating terms.

> How to search visible strings fast: `grep -rin "match\|super ?like\|singles\|swipe\|flirt\|nearby" lib/generated/app_localizations*.dart` — anything user-facing here is a red flag. (Code behind disabled flags is fine; **reachable UI text** is what matters.)

---

## 2. Reviewer note (paste into App Review Information → Notes)

```
Thank you for reviewing GreenGo.

GreenGo is a CULTURAL EXCHANGE and LANGUAGE-LEARNING app — it is not a dating
app and does not duplicate that category.

What you will see with the demo account:
• The home screen is "Explore" — cultural experiences and local events browsed
  by city, language and interest.
• "Events" (tab 2) lists local events and experiences you can join.
• "Community" (tab 3) hosts language-exchange and interest groups. Each
  community has its own Chat, Tips, Announcements and Events, with published
  rules, moderator roles and join approval.
• There is NO swipe deck, NO like/super-like, and NO "match" mechanic anywhere.
• People are found through a directory filtered by LANGUAGE / INTEREST / CITY —
  never by age or distance targeting.
• Safety: users can block and report from any surface; reporting auto-blocks,
  and blocked users disappear from search, chats and communities immediately.

We rebuilt the product for version 3.0.0 specifically to address the prior
4.3(b) feedback. The cultural-exchange experience is now the default build on
every platform we ship — iOS, Android and web — not an iOS-only variant.
Category, screenshots, keywords and description are Travel / Education.

Note on navigation: the bottom menu can be swiped down to hide it; a gold
button in the centre of the bottom edge brings it back.

Demo account:  ⟨email⟩  /  ⟨password⟩   (approved and onboarded; opens on Explore)
Demo video (optional): ⟨link⟩

Happy to answer any questions. Thank you for reconsidering.
```

Fill ⟨email⟩/⟨password⟩ with a real, tested account (see Runbook Phase 6).

---

## 3. Demo video script (30–60s, optional but strong)

Record on a real device (or the review-device iPad simulator) with the demo account. Screen-record; narration optional (on-screen captions are enough).

| Time | On screen | Caption |
|---|---|---|
| 0:00–0:05 | Cold launch → black splash with gold GG → **Explore** loads with Featured + Happening soon | "GreenGo opens on Explore — culture, not dating." |
| 0:05–0:13 | Scroll Explore: experiences and events by city/language/interest | "Discover cultures and languages by city and interest." |
| 0:13–0:22 | Tap **Events** tab → list of local events → open one | "Browse and join local events." |
| 0:22–0:36 | Tap **Community** tab → open a community → swipe its **Chat · Tips · Announcements · Events** tabs → show the rules screen | "Communities for language exchange — with their own chat, tips, announcements, events and rules." |
| 0:36–0:45 | Open a person via directory → filter shows Language/Interest/City (no age/distance) | "Connect by language and interest — no swiping, no matching." |
| 0:45–0:53 | Messages tab → a normal conversation | "Message the people you connect with." |
| 0:53–0:60 | Open the safety menu → Block / Report | "Block and report from anywhere." |

Keep it silent-safe (captions), < 500 MB, mp4/mov. Upload as an **App Preview** and/or link it in the reviewer Notes.

---

## 4. Off-app dating signals — the leak nobody checks

The app is clean. **Your backend is not.** These reach the reviewer *outside* the binary, where none of your flavor flags apply.

### 4.1 🔴 Brevo transactional emails still use dating copy
Scheduled Cloud Functions send templated email to every user:

| Function | File | Dating copy it can send |
|---|---|---|
| `sendBrevoWeeklyDigest` | `functions/src/notifications/brevoEmailService.ts:2133` | "**New matches:** N" (`:1399`) |
| `sendBrevoReEngagement` | `brevoEmailService.ts:2217` | "Several people have **liked your profile**!" (`:1435`, `:1521`) |
| template registry | `brevoEmailService.ts:1241, 1251` | `new_match`, `super_like_received` |
| digest/re-engagement triggers | `functions/src/notification/index.ts:580, 635` | `weekly_digest` counts `newMatches` (`:583`) |

A reviewer who leaves the demo account idle can receive one of these. Even without that, it contradicts your reviewer note if anyone looks.

**Action before submitting:** either disable those schedulers for the review window, or strip the match/like copy and counts from the templates. Server-side only — no app rebuild.

### 4.2 Push routing still knows dating types
`lib/core/services/push_notification_service.dart:244, 308-309` still routes `newMatch` / `newLike` / `superLike`. Harmless *if* the server never sends them — but the producers were only removed for some paths.

**Action:** confirm no deployed function emits those types (`APPLE_RISK_CLEANUP_PLAN.md` §3.3), and that if one arrives it lands on the de-dated profile view rather than a gated dating screen.

---

## 5. If rejected again — escalation ladder

Work top-down; don't skip to the bottom.

### 5.1 Reply in Resolution Center (first response)
Apple's rejection will cite what they saw. Reply **specifically to their screenshot**, don't send a generic letter:

```
Thank you for the follow-up. Could you clarify which screen signals a dating
app? With the demo account the app opens on Explore (cultural experiences and
local events) and contains no swipe deck, like/super-like, or match mechanic.

If a specific screen or string is the concern, we will remove it immediately.
For reference:
• Home = Explore (culture/events), Tabs = Explore/Events/Community/Messages/Profile
• Communities have chat, tips, announcements, events, rules and moderators
• People are found by language/interest/city, never age/distance
• The non-dating build is our default on iOS, Android and web
• Category is Travel/Education

We're committed to resolving this and can provide a live demo call or video.
```

Attach a fresh screenshot/video of the Explore-first flow.

### 5.2 Ask for a call
In Resolution Center you can request a phone call with App Review. A 10-minute live walkthrough of the Explore-first flow resolves subjective 4.3(b) cases faster than text.

### 5.3 App Review Board appeal
If you believe the rejection is wrong (not a policy you can change), file an appeal:
- App Store Connect → the rejected version → **Resolution Center → Submit an appeal** (or appstoreconnect.apple.com/apps → App Review → Appeal).
- Lead with: "GreenGo 3.0.0 is a Travel/Education cultural-exchange app. The prior 4.3(b) concern was addressed by removing all dating mechanics; the home screen is Explore, and this build is our default across all platforms." Attach the demo video.
- The Board reviews independently of the original reviewer.

### 5.4 PWA fallback (ship to iOS without the App Store)
If Apple ultimately refuses, distribute on iOS as an **installable PWA** (per `APPLE_APPROVAL_PLAN_v3.0.0.md` §6):
- `web/manifest.json` branded; `web/index.html` has `apple-mobile-web-app-capable`, `apple-touch-icon` (the gold GG), splash images, `theme-color=#0A0A0A`.
- iOS users install via Safari → Share → **Add to Home Screen**.
- Honest limits: iOS Web Push needs iOS ≥16.4 **and** the PWA installed; payments via **Stripe Checkout** (no native IAP); not in App Store search.

---

## 6. Common 4.3(b) traps to avoid

- **The iOS permission strings** (§0.1). Still unfixed at the time of writing. Highest reviewer impact per character changed in the whole repo.
- **Brevo weekly-digest / re-engagement email** landing in the reviewer's inbox with "New matches" (§4.1).
- **Leaving a dating string in an ARB file** that still renders somewhere (badges, empty states, push copy). Search generated localizations, not just source.
- **Screenshots** that still show faces-grid or swipe UI — the reviewer compares them to the live app.
- **Category left as Social/Lifestyle** — this alone re-triggers the "another dating app" pattern.
- **A deep link that opens a gated dating screen.** Universal Links are live now (`ebe89c7`), so `/u/{id}` really does open in-app on the reviewer's device — test it.
- **Demo account that dumps the reviewer into a dating screen** because it was created before the repositioning, or that is stuck behind the approval gate, or that hits a security-rules wall on upload. Use a fresh, approved, smoke-tested account.
- **A reviewer who swipes the bottom menu away** and reports the app as broken. Mention the restore pill in the reviewer note (§2).

---

## 7. One-line summary to keep in your head

> The build the reviewer opens must **look, read, and behave** like a Travel/Education cultural-exchange app on the very first screen — and so must every OS prompt and every email it sends. Everything else is supporting evidence.
