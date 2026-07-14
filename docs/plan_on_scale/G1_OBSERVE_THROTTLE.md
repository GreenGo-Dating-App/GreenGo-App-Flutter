# G1 — Observe & Throttle

**Gate:** G1 · **Registered trigger:** ~100K users · **Peak concurrent:** ~2.5K · **Start work at:** ~70K (be live before 100K)
**Theme:** Get real visibility, and cut write amplification, before it matters. Still cheap — no sharding yet.
**Owner:** Eng lead · **Date:** 2026-07-13 · **Version:** v1 · **Status:** Not started (activate at ~70K)
**Stack:** Flutter (Clean Arch + BLoC) · Firestore + Cloud Functions v2 + FCM · migration target AlloyDB + GKE Autopilot + Pub/Sub

> This is the detailed expansion of gate **G1** from [`README.md`](./README.md). Read that master plan first — the SLO table (§0), the activation-gate rule (§1), and the rollout/verification model (§2–3) all govern this document. G1 does **not** shard anything and does **not** move presence to RTDB — those are G2. G1 is: *see the load, and stop paying for churn we don't need.*

---

## 1. When to activate / when done

**Activate at ~70K registered (≈70% of the 100K trigger)** so the dashboards, throttles, and cache extensions are live and battle-tested before the app actually crosses 100K. Below ~70K there is nothing meaningful on a dashboard and no write pressure worth throttling — doing this work earlier is premature complexity (README §1, guiding principle 1).

**G1 is DONE when:**
- Cloud Monitoring dashboards show reads/writes per second per collection, p50/p95/p99 request latency, and active connections — with 7+ days of captured data.
- The four high-churn write signals (typing, presence/last-seen, read receipts, scroll/activity) each write at or below their target rate under load (§5.2).
- At least the two measured-hottest read paths are served cache-first, mirroring the `external_events` pattern (§5.3).
- Cloud Functions cold-start p99 is either within SLO on its own **or** `minInstances` has been applied to the hot triggers that showed cold-start spikes (§5.4) — conditional, not unconditional.

---

## 2. Objectives & SLOs defended

G1 defends the *observability* and *write-volume* rows of the master SLO table (README §0). It does not yet defend the single-doc hotspot row (that is G2).

| Metric (from master SLO table) | Target | Alert threshold | How G1 defends it |
|---|---|---|---|
| Writes/sec per database | < 7,000 | > 8,500 (approach ceiling) | Throttle typing/presence/receipts/activity (§5.2) |
| Writes/sec to any single document | < 5 sustained | > 20 (hotspot) | Dashboard makes it *visible*; typing-doc throttle keeps `conversations/{id}` cool (§5.2) — sharding deferred to G2 |
| Message-send latency (p95 / p99) | < 300 ms / < 800 ms | p99 > 1.2 s | Cold-start removal on fan-out (§5.4); fewer contending writes on the conversation doc |
| Feed / discovery load (p95) | < 500 ms | > 1 s | Cache-first on hot reads (§5.3) |
| Cold start to interactive (function) | fan-out p99 stable under burst | cold-start spikes visible on dashboard | Conditional `minInstances` (§5.4) |
| Active snapshot listeners per screen | ≤ 3 | > 6 | Inherited from G0; dashboard confirms active-connection count |

**Guiding principle for G1 (README §1):** measure first, throttle second. No throttle or cache change ships without the dashboard proving the signal it targets is actually hot.

---

## 3. Prerequisites — G0 must be complete

G1 assumes **G0 — Hygiene** is done and merged (README §1, Phase 0 lite + Phases 3.1/4.1/6.1):

- Every `.snapshots()` listener is cancelled on `dispose()` / BLoC `close()` (pattern already present in `lib/features/chat/presentation/bloc/chat_bloc.dart`).
- Every list query carries a `.limit()` / pagination cursor (the `external_events` pager at `lib/features/events/data/datasources/external_events_pager.dart` is the reference).
- Firebase Performance + Crashlytics traces are wired — **already present** at `lib/features/analytics/data/services/performance_monitoring_service.dart` (custom traces via `_performance.newTrace`, Crashlytics fatal handlers). G1 builds the *backend* dashboards on top of these client traces.
- The PR review checklist blocks un-throttled per-keystroke writes and un-paginated queries.

If any of the above is not true, stop and finish G0 first. G1 optimizations on top of leaking listeners or unbounded queries will give misleading dashboard numbers.

