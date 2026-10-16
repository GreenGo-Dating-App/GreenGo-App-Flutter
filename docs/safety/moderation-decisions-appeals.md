# Moderation decisions, statements of reasons and appeals

Terms of Service sections 17-18; EU DSA arts. 17 (statement of reasons), 20 (internal complaints), 23 (misuse).
Code: `functions/src/safety/` (`moderationDecisions.ts`, `moderationEffects.ts`, `appealResolution.ts`,
`appealPage.ts`, `repeatOffenders.ts`, `reporterStanding.ts`).

## What happens on every decision

Every account or content measure, and every decision **not** to act on a report, goes through
`createModerationDecision`:

| Stored in `moderation_decisions/{id}` (server-only) | |
|---|---|
| `userId`, `role` | `affected` (the measure is about them) or `reporter` (no action on their report) |
| `action` | `removeContent`, `issueWarning`, `suspendUser`, `banUser`, `shadowBan`, `requireVerification`, `restrictAccount`, `reporterWarning`, `suspendReporting`, or `noAction` (reporter) |
| `reasonCode`, `explanation` | the facts and the rule, as written by the moderator |
| `contentRef` `{type, id, excerpt}` | which Content it concerns. The excerpt is only taken from the user's own content, never from the reporter's text |
| `automated`, `automatedDetection`, `automatedDecision` | keyword screen (`keyword`), Vision SafeSearch (`vision`), hash list (`hash`). `automatedDecision` is true only when the tool applied the measure itself (a Vision hold) |
| `effects[]` | what the measure changed, so an overturn can reverse it |
| `appealable`, `appealDeadline` (183 days), `appealStatus`, `appealOutcome` | |

The user is told **in the app** (notification `data.action = moderation_decision`) and **by email** (Resend,
`email_dispatch` idempotency). The email has a signed link to the web appeal page `moderationAppeal`, which also
works when the account is banned and Firebase Auth is disabled. The email's Reply-To is safety@greengochat.com.

No notice where the law forbids it: decisions with `reasonCode: 'csae'` are recorded with
`noticeWithheld: 'csae_law_enforcement'`. No notification, no email, no appeal.

Sources that now create decisions: `takeModerationAction` (all actions), `executeBulkModeration`,
`suspendUserAccount`, `banUserAccount`, legacy `reviewReport`, report auto-actions (restriction and minor-safety
warning, `automatedDecision: true`), NCII safety-case sanctions, the Vision upload hold, repeat-offender
escalations, the abusive-reporter warning and reporting suspension, and reporter "no action" outcomes.

## Admin panel contract

### Appeals in the existing moderation queue (no panel change needed)

Appeal items are `moderation_queue` docs with `itemType: 'appeal'`, `status: 'pending'`, id `appeal__<decisionId>`
(legacy: `appeal__legacy_<appealId>`). `category` is `appeal`, or `reporterAppeal` for a reporter's appeal.
`metadata.originalDecidedBy` is the moderator who may **not** resolve it.

`takeModerationAction({ queueId, action, reasonCode, explanation, parameters })` on an appeal item:

| action | outcome |
|---|---|
| `approve` | **overturned**: the decision is reversed |
| `approve` + `parameters.outcome: 'partially_overturned'` + `parameters.replacementAction: 'issueWarning' \| 'suspendUser'` (+ `parameters.durationDays` 1-365 for a suspension) | reversed, then the milder measure is applied |
| `dismiss` | **upheld** |
| anything else | `failed-precondition` |

The user is told the `explanation` as the reasons for the outcome. It is required (5-2000 characters).

`getModerationReviewItem({ queueId })` on an appeal item also returns `appealContext`:
`{ appealId, role, channel ('app'|'web'), appealReason, originalDecision {action, reasonCode, explanation, decidedBy, contentRef, automated, effects, ...}, excludedReviewers[], canResolve, outcomes[] }`.
On a report re-opened by a reporter's appeal it returns `excludedReviewers[]`.

### New callable `resolveModerationAppeal` (roles superAdmin | moderator)

```
resolveModerationAppeal({
  appealId?: string,          // or
  queueId?: string,           // the appeal queue item
  outcome: 'upheld' | 'overturned' | 'partially_overturned',
  explanation: string,        // 5-2000 chars, shown to the user
  replacementAction?: 'issueWarning' | 'suspendUser',   // partially_overturned only
  durationDays?: number       // 1-365, replacement suspension only
}) -> { appealId, decisionId, outcome, reversal: {reversed[], skipped[], errors[]} | null,
        reopenedQueueId | null, replacementDecisionId | null }
```

