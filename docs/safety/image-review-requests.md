# Held pictures, "My pictures" and review requests

Code: `functions/src/safety/` (`moderateUploadedImage.ts`, `mediaLibrary.ts`, `imageReview.ts`,
`moderationEffects.ts` `restoreQuarantined`, `mainPhotoFaceRule.ts`) and `functions/src/admin/moderationQueue.ts`
(`takeModerationAction`). App: `lib/features/media_library/`.

## 1. A held picture is never visible to anyone else

`moderateUploadedImage` (Storage trigger) checks every user image. On a hold (SafeSearch adult/racy/violence, or
no face on a personal main-photo upload) the object is **moved** to `quarantine/<path>`; the original path is
deleted, so every stored download URL stops working. The quarantined copy gets a **new download token**
(token URLs bypass storage.rules, so with the old token anyone who had seen the original URL could open the copy
by prefixing the path). The original token is kept in the copy's custom metadata `heldDownloadToken`;
`restoreQuarantined` puts it back, so a restored picture works again wherever its URL was already stored.

`quarantine/` is admin-only in storage.rules. Hash-list matches (NCII/CSAE) are moved to `safety_holds/` by the
takedown screening, unchanged.

The uploader sees a held picture in **My pictures** as "Not visible - held back / under review / rejected", without
any URL (`url: null`): the owner gets no shareable link to held content either.

Not changed: `status: 'error'` (Vision unreachable) still leaves the file in place; the app refuses such an upload
(fail closed in `ImageModerationGate`), and nothing is recorded in the library for it.

## 2. My pictures library

`media_library/{uid}/items/{itemId}`, `itemId` = object path with `/` replaced by `~` (same as `image_moderation`).
Written only by the server; owner may `get`, `list`, `delete` (rules on both rule files). Fields:

| field | |
|---|---|
| `path`, `bucket`, `generation`, `contentType` | the storage object (never moved; deleting the entry never deletes the object) |
| `status` | `approved` / `held` (quarantined, automated hold) / `rejected` (a person decided, or a hash-list block) |
| `url`, `thumbUrl` | download URL when approved, else `null`. `thumbUrl` is `null` today (no thumbnails are generated for these prefixes) |
| `width`, `height` | read from the image header (first 256 KB) when approved; `null` if unreadable |
| `hasFace` | Vision face result for public profile photos; on-demand result cached by the face rule; else `null` |
| `usage` | where it was first uploaded: `profile` (incl. storefront images), `event`, `experience`, `group`, `community`, `chat`, `group_chat` |
| `createdAt`, `updatedAt`, `approvedAt` | `approvedAt` exists only on approved items: the pickers order by it (no composite index) |
| `reasons`, `reasonCode`, `queueId`, `decisionId`, `quarantinePath`, `reviewable` | hold details |
| `review` | `null` or `{status: pending/approved/rejected, kind: imageReview/appeal, queueId, note, requestedAt, dueAt, decidedAt, decisionId}` |

Recorded: `profiles/{uid}/{photos,events,experiences,groups}/...`, `profiles/{uid}/<file>`, `communities/{uid}/...`
(owner = path segment, enforced by storage.rules) and `chat_images/` / `group_media/` with `customMetadata.uploaderId`
(storage.rules force it to the uploader). Never recorded: private-album uploads (`visibility: private`), voice,
video, verification, support attachments, ticket receipts.

`onMediaObjectDeleted` removes an **approved** entry when its object (same generation) is deleted, so the library
never offers a dead URL. Held entries survive the quarantine move.

Reuse: picking a library picture reuses its URL (no upload, no second moderation). The personal main-photo face
rule still applies server-side: `mainPhotoFaceRule` resolves a reused picture's face status from the verdict, then
the library item's `hasFace`, then an on-demand Vision call (now for any `profiles/`, `communities/`,
`chat_images/`, `group_media/` object, not only `profiles/`).

## 3. "Ask for a review" (callable `requestImageReview`)

Input `{ itemId, note? }` (note optional, max 500 chars). Allowed when the caller's item has
`reviewable: true` and status `held` (or `rejected` with an appealable decision), and no request is pending.
Rate limit: one open request per picture, **5 requests per user per 24 h** (`image_review_limits/{uid}`,
server-only). Error `details.code`: `not_found`, `not_reviewable`, `already_requested`, `rate_limited`,
`note_too_long`, `invalid_item`.

Two routes, both in the existing `moderation_queue`:

1. **The hold carried a DSA decision** (SafeSearch reason; `item.decisionId` set): the request **is the art. 20
   appeal** (`submitAppealForDecision`). Queue item `appeal__<decisionId>`, `itemType: 'appeal'`, resolved exactly
   like any other appeal (`approve` = overturn, restores the file; `dismiss` = uphold; the original decider may not
   resolve it). Extra fields on that item: `imageReview: {uid, itemId, objectPath, requestedAt}`, `slaDueAt`,
   `slaAlertAt`, `slaHours: 48`.
