# GreenGo — End-to-End User Test Matrix

> **App:** GreenGo Flutter (cross-cultural discovery & networking — NOT a dating app)
> **Scope:** Every user-facing functionality grounded in real code under `lib/features/**` (134 screens across 48 feature modules).
> **Purpose:** A QA-lead master matrix of concrete, testable end-to-end user flows — happy paths, negative paths, empty/error/loading states, permission gates, and paid-tier gates.
> **Total items:** **423**
> **Priority:** P0 = core revenue/auth/data-integrity/safety flows a broken build must never ship; P1 = important feature paths; P2 = polish, edge, cosmetic.
> **Existing automated coverage:** The repo ships 120 widget tests (`test/userTests/`, Tests 1–120) built on a mocked `test_app.dart`. Each row below cites the covering test file + test number, or `none`.

Legend for the "Existing automated test?" column:
- `auth #N` = `test/userTests/authentication_test.dart` Test N
- `onb #N` = `onboarding_test.dart` · `prof #N` = `profile_editing_test.dart` · `disc #N` = `discovery_test.dart` · `match #N` = `matching_test.dart` · `chat #N` = `chat_test.dart` · `notif #N` = `notifications_test.dart` · `gam #N` = `gamification_test.dart` · `coin #N` = `coins_test.dart` · `sub #N` = `subscription_test.dart` · `set #N` = `settings_test.dart` · `nf #N` = `new_features_test.dart` (consent + translation)
- `none` = no automated coverage exists.

---

