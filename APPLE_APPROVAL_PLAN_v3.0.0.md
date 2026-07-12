# GreenGo — Apple App Store Approval Plan (v3.0.0)

**Goal:** Clear Apple **Guideline 4.3(b) – Design – Spam** and get GreenGo approved on the App Store by shipping a genuinely differentiated, glassmorphic, *cultural-exchange* experience — not a dating app.

- **Rejected build:** 2.2.4 (90) · Submission ID `9ce01678-d37f-4ed6-9b6f-0c111d8e57e4` · Review device iPad Air 11" (M3)
- **Current repo version:** `2.2.4+100`
- **New target version:** **`3.0.0+101`** (major bump — this is a product repositioning, not a patch)
- **Interactive UI preview:** https://claude.ai/code/artifact/8aee4601-a33e-4422-8d14-ad80ab9a51a5

> ⚠️ **Honest framing.** 4.3(b) is a *subjective* rejection about what the reviewer perceives the app to be. There is **no guaranteed** approval. This plan maximises the odds by (1) removing every dating signal from the iOS build, (2) leading with cultural/language/events content on the first screens, (3) overhauling store metadata, and (4) pairing it with a strong Resolution Center reply. If Apple still refuses, the **PWA** (installable web app) is the fallback distribution channel for iOS.

---

## 1. Why the app keeps getting rejected

A reviewer opening build 90 lands **immediately on a Tinder-style swipe deck of faces** with like / super-like buttons. The codebase is saturated with dating signals:

- `discovery_screen.dart` — swipe deck (`swipe_card.dart`, `swipe_buttons.dart`), like / **superLike** / nope, hourly like limits, "grid mode" of faces.
- A `matches` collection + `matches_screen.dart`, `match_detail_screen.dart`, `match_card_widget.dart`, `match_notification.dart`, "It's a match" nav badge.
- `discovery_preferences_screen.dart` — age-range + distance targeting.
- Feature folders that read as dating on sight: `blind_date`, `date_scheduler`, `second_chance`, `share_my_date`, `icebreakers`, `vibe_tags`, `video_profiles`, `virtual_gifts`, `special_modes`, `matching`.

**No amount of repositioning text fixes this while the first screen is a swipe deck.** v3.0.0 changes the product the reviewer actually sees.

---

## 2. Strategy — UNIFY EVERYWHERE, one codebase

> **Decision (2026-07-10): one product across web, iOS and Android.** The glass, Explore-first, non-dating experience is the **default everywhere**. Dating mechanics are turned **OFF by default behind `FlavorConfig` flags** — the code is preserved and re-enableable, but no platform ships it. This matches GreenGo's own "not a dating app" identity.

```
                 ┌─ web (Flutter web / PWA) ──┐
 Shared Flutter ─┼─ iOS (App Store)          ─┼──→ glass · Explore-first · NO swipe deck
   codebase      └─ Android (Play Store)     ─┘     (dating features OFF by default, flag-gated)
```

- The new experience is the **default in `main.dart`**, so **web, iOS and Android all inherit it** — no per-platform fork.
- Dating features (`swipe`, `matching`, `blind_date`, `date_scheduler`, `second_chance`, `share_my_date`, `special_modes`, `virtual_gifts`, `video_profiles`) remain in code but gated by flags that **default to `false` everywhere**. A "full" build could re-enable them later.
- **Same Firestore backend** — no data migration.
- Glassmorphism + modern UX is theme-tokenised → identical polish on every platform.

---

## 3. Repository & versioning

| Item | Before | After (v3.0.0) |
|---|---|---|
| Version | `2.2.4+100` | **`3.0.0+101`** |
| App structure | Single build, dating features always on | Flutter **flavors**: `android_full` (unchanged) + `ios_culture` (dating off, Explore-first) |
| Feature gating | `AppConfig` flags (partial) | Extended `FlavorConfig`: `enableSwipeDiscovery`, `enableMatching`, `enableBlindDate`, `enableDateScheduler`, `enableSecondChance`… all **false** on iOS |
| Repo split | one repo | Stay one repo + flavor now; split to a separate iOS repo **only if** the builds truly diverge later |
| `.ai/context_base.md` | present | add flavor + v3.0.0 repositioning notes (repo standard) |

> Bump `version: 3.0.0+101` in `pubspec.yaml`; iOS build number must exceed 90 (Apple) — 101 satisfies both stores.

---

## 4. BEFORE → AFTER — the full change table

### 4.1 Navigation / menu
| Tab | Before (dating) | After — iOS `ios_culture` (v3.0.0) |
|---|---|---|
| 0 | **Discover** — swipe deck of faces 🚫 | **Explore** — cultural feed: experiences by city, language & interest |
| 1 | Messages | **Events** — local events & experiences (existing `external_events` data) |
| 2 | Groups | **Community** — language-exchange & interest groups |
| 3 | Events | Messages |
| 4 | Profile | Profile |
| Nav style | Solid opaque `BottomNavigationBar` | **Floating frosted-glass** nav bar, gold active pill, haptic on tap |

