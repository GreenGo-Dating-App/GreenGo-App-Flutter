# Plan: Update `greengo-app-flutter-web` to the latest GreenGo (3.0.0)

**Date:** 2026-07-17
**Goal (as requested):** update the web repo `GreenGo-Dating-App/greengo-app-flutter-web` so `greengo-chat.web.app` runs the latest GreenGo with all mobile changes.
**Author's note:** supersedes the 2026-07-13 investigation (`README.md` in this folder) with the current repo state and your decision to keep/update the web repo.

---

## 0. The situation, stated plainly (read first)

| Repo | GitHub | Version | Product generation | Deploys to |
|---|---|---|---|---|
| **Mobile = source of truth** | `GreenGo-Dating-App/GreenGo-App-Flutter` | **3.0.0+101** | Cultural discovery (non-dating, Apple-4.3b safe) | `hosting:app` → `greengo-chat.web.app` |
| **Web repo (to update)** | `GreenGo-Dating-App/greengo-app-flutter-web` | **1.8.0+53** | **Old dating app** (swipe/match, "hybrid direct match") | `hosting:app` → **same** `greengo-chat.web.app` |

Two facts that shape the whole plan:

1. **The web repo is not "behind" — it's a deprecated product.** ~48 versions and ~119 Dart files back, built around the swipe/match/dating UX that 3.0.0 deliberately removed. Its four big screens (Discovery/Chat/Profile/Events) diverged; per project rule, **never wholesale-copy those diverged screens back in.**
2. **Both repos point at the same Firebase hosting target.** Whichever deploys `hosting:app` last wins `greengo-chat.web.app`. This is a footgun regardless of which path we take.

The mobile repo **already is the web app**: its `firebase.json` declares `hosting:app → build/web`, its `codemapic.yaml` has a `web-release` job, and `web/` is fully GreenGo-branded. So "the latest web" already exists in the mobile repo — it just hasn't been rebuilt/redeployed since 2026-07-15 (~40 commits ago).

### Recommended path (Option A — replace, not merge)
Make `greengo-app-flutter-web` a **mirror of the unified 3.0.0 codebase** rather than trying to merge 48 versions of dating code forward. Concretely: overwrite the web repo's app code with the mobile repo's `lib/` + `web/` + config, keeping only anything genuinely web-repo-specific (there is very little). This is faster, safe, and can't reintroduce dating UI. Steps in §2.

> If instead you want the web repo to stay an independent fork and cherry-pick features forward, that's Option B in §5 — it is much larger, risks re-importing dating UX, and is **not recommended**.

---

## 1. Pre-flight (30 min)

- [ ] Confirm the intent: **web repo mirrors 3.0.0** (Option A). If yes, continue.
- [ ] Clone the web repo fresh locally (only a stale scratchpad clone exists today):
  `git clone https://github.com/GreenGo-Dating-App/greengo-app-flutter-web.git`
- [ ] Snapshot/branch the web repo's current `main` as `archive/dating-1.8.0` so the old dating build is never lost.
- [ ] **De-footgun the deploy target:** decide whether the web repo keeps deploying `hosting:app` (production) or a **preview channel** until verified. Until Option A lands, do NOT let either repo deploy `app` blindly.

## 2. Bring the web repo to 3.0.0 (Option A — ½–1 day)

- [ ] In the web repo, replace with the mobile repo's current `main` contents:
  - `lib/` (entire app — 809 Dart files, unified culture/Explore-first UX)
  - `web/` (index.html, manifest.json, `.well-known/`, `u/`, `e/`, `firebase-messaging-sw.js`)
  - `pubspec.yaml` + `pubspec.lock` (Billing 8 / `in_app_purchase ^3.3.0`, ML Kit pins)
  - `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`, `storage.rules`
  - `functions/` if the web repo is expected to deploy them (otherwise leave functions to the mobile repo only — recommended: **one repo owns functions**).
  - `codemagic.yaml` web-release job.
- [ ] Restore the 3 gitignored configs (they never live in git): `firebase_options.dart`, `google-services.json`, signing keystore — from `Desktop/Projects/GreenGo/greengo-secrets` / the credentials file.
- [ ] Bump the web repo `pubspec` version to match (`3.0.0+101`) so the two never disagree.
- [ ] Delete/quarantine the diverged dating screens that Option A overwrote (Discovery swipe, match, etc.) so no dead dating routes remain.
- [ ] `flutter pub get` → confirm a clean resolve.