There is also **existing function-level monitoring scaffolding to build on**, not replace:
- `functions/src/shared/monitoring.ts` — a `monitored(name, handler)` wrapper already applied to every deployed handler (see `functions/scripts/instrument-monitoring.cjs`). It is inert until a function is selected in the admin panel (`app_config/function_monitoring`), then writes per-invocation stats to `function_monitors/{name}`. G1 uses this to sample the hot triggers cheaply.
- `docs/migration/08-observability-slo.md` — the migration observability plan; keep the G1 dashboards consistent with it.

---

## 4. Real code this gate touches (inventory)

Grounded in the current repo — the concrete write/read sites G1 acts on:

| Signal | Real file & symbol | What it writes today | Frequency today |
|---|---|---|---|
| **Presence (online/lastSeen)** | `lib/core/services/presence_service.dart` — `_setOnline()` / `_setOffline()` | `isOnline` + `lastSeen` on `profiles/{uid}` | On every online↔offline transition; 1-min inactivity check, 5-min timeout. Writes on **every** foreground resume (`onAppResumed`). |
| **Activity / "last active"** | `lib/core/services/activity_tracking_service.dart` — `_updateLastActive()` | `lastActiveAt` on `users/{uid}` | 5-min periodic heartbeat + `recordActivity()` debounced to 5 min. Already reasonable — verify only. |
| **Typing indicator** | `lib/features/chat/data/datasources/chat_remote_datasource.dart` `setTypingIndicator()` (≈L717–731); use case `lib/features/chat/domain/usecases/set_typing_indicator.dart`; dispatched via `lib/features/chat/presentation/bloc/chat_bloc.dart` `_onTypingIndicatorChanged` (≈L261) on `ChatTypingIndicatorChanged` | `isTyping` + `typingUserId` on the **shared** `conversations/{id}` doc | Every `ChatTypingIndicatorChanged` event → 1 write to a doc both participants also stream. This is the write to throttle hardest — it lands on a shared doc. |
| **Read receipts** | `chat_remote_datasource.dart` `markMessageAsRead` (≈L610) + `markConversationAsRead` (≈L623–665) | `readAt` per message (batched) + a `unreadCount` transaction on `conversations/{id}` | On open / on each incoming message viewed. `markConversationAsRead` already batches + uses a transaction. |
| **Unread bump on send** | `chat_remote_datasource.dart` (≈L502, L1534) | `FieldValue.increment(1)` on `unreadCount` of `conversations/{id}` | 1 per message sent (shared-doc write — visible on dashboard, sharded only at G2). |
| **Scroll position** | *No dedicated Firestore write found.* | — | If added later, it must go through the debounce helper (§5.2 / §6), never per-frame. Flag in review checklist now. |

**Read paths (cache-first target):**
- Reference pattern: `lib/features/events/data/datasources/external_events_data_source.dart` — reads the `external_events` collection (populated by ingester Cloud Functions), cache-first via Firestore persistence, bounded `.limit()`, geohash bounds, sample fallback while empty. Companions: `external_events_pager.dart`, `external_events_preloader.dart`, `core/services/external_events_index_service.dart`, `core/utils/geo_query.dart`. This is the template every G1 cache extension copies.

**Hot Cloud Function triggers (cold-start candidates):**
- `functions/src/group_chat/fanout.ts` — `onDocumentCreated` on group message write; does O(N) fan-out to `user_group_inbox/{uid}/threads/{groupId}` + chunked FCM multicast. Highest-fan-out trigger.
- `functions/src/notifications/pushNotificationTriggers.ts` — `onNewMessagePush` (`conversations/{convId}/messages/{msgId}`, ≈L388), `onNewLikePush` (≈L250), `onNewMatchPush` (≈L313). Per-message / per-interaction push.

**No function currently sets `minInstances`, `maxInstances`, or `concurrency`.** A grep of `functions/src` finds only a handful of v1 `.runWith({ memory, timeoutSeconds })` calls (`backup/pdfExport.ts`, `admin/userManagement.ts`, `media/voiceTranscription.ts`, `media/videoProcessing.ts`, `security/securityAudit.ts`) and `.runWith({ secrets })` on Stripe — **none** touch instance floors/ceilings. Cold-start behavior is therefore entirely at platform default today. That is fine below G1; §5.4 makes changing it conditional on observed spikes.

