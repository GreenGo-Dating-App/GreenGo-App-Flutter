# G2 — De-hotspot

**Gate:** G2 · **Registered trigger:** ~1M (start work at ~700K) · **Peak concurrent:** ~25K
**Theme:** remove single-document write bottlenecks — **but only the ones measurement proves hot.**
**Owner:** Eng lead · **Date:** 2026-07-13 · **Version:** v1 · **Status:** Not started (pre-trigger)
**Stack:** Flutter (Clean Arch + BLoC) · Firestore + Cloud Functions + FCM · migration target AlloyDB + GKE Autopilot + Pub/Sub

> This is the detailed expansion of gate **G2** from [`README.md`](./README.md). It is the "how" behind
> README §1 (G2 row), Phase 1 (Hotspot elimination) and Phase 2 (ephemeral-off-Firestore). Read the
> README first for the gate model and the SLO table — this document does not restate them, it operationalizes G2.

---

## 1. Gate summary

At ~1M registered / ~25K peak concurrent, a **single Firestore document caps at roughly 1 sustained
write/sec** (soft; contention and latency climb well before the hard ceiling). That is the wall where
GreenGo actually starts to feel slow — not the per-database write ceiling (that is G3). G2 is the gate
that finds the handful of documents that have become hot and de-hotspots *only those*, using four
mechanisms:

1. **Shard the counters measurement flags hot** — distributed counters (`N` shard docs, random-shard write, summed+cached read).
2. **Move presence/typing off Firestore** to Realtime Database with `onDisconnect`.
3. **Build a load-test harness** on a staging Firebase project that replays the real ops mix.
4. **Hot-document detection + alerting** so a new hotspot pages on-call instead of being discovered by users.

Plus two audits that gate the above: a **batched-fan-out coverage audit** and a **document-ID distribution audit**.

**The one rule that governs this whole gate:** *sharding a counter that takes 5 writes/sec is pure
overhead.* Do not shard, do not stand up an RTDB fleet, do not touch a working counter until the G1
dashboards or the G2 hot-doc alert name that exact document as hot. Below the trigger, the un-sharded
counter is the **correct** implementation.

---

## 2. When to activate

**Start at ~700K registered (≈70% of trigger)** so the mechanisms are live before the wall arrives at ~1M.

**Activation is evidence-driven, not calendar-driven.** The trigger to shard a *specific* document is:

- The **G1 Cloud Monitoring dashboards** (built in Gate G1 — see [`G1_OBSERVE_THROTTLE.md`](./G1_OBSERVE_THROTTLE.md))
  show sustained write pressure to a collection, **and**
- The **G2 hot-doc alert** (Task 5.4 below) names a specific `docPath` exceeding threshold, **or** the
  **load harness** (Task 5.3) reproduces a hot doc at 25K-concurrent-equivalent.

If neither fires for a candidate document, that document stays un-sharded. This gate ships a **ranked
hotspot backlog** (from the audit in §5.1), then shards top-down until the harness is clean — it does
**not** blanket-shard every counter in §5.1.

**DONE when:** exit criteria in §10 are met (load harness green, presence on RTDB, alert fires on synthetic hotspot).

---

## 3. Objectives & SLOs

Inherits the README §0 SLO table. The G2-specific commitments:

| Metric | Target | Alert threshold |
|---|---|---|
| Writes/sec to **any single document** | **< 5 sustained** | **> 20 (hotspot page)** |
| Message-send latency p95 / p99 | < 300 ms / < 800 ms | p99 > 1.2 s |
| Presence accuracy (staleness of `online` flip) | within **60 s** | > 120 s |
| Typing signal write rate per user | **≤ 1 write / 3 s** | — (moves off Firestore entirely) |
| Sharded-counter read staleness (cached sum) | ≤ 30 s | — |
| Load-harness reproducibility | ops mix within ±5% of target weights | — |

---

## 4. Prerequisites — G0 + G1 MUST be complete

**G2 cannot start blind. It depends on the observability built in earlier gates:**

- **G0 (hygiene, any scale):** listeners cancelled on dispose, `.limit()` on every query, PR checklist
  live. Without this the load harness measures noise.
- **G1 (~100K):** the **Cloud Monitoring dashboards** (reads/writes per second per collection, p50/p95/p99
  latency) and the **debounce work** on high-churn writes. **These dashboards are how you KNOW what is hot.**
  Sharding without them is guessing.

The repo already ships partial scaffolding G2 builds on:

