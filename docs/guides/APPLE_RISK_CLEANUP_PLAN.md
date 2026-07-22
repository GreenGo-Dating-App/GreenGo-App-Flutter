# GreenGo — Apple Approval Risk Cleanup Plan

**Purpose:** Reduce the risk of an App Store rejection by fixing reviewer-facing signals and removing/neutralising **inactive ("useless") functionality** — **without changing any active code or working feature**.

**Guarantee for every item below:** it touches only (a) reviewer-facing text/config that does not affect runtime behavior, or (b) code that is already **flag-off / unreachable**. No item alters what a real user can do in the shipping app.

**Companion docs:** `APPLE_SUBMISSION_RUNBOOK.md` (how to submit), `APPLE_4.3b_RESPONSE_KIT.md` (beating the dating-spam denial), `APPLE_APPROVAL_PLAN_v3.0.0.md` (product repositioning strategy).

---

## 0. Risk assessment — what the code review found

### ✅ Already compliant — do NOT touch
| Area | Guideline | Evidence |
|---|---|---|
| In-app payments | 3.1.1 | iOS/Android use **StoreKit / Play Billing** (`coin_shop_screen.dart`: `if (kIsWeb) return;`, `InAppPurchase.instance`); Stripe is **web-only** (`stripe_web_checkout.dart` behind `kIsWeb`) |
| Sign in with Apple | 4.8 | `enableGoogleAuth/enableFacebookAuth/enableAppleAuth = false` → `showSocialLoginSection = false` → no third-party login renders → **Apple Sign-In not required** |
| Live video (UGC) | 1.2 | `enableVideoCalls = false`; `agora_rtc_engine` commented out → not reachable |
| Report / block | 1.2 | `features/safety/` (`block_user.dart`, `report_user.dart`, `blocked_users_service.dart`, `safety_actions_menu.dart`, `community_report.dart`) |
| Account deletion | 5.1.1(v) | `edit_profile_screen.dart` → `_showDeleteAccountDialog` → real Firestore + Firebase Auth deletion (`profile_bloc.dart`) |
| Encryption compliance | 2.1 | `ITSAppUsesNonExemptEncryption = false` in `Info.plist` |
| Location scope | 5.1.1 | All calls are one-shot `getCurrentPosition` (when-in-use). **No** `requestAlways` / background streaming |

### ⚠️ To address (this plan)
Reviewer-facing dating language in permission strings, an unused "Always" location declaration, dead Google/Facebook login code, and dead/gated dating + video-call artifacts that should be *verified unreachable*.

---

## Tier 1 — Reviewer-facing config · zero behavior change · do before submit

### 1.1 Reword iOS permission strings (`ios/Runner/Info.plist`)
**Why:** The OS shows these strings verbatim in the permission prompt. The current location text is a literal **dating signal** the 4.3(b) reviewer reads. Rewording changes **no** behavior.

| Key | BEFORE | AFTER (proposed) |
|---|---|---|
| `NSLocationWhenInUseUsageDescription` | "GreenGo needs your location to show **people near you** and calculate **distances**." | "GreenGo uses your location to show **local events, cultural experiences and language partners in your area**." |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | (same "people near you / distances") | **Remove entirely** — see 1.2 |
| `NSCameraUsageDescription` | "…take photos for your profile." | "GreenGo uses the camera to **take profile photos and scan QR codes**." *(app uses `mobile_scanner` for QR)* |
| `NSMicrophoneUsageDescription` | "…record voice messages." | Keep (accurate; video calls are off). |
| `NSPhotoLibraryUsageDescription` | "…upload profile pictures." | "GreenGo accesses your photos so you can **upload profile and event pictures**." |

**Functional impact:** none (string literals only).

### 1.2 Remove the unused "Always" location declaration
**Why:** Verified the app only uses **when-in-use** location (no `requestAlways`, no `getPositionStream`). Declaring `NSLocationAlwaysAndWhenInUseUsageDescription` advertises a background capability the app never uses → invites a 5.1.1/2.5.4 rejection question.
**Action:** delete the `NSLocationAlwaysAndWhenInUseUsageDescription` key from `Info.plist`.
**Functional impact:** none (nothing requests Always).

> Tier 1 needs a rebuild to ship, but is **safe** — no Dart/behavior changes. Rebuild + smoke-test on Pixel 9 (and iOS when available) per project rule.

---

## Tier 2 — Remove genuinely dead ("useless") functionality · inactive code only

