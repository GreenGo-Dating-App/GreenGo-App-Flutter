# GreenGo Web — Migration 2.2.4 → 3.0.0

**Key fact:** the codebase is **unified**. Web builds from `lib/main.dart`, which is now the **culture / Explore-first 3.0.0** experience. So the web app *already is* 3.0.0 in code — there is **no separate web port to migrate**. The "migration" is really: **build 3.0.0 web → handle the web-specific concerns → redeploy** (the live `greengo-chat.web.app` still serves the old 2.2.4 build until we redeploy).

---

## Phase W0 — Code parity (already done)
- `main.dart` → culture flavor (Explore-first, glass, no dating) → **web inherits it automatically**.
- Dating features gated off everywhere (same flags).
- **Action:** none in code. Just confirm no `kIsWeb`-guarded dating UI slipped through.

## Phase W1 — PWA config (mostly done, verify)
- `web/manifest.json` rebranded, `web/index.html` iOS tags + `apple-mobile-web-app-capable`, `firebase.json` headers — done in the earlier PWA pass.
- **Still to do:** generate the `apple-touch-startup-image` **splash PNGs**, add `screenshots` to the manifest, build the **Add-to-Home-Screen** prompt (Android `beforeinstallprompt` + iOS Safari banner).

## Phase W2 — Web payments (critical — IAP ≠ web)
- Native IAP (Play/Apple) **cannot run in a browser** → web must use **Stripe Checkout** (`lib/core/services/stripe_web_checkout.dart`).
- **Action:** verify every purchase entry point (subscription tiers, coin shop, base membership) detects `kIsWeb` and routes to **Stripe**, never to `in_app_purchase`. Confirm success/cancel redirects + webhook → Firestore entitlement.
- Confirm the new **membership tier marketplace** (Part 3) also uses Stripe on web.

## Phase W3 — Responsive / desktop layout
- The app is mobile-first; on web it opens at desktop widths. Audit the 3.0.0 screens on wide viewports:
  - Explore carousel + Network grid (2/3/4 columns should scale up on desktop; the glass cards must not stretch ugly).
  - Bottom nav vs. a wider layout (consider a max-width app shell / centered column on desktop).
  - Hover states, mouse scroll on the carousels, keyboard focus.
- **Action:** add a `max-width` app shell for desktop + verify at 768/1024/1440.

## Phase W4 — Glass / performance on web
- `BackdropFilter` blur is heavier under CanvasKit. Verify the glass surfaces don't tank FPS on web; lower blur sigma / fewer layers on web if needed (`kIsWeb`).
- Image caching + list virtualization on the endless grids.

## Phase W5 — Build & deploy
```
flutter build web --release
NODE_TLS_REJECT_UNAUTHORIZED=0 firebase deploy --only hosting:app --project greengo-chat
```
- Target `app` → `greengo-chat.web.app`.
- Service worker (`flutter_service_worker.js`, no-cache header already set) pushes the update to returning 2.2.4 users on next load.
- **Action:** decide custom domain (`app.greengo.…`) vs. keep `greengo-chat.web.app`.

## Phase W6 — Verify on web
- Login (Firebase Auth) — note the **AVG TLS-MITM** issue is local-machine only; real users are unaffected.
- Full flow: Explore → Network filters → chat → tags → Events → Community → **Stripe purchase** → membership entitlement.
- PWA install (Android auto-prompt, iOS "Add to Home Screen").
- Responsive at phone / tablet / desktop.

---

## Rollout note
Because it's an SPA with a service worker, returning 2.2.4 web users receive 3.0.0 automatically on their next visit after the redeploy — no app-store review, instant. That makes **web the fastest channel** to ship the repositioned product while the iOS native review is pending.

**Estimated effort:** ~2–3 days (mostly W2 payment verification + W3 responsive + W5 deploy).
