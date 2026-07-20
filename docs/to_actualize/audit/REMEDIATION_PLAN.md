# GreenGo — Audit Remediation Plan

**Branch:** `fix/audit-remediation` · **Scope:** all CRITICAL + HIGH + MEDIUM findings from `AUDIT_REPORT_2026-07-18.md`. LOW/cleanup tracked separately.

**Ground rules for this work:**
- Validate locally before each deploy (memory: CI auto-merges past red; use local `flutter analyze` + `functions tsc --noEmit` + rules emulator).
- **Deploy functions BY NAME** until H5 (drift) is resolved — a full `--only functions` deletes the 3 orphaned prod functions.
- Security-rules and payment changes ship in their own commits so they can be reviewed/rolled back independently.
- Each phase = its own commit(s); nothing squashed.

Legend — Risk: 🟩 low / 🟨 medium / 🟥 high (can lock users out / touch money). Verify: how we prove it works.

---

## PHASE 0 — Security emergency (rules) 🟥
Ships as 2 commits: `firestore.rules`, `storage.rules`. Test against the Firebase **rules emulator** with allow/deny unit cases before deploy.

**0.1 Storage lockdown (C1)** — `storage.rules`
- Replace `allow read,write: if true` with authenticated, owner-scoped, path-based rules + size/content-type limits. Map real upload paths first (grep `Reference`/`putData`/`putFile`, `ref(`), then: profile photos/voice `users/{uid}/**` → write if `request.auth.uid==uid`, read if signed-in (or public per product need); ID-verification images → owner-write, **admin-only read**; chat media → participants only.
- Verify: emulator tests (owner write ✓, other-user write ✗, anon read ✗); manual upload smoke on device.

**0.2 Admin → custom claims (C2, H(admin gates))** — `firestore.rules` + `functions/src/shared/utils.ts` + a one-off claim-set script
- `verifyAdminAuth` reads `context.auth.token.admin` (custom claim) instead of `users/{uid}.isAdmin`. Add a callable/script to set the claim for the current real admins (from the existing admin list) — run once.
- In `firestore.rules`: `isAdmin()`/`isProfileAdmin()` read `request.auth.token.admin`; field-lock so owner-update can't change `isAdmin`/`role`/`isBanned`/`isBusinessVerified` (`request.resource.data.X == resource.data.X`).
- Verify: emulator (self-set isAdmin denied); confirm real admins still pass after claim migration BEFORE removing the Firestore-flag fallback.
- Risk 🟥: sequencing — set claims first, deploy functions to read claims, THEN tighten rules, so admins are never locked out.

**0.3 Coins server-only (C3)** — `firestore.rules` — 🟡 PARTIAL
- ✅ DONE (commit 133c8a8): removed the blatant client-side minting in the legacy `ShopScreen` (`_processCoinPurchase`/`_processVideoCoinPurchase` used `FieldValue.increment` on `coinBalances`/`videoCoinBalances` with **no payment/verification** — two taps = free coins). `limit_reached_dialog` now opens the verified `CoinShopScreen` (server `verifyPurchase`); the legacy screen routes there instead of minting. Removed unused `_createInvoice`.
- ⏳ REMAINING (the rule lockdown — needs the Phase-1.4 refactor FIRST, or it breaks the coin economy): `coinBalances`/`videoCoinBalances`/`coinTransactions` still allow `isOwner(userId)` writes, so a custom Firestore client can mint directly. The client datasource (`coin_remote_datasource.dart`) also does client-side **spend** (decrement), **gift** (sender−/receiver+), **reward/allowance** credits, and **video-coin** writes via transactions — so `allow write: if false` would break all of those until each moves to a callable.
  - Sequenced plan: (a) build callables for the credit paths — reuse existing `claimReward`/`grantMonthlyAllowances`/`verifyGooglePlayCoinPurchase`, add a `giftCoins` callable for the receiver-side credit; (b) rewire the datasource to call them; (c) THEN tighten the rule. Interim option: allow client writes only when `request.resource.data.totalCoins <= resource.data.totalCoins` (spend-only) — blocks mints but breaks gift-receive until (a).
- Verify: emulator (client write denied); coin spend/earn/gift still works via functions on device.

**0.4 Messages/matches participant-gating (C4)** — `firestore.rules`
- `conversations` + nested `messages`: read/write only if `request.auth.uid in [userId1,userId2]` (or `participants`); create requires `senderId==auth.uid`; edit/delete own only. Mirror the correct `groups/{gid}/messages` rule. Same for `matches`/`likes`.
- Verify: emulator (non-participant read/write denied); real 1:1 + group chat still send/read on device.

**0.5 users PII + catch-all + notifications create (H1,H2,MED)** — `firestore.rules`
- `users` read → owner/admin only. Catch-all `{document=**}` read → `if false` (add explicit rules for any legit collection surfaced, incl. audit logs → admin-only). `notifications` create → `if false` (server-only) or a validated cross-user allowlist.
- Verify: emulator; confirm the app doesn't rely on reading other `users` docs (it should use `profiles`).

**0.6 Remove/guard token HTTP endpoints (H3)** — `functions/src/admin/mockData.ts`, `communities/backfillCreatorMembers.ts`
- Delete `seedMockData`/`removeMockData`/`diag*` and `backfillCreatorMembers` from prod exports, or gate on Auth admin claim (no static token). Deploy the removals BY NAME.

---