---

## 5. Tasks

Each task: **Objective · Steps (real files) · Acceptance · Effort · Risk.**

### 5.1 Cloud Monitoring dashboards (observability)

**Objective:** make Firestore load and function latency *visible* so every later G1/G2 decision is measurement-driven, not guessed.

**Steps:**
1. In Cloud Monitoring for the GreenGo Firebase project, enable Firestore usage metrics and build a **"GreenGo — Firestore Load"** dashboard with these charts:
   - **Reads/sec per collection** and **Writes/sec per collection** (metric `firestore.googleapis.com/document/read_count` and `.../write_count`, grouped by `collection_id`). Pin the churn collections: `conversations`, `profiles`, `users`, `groups`, `user_group_inbox`.
   - **Request latency p50 / p95 / p99** (`firestore.googleapis.com/api/request_latencies`, aligned as `PERCENTILE_50/95/99`).
   - **Active connections / concurrent listeners** (`firestore.googleapis.com/network/active_connections`).
2. Build a **"GreenGo — Functions"** dashboard: execution count, execution latency p95/p99, active/idle instance count, and **cold-start count** per function (`cloudfunctions.googleapis.com/function/execution_times` p99 + instance-count deltas) — filtered to `groupFanout`, `onNewMessagePush`, `onNewLikePush`, `onNewMatchPush`.
3. Wire alerts to the master SLO thresholds (README §0):

   | Alert | Condition | Source |
   |---|---|---|
   | DB write ceiling approaching | writes/sec per database > 8,500 | Firestore write_count |
   | Hot document | any single-doc write rate > 20/s | native metric or sampled logger via `monitored()` in `group_chat/fanout.ts` |
   | Request latency breach | request p99 > 1.2 s for 5 min | request_latencies |
   | Feed/discovery slow | feed-load trace p95 > 1 s | Firebase Perf trace (client) |
   | Function cold-start spike | fan-out p99 > 2× rolling median | function execution_times |

4. For per-document sampling (native metric is coarse), reuse the existing `monitored()` wrapper (`functions/src/shared/monitoring.ts`): extend it (behind the same `app_config/function_monitoring` flag) to sample `docPath` write frequency in `group_chat/fanout.ts` and log the top-N hottest paths. Do **not** write a new monitoring system — extend this one.

**Acceptance:** both dashboards live; 7 continuous days of data captured; a synthetic test driving >20 writes/s to one doc fires the hot-document alert within 5 min.
**Effort:** ~2 dev-days. **Risk:** Low — read-only observability, no app behavior change.

---

### 5.2 Debounce / throttle high-churn writes

**Objective:** cut write amplification on the four churn signals so writes/sec per database (and per shared conversation doc) drops at constant concurrency — *without* moving anything off Firestore yet (that is G2).

**Per-signal target rates:**

| Signal | Current | G1 target | Where to change |
|---|---|---|---|
| Typing indicator | 1 write per `ChatTypingIndicatorChanged` (potentially per keystroke) | **≤ 1 write / 3 s per user per conversation**, and a single "stopped typing" write on a 4 s idle timer | Wrap `SetTypingIndicator` call in `chat_bloc.dart` `_onTypingIndicatorChanged` with the debounce helper (§6.1) |
| Presence (online/lastSeen) | write on every foreground resume + every transition | **≤ 1 write / 60 s**; suppress redundant `isOnline:true` writes when already online (partly done — `_setOnline` early-returns if `_isCurrentlyOnline`); add a min-interval guard on `onAppResumed` | `lib/core/services/presence_service.dart` |
| Read receipts | `readAt` per message + `unreadCount` transaction on open | **coalesce**: keep the existing batch in `markConversationAsRead`, but debounce the trigger so rapid scroll-through doesn't fire it repeatedly (≤ 1 / 2 s) | `chat_remote_datasource.dart` `markConversationAsRead`; debounce at the caller in the chat BLoC |
| Activity / lastActiveAt | 5-min heartbeat + 5-min debounced `recordActivity` | **verify only** — already ≤ 1 write / 5 min; confirm no caller bypasses the debounce | `lib/core/services/activity_tracking_service.dart` |

