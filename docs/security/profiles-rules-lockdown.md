# Public profile lockdown (P1-4 follow-up)

Audit findings: C-07 (exact location and sensitive data on a world-readable
profile), C-10 (ID-selfie download URL), H-05 prep. Plan task P1-4.

Phase 1 (this branch) is additive: `profiles_private/{uid}` exists, the mirror
triggers fill it, and the new app writes sensitive fields only there. The public
`profiles/{uid}` still carries the old fields because old app versions read and
write them. This document holds the rules and steps for the **lockdown**, which
the coordinator applies later in monitored waves. Nothing here is deployed by
this branch.

## 1. Deployment order

1. **Deploy the functions:** `mirrorPrivateProfileFields`, `syncCoarseFromPrivateProfile`,
   `refreshBirthdayAges`, `getVerificationPhotoUrl`, `getSharedAlbum`, plus the changed
   `submitAgeDocument`, `getAgeVerificationState`, `deleteMyAccount` / the deletion cascade
   (the `profiles_private` inventory line). Also deploy the rules containing the
   `profiles_private` block (additive).
   - Console, once: give the functions runtime service account
     `roles/iam.serviceAccountTokenCreator` on itself, because `getSignedUrl` uses signBlob.
   - Set `PROFILE_LOCATION_JITTER_KEY` (at least 16 random chars) in the functions env
     BEFORE the first deploy. If it changes later, every approxLocation moves once.
2. **Run the backfill:** `functions/scripts/backfill-profiles-private.ts` until `done=true`.
   It is safe to re-run.
3. **Ship the app** that reads its own data from `profiles_private` and other users' data from
   `geohash5` / `approxLocation` / `age`. Update the admin panel (section 5). Then raise
   `app_config/version.minVersion` to that build.
4. **Wait** until old versions have drained (watch the share of writes that carry
   `location.latitude` on `profiles`).
5. **Run the strip:** `functions/scripts/strip-public-sensitive-fields.ts`, first as a dry run
   (the default), then with `--apply`.
6. **Deploy the lockdown rules** below (Firestore, then Storage).

## 2. Firestore: `profiles` field allow-list

Add this to the owner branch of `allow create` and `allow update` in
`match /profiles/{profileId}`. It sits next to the existing privilege checks.
Admin-SDK writers (triggers, callables, scripts) are unaffected.

```
// Fields that must never be written to the PUBLIC profile by a client:
// sensitive data lives in profiles_private; coarse values are server-computed.
function profilePrivateOnlyKeys() {
  return ['dateOfBirth', 'sexualOrientation', 'email', 'verificationPhone',
          'verificationPhotoUrl', 'privatePhotoUrls', 'geohash',
          'geohash5', 'approxLocation', 'age'];
}
function noPrivateFieldsInPublicProfile() {
  return !request.resource.data.keys().hasAny(profilePrivateOnlyKeys())
    // location / travelerLocation stay (city, country, displayAddress) but
    // without coordinates.
    && !(request.resource.data.get('location', {}).keys().hasAny(['latitude', 'longitude']))
    && !(request.resource.data.get('travelerLocation', {}) is map
         && request.resource.data.travelerLocation.keys().hasAny(['latitude', 'longitude']));
}
```

- On **create**, add `&& noPrivateFieldsInPublicProfile()`.
- On **update**, for the owner branch, compare the changed keys instead, so a doc
  the server already wrote coarse fields to stays updatable:

  ```
  && !request.resource.data.diff(resource.data).affectedKeys()
        .hasAny(profilePrivateOnlyKeys())
  && request.resource.data.get('location', {}).get('latitude', null) == null
  && request.resource.data.get('location', {}).get('longitude', null) == null
  ```

The `ageVerification` map is already immutable for the owner.

## 3. Firestore: bounded listing and the blocked-user rule

Replace `allow read: if isSignedIn();` on `profiles/{profileId}` with:

```
// Single profile view. A user who was blocked by the profile owner can't open it.
allow get: if isSignedIn()
  && (isOwner(profileId)
      || isAdminPanelUser()
      || !exists(/databases/$(database)/documents/block_index/$(profileId + '_' + request.auth.uid)));
// Discovery / search queries: bounded pages only.
allow list: if isSignedIn() && request.query.limit <= 50;
```

