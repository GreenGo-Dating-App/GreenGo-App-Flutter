# Identity records (optional ID-document details, encrypted)

Owner decision 17 Oct 2026. Implementation: `functions/src/safety/identityRecords.ts`
(callables + sweep), `identityRecordsLogic.ts` (pure rules), `identityRecordCrypto.ts`
(AES-256-GCM). App: `lib/features/safety/presentation/widgets/identity_details_form.dart`,
`lib/features/safety/data/services/identity_details_service.dart`.

## What it is

When a user OPTIONALLY uploads an ID document (registration "photo holding your ID",
age-assurance document, business owner document) they may also type the document
details: first name, surname, date of birth, document type, issuing country,
document number. No OCR runs (google_mlkit_text_recognition is not a dependency;
adding a new ML Kit pod would break the aligned iOS pod set), so the user fills a
form. The reviewer sees the photo plus the typed details, corrects them if needed
and approves. Only then is the confirmed record kept, ENCRYPTED, for requests from
courts and police. The photo itself is deleted after the review (branch
`fix/delete-id-photos`, `verificationPhotoRetention.ts`). Nothing here is
required to use GreenGo; the verified phone is the requirement.

## Storage

`identity_records/{uid}` — server only. Rules: `allow read, write: if false` in
both `firestore.rules` and `firestore.additive.rules` (no client, not the owner,
not an admin-panel client). Same for `identity_access_log/{id}`,
`identity_rate_limits/{key}` and `phone_index/{hash}`.

| field | meaning |
|---|---|
| `uid` | subject |
| `status` | `pending` (submitted, not reviewed) / `verified` (confirmed by a reviewer) |
| `source` | `registration` / `age` / `business` |
| `enc` | `{alg: 'AES-256-GCM', keyVersion, iv, tag, ciphertext}` (base64) — the six fields as JSON |
| `keyVersion` | key version that encrypted `enc` (rotation) |
| `docType`, `issuingCountry` | non-sensitive metadata (also inside `enc`) |
| `verifiedAt`, `reviewedBy` | review metadata |
| `submittedAt` | when the user sent the details |
| `pendingExpiresAt` | pending only: submitted + 30 days (sweep) |
| `pending` | a re-submission on top of a verified record `{enc, source, submittedAt}` |
| `retainUntil` | null while the account exists; account deletion + 183 days after |
| `accountDeletedAt` | set by account deletion |
| `legalHold` | optional manual flag: blocks deletion |

Plaintext is never written to Firestore and never logged. The uid is bound as
AES-GCM additional data: a record copied to another uid does not decrypt.

## Key (Secret Manager `ID_DATA_KEY`)

Bound with `defineSecret('ID_DATA_KEY')` on the four callables. The value is either
one base64 32-byte key (version `v1`) or a keyring `v2:<b64>,v1:<b64>`: the FIRST
entry encrypts, all entries decrypt. Create it:

    openssl rand -base64 32 | firebase functions:secrets:set ID_DATA_KEY --data-file -

Rotation: set a new secret version `v2:<new>,v1:<old>`, redeploy the identity
functions, run a re-encrypt pass (read, decrypt, `adminConfirmIdentityDetails`
logic) when needed, then drop `v1`. Without the key the callables fail with
`failed-precondition identity_key_unavailable`; nothing is stored in clear.

## Callables (contract for the admin panel session)

All are v2 `onCall`, region default, memory 512MiB.

### `submitIdentityDetails` (signed-in user, for themselves)
Request `{source: 'registration'|'age'|'business', fields: {firstName, surname,
dateOfBirth 'YYYY-MM-DD', docType 'passport'|'id_card'|'driving_licence'|'residence_permit'|'other',
issuingCountry ISO-3166 alpha-2, docNumber}}` → `{ok: true}`. Validation errors:
`invalid-argument` with `details.code` `invalid_<field>`. 10 submissions per user per
24 h (`resource-exhausted rate_limited`). A verified record is not overwritten: the
new submission waits in `pending` until reviewed.

### `adminGetIdentityDetailsForReview` (MODERATION_ROLES)
Request `{uid}` → `{found: false}` or `{found: true, status, source, fields}`.
Writes `admin_audit_log` `view_identity_details_for_review`.

### `adminConfirmIdentityDetails` (MODERATION_ROLES)
Request `{uid, decision: 'approve'|'reject', fields?}`. Approve: the reviewer's
`fields` (corrected) or, when omitted, the user's entry are re-encrypted and the
record becomes `verified` (`verifiedAt`, `reviewedBy`, `docType`, `issuingCountry`,
`keyVersion`, `retainUntil: null`). Reject: a pending record is deleted (a pending
re-submission on a verified record is dropped; the verified record stays).
The in-app reviewer (`verification_admin_screen.dart`) calls it before the
existing approve / reject. The web admin panel should do the same.

### `adminRevealIdentityRecord` (SUPER_ADMIN_ONLY — `requireAdmin`, re-reads `admin_users`, admin 2FA when enforced)
Request `{uid, legalBasis: 'court_order'|'police_request'|'legal_hold'|'other',
reference: string (8..500 chars: case / process / letter number)}` →
`{uid, fields, docType, issuingCountry, verifiedAt, reviewedBy, retainUntil}`.
Order: role check → validation → rate limit (20 per admin per hour) → record
exists and is verified (`not-found no_identity_record`) → **`identity_access_log`
doc written** `{adminUid, adminEmail, subjectUid, legalBasis, reference, at}` →
decrypt → return. If the audit write fails nothing is decrypted.
UI must show a confirmation, require the legal basis + reference, never cache the
result, and must not log it.

## Retention

- Account exists: kept while the account exists (verified records).
- Account deleted (`deleteAccountData` → `runInventory`): a verified record gets
  `retainUntil = deletion + 183 days` (Marco Civil art. 15 period; the lawyer may
  extend); a pending one is deleted immediately.
- `sweepIdentityRecords` (daily 03:50 UTC) deletes records whose `retainUntil` has
  passed and pending records older than 30 days, unless the subject has an active
  legal hold (`legal_holds`, `activeHoldsFor`) or the record has `legalHold: true`.
  Paged (300 × 20), counts-only logs.
- `identity_records` and `identity_access_log` are listed in `RETENTION_STORES`
  (accountDeletion.ts).

## Deploy (owner)

Functions: `submitIdentityDetails, adminGetIdentityDetailsForReview,
adminConfirmIdentityDetails, adminRevealIdentityRecord, sweepIdentityRecords`
plus redeploy of every function bundling `accountDeletion.ts`
(`deleteMyAccount, confirmAccountDeletion, requestAccountDeletion,
onUserDeletedCleanup`, ...). Secret: `ID_DATA_KEY`. Rules: both rule files.

## What Terms / Privacy must state

- Providing ID-document details is OPTIONAL; a verified phone number is the only
  identity requirement.
- What is kept after the review: first name, surname, date of birth, document
  type, issuing country and document number, as confirmed by a GreenGo reviewer;
  the document photo is deleted after the review.
- Purpose: identifying the account holder at the request of a court, police or
  other competent authority, and for legal holds; legal basis: legal obligation /
  legitimate interest (LGPD art. 7 II and IX; GDPR art. 6(1)(c)/(f)).
- Stored encrypted (AES-256), access limited to super administrators, every access
  logged with its legal basis and reference.
- Retention: while the account exists and 6 months after deletion (longer only
  under a legal hold or when the law requires).
- The user may see that a record exists and request access / deletion through the
  usual privacy channel (deletion is refused during a legal hold or the legal
  retention period).
