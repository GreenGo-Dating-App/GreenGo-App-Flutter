# Mandatory verified phone (owner rule 2026-10-17)

Every GreenGo account must have an SMS-verified mobile number linked to it
as a Firebase Auth phone credential. The ID document is optional everywhere
(see `identity-records.md`).

## Who (owner decision 2026-10-17, final)

| Account | Requirement |
|---|---|
| Created on/after **16 Oct 2026 00:00 UTC** | Must verify at sign-up (onboarding step "verification") before the app is usable. Any new account that still lacks a phone (e.g. created 16-17 Oct before this release) is blocked by the gates below until it verifies. |
| Created before 16 Oct 2026 | **Never required, never blocked** - not now and not later. Only an optional, dismissible profile banner "Add your phone number (optional) - it helps keep your account safe". No sheet on join / book / host. |
| Phone sign-in accounts | Already verified (the onboarding step detects the phone and continues). |
| Guests (no account, guest booking / free guest RSVP) | Unchanged, no phone. |

Constant: `kPhoneRequiredForAccountsCreatedFrom`
(`lib/core/constants/phone_verification_countries.dart`) =
`PHONE_REQUIRED_FOR_ACCOUNTS_CREATED_FROM`
(`functions/src/shared/participation.ts`), sync test
`test/unit/safety/phone_countries_sync_test.dart`.

How "new account" is known:
- App: `FirebaseAuth.currentUser.metadata.creationTime`.
- Callables: Auth user `metadata.creationTime` (looked up only when the
  token has no `phone_number`).
- Rules (cannot see the creation time): the server-only marker
  `phone_required/{uid}` written by the Auth trigger
  `onAuthUserCreatedPhoneRequired` for every new account; rules
  `phoneOk() = phone_number claim || !exists(phone_required/{uid})`. One
  extra document read per gated write. Accounts created between 16 Oct and
  the deploy of the trigger: run `functions/scripts/backfill-phone-required.ts`
  (dry run, then `--apply`). The marker is deleted with the account.
  Chosen over a custom claim because a claim set at creation reaches the
  token only after a refresh (up to 1 h of bypass) and costs an Admin SDK
  write per sign-up anyway.
- Edge case: an account created before 16 Oct that never finished
  onboarding still sees the mandatory phone step when it finishes now
  (the step is the same for everyone); it can verify any supported number.

## Supported SMS countries

All European countries except Russia and Belarus, plus BR, US, CA (53 ISO
codes): EU27, NO IS LI, CH, GB, AL AD BA XK ME MK MD MC RS SM UA VA GI FO IM
JE GG AX, BR, US, CA. +1 numbers in non-US/CA NANP area codes (Caribbean,
Puerto Rico, Guam, ...) are refused. Single list: Dart
`kPhoneVerificationCountries` + TS `PHONE_VERIFICATION_COUNTRIES`.

Other countries: the country picker shows only supported countries, and
people whose profile/device country is unsupported see "Phone verification is
not yet available in your country" with support@greengochat.com. **They
cannot complete sign-up** (the step cannot be skipped) - deliberate: the
phone is the identity requirement in the Terms. Support can help them with a
number from a supported country, or the list can be extended (both files +
the console region policy).

## Flow

1. App: `checkPhoneAllowed({phone})` - supported country, number not
   remembered from a BANNED account, not indexed to another live account.
   Rate limit 10/hour/uid (per instance).
