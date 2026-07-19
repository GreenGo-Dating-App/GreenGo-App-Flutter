# GreenGo — Whole-App Audit (consolidated)

**Date:** 2026-07-18 · **Method:** 5 parallel read-only agents (security, backend/Cloud Functions, performance/scale, architecture/quality, correctness). `flutter analyze` = 0 errors (95 warn / 95 info). `functions tsc --noEmit` = clean.

**Read this first:** there are **exploitable-today** security and payment holes. Nothing was modified during the audit. Severity = business/user impact.

---

## 🔴 CRITICAL — fix before anything else (exploitable now)

| # | Finding | Where | Fix |
|---|---|---|---|
| C1 | **Cloud Storage is world-open & deployed** — `allow read, write: if true` → anyone (no auth) reads/overwrites/deletes every photo, voice note, **ID-verification image** | `storage.rules:13-16` | Authenticated, owner-scoped, path + size/type limited rules. **Emergency deploy.** |
| C2 | **Self-promote to full admin** — user can write `users/{uid}.isAdmin=true` / `profiles/{uid}.isAdmin=true`; admin gates trust it | `firestore.rules:42-47,76-82`; `functions/src/shared/utils.ts:92-103` | Move admin to **Auth custom claims**; field-lock `isAdmin`/`role`/`isBanned` in rules |
| C3 | **Mint unlimited coins** — `coinBalances`/`coinTransactions` client-writable, no integrity check | `firestore.rules:381-393,434-444` | Deny client writes; mutate only via Admin-SDK callables |
| C4 | **All 1:1 DMs readable/writable by any signed-in user** (no participant check) | `firestore.rules:110-123` (+ `matches` :89, `likes` :100) | Gate on `request.auth.uid in participants` (mirror the correct `groups/*/messages` rule) |
| C5 | **Coin purchase verification is a stub** — `const verified = true` + no `purchaseToken` dedup → replayable free coins | `functions/src/coins/coinManager.ts:46` | Validate receipt server-side + idempotent token record. **Note:** this file isn't exported — verify it's dead & delete it |
| C6 | **Stripe webhook trusts unsigned bodies** when `STRIPE_WEBHOOK_SECRET` unset → forge "purchase completed"; also non-atomic coin credit → double-credit on retry | `functions/src/payments/stripeCheckout.ts:196,212-301` | Fail closed if secret missing; do idempotency claim + credit in one `runTransaction` keyed on `session.id` |

## 🟠 HIGH

| # | Finding | Where | Fix |
|---|---|---|---|
| H1 | **PII leak** — `users` docs (email, **fcmToken**, tier) readable by every signed-in user | `firestore.rules:42` | Restrict read to owner/admin; keep discovery fields in `profiles` |
| H2 | **Catch-all** exposes admin **audit logs** + any unlisted collection to any user | `firestore.rules:1176-1179` | Read `if false`; explicit per-collection rules; audit logs → admin-only |
| H3 | **Public HTTP endpoints** (`seedMockData`,`removeMockData`,backfill) guarded by a **hardcoded committed token** → unauth data delete/spam | `functions/src/admin/mockData.ts:25`; `communities/backfillCreatorMembers.ts:22` | Remove from prod / gate on Auth admin; rotate tokens |
| H4 | **Purchase verification fails OPEN** when Play API misconfigured → free coins/tiers | `functions/src/shared/purchase_verification.ts:95,152` | Fail closed; alert on `apiUnavailable` |
| H5 | **Deploy-drift will delete live functions** — `getDisplayPrices` (prod-only), `refreshMyStats` + `onMessageCreatedVocabulary` (orphaned in `gamification/index.ts`, never re-exported from root) → a full `deploy --only functions` prunes all 3 (breaks pricing/stats, silently kills vocabulary trigger) | `functions/src/index.ts`, `gamification/index.ts:21,355` | Re-export from root (or retire client calls). **Deploy BY NAME until reconciled.** |
| H6 | **Scale bomb:** `batchChurnPrediction` unbounded full-`users` `.get()` in a daily job (OOM + millions of billed reads; loop is a no-op) | `functions/src/analytics/userSegmentation.ts:452` | Paginate or delete (looks like dead/mock work) |
| H7 | **Discovery reads 500–1,400 profiles per refresh**, scores client-side; candidate-pool path only a "try-first" fallback | `matching_remote_datasource.dart:131-202`; `discovery_remote_datasource.dart:233` | Make server-side candidate pool primary; return small scored ID sets |
| H8 | **1:1 chat mute is silently broken** — `onNewMessagePush` needs `participants` (never written for 1:1); effective push (`onNotificationCreatedPush`) ignores mute | `pushNotificationTriggers.ts:266`; `pushParity.ts:49`; `conversation_model.dart` toFirestore | Write `participants:[u1,u2]` for 1:1 OR honor `mutedBy` in the parity path |
| H9 | **False "failed to send" → duplicate messages** — `sendMessage` throws on post-write side-effects after the doc is written | `chat_remote_datasource.dart:433-581`; `chat_bloc.dart:207` | Isolate post-`set` side-effects in their own try/catch; return the message regardless |
| H10 | **BigQuery per-user DML in a loop** (churn) + **cohort retention rescans an ever-growing set** | `analytics/churnPrediction.ts:278`; `userSegmentation.ts:263` | Batch MERGE; only recompute cohorts inside their 90d window |
| H11 | **Leaky data layer** — 60 presentation files call Firestore directly (21 widgets write) → blocks testing + GCP migration | app-wide | Ban `FirebaseFirestore.instance` in `presentation/`; route through repo→usecase→bloc |