2. **No decision** (e.g. `no_face`): new item `imgreview__<itemId>__<generation>`:

```jsonc
{
  "queueId": "imgreview__profiles~uid~photos~1.jpg__1712",
  "itemType": "imageReview",
  "itemId": "profiles/uid/photos/1.jpg",          // object path
  "userId": "uid",
  "status": "pending",
  "priority": "medium", "priorityLevel": "P1", "category": "imageReview",
  "reasonCode": "other", "reasons": ["no_face"],
  "userNote": "It is me with sunglasses",          // or null
  "objectPath": "profiles/uid/photos/1.jpg",
  "quarantinePath": "quarantine/profiles/uid/photos/1.jpg",  // admins can read it (storage.rules)
  "libraryItemPath": "media_library/uid/items/profiles~uid~photos~1.jpg",
  "relatedQueueId": "image__profiles~uid~photos~1.jpg__1712", // the original quarantinedImage item
  "usage": "profile",
  "contentRef": { "type": "photo", "id": "1.jpg", "path": "profiles/uid/photos/1.jpg" },
  "reporterId": "system",
  "addedAt": "<ts>", "createdAt": "<ts>",
  "slaDueAt": "<+48 h>", "slaAlertAt": "<+24 h, removed once alerted>", "slaHours": 48
}
```

### Deciding an `imageReview` item (admin panel)

`takeModerationAction({ queueId, action, notes?, reasonCode?, explanation? })`, only two actions:

| action | effect |
|---|---|
| `approve` | `restoreQuarantined` copies the file back to its path (original token restored), the library item becomes `approved` with its URL, `review.status = approved`, the related `quarantinedImage` item is closed, the user gets the in-app notice `srvImageReviewApprovedTitle/Body` (`data.action = my_pictures`). The picture is available in My pictures to use anywhere; places that already stored the URL show it again. |
| `removeContent` | keeps the hold. A statement of reasons is created with `createModerationDecision` (decision id = queue id, `action: removeContent`, `reasonCode` = the given one or the item's, `explanation`, in-app + email, appealable - the existing DSA flow). The library item becomes `rejected`, `reviewable: false`. No strike. |

Any other action is refused (`failed-precondition`). Pass `reasonCode` + `explanation` (statement-of-reasons codes)
on `removeContent` so the user reads a real reason.

Approving or removing the original `quarantinedImage` item directly also keeps the library in sync (restore -> approved;
removeContent -> `rejected`, still appealable when a decision exists). Upheld appeals make the item `rejected`.

## 4. SLA reminder (`imageReviewSlaSweep`, hourly)

Query `moderation_queue where slaAlertAt <= now` (single-field, automatic index). Open items are reported once:
`admin_alerts/image_review_sla_<yyyy-mm-ddThh>` (`type: image_review_sla`, `count`, `queueIds`) and one email to
the security/safety recipients; `slaAlertAt` is removed and `slaAlertedAt` set. Resolved items just lose the field.

## 5. Indexes / deploy

No new composite index. Functions (deploy by name): new `onMediaObjectDeleted`, `requestImageReview`,
`imageReviewSlaSweep`; changed `moderateUploadedImage`, `takeModerationAction`, `resolveModerationAppeal`,
`mirrorPrivateProfileFields` (face rule), and the users of the per-uid inventory (`media_library`,
`image_review_limits` added): `onUserDeletedCleanup`, `deleteMyAccount`, `confirmAccountDeletion`,
`processDeletionFollowup`, `retryDeletionFollowups`, `exportMyData` (the export includes My pictures).
Rules: `firestore.additive.rules` (prod) and `firestore.rules`. storage.rules unchanged.

Backfill (existing approved pictures -> library): `functions/scripts/backfill-media-library.cjs` (dry run by default).

## 6. Admin preview of a held picture (`adminQuarantinePreview`)

`quarantine/**` is readable in storage.rules only with the legacy `token.admin == true` claim, which the current
admin role sync (`adminRole` claim) never sets, so panel moderators cannot open a held picture with the Storage SDK.
Callable `adminQuarantinePreview({ queueId })` (`functions/src/safety/quarantinePreview.ts`, superAdmin | moderator)
returns `{ url, expiresAt, path, location: 'quarantine' | 'original', contentType }`: a V4 signed URL valid 10 minutes
for the item's `quarantine/<objectPath>` (or the original path when the move failed / the file was restored). Works for
`quarantinedImage`, `imageReview` and picture `appeal` items (`imageReview.objectPath`); only moderated image prefixes,
never `safety_holds/` / `legal_holds/`. Each view writes `admin_audit_log` `viewedHeldImage`. Needs the runtime SA to
have signBlob on itself (same as `getMediaUrl`).

Composite index `moderation_queue (itemType ASC, status ASC, addedAt ASC)` serves the panel's Pictures queue
(oldest first). Until it is built the panel falls back to the existing `(status, addedAt)` index and filters by type.
