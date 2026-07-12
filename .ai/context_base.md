# GreenGo — Context Base

> Repo-standard `.ai/context_base.md`. Keep this current so any agent or
> contributor can get oriented quickly.

## What GreenGo is

GreenGo is a cross-cultural **discovery, language-exchange and networking** app —
**not a dating app**. It centres on cultural discovery, language-barrier-free
networking and learning-by-doing (local events, community groups, cultural
exchange).

## Tech stack

- **Flutter** (Dart) mobile app; Firebase backend (Auth, Firestore, Storage,
  Crashlytics, Performance, Remote Config, App Check, FCM).
- **Clean Architecture + BLoC**, DI via `get_it` (`lib/core/di/injection_container.dart`).
- Also builds to **Flutter web** (PWA target) at `greengo-chat.web.app`.

## Layout (high level)

- `lib/main.dart` — default entrypoint + `AuthWrapper` routing and bootstrap.
- `lib/core/config/` — build/feature configuration (`app_config.dart`,
  `flavor_config.dart`).
- `lib/features/<feature>/` — Clean-Arch feature slices (data / domain / presentation).
- `lib/l10n/app_en.arb` — i18n source of truth; run `flutter gen-l10n`, never
  hardcode UI strings.

---

## v3.0.0 — Culture is the default everywhere (Apple Guideline 4.3(b))

**Version bumped `2.2.4+100` → `3.0.0+101`** (major bump: product repositioning,
not a patch; iOS build number must exceed the rejected 90 — 101 satisfies both
stores). Full plan: `APPLE_APPROVAL_PLAN_v3.0.0.md` at repo root.

**Decision (2026-07-10 — UNIFY EVERYWHERE):** the glass, Explore-first,
**non-dating** experience is now the **default on every platform (web, iOS and
Android)**. Dating mechanics are preserved in code but **OFF by default**,
re-enableable only through an opt-in "full" entrypoint. There is no per-platform
fork — one codebase, one default.

The single codebase ships in two **flavors**, selected by the entrypoint:

| Flavor | Entrypoint | Dating features | Distribution |
|---|---|---|---|
| `AppFlavor.culture` | `lib/main.dart` (**default**) | **OFF** — Explore-first, cultural-exchange | web + iOS + Android |
| `AppFlavor.full` | `lib/main_full.dart` | **ON** — full swipe/dating product | opt-in only (re-composable later) |

### `FlavorConfig` (`lib/core/config/flavor_config.dart`)

Dependency-free static switch. `FlavorConfig.current` defaults to
`AppFlavor.culture` (so `main.dart` yields the Explore-first experience with no
override). `main_full.dart` sets it to `AppFlavor.full` before delegating to the
shared `main()` bootstrap.

Boolean getters (all `false` on `culture`, all `true` on `full`):
`enableSwipeDiscovery`, `enableMatching`, `enableBlindDate`,
`enableDateScheduler`, `enableSecondChance`, `enableShareMyDate`,
`enableSpecialModes`, `enableVirtualGifts`, `enableVideoProfiles`.
Convenience getters: `isCulture` / `isFull`, plus **`exploreFirst`**
(`= !enableSwipeDiscovery`) — the flag the app shell branches on to present the
glass Explore home instead of the swipe DiscoveryScreen.

Build the opt-in full (dating) build with:
`flutter build apk --target lib/main_full.dart`
(the default `main.dart` needs no `--target` and is culture.)

### Navigation (`main_navigation_screen.dart`)

Branches on `FlavorConfig.exploreFirst`:

- **Explore-first (default):** tabs = Explore(0), Events(1), Community(2),
  Messages(3), Profile(4); frosted `GlassBottomNav`. No swipe `DiscoveryScreen`
  is mounted; the usage counters, match-count listener (`matches` collection),
  grid toggle and swipe-card tour anchoring are all guarded behind
  `enableSwipeDiscovery` so nothing dating-related runs or renders.
- **Full (opt-in):** legacy layout unchanged — Discovery(0), Messages(1),
  Groups(2), Events(3), Profile(4) with the solid `BottomNavigationBar`, match
  badge, grid toggle and gesture tour.

> **Next up:** broader dating-feature entrypoint gating (blind date, date
> scheduler, second chance, special modes, virtual gifts, video profiles) and
> wiring real events data into the Explore/Events tabs.