Errors: `permission-denied` if the caller took the original decision (Terms 18.4 b) or is the appellant;
`failed-precondition` if the appeal is already resolved; `invalid-argument` for a bad outcome or explanation.
`reversal.errors` lists anything that could not be undone automatically, for example a file already deleted.
Those parts are fixed by hand.

What an overturn reverses (`moderationEffects.ts`):

| Measure | Reversal |
|---|---|
| Removed message | Original text restored from `moderation_content_backups`, kept until the appeal window ends plus 30 days (TTL on `expireAt`) |
| Cancelled event, hidden experience | Previous status restored |
| Vision hold | File copied back from `quarantine/` to its original path |
| NCII safety case | Held items restored. Files already deleted by a confirmed removal cannot come back |
| Suspension, ban | Lifted, and Firebase Auth is re-enabled after a ban. Only when the sanction is still the one this decision applied (`suspensionDecisionId` / `banDecisionId`) |
| Warning, strike | Marked `revoked` |
| Shadow ban, verification requirement, report-volume restriction, reporting suspension | Lifted |

A **reporter's** appeal can only be upheld or overturned. On overturn, the original report goes back to `pending`
with `priority: 'high'` and `excludedReviewers` set to the first decider. That moderator gets `permission-denied`
from `takeModerationAction` on it.

### Other new queue item types

- `quarantinedImage`: the Vision hold. Id `image__<path with ~>__<generation>`, `status: 'pending'`.
  `approve` restores the upload to its original path and tells the user. `removeContent` confirms the hold.
- `reporterAbuse`: a reporter who keeps sending clearly unfounded reports after a warning. Use
  `suspendReporting` (`parameters.durationDays`, default 30, max 180) or `dismiss`.

Statement-of-reasons codes accepted by the server also include `repeat_violations` and `unfounded_reports`.
The panel's own list does not have them yet. For `suspendReporting` the server records `unfounded_reports`
whatever code the panel sends.

## Repeat offenders (Terms 18.6)

After a moderator warning or content removal: if the user has 3 or more active violations (`user_strikes`, last 12
months) and at least one **earlier** warning, the account is suspended for 7 days (30 days for a second escalation
in the window). This is its own decision with reason `repeat_violations`, and it can be appealed.

## Abusive reporters (Terms 18.6, DSA art. 23)

When a report-pipeline item closes as no violation, the reporter's last 30 days are counted. If at least 10 reports
were dismissed and at least 80% of the decided ones were dismissed:

1. The reporter gets an automatic **warning** (`reporterWarning`, with a statement of reasons and appeal).
2. If 5 or more further dismissed reports were filed after a warning that is less than 180 days old, a
   `reporterAbuse` item goes to the queue. A moderator decides case by case.

While reporting is suspended, the reporter's reports are stored with `status: 'reporter_suspended'` and
`priority: 'low'`. They are not in the pending queue and run no auto-actions. Child-safety (P0) reports are
always processed.

## Web appeal page

`GET/POST https://us-central1-<project>.cloudfunctions.net/moderationAppeal?d=<decisionId>&s=<sig>&hl=<locale>`.
The signature is an HMAC of the decision id and user id, with a key derived from the ticket signing key, so
nothing new needs configuring. The page is server-rendered, has no JavaScript, only accepts same-origin POSTs, and
files the appeal with `channel: 'web'`.

## Deploy (by name)

`resolveModerationAppeal`, `moderationAppeal`, plus every changed function: `takeModerationAction`,
`executeBulkModeration`, `getModerationReviewItem`, `suspendUserAccount`, `banUserAccount`, `reviewReport`,
`submitAppeal`, `onUserReportQueued`, `onMessageReportQueued`, `onContentReportQueued`,
`onModerationQueueResolved`, `moderateUploadedImage`, `screenCommunityMessage`, `screenGroupMessage`,
`screenEventMessage`, `safetyAdmin`, `nciiTakedownRequest`, `submitSafetyRequest`, `safetySlaSweep`,
`adminDecideCopyrightNotice`, `processCopyrightNotices` (the copyright repeat-infringer notice now also sends the
email). Then deploy `firestore:rules` and `firestore:indexes`, **without `--force`**: two new composite indexes
and one TTL override.