### 4.2 Core functionality
| Area | Before | After (iOS) |
|---|---|---|
| People discovery | Swipe deck, like / **superLike** / nope, hourly limits | Browse **directory** by language / city / interest — no swipe, no deck |
| Connection model | "Match" (mutual like) + "It's a match" | **"Connect" / "Request exchange"** — plain connections list |
| Preferences | Age range + distance targeting | Filter by **language, interest, city** (age/distance removed) |
| `blind_date` | On | **Off** (flag) |
| `date_scheduler` | On | **Off** (flag) |
| `second_chance` (rematch) | On | **Off** (flag) |
| `share_my_date` | On | **Off** (flag) |
| `special_modes` | On | **Off** (flag) |
| `virtual_gifts` / `video_profiles` | On | **Off** (flag) |
| `icebreakers` / `vibe_tags` | Flirting tools | Reframed as **cultural conversation starters / interest tags** |
| Matches badge | "New match" count on nav | Removed; replaced by message/connection badges |
| Events | 4th tab, secondary | **Promoted** — 2nd tab, core of the experience |
| Language exchange | Buried | **Foregrounded** on Explore + Community |

### 4.3 Visual design / colors
| Token | Before | After |
|---|---|---|
| Ground | `AppColors.deepBlack #0A0A0A` (flat) | `#0A0A0A → #141414` cinematic gradient |
| Accent | `richGold #D4AF37` | `#D4AF37` + `#E9C96A` highlight + soft **gold glow** on primary CTA |
| Surfaces | Solid opaque cards | **Frosted glass** — `BackdropFilter blur 18`, fill `rgba(255,255,255,.06)`, hairline border `rgba(255,255,255,.12)` |
| Radius | Mixed (12–20) | Consistent scale — cards `22`, sheets `28`, pills `999` |
| Elevation | Ad-hoc shadows | Consistent glass shadow + inset top-edge sheen |
| Motion | Default Material curves | Spring `Cubic(0.16,1,0.3,1)`, press-scale `0.97`, staggered list reveals, shared-element hero |
| Feedback | Minimal | `HapticFeedback.lightImpact()` on cards/buttons; skeleton shimmer >300ms |
| Web manifest colors | Flutter blue `#0175C2` | Brand `#0A0A0A` / gold |

### 4.4 Copy / vocabulary (i18n — new keys in `app_en.arb`, run `flutter gen-l10n`)
| Before | After |
|---|---|
| "Discover new people" | "Explore cultures & languages" |
| "Like" / "Super Like" / "Nope" | "Connect" / "Say hi" / "Skip" |
| "It's a Match!" | "New connection" |
| "Matches" | "Connections" / "Exchange partners" |
| Onboarding: "find people near you" | "learn languages, meet locals, join cultural events" |

### 4.5 App Store metadata
| Field | Before | After |
|---|---|---|
| Category | Social / dating-adjacent | **Travel** (primary) + **Education** (secondary) |
| Screenshots | Swipe deck, faces grid | **Explore / Events / Community / language exchange** (glass UI) — no swipe deck, no faces grid |
| Keywords | match, nearby, meet, singles… | language exchange, cultural, travel, local events, learn |
| Description | People discovery | Cultural discovery, language-barrier-free networking, learn by doing |
| Subtitle | — | "Cultural exchange, languages & local events" |

### 4.6 Distribution
| Channel | Before | After |
|---|---|---|
| Android | Play Store (full app) | Play Store — **unchanged** |
| iOS native | Rejected under 4.3(b) | Resubmit v3.0.0 `ios_culture` build + Resolution Center reply |
| Web | Default Flutter web (not a real PWA) | **Installable PWA** on iOS + Android (fallback if Apple refuses) — see §6 |

---

## 5. Glassmorphism design system (Track F)

Direction: **Modern Dark Cinematic Glass** — frosted surfaces over deep-black→charcoal, gold accent + glow, spring motion + haptics. Matches existing `AppColors`.

**Tokens** (new `AppGlass`):
```dart
blurSigma = 18;  radius = 22 (cards) / 28 (sheets);
surface  = white @ 6%;   border = white @ 12%;   borderGold = gold @ 35%;
goldGlow = BoxShadow(gold @ 25%, blur 24);
spring   = Cubic(0.16, 1.0, 0.3, 1.0);   press = 180ms;
```

**One reusable widget** `GlassContainer` = `ClipRRect` → `BackdropFilter(blur)` → `Container(glass fill + hairline border + top sheen)`. Everything composes from it: nav bar, app bar, Explore cards, sheets, dialogs, coin/membership pills. Primary CTA stays **solid gold + glow** (readability beats glass for the main action).

