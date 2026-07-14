# GreenGo — App Store & Google Play Submission Guide

**Everything to enter in App Store Connect and Google Play Console to get GreenGo approved.**
**App:** GreenGo · **Bundle/App ID:** `com.greengochat.greengochatapp` (both platforms) · **Version:** `3.0.0+101`
**Positioning:** Cross-cultural discovery & language-barrier-free networking — **NOT a dating app**
**Date:** 2026-07-13 · **Status:** Submission-ready checklist

> This guide is the **field-by-field listing + compliance** reference. The *product-repositioning* strategy that clears Apple **Guideline 4.3(b) (dating spam)** lives in [`../../APPLE_APPROVAL_PLAN_v3.0.0.md`](../../../APPLE_APPROVAL_PLAN_v3.0.0.md) — read that first for Apple; this doc does not duplicate it.

## Documents
- **[APPLE_APP_STORE.md](./APPLE_APP_STORE.md)** — every App Store Connect field + the Apple guidelines that block approval.
- **[GOOGLE_PLAY.md](./GOOGLE_PLAY.md)** — every Play Console field + the Play policies that block approval.

---

## The 8 things that actually get a social app rejected (fix these first)

Metadata is easy; these are what cause real rejections for an app like GreenGo. Both stores.

| # | Blocker | Applies | What you must do |
|---|---|---|---|
| 1 | **Apple 4.3(b) — "this is a dating app / spam"** | Apple | Ship the repositioned v3.0.0 build: Explore-first, no swipe deck, dating features flag-off. See the approval plan. **The single biggest risk.** |
| 2 | **UGC safety (Apple 1.2 / Play UGC policy)** | Both | You have user profiles, chat, groups → you MUST provide: (a) EULA with **zero tolerance for objectionable content/abusive users**, (b) **report** content, (c) **block** users, (d) **filter/moderate**, (e) act on reports & eject violators within **24h**, (f) published contact. Missing any of these is an instant reject. |
| 3 | **In-app account deletion (Apple 5.1.1(v) / Google account-deletion policy)** | Both | A logged-in user must be able to **delete their account + data from inside the app**. Google **also** requires a **public web URL** to request deletion. |
| 4 | **Sign in with Apple (Apple 5.1.1(iv))** | Apple | If GreenGo offers Google/Facebook login, it **must also** offer **Sign in with Apple** on iOS. Verify it's wired before submitting. |
| 5 | **Digital-goods payments (Apple 3.1.1 / Google Payments)** | Both | Coins & Base Membership are **digital goods** → must use **Apple IAP** on iOS and **Google Play Billing** on Android. **Stripe is web-only** — never expose a Stripe/web-payment path or "buy on our website" link inside the mobile apps. |
| 6 | **Privacy: Data Safety / Privacy Nutrition Labels** | Both | Fill Apple "App Privacy" and Google "Data safety" **accurately and consistently with the privacy policy** in `legal/`. Mismatch = reject. Declare location, photos, contacts-none, identifiers, usage data, etc. |
| 7 | **Permissions justification** | Both | You request **location, camera, mic, photos, media, notifications**. Each needs a clear purpose string (iOS) / prominent disclosure (Android). Remove any permission you don't actually use (esp. legacy `WRITE_EXTERNAL_STORAGE`, background location). |
| 8 | **Demo account + reviewer notes** | Both | Provide a **working demo login** (no phone/OTP wall) and notes telling the reviewer where the cultural/events content is — so they don't perceive a dating app. |

---

## Shared listing values (use identically on both stores where the field exists)

| Field | Value |
|---|---|
| **App name** | GreenGo |
| **Subtitle / short tagline** | Cultural exchange, languages & local events |
| **Primary category** | Travel *(Apple)* / Travel & Local *(Google)* |
| **Secondary category** | Education |
| **Positioning keywords** | language exchange · cultural discovery · travel · local events · learn by doing · meet locals · community |
| **Privacy Policy URL** | *(host `legal/PRIVACY_POLICY_en.md` at a public URL — e.g. greengo-chat.web.app/privacy)* |
| **Terms URL** | *(host `legal/TERMS_AND_CONDITIONS_en.md` — e.g. greengo-chat.web.app/terms)* |
| **Support URL / email** | *(required — add a real support page + email)* |
| **Marketing URL** | greengo-chat.web.app *(optional)* |
| **Age rating** | Expect **17+ (Apple) / Mature-Teen (Google IARC)** — driven by unrestricted user communication + UGC. See per-platform questionnaires. |
| **Languages** | EN, IT, PT-BR, PT, ES, FR, DE *(match the `legal/` + l10n set)* |

> ⚠️ **Do NOT reuse dating vocabulary** anywhere in either listing (no "match", "singles", "nearby", "date", "hookup", "flirt"). Metadata keywords are a documented 4.3 signal. Description, keywords, screenshots, and preview must all read as cultural/language/travel.

---

## Pre-submission checklist (both platforms)
- [ ] v3.0.0+101 build, dating features flag-off (Apple), verified on a real device **and iPad** (Apple reviewed on iPad Air).
- [ ] In-app account deletion works end-to-end; Google deletion **web URL** live.
- [ ] Report content · block user · moderation · EULA (no objectionable content) all present and testable.
- [ ] Sign in with Apple present (iOS) alongside any other social login.
- [ ] Coins + Membership go through Apple IAP / Play Billing; **no** web-payment path in the app binary.
- [ ] Privacy Policy + Terms hosted at public HTTPS URLs; Data Safety / App Privacy filled to match.
- [ ] Every requested permission is used + justified; unused ones removed.
- [ ] Demo account + reviewer notes prepared (see per-platform docs).
- [ ] Screenshots show Explore / Events / Community / language exchange — **no swipe deck, no faces grid**.

*Companion: [`../../APPLE_APPROVAL_PLAN_v3.0.0.md`](../../../APPLE_APPROVAL_PLAN_v3.0.0.md) (4.3(b) strategy) · [`../plan_on_scale/`](../plan_on_scale/) (backend scaling).*
