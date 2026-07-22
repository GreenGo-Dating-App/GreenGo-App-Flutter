# GreenGo — Apple App Store Submission Runbook (v3.0.0)

**Purpose:** The click-by-click operational steps to submit GreenGo `3.0.0 (101)` to the App Store and get it approved. This is the *how to submit* companion to:
- `APPLE_APPROVAL_PLAN_v3.0.0.md` (the product/code strategy for the 4.3(b) rejection — already implemented)
- `docs/guides/APPLE_4.3b_RESPONSE_KIT.md` (how to beat the dating-spam denial + reviewer reply)

> Google Play is already approved — nothing here touches Android.

## Project facts (fill the blanks marked ⟨…⟩ from your accounts)

| Item | Value |
|---|---|
| App name | GreenGo |
| Bundle ID | `com.greengochat.greengochatapp` |
| Marketing version | `3.0.0` |
| Build number | `101` (must be > previously-rejected `90`) |
| Firebase project | `greengo-chat` (#666632803027) |
| iOS min deployment | 15.5 |
| Apple Team ID | ⟨from developer.apple.com → Membership⟩ |
| Primary category | **Travel** |
| Secondary category | **Education** |
| Support URL | ⟨e.g. https://greengo-chat.web.app/support⟩ |
| Privacy Policy URL | ⟨required — must be live before submit⟩ |

---

## Phase 0 — Pre-flight (do this first, once)

1. **Paid Apple Developer account** active (renewed, not expired).
2. **Agreements** — App Store Connect → Business → *Paid Apps* / *Free Apps* agreements all show **Active**. A pending agreement silently blocks submission.
3. **Bank + Tax** filled if the app or IAP is paid (GreenGo has coins/IAP → required).
4. Xcode is current; you can sign in under Xcode → Settings → Accounts with the Apple ID on the team.
5. Confirm the **4.3(b) code work is live in this build** — run the checklist in `APPLE_4.3b_RESPONSE_KIT.md` §1 **before** archiving. Do not archive a build where a swipe deck / "It's a match" is reachable.

---

## Phase 1 — App Store Connect record

1. Go to **App Store Connect → Apps**. If the app already exists (it was rejected before), open it — don't create a new one.
2. If new: **+ → New App**
   - Platform: iOS
   - Name: **GreenGo**
   - Primary language: English (U.S.)
   - Bundle ID: `com.greengochat.greengochatapp` (must already exist in Certificates, IDs & Profiles → Identifiers)
   - SKU: `greengo-ios` (any unique string)
3. **App Information** (left sidebar):
   - Category → Primary **Travel**, Secondary **Education** *(this is a core 4.3(b) signal — do NOT leave it as Social/Lifestyle)*
   - Content Rights: confirm you have rights to all content.
   - Age Rating → **Edit** → answer honestly. GreenGo is user-generated social + messaging: expect **12+** (infrequent/mild content, unrestricted web = No if you sandbox links). Answer *"Made for Kids" = No*.

---

## Phase 2 — Version metadata (the 4.3(b) battleground)

Open the **3.0.0** version page (create it with the **(+) next to iOS App** if needed).

1. **Promotional text** (170 chars, editable without review):
   > Explore cultures, exchange languages, and join local events — barrier-free.
2. **Subtitle** (30 chars):
   > Cultural exchange & languages
3. **Description** — lead with cultural discovery / language exchange / events. **No** "match", "singles", "nearby dating", "swipe". Reuse the positioning from `APPLE_APPROVAL_PLAN_v3.0.0.md` §4.5.
4. **Keywords** (100 chars, comma-sep, no spaces):
   > language exchange,cultural,travel,local events,learn,community,meet locals,expat
   Avoid: `match,dating,singles,hookup,nearby,flirt` — any of these invites 4.3(b).
5. **Screenshots** — upload the **Explore / Events / Community / language-exchange** glass screens. **No swipe deck, no grid of faces.** Required sizes:
   - 6.9" iPhone (1320×2868 or 2868×1320) — *required*
   - 6.5"/6.7" iPhone
   - 13" iPad (2064×2752) — *required because the rejection review device was an iPad Air*; make sure the iPad screenshots are the non-dating Explore UI.
6. **App Preview** (optional video) — if you record the demo (see Response Kit §3), upload here; it reinforces the non-dating story.
7. **Support URL** and **Marketing URL** (optional).
8. **Copyright**: `2026 GreenGo`.

---

## Phase 3 — App Privacy (nutrition labels)

App Store Connect → your app → **App Privacy → Edit**. GreenGo collects a lot; declare it accurately or risk rejection under 5.1.

Typical declarations for this app (verify against your Firebase/analytics usage):
- **Contact Info**: Email, Name — *App Functionality, Account*.
- **User Content**: Photos, Messages, other user content — *App Functionality*.
- **Identifiers**: User ID, Device ID — *App Functionality, Analytics*.
- **Location**: Coarse and/or Precise — *App Functionality* (discovery/events by city). If you only use coarse city, declare Coarse.
- **Usage Data**: Product interaction — *Analytics* (Firebase Analytics).
- **Diagnostics**: Crash data, Performance — *Analytics* (Crashlytics/Performance).
- **Purchases**: Purchase history — *App Functionality* (coins/IAP).

For each: set **Linked to identity** and **Used for tracking** correctly. If you don't run cross-app ad tracking, *Used for tracking = No* everywhere (then you do **not** need App Tracking Transparency prompt).

> Privacy Policy URL is **mandatory** and must be reachable at submit time.

---

## Phase 4 — Build: archive & upload

1. In `ios/`, make sure signing is set: Xcode → Runner target → **Signing & Capabilities** → *Automatically manage signing*, Team = ⟨your team⟩.
2. Confirm capabilities present: **Push Notifications**, **Background Modes** (Remote notifications), **Associated Domains** (`applinks:greengo-chat.web.app`). (See the iOS push guide — the release entitlement must use `aps-environment = production`.)
3. Set the run destination to **Any iOS Device (arm64)**.
4. Bump nothing else — `pubspec.yaml` is already `3.0.0+101`. Regenerate iOS build files:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ipa --release
   ```
   This produces `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/*.ipa`.
5. Upload — either:
   - **Transporter** app (drag the `.ipa`), or
   - Xcode → Product → Archive → **Distribute App → App Store Connect → Upload**.
6. Wait ~5–30 min for the build to finish **processing** in App Store Connect → TestFlight. Resolve any email about missing compliance (see Phase 5).

---

## Phase 5 — Compliance answers

1. **Export Compliance** (asked on the build): GreenGo uses HTTPS/standard crypto only → answer *Uses encryption = Yes*, then *Exempt (standard encryption)* = Yes. To skip the prompt each time, add to `ios/Runner/Info.plist`:
   ```xml
   <key>ITSAppUsesNonExemptEncryption</key>
   <false/>
   ```
2. **Content Rights** — you have rights: Yes.
3. **IDFA / Advertising** — if you don't serve ads or track, answer **No** to using IDFA.

---

## Phase 6 — Review information (critical for 4.3(b))

On the version page → **App Review Information**:
1. **Sign-in required = Yes.** Provide a **working demo account** (email + password) that is already past onboarding and lands on **Explore**. Test it yourself right before submitting.
2. **Notes** — paste the reviewer note from `APPLE_4.3b_RESPONSE_KIT.md` §2. Explicitly state: *"This is not a dating app; the home screen is Explore (cultural experiences and local events); there is no swipe deck or match mechanic."*
3. Contact first/last name, phone, email — a real reachable person.
4. If you recorded a demo video, add the link in Notes.

---

## Phase 7 — Submit

1. **Version Release**: choose *Automatically release* or *Manually release* (recommend **Manual** so you control the go-live moment).
2. Select the processed **Build 101**.
3. Click **Add for Review → Submit**.
4. State goes: *Waiting for Review → In Review → (Approved | Rejected)*. Typical wait: 24–48h.

---

## Phase 8 — If rejected again

Go straight to `APPLE_4.3b_RESPONSE_KIT.md` §4 (Resolution Center reply templates + App Review Board appeal + PWA fallback). Do **not** silently resubmit the same build — reply in Resolution Center first, or appeal.

---

## Quick command reference

```bash
# Clean release build for the store
flutter clean && flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release          # -> build/ios/ipa/*.ipa  (upload via Transporter)

# Verify version/build before archiving
grep '^version:' pubspec.yaml          # expect: version: 3.0.0+101
```

## Submission checklist (tick before you hit Submit)

- [ ] 4.3(b) code checklist in Response Kit §1 passes (no dating signal reachable)
- [ ] Category = Travel / Education
- [ ] Screenshots (incl. **iPad**) show Explore/Events/Community, no swipe deck
- [ ] Keywords contain no dating terms
- [ ] App Privacy labels complete + Privacy Policy URL live
- [ ] `ITSAppUsesNonExemptEncryption=false` set (or compliance answered)
- [ ] Demo account works and lands on Explore
- [ ] Reviewer notes pasted
- [ ] Build 101 processed and selected
- [ ] Push: release entitlement `aps-environment = production` (see iOS push guide)