- `functions/src/shared/monitoring.ts` — a `monitored(name, handler)` wrapper on every Cloud Function that
  records per-invocation stats to `function_monitors/{name}`. G2 extends this into the hot-doc sampler
  (§5.4). **Note:** `function_monitors/{name}` is itself a single doc per function (uses
  `FieldValue.increment` at lines 73–86) — for a busy monitored function (e.g. `onGroupMessageCreated`)
  it becomes a hotspot *when monitoring is enabled*. Sample, don't count-every-invocation, at scale.
- `functions/scripts/monitored-functions.json` and the `app_config/function_monitoring` doc — the
  selection mechanism the alerting reuses.

**Gate check before any G2 code merges:** G1 dashboards live with ≥7 days of data; a named hot document exists.

---

## 5. Tasks

Each task: **Objective · Steps (real files) · Acceptance · Effort · Risk.**

### 5.0 — Hotspot inventory & ranking (do first; gates everything else)

**Objective:** turn the raw grep below into a ranked backlog so §5.1 shards top-down, not blindly.

**Current-state inventory (from code audit 2026-07-13).** Every `FieldValue.increment` / aggregate write,
classified by contention shape:

| Counter / field | Site | Doc granularity | Hot? |
|---|---|---|---|
| `events/{id}.likeCount` | `functions/src/events/likes.ts:26` | **1 doc per event** | **HIGH — viral event = many writers → 1 doc.** Prime shard candidate. |
| `events/{id}.viewCount` | `lib/features/events/presentation/screens/event_detail_loader_screen.dart:42` | **1 doc per event** (client increment on open) | **HIGH — viral event.** Prime shard candidate. |
| `profiles/{id}.followerCount` | `lib/features/business/data/services/follow_service.dart:89,113` | 1 doc per followee | **MED-HIGH — celebrity/business mass-follow.** Shard candidate. |
| business `ratingSum` / `ratingCount` | `lib/features/business/data/services/rating_service.dart:106-112` | 1 doc per business | **MED — popular business.** Shard candidate. |
| `communities/{id}.memberCount` | `lib/features/communities/data/datasources/communities_remote_datasource.dart:231,255` | 1 doc per community | **MED — popular community join spike.** Shard candidate. |
| cultural-exchange tip `likes` | `lib/features/cultural_exchange/data/datasources/cultural_exchange_remote_datasource.dart:164,173` | 1 doc per tip (in txn) | **MED — viral tip.** Shard candidate. |
| coupon `redemptionsCount` | `functions/src/coupons/applySignupGrants.ts:327`, `functions/src/coupons/redeemCoupon.ts:238` | **1 doc per coupon** | **MED-HIGH — a launch/viral promo code = one doc, all redeemers.** Shard candidate. |
| `conversations/{id}` (`unreadCount` + `lastMessage` + `lastMessageAt` + `isTyping`) | `lib/features/chat/data/datasources/chat_remote_datasource.dart:492-503,724-727`; also `:1534`, `coin_remote_datasource.dart:790`, `functions/src/messaging/scheduledMessages.ts:61` | 1 doc per 1:1 convo (2 writers) | **MED — only 2 participants, but the doc absorbs message-send + typing + read-clear. Fix typing first (§5.2), not sharding.** |
| `groups/{id}.memberCount` | `lib/features/chat/data/datasources/group_chat_remote_datasource.dart:425,463` | 1 doc per group (256 cap) | **LOW — bounded, join/leave only.** Leave un-sharded. |
| `groups/{id}.lastMessage/lastMessageAt` | `functions/src/group_chat/fanout.ts:96-108` | 1 doc per group, server-side | **LOW-MED — one write per message, server-serialized. Watch under load; debounce if hot.** |
| `user_group_inbox/{uid}/threads/{gid}.unreadCount` | `functions/src/group_chat/fanout.ts:133` | per-user per-thread | **LOW — naturally distributed.** Leave. |
| `coin_balances/{uid}.totalCoins` (+`coinBalances/{uid}` client path) | `functions/src/coins/index.ts:119,224,311,401,566`; `lib/features/coins/presentation/screens/shop_screen.dart:233,403,411` | per-user | **LOW — per-user.** (Flag the `coin_balances` vs `coinBalances` collection-name split as a data-hygiene bug, separate from G2.) |
| gamification `coins.balance`, XP, `stats.*` | `functions/src/gamification/handlers.ts:134,363,426,619`; `functions/src/language_learning/languageLearningManager.ts` (many) | per-user; `stats.*` per-teacher/course | **LOW per-user; MED for a hit course's `stats.*`.** Revisit only if a course goes viral. |
| `function_monitors/{name}` | `functions/src/shared/monitoring.ts:73-86` | 1 doc per function | **MED when enabled for a busy fn.** Switch to sampled writes (§5.4). |
| `users/{id}.reportCount`, video `stats.*`, referral counts | `safety_actions_service.dart:58`, `functions/src/video_calling/videoCalling.ts:645`, `referral_service.dart:217` | per-user / low-rate | **LOW.** Leave. |

