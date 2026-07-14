# GreenGo — Google Play Console Submission

**Every field to enter in Play Console, plus the policies that block approval.**
Application ID: `com.greengochat.greengochatapp` · versionName `3.0.0` · versionCode `101` · Date: 2026-07-13

> Google is less subjective than Apple's 4.3, but it enforces **Data safety**, **account deletion**, **UGC**, **permissions**, and **payments** strictly and via automated + human review. The blockers below are what actually cause Play rejections/suspensions for an app like GreenGo.

---

## 1. Store listing (→ Grow → Store presence → Main store listing)
| Field | Limit | Value |
|---|---|---|
| **App name** | 30 | `GreenGo` |
| **Short description** | 80 | `Discover cultures, exchange languages, and join local events — learn by doing.` |
| **Full description** | 4000 | Cultural discovery / language exchange / local events / community. No dating vocabulary. Draft in §2. |
| **App icon** | 512×512 PNG, 32-bit | Brand icon (gold/black). |
| **Feature graphic** | 1024×500 | Required — cultural/travel theme, app name, no faces grid. |
| **Phone screenshots** | 2–8, min 320px | Explore / Events / Community / language chat (glass UI). |
| **7" & 10" tablet screenshots** | recommended | Same non-dating screens (helps featuring + tablet quality). |
| **Promo video** | YouTube URL | Optional. |

## 2. Full description draft (paste & refine)
```
GreenGo is a cross-cultural discovery app for exploring new cultures, exchanging
languages, and joining local events — learning by doing.

• EXPLORE CULTURES — browse experiences, languages and interests by city.
• LANGUAGE EXCHANGE — practice with real people, with translation and
  text-to-speech to break the language barrier.
• LOCAL EVENTS — find cultural events and activities near you, and see who's going.
• COMMUNITY — join interest and language-exchange groups and chat.

GreenGo is about culture, learning and genuine connection. Optional Membership and
coins unlock premium features like advanced translation and text-to-speech.
```

## 3. Store settings (→ Store settings)
| Field | Value |
|---|---|
| **App category** | **Travel & Local** (primary). *(Education is an acceptable alternative; avoid "Dating".)* |
| **Tags** | Choose culture/travel/education/social tags; avoid dating tags. |
| **Contact details** | Email (required), phone, website — must be real. |
| **External marketing** | Off unless intended. |

## 4. Data safety form (→ Policy → App content → Data safety) — MUST match `legal/PRIVACY_POLICY_en.md`
Declare all collection/sharing accurately (mismatch with the policy = rejection). Typical GreenGo answers:

| Data type | Collected | Shared | Purpose | Processing |
|---|---|---|---|---|
| **Location (approx + precise)** | Yes | No | App functionality (nearby events) | Not required to use? mark accordingly |
| **Personal info (name, email, user IDs)** | Yes | No | Account, app functionality | Encrypted in transit |
| **Photos & videos** | Yes | No | App functionality (profile/chat) | User can request deletion |
| **Messages / in-app content (UGC)** | Yes | No | App functionality | |
| **App activity / interactions** | Yes | No | Analytics, app functionality | Firebase |
| **Crash logs & diagnostics** | Yes | No | App functionality, analytics | Crashlytics |
| **Purchase history** | Yes | No | App functionality | Play Billing |
| **Financial info** | Handled by Google Play Billing | — | — | Don't collect card data in-app |

- **Data encrypted in transit:** Yes. **Users can request deletion:** Yes (see §7).
- **Privacy Policy URL:** host `legal/PRIVACY_POLICY_en.md` publicly and enter here (required).

## 5. App content declarations (→ Policy → App content)
Complete **all** of these — each is a gate:
- [ ] **Privacy policy** URL.
- [ ] **Ads** — declare whether the app contains ads (likely **No**).
- [ ] **App access** — provide a **demo login** (email + password, OTP-free) + instructions, since content is behind sign-in.
- [ ] **Content rating** — complete the **IARC questionnaire** (§6).
- [ ] **Target audience & content** — target **18+ / adults** (or 13+); **do NOT target children** (avoids Families policy + stricter data rules). Declare that the app is not primarily child-directed.
- [ ] **News app** — No.
- [ ] **Data safety** — §4.
- [ ] **Government / financial / health** — No (Membership/coins are app features, not regulated financial services).
- [ ] **Advertising ID** — declare if you use it (Firebase Analytics may). If unused, remove the `AD_ID` permission.

