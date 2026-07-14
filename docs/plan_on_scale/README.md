# GreenGo — Performance Hardening & Anti-Slowdown Implementation Plan

**Goal:** eliminate the slowdowns that occur in practice (hotspots, write contention, client jank) and push the systemic slowdown point from "hundreds of users" out past **10M registered / 250K concurrent**, while laying the groundwork for the Phase-B migration.
**Owner:** Eng lead · **Date:** 2026-07-13 · **Version:** v1 · **Status:** Ready to execute
**Stack:** Flutter (Clean Arch + BLoC) · Firestore + Cloud Functions + FCM · migration target AlloyDB + GKE Autopilot + Pub/Sub

> This plan is grounded in a real audit of this repo, not just architecture notes. **Phase 0 replaces every remaining assumption with measured data** — do not skip it. Each gate below has its own deep-dive document with real code anchors.

---

## Detailed gate plans (this folder)

This README is the overview and the activation-gate model. Each gate has a standalone deep-dive — tasks, real file references, code patterns, verification, and a gains/losses trade-off analysis:

| Gate | Trigger | Theme | Document |
|---|---|---|---|
| **G0** | now / any scale | Hygiene (correct code, no complexity) | [`G0_HYGIENE.md`](./G0_HYGIENE.md) |
| **G1** | ~100K | Observe & throttle | [`G1_OBSERVE_THROTTLE.md`](./G1_OBSERVE_THROTTLE.md) |
| **G2** | ~1M | De-hotspot | [`G2_DE_HOTSPOT.md`](./G2_DE_HOTSPOT.md) |
| **G3** | ~3M → 10M | Structural / migration kickoff | [`G3_STRUCTURAL.md`](./G3_STRUCTURAL.md) |
| **G4** | ~10M+ | Distributed | [`G4_DISTRIBUTED.md`](./G4_DISTRIBUTED.md) |

## Trade-offs at a glance — what each gate adds vs. what it costs

Every gate is a deliberate trade. Full detail lives in each gate doc's *Trade-offs* section; this is the summary.

| Gate | ✅ What you gain (features · performance · capability) | ⚠️ What you give up (complexity · regressions · cost) |
|---|---|---|
| **G0** | No leaked listeners (memory/battery/stale UI); bounded, cheaper, faster reads; real perf visibility; regression guard | Near-zero. Some "load-all" lists become infinite-scroll; small pre-commit/dev friction |
| **G1** | Real observability; lower write volume + cost; faster feeds via cache-first | Typing/presence slightly less instant (debounced); feed staleness window; dashboard ops; `minInstances` idle cost |
| **G2** | Removes the actual hotspot slowdowns; presence scales via RTDB; hot-doc alerting | Counters become **approximate/eventually-consistent**; adds RTDB as a 2nd datastore (rules, cost, dep); presence-swap migration risk |
| **G3** | Breaks the ~10K writes/s ceiling; **transactional integrity** for money on AlloyDB; smoother UI (isolates); CDN | Two backends + dual-write; multi-month program; AlloyDB+GKE 24/7 run-cost; possible cutover freeze windows |
| **G4** | 1B-user capacity; multi-region latency + DR/failover; falling cost/MAU | Highest ops complexity; **cross-shard loses global queries** (features must be shard-aware); data-residency limits; high fixed cost |

> Read top-to-bottom, the app **gains scale and resilience** and **gives up simplicity and some real-time exactness** — but only when each gate's trigger forces the trade. Below a trigger, you keep the simpler, cheaper version.

---

## 0. Success criteria (SLOs)

Ship nothing until these are instrumented; use them as the definition of done.

| Metric | Target | Alert threshold |
|---|---|---|
| Message-send latency (p95 / p99) | < 300 ms / < 800 ms | p99 > 1.2 s |
| Feed / discovery load (p95) | < 500 ms | > 1 s |
| Cold start to interactive | < 2.5 s | > 4 s |
| **Writes/sec to any single document** | < 5 sustained | **> 20 (hotspot)** |
| Writes/sec per database | < 7,000 | > 8,500 (approach ceiling) |
| Frame jank (build > 16 ms) | < 1% of frames | > 3% |
| Crash-free sessions | > 99.5% | < 99% |
| Active snapshot listeners per screen | ≤ 3 | > 6 |