**Steps:** re-run the grep at trigger time (`FieldValue.increment` across `lib/` and `functions/src/`),
join it to the G1 per-collection write-rate dashboard, and rank by *measured* writes/sec × concentration.

**Acceptance:** a ranked hotspot list committed to the repo; each row tagged `shard-now` / `watch` / `leave`.
**Effort:** ~1 dev-day. **Risk:** Low.

---

### 5.1 — Shard the measured-hot counters (distributed counters)

**Objective:** convert only the `shard-now` counters from §5.0 to distributed counters. There is **no
existing sharded-counter code** in the repo today (the only `shard` references are the unrelated
`external_events` compact index in `functions/src/index.ts:87` and `build_index.ts`) — so this task also
establishes the **canonical helper** every future counter reuses.

**Shard-count sizing rule.** Pick `N = ceil(expected_peak_writes_per_sec / 1)` for that document, clamped
to `[3, 50]`; start at `N = 10` and tune from the harness. A doc taking a measured 8 writes/s needs
`N ≈ 8–10`; do not over-shard (read cost = 1 query over `N` docs). Store `N` on the parent so reads know
the fan-in without a config lookup.

**Steps (per hot counter):**
1. Add the canonical helper — new file `lib/core/utils/sharded_counter.dart` (client) and
   `functions/src/shared/shardedCounter.ts` (server). Pattern in §6.1.
2. **Dual-write migration (safe, reversible):**
   - Deploy the helper writing to **both** the legacy field (e.g. `events/{id}.likeCount`) **and** the new
     `events/{id}/shards/{0..N-1}.count`. Reads still use the legacy field. No behavior change.
   - Backfill: one-off script seeds `shards/0.count = <current legacy value>`, the rest at 0.
3. **Reconcile:** scheduled Cloud Function compares `sum(shards)` against the legacy field nightly; log drift.
   Zero drift for 48 h is the go signal.
4. **Cutover reads** behind a Remote Config flag (`sharded_counter_reads_enabled`, per-counter map): read
   switches to the cached shard-sum (§6.1 read path). Legacy field kept as a fallback for one release.
5. **Stop legacy write** once reads are 100% on shards and stable for a release; drop the legacy field next release.

**Concrete first targets (from §5.0 ranking):** `events/{id}.likeCount` (`functions/src/events/likes.ts`
`bump()` → shard write) and `events/{id}.viewCount` (move the client increment at
`event_detail_loader_screen.dart:42` into the helper, or better, off the client into a CF on an `event_views`
per-user-per-day dedupe doc so the client write path stays O(1)). Then `followerCount`, coupon
`redemptionsCount`, `communities.memberCount` — only if still hot after the first two ship.

**Acceptance:** load test shows **no single counter doc > 5 writes/s** at 25K-concurrent-equivalent; UI
counts match legacy within reconcile tolerance; cutover flag flips with zero drift.
**Effort:** ~4 dev-days (helper + first two counters; +0.5 day each additional). **Risk:** Med — count
correctness during dual-write; mitigated by reconcile-before-cutover and the flag.

---

### 5.2 — Move presence & typing off Firestore → RTDB `onDisconnect`

**Objective:** stop writing ephemeral online/typing state to Firestore docs.

**Current state:**
- **Presence** is written to the user's **own** `profiles/{userId}` doc (`isOnline`, `lastSeen`) by
  `lib/core/services/presence_service.dart` (`_setOnline`/`_setOffline`, lines 84–109). It is a *per-user*
  doc (not a shared hot doc), so it is not a contention hotspot — **but** every flip triggers
  `functions/src/presence/onPresenceUpdate.ts` (a full geocode + a second write to the same doc), and
  `functions/src/presence/cleanupStalePresence.ts` scans `profiles where isOnline == true` every 5 min.
  At 25K concurrent this is real, avoidable write + function volume on the *profile* documents that
  discovery also reads.
- **Typing** is written to the **shared** `conversations/{conversationId}` doc via
  `chat_remote_datasource.dart:718-731` (`isTyping`, `typingUserId`) — **unthrottled, on the same doc that
  absorbs every message-send `unreadCount` increment.** This is the worst ephemeral offender.
