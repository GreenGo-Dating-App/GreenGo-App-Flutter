# P1-9 deploy plan: app repo becomes the single source of truth for non-Stripe functions

Branch `security/p1-recon` (app) and `security/p1-recon-web` (web). Analysis date 2026-10-08.
Nothing here has been deployed. All production access during the analysis was read-only
(`gcloud storage cat` of the deployed source zips).

## 1. What the analysis found

Every function in `C:\dev\p1-excluded.txt` (except the experience bookings, which belong to
another session), plus `claimReward`, `sendScheduledMessages` and `computeDailyUserStats`,
was downloaded from production. The function's module was then compared with every commit of
both repos (`git log --all`), not only with the two branch heads.

| Result | Modules |
|---|---|
| Live module **byte-identical to an older app-repo commit** (the web repo was just carrying a stale copy) | adminDashboard, roleManagement, userManagement, conversationBackup, gamificationManager, languageLearningManager, disappearingMedia, imageCompression, cleanupStalePresence, identityVerification, adminCoupons (2 versions live), country_aggregate, external_events/{build_index, geohash, ingest x2}, group_chat/membership, notifications/pushNotifications, social/follows, user_experiences/safetyCallables, messaging/scheduledMessages, gamification/index (computeDailyUserStats) |
| Live = an older app commit **plus** a change the app later committed in another form | candidatePoolPrecompute (app later also accepts `verificationStatus == 'verified'`), brevoEmailService (app later added the `coupon_redeemed` template), pushNotificationTriggers (live = 7654acb + `PUSH_MEMORY`, which app HEAD already has), onPresenceUpdate (live used an `'Unknown'` city sentinel filtered before writing; app HEAD returns `''`, same effect) |
| Live = web repo, **behaviour missing from the app** | only `claimReward` (in the web repo's `coins/coinManager.ts`) |
| Live = web repo, app identical except log redaction | `checkExpiringMemberships` (`subscription/index.ts`) |

So no module except `claimReward` had live web-only behaviour to port. Everywhere else the
app repo is strictly newer. Its extra commits are intentional (security Phase 0/1, push
branding, 512MiB memory, business exclusion in groups, follow-counter refactor, and so on)
and they are kept.

`claimReward` was rewritten rather than ported line by line (`functions/src/coins/claimReward.ts`):
- **Ported from live:** input `{rewardId}`, response `{success, coinsAdded}`, the `first_message`
  reward (25 coins, web only), camelCase `coinBalances`/`coinTransactions`, and the legacy
  `claimedRewards` record.
- **Kept from the app:** the `{rewardType}` input and the `coinsEarned`, `newBalance` and
  `rewardType` response fields.
- **Fixed:** It is now 1st-gen at 512MB, so it replaces the live gen1 function in place. It no
  longer writes the phantom `coin_balances`. Each reward has an eligibility check:
  - `complete_profile`: requires name, date of birth, gender, at least one photo, at least one
    interest, and a non-empty bio.
  - `first_match`: requires a `matches` doc with the caller as `userId1` or `userId2`.
  - `first_message`: requires a message the caller sent.
  - `photo_verification`: requires a `verification_badges` doc or `isAgeVerified`.
  - `daily_login`: once per UTC day.
  - streaks: refused, because there is no server-owned streak record.
  - `refer_friend`: refused, because `redeemReferral` already pays referrals.

  Dedup is transactional through `reward_claims/{uid}_{reward}_{period}`.
- **Callers:** none today. Both Flutter builds credit rewards client-side and never call this
  callable, so the risk to the app is nil.

**Provenance tooling bug (affects the Wave 1 record).** `C:\dev\gg-provenance.py` picked a
function's module by "first file containing `export const <name>`". That was wrong for 27
functions, which have duplicate definitions in dead modules: `trackNotificationOpened`,
`getNotificationAnalytics`, `blockUser`, `searchUsers`, `transcribeAudio`, and others. Those 27
were re-checked against the module that `src/index.ts` really exports (resolved with the
TypeScript compiler, `C:\dev\recon-scripts\exports.js`). 25 of them now equal app HEAD
(Wave 1 deployed them). `trackNotificationOpened` and `getNotificationAnalytics` were live
from app commit 604d2a5 (the web had nothing extra) and are in this plan.

## 2. Pre-deploy re-check (mandatory)

1. Merge `security/p1-recon` and build (`cd functions && npx tsc -p .`).
2. **Immediately** before deploying, from the repo root (read-only):
   `python -I tools/security/p1_9_live_recheck.py`
   (or `--names a,b,c` for one wave). For each function it downloads the live zip and compares
   it with `tools/security/p1_9_live_baseline.json`:
   - `OK`: proceed.
   - `WARN`: the function was redeployed but its module is unchanged. Proceed.
   - `ABORT`: the live module changed after this analysis. **Remove that function from the
     deploy**, then diff the new live module against this repo before deploying it later.
3. Deploy **by name only** (`firebase deploy --only functions:a,functions:b,...`). Never run a
   bare `--only functions` from either repo.
4. Deploy indexes before or with Wave M: `firebase deploy --only firestore:indexes`. The two
   new `messages` indexes must be built before `sendScheduledMessages` stops failing. If the CLI
   asks to delete indexes that are not in the file, answer **No**.
5. After each wave, check the logs (`gcloud functions logs read <fn>`) for OOMs and errors for
   about 15 minutes.

## 3. Wave L: low risk (live behaviour unchanged; only memory, `monitored()` wrapper, central admin-auth refactor or log redaction)

| Function | Live provenance | Change vs live |
|---|---|---|
| getUserActivityMetrics, getUserGrowthChart, getRevenueMetrics, getEngagementMetrics, getGeographicHeatmap, getSystemHealthMetrics, createSystemAlert, resolveSystemAlert, getAdminAuditLog | WEB (= app c5f7d8d) | `requireAdmin` (P1-6) replaces the `admins` collection + boolean claims; 256 -> 512MB (set in this branch); audit-log name lookup reads `admin_users` |
| createAdminUser, updateAdminRole, updateAdminPermissions, deactivateAdminUser, recordAdminLogin | WEB (= c5f7d8d) | 512MB, monitored |
| adminBulkDeleteUsers | WEB (= c5f7d8d) | `requireAdmin` refactor, monitored |
| backupConversation, restoreConversation, listBackups, deleteBackup, autoBackupConversations | WEB (= c5f7d8d) | 256 -> 512MB, monitored |
| cleanupDisappearingMedia, markMediaAsDisappearing | WEB (= c5f7d8d) | 256 -> 512MB, monitored |
| compressImage, compressUploadedImage | WEB (= c5f7d8d) | 256 -> 512MB (compressImage set in this branch), monitored |
| cleanupStalePresence | WEB (= c5f7d8d) | 256 -> 512MiB, monitored |
| startPhotoVerification, verifyPhotoSelfie, verifyIDDocument, calculateTrustScore | WEB (= c5f7d8d) | 256 -> 512MB, monitored |
| createLesson, deleteLesson, getAdminLessons, getLearningAnalytics, getLessonStats, getTeacherAnalytics, getUserProgressReport, publishLesson, purchaseLesson, reviewTeacherApplication, seedLessons, submitTeacherApplication, updateLesson, updateLessonProgress | WEB (= c5f7d8d) | admin check `profiles.isAdmin` -> `isAdminCaller` (P1-6); 256 -> 512MB (set in this branch) |
| onAchievementUnlocked, onPhotoModerationUpdated, onPurchaseCreated, onSubscriptionUpdated, onUserCreatedSendWelcome, sendBrevoReEngagement, sendBrevoStreakReminder, sendBrevoWeeklyDigest | WEB (= c5f7d8d + 16 lines) | email address redacted in logs; 512MiB (sendBrevoStreakReminder 256 -> 512 set in this branch); new `coupon_redeemed` template (unused by these triggers) |
| getCandidatePoolStats | WEB | 256 -> 512MiB (set in this branch) |
| onEventWriteUpdateCountryStats | OTHER (= app aab62ae) | monitored, 256 -> 512MiB |
| trackNotificationOpened, getNotificationAnalytics | OTHER (= app 604d2a5; was mis-attributed) | 256 -> 512MB (set in this branch) |
| checkExpiringModes, onSupportMessagePush, onVerificationStatusChange | OTHER (= 7654acb + PUSH_MEMORY) | shared `sendPushToUser` gained optional actor fields; these three pass none, so the output is the same |
| onPresenceUpdate | OTHER (= c5f7d8d-era, 6 lines) | **256 -> 512MiB (OOM fix)**, monitored; city sentinel equivalent |
| checkExpiringMemberships | WEB | email redacted in one log line |
| computeDailyUserStats | WEB-only export (module identical in both repos) | none; now exported by the app (1GiB as before) |
| sendScheduledMessages | WEB (= c5f7d8d) | monitored, 256 -> 512MB; **needs the new index (step 4)** |

## 4. Wave M: medium risk (the app's newer behaviour reaches production for the first time)

| Function | Live provenance | What changes vs live |
|---|---|---|
| claimChallengeReward, claimLevelRewards, trackAchievementProgress, trackChallengeProgress, unlockAchievementReward, resetDailyChallenges, updateLeaderboardRankings | WEB (= c5f7d8d) | L-04: `userId` must equal the caller (the apps send their own uid), ids and amounts validated; weekly-leaderboard fields; 512MB (updateLeaderboardRankings set in this branch) |
| precomputeCandidatePools, triggerPoolRecompute | WEB | candidate eligibility also accepts `verificationStatus == 'verified'` (more profiles in pools) |
| getCouponRedemptions, listCoupons, upsertCoupon | OTHER (c5f7d8d / 4d4d956) | `upsertCoupon` becomes **superAdmin-only**; listCoupons page cap 200 -> 1000; codes redacted in logs |
| onGroupCreated, onGroupInfoChanged | OTHER (= 06b0039) | business accounts added to a group are stripped (65dcfbb) |
| backfillFollowCounts | OTHER (= 1ff535a) | follow-counter refactor (followCounters.ts), superAdmin-only |
| runBuildExternalIndexNow, runBackfillGeohashNow, runBackfillViatorCategoriesNow, runCleanupNoImageNow | OTHER | L-05 admin token by header (`?token=` still accepted); index gains website/wikidata/describedAt fields; `hasImage` flag |
| acceptHostAgreement, onExperienceReportCreated | OTHER (= 1e31e22) | acceptHostAgreement now requires an upcoming OPEN date (3cf679c). This is the experiences feature: **confirm with the experiences session before deploying** |

## 5. Wave P: ported / rewritten

| Function | Live provenance | Notes |
|---|---|---|
| claimReward | WEB gen1 (`coins/coinManager.ts`, old web commit) | v1 `runWith({memory:'512MB'})`, deployed in place (gen1 -> gen1). Response is a superset of the live one. No current client calls it. |

## 6. Not in this plan
- `experience_bookings/*` (15 functions): another session.
- Stripe family: `createStripeCheckoutSession`, `createStripePortalSession`, `getMembershipPrice`,
  `getDisplayPrices`, `stripeWebhook`, `reconcileStripeMemberships`, `runStripeReconcileNow`.
  These deploy **only** from the web repo, unchanged.
- Web-only names that are now commented out in the web repo and are **not** deployed:
  `onNewMatch`, `onNewMatchPush`, `onNewLikePush` (dating notifications the app removed on
  purpose). Do not create them.

## 7. Web repo after this change
`functions/src/index.ts` exports only the 7 Stripe functions. Every other name is commented out
as `deploys ONLY from GreenGo-App-Flutter (P1-9)` (176 names). This includes
`computeDailyUserStats` and also `onPresenceUpdate`, so `deploy-all.sh`/`.ps1` step 3 there
(`--only functions:onPresenceUpdate`) now fails instead of rolling the function back to 256MiB.