**Data model change needed for the blocked-user rule.** Today blocks live in
`blockedUsers/{randomId}` as `{blockerId, blockedUserId}` (written by
`chat_remote_datasource.dart` and `safety_actions_service.dart`, and read in both
directions by `BlockedUsersService`). Rules can only call `exists()` on a known
document path, so a random id can't be checked. The fix is to add a
**deterministic index** that only the server writes:

- `block_index/{blockerId}_{blockedUserId}` = `{blockerId, blockedUserId, createdAt}`, maintained by a new
  `onDocumentWritten('blockedUsers/{id}')` trigger: create the index doc on create,
  delete it on delete. Run a one-off backfill over `blockedUsers`.
- Rules: `match /block_index/{id} { allow read, write: if false; }`. The `exists()`
  inside rules does not need read permission.
- `list` rules can't evaluate `exists()` per result document. Queries therefore still
  depend on the client filter: `BlockedUsersService` already loads both directions,
  and the app now drops blockers from discovery/search. A blocker who should be
  hidden from a *list* result needs a server-side search (P2) for strict enforcement.

Also fix `blockedUsers` / `blocked_users`. Today any signed-in user can read,
create and delete any block. The lockdown should be:

```
allow read: if isSignedIn() && (resource.data.blockerId == request.auth.uid
                               || resource.data.blockedUserId == request.auth.uid);
allow create: if isSignedIn() && request.resource.data.blockerId == request.auth.uid;
allow delete: if isSignedIn() && resource.data.blockerId == request.auth.uid;
```

## 4. Firestore: `album_access` (private album grants)

`privatePhotoUrls` now lives in `profiles_private`. The app reads another user's
private album through the `getSharedAlbum({ownerId})` callable. That callable returns
the photos only to the owner, or to a caller who holds an
`album_access {ownerId, grantedToId: caller}` document.

**The current rules let ANY signed-in user create such a document**, which means
self-granting access to anyone's album. Without this fix the callable gate is
worthless:

```
match /album_access/{docId} {
  allow read: if isSignedIn() && (resource.data.ownerId == request.auth.uid
                                 || resource.data.grantedToId == request.auth.uid);
  allow create: if isSignedIn() && request.resource.data.ownerId == request.auth.uid
                && request.resource.data.keys().hasOnly(['ownerId', 'grantedToId', 'grantedAt']);
  allow update: if false;
  allow delete: if isSignedIn() && resource.data.ownerId == request.auth.uid;
}
```