- **`firebase_database` (RTDB) is NOT a dependency** — confirmed absent from `pubspec.yaml` (only
  `cloud_firestore`, `firebase_*`). **This task must add it.**

**Steps:**
1. Add `firebase_database: ^11.0.0` to `pubspec.yaml` (aligns with the Firebase 3.x/iOS-SDK-11 generation
   already pinned there); provision the RTDB instance and set `databaseURL` in `firebase_options`.
2. New `lib/core/services/rtdb_presence_service.dart` implementing the §6.2 pattern: write `presence/{uid}`
   with `onDisconnect().set({online:false,lastSeen:ServerValue.timestamp})` then `set({online:true})`.
   Retain the 5-min inactivity heuristic from the existing service but the *state lives in RTDB*, not the
   profile doc.
3. New `lib/features/chat/.../rtdb_typing_service.dart`: typing writes to `typing/{conversationId}/{uid}`
   in RTDB with `onDisconnect().remove()`; **keep the ≤1-write/3s debounce** (README A.5) as a client guard
   even though RTDB is cheaper.
4. **Reconcile job:** a GKE/Cloud-Run (or, interim, scheduled CF) worker mirrors RTDB `online` truth to
   `profiles/{uid}.isOnline` **every 60 s** (batched) so discovery/network queries that filter on
   `isOnline` keep working without per-flip Firestore writes. Retire the per-flip write in
   `presence_service.dart` and repurpose `cleanupStalePresence.ts` to trust RTDB `lastSeen` instead of scanning.
5. Feature-flag the swap (`presence_backend = firestore|rtdb`) and canary (§7).

**Acceptance:** zero per-flip Firestore presence writes and zero typing writes to `conversations/*`;
presence still accurate within 60 s; typing indicator visually unchanged.
**Effort:** ~3 dev-days. **Risk:** Med — staleness / dual-source-of-truth; mitigated by 60 s reconcile +
`onDisconnect` + canary + flag rollback.

---

### 5.3 — Load-test harness (staging Firebase project)

**Objective:** reproduce the production ops mix at target concurrency and produce latency-vs-concurrency curves.

**Tool choice:** **k6** (Grafana k6) driving the Firestore/RTDB REST + callable endpoints from a Node
scenario, run against a **dedicated staging Firebase project** (never prod). k6 is chosen over a headless
Flutter driver because it scales to tens of thousands of virtual users cheaply and emits the latency
histograms we need; the Flutter driver is reserved for the client-jank work in G-render tasks.

**Ops mix to replay (README §0.7 weights):**

| Weight | Operation | Backend path exercised |
|---|---|---|
| **45%** | chat + presence | message write to `conversations/{id}/messages`, `unreadCount` increment, RTDB presence/typing |
| **25%** | discovery | paginated `profiles` query (geohash-bounded), `isOnline` filter |
| **12%** | events | `events` list query, `likeCount`/`viewCount` increment (the shard targets) |
| **8%** | coins | `coin_balances` read + a spend/gift write |
| **6%** | tags | `user_group_tags` read/write |
| **4%** | TTS | coin-debit + cached-TTS read path |

**Steps:** parameterize virtual-user count; ramp **1K → 5K → 15K → 25K concurrent** (25K = the G2 peak);
seed a representative staging dataset (hot events, a celebrity profile, a viral coupon — so hotspots
actually form); record p50/p95/p99 per op and **per-document write rate** for the §5.0 candidates.
Output = a latency-vs-concurrency curve per operation + a "hottest documents" table per run, committed as
the run artifact.

**Acceptance:** harness drives staging to 25K concurrent-equivalent and reproduces at least one known
hotspot on un-sharded code (proving it can *see* hotspots), then shows them gone post-shard.
**Effort:** ~4 dev-days. **Risk:** Med — staging fidelity; mitigated by seeding realistic skew, not uniform data.

---

### 5.4 — Hot-document detection + alerting

**Objective:** page on-call when any document exceeds the hotspot threshold, in staging load runs and in prod.

**Steps:**
1. **Native metric first:** Cloud Monitoring alert on Firestore `document/write_count` — but native metrics
   are per-collection, not per-doc. So add:
2. **Sampled hot-doc logger** in the fan-out / high-write Cloud Functions (extend the existing
   `monitored()` wrapper in `functions/src/shared/monitoring.ts`): with probability `p` (e.g. 0.05) log
   `{docPath, ts}` as structured logs. A **log-based metric** counts writes per `docPath` label; alert when
   a single `docPath` exceeds **> 20 writes/s** (README hotspot threshold). Keep it sampled so the logger
   is not itself a hotspot (see the `function_monitors` caveat in §4).
3. **Alert policy + routing:** Cloud Monitoring alert policy (§6.4) → notification channel → PagerDuty/
   Opsgenie on-call rotation. Two severities: **warn at > 10 writes/s** (Slack), **page at > 20 writes/s** (on-call).
4. Wire the same log-based metric into the load harness output so §5.3 runs assert on it automatically.

**Acceptance:** a synthetic test writing > 20 writes/s to one doc **pages on-call within 5 min**; the
sampled logger adds < 1% overhead to fan-out latency.
**Effort:** ~2 dev-days. **Risk:** Low-Med — sampling under-counts a brief spike; mitigated by the
harness catching sustained hotspots and native per-collection alerts catching gross regressions.

---

### 5.5 — Batched-fan-out coverage audit

**Objective:** confirm every group-message / broadcast delivery is one batched server-side fan-out, not N client writes.

**Current state (good):** `functions/src/group_chat/fanout.ts` (`onGroupMessageCreated`) already does the
canonical thing — client writes the message **once** to `groups/{groupId}/messages/{auto-id}`; the function
denormalizes `lastMessage`, fans out inbox summaries **batched at 450 writes/commit** to
`user_group_inbox/{uid}/threads/{groupId}`, bumps `unreadCount` per-recipient, and multicasts FCM in
500-token chunks. Group size is capped at 256 so per-message work is bounded.

**Steps:** audit that **all** group-adjacent features route through this pattern and none regress to
client-side fan-out — specifically the newer **group tags** (`user_group_tags`) and any **network
broadcast** feature. Verify `memberCount` on the group doc (`group_chat_remote_datasource.dart:425,463`)
is not read-modify-written by clients under contention. For the noted future "Culture Rooms" (unbounded
public groups), confirm the fanout.ts header's own plan holds: switch step 3 to **FCM topic publish (O(1))**
and step 2 to a pull-based inbox rather than push fan-out.

**Acceptance:** one logical message = one batched fan-out for every group feature; no feature writes O(members) docs from the client.
**Effort:** ~1 dev-day. **Risk:** Low.

---

### 5.6 — Document-ID distribution audit

**Objective:** ensure no high-write collection uses monotonic (timestamp/sequential) document IDs that
hotspot a single Firestore tablet.

**Current state (good):** high-write collections already use **auto-IDs** —
`conversations/{id}/messages/.doc()` (`chat_remote_datasource.dart:465`),
`groups/{id}/messages/.doc()` (`group_chat_remote_datasource.dart:329`), `conversations/.doc()` (`:359`),
`groups/.doc()` (`:175`), `coin_transactions/.doc()` (`coins/index.ts:127`). No sequential/timestamp-prefixed
document IDs were found on any write-hot collection. (Note: coin *batch* IDs use `batch_${Date.now()}` —
that is a **field value**, not a doc ID, so it does not hotspot a tablet.)

**Steps:** at trigger time re-grep for `.doc('` with interpolated timestamps/counters on any collection the
G1 dashboard shows as write-hot; if any appear, switch to auto-ID or a hashed prefix. Confirm no new
feature introduced a monotonic key.

**Acceptance:** no monotonic ID pattern on any high-write collection (verified by grep + dashboard).
**Effort:** ~0.5 dev-day. **Risk:** Low.

---

## 6. Reference code patterns

### 6.1 Sharded counter — Dart write + cached read

```dart
// lib/core/utils/sharded_counter.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShardedCounter {
  ShardedCounter(this.parent, {this.shards = 10, this.field = 'count'});
  final DocumentReference parent;   // e.g. events/{eventId}
  final int shards;
  final String field;
  static final _rng = Random();

  // WRITE: one random shard, O(1), no contention on a single doc.
  Future<void> increment([int by = 1]) {
    final shardId = _rng.nextInt(shards);
    return parent.collection('shards').doc('$shardId')
        .set({field: FieldValue.increment(by)}, SetOptions(merge: true));
  }

  // READ: sum shards. Cache the result — never sum on every frame/scroll.
  Future<int> value() async {
    final snap = await parent.collection('shards').get();
    return snap.docs.fold<int>(0, (s, d) => s + ((d.data()[field] as int?) ?? 0));
  }
}

// Cached read wrapper (30 s TTL) so a list of 30 events is not 30*N reads per scroll.
class CachedShardSum {
  final _cache = <String, ({int v, DateTime at})>{};
  Future<int> get(ShardedCounter c, String key,
      {Duration ttl = const Duration(seconds: 30)}) async {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < ttl) return hit.v;
    final v = await c.value();
    _cache[key] = (v: v, at: DateTime.now());
    return v;
  }
}
```