**Guiding principles**
1. **Complexity is a cost — add it only when load demands it.** Do NOT shard counters, swap in an RTDB presence fleet, or split databases at 5K users. Each scale-defense mechanism is switched on at a **user-count trigger** (see §1). Below the trigger, the simple version is the *correct* version.
2. **Separate hygiene from scale-defense.** A small set of items (cancel listeners, cap query limits, review checklist) are just *correct code* — cheap, do them now at any scale, they prevent debt. Everything else waits for its gate.
3. **Measure first, optimize second.** No scale-defense change without a metric proving the trigger has been reached.
4. **Hotspots beat scale.** A single hot doc slows the app at any user count — but you only *fix* it once measurement shows it's actually hot, not preemptively everywhere.
5. **Ship behind flags.** Every risky change is feature-flagged and canaried.
6. **Prevent regressions in CI**, not in production.

---

## 1. Activation gates — turn each change on at the scale that needs it

**The core rule: complexity is deferred until a user-count trigger is crossed.** Below a gate, the simple implementation is correct and you should not touch it. Start each gate's work when you reach ~70% of its trigger, so it's live before you need it.

| Gate | Registered trigger | Peak concurrent | What activates here | Why not earlier |
|---|---|---|---|---|
| **G0 — Hygiene** | **Now / any scale** | any | Cancel listeners on dispose · cap every query with `.limit()` · PR review checklist · lightweight Firebase Perf traces | These are *correct code*, not complexity. ~zero cost, prevent debt. |
| **G1 — Observe & throttle** | **~100K** | ~2.5K | Proper Cloud Monitoring dashboards · debounce high-churn writes (typing/presence/scroll) · Cloud Functions `minInstances` *if* cold starts appear · cache-first on measured-hot reads | Below 100K there's nothing to see on a dashboard and no write pressure worth throttling. |
| **G2 — De-hotspot** | **~1M** | ~25K | Shard the counters that measurement shows are hot · move presence/typing to RTDB · batched fan-out audit · load-test harness · hot-doc alerting · full monitoring | Sharding a counter that takes 5 writes/sec is pure overhead. Wait until a doc is actually hot. |
| **G3 — Structural scale** | **~3M** (start) → 10M | ~75K–250K | Database-sharding readiness · **migration Phase-B kickoff** (AlloyDB for coins/membership, GKE presence fleet, Pub/Sub) · isolates for heavy client work · CDN/bundles for shared content | This is where the ~10K writes/sec ceiling comes into view. Starting at 3M means it's live before 10M. |
| **G4 — Distributed** | **~10M+** | 250K+ | Multi-database sharding active · full GKE WebSocket fleet · multi-region · migration complete | Only justified past the single-DB ceiling. |

**How to read this:** the *first* column of work (G0) you do today regardless of size. Everything else you leave alone until the trigger. If you're at, say, 50K users now, your entire backlog is **G0 only** — do not build the rest yet.

### Phase → gate mapping
The detailed phases below are the *how*; this table says *when* each turns on.

| Phase (the "how") | Activates at | Notes |
|---|---|---|
| **0** Baseline & instrumentation | G0 (lite) → G1/G2 (full) | Perf traces now; dashboards at 100K; load harness at ~1M |
| **1** Hotspot elimination | **G2 (~1M)** | Only shard what measurement flags as hot |
| **2** Write-pressure reduction | G1 (~100K) → G2 | Throttling early; ephemeral-off-Firestore at G2 |
| **3** Read & cache optimization | G0 (limits) → G1/G2 (caching) | Pagination limits now; cache-first when reads get hot |
| **4** Client render perf | G0 (listeners) → G1/G2 (rest) | Listener lifecycle now; images/isolates as jank appears |
| **5** Structural / migration | **G3 (~3M)** → G4 | Separate long track; trigger on time |
| **6** Regression prevention | G0 (checklist) → G1 (CI guards) | Checklist now; automated guards once team/PR volume grows |