## 1. Auth & Onboarding
*Screens: `authentication/presentation/screens/{login,register,forgot_password,change_password,selfie_verification_login,waiting}_screen.dart`, `profile/presentation/screens/onboarding_screen.dart` + `onboarding/step0..step9`, `splash/post_login_splash_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 1 | View login screen on launch | Open app logged out | Email + password fields, Login button, language selector render | P0 | auth #1, #14 |
| 2 | Login with valid credentials | Enter valid email/password → Login | AuthWrapper routes to main nav (bottom bar visible) | P0 | auth #7 |
| 3 | Login accepts nickname OR email | Enter a nickname instead of email → Login | Resolves and authenticates | P1 | none |
| 4 | Login invalid credentials | Enter wrong email/password → Login | "Invalid email or password" error dialog with Retry | P0 | auth #8 |
| 5 | Login empty email validation | Leave email empty → Login | `authPleaseEnterEmail` validation error | P1 | none |
| 6 | Login empty password validation | Leave password empty → Login | `passwordRequired` validation error | P1 | none |
| 7 | Login network-error classification | Trigger connection/timeout error | Dedicated connection-error dialog with Retry (distinct from server/generic) | P1 | none |
| 8 | Login server-error classification | Trigger 500/503 error | Server-error dialog with Retry | P2 | none |
| 9 | Password visibility toggle (login) | Tap eye icon | `obscureText` flips to false | P2 | auth #9 |
| 10 | Loading state disables login form | Tap Login, pump once | Spinner shown, all fields/buttons disabled | P1 | auth #13 |
| 11 | Social login buttons (flag-gated) | Enable `showSocialLoginSection` | Google/Facebook/Biometric buttons render per flags; Apple shows "coming soon" snackbar | P2 | none |
| 12 | Navigate to registration | Tap "Create Account" / "Sign up" | Register screen with email/password/confirm fields | P0 | auth #2, #15 |
| 13 | Register with valid credentials | Fill valid data + required consents → Register | Success snackbar, routes to OnboardingScreen | P0 | auth #3, nf #110 |
| 14 | Register invalid email format | Enter malformed email → Register | "Please enter a valid email" error | P0 | auth #4 |
| 15 | Register weak/strong password strength meter | Type weak then strong password | Live strength label Weak→Strong (0–4) | P1 | auth #5 |
| 16 | Register password policy enforcement | Enter password missing uppercase/number/special | Validation blocks submit (≥8, upper, lower, digit, special) | P1 | none |
| 17 | Register passwords mismatch | Confirm ≠ password → Register | "Passwords do not match" error | P0 | auth #6 |
| 18 | Consent checkboxes present on registration | Open register | Privacy + Terms (required, unchecked) + profiling + third-party (optional, pre-checked) | P0 | nf #101 |
| 19 | Required consents block registration | Leave privacy/terms unchecked → Register | Red `consentRequiredError` snackbar, submit blocked | P0 | nf #102, #105 |
| 20 | Accept privacy / terms consent | Tap privacy then terms checkbox | Checkboxes toggle checked | P1 | nf #103, #104 |
| 21 | Toggle optional consents | Toggle profiling / third-party | State updates independently | P2 | nf #106, #107 |
| 22 | Open privacy policy / terms links | Tap privacy / terms link | Opens `LegalDocumentScreen` (Privacy / Terms) | P1 | nf #108, #109 |
| 23 | Apply valid referral code at register | Enter referral code → Register | `PendingSignupReferral` persisted | P1 | none |
| 24 | Apply valid coupon at register | Enter coupon → Apply | `validateCoupon` CF → green `couponAppliedSuccess` + pending set | P1 | none |
| 25 | Apply invalid coupon | Enter bad coupon → Apply | Red `couponNotValid`, `freeBaseWeekInfo` hint shown | P2 | none |
| 26 | Navigate to forgot password | Tap "Forgot Password?" | Reset screen with email field | P0 | auth #10 |
| 27 | Request password reset | Enter email → Send Reset Link | `sendPasswordResetViaResend` CF → blocking "Email Sent" dialog | P0 | auth #11 |
| 28 | Forgot-password invalid email | Submit malformed email | Validation error / `invalid-argument` snackbar | P2 | none |
| 29 | Change password (reauth) | Current pw + new pw + confirm + email confirm → Submit | Reauth then `updatePassword`, success snackbar + pop | P0 | none |
| 30 | Change password wrong current | Enter wrong current password | `wrong-password` red snackbar | P1 | none |
| 31 | Change password email mismatch | Confirm email ≠ account email | `changePasswordEmailMismatch` snackbar, aborts | P1 | none |
| 32 | Language selector on login | Tap language selector | "Select Language" list (English, Español…) | P1 | auth #12 |
| 33 | Selfie-on-login gate | User has `requireSelfieOnLogin` → login | Selfie verification screen shown before home | P1 | none |
| 34 | Take & verify selfie on login | Take Selfie → Verify & Continue | Dispatches `AuthSelfieVerificationCompleted`, proceeds | P1 | none |
| 35 | Selfie verify without photo | Tap Verify with no photo | `authTakeSelfieToVerify` red snackbar | P2 | none |
| 36 | Selfie cancel → sign out | Tap X / "Sign out instead" → confirm | `AuthSelfieVerificationCancelled` signs out | P2 | none |
| 37 | Waiting screen — pending approval | Login while `pending` | 3-step "under review" tracker card | P1 | none |
| 38 | Waiting screen — countdown active | Login before access date | `LuxuryCountdownWidget` + access-date info | P1 | none |
| 39 | Waiting screen — rejected | Login while `rejected` | Rejected card + "Re-upload verification" + "Contact support" | P1 | none |
| 40 | Waiting screen VIP badge (tier-gated) | Non-basic member during countdown | Platinum/Gold/Silver badge rendered | P2 | none |
| 41 | Post-login splash animation | Complete login | 2.2s logo animation → `onComplete` advances | P2 | none |
| 42 | Splash business label | `is_business_account` in prefs | Gold "BUSINESS" label under logo | P2 | none |
| 43 | Onboarding step 0 — welcome | Enter onboarding | Feature intro (Explore/Events/Community/Messages), Continue | P1 | onb #16 |
| 44 | Onboarding basic info + DOB 18+ gate | Enter name/DOB/gender | DOB picker `lastDate = now−18y` enforces 18+; incomplete → `completeAllFields` snackbar | P0 | onb #18, #26 |
| 45 | Onboarding photo upload (min 1) | Add photo camera/gallery → Continue | Upload; 0 photos → `uploadAtLeastOnePhoto` snackbar | P0 | onb #19, #20 |
| 46 | Onboarding photo moderation reject | Upload non-compliant photo | "Photo Not Accepted" dialog (noFace/nudity/tooLarge codes) | P1 | none |
| 47 | Onboarding verification — ID photo path | Take verification photo → Continue | `OnboardingVerificationPhotoAdded`, proceeds | P1 | none |
| 48 | Onboarding verification — phone OTP path | Send code → enter 6-digit → Verify | Links phone credential; resend 60s countdown | P1 | none |
| 49 | Onboarding verification errors | Trigger invalid-phone / bad code | Mapped error messages shown inline | P2 | none |
| 50 | Onboarding interests min 3 / max 10 | Select interests → Continue | <3 blocks (`minInterests`); >10 amber snackbar | P1 | none |
| 51 | Onboarding location + language | Use current location + pick languages | Location required, ≥1 language required; max 3 languages | P1 | none |
| 52 | Onboarding location permission denied | Deny location on "Use Current Location" | ConnectionErrorDialog with retry, inline error | P1 | none |
| 53 | Onboarding travel preference (skippable) | Select Learn/Guide/Both or skip | Advances either way | P2 | none |
| 54 | Onboarding voice recording (≤15s, skippable) | Record → auto-upload | Uploads m4a; mic denied → `voiceMicPermissionDenied` snackbar | P2 | none |
| 55 | Onboarding personality quiz | Answer all 5 Likert questions | Builds `PersonalityTraits`, proceeds | P2 | none |
| 56 | Onboarding social links (skippable) | Fill/skip social handles | Saves `SocialLinks` or skips | P2 | none |
| 57 | Onboarding preview + complete | Review preview → Complete Profile | `OnboardingCompleted` → coupon outcome snackbar → home | P0 | none |
| 58 | Onboarding back / exit dialog | Press back on first data step | "Exit registration?" dialog → Sign Out | P1 | onb #23 |
| 59 | New user reaches main after onboarding | Complete onboarding | Main nav bottom bar visible | P0 | onb #16 |

---

## 2. Explore / Discovery
*Screens: `discovery/presentation/screens/{matches,match_detail,profile_detail,discovery_preferences,travel_explore_map}_screen.dart`, `explore_map/explore_map_screen.dart`, `explore/qr_hub_screen.dart`, `profile/user_search_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 60 | View discovery/matches list | Open Discover/Network | Profile cards render (or grid) | P0 | disc #38 |
| 61 | Like a profile | Tap like button | Like recorded, advances | P0 | disc #39 |
| 62 | Pass a profile | Tap pass button | Pass recorded, advances | P0 | disc #40 |
| 63 | Super-like a profile | Tap super-like | Super-like recorded | P1 | disc #41 |
| 64 | Rewind last swipe | Tap rewind | Restores previous card | P1 | disc #49 |
| 65 | Open profile card detail | Tap a card | `ProfileDetailScreen` opens | P0 | disc #42 |
| 66 | Photo gallery swipe in profile detail | Swipe photos | PageView with index indicators | P1 | disc #43 |
| 67 | Double-tap photo like | Double-tap a photo | Heart pop + `photo_likes` toggle + notification | P1 | none |
| 68 | Like count formatting | View liked photo | Count shows, >999 → "k" | P2 | none |
| 69 | Voice-intro playback in profile | Tap play on voice card | Waveform progress + play/pause | P2 | none |
| 70 | Social link launch from profile | Tap Instagram/Facebook/etc. | `launchUrl` external; failure → "could not open" snackbar | P2 | none |
| 71 | Report / Block from profile safety menu | Open overflow → Report/Block | Report reasons sheet / block confirm (hidden on self) | P0 | none |
| 72 | Matches list — loading state | Open with slow load | Gold spinner (`MatchesLoading`) | P2 | none |
| 73 | Matches list — empty state | No matches | "No matches yet / Start swiping" empty | P1 | none |
| 74 | Matches list — error + retry | Force load error | Error message + Retry re-dispatches | P1 | none |
| 75 | View mutual matches list | Open Matches | Mutual matches render | P0 | match #50, #51 |
| 76 | Search matches by name/nickname | Type in search | List filters live; clear (X) resets | P1 | none |
| 77 | Filter matches All/New/Messaged | Tap filter chips | List filters accordingly | P1 | none |
| 78 | Sort matches by compatibility | Tap sort button | Cycles none→desc→asc | P2 | none |
| 79 | Match detail — options | Tap a match | Match detail with See Profile / Start Chat / Unmatch | P1 | match #52 |
| 80 | Start chat from match | Tap Start Chat | `ChatScreen` opens | P0 | match #53 |
| 81 | Unmatch a match | Tap Unmatch → confirm | `MatchUnmatchRequested`, pops + snackbar | P1 | match #54, #55 |
| 82 | Match timestamp displayed | View match card | Timestamp rendered | P2 | match #56 |
| 83 | Refresh matches list | Pull-to-refresh | `MatchesRefreshRequested`, 15s timeout | P2 | match #57 |
| 84 | **Base-membership gate on opening a match** | Tap a match without active base membership | `BaseMembershipDialog` purchase prompt blocks entry | P0 | none |
| 85 | Discovery preferences — open | Open preferences | Age/distance/country/language/interest filters render | P1 | disc #44 |
| 86 | Adjust age range (flavor-gated) | Drag age RangeSlider 18–100 | Value updates; save enabled | P1 | disc #45 |
| 87 | Adjust max distance | Drag distance slider / "No limit" switch | Value updates | P1 | disc #46 |
| 88 | Set gender / orientation preference | Select radios/checkboxes | Preference stored (flavor-gated) | P1 | disc #47 |
| 89 | Country filter add/remove | Open country picker, search, add, delete chip | Filter updates; "By Users" sort loads counts | P2 | none |
| 90 | Save discovery preferences | Change a filter → Save | Persists `matchPreferences`, pops with result | P1 | disc #48 |
| 91 | Reset preferences to default | Tap "Reset to default" | Defaults applied, marked changed | P2 | none |
| 92 | User search by nickname | Open search, type nickname | 500ms debounce results; excludes self + blocked | P1 | none |
| 93 | User search — no results | Search unknown nickname | "No users found for {query}" | P2 | none |
| 94 | User search — error + retry | Force search error | Error + Retry | P2 | none |
| 95 | QR hub — My Tickets tab | Open QR hub | Ticket list ordered upcoming-first; empty state | P1 | none |
| 96 | QR hub — Scan tab (organizer) | Switch to Scan | Live scanner; camera-permission error state | P1 | none |

---

