# P3-1 Regional age assurance: enforcement map and lockdown-wave rules

Audit H-21. Laws: Brazil ECA Digital (Lei 15.211/2025), UK Online Safety Act
("highly effective age assurance"), Texas SB 2420 (plus the Utah and Louisiana
app-store age laws), EU DSA art. 28.

**Owner decision (2026-10-08).** When the feature is switched on, users in the
configured regions need strong age assurance before they can use people
discovery or start private 1:1 messages. The rest of the app keeps working, and
so do conversations the user has already written in. Everyone else keeps the
self-declared gate (`declareAge`, under-18 blocked). Minors are blocked
entirely, so there are no parental-supervision tools.

## Switches (admin-editable)

| Document / field | Default | Meaning |
|---|---|---|
| `app_config/feature_flags.ageAssuranceEnforced` (or `flags.ageAssuranceEnforced`) | `false` (absent) | Master switch. While off, nobody is gated. |
| `app_config/age_assurance.regions` | `['BR','GB','US-TX']` | ISO 3166-1 countries or ISO 3166-2 subdivisions. |
| `app_config/age_assurance.acceptedAndroidSources` | `[3, 4]` | Play `ageRangeSource` tiers accepted: TIER_C (card, email, selfie, ID or tax ID) and TIER_D (ID plus selfie, or digital ID). TIER_A (self-declared) and TIER_B (guardian) are recorded but not accepted. |
| `app_config/age_assurance.acceptedAppleDeclarations` | `['checkedByOtherMethod','governmentIDChecked','paymentChecked']` | Apple `AgeRangeDeclaration` case names accepted. `selfDeclared` is not accepted. |
| `app_config/age_assurance.storeSignalMaxAgeDays` | `365` | After this many days, a store signal stops counting and must be checked again. |

Server config is cached for 60 s per instance. The app caches status for 10 min.

## What satisfies assurance

Any one of these:

- **`id_verification`:** `profiles.isAgeVerified` or `id_documents/{uid}.ageVerified`. Both are server-owned.
- **`store_signal`:** the latest `age_assurance/{uid}.storeSignal` has `accepted: true` and is fresh.
- **`admin_override`:** `age_assurance/{uid}.adminOverride.granted == true`. Set by `setAgeAssuranceOverride`, which is superAdmin only and writes to `admin_audit_log`.

The record lives in `age_assurance/{uid}`. It is server-only: no rule matches it, so the default-deny rule applies. It holds `storeSignal{platform, source, strength, ageLower, ageUpper, shared, accepted, minor, installId, verifiedServerSide:false, recordedAt}`, `adminOverride{granted, by, reason, at}`, `regionHints`, `lastSatisfiedMethod/At`, and `blocked` plus `blockedComputedAt`, which mirror the rules (see below). The record is deleted with the account through the deletion inventory.

A store signal that says the user is under 18 is treated like `declareAge` with an under-18 date: `age_gate/{uid}` is set and the profile becomes `age_blocked`.

## Region detection

1. The country comes from the public `profiles.location.country` (an English name or an ISO code; common it/de/es/fr/pt names are mapped).
2. For the US, the state comes from the public coordinates rounded to 0.1 degree, using a Texas point-in-polygon test. The exact private location is never used. Accuracy at the state lines with NM, OK, AR and LA is roughly 10 to 20 km. The country is checked first, so the polygon's spill into Mexico and the Gulf does not matter.
3. Device hints sent with `getAgeAssuranceStatus` (`localeCountry`, `storeCountry`, `subdivision`) only **fill in** a missing country or **add** a region. They never remove one, and they are stored for later enforcement calls.
4. A US user with no coordinates and no hint is treated as **not** Texas. This is deliberate: gating every US user would over-block. Other US states (UT, LA) can be added to `regions`, but they are only detected through the `subdivision` hint until polygons are added.

A user can still spoof a profile location. ID verification is accepted everywhere, so being correctly gated never leaves anyone stuck.

## Enforcement: server vs client (this branch)