## 3. Web-target hardening (½–1 day) — applies to the code regardless of repo

These are the web-only concerns for the ~40 commits since the last web build. Most are already handled in 3.0.0; verify each.

- [ ] **`dart:io` runtime guards** — 35 files import `dart:io`. Audit the newest surfaces for web-reachable `File(...)`/`Platform.isX` without a `kIsWeb` branch:
  - block/report cascade, communities first-time guide, event report/leave, featured/happening-soon.
  - On web, always upload via `XFile.readAsBytes()` → `Reference.putData(bytes)`, never `File(xfile.path)`.
- [ ] **FCM web push** (was the #1 gap; now partially done):
  - `web/firebase-messaging-sw.js` exists (untracked → commit it).
  - `getToken(vapidKey: WebPushConfig.vapidPublicKey)` is wired — **drop in the real VAPID public key** (Firebase console → Cloud Messaging → Web Push certificates).
  - Verify `functions/.../pushParity.ts` accepts web tokens and the SW shows notifications.
- [ ] **Payments** — every purchase entry (subscription tiers, coin shop, base membership, tier marketplace) must detect `kIsWeb` → **Stripe Checkout** (`stripe_web_checkout.dart`), never `in_app_purchase`. Confirm success/cancel redirect + webhook → Firestore entitlement.
- [ ] **Maps / scanner / audio** — `web_map_placeholder.dart` swaps `GoogleMap` on web (keep); gate `mobile_scanner` QR-scan entry behind `!kIsWeb` with a manual-code fallback; verify `record` produces an uploadable blob on web.
- [ ] **No-web plugins** — confirm Crashlytics, `flutter_local_notifications`, `path_provider`, App Check are `kIsWeb`-guarded / early-return (already true in 3.0.0; re-verify after any new calls).

## 4. Responsive + glass perf (½–1 day)

- [ ] Desktop app-shell: max-width centered column so glass cards don't stretch at 1440.
- [ ] Explore carousel + Network grid: 2/3/4 columns scale up; hover, mouse-wheel scroll, keyboard focus.
- [ ] Lower `BackdropFilter` blur sigma on web (`kIsWeb`) — CanvasKit blur is expensive.
- [ ] Verify at 768 / 1024 / 1440.

## 5. Option B (independent fork — NOT recommended)

Only if the web repo must remain an independently-evolving fork: cherry-pick the 48 versions of feature work forward branch-by-branch, resolving the diverged 4 big screens by hand. This is multi-week, high-risk (re-imports dating UX), and duplicates every future change. Documented here only to be explicit that it was considered and rejected in favor of §2.

## 6. Build, smoke-test, deploy (½ day)

```bash
flutter build web --release
NODE_TLS_REJECT_UNAUTHORIZED=0 firebase deploy --only hosting:app --project greengo-chat
```

- [ ] **Run it, don't just build it** (project rule): full flow Explore → Network filters → chat → tags → Events → Community → **Stripe purchase** → membership entitlement.
- [ ] PWA install (Android `beforeinstallprompt`, iOS "Add to Home Screen").
- [ ] Responsive phone/tablet/desktop.
- [ ] Note: SPA + service worker (`flutter_service_worker.js`, no-cache) pushes 3.0.0 to returning users automatically on next visit — **no store review, instant**. Web is the fastest channel to ship the repositioned product.
- [ ] Local `firebase deploy` needs `NODE_TLS_REJECT_UNAUTHORIZED=0` (AVG TLS-MITM on this machine only; real users unaffected).

---

## Effort estimate
**Option A (recommended): ~2.5–3.5 days**, front-loaded on §2 (mirror) + §3 (hardening audit).
Option B: multi-week, not recommended.

## Open decisions for the owner
1. **Option A (mirror) vs B (independent fork)?** — recommend A.
2. **Who owns Cloud Functions & firestore rules** — mobile repo only, or both? Recommend: **one repo owns them** to avoid double-deploy drift.
3. **Retire the footgun:** long-term, should the web repo exist at all, or should web ship from the unified mobile repo's `web-release` job? Recommend consolidating to one repo after this sync.