## 3. 1:1 Chat
*Screens: `chat/presentation/screens/{conversations,chat,support_chat,support_tickets_list}_screen.dart`, `chat/presentation/widgets/{message_bubble,message_composer}.dart`, `video_call` / `video_calling`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 97 | View conversations list | Open Messages/Exchanges | Conversation rows render | P0 | chat #58 |
| 98 | Unread message badge/indicator | Have unread convos | Gold unread badge ("99+" cap) per tab | P1 | chat #59 |
| 99 | Business tab visibility | Business account opens Exchanges | 3rd "Business" tab shown only for business users | P2 | none |
| 100 | Search conversations | Type in search | Filters by name/nickname; clear (X) | P1 | none |
| 101 | Filter conversations All/New/Unread/Favorites | Tap filter chips | List filters; counts in labels | P2 | none |
| 102 | Toggle conversation favorite | Tap star on a row | Favorite toggles | P2 | none |
| 103 | Open a conversation | Tap a conversation | `ChatScreen` opens (after base-membership gate) | P0 | chat #60 |
| 104 | **Base-membership gate opening a chat** | Open chat without active membership | Purchase prompt blocks | P0 | none |
| 105 | Conversations empty state | No conversations | "No messages yet / Start swiping" illustration | P1 | none |
| 106 | Delete conversation (long-press) | Long-press → Delete for me/both | Bottom sheet, conversation removed | P1 | chat #67, #68 |
| 107 | Accept / reject superLike conversation | On to-approve item | Accept/Reject actions decrement badge | P1 | none |
| 108 | Send text message | Type ≤200 chars → Send | Message appears in list; send sound; XP awarded | P0 | chat #61, nf #113 |
| 109 | View message list + sent/received bubbles | Open chat with history | Sent (right) / received (left) bubbles render | P0 | chat #62, #63, #64, nf #111, #112 |
| 110 | Message length counter | Focus composer, type | Counter shows when focused/nonempty | P2 | none |
| 111 | Contact-info filter blocks send | Type message containing phone/email | Blocked before send ("contains contact info") | P1 | none |
| 112 | Send voice message | Long-press mic, release | Records m4a, uploads; <1s → "too short" | P1 | none |
| 113 | Voice record slide-to-cancel | Slide left while recording | Recording cancelled | P2 | none |
| 114 | Mic permission denied | Record without mic permission | "Microphone permission required" snackbar | P1 | none |
| 115 | Send image (with moderation) | Attach image → send | On-device nudity check → upload with % → backend `moderateChatImage`; rejected deleted | P0 | none |
| 116 | Send video (≤60s, ≤50MB) | Attach/record video → send | Upload with progress; >50MB → "too large" | P1 | none |
| 117 | **Media send limit gate (tier)** | Exceed per-tier media sends | "Media limit reached" dialog | P1 | none |
| 118 | Share album (private photos) | Attach → Album → select photos | Each sent as image; empty album → "No private photos" | P2 | none |
| 119 | Share location message | Attach → Share location | GPS captured; denied → "Location denied" snackbar | P2 | none |
| 120 | Reply to a message | Long-press → Reply → send | Reply preview bar, `ChatMessageReplied` | P1 | nf #114 |
| 121 | Forward a message | Long-press → Forward | Forward flow (hidden for private-album images) | P2 | none |
| 122 | Star / unstar a message | Long-press → Star | Star indicator toggles | P2 | none |
| 123 | Report a received message | Long-press received → Report | 6-reason report sheet | P1 | none |
| 124 | Inline auto-translation | Receive foreign-language text | Translated text + original toggle + translate icon | P0 | nf #115, #116 |
| 125 | Open translation settings | Tap tools → chat settings | Show-original / flags / difficulty / TTS-source toggles | P1 | nf #117 |
| 126 | Per-chat target language picker | Tools → Your language | Persists per-matchId language | P1 | none |
| 127 | Language pack download | Translation settings → download pack | Pack downloads | P2 | nf #118 |
| 128 | Re-translate on app language change | Change app language | Messages re-translated to new target | P2 | nf #120 |
| 129 | **TTS double-tap costs 5 coins** | Double-tap a text bubble | Plays TTS, deducts 5 coins | P0 | none |
| 130 | TTS insufficient coins | Double-tap with <5 coins | "Not enough coins for TTS (5 required)" | P0 | none |
| 131 | **Word breakdown (Silver+ gate)** | Tap received text | Breakdown sheet; free tier → "available for Silver…" snackbar | P1 | none |
| 132 | **Smart replies (Silver+ gate)** | Open chat as Silver+ | Suggestion bar with translations; free → none | P2 | none |
| 133 | **Grammar check (Silver+ gate)** | Send non-native ≥3-word text | Correction banner: Use correction / Send anyway | P2 | none |
| 134 | Copy a message | Long-press → Copy | Text copied | P2 | nf #119 |
| 135 | Read receipts | Send then partner reads | clock → single check → double-check green | P1 | chat #69 |
| 136 | Typing indicator | Partner typing | Animated dots + "typing…" in app bar | P2 | none |
| 137 | Chat partner online/last-seen | Open chat | "Online" / "X min ago" / offline in header | P1 | chat #65 |
| 138 | Open partner profile from chat | Tap app-bar header | `ProfileDetailScreen` (business identity for business partners) | P1 | chat #66 |
| 139 | Mute / unmute conversation | ⋮ → Mute/Unmute | Per-user mute persisted | P2 | none |
| 140 | Block user from chat | ⋮ → Block user | User blocked (disabled for admin targets) | P0 | none |
| 141 | Report user from chat | ⋮ → Report (7 reasons) | Report submitted | P0 | none |
| 142 | Share / revoke album access | ⋮ → Share/Revoke album | albumShare/albumRevoke system message | P2 | none |
| 143 | Message pagination | Scroll to top in long chat | Loads +30 older (40 initial window) | P1 | none |
| 144 | Image/video fullscreen view | Tap image/video bubble | Blurred → fullscreen zoom / video player w/ error state | P1 | none |
| 145 | Support chat — send text/image | Open support ticket chat | Send text + image attachment; AI-agent badge | P1 | none |
| 146 | Support tickets list + create | Open support list → New ticket | Category/subject/description dialog; empty state | P1 | none |
| 147 | Reopen closed support ticket | Open resolved ticket → Reopen | Status set open, input restored | P2 | none |
| 148 | Video call — incoming accept/decline | Receive call | Accept/Decline buttons | P2 | none |
| 149 | Video call — controls | In active call | Mute/video/switch-camera/speaker/end | P2 | none |
| 150 | Video call — real-time translation subtitles | Toggle translation in call | Subtitle overlay + language selector sheet | P2 | none |

---