**Effort note:** G0 is ~2–3 dev-days total and permanent hygiene. G1–G2 (~15 dev-days) only get scheduled once you approach 100K–1M. G3+ is the migration program. **You are not signing up for 6 weeks of work at low scale — at low scale you do G0 and stop.**

---

## PHASE 0 — Baseline, instrumentation & load-test harness
**Objective:** know the real numbers before touching code. Nothing else is trustworthy without this.

### Tasks
- **0.1 Backend observability.** Enable Firestore usage metrics in Cloud Monitoring; build a dashboard for: reads/writes per second per collection, p50/p95/p99 request latency, active connections. *Acceptance:* dashboard live, 7 days of data captured.
- **0.2 Hot-document detection.** Add a Cloud Monitoring alert on document write rate; if native metrics are insufficient, add a lightweight sampled logger in the fan-out Cloud Functions that records `docPath` write frequency. *Acceptance:* alert fires in a synthetic test at >20 writes/s to one doc.
- **0.3 Client performance telemetry.** Wire up Firebase Performance Monitoring in the Flutter app: custom traces on message-send, feed-load, screen-open, and app cold-start. *Acceptance:* traces visible in console; p95 baselines recorded.
- **0.4 Frame/jank profiling.** Run the app in profile mode through DevTools on a low-end reference device (minSdk 24 target); capture jank baseline on the 4 heaviest screens (chat, discovery, network grid, events). *Acceptance:* jank % recorded per screen.
- **0.5 Listener inventory.** Audit every `.snapshots()` / active listener across the app; produce a table of screen → listeners → lifecycle (is it cancelled on dispose?). *Acceptance:* spreadsheet of all live listeners + leak flags.
- **0.6 Hotspot inventory.** Grep the codebase for every counter/aggregate write and shared-doc write (member counts, online counts, unread counts, likes, coin totals, presence, typing). Classify each: sharded / un-sharded / hot. *Acceptance:* ranked hotspot list — this becomes Phase 1's backlog.
- **0.7 Load-test harness.** Stand up a staging Firebase project; build a load generator (e.g. Node/k6 or a headless Flutter driver) that replays realistic mix: 45% chat+presence, 25% discovery, 12% events, 8% coins, 6% tags, 4% TTS. *Acceptance:* can drive staging to a target concurrent-user count and record latency curves.

**Exit criteria:** dashboards live, baselines recorded, hotspot + listener inventories complete, load harness reproduces the ops mix. **Effort ~5 dev-days.**

---

## PHASE 1 — Hotspot elimination (P0)
**Objective:** remove every single-document write bottleneck. This is what actually slows the app in production, at any scale.

### Tasks
- **1.1 Shard all remaining counters.** For each un-sharded counter from 0.6, convert to a distributed counter: `N` shard docs, random-shard write, summed read. Size `N ≈ expected peak writes/sec` (start 10, tune). *Where:* member counts, online counts, coin totals, reaction/like counts. *Acceptance:* load test shows no single counter doc > 5 writes/s at target load.
- **1.2 Move presence off Firestore.** Replace any Firestore presence/heartbeat writes with **Realtime Database `onDisconnect` presence** (or a throttled per-user doc, never a shared doc). *Acceptance:* zero writes to a shared presence doc; presence still accurate within 60s.
- **1.3 De-hotspot "typing…" & read receipts.** Route ephemeral signals through RTDB or throttle to per-conversation debounced writes; never every keystroke. *Acceptance:* typing indicator generates ≤ 1 write / 3s per user.
- **1.4 Group-chat write path.** Verify messages write to an auto-ID subcollection (naturally distributed). Move any `lastMessage` / `unreadCount` on the group doc to a **sharded field or a debounced Cloud Function**, not a per-client write. *Acceptance:* group doc write rate independent of member count under load.
- **1.5 Document-ID distribution.** Audit high-write collections for sequential/timestamp-prefixed IDs; switch to auto-IDs or hashed prefixes to avoid tablet hotspotting. *Acceptance:* no monotonic ID pattern on any high-write collection.
- **1.6 Verify batched fan-out coverage.** Confirm the existing batched fan-out covers all group-message delivery; extend to any new group features (group tags, network broadcasts). *Acceptance:* one logical message = one batched fan-out, not N client writes.