**Steps:**
1. Add a small reusable `WriteThrottle` / debounce utility in `lib/core/utils/` (see §6.1) — leading-edge throttle for "start typing", trailing-edge debounce for "stopped typing" and receipts.
2. Route the typing write in `chat_bloc.dart` through it. Keep the write target the same (`conversations/{id}`) for G1 — throttling alone drops the shared-doc write rate below the hotspot line at 2.5K concurrent. (Moving typing to RTDB is explicitly G2, README §1 / Phase 1.3.)
3. Add the 60 s min-interval guard to `PresenceService._setOnline` on resume.
4. Debounce the `markConversationAsRead` trigger at the BLoC layer.
5. Put all four behind the G1 feature flag (§7) so they can be rolled 1%→10%→50%→100%.

**Acceptance:** on the dashboard at constant concurrency, aggregate writes/sec drops measurably (target ≥ 30% on the churn collections combined, echoing README Phase 2 exit); typing generates ≤ 1 write / 3 s per user; no single `conversations/{id}` doc exceeds the 20/s hotspot alert under load test.
**Effort:** ~3 dev-days. **Risk:** Med — over-throttling presence makes "online" look stale; mitigate with the 60 s reconcile and canary (§9).

---

### 5.3 Cache-first on measured-hot reads

**Objective:** extend the proven `external_events` cache-first approach to the read paths the §5.1 dashboard shows are hottest — so repeat loads hit the device/cache and backend reads/user fall, holding feed p95 within SLO.