## 4. Group Chat
*Screens: `chat/presentation/screens/{groups,group_chat,create_group,group_info}_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 151 | View groups list | Open Groups | Group rows; search; All/Unread/Favorites filters | P1 | none |
| 152 | Groups empty state | No groups | "say hello" illustration | P2 | none |
| 153 | Open a group chat | Tap a group | `GroupChatScreen` opens | P0 | none |
| 154 | Send group text message | Type → Send | Message appears; too-long → "message too long" | P0 | none |
| 155 | Send group voice/image/video/location/album | Attachment sheet | Each type sends (image nudity-validated) | P1 | none |
| 156 | Group per-viewer translation | Toggle translate + pick language | Messages translated, persisted per group | P1 | none |
| 157 | Group TTS double-tap (5 coins) | Double-tap message | TTS plays, 5 coins deducted; insufficient → snackbar | P1 | none |
| 158 | Group message pagination | Scroll to top | Loads +30 older | P2 | none |
| 159 | Create group — name required | Open create group | Create disabled until name entered | P1 | none |
| 160 | Create group — invite by nickname | Search nickname, add | Excludes self/ghost/business; feedback snackbars | P1 | none |
| 161 | Create group — select chat partners (infinite scroll) | Scroll candidate list | Paginated chat partners, multi-select checkboxes | P2 | none |
| 162 | Create group — max 256 members | Select >255 others | Cap snackbar | P2 | none |
| 163 | **Create group — membership + group-cap gate** | Create beyond per-tier group limit | Limit dialog with Upgrade button | P1 | none |
| 164 | Group info — members list + admin chips | Open group info | Active members, "You", Admin chips, language flags | P1 | none |
| 165 | Group admin — remove member | Admin taps member → Remove → confirm | Member removed | P1 | none |
| 166 | Group admin — add members | Admin → Add members | Nickname search sheet, capped at 256 | P2 | none |
| 167 | Group admin — edit name / change photo | Admin → edit name / photo | Name updated; photo nudity-validated + uploaded | P2 | none |
| 168 | Group admin — delete group | Admin → Delete for everyone → confirm | Group deleted | P1 | none |
| 169 | Group — my private group tags | Open group info → tags editor | `MyGroupTagsTile` add/remove tags | P2 | none |
| 170 | Group — report group | Member → Report group → confirm | Report submitted | P1 | none |
| 171 | Group — leave group | Member → Leave → confirm | Leaves, pops to root | P1 | none |

---

## 5. Communities
*Screens: `communities/presentation/screens/{communities,community_detail,create_community}_screen.dart` + widgets `member_moderation_sheet`, `join_requests_sheet`, `community_events_tab`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 172 | Communities — Joined/Discover/Managed tabs | Open Communities | 3 tabs; per-tab loading spinner | P1 | none |
| 173 | Joined empty state | No joined communities | Empty + "Discover communities" jumps to Discover | P1 | none |
| 174 | Search joined communities | Type in Joined search | Client-side filter; search-empty state | P2 | none |
| 175 | Favorite/unfavorite a community | Tap star on joined card | Optimistic toggle, pinned under Favorites; reverts on failure | P2 | none |
| 176 | Discover — search + type filter chips | Search / tap type chip | Filtered `LoadCommunities`; excludes joined | P1 | none |
| 177 | Discover — recommended section | Open Discover | "Recommended for you" (≤5, excludes joined) | P2 | none |
| 178 | Discover — infinite scroll | Scroll near bottom | Loads more page; trailing spinner | P2 | none |
| 179 | Open community detail | Tap a card | `CommunityDetailScreen` (logs view) | P0 | none |
| 180 | Join public community | Non-member → Join community | `JoinCommunity`, success snackbar, becomes member | P0 | none |
| 181 | Request to join private community | Non-member → Request to join | "join request sent" snackbar | P1 | none |
| 182 | Business account join confirmation | Business user joins | "join as personal profile" confirm dialog first | P2 | none |
| 183 | Community detail — 4 tabs | Open detail | Chat / Tips / Announcements / Events render | P1 | none |
| 184 | Community chat — post message | Member composer → send | Text/Language Tip/Cultural Fact (City Tip for local guides) | P1 | none |
| 185 | Muted member composer | Muted member opens Chat | "you are muted" read-only notice | P2 | none |
| 186 | Report a community message | Tap others' message → report | Community report sheet | P1 | none |
| 187 | Tips tab — filter + add tip | Filter chips / Add tip (if `canWriteTips`) | Board filters; composer gated to writers | P2 | none |
| 188 | Announcements tab — post (gated) | `canWriteAnnouncements` → Post announcement | Broadcast posted; read-only otherwise | P2 | none |
| 189 | Community events tab — create/open | Moderator → Create event / open event | `CreateEventScreen` (communityId locked) / `EventDetailLoaderScreen` | P1 | none |
| 190 | Moderation sheet — promote/demote/mute | Moderator taps member | Promote admin / demote / mute / unmute | P1 | none |
| 191 | Moderation — grant/revoke tips/announcements writing | Moderation sheet | Toggles writer permissions | P2 | none |
| 192 | Moderation — remove / ban member | Moderation sheet → Remove/Ban | Member removed/banned | P1 | none |
| 193 | Join requests — approve/reject | Moderator (private) → Join requests | Approve/Reject per request; empty state | P1 | none |
| 194 | Edit rules & resources (moderator) | Moderator → edit rules pencil | Rules editor → `UpdateCommunity` | P2 | none |
| 195 | Edit sponsorship (owner + Platinum gate) | Owner → Edit sponsorship | Editor opens only if `SponsorshipGate.canSponsor`; else gate | P2 | none |
| 196 | Leave community | Member → Leave → confirm | `LeaveCommunity`, pops | P1 | none |
| 197 | Delete community (owner, reauth) | Owner → Delete → password reauth | `DeleteCommunity`; wrong-password handled | P1 | none |
| 198 | Create community — form validation | Fill name(≥3)/desc(≥10)/type/languages | Preview only when valid | P1 | none |
| 199 | Create community — sponsorship paid gate | Tap sponsorship in create | Editor only if eligible; else `SponsorshipGate.showGate` | P2 | none |
| 200 | Create community — submit | Preview → Create | Uploads cover, `CreateCommunity`, opens new detail | P1 | none |

---

## 6. Events
*Screens: `events/presentation/screens/{events,event_detail_loader,event_attendance,event_chat,event_ticket,event_scanner,event_location_picker}_screen.dart`, `business/business_events_screen.dart`, inner `EventDetailsScreen`/`CreateEventScreen`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 201 | Events — 5 tabs (Community/Live/Attractions/Experiences/My) | Open Events | Tabs render; gold loading spinner | P1 | none |
| 202 | Events — search | Type country/city/name/tag | Filters; Community tab searches whole table | P1 | none |
| 203 | Events — sort + grid/list toggle | Tap sort menu / view toggle | Sort options per tab; layout toggles | P2 | none |
| 204 | Events — date-range filter | Open date filter → Today/Week/Month/custom | Events filtered by range | P2 | none |
| 205 | Events — category filter chips | Tap category chip | Filters by `EventCategory` / place category | P2 | none |
| 206 | Community events — nearby (geohash) | Open Community tab with location | Closest-100 events; cache-first feed | P1 | none |
| 207 | Events — empty state | No events found | `event_busy` empty + Create button | P1 | none |
| 208 | RSVP from event card | Tap Join/Going on card | RSVP set; disabled when full; logs business lead | P0 | none |
| 209 | Like/unlike event | Tap like button on tile | `EventLikeButton` toggles | P2 | none |
| 210 | Open event details | Tap event | `EventDetailsScreen` renders info rows | P0 | none |
| 211 | Event RSVP / join (bottom bar) | Tap Join event | Label reflects Join/Waitlist/Going/On-waitlist | P0 | none |
| 212 | **Paid event join — ticket tiers + coins** | Join event with tiers | Tier picker; affordability pre-check; coin spend; rollback on fail | P0 | none |
| 213 | Join full event → waitlist | Join full event | "You're #N on waitlist" banner; no ticket | P1 | none |
| 214 | My ticket card (going only) | Going user → My ticket | Opens `EventTicketScreen` | P1 | none |
| 215 | Safety check-in ("arrived safely") | Going user → check-in | Records safe arrival | P2 | none |
| 216 | Report event (non-organizer) | Non-organizer → report | Writes `reports`, hides event, pops | P1 | none |
| 217 | Share event / open group chat | Tap share / group chat | Share sheet / event group chat | P2 | none |
| 218 | **Boost/feature event (organizer, coins)** | Organizer → boost → pick duration | Affordability check → buy-coins prompt → charge → `featuredUntil` | P1 | none |
| 219 | **Create event — membership gate** | Create event with expired membership | Blocked → renew (`ensureValidMembershipByUid`) | P0 | none |
| 220 | **Create event — extra-event paywall** | Create beyond free allowance | Each extra costs `kExtraEventCost` (50) coins | P1 | none |
| 221 | Create event — image moderation | Add event image (non-web) | Nudity/explicit check before upload | P1 | none |
| 222 | Event detail loader (deep-link) | Open event by id | Loading/error/loaded; merges attendees; logs view | P1 | none |
| 223 | Event attendance list (organizer) | Organizer → attendance | Live roster; checked-in/total stats; empty state | P1 | none |
| 224 | Event chat — send + moderation | Send message in event chat | Content-filter block; hides blocked senders | P2 | none |
| 225 | Event chat — organizer broadcast | Organizer toggles campaign | Announcement banner | P2 | none |
| 226 | Event ticket — QR display | Open ticket | `greengo:{e,u}` QR; "Admits N" | P1 | none |
| 227 | Event ticket — guest picker | +/- guests (if allowed) | Clamped to `guestsAllowedPerAttendee`, persists | P2 | none |
| 228 | Event ticket — delete (post-24h) | Delete after event ended 24h | Delete icon appears → confirm → deletes attendee doc | P2 | none |
| 229 | **Event scanner — QR check-in (organizer/allowed)** | Scan attendee QR | Validates namespace/eventId/going; flips checkedIn; denied cases | P0 | none |
| 230 | Scanner — denied cases | Scan invalid/foreign/already-checked-in | Denied overlay with reason/name | P1 | none |
| 231 | Scanner — manage scanners (owner) | Owner invites scanner by nickname | Added to `allowedScannerIds` | P2 | none |
| 232 | Scanner — web fallback | Open scanner on web | "use mobile app" fallback | P2 | none |
| 233 | Event location picker — map/search | Tap map / search address | Reverse/forward geocode; web placeholder | P2 | none |
| 234 | Business events — manage own events | Open manage events | Own events (drafts+scheduled) with status badges | P1 | none |
| 235 | Business events — analytics (tier-gated) | Tap Analytics on event | `ensureAnalytics` gate → `EventAnalyticsScreen` | P2 | none |
| 236 | Business events — feature (100 coins) | Feature an event | `kFeatureEventCost` (100) coins, 7-day feature | P2 | none |
| 237 | Business events — cancel (single/recurring) | Cancel event / series | Series-specific confirm text | P2 | none |

---

## 7. Coins & Shop
*Screens: `coins/presentation/screens/{coin_shop,shop,transaction_history,payment_result}_screen.dart`, widgets `coin_balance_widget`, `web_checkout_dialog`, `virtual_gifts/gift_shop_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 238 | View coin shop | Open Coin Shop | Buy Coins + Membership tabs; balance header | P0 | coin #88, #91 |
| 239 | See coin packages + prices | Buy Coins tab | Package cards, price+taxes, coins/$ ratio, bonus badges | P0 | coin #89 |
| 240 | See active promotions | Open with promotion active | Promotion banner "{days}d left" | P2 | coin #90 |
| 241 | **Buy coins (native IAP)** | Select package → Purchase | `queryProductDetails` → `buyConsumable` → credit + success dialog | P0 | coin #93 |
| 242 | Buy coins — store unavailable / product not found | Purchase when store down | Handled error (setup message / snackbar) | P1 | none |
| 243 | Buy coins — canceled/pending | Cancel purchase mid-flow | Loading reset, purchase consumed | P1 | none |
| 244 | **Buy coins (web Stripe)** | Purchase on web | `WebCheckoutDialog` Stripe → refresh balance | P0 | none |
| 245 | **Send coins P2P by nickname** | Enter nickname + amount → Send → confirm | FIFO debit/credit, `coinGifts` record, chat message + notification | P0 | none |
| 246 | Send coins — validation edges | Empty/≤0/over-balance/self/unknown nickname | Respective error snackbars, blocked | P0 | none |
| 247 | Redeem coupon in shop | Gift icon → enter coupon | Refresh profile/balance/tier on success | P1 | none |
| 248 | Coin balance widget animation | Balance changes | Animated coin + K/M formatting; tap → shop | P2 | none |
| 249 | Transaction history — list + grouping | Open history | Grouped Today/Yesterday/date; credit/debit colored | P1 | coin #92 |
| 250 | Transaction history — empty state | No transactions | "No transactions yet" | P2 | none |
| 251 | Transaction history — filter dialog (inert) | Open filter → apply | Radios present but non-functional (regression guard) | P2 | none |
| 252 | Payment result — success verify | Return from Stripe success | Polls `stripe_orders`, shows credited success | P0 | none |
| 253 | Payment result — pending / cancelled | Return pending / cancelled | Hourglass "processing" / red "no charges" | P1 | none |
| 254 | Legacy shop → routes to verified shop | Tap package in legacy Shop | Confirm dialog → routes to `CoinShopScreen` (no client mint) | P1 | none |
| 255 | Virtual gifts — send gift | Open gift shop → select → Send | `SendGiftEvent`, success snackbar, returns gift | P1 | none |
| 256 | Virtual gifts — insufficient coins | Send unaffordable gift | `InsufficientCoins` dialog (required/available/shortfall) | P1 | none |
| 257 | Virtual gifts — received gifts | Open received gifts | List; tap → animation dialog + mark viewed | P2 | none |
| 258 | Accept / decline received coin gift | Gifts tab → Accept/Decline | Accept credits receiver; decline refunds sender | P1 | none |