## 🟡 MEDIUM

- **`_updateAttendeeCount` recounts all attendees per RSVP** (10k reads/join) — `events_remote_datasource.dart:1148`; use the transactional increment already in `joinEventWithTier`.
- **Unbounded reads:** `getUserEvents` collectionGroup, `getCommunityMembers`, `getUnreadCount`, delete-conversation message scans, `onProfileDeleted` (batch-per-doc), `deleteEvent/Community` per-doc deletes.
- **`cityAlerts.ts:222` loads all community members unbounded** to build the exclude set *(session code — paginate or drop the exclude)*. Flagged by 2 agents.
- **Two divergent notification-pref schemas** — `prefs.ts shouldNotify` (category, tz quiet-hours) vs legacy `sendPushToUser` (flat fields, UTC) gate the same push inconsistently *(session-adjacent)*.
- **Parity trigger lacks atomic claim** → rare duplicate push (`pushParity.ts`); sibling fan-outs do it right.
- **Unguarded `as Timestamp` casts** crash whole lists on one legacy/partial doc — `match_model.dart:43`, `swipe_action_model.dart:33`, gifts/dates/prefs models; also `sentAt` in delete/jump paths.
- **Shared-int `unreadCount`** inflates the **sender's** unread badge — use a per-user map (`unreadCounts`).
- **`ChatBloc` re-subscribes the message stream per action** → leaked Firestore listeners; use a `restartable()` transformer.
- **Feed images use raw `Image.network`** (no downsampling/caching) despite `cached_network_image` — Storage egress + jank.
- **God files/blocs** — 7 screens >2,700 lines (`events` 4,402, `explore` 4,158, `chat` 3,728…); `communities_bloc` 762 lines / 5 concerns.
- **Duplication** — ~30 date formatters (no shared util), 7 Haversine copies (ignore `GeoQuery`), unused `paginatedQuery` while ~40 sites hand-roll pagination, 6 near-duplicate location pickers, 5 reverse-geocode copies.
- **Anyone can create `notifications` in anyone's feed** (phishing) — `firestore.rules:175`; **no App Check** anywhere.
- **Cross-user counter griefing** — followers/coins/referrals/event counters client-incrementable.

## 🔵 LOW / cleanup

- **~74 files of dead abandoned-dating code** (~9% of repo): `matching`, `blind_date`, `vibe_tags`, `second_chance`, `conversation_expiry`, `date_scheduler`, `share_my_date` + `matches_screen.dart`, `main_preview.dart`, `seed_data.dart.bak`, 5 orphan flavor flags (zero consumers). Removable; repositioning liability. *(Keep `swipe_*`/`dating_etiquette*` — LIVE.)*
- **Hardcoded secrets committed** — OAuth `client_secret` in `scripts/*.js`, admin password in `seed_data.dart(.bak)`. Rotate + scrub.
- **i18n gaps** — 246 hardcoded `Text`, 631 SnackBars (many raw literals); worst: `chat_screen.dart`, `forgot_password_screen.dart`.
- **Tests** — 33/41 features have none; only ~4/31 blocs tested. Refactors are unguarded.
- **`bulkApproveUsers`** never actually sends its approval push (dead branch).
- **`video_call_bloc.dart:589`** calls `emit` outside a handler (can throw at runtime).
- **Monolithic** `main.dart` (1,490 lines, Firestore in root widget) + 958-line DI file.
- Domain entities import `cloud_firestore`/`material` (Timestamp/TimeOfDay leak) — keep domain framework-free.

---

## Recommended fix plan (by priority)

**Phase 0 — Security emergency (hours):** C1 Storage rules, C2 admin custom-claims + field-locks, C3 coin rules server-only, C4 message participant rules, H1 users PII, H2 catch-all, H3 remove token endpoints. Redeploy `firestore.rules` + `storage.rules`.

**Phase 1 — Payments (before any real payment traffic):** C5 delete coin stub, C6 Stripe fail-closed + atomic credit, H4 purchase fail-closed, C3 coin mutations server-side.

**Phase 2 — Deploy integrity:** H5 reconcile orphaned/prod-only functions so a full deploy is safe again.

**Phase 3 — Reliability bugs:** H8 mute, H9 duplicate-send, Timestamp null-guards, unread-count map, ChatBloc listener leak.

**Phase 4 — Scale:** H6/H7/H10 analytics + discovery read path, attendee recount, unbounded reads, image caching, `cityAlerts` member paging.

**Phase 5 — Quality:** delete dead dating code, shared date/distance/pagination utils, split god files/blocs, i18n sweep, add bloc tests, App Check.

---
*5 agents, read-only. All citations are file:line from files the agents actually read. `flutter analyze` 0 errors; `functions tsc` clean.*