The app's `AlbumAccessDataSource` queries use `ownerId ==` or `grantedToId ==`
filters, so they satisfy the read rule. Check `getAccessibleAlbums` and
`getGrantedUsers` (both filter on the caller's own id) before deploying.

## 5. Storage: legacy selfie location (C-10)

Older app versions uploaded the onboarding verification selfie to
`profiles/{uid}/verifications/<ts>.jpg`. Storage rules make everything under
`profiles/{uid}/` readable by any signed-in user. The new app uploads to
`verifications/{uid}/` (owner and admin only). `getVerificationPhotoUrl` accepts both
prefixes.

Lockdown rule. The sub-folder match must come first, and the broad match must exclude
it, because Storage ORs matching rules:

```
match /profiles/{uid}/{allPaths=**} {
  allow read: if signedIn() && !allPaths.matches('verifications/.*');
  allow write: if isOwner(uid) && validUpload();
}
match /profiles/{uid}/verifications/{file=**} {
  allow read: if isOwner(uid) || isAdmin();
}
```

There is an optional one-off script (not written yet). It would list
`profiles/*/verifications/*` with the Admin SDK, copy each file to
`verifications/{uid}/legacy-<name>`, set `profiles_private/{uid}.verificationPhotoPath`
to the new path, and delete the original. Run it after step 3, so that no old client
still uploads there.

## 6. Admin panel changes (greengo-admin-panel, before the strip)

- `src/pages/Moderation.tsx` and `src/pages/Users.tsx` show
  `profile.verificationPhotoUrl`. They should call `getVerificationPhotoUrl({uid})`
  (moderator / superAdmin) and render the returned `url`. That URL is short-lived,
  so fetch it when the dialog opens. Until then, old submissions keep working
  (legacy URL) but new-app submissions show no photo in the panel.
- `src/services/userService.ts` and `verificationService.ts` read `dateOfBirth`
  (and email) from `profiles`. Read `profiles_private/{uid}` instead. Admin-panel
  users can read it under the new rule.

## 7. Server-side readers of the sensitive public fields

These must not depend on public copies after the strip:

| File | Reads | Status / action |
|---|---|---|
| `safety/ageAssurance.ts` | `dateOfBirth`, `ageVerification.documentHash` | **Done**: reads private first; the duplicate check queries both collections; the hash and document DOB are also written to private |
| `discovery/candidatePoolPrecompute.ts` | `dateOfBirth`, `location` / `travelerLocation` lat/lng, `sexualOrientation` | Before the strip: use `age` + `approxLocation` (or read `profiles_private` in batch with `getAll`) |
| `discovery/profileGeohash.ts` (`backfillProfileGeohash`) | public lat/lng → public `geohash` | Retire after the strip. `geohash5` replaces it; the private `geohash` is kept by the app |
| `presence/onPresenceUpdate.ts` | `location.latitude/longitude` (reverse-geocodes a missing city) | After the strip it returns early (no coordinates). Read `profiles_private` if city enrichment is still wanted |
| `admin/userManagement.ts`, `admin/adminDashboard.ts` | `users/{uid}` email/lat/lng (the `users` collection, not `profiles`) | Unaffected by this change (`users` is already owner/admin only) |
| `share/sharePreview*.ts` | display name / photo only | No sensitive fields |
| `auth/accountDeletion.ts` | n/a | **Done**: `profiles_private` is in `ACCOUNT_DATA_INVENTORY` and is deleted by `onProfileDeleted` via the mirror trigger |

## 8. Index notes

- `profiles` `orderBy('geohash5')` range scans: these use single-field indexes, which are automatic.
  The Explore map combines them with `showOnMap ==`: the composite index `profiles(showOnMap ASC, geohash5 ASC)`
  is added in `firestore.indexes.json` (deploy it with the functions). Without it the app retries the same
  ranges without the filter.
- `profiles_private where birthMonthDay ==` ordered by document id: automatic single-field index.
- `profiles_private where ageVerification.documentHash ==`: automatic single-field index.

## 9. Status (INC-2026-001, branch fix/close-support-exposure)

Implemented in `firestore.rules` AND `firestore.additive.rules`, `storage.rules`:

- §2 field allow-list: `publicProfileCreateOk()` / `publicProfileUpdateOk()` bind EVERY client
  branch (owner, admin panel, profile admin, counters). Private-only keys (`dateOfBirth`,
  `sexualOrientation`, `email`, `verificationPhone`, `verificationPhotoUrl`, `verificationPhotoPath`,
  `privatePhotoUrls`, `geohash`, `fcmToken`, `birthMonthDay`, coordinates inside `location` /
  `travelerLocation`, `ageVerification.documentHash` / `.documentDateOfBirth`) may stay as they are or be
  cleared (null / delete), never get a new value. Server-coarse keys (`geohash5`, `approxLocation`, `age`)
  are never changed by a client.
- §3 `get` denies a user the profile owner blocked (`block_index/{owner}_{caller}`, maintained by the
  `syncBlockIndex` trigger; backfill `functions/scripts/backfill-block-index.ts`). `blockedUsers` /
  `blocked_users` are party-only. The `list` page cap (`limit <= 50`) is **deferred**: app 4.6.0+194/195
  still runs profile queries with limit 75/100/200/500/1000 and unbounded `whereIn` batches.
- §4 `album_access`: owner-only grants.
- §5 Storage legacy selfie folder: owner/admin only (match on the first path segment, since a `**`
  wildcard is a path, not a string).
- Push tokens: every sender reads `users/{uid}.fcmToken`; the app no longer writes the token to the
  public profile; `strip-public-sensitive-fields.ts --fcm-token` removes legacy public tokens.
- Server: `writeStatus` (ageAssurance) no longer puts `documentHash` / `documentDateOfBirth` on the
  public profile (they go to `profiles_private` only).

Deploy order: functions `syncBlockIndex` (+ the changed functions) -> `backfill-block-index --apply`
-> Firestore rules -> Storage rules -> optional `strip-public-sensitive-fields --fcm-token --apply`.