**Guardrails (non-negotiable):**
- `BackdropFilter` is expensive — blur only **structural** surfaces (nav, app bar, sheets, hero, key cards). **Never blur every list row**; long lists use solid `charcoal` + hairline. Wrap static glass in `RepaintBoundary`.
- **Test on real devices** — Impeller can render blur as **black on emulators** (known GreenGo gotcha).
- Text over glass must hit **4.5:1** — add a subtle scrim. Respect **reduced-motion** & **Dynamic Type**.
- Web/PWA: lower sigma + fewer glass layers (blur heavier in browsers).

---

## 6. PWA — installable on iOS + Android (Track E)

Current `web/` is the **default Flutter template** (manifest says "greengo_chat / A new Flutter project", Flutter-blue). Work:

| Item | Change |
|---|---|
| `web/manifest.json` | GreenGo name/short_name/description, brand colors, `id`, `scope`, `categories:[travel,education,social]`, `shortcuts`, `screenshots` |
| `web/index.html` (iOS) | Add `apple-mobile-web-app-capable=yes` (**missing today**), status-bar style, `apple-touch-icon` 180, `theme-color`, notch-safe `viewport-fit=cover`, **`apple-touch-startup-image` splash screens** per device |
| Install prompt | Android: capture `beforeinstallprompt` → "Install GreenGo". iOS: one-time "Share → Add to Home Screen" banner (no iOS install API) |
| Hosting | `firebase.json` headers: correct manifest MIME, no-cache on `flutter_service_worker.js`; deploy with `NODE_TLS_REJECT_UNAUTHORIZED=0` (corp TLS) |
| Domain | Decide: keep `greengo-chat.web.app` or a cleaner `app.greengo.*` for the public "install" story |

**PWA limits (honest):** iOS Web Push works **only when installed**, iOS ≥16.4; payments via **Stripe Checkout** (no native IAP — better margins); a PWA is **not** in App Store search.

---

## 7. Execution phases

| # | Phase | Output | Visible change? |
|---|---|---|---|
| 1 | Flavor scaffold | `FlavorConfig`, `ios_culture` entrypoint, flags, `pubspec` → 3.0.0+101 | No |
| 2 | Glass design system | `AppGlass` + `GlassContainer` + a demo screen | Demo only |
| 3 | `ExploreScreen` + reordered glass nav (iOS) | New home | **Yes** |
| 4 | Strip swipe/like/match; gate dating features off (iOS) | De-dated build | **Yes** |
| 5 | Onboarding + copy rewrite (i18n) | New first-run + strings | **Yes** |
| 6 | PWA (manifest, iOS splash, install prompt, headers) | Installable web app | Web |
| 7 | Store metadata + screenshots | New listing assets | Store |
| 8 | Build & smoke-test on **real iPhone + Android + installed PWA**; submit; Resolution Center reply | Submission | — |

**Definition of done per phase:** builds *and runs* (reboot + smoke-test on a real device), not just compiles. No hardcoded UI strings. No dating signals reachable in the `ios_culture` flavor.

---

## 8. Resolution Center reply (draft to send with the resubmission)

> Hello, and thank you for the detailed feedback on Guideline 4.3(b).
>
> With version 3.0.0 we have substantially reworked GreenGo so it is **not a dating app** and does not duplicate that category. Specifically:
> - The home screen is now **Explore** — cultural experiences and local events browsed by **city, language and interest**. There is **no swipe deck** and **no match mechanic**.
> - We removed like / super-like / "it's a match", age-and-distance targeting, and all dating-oriented features (blind date, date scheduler, rematch, etc.).
> - The app now centres on **language exchange, cultural discovery and locally-hosted events** (see the Events and Community tabs).
> - Store category, screenshots and description have been updated to **Travel / Education** to reflect this.
>
> We believe this delivers a distinct experience — language-barrier-free cultural networking and learning-by-doing — not found elsewhere on the App Store. We're happy to provide a demo video or answer any questions. Thank you for reconsidering.

---

## 9. Risks & honest caveats

- **4.3(b) has no guarantee.** A reviewer may still subjectively flag it. Mitigation: the changes above are substantive and visible on screen 1; the appeal letter reinforces them.
- **Repeated rejection is possible.** If so → escalate via App Review Board, or ship the **PWA** as the iOS channel.
- **Glass performance** — must be validated on real devices (Impeller/emulator black-render gotcha).
- **Scope** — this is a major release; keep Android stable behind its flavor so nothing regresses for existing users.

---

*Prepared for the v3.0.0 repositioning. Interactive glass UI preview: https://claude.ai/code/artifact/8aee4601-a33e-4422-8d14-ad80ab9a51a5*