**Exit criteria:** load test at 250K-concurrent-equivalent shows no document exceeding the hotspot threshold; message-send p99 within SLO. **Effort ~8 dev-days.**

---

## PHASE 2 — Write-pressure reduction (P1, parallel with Phase 1)
**Objective:** cut total write volume so the ~10K/s database ceiling arrives later.

### Tasks
- **2.1 Debounce/throttle high-churn writes** — presence, typing, scroll position, "last seen." *Acceptance:* aggregate writes/sec drop measurably at constant load.
- **2.2 Batch multi-doc writes** — use `WriteBatch`/transactions for coin-ledger entries and any multi-document update (e.g. send message + update conversation + increment counter). *Acceptance:* related writes commit as one round-trip.
- **2.3 Move ephemeral state off per-op billing** — typing/presence/live-cursor to RTDB or in-memory. *Acceptance:* Firestore write volume for ephemeral state ≈ 0.
- **2.4 Coalesce coin operations** — batch rapid coin spends (e.g. TTS calls) into fewer ledger writes where consistency allows. *Acceptance:* coin write rate reduced without ledger integrity loss.

**Exit criteria:** total peak writes/sec per database reduced ≥ 30% at constant concurrency. **Effort ~6 dev-days.**

---

## PHASE 3 — Read & cache optimization (P1)
**Objective:** hold read latency and cost flat as users grow.

### Tasks
- **3.1 Pagination guardrails.** Audit every query; enforce a `.limit()` on all, and forbid unbounded `.snapshots()`. Add a lint/review rule (feeds into Phase 6). *Acceptance:* no query returns > page size; infinite-scroll everywhere for long lists.
- **3.2 Extend cache-first pattern.** Replicate the `external_events` cache-first approach to hot profiles, the discovery feed, and event lists — shared cached reads. *Acceptance:* repeat feed loads served from cache; backend reads/user drop.
- **3.3 Enable SDK local persistence.** Confirm Firestore offline persistence + cache size tuning is on for all platforms so repeat reads hit the device. *Acceptance:* second view of same data does zero network reads.
- **3.4 Firestore bundles / CDN for shared content.** Serve identical-across-users content (trending, featured, static config) via bundles or a CDN-fronted cache. *Acceptance:* shared content read once per client per TTL, not per view.
- **3.5 Query/index review.** Ensure every list query is backed by a composite index and uses geohash bounds for proximity (no full scans). *Acceptance:* no query missing an index; geo queries bounded.

**Exit criteria:** feed p95 within SLO at 10× current load in the harness; reads/MAU flat or falling. **Effort ~7 dev-days.**

---

## PHASE 4 — Client-side (Flutter) render performance (P1)
**Objective:** the app feels fast on a low-end device regardless of backend load.

### Tasks
- **4.1 Fix listener lifecycle.** For every leak flagged in 0.5: one BLoC → owns its stream subscriptions → cancels them in `close()`. Cap active listeners per screen ≤ 3. *Acceptance:* listener count returns to baseline after navigating away from every screen.
- **4.2 List & image discipline.** `ListView.builder` for all long lists; `cached_network_image` with explicit width/height and memCacheWidth; lazy-load below the fold. *Acceptance:* jank < 1% while scrolling chat/discovery on the reference device.
- **4.3 Minimize rebuilds.** Add BLoC `buildWhen`/selectors, `const` constructors, and split large widgets so a state change doesn't rebuild the whole subtree. *Acceptance:* rebuild count per interaction drops in DevTools.
- **4.4 Offload heavy work to isolates.** Move JSON parsing, geohash math, and image decode off the UI isolate (`compute()` / isolates). *Acceptance:* no UI-thread stalls > 16 ms during those operations.
- **4.5 Cold-start optimization.** Defer non-critical init (analytics, remote config, prefetch) past first frame; audit the startup dependency graph. *Acceptance:* cold start < 2.5 s on reference device.