### 2.1 Remove dead Google/Facebook login (approved)
**State:** already flag-off (`enableGoogleAuth=false`, `enableFacebookAuth=false`); social buttons never render; standalone plugins already commented out in `pubspec.yaml`.
**Proposed removal (all currently unreachable):**
- `auth_remote_data_source.dart`: `signInWithGoogle()`, `signInWithFacebook()` impls (+ interface entries)
- `auth_repository.dart` / `auth_repository_impl.dart`: `signInWithGoogle`/`signInWithFacebook`
- `auth_bloc.dart` / `auth_event.dart`: Google/Facebook events + handlers
- `login_screen.dart`: the `showSocialLoginSection` block + `_buildSocialLoginButton` calls
- `app_config.dart`: `enableGoogleAuth`, `enableFacebookAuth` flags
**Why:** 4.8 hygiene + removes the `facebookAuth.logOut()` reference and any lingering social-login surface.
**Functional impact:** none (buttons never render today). **Build-verify required** after removal.

> **Decision (per your choice): DEFER hard-removal.** Keep this documented; execute only if/when you want the cleanup. The safe minimum is that the section is already flag-off and unreachable.

### 2.2 Video-calling module — KEEP GATED (your choice), verify unreachable
**State:** `enableVideoCalls=false` → DI block in `injection_container.dart` (`if (AppConfig.enableVideoCalls)`) not registered; no call UI reachable. ARB still contains dating+video strings ("video call with your matches") but they are **not rendered**.
**Action:** **do not delete.** Verify (see Tier 3 checklist) that no chat/profile entry point starts a call while the flag is false.
**Functional impact:** none.

### 2.3 Gated-off dating features — KEEP GATED (your choice), verify unreachable
`swipe`, `matching`, `blind_date`, `date_scheduler`, `second_chance`, `share_my_date`, `special_modes`, `virtual_gifts`, `video_profiles` remain flag-gated per the v3.0.0 strategy (re-enableable later).
**Action:** **do not delete.** Verify unreachable in the default/iOS build. Hard-removal is explicitly **out of scope** here.

---

## Tier 3 — Reachability & server audit · no real-user behavior change

These are **audits**; any code change (e.g. gating a route) will be reported back for your approval before I touch active routing.

### 3.1 Runtime "no dating signal reachable" verification
Run on a real device with the demo account (mirrors `APPLE_4.3b_RESPONSE_KIT.md` §1). Confirm, with current flags:
- [ ] Home = Explore; no swipe deck / like / super-like / "It's a match" anywhere
- [ ] No Matches tab/badge; tabs are Explore/Events/Community/Messages/Profile
- [ ] No **video-call** button in chat or profile (flag off)
- [ ] No age/distance filter (language/interest/city only)
- [ ] No third-party login buttons on the login screen

### 3.2 Deep-link / push routing audit
`push_notification_service.dart` still routes `type: newMatch/newLike/superLike` and `greengo://u|e/*` deep links. Verify none of these open a gated-off dating screen. **If one does**, I'll propose gating just that destination (reported first — this is the only place that could touch active routing).

### 3.3 Server-side (Cloud Functions) — not app functionality
Stop emitting `newMatch/newLike/superLike` push types to the iOS audience (`functions/src/**`). Server change only; no app behavior impact.

---

## Tier 4 — Operational / store (not code)
Covered in the submission guides: App Privacy labels accuracy (5.1.1), category Travel/Education, de-dated screenshots/keywords, and a visible **Restore Purchases** action (3.1.1). No code in this repo required beyond confirming Restore exists in the coin/subscription UI.

---

## Execution order & impact summary

| # | Item | Files | Active functionality touched? | Needs rebuild |
|---|---|---|---|---|
| 1.1 | Reword permission strings | `Info.plist` | No | Yes |
| 1.2 | Remove Always-location key | `Info.plist` | No | Yes |
| 2.1 | Remove dead Google/FB login | auth + login_screen + app_config | No (deferred) | Yes (if done) |
| 2.2 | Video calling | — (verify only) | No | No |
| 2.3 | Gated dating features | — (verify only) | No | No |
| 3.1 | Runtime reachability audit | — (verify only) | No | No |
| 3.2 | Deep-link/push audit | report only | No (unless approved) | No |
| 3.3 | Server push types | `functions/src/**` | No (server) | No |

**Recommended first action:** Tier 1 only (Info.plist) — highest reviewer impact, zero functional risk — then the Tier 3.1 runtime audit.

## Sign-off checklist before submitting to Apple
- [ ] Permission strings reworded, Always-location removed (Tier 1)
- [ ] Runtime audit passes — no dating/video signal reachable (Tier 3.1)
- [ ] Deep-link/push audit done; no gated dating screen reachable (Tier 3.2)
- [ ] Server no longer sends dating push types to iOS (Tier 3.3)
- [ ] Restore Purchases visible in coin/subscription UI (Tier 4)
- [ ] (Optional) dead Google/FB login code removed (Tier 2.1)