```ts
// functions/src/shared/shardedCounter.ts — server-side write (used by likes.ts, coupons, etc.)
import * as admin from 'firebase-admin';
const db = admin.firestore();

export async function bumpShard(parentPath: string, delta: number, shards = 10) {
  const shardId = Math.floor(Math.random() * shards);
  await db.doc(`${parentPath}/shards/${shardId}`)
    .set({ count: admin.firestore.FieldValue.increment(delta) }, { merge: true });
}
```

### 6.2 Presence via Realtime Database `onDisconnect`

```dart
// lib/core/services/rtdb_presence_service.dart
import 'package:firebase_database/firebase_database.dart';

Future<void> goOnline(String uid) async {
  final ref = FirebaseDatabase.instance.ref('presence/$uid');
  // Registered with the server: fires even on a hard crash / lost connection.
  await ref.onDisconnect().set({'online': false, 'lastSeen': ServerValue.timestamp});
  await ref.set({'online': true, 'lastSeen': ServerValue.timestamp});
}

// Typing: RTDB, debounced, auto-clears on disconnect. No writes to conversations/*.
Timer? _typingDebounce;
void setTyping(String conversationId, String uid) {
  if (_typingDebounce?.isActive ?? false) return;   // ≤ 1 write / 3 s
  _typingDebounce = Timer(const Duration(seconds: 3), () {});
  final ref = FirebaseDatabase.instance.ref('typing/$conversationId/$uid');
  ref.onDisconnect().remove();
  ref.set(ServerValue.timestamp);
}
```

```ts
// 60 s reconcile: mirror RTDB truth → profiles.isOnline (batched) so discovery keeps filtering.
// Replaces the per-flip Firestore write in presence_service.dart + repurposes cleanupStalePresence.ts.
export const reconcilePresence = onSchedule('every 1 minutes', async () => {
  const snap = await admin.database().ref('presence').get();
  const now = Date.now();
  let batch = db.batch(); let ops = 0;
  for (const [uid, v] of Object.entries<any>(snap.val() ?? {})) {
    const online = v.online === true && (now - (v.lastSeen ?? 0)) < 60_000;
    batch.set(db.doc(`profiles/${uid}`), { isOnline: online }, { merge: true });
    if (++ops >= 450) { await batch.commit(); batch = db.batch(); ops = 0; }
  }
  if (ops) await batch.commit();
});
```

### 6.3 k6 load-test skeleton replaying the ops mix

```js
// staging only — never point at prod. Weighted scenario per README §0.7.
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  scenarios: {
    mix: { executor: 'ramping-vus', startVUs: 0,
      stages: [
        { duration: '2m', target: 1000 },
        { duration: '3m', target: 5000 },
        { duration: '3m', target: 15000 },
        { duration: '5m', target: 25000 },   // G2 peak-concurrent
        { duration: '2m', target: 0 },
      ] },
  },
};

function pick() {                       // cumulative weights
  const r = Math.random();
  if (r < 0.45) return 'chat';
  if (r < 0.70) return 'discovery';
  if (r < 0.82) return 'events';
  if (r < 0.90) return 'coins';
  if (r < 0.96) return 'tags';
  return 'tts';
}

export default function () {
  const base = `${__ENV.FS}/v1/projects/${__ENV.PROJECT}/databases/(default)/documents`;
  const h = { headers: { Authorization: `Bearer ${__ENV.TOKEN}` } };
  const op = pick();
  let res;
  switch (op) {
    case 'chat':      res = http.post(`${base}/conversations/${__ENV.HOT_CONV}/messages`, msg(), h); break;
    case 'events':    res = http.patch(`${base}/events/${__ENV.HOT_EVENT}?...likeCount`, like(), h); break; // stress the shard target
    case 'discovery': res = http.get(`${base}:runQuery?profiles-geohash-page`, h); break;
    default:          res = http.get(`${base}/coin_balances/${__ENV.UID}`, h);
  }
  check(res, { 'ok': (r) => r.status < 400 });
}
```
Emit p50/p95/p99 per `op` tag and correlate with the §6.4 hot-doc log-based metric to plot latency-vs-concurrency.

