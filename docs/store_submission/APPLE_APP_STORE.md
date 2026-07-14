# GreenGo — Apple App Store Connect Submission

**Every field to enter in App Store Connect, plus the guidelines that block approval.**
Bundle ID: `com.greengochat.greengochatapp` · Version `3.0.0` · Build `101` · Date: 2026-07-13

> Read [`../../APPLE_APPROVAL_PLAN_v3.0.0.md`](../../APPLE_APPROVAL_PLAN_v3.0.0.md) FIRST — it covers the **Guideline 4.3(b) dating-spam** repositioning (Explore-first build, no swipe deck). This doc is the concrete listing + compliance checklist that sits on top of it.

---

## 1. App information (App Store Connect → App Information)
| Field | Value / guidance |
|---|---|
| **Name** (30 char max) | `GreenGo` |
| **Subtitle** (30 char max) | `Cultural exchange & languages` (29) |
| **Bundle ID** | `com.greengochat.greengochatapp` |
| **Primary category** | **Travel** |
| **Secondary category** | **Education** |
| **Content rights** | Confirm you own or are licensed for all content (events data from Geoapify/Viator/Ticketmaster — ensure attribution/licensing terms are met). |
| **Age rating** | Complete the questionnaire (§7). Expect **17+** due to *Unrestricted Web Access* / user-generated content / frequent user communication. |

## 2. Version metadata (→ [Version] → App Store tab)
| Field | Value / guidance |
|---|---|
| **Promotional text** (170 char, editable anytime) | "Explore cultures, exchange languages, and join local events near you. Meet locals, practice a language, and learn by doing — no barriers." |
| **Description** (4000 char) | Lead with cultural discovery / language exchange / local events / community. **Zero dating vocabulary.** Draft in §3. |
| **Keywords** (100 char, comma, no spaces) | `language exchange,cultural,travel,local events,learn,community,meet locals,expat,languages` |
| **Support URL** | Required — a real support page + email. |
| **Marketing URL** | `https://greengo-chat.web.app` (optional). |
| **Version** | `3.0.0` |
| **Copyright** | `2026 GreenGo` |
| **Routing App Coverage / Sign-in required** | Provide demo account (§8). |

## 3. Description draft (paste & refine — no dating terms)
```
GreenGo is a cross-cultural discovery app that helps you explore new cultures,
exchange languages, and join local events — learning by doing.

EXPLORE CULTURES
Browse experiences, languages, and interests by city. Discover what's happening
around you and connect with people who share your curiosity.

LANGUAGE EXCHANGE, NO BARRIERS
Practice a new language with real people. Built-in translation and text-to-speech
help you communicate across languages from day one.

LOCAL EVENTS & EXPERIENCES
Find cultural events, meetups, and activities nearby, and see who's going.

COMMUNITY
Join interest and language-exchange groups, chat, and build genuine connections
around culture and learning — not swiping.

GreenGo is about learning, culture, and connection. Membership and coins unlock
premium features like advanced translation and text-to-speech.
```

## 4. Screenshots & preview (→ Media Manager)
**Critical: reviewers rejected build 90 on an iPad Air — you MUST upload iPad screenshots, and none may show a swipe deck or a grid of faces.**

| Asset | Requirement |
|---|---|
| iPhone 6.9" (1290×2796) | Required. Show **Explore, Events, Community, language-exchange chat** (glass UI). |
| iPhone 6.5" (1242×2688) | Recommended fallback. |
| **iPad 13" (2064×2752)** | **Required** — this is where you were reviewed. Same non-dating screens. |
| App Preview video | Optional but persuasive — a 15–30s walkthrough of Explore→Events→Community. |
| No dating signals | No "like/super-like/nope", no "It's a match", no faces grid, no age/distance targeting. |

## 5. App Privacy (→ App Privacy) — must match `legal/PRIVACY_POLICY_en.md`
Declare data collection accurately. Typical for GreenGo:

| Data type | Collected? | Linked to user | Used for | Notes |
|---|---|---|---|---|
| **Precise/Coarse Location** | Yes | Yes | App functionality (nearby events/people) | Justified by `NSLocation…UsageDescription`. |
| **Photos/Media** | Yes | Yes | App functionality (profile, chat media) | `NSPhotoLibraryUsageDescription`. |
| **Contact info (name, email)** | Yes | Yes | Account, app functionality | From auth. |
| **User content (messages, photos, profile)** | Yes | Yes | App functionality | UGC. |
| **Identifiers (user ID)** | Yes | Yes | App functionality, analytics | Firebase UID. |
| **Usage data / diagnostics** | Yes | Maybe | Analytics, app functionality | Firebase/Crashlytics/Performance. |
| **Purchases** | Yes | Yes | App functionality | IAP. |
| **Tracking (ATT)** | Only if you track across apps | — | — | If you do NOT track, declare "not used for tracking" and skip App Tracking Transparency. If you DO, you must show the ATT prompt (Guideline 5.1.2). |