---

## 8. Subscriptions / Membership
*Screens: `subscription/presentation/screens/{membership,subscription_selection}_screen.dart`, `membership/widgets/coupon_code_widget.dart`, coin_shop Membership tab.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 259 | View subscription plans / tiers | Open membership | Base/Silver/Gold/Platinum cards, prices+taxes | P0 | sub #94 |
| 260 | See per-tier premium features | View tier cards | Feature rows (events/groups/connects/boosts/coins/no-ads/travel/business) | P1 | sub #95 |
| 261 | Compare subscription tiers | Open comparison table | Free/Silver/Gold columns with limits | P1 | sub #97 |
| 262 | Monthly/yearly toggle + savings | Toggle billing period | Yearly shows "Save X%", equivalent monthly | P2 | none |
| 263 | **Subscribe / upgrade (IAP)** | Select tier → Subscribe | `buyNonConsumable`; Android upgrade uses proration | P0 | sub #96 |
| 264 | Tier gate — downgrade/current locked | View lower/current tier | Locked (lock icon, 50% opacity, not tappable) | P1 | none |
| 265 | Subscription success server-verify | Complete purchase | `verifyPurchase` CF → tier+end-date updated + success dialog | P0 | none |
| 266 | Base membership purchase (+500 coins) | Subscribe base membership | Grants base + coins; ACTIVE badge + valid-until | P1 | none |
| 267 | **Restore purchases** | Legal footer → Restore | Re-queries store, reloads tier, "Purchases restored" | P0 | none |
| 268 | Subscribe (web Stripe) | Subscribe on web | Routes to Stripe checkout | P1 | none |
| 269 | Redeem coupon (membership widget) | Enter coupon code → Redeem | Grant summary; typed errors (expired/max-uses/mismatch/already-redeemed) | P1 | none |
| 270 | Subscription expiry downgrade dialog | Open app with expired sub | Downgrade dialog (OK/Upgrade), tier reset to free | P1 | none |

---