### 6.4 Cloud Monitoring alert for hot documents

```yaml
# Log-based metric: count of sampled write logs, labelled by docPath.
# Metric:  logging.googleapis.com/user/firestore_doc_writes  (extracted label: docPath)
displayName: "Firestore hot document (>20 writes/s)"
conditions:
  - displayName: "single doc > 20 writes/s (5m)"
    conditionThreshold:
      # sampled at p=0.05 → divide-by-p in the metric; alert on the estimated true rate
      filter: 'metric.type="logging.googleapis.com/user/firestore_doc_writes"'
      aggregations: [{ alignmentPeriod: 60s, perSeriesAligner: ALIGN_RATE,
                       crossSeriesReducer: REDUCE_MAX, groupByFields: ["metric.label.docPath"] }]
      comparison: COMPARISON_GT
      thresholdValue: 20
      duration: 300s
notificationChannels: ["projects/greengo/notificationChannels/oncall-pagerduty"]
severity: CRITICAL
# Second policy, thresholdValue: 10, channel: slack-eng, severity: WARNING.
```

---

## 7. Rollout & safety

- **Counters (§5.1):** strict **dual-write → reconcile (48 h zero drift) → flag-cutover reads → drop legacy
  write → drop legacy field.** Never cut reads over before reconcile is clean. Per-counter Remote Config flag.
- **Presence/typing (§5.2):** `presence_backend` feature flag (`firestore|rtdb`); canary 1% → 10% → 50% →
  100% with the presence-staleness SLO watched at each step; instant rollback flips the flag back to Firestore.
- **Canary cohort** before global for every behavioral change; **auto-rollback** wired to the SLO alerts (§6.4).
- **No big-bang:** ship each hot counter as its own small PR with a before/after harness curve attached.

---

## 8. Verification

1. **Load harness (§5.3)** at 25K-concurrent-equivalent shows **no single counter doc > 5 writes/s** —
   captured before (hotspot present) and after (gone) each shard PR.
2. **Presence accurate within 60 s** after the RTDB swap, verified by the harness driving connect/disconnect
   churn and diffing RTDB truth vs `profiles.isOnline`.
3. **Typing:** zero writes to `conversations/*` for typing; indicator still appears/clears in manual QA.
4. **Alert fires** on a synthetic > 20 writes/s hotspot within 5 min, paging the on-call channel.
5. **Message-send p95/p99** within SLO (< 300 ms / < 800 ms) at peak in the harness.

---

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Counter miscount during dual-write | Med | High | Reconcile job + 48 h zero-drift gate before read cutover; per-counter flag |
| Over-sharding (read cost, complexity) | Med | Med | Size `N` from measured writes/s; cache shard sums (§6.1); only shard `shard-now` rows |
| RTDB presence staleness / dual source of truth | Med | Med | `onDisconnect` + 60 s reconcile + canary + flag rollback |
| `firebase_database` add breaks iOS pod graph | Low | Med | Pin to Firebase 3.x/iOS-SDK-11 generation already used; verify pods per the iOS-pod-GDT playbook |
| Hot-doc sampler under-counts a brief spike | Med | Low | Harness catches sustained hotspots; native per-collection alert catches gross regressions |
| `function_monitors/{name}` becomes a hotspot when monitoring a busy fn | Med | Med | Sampled writes, not per-invocation, at scale (§5.4) |
| Harness staging data too uniform to form hotspots | Med | High | Seed realistic skew (hot event, celebrity profile, viral coupon) before runs |
| Sharding preemptively where not hot | Med | Med | The governing rule (§2): shard only what G1 dashboards / G2 alert / harness prove hot |

---

## Trade-offs — What this gate adds and what it costs

### ✅ What you gain
- **Features / UX:** presence and typing stay accurate for millions of concurrent users without lag or
  dropped indicators — a hard crash still flips a user offline (via RTDB `onDisconnect`) where today a
  crash could leave `profiles/{uid}.isOnline` stuck true until `cleanupStalePresence.ts` runs. Group
  chat, discovery, and events keep working smoothly at 25K concurrent instead of stuttering.
- **Performance:** removes the actual production slowdown — the single-doc write bottlenecks on
  `events/{id}.likeCount` (`functions/src/events/likes.ts:26`), `events/{id}.viewCount`
  (`event_detail_loader_screen.dart:42`), `profiles.followerCount`, coupon `redemptionsCount`, and the
  shared `conversations/{id}` doc (which absorbs message-send + typing + read-clear today). Message-send
  p95/p99 stays within SLO under contention; presence writes stop hammering the `profiles/*` documents
  that discovery also reads.