- **Privacy Policy URL:** host `legal/PRIVACY_POLICY_en.md` at a public HTTPS URL and enter it here (required).

## 6. In-App Purchases & Subscriptions (→ Monetization → In-App Purchases / Subscriptions)
| Item | Type | Notes |
|---|---|---|
| **Coins** | **Consumable** IAP | Create products, set price tiers, add localized display name/description, add review screenshot. |
| **Base Membership** | **Auto-Renewable Subscription** | Create a Subscription Group; add localized metadata + review screenshot; provide the required **subscription disclosures** (price, term, auto-renew) in the app's paywall + a link to Terms (EULA) and Privacy. |
| **Guideline 3.1.1** | — | On iOS, coins & membership MUST use Apple IAP. **Do not** show Stripe/web-checkout or "buy on our site" anywhere in the iOS binary — that's a hard reject. Stripe stays web-only. |
| **Restore purchases** | — | Provide a working "Restore Purchases" control (required for subscriptions/non-consumables). |

## 7. Age rating questionnaire (→ App Information → Age Rating)
Answer honestly. For GreenGo the drivers are:
- **Unrestricted web access** (in-app links/browsers) → pushes to 17+ if present; disable if not needed.
- **User-generated content / user communication** → declare it; this typically yields **17+** for social apps and requires the §9 safety controls.
- Gambling / contests / mature themes → **No** (unless you add them).

## 8. App Review Information (→ Version → App Review Information)
| Field | Value |
|---|---|
| **Sign-in required** | Yes → provide a **demo account** (email + password) that bypasses phone/OTP and has content pre-populated. |
| **Demo notes** | "GreenGo is a cultural-exchange & language-learning app. On launch you land on **Explore** (cultures/experiences), tab 2 is **Events**, tab 3 is **Community/language groups**. There is no dating/swipe feature. To test IAP use the sandbox account. Location is used to show nearby events." |
| **Contact** | Real name, phone, email of someone who can answer within 24h. |
| **Attachments** | Optional: a short note/screenshots pointing to the cultural content. |

## 9. Guideline 1.2 — UGC safety (MANDATORY, common reject reason)
Because GreenGo has profiles, chat, and groups, **all** of these must exist and be testable, or Apple rejects:
- [ ] **EULA** with a clear statement of **no objectionable content and no abusive behavior** (either use Apple's standard EULA or link your `legal/TERMS_AND_CONDITIONS_en.md` which must contain this clause).
- [ ] **Filtering/moderation** of objectionable content (automated and/or manual — you have Cloud Functions safety/moderation).
- [ ] **Report** mechanism on content and users.
- [ ] **Block** abusive users.
- [ ] **Act within 24h**: remove content + eject the offending user, and a way to contact you.

## 10. Sign in with Apple (Guideline 5.1.1(iv))
- If GreenGo offers Google/Facebook (or any third-party social login), it **must** also offer **Sign in with Apple** on iOS. Verify it is implemented and visible on the login screen **before** submitting.

## 11. Account deletion (Guideline 5.1.1(v))
- A logged-in user must be able to **initiate account + data deletion from within the app** (not just deactivate). Confirm the flow works and actually deletes Firestore/Auth data.

## 12. Export compliance & build settings
| Field | Value |
|---|---|
| **Uses encryption** | Almost certainly "Yes, but only exempt (HTTPS/standard)" → set `ITSAppUsesNonExemptEncryption = NO` in `Info.plist` to skip the yearly prompt, if you only use standard crypto. |
| **Build number** | `101` (must exceed the rejected `90`). |
| **TestFlight** | Recommended: push to TestFlight, run the §Pre-submission checklist on device + iPad before promoting. |

## 13. Resolution Center (if rejected again)
Reply factually: state GreenGo is a cultural-exchange/language app, list the concrete non-dating changes (Explore-first, swipe deck removed, dating features disabled), and point to the exact screens. See the approval plan for the full reply template.

---

### Apple submission order
1. Bump `3.0.0+101`, verify dating-off build on device **and iPad**.
2. Create IAP/subscription products + review screenshots.
3. Fill App Information, Version metadata, Description, Keywords.
4. Upload iPhone **and iPad** screenshots (no dating signals).
5. Complete App Privacy + Age Rating.
6. Verify UGC safety, Sign in with Apple, account deletion, IAP-only payments.
7. Enter App Review demo account + notes.
8. Submit. If 4.3(b) recurs → Resolution Center reply; PWA is the iOS fallback channel.