## 9. Profile
*Screens: `profile/presentation/screens/{edit_profile,edit_basic_info,edit_bio,edit_details,edit_interests,edit_nickname,edit_social_links,edit_location,edit_voice,photo_management,reverification,usage_stats}_screen.dart`, `video_profiles/{video_profile,video_discovery}_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 271 | Open Edit Profile hub | Profile tab | Accordion tiles (Photos/Nickname/Basic/Bio/Interests/Location/Voice/Social) | P0 | prof #28, #29, onb #17, #24 |
| 272 | View my profile (self preview) | Tap "View My Profile" | `ProfileDetailScreen` self-view (no swipe) | P1 | prof #28 |
| 273 | Edit basic info (name/gender validation) | Edit name (2–50) + gender → Save | Save disabled until valid; DOB locked | P0 | onb #18, prof #30 |
| 274 | Basic info empty-name validation | Clear name | Save disabled; validation message | P1 | onb #26 |
| 275 | Edit bio (min 50, max 500) | Edit bio → Save | <50 inline error; counter; success dialog | P1 | onb #21, #22, prof #35, #36 |
| 276 | Edit details (education/occupation/height) | Edit fields → Save | Save enabled only when changed; nulls for empty | P2 | prof #37, onb #25 |
| 277 | Edit interests (min 3 / max 10) | Toggle interests → Save | <3 blocks; 11th → amber snackbar; progress card | P1 | none |
| 278 | Edit nickname — live validation + uniqueness | Type nickname | Rules (3–20, letter-start, reserved words) + Firestore uniqueness spinner/check | P1 | none |
| 279 | Nickname suggestions + refresh | Tap suggestion chip / Refresh | Selects / regenerates suggestions | P2 | none |
| 280 | Edit social links (validation gap) | Enter handles → Save | Saved even if invalid URL (no format validation — guard) | P2 | none |
| 281 | Edit location — GPS permission gates | "Update current location" | Service/denied/deniedForever handled; geocode resolves | P1 | none |
| 282 | Edit location — web monthly limit | Web location change | Once/month gate; amber "monthly limit until <date>" | P2 | none |
| 283 | Edit location — languages max 3 | Toggle languages | 4th → amber snackbar; ≥1 required to save | P2 | none |
| 284 | Edit voice intro (≤30s) | Record → play/seek → Save | Uploads m4a with progress; mic denied snackbar | P2 | none |
| 285 | Photo management — public/private tabs | Open photos | 6-slot grid per tab; add from gallery | P0 | onb #19, prof #31 |
| 286 | Add photo from gallery | Add photo → gallery | Uploads; validated via moderation | P0 | onb #20, prof #32 |
| 287 | Add photo from camera | Add photo → camera | Uploads | P1 | prof #33 |
| 288 | Photo moderation reject | Upload non-compliant | "Validating…" → rejection dialog (noFace/nudity/tooLarge) | P1 | none |
| 289 | Delete a photo | Tap X → confirm | Removed; cannot delete only public photo | P1 | onb #27, prof #34 |
| 290 | Max 6 photos guard | Add 7th photo | Amber "maximum 6 photos" | P2 | none |
| 291 | Reorder photos (drag) | Long-press drag | Order persists; primary badge on index 0 | P2 | none |
| 292 | Copy photo private↔public (NSFW guard) | Copy private→public | Blocked (amber snackbar); public→private allowed | P2 | none |
| 293 | Reverification selfie flow | Take front selfie → Submit | Uploads, sets `verificationStatus=pending` | P1 | none |
| 294 | Usage stats display | Open usage stats | Per-stat used/limit bars; unlimited "∞"; tier badge live | P1 | none |
| 295 | Usage stats upgrade CTA (non-Platinum) | View as non-Platinum | "Upgrade Benefits" comparison + upgrade button | P2 | none |
| 296 | Record video profile intro (≤30s) | Record/upload video → Save | Prompt selector; >30s → discard snackbar; upload states | P2 | none |
| 297 | Delete video profile | Delete → confirm | `DeleteVideoProfile` | P2 | none |
| 298 | Video discovery feed (TikTok-style) | Open video discovery | Vertical PageView autoplay; like/pass taps; mute; infinite scroll | P2 | none |

---

## 10. Notifications
*Screens: `notifications/presentation/screens/{notifications,notification_preferences,city_picker}_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 299 | View notifications list | Open notifications | 100 recent, newest-first; unread gold tint/dot | P0 | notif #70, #73 |
| 300 | Notification type variety renders | Open with mixed types | like/superlike/match/event/community/message rows | P1 | notif #71 |
| 301 | Tap notification → navigate to source | Tap a notification | Marks read + routes (profile/event/community/chat) | P0 | notif #72 |
| 302 | Unknown-action notification | Tap notification with no route | No-op (dead tap, no crash) | P2 | none |
| 303 | Mark all as read | Tap "Mark all read" (unread>0) | `NotificationsMarkedAllAsRead` | P1 | notif #74 |
| 304 | Swipe to delete single notification | Swipe row end-to-start | `NotificationDeleted` | P2 | none |
| 305 | Delete all notifications | Tap delete-sweep → confirm | `NotificationsAllCleared` | P2 | none |
| 306 | Notifications empty state | No notifications | Bell icon + `notificationsEmpty` | P1 | none |
| 307 | Notifications error + retry | Force error | Error + Retry | P2 | none |
| 308 | Pull-to-refresh notifications | Pull down | Reloads list | P2 | none |
| 309 | Notification preferences — master + categories | Open preferences | Master Push toggle gates category toggles (Messages/Events/Communities/Social/Account) | P1 | notif #75, #76, #77 |
| 310 | Notification prefs — free users CAN toggle categories | Free user toggles category | Toggles work (categories gate only on master push, NOT tier — regression guard vs. docs) | P1 | none |
| 311 | Event-city alerts add/remove | Prefs (events on) → Add city → CityPicker | City added (normalized/deduped); remove chip; empty state | P2 | none |
| 312 | Quiet hours + sound/vibration | Toggle quiet hours → set times | Start/End time pickers, `HH:mm` persisted | P2 | none |
| 313 | City picker — search + map pin | Search / tap map | Geocode resolves "City, Country"; "Use this city" enabled when pin+city | P2 | none |

---