- **Functionality / capability headroom:** a canonical `ShardedCounter` helper + an RTDB presence service
  that every future high-write feature reuses; a repeatable load-test harness and hot-doc alerting that
  turn "is it slow?" into a measured, paged signal — and directly seed the G3 migration (GKE presence
  fleet, Pub/Sub fan-out build on exactly this work).

### ⚠️ What you give up / the costs
- **Complexity & maintenance:** counters become distributed (`N` shard docs per hot parent). Reads are
  now a fan-in — sum `N` docs and **cache the result** (§6.1) — instead of a single-field read. Two new
  helpers, a dual-write migration, a reconcile job, and per-counter feature flags to maintain.
- **Performance or UX regressions in specific paths:** sharded counts are **eventually consistent /
  slightly approximate** — a summed-and-cached shard total (30 s TTL) can lag the true value by seconds.
  Any UI showing an exact live number (like count ticking up in real time, exact follower count) trades
  precision for scale. Presence via `onDisconnect` + 60 s reconcile means the `isOnline` flag can be up
  to ~60 s stale for discovery filters (RTDB itself is near-real-time; the Firestore mirror is the lag).
- **Feature/behavior changes required:** UI surfaces that assumed an exact, instantly-consistent counter
  must tolerate small lag/approximation (or read the live shard sum directly when exactness matters).
  Typing state moves out of the `conversations/{id}` document, so anything reading `isTyping` from
  Firestore must switch to the RTDB path.
- **Engineering cost / dependencies:** ~15 dev-days across the gate, plus a **second datastore** —
  adding `firebase_database` (RTDB) introduces a new dependency, its own security rules, its own
  cost/quota model, and iOS pod-graph risk. The presence swap is a dual-write + reconcile migration with
  real rollback risk (mitigated by the `presence_backend` flag + canary). Staging Firebase project and
  load-test budget are prerequisites.

### Net verdict
Necessary once you approach ~1M / 25K concurrent — this is the gate where Firestore's ~1-write/sec-per-doc
wall actually slows the app, so the alternative to paying these costs is a visibly stuttering product under
real concurrency. The honest price is **added architectural surface** (a second datastore in RTDB) and
**counters that are fast-but-approximate rather than exact**. Both are the right trade at this scale — but
only at this scale: below the trigger these mechanisms are pure overhead, which is why the governing rule
(§2) is to shard and swap **only what measurement proves hot**, not preemptively.

## 10. Exit criteria → hand-off to G3

G2 is **DONE** when:
- Load harness at 25K-concurrent-equivalent shows **no document exceeding the hotspot threshold**; message-send p99 within SLO.
- The `shard-now` counters are sharded, cut over, and legacy fields retired; the canonical
  `ShardedCounter` helper is the only way new counters are written (enforced by the G6/README §6 PR checklist).
- Presence/typing are on RTDB with `onDisconnect` + 60 s reconcile; zero ephemeral writes to Firestore docs.
- Hot-doc alerting is live in prod with on-call routing and has fired on a synthetic test.
- Batched-fan-out coverage and document-ID audits are clean.

**Hand-off to [`G3_STRUCTURAL.md`](./G3_STRUCTURAL.md) (~3M):** G2 removed *per-document* hotspots; G3
addresses the *per-database* ~10K writes/sec ceiling — database-sharding readiness, the migration Phase-B
kickoff (AlloyDB for coins/membership, GKE Autopilot presence fleet built on the RTDB work here, Pub/Sub
fan-out extending the fanout.ts pattern). The RTDB presence service and the `ShardedCounter` helper from
this gate are the foundations G3 builds the migration on.

---

## 11. Cross-references

- [`README.md`](./README.md) — gate model, SLO table, guiding principles (esp. principle 4: "hotspots beat scale").
- [`G1_OBSERVE_THROTTLE.md`](./G1_OBSERVE_THROTTLE.md) — the dashboards + debounce work that G2 depends on to KNOW what is hot.
- [`G3_STRUCTURAL.md`](./G3_STRUCTURAL.md) — the per-database ceiling + migration Phase-B this gate hands off to.
- Repo: `functions/src/group_chat/fanout.ts` (fan-out reference), `functions/src/shared/monitoring.ts`
  (alerting scaffolding), `lib/core/services/presence_service.dart` (presence to replace),
  `functions/src/events/likes.ts` (first shard target), `docs/migration/` (GCP migration plan G3 kicks off).