2. App sends the SMS: mobile `verifyPhoneNumber` + `linkWithCredential`;
   web `linkWithPhoneNumber` (invisible reCAPTCHA) + `confirm`.
   Firebase Auth refuses a number already linked to another account
   (`credential-already-in-use` -> "This number is already used by another
   account").
3. App: `reload()` + `getIdToken(true)` (the `phone_number` claim reaches the
   rules/callables), then `recordVerifiedPhone()`: the server reads the
   number from the Auth user record (never from the client), stores
   `profiles_private/{uid}.phone` (+ `phoneHash`, `phoneVerifiedAt`; owner and
   admins can read, the owner cannot write these keys, never public) and
   `phone_index/{HMAC-SHA256(PHONE_INDEX_KEY, e164)}` = `{uid, verifiedAt}`.
4. Account deletion (`deleteAccountData`, every path): a BANNED account's
   index entry is kept as `{banned: true, uid: null, retainUntil}` (hash
   only) for **5 years** after the deletion (Privacy Policy), otherwise
   removed. Until then the number cannot verify again (`phone_banned`). The
   daily `sweepIdentityRecords` run also deletes expired banned hashes
   (`runBannedPhoneSweep`, paged 300 x 50 per run; single-field query on
   `retainUntil`, no composite index).

`phone_index` is server-only (`allow read, write: if false`).

## Where the phone is required (new accounts only)

Client gate `PhoneVerificationGate.ensureVerified` (returns true at once for
old accounts): inside `BaseMembershipGate.ensureCanParticipate` /
`ensureCanCreate` (join / RSVP going-waitlist, ticket purchase, booking,
event / community event / experience creation), business account switch,
Business Center (profile tab + Explore), business verification request,
experiences ID gate (`ExperienceSafetyFlow.ensureIdDocument`), community
publishing (`AgeVerificationGate.ensureCanPublish`). Server refusals
`phone_verification_required` open the same sheet.

Server:
- Callables (`assertPhoneVerified`): `createTicketCheckout` (kind `event`;
  `experience` = paying an existing booking, not gated), `createBooking`,
  `createUserExperience`, `publishUserExperience`. Refusal
  `failed-precondition` `{code: 'phone_verification_required'}`.
- Rules `phoneOk()`: attendee going / waitlist (`canParticipate`), booking
  consents, `events` create, turning `isBusiness` on,
  `business_verification_requests` create, community chat posting
  (`isAgeVerified() || phoneOk()`), editing a published paid experience
  (`hostIdApproved() || phoneOk()`).

## ID document: optional everywhere (gates changed)

| Gate | Before | Now |
|---|---|---|
| Sign-up step 3 | photo OR phone | phone mandatory, ID photo optional |
| Create experience (`createBlockReason`) | ID uploaded | verified phone, or old account; ID optional |
| Publish paid experience (`publishBlockReason`) | ID approved | verified phone, or old account |
| Book experience (`createBooking`) | guest ID uploaded | phone for new accounts (wrapper); no ID |
| Paid booking: host check | host ID approved | host ID approved OR host phone OR host account older than the rule |
| Edit published paid experience (rules) | `hostIdApproved()` | `hostIdApproved() || phoneOk()` |
| Community chat posting (rules + app) | `isAgeVerified()` | `isAgeVerified() || phoneOk()` |
| Business verification request | OTP + owner ID document | account phone only (new accounts); owner ID optional |

Unchanged: regional age assurance (`ageAssuranceGate.ts`, BR / GB / US-TX
switch) and the age-document flow itself.

## Console settings the owner must apply (not done by code)

1. **Identity Platform > Settings > SMS region policy**: *Allow* only the 53
   regions above (AD AL AT AX BA BE BG BR CA CH CY CZ DE DK EE ES FI FO FR
   GB GG GI GR HR HU IE IM IS IT JE LI LT LU LV MC MD ME MK MT NL NO PL PT
   RO RS SE SI SK SM UA US VA XK). This is the real SMS-pumping brake.
2. **Phone provider enabled** in Firebase Auth (already, phone sign-in).
3. **Web: reCAPTCHA Enterprise SMS defense** (Identity Platform >
   reCAPTCHA, "SMS toll fraud protection", start in audit mode, then
   enforce); add the web domains (greengo-chat.web.app, greengochat.com).
4. **App Check**: Play Integrity (Android), App Attest / DeviceCheck (iOS),
   reCAPTCHA Enterprise (web); enforce for Authentication once metrics are
   clean.
5. Optional: Identity Platform SMS quota alert / budget alert on the SMS SKU.
6. Secret / env: `PHONE_INDEX_KEY` (functions env, >= 32 random chars,
   NEVER change it later - it re-keys every hash; without it a key is
   derived from `PROFILE_LOCATION_JITTER_KEY`).

## Deploy

Rules (`firestore.additive.rules`), functions by name: `checkPhoneAllowed`,
`recordVerifiedPhone`, `onAuthUserCreatedPhoneRequired` (then run the
backfill script), `createTicketCheckout`, `createBooking`,
`createUserExperience`, `publishUserExperience`, and every function bundling
`auth/accountDeletion.ts` (`deleteMyAccount`, `confirmAccountDeletion`,
`requestAccountDeletion`, `onUserDeletedCleanup`, ...). Ship the app first or
together: older app builds have no verify flow for the gated actions (old
accounts are unaffected either way).