## 11. Business
*Screens: `business/presentation/screens/{business_hub,business_account,storefront_editor,business_verification_request,promote,followers,business_leads}_screen.dart`, `analytics/{analytics,event_analytics}_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 314 | Business hub — active tools | Open hub (active Platinum business) | Storefront/Account/Analytics/Events/Scanner/Followers/Promote/Leads/Verification tiles | P1 | none |
| 315 | Business hub — paused (lapsed Platinum) | Open hub without active business tier | "Business paused" + Reactivate button instead of tools | P1 | none |
| 316 | **Enable storefront — Platinum gate** | Non-Platinum toggles storefront on | `FeatureNotAvailableDialog` upsell → Shop; no change | P0 | none |
| 317 | Enable storefront (Platinum) | Platinum toggles on | `isBusiness:true`, `businessSince` stamped, snackbar | P1 | none |
| 318 | Business account — name/category validation | Fill business/legal name + category → Save | Save disabled until valid | P1 | none |
| 319 | Request business verification | Fill name/owner/phone-OTP/ID doc → Submit | E.164 validated, OTP, doc upload; `status:pending` | P1 | none |
| 320 | Verification — pending/verified states | Reopen after submit | "pending" label/hourglass; verified row read-only | P2 | none |
| 321 | Storefront editor — cover/avatar/gallery | Add/replace/remove images | NSFW+face validation; max 12 gallery; one upload at a time | P1 | none |
| 322 | Storefront editor — hours/links/description | Set weekday hours, links, bio, WhatsApp | Save → `ProfileUpdateRequested`, snackbar | P2 | none |
| 323 | Promote business (coins) | Promote → duration → confirm | Charges coins; active-until date; insufficient → Get coins | P2 | none |
| 324 | Promote event (coins) | Promote event → pick event → duration | Charges; "already featured" flagged; empty → snackbar | P2 | none |
| 325 | View followers | Open followers | Max 100 tiles; count header; empty state | P2 | none |
| 326 | View business leads | Open leads | Contact vs saved_event leads; tap → profile; pull-refresh | P1 | none |
| 327 | Business analytics (Platinum gate) | Open analytics | Locked non-Platinum (upgrade CTA); unlocked 6-stat grid + charts | P1 | none |
| 328 | Event analytics (Platinum gate) | Open event analytics | Views/going/waitlist/checked-in/rate; tier breakdown chart | P2 | none |

---

## 12. Settings
*Screen: `profile/presentation/screens/edit_profile_screen.dart` (Settings rendered as `SettingsAccordion`; there is no standalone settings screen).*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 329 | Access settings/account section | Open Profile tab | Account & Settings accordion visible | P1 | set #98 |
| 330 | App version / info display | Scroll settings | Version info rendered | P2 | set #99 |
| 331 | Access help & support | Open Help & Support accordion | Support Center / Coin Shop / Invite Friends / Progress / Usage | P1 | set #100 |
| 332 | Change app language (persists) | Account → App Language → pick | `setLocale` persists to prefs + Firestore; green snackbar | P1 | none |
| 333 | Change password entry | Account → Change Password | Opens change-password screen | P1 | none |
| 334 | **Notification Settings row (tier-gated)** | View as free vs paid | Row only shown when tier ≠ free; appears/disappears on tier change | P1 | none |
| 335 | Premium — Incognito Mode toggle | Toggle Incognito | State updates (premium-gated) | P2 | none |
| 336 | Premium — Globe Discoverability | Set 3-tier discoverability | State updates | P2 | none |
| 337 | Premium — Traveler Mode toggle | Activate/deactivate traveler mode | State updates | P1 | none |
| 338 | Premium — Boost Profile (coins) | Tap Boost | Success records boost vs monthly allotment; insufficient → Get coins CTA | P1 | none |
| 339 | Delete account (2-step + reauth) | Delete → confirm → password reauth | `ProfileDeleted` → sign out → `/`; blocked for admins | P0 | none |
| 340 | Delete account — Google account no password | Delete on social-login account | Provider-mismatch error (cannot delete via password) | P1 | none |
| 341 | Log out (confirmation) | Log Out → confirm | `AuthSignOutRequested` (fallback direct signOut) | P0 | none |
| 342 | Become-a-business promo / hub tile | Non-business views business tile | "Become a business" promo → account screen | P2 | none |
| 343 | Admin accordion (admin only + 2FA) | Admin opens admin tools | Verification/Reports panels behind `Admin2FAScreen` | P2 | none |

---

## 13. Maps / Traveler Mode
*Screens: `explore_map/explore_map_screen.dart`, `globe_explore/globe_screen.dart`, `discovery/travel_explore_map_screen.dart`, `spots/{spots,spot_detail}_screen.dart`, `saved_searches/saved_searches_screen.dart`, `profile/traveler_location_picker_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 344 | Explore map — nearby users | Open map (ProfileLoaded) | User cards w/ match %, distance, online dot, shared languages | P1 | none |
| 345 | Explore map — "Show me on map" toggle | Toggle visibility switch | `ToggleShowOnMap`; green/grey label | P2 | none |
| 346 | Explore map — radius chips | Select 1/5/10/25 km | Reloads nearby; default 5km | P2 | none |
| 347 | Explore map — empty + expand radius | No one nearby | Empty + "Expand radius" jumps to next radius | P2 | none |
| 348 | Globe — load + layers | Open globe → toggle layers | Contacts/Community Events/Live/Attractions/Experiences (mutually exclusive) | P1 | none |
| 349 | Globe — tap user/cluster/country | Tap pins | Profile+Chat sheet / cluster list / country matches sheet | P1 | none |
| 350 | Globe — external event booking tiles | Tap event tile in sheet | `launchUrl` booking; disabled when no bookingUrl | P2 | none |
| 351 | Globe — country search | Search a country | Filters to country | P2 | none |
| 352 | Travel explore map — travelers/guides | Open travel map | Travelers grouped by city + Local Guides; stats bar | P1 | none |
| 353 | Travel map — In-my-city / Worldwide filter | Toggle filter | List re-scopes; filter-specific empty states | P2 | none |
| 354 | Traveler location picker — search city | Search address | Debounced geocode results; "No results" snackbar | P2 | none |
| 355 | Traveler location picker — GPS gates | Tap "Use GPS" | Service/denied/deniedForever handled; resolves location | P1 | none |
| 356 | Traveler location picker — pick on map | "Pick on Map" → tap → confirm | Marker + reverse-geocode; "appear 24h" notice | P2 | none |
| 357 | Spots — list by city + category filter | Open Spots | Spots for city; category chips; empty/loading/error | P1 | none |
| 358 | Spots — add a spot | FAB → fill name/category → Create | `CreateSpot`; empty name blocks | P2 | none |
| 359 | Spot detail — photos + reviews | Open a spot | Gallery, rating, reviews; empty reviews state | P2 | none |
| 360 | Spot detail — write review | "Write a Review" → stars + text → Submit | `AddReview`, success snackbar | P2 | none |
| 361 | Saved searches — list + run | Open saved searches | Cards with summary; Run → NetworkDiscovery seeded | P2 | none |
| 362 | Saved searches — alerts toggle + delete | Toggle alerts / delete | Persists opt-in; delete removes; error snackbar | P2 | none |

---

## 14. Gamification
*Screens: `gamification/presentation/screens/{achievements,daily_challenges,leaderboard,journey,missions,seasonal_event,my_progress,personal_stats}_screen.dart`, `referral/referral_screen.dart`, `passport/cultural_passport_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 363 | View achievements | Open achievements | Unlocked/locked cards + progress header | P1 | gam #78, #79, #80, #87 |
| 364 | Filter achievements by category | Tap category chips | Filters; empty-category state | P2 | gam #81, #86 |
| 365 | Achievement details sheet | Tap a card | Details sheet (progress, reward) | P2 | gam #85 |
| 366 | Achievement unlock dialog | Trigger unlock | Auto unlock dialog + success snackbar | P2 | none |
| 367 | View daily challenges | Open challenges | Daily/Weekly tabs; rewards summary | P1 | gam #83 |
| 368 | Claim challenge reward | Challenge with `canClaim` → Claim | `ClaimChallengeRewardEvent`; success snackbar | P1 | none |
| 369 | View leaderboard | Open leaderboard | Rank card, top-3 podium, list; empty state | P1 | gam #82 |
| 370 | Leaderboard Global/Regional + period | Toggle scope / Week-Month-Year | Reloads accordingly | P2 | none |
| 371 | View seasonal events | Open seasonal event | Themed header, date range, time-remaining, challenges | P1 | gam #84 |
| 372 | Journey milestones | Open journey | Category tabs; completed/locked/in-progress states | P2 | none |
| 373 | Missions — streak + claim | Open missions | Streak header; Claim reward → "+N 🪙" snackbar | P2 | none |
| 374 | Missions — double-claim guard | Rapid-tap claim | Guard prevents double-claim; spinner | P2 | none |
| 375 | My progress — level/badges/stats | Open my progress | Level card, quick stats, badges (empty state), pull-refresh | P2 | none |
| 376 | Personal stats — refresh (CF) | Refresh personal stats | `refreshMyStats` CF (15s) → fallback local compute | P2 | none |
| 377 | Level-up celebration dialog | Cross level threshold | Celebration dialog (guarded by `lastCelebratedLevel`) | P2 | none |
| 378 | Referral — code load + share/copy | Open referral | Code loads; Share copies invite message + snackbar | P1 | none |
| 379 | Referral — redeem code | Enter code → redeem | Success clears field + "reward earned"; failure → info | P1 | none |
| 380 | Referral — live stats | Open referral | Invited count + coins earned stream | P2 | none |
| 381 | Cultural passport — stamps | Open passport | Countries/Languages/Events grids; earned vs locked; progress % | P2 | none |
| 382 | Passport — pull-to-refresh | Pull down | Invalidates cache, reloads | P2 | none |

---

## 15. Deep Links
*Service: `core/services/deep_link_service.dart` (app_links; only profile + event targets).*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 383 | Profile deep link (warm) | Open `greengo://u/{id}` / `https://greengo-chat.web.app/u/{id}` while running | Opens instant chat via `openConnectChat` | P1 | none |
| 384 | Event deep link (warm) | Open `.../e/{id}` while running | `EventDetailLoaderScreen` | P1 | none |
| 385 | Deep link cold start | Launch app from link | `getInitialLink` handled; navigator retry loop | P1 | none |
| 386 | Deep link while logged out | Open link when signed out | Silently dropped (no crash); web bounces to store | P1 | none |
| 387 | Self-profile deep link | Open link to own userId | Returns, never opens chat with self | P2 | none |
| 388 | Malformed / unknown deep link | Open bad link | Ignored, no navigation | P2 | none |
| 389 | Share profile / event link | Profile detail / event share → Share | Canonical HTTPS link opens OS share sheet | P2 | none |