## PHASE 1 — Payments 🟥 (before any live payment traffic)
**1.1 Delete coin stub (C5)** — remove `functions/src/coins/coinManager.ts` (confirmed not exported). Verify grep: no imports.
**1.2 Stripe fail-closed + atomic (C6)** — `functions/src/payments/stripeCheckout.ts`
- If `STRIPE_WEBHOOK_SECRET` empty → reject 500 (no unsigned processing). Move idempotency claim + coin credit into one `runTransaction` keyed at `stripe_orders/{session.id}` (create-if-absent; increment only on first create).
- Verify: Stripe CLI test event with/without signature; replay the same event twice → coins credited once.
**1.3 Purchase verification fail-closed (H4)** — `functions/src/shared/purchase_verification.ts`
- On `accessNotConfigured`/unreachable store API → `verified:false` (+ log/alert), never grant.
- Verify: simulate the 403 path → entitlement denied.
**1.4 Coin mutations server-side (C3 follow-through)** — ensure spend/earn are callables with server validation (pairs with 0.3).

---

## PHASE 2 — Deploy integrity 🟨
**2.1 Reconcile orphaned functions (H5)** — `functions/src/index.ts`, `gamification/index.ts`
- Re-export the still-needed ones from root: `export { refreshMyStats, onMessageCreatedVocabulary } from './gamification';`. Rebuild `getDisplayPrices` in source if the client still calls it (grep client), else remove the client call.
- Verify: `firebase functions:list` vs source exports match; then a full `--only functions` is safe. Until verified, keep deploying by name.

---

## PHASE 3 — Reliability bugs 🟨
**3.1 1:1 mute (H8)** — write `participants:[userId1,userId2]` in `conversation_model.dart` 1:1 `toFirestore()`; make `onNewMessagePush` the sole 1:1 message-push path (stop the notification-doc path from double-pushing messages) OR have `onNotificationCreatedPush` honor `mutedBy`/`isMuted`. Also fixes the block-check gap. Verify: mute a chat → 0 pushes.
**3.2 Duplicate-send (H9)** — `chat_remote_datasource.dart`: wrap everything after `messageRef.set(...)` in its own try/catch that logs but doesn't rethrow; return `message`. Verify: kill network after set → no ChatError, no duplicate.
**3.3 Timestamp null-guards (MED)** — guard `as Timestamp` in `match_model.dart:43`, `swipe_action_model.dart:33`, gifts/dates/prefs models, and `sentAt` at `chat_remote_datasource.dart:1097,1730`. Verify: a doc missing the field → list renders, skips/defaults.
**3.4 Per-user unread map (MED)** — `unreadCounts.{recipientId}` increment; `getUnreadCount` sums only current user's entry. Verify: sender's badge stays 0 after sending.
**3.5 ChatBloc listener leak (MED)** — `restartable()` transformer for `ChatConversationLoaded` (or cancel prior subscription). Verify: N sends → 1 active listener.
**3.6 video_call_bloc emit-after-handler (LOW-but-crash)** — capture/emit via a proper event. Verify: analyzer warning gone; no runtime throw.

---

## PHASE 4 — Scale 🟨
**4.1 Analytics scale bombs (H6,H10)** — `analytics/userSegmentation.ts`, `churnPrediction.ts`: paginate `batchChurnPrediction` (or delete if dead), batch BigQuery MERGE, bound cohort retention to the 90d window, chunk `createUserCohort` at 450. Verify: dry-run on staging.
**4.2 Discovery read path (H7)** — make the precomputed candidate-pool the primary path; cap the profile-scan fallback far below 500; move scoring/filtering server-side. Verify: reads-per-refresh drop from ~500 to ~20–50.
**4.3 Attendee recount (MED)** — retire `_updateAttendeeCount`; `rsvpEvent`/`cancelRsvp` use transactional `FieldValue.increment` like `joinEventWithTier`. Verify: RSVP → 1 write, no full recount.
**4.4 Unbounded reads (MED)** — add `.limit()`/paging to `getUserEvents`, `getCommunityMembers`, `getUnreadCount`, delete-conversation scans; chunk `onProfileDeleted` at 450; `recursiveDelete` for `deleteEvent/Community`.
**4.5 cityAlerts member paging (MED, session code)** — page `communities/{id}/members` in `cityAlerts.ts:222` (or drop the exclude above a threshold).
**4.6 Notification-pref schema consolidation (MED, session-adjacent)** — make `sendPushToUser` delegate to `prefs.ts shouldNotify`; retire the flat-field/UTC path. Verify: one gate, tz-correct quiet hours.
**4.7 Parity atomic claim (MED)** — transactional `pushSent` claim in `pushParity.ts`. Verify: concurrent redelivery → 1 push.
**4.8 Image caching (MED)** — standardize feed/list images on `CachedNetworkImage` + `memCacheWidth`. Verify: no re-download on rebuild.

---

## PHASE 5 — App Check + counter griefing (MED, security)
**5.1 App Check** — enable + `enforceAppCheck:true` on sensitive callables; consider Firestore/Storage enforcement. Risk 🟨 (can break clients if misconfigured — stage first).
**5.2 Counter griefing (MED)** — move follower/coin/referral/event counter mutations server-side (transactions); deny direct client increments in rules.

---

## Sequencing & deploy summary
1. Phase 0 → deploy `firestore.rules` + `storage.rules` (+ admin claim migration + by-name function removals). **Highest urgency.**
2. Phase 1 → deploy payment functions by name.
3. Phase 2 → reconcile, then full deploy becomes safe.
4. Phases 3–5 → client changes → new APK/AAB + iOS build; function changes by name.

**Testing per phase:** `flutter analyze` (0 new errors), `functions tsc --noEmit` clean, rules emulator allow/deny cases for every rule change, on-device smoke of the touched flow. Nothing deployed to prod without the local gate.

## Not in this plan (LOW/cleanup — separate branch later)
Delete ~74 dead dating files + orphan flags; shared date/distance/pagination utils; split god files/blocs; i18n sweep (246 Text + 631 SnackBars); add bloc tests; rotate committed secrets + scrub history.