**Steps:**
1. From the §5.1 dashboard, rank collections by reads/sec. Candidates (confirm with data, don't assume): discovery/candidate reads (`lib/features/discovery/data/datasources/discovery_remote_datasource.dart`, `core/services/candidate_pool_service.dart`), hot profile reads (`profiles/{uid}` fetched by chat/network cards), and event lists.
2. For the top two measured-hot read paths, mirror `external_events_data_source.dart`:
   - Bounded `.limit()` query (already the norm).
   - Rely on Firestore local persistence for repeat reads (confirm persistence is enabled app-wide — G0/Phase 3.3).
   - Add an explicit in-repo cache layer with a TTL for shared-across-users content, following the repository read pattern in §6.2.
   - Keep the "sample/fallback while empty" ergonomics from `external_events` so first paint is instant.
3. Do **not** cache per-user mutable state that must be live (unread counts, active typing) — cache only shared or slow-changing reads.

**Acceptance:** repeat feed/profile loads served from cache (second view of same data = zero network reads, verified in DevTools network tab); backend reads/user on the targeted collections drop on the dashboard at constant MAU; feed p95 stays < 500 ms.
**Effort:** ~2.5 dev-days. **Risk:** Med — cache staleness on profiles; mitigate with short TTL + cache-then-network revalidation (§9).

---

### 5.4 Cloud Functions `minInstances` — CONDITIONAL on observed cold starts

**Objective:** eliminate cold-start latency spikes on the hot triggers **only if the §5.1 Functions dashboard actually shows them.** No preemptive warm fleet — that is wasted spend below the trigger.

**Decision rule (do NOT skip):**
> Apply `minInstances` to a function **only** when its dashboard shows cold-start-driven p99 spikes (fan-out p99 > 2× rolling median correlated with instance count hitting zero) at G1 concurrency. If p99 is stable at default (0 min instances), **change nothing** and record "not needed" in the exit checklist.

**Steps (if and only if the rule fires):**
1. Identify the offending trigger from the dashboard — most likely `groupFanout` (`functions/src/group_chat/fanout.ts`) or `onNewMessagePush` (`functions/src/notifications/pushNotificationTriggers.ts`).
2. Migrate that handler's options to the v2 form with `minInstances` set low (start at 1–3, tune to observed concurrency) and a `maxInstances` ceiling to protect downstream Firestore/FCM (§6.3). These functions are already `firebase-functions/v2` (`onDocumentCreated`), so this is an options change, not a rewrite.
3. Optionally raise `concurrency` (v2 default 80) if per-instance CPU headroom allows — reduces the instance count needed.
4. Re-measure for 48 h; confirm the spike is gone and cost delta is acceptable.

**Acceptance:** after applying, fan-out / push p99 is stable under burst with no cold-start spikes on the dashboard; **or**, if the rule never fired, a recorded "cold starts within SLO at G1 — minInstances deferred" note. Either is a valid DONE.
**Effort:** ~0.5–1 dev-day (conditional). **Risk:** Low — but `minInstances` bills for idle warm instances, so keep the floor small and revisit at G2.

---

## 6. Reference code patterns

### 6.1 Debounced typing write (route away from per-keystroke)

Drop-in helper for `lib/core/utils/`, then used from `chat_bloc.dart` `_onTypingIndicatorChanged`. Leading-edge throttle for "start", trailing debounce for "stop":

```dart
// lib/core/utils/write_throttle.dart
import 'dart:async';

/// Emits at most one "typing" write per [minInterval], plus one trailing
/// "stopped typing" write after [idleAfter] of no keystrokes. Keeps the write
/// target unchanged (Firestore conversations/{id}) — G1 only cuts the RATE.
class TypingThrottle {
  TypingThrottle({
    this.minInterval = const Duration(seconds: 3),
    this.idleAfter = const Duration(seconds: 4),
    required this.onTyping,   // (isTyping) => setTypingIndicator(...)
  });

  final Duration minInterval;
  final Duration idleAfter;
  final void Function(bool isTyping) onTyping;

  DateTime? _lastSent;
  Timer? _idleTimer;

  /// Call on every keystroke / text change.
  void onKeystroke() {
    final now = DateTime.now();
    if (_lastSent == null || now.difference(_lastSent!) >= minInterval) {
      _lastSent = now;
      onTyping(true);                 // <= 1 write / minInterval
    }
    _idleTimer?.cancel();
    _idleTimer = Timer(idleAfter, () => onTyping(false)); // single "stopped"
  }

  void dispose() => _idleTimer?.cancel();
}
```

In the BLoC, replace the direct `setTypingIndicator(...)` call in `_onTypingIndicatorChanged` with `_typingThrottle.onKeystroke()`, and cancel it in `close()` (G0 lifecycle rule).

### 6.2 Cache-first repository read (mirroring `external_events`)

Same shape as `ExternalEventsDataSource` (bounded query + persistence), with an explicit TTL cache for shared reads:

```dart
// Pattern for a measured-hot read path (e.g. hot profiles / discovery pool).
class CachedProfileReader {
  CachedProfileReader(this._firestore);
  final FirebaseFirestore _firestore;

  final _cache = <String, ({DateTime at, Map<String, dynamic> data})>{};
  static const _ttl = Duration(minutes: 5);

  Future<Map<String, dynamic>?> get(String uid) async {
    final hit = _cache[uid];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
      return hit.data;                       // in-memory, zero network
    }
    // Cache-first: Firestore serves from local persistence when offline/warm,
    // exactly like ExternalEventsDataSource relies on SDK persistence.
    final snap = await _firestore.collection('profiles').doc(uid).get();
    final data = snap.data();
    if (data != null) _cache[uid] = (at: DateTime.now(), data: data);
    return data;
  }

  void invalidate(String uid) => _cache.remove(uid); // on known writes
}
```

### 6.3 Cloud Functions v2 `minInstances` (JS/TS — conditional)

Only after the §5.4 rule fires. `group_chat/fanout.ts` is already `onDocumentCreated` (v2); add options:

```typescript
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { monitored } from '../shared/monitoring';

export const groupFanout = onDocumentCreated(
  {
    document: 'groups/{groupId}/messages/{messageId}',
    region: 'us-central1',
    minInstances: 2,      // ONLY if dashboard showed cold-start p99 spikes
    maxInstances: 50,     // protect downstream Firestore/FCM from runaway scale
    concurrency: 80,      // v2 default; raise only with CPU headroom
    memory: '512MiB',
  },
  monitored('groupFanout', async (event) => {
    // ...existing O(N) fan-out to user_group_inbox + chunked FCM multicast...
  }),
);
```

Alternatively set a project-wide floor with `setGlobalOptions({ maxInstances })` for the ceiling, but keep `minInstances` per-function so only the proven-hot triggers pay for warm capacity.

---

## 7. Rollout & safety

- **Feature-flag every behavioral change.** Add a `g1_flags` block to remote config / `app_config`: `throttleTyping`, `throttlePresence`, `throttleReceipts`, `cacheFirstProfiles`, `cacheFirstDiscovery`. Default off; flip per cohort.
- **Canary order:** throttles first (lowest risk, biggest write-volume win), then caching, then — only if needed — `minInstances`.
- **Staged rollout:** 1% → 10% → 50% → 100%, watching the §5.1 dashboard + crash-free SLO at each step (README §2).
- **Auto-rollback** tied to the SLO alerts: if presence-staleness complaints or feed p95 regress past threshold, flip the flag off — no redeploy needed.
- **Small PRs**, each with its own before/after dashboard capture. No big-bang.

---

## 8. Verification

- **Throttle win:** capture writes/sec per collection on the §5.1 dashboard at a fixed concurrency (load harness or real traffic) **before and after** enabling each throttle flag. Success = a visible step-down in writes/sec at constant load, and typing ≤ 1 write / 3 s per user.
- **Cache win:** DevTools network tab — second view of the same feed/profile issues zero reads; dashboard shows reads/user falling on the targeted collections while MAU is flat.
- **Cold-start (if applied):** function p99 chart shows the pre-`minInstances` spikes flatten and stay flat under burst for 48 h; instance count no longer hits zero between bursts.
- **No regressions:** crash-free sessions stay > 99.5%; message-send p99 stays < 800 ms; presence still accurate within 60 s (spot-check "online" dots against real sessions).

---

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Presence looks stale after throttling (dot lags real state) | Med | Med | 60 s min-interval + reconcile on next activity; feature-flag + canary; `onAppPaused` still writes offline immediately |
| Cache staleness on hot profiles (name/photo/online out of date) | Med | Med | Short TTL (5 min) + cache-then-network revalidate; `invalidate(uid)` on known local writes; never cache unread/typing |
| Typing throttle drops the "stopped typing" write, leaving a stuck indicator | Low | Low | Trailing idle-timer always emits `isTyping:false` (§6.1); receiver also times out the indicator client-side |
| `minInstances` bills for idle warm instances with no benefit | Med | Low | Strictly conditional on observed spikes (§5.4); start floor at 1–2; `maxInstances` ceiling; revisit at G2 |
| Dashboard metrics too coarse to see a single hot doc | Med | Med | Extend existing `monitored()` sampler (`functions/src/shared/monitoring.ts`) for `docPath` frequency — reuse, don't rebuild |
| Throttling masks a real hotspot instead of fixing it | Low | Med | G1 explicitly defers sharding to G2; dashboard + hot-doc alert stay on so the true hotspot is still visible for G2 |

---

## 10. Exit criteria → hand-off to G2

G1 exits (and G2 planning begins) when **all** hold:
1. Both Cloud Monitoring dashboards live with 7+ days of data; all §5.1 alerts wired to the master SLO thresholds.
2. Typing / presence / read-receipt / activity writes each at or below their §5.2 target rate under load, verified on the dashboard.
3. The two measured-hottest read paths served cache-first (§5.3); reads/user flat or falling.
4. Cold-start decision recorded — `minInstances` either applied-and-stable or documented as not-needed at G1.
5. Aggregate churn writes/sec down ≥ 30% at constant concurrency vs. the pre-G1 baseline.

**Hand-off to [G2 — De-hotspot](./G2_DE_HOTSPOT.md):** by this point the dashboard will have *named the actually-hot documents* (e.g. `conversations/{id}` `unreadCount`, any member/online counters). That ranked hot-doc list — which throttling alone can no longer keep under 5 writes/s at ~1M — is the exact input G2 needs to shard counters, move presence/typing to RTDB, and stand up the load-test harness. G1 makes the hotspots visible; G2 removes them.

---

## 11. Cross-references

- [`README.md`](./README.md) — master plan: SLO table (§0), activation gates (§1), rollout/verification (§2–3), reference patterns (Appendix A).
- [`G0_HYGIENE.md`](./G0_HYGIENE.md) — prerequisite: listener lifecycle, query limits, review checklist, client Perf traces.
- [`G2_DE_HOTSPOT.md`](./G2_DE_HOTSPOT.md) — next gate (~1M): counter sharding, RTDB presence/typing, batched-fan-out audit, load-test harness.
- `docs/migration/08-observability-slo.md` — migration observability plan; keep G1 dashboards consistent.
- Real code anchors: `lib/core/services/presence_service.dart`, `lib/core/services/activity_tracking_service.dart`, `lib/features/chat/data/datasources/chat_remote_datasource.dart`, `lib/features/chat/presentation/bloc/chat_bloc.dart`, `lib/features/events/data/datasources/external_events_data_source.dart`, `functions/src/group_chat/fanout.ts`, `functions/src/notifications/pushNotificationTriggers.ts`, `functions/src/shared/monitoring.ts`, `lib/features/analytics/data/services/performance_monitoring_service.dart`.