## 6. Content rating (IARC questionnaire → App content → Content rating)
Answer honestly. For GreenGo the drivers are **user interaction / user-generated content / shares location** → typically lands around **Teen / Mature**. Declare:
- Users can interact / communicate: **Yes**.
- User-generated content: **Yes** (→ triggers UGC obligations, §8).
- Shares user location: **Yes**.
- Digital purchases: **Yes**.
- Violence/sexual/gambling content: **No**.

## 7. Account deletion (→ App content → Data deletion) — REQUIRED
Google requires BOTH:
- [ ] **In-app** account + data deletion flow (logged-in user can delete).
- [ ] A **public web URL** where a user can **request account + data deletion without reinstalling the app** — enter that URL in the Data deletion section. (Host a simple deletion-request page, e.g. `greengo-chat.web.app/delete-account`.)

## 8. User-generated content policy (profiles, chat, groups)
Play's UGC policy requires, and reviewers check for:
- [ ] **Report** content/users, and **block** users — in-app.
- [ ] **Moderation** of objectionable content (you have Cloud Functions safety/moderation).
- [ ] A published way to contact you + a stated content policy in Terms (`legal/TERMS_AND_CONDITIONS_en.md`).
- [ ] Remove violating content and repeat offenders.

## 9. Permissions (→ declared in `AndroidManifest.xml`; some need a declaration form)
You currently declare: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `CAMERA`, `RECORD_AUDIO`, `READ_MEDIA_IMAGES/VIDEO/AUDIO`, legacy `READ/WRITE_EXTERNAL_STORAGE`, `POST_NOTIFICATIONS`, `VIBRATE`, `INTERNET`.

| Permission | Action |
|---|---|
| **Location (fine/coarse)** | Must show a **prominent in-app disclosure** before requesting, and the purpose (nearby events/people) must be obvious. If you do NOT use **background** location, ensure no `ACCESS_BACKGROUND_LOCATION` is declared (it triggers a separate, strict review). |
| **Photos/media & camera** | Justified by profile/chat media. With `READ_MEDIA_*` on Android 13+, the legacy `READ/WRITE_EXTERNAL_STORAGE` should be **removed or `maxSdkVersion`-capped** — unused broad storage access is flagged. |
| **RECORD_AUDIO** | Justified by voice/TTS/video calls — keep only if used. |
| **POST_NOTIFICATIONS** | Fine (FCM). |
| **AD_ID** | If you don't run ads, remove the `com.google.android.gms.permission.AD_ID` permission and declare "no advertising ID" in Data safety. |

## 10. Payments (Google Play Billing)
- Coins (**consumable**) and Base Membership (**subscription**) are **digital goods** → must use **Google Play Billing** (you ship Play Billing 8.0.0). 
- **Do not** offer or link to Stripe/web checkout for these inside the app — that violates the Payments policy. Stripe remains web-only.
- Configure products in **Monetize → Products** (in-app products + subscriptions) with localized titles/descriptions and prices.

## 11. Release setup (→ Production → Create release)
| Item | Value |
|---|---|
| **Format** | Android App Bundle (`.aab`) — signed with your `greengo-release.keystore`; enroll in **Play App Signing**. |
| **versionCode / versionName** | `101` / `3.0.0`. |
| **Target API level** | Must meet Google's current minimum (bump `targetSdk` to the latest required). `minSdk 24` is fine. |
| **Pre-launch report** | Review it (crashes, accessibility, privacy) before rollout. |
| **Countries / staged rollout** | Start with a staged rollout (e.g. 20%) and watch vitals. |
| **Testing tracks** | Use **Closed/Internal testing** first; note Play now often requires a testing period + testers for new personal developer accounts. |

## 12. Store-listing metadata policy
- No dating keywords ("match", "singles", "hookup"), no misleading claims, no other brands' names, no "free" if it has paid features. Keep the listing consistent with actual functionality.

---

### Google submission order
1. Build signed **.aab** `3.0.0(101)`, dating features off, target latest API level.
2. Fill Main store listing (name, descriptions, icon, feature graphic, screenshots incl. tablet).
3. Complete **all** App content declarations: privacy policy, ads, app access (demo login), content rating (IARC), target audience, **data safety**, **data deletion (in-app + URL)**.
4. Verify UGC controls (report/block/moderate), account deletion, Play-Billing-only payments, permission hygiene (drop unused storage/AD_ID/background-location).
5. Configure IAP + subscription products.
6. Upload to Internal/Closed testing → check pre-launch report → promote to Production (staged).