| Path | Where | Enforced |
|---|---|---|
| `spendCoins` `direct_message`, `superlike` (alias `super_like`) | Cloud Function | **Server.** Refused with `failed-precondition` and `details.reason = 'age-assurance-required'` before any charge. |
| `spendCoins` `grid_view_more`, `discovery_see_more` | Cloud Function | **Server.** Same refusal. |
| `scheduleMessage` | Cloud Function | **Server.** Refused unless the sender already has a message in that conversation. |
| `getAgeAssuranceStatus` / `recordStoreAgeSignal` / `setAgeAssuranceOverride` | Cloud Function | New. |
| Discovery stack, Explore "people around you", nickname search (`DiscoveryRemoteDataSource`) | Client, Firestore reads | Client: returns nothing when gated. |
| People map (`ExploreMapRemoteDataSource`) | Client, Firestore reads | Client: returns nothing. |
| Discovery, Network discovery, Explore map, Travel map and Video discovery screens | Client | Client: the gate panel replaces the screen. |
| New conversation: `openConnectChat`, `getOrCreateSearchConversation`, match `getConversation`, super-like conversation | Client, Firestore writes | Client: gate screen, plus `AgeAssuranceRequiredException` in the data layer. |
| First message in a conversation (`ChatScreen` sends and replies, `ChatRemoteDataSource.sendMessage`) | Client, Firestore writes | Client: allowed only when the user already wrote in the conversation. |
| `candidate_pools` reads | Client | Already denied: no rule matches, so the default-deny rule applies. |

Every client check fails **open** on network errors. Until the rules below are deployed, a modified client can bypass the client-side rows.

Not gated, by decision: support chats, group, community and event chats (not 1:1), and coin-gift conversations (`coin_remote_datasource` and `coin_shop_screen`). Gifting needs the recipient to be found first, which is gated. Gate gifts too if counsel wants that.

## Rules for the lockdown wave (NOT applied in this branch)

Rules cannot compute a region, so the server keeps a mirror,
`age_assurance/{uid}.blocked` (= required && !satisfied). It is refreshed by
`getAgeAssuranceStatus`, `recordStoreAgeSignal` and `setAgeAssuranceOverride`,
and written only when it changes. `get()` inside rules bypasses the
default-deny on `age_assurance`.

```
function ageAssuranceOn() {
  let f = get(/databases/$(database)/documents/app_config/feature_flags).data;
  return f.get('ageAssuranceEnforced', false) == true
    || f.get('flags', {}).get('ageAssuranceEnforced', false) == true;
}
function ageAssuranceBlocked() {
  let p = /databases/$(database)/documents/age_assurance/$(request.auth.uid);
  return ageAssuranceOn() && exists(p) && get(p).data.get('blocked', false) == true;
}

// conversations/{conversationId}: no NEW 1:1 conversation while blocked
// (support conversations exempt).
allow create: if isSignedIn()
  && (request.auth.uid == request.resource.data.get('userId1', '')
      || request.auth.uid == request.resource.data.get('userId2', ''))
  && (request.resource.data.get('conversationType', '') == 'support'
      || !ageAssuranceBlocked());

// conversations/{id}/messages/{messageId}: a blocked user may only write
// where they already wrote. Needs `conversations/{id}.wrote.<uid> == true`,
// set SERVER-side on a sender's first message (one guarded write in the
// existing onNewMessagePush trigger) and made non-client-writable:
allow create: if convMember(conv())
  && (request.auth.uid == request.resource.data.get('senderId', request.auth.uid)
      || request.resource.data.get('senderId', '') == 'system')
  && (!ageAssuranceBlocked()
      || conv().get('wrote', {}).get(request.auth.uid, false) == true
      || conv().get('conversationType', '') == 'support');
// ...and on conversations/{id} update:
//   && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['wrote'])

// Discovery side effects:
match /swipes/{docId}  { allow create: if isSignedIn() && !ageAssuranceBlocked(); }
match /likes/{likeId}  { allow create: if isSignedIn() && !ageAssuranceBlocked(); }
match /matches/{matchId} { allow create: if isSignedIn() && !ageAssuranceBlocked(); }
match /profiles/{profileId} {
  // People discovery reads profiles with LIST queries; get() of a known
  // profile (chat header, own profile) stays open.
  allow get: if isSignedIn();
  allow list: if isSignedIn() && !ageAssuranceBlocked();
}
```

Notes for the wave:

- **Cost.** Each guarded write costs up to three extra document reads (`feature_flags`, `exists` and `get` of `age_assurance`; rules cache repeated gets within one evaluation). Only creates and lists pay this cost; reads of open conversations do not.
- **`profiles` list.** Check every non-discovery profile list query in `lib/` before splitting `read` into `get` and `list`: the nickname check at onboarding, community member lists, and `user_directory_service` batched `whereIn` reads. Blocked users would lose those. An alternative is to gate only the geo or discovery query shapes, which rules cannot tell apart, or to move discovery behind a callable.
- **Before switching the flag on.** Backfill `blocked` for existing users in the regions, for example with a one-off admin script that calls `computeAgeAssurance` and `syncBlockedFlag` over profiles filtered by `location.country`. Until it is set, rules treat a user as not blocked (fail open).
- **ID verification approval** (`submitAgeDocument` / `reviewAgeVerification`) does not refresh `blocked`. The app calls `getAgeAssuranceStatus` right after verification, which clears it. For the wave, also call `syncBlockedFlag` from `finalizeIdDocumentDecision`.
- **Old app versions** do not call `getAgeAssuranceStatus`, so they never see the gate. Ship the wave only after `app_config/version.minVersion` includes this build.

## Store signals: trust model (for counsel)

- **Google Play Age Signals** (`com.google.android.play:age-signals:0.0.4`, beta) returns an age band, an `ageRangeSource` tier and an install id. Google started returning signals for users in **Brazil** (17 March 2026, ECA Digital) and for **Texas** accounts created after 28 May 2026 (SB 2420). There is **no signed, server-verifiable token**. Google recommends wrapping the call with Play Integrity. The callable accepts an optional `integrityToken`, but it is **not verified yet**, and `verifiedServerSide` is always false.
- **Apple Declared Age Range** (iOS 26, `AgeRangeService.requestAgeRange(ageGates: 18)`) returns a band and an `AgeRangeDeclaration`. It is also unsigned. It needs the `com.apple.developer.declared-age-range` entitlement.
- **Because both are read on the device, a modified client can forge them.** They are recorded with their source and only ever satisfy the `store_signal` method. Only tiers that rest on a check beyond self-declaration are accepted by default.
- **Does this meet the bar in each jurisdiction?** (DRAFT, for counsel)
  - **UK (Ofcom "highly effective"):** an unsigned client-reported signal is unlikely to be enough on its own. Ofcom's listed methods include ID matching, facial estimation and similar. Consider accepting **only** `id_verification` and `admin_override` for GB, either with a per-region accepted-methods setting (not built) or by setting `acceptedAndroidSources: []` and `acceptedAppleDeclarations: []` if GB is the only region.
  - **Texas SB 2420 / Utah / Louisiana:** these laws put the verification duty on the **app stores**. Developers must use the store's signal. Using the Play and Apple signal is the intended path. The developer-side duty is to use it and to respect parental consent, which does not apply here because minors are blocked.
  - **Brazil ECA Digital:** it requires "reliable" age verification mechanisms and does not accept self-declaration. Store signals from TIER_C/D or a checked Apple declaration are a reasonable argument. ID verification is the safe path.
  - **EU DSA art. 28:** this is a proportionality duty, not a specific method. Nothing EU-wide is gated by default.
- **ID verification** (the existing flow) is OCR of a government ID plus a match with the declared birth date. There is no liveness or selfie check, which is a gap for "highly effective" under the UK regime. Images are deleted after the decision (P2-6).

## Deploy list (when approved)

Functions: `getAgeAssuranceStatus`, `recordStoreAgeSignal`, `setAgeAssuranceOverride`, `spendCoins`, `scheduleMessage`. Also redeploy any function that bundles `accountDeletion.ts` inventory changes (`deleteMyAccount`, `confirmAccountDeletion`, `onUserDeletedCleanup`, `requestAccountDeletion`). No index or rules changes in this branch. The `messages` `senderId` equality query uses the automatic single-field index.

Admin panel (separate repo, not edited): an override control that calls `setAgeAssuranceOverride({userId, granted, reason})`, superAdmin only. Optionally show `getAgeAssuranceStatus`-like data per user. That needs an admin read callable or a direct read of `age_assurance/{uid}`, and panel rules allow neither today.