---

## 16. Navigation / Bottom-menu
*Screen: `main/presentation/screens/main_navigation_screen.dart`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 390 | Bottom nav tab switching | Tap each bottom tab | `IndexedStack` switches; tabs stay alive | P0 | auth #7 (bar present) |
| 391 | Unread badges on nav tabs | Have unread messages/groups | Combined badge ("99+" cap) updates live | P1 | none |
| 392 | Nested navigator preserves bottom bar | Explore → "See all" sub-page | Bottom menu persists in nested nav | P1 | none |
| 393 | Collapsible bottom nav | Swipe down on bar | Hides bar, shows Menu pill; swipe up / tap restores | P2 | none |
| 394 | Android back — nested pop | Back with sub-page open | Pops nested navigator first | P1 | none |
| 395 | Android back — jump to tab 0 | Back on non-home tab | Jumps to Explore/Discover tab | P1 | none |
| 396 | Android back — exit confirmation | Back on tab 0 | Exit-app dialog (Cancel/Exit → `SystemNavigator.pop`) | P1 | none |
| 397 | App bar chips (dating build) | Discover tab app bar | Coin chip → shop, bell → notifications, globe, search, prefs, mode toggle | P2 | none |
| 398 | No-profile redirect | Login without `profiles/{uid}` | pushReplacement to OnboardingScreen | P0 | none |
| 399 | Home skeleton while checking profile | Open app | `HomeSkeleton` during `_isCheckingProfile` | P2 | none |
| 400 | Pre-launch countdown blur gate | Non-admin with active countdown | `CountdownBlurOverlay` covers shell + Logout | P1 | none |
| 401 | Admin bypass + red border | Admin opens app | All gates bypassed; red border around shell | P2 | none |
| 402 | Trial welcome / base-membership popup | First main-nav open (post-tour) | One-time trial dialog OR BaseMembershipDialog (suppressed during countdown) | P1 | none |
| 403 | Signup grant banners | Login with un-dismissed grant | MaterialBanner per grant; "Got it" flips dismissed | P2 | none |
| 404 | Daily 20-coin reward | Open app new day | 20 coins granted + streak touch | P2 | none |

---

## 17. Cross-cutting / i18n / Permissions / Safety
*Screens: `legal/legal_document_screen.dart`, `safety/{community_guidelines,date_checkin}_screen.dart`, `stories/stories_screen.dart`, `app_guide/app_guide_screen.dart`, `l10n/` + `LanguageProvider`.*

| # | Functionality | Steps | Expected result | Priority | Existing automated test? |
|---|---|---|---|---|---|
| 405 | Legal document load (Terms/Privacy) | Open Terms / Privacy | Loads by locale; version badge + updated date | P1 | none |
| 406 | Legal document — error/unavailable | Force load error / missing locale doc | Error + Retry / "not available" state | P2 | none |
| 407 | Community guidelines — first-run gate | First app run | Mandatory "Accept & Continue" persists acceptance | P1 | none |
| 408 | Community guidelines — read-only reopen | Open guidelines later | Close button (no re-accept) | P2 | none |
| 409 | Community guidelines — reduced motion | Enable reduce-motion | Instant (no staggered animation) | P2 | none |
| 410 | Date check-in — schedule | Fill location/date/time/interval → create | Green "scheduled" snackbar, returns `DateCheckIn` | P1 | none |
| 411 | Date check-in — no emergency contact block | Create without contacts | Red "add at least one contact" snackbar | P1 | none |
| 412 | Date check-in — emergency contacts add/remove | Add contact (name/phone/relationship) | Contact added; remove via × | P2 | none |
| 413 | Stories — view + tap navigation | Open a story | Tap left/right prev/next; long-press pause | P2 | none |
| 414 | Stories — auto-advance + close | Watch to end | Auto-advances; last → pop; X closes | P2 | none |
| 415 | Stories — add story (create) | Stories row → Add | Pick media (gallery/camera photo/video ≤30s) → caption → Post | P2 | none |
| 416 | Stories — reply/react (unimplemented) | Tap reply/heart | No-op stub (regression guard: flag unimplemented) | P2 | none |
| 417 | Stories — empty states | No stories / no active | "storiesNoStories" / "storiesNoActive" | P2 | none |
| 418 | i18n — supported locales | Switch through 7 languages | en/it/es/pt/pt_BR/fr/de all render translated | P1 | auth #12 |
| 419 | i18n — language persists across restart | Change language → restart | Locale restored from prefs; syncs from Firestore | P1 | none |
| 420 | i18n — no hardcoded strings on key screens | Switch to non-English | UI text localized (no raw English leaks) | P2 | none |
| 421 | App guide — sections + replay tour | Open App Guide (?) | 17 expansion sections; "Replay Tour" returns `replay_tour` | P2 | none |
| 422 | First-launch gesture tour | Fresh install main nav | ShowCase tour; replayable via App Guide → `resetAllTours` | P2 | none |
| 423 | Offline / network-failure resilience | Kill network mid-flow (login/chat send/event join) | Errors surface gracefully with retry, no crash/data loss | P0 | none |

---

## Coverage summary

| Category | Item count | Items with existing automated coverage | % covered |
|---|---|---|---|
| 1. Auth & Onboarding | 59 | 26 | 44% |
| 2. Explore / Discovery | 37 | 16 | 43% |
| 3. 1:1 Chat | 54 | 18 | 33% |
| 4. Group Chat | 21 | 0 | 0% |
| 5. Communities | 29 | 0 | 0% |
| 6. Events | 37 | 0 | 0% |
| 7. Coins & Shop | 21 | 5 | 24% |
| 8. Subscriptions | 12 | 4 | 33% |
| 9. Profile | 28 | 13 | 46% |
| 10. Notifications | 15 | 5 | 33% |
| 11. Business | 15 | 0 | 0% |
| 12. Settings | 15 | 3 | 20% |
| 13. Maps / Traveler | 19 | 0 | 0% |
| 14. Gamification | 20 | 8 | 40% |
| 15. Deep Links | 7 | 0 | 0% |
| 16. Navigation / Bottom-menu | 15 | 1 | 7% |
| 17. Cross-cutting / i18n / Safety | 19 | 2 | 11% |
| **TOTAL** | **423** | **101** | **~24%** |

> Note: the 120 shipped widget tests map to ~101 distinct matrix items (several tests validate the same functionality from different angles, e.g. Tests 30/18 both cover "edit basic info"). The remaining ~322 items — the entire Group Chat, Communities, Events, Business, Maps/Traveler, and Deep Links surfaces, plus all coin-spend / paid-tier / permission / moderation gates — have **no automated coverage** today.

### Top priorities to automate next (P0 items with NO existing test)
Group Chat, Communities, Events, Business, Deep Links, coin-spend and paid-tier gates dominate the untested P0 surface. See the "top 15 P0 gaps" in the delivery summary.