**Exit criteria:** all 4 heavy screens meet the jank SLO on a minSdk-24 device; cold start within SLO. **Effort ~8 dev-days.**

---

## PHASE 5 — Structural / backend scale (P2)
**Objective:** raise the systemic ceiling and start the migration on schedule.

### Tasks
- **5.1 Cloud Functions tuning.** Set `minInstances` on hot triggers (chat fan-out) to kill cold starts; set `maxInstances` to protect downstream; raise concurrency. *Acceptance:* fan-out p99 stable under burst; no cold-start spikes.
- **5.2 Database sharding readiness.** Design the shard key and a routing layer so the app can split across multiple Firestore databases when writes approach 8K/s. *Acceptance:* documented sharding scheme + a dark-launched routing abstraction.
- **5.3 Multi-region placement review.** Confirm Firestore location matches the largest user clusters; plan multi-region for durability + latency. *Acceptance:* location decision documented with RTT rationale.
- **5.4 Migration Phase-B kickoff (start at ~3M registered).** Stand up AlloyDB for coins/membership (transactional), begin the GKE Autopilot WebSocket presence fleet, introduce Pub/Sub for fan-out — strangler-fig, one workload at a time. *Acceptance:* coins/membership reads/writes served by AlloyDB in canary; Firestore retained elsewhere. *(This is a separate multi-month track — see the GCP migration plan; this task only ensures it's triggered on time.)*

**Exit criteria:** load test sustains target concurrency with headroom; migration track opened with the first workload in canary. **Effort ~10 dev-days + migration program.**

---

## PHASE 6 — Regression prevention (P1, continuous)
**Objective:** keep the slowdown point at 10M, not let it silently collapse back to hundreds.

### Tasks
- **6.1 Code-review checklist (enforced).** Add to PR template: *no un-sharded counter · no un-paginated query · no shared hot doc · no un-cancelled listener · no per-keystroke write.* *Acceptance:* checklist blocks merge; reviewers trained.
- **6.2 CI performance guards.** Add static checks: fail CI on `.snapshots()` without a `.limit()` in list contexts, or writes to known counter docs outside the sharded helper. *Acceptance:* CI catches a seeded violation.
- **6.3 Monitoring & alerting live in prod.** Promote the Phase-0 dashboards + hotspot/latency alerts to production with on-call routing. *Acceptance:* alert pages on a synthetic hotspot within 5 min.
- **6.4 Recurring load test.** Run the harness before every phase-transition and on a schedule (e.g. monthly), tracking the latency curve over time. *Acceptance:* trend chart of p99 vs concurrency maintained.

**Exit criteria:** guards enforced in CI + review; prod alerting on-call; scheduled load test running. **Effort ~4 dev-days, then ongoing.**

---

## 2. Rollout & safety
- **Feature-flag** every behavioral change (presence backend swap, cache-first extensions, counter sharding reads). Roll out 1% → 10% → 50% → 100% with SLO watch at each step.
- **Canary** on a small user cohort before global; **auto-rollback** trigger tied to the SLO alerts.
- **Backfill/migration care** for counter sharding: dual-write during transition, reconcile shard sums against the old counter, then cut the read path over.
- **No big-bang.** Phases 1–4 ship as many small PRs, each with its own before/after metric.

## 3. Verification strategy
Every task carries a metric-based acceptance criterion (above). Additionally:
- **Before/after** capture in the load harness for each backend change.
- **DevTools profile** before/after for each client change on the reference device.
- **Go/no-go** at each phase exit against the SLO table in §0.

## 4. Risk register
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Hidden hotspot not found in audit | Med | High | Hot-doc alerting (0.2) catches it in prod; load test stresses it |
| Presence swap to RTDB introduces staleness | Med | Med | `onDisconnect` + 60s reconcile; feature-flag + canary |
| Counter shard read cost/complexity | Low | Med | Cache shard sums; tune N; only shard true hotspots |
| Client refactor regresses UX | Med | Med | Small PRs, canary, crash-free SLO gate |
| Migration started too late | Low | High | Trigger Phase-B at 3M, not 10M (5.4) |
| Team bandwidth | Med | Med | P0/P1 only for the 6-week window; P2 migration is separate track |

## 5. Dependencies
- Staging Firebase project + budget for load testing.
- Firebase Performance Monitoring + Cloud Monitoring enabled.
- Reference low-end Android device (minSdk 24) for profiling.
- Decision owner for the migration Phase-B trigger (ties to the approved GCP migration plan).

## 6. What to do *right now* (Gate 0 — hygiene, any scale)
These three cost almost nothing, are correct code regardless of size, and prevent the debt that would otherwise force a painful retrofit later:
1. **Phase 4.1** — cancel listeners on dispose (a correctness fix, not a scale fix).
2. **Phase 3.1** — cap every query with `.limit()` / paginate long lists.
3. **Phase 6.1** — enforce the review checklist so hotspots/leaks never merge.

**Do NOT do yet (defer to their gates):** counter sharding, RTDB presence swap, database sharding, migration, min-instances, CDN/bundles. At low scale these add complexity for zero benefit — the checklist (item 3) keeps the *option* open by preventing the anti-patterns, so you can flip each one on exactly when its trigger arrives.

---

## Appendix A — Reference code patterns

### A.1 Sharded counter (Dart / Firestore)
```dart
// Write: pick a random shard, increment it.
Future<void> incrementSharded(DocumentReference parent, {int shards = 10}) {
  final shardId = Random().nextInt(shards); // client-side random
  return parent.collection('shards').doc('$shardId')
      .set({'count': FieldValue.increment(1)}, SetOptions(merge: true));
}

// Read: sum all shards (cache the result; don't sum on every frame).
Future<int> readSharded(DocumentReference parent) async {
  final snap = await parent.collection('shards').get();
  return snap.docs.fold<int>(0, (sum, d) => sum + (d.data()['count'] as int? ?? 0));
}
```

### A.2 Presence via Realtime Database `onDisconnect`
```dart
final ref = FirebaseDatabase.instance.ref('presence/$uid');
await ref.onDisconnect().set({'online': false, 'lastSeen': ServerValue.timestamp});
await ref.set({'online': true});
// No shared document, no per-heartbeat Firestore write.
```

### A.3 Listener lifecycle in a BLoC
```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  StreamSubscription? _sub;
  ChatBloc(this._repo) : super(ChatInitial()) {
    on<ChatStarted>((e, emit) {
      _sub?.cancel();
      _sub = _repo.messages(e.chatId).listen((m) => add(ChatMessagesUpdated(m)));
    });
  }
  @override
  Future<void> close() {
    _sub?.cancel(); // <-- the fix that prevents leaked listeners
    return super.close();
  }
}
```

### A.4 Paginated query guardrail
```dart
Query messagesPage(String chatId, {DocumentSnapshot? startAfter, int limit = 30}) {
  var q = FirebaseFirestore.instance
      .collection('conversations/$chatId/messages')
      .orderBy('createdAt', descending: true)
      .limit(limit); // never unbounded
  if (startAfter != null) q = q.startAfterDocument(startAfter);
  return q;
}
```

### A.5 Debounced ephemeral write (typing)
```dart
Timer? _typingDebounce;
void onTyping(String chatId) {
  if (_typingDebounce?.isActive ?? false) return; // ≤ 1 write / interval
  _typingDebounce = Timer(const Duration(seconds: 3), () {});
  _presenceRepo.setTyping(chatId); // route to RTDB, not Firestore
}
```

---

## Appendix B — Where this plan should live
Per the GreenGo `.ai/` standard, commit this plan into the repo at `.ai/plans/performance-hardening.md` and link it from `.ai/context_base.md`, so it's versioned with the code and visible to every contributor. Track each phase as a milestone with the tasks as issues.

*Companion documents: the capacity model artifact ("How many users can GreenGo handle at once?") and `GreenGo-Cost-Revenue-Analysis.md`.*
