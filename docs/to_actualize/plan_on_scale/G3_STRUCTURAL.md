# G3 — Structural Scale

**Gate:** G3 — Structural · **Trigger:** ~3M registered (START) → 10M registered · **Peak concurrent:** ~75K–250K
**Theme:** raise the systemic ceiling and kick off the migration on schedule.
**Status:** Not started (activate at ~2.1M = 70% of the 3M trigger) · **Owner:** Eng lead + Platform squad · **Date:** 2026-07-13 · **Version:** v1

> This document is the detailed expansion of **one gate** from [`README.md`](README.md) §1 (the activation-gate table) and Phase 5 (structural / migration). It is **app-side and trigger-focused**. It does **not** duplicate the GCP migration program — the deep infra (AlloyDB provisioning, GKE platform, Pub/Sub topology, Terraform, GitOps, SLO stack) lives in [`../migration/`](../../migration/) and is referenced, not repeated, here.

---

## 1. Gate summary

| Field | Value |
|---|---|
| Registered trigger | **~3M (start)** → 10M |
| Peak concurrent | ~75K–250K |
| What activates here | (1) DB-sharding readiness · (2) migration Phase-B kickoff (AlloyDB coins/membership → GKE presence fleet → Pub/Sub fan-out) · (3) isolates for heavy client work · (4) CDN/Firestore bundles for shared content |
| Why not earlier | This is where the **~10K writes/sec single-database ceiling** comes into view. Starting at 3M means the migration is **live before 10M**, not scrambling at the wall. |
| Ceiling rationale | A single Firestore database sustains on the order of **~10K writes/sec** steady-state. Our SLO alert (README §0) fires at **>8,500 writes/sec per database**. At 75K–250K concurrent — with chat, presence, coins, events, tags in the mix — a single DB approaches that ceiling. G3 raises it by (a) splitting the write domain across databases (sharding readiness) and (b) moving the transactional money domain off Firestore entirely (AlloyDB). |

The migration program numbers the money-domain move **P4** (see [`../migration/00-overview.md`](../../migration/00-overview.md) §5). The scale plan calls the whole migration track **"Phase-B."** They are the same track — this gate is the **trigger and app-side seam** for it; the migration docs are the **execution runbook**.

---

## 2. When to activate / DONE

- **Activate** structural work when registered users cross **~2.1M** (70% of the 3M trigger), so the first AlloyDB canary and the sharding routing seam are dark-launched *before* 3M and battle-tested well before 10M.
- **The ~10K writes/sec ceiling is the reason this gate exists.** Below ~1M (G2) the correct move is to *de-hotspot* individual documents (sharded counters, presence off Firestore) — see [`G2_DE_HOTSPOT.md`](G2_DE_HOTSPOT.md). That buys headroom on a **single** database. G3 is what you do when de-hotspotting is no longer enough because the **aggregate** write rate — not any one doc — is approaching the per-database limit.
- **DONE when:** the load harness sustains **250K-concurrent-equivalent** with headroom; coins/membership are served by AlloyDB in a canary cohort behind the *existing* repository interface; a GKE WebSocket presence fleet handles a target socket count; Pub/Sub carries at least one fan-out workload; and the client offloads heavy parse/geo/decode work off the UI isolate. Hand off to [`G4_DISTRIBUTED.md`](G4_DISTRIBUTED.md).

---

## 3. Objectives & SLOs

Inherit the SLO table in [`README.md`](README.md) §0. G3 adds/tightens these:

| Objective | Target | Alert |
|---|---|---|
| Sustain peak concurrent with headroom | 75K–250K concurrent, ≥30% write headroom | headroom < 15% |
| Writes/sec **per database** | **< 7,000 sustained** | > 8,500 (approach ceiling) |
| Message-send p95 through the transition | < 300 ms (unchanged) | p99 > 1.2 s |
| Feed / discovery p95 through the transition | < 500 ms (unchanged) | > 1 s |
| Coins/membership correctness on AlloyDB | 100% ledger parity vs Firestore in dual-write | any reconciliation diff |
| Presence fleet | target concurrent sockets, < 60 s staleness | socket drop storms |

**Guiding constraint:** the migration must not move an SLO the wrong way. Every workload cutover is a canary with the SLO table as the go/no-go, and a Remote Config rollback that flips a cohort back in seconds.

---

## 4. Prerequisites (G0 + G1 + G2 complete)

**Do not start G3 before G0–G2 are done.** Restructuring on top of un-fixed hotspots just moves the pain across a database boundary.

| Prereq | Why it must land first | Source |
|---|---|---|
| **G0 hygiene** — listeners cancelled, queries capped, review checklist | Sharding/routing changes touch every repository; leaks and unbounded reads would multiply across shards | README §1 (G0), Phase 4.1 / 3.1 / 6.1 |
| **G1 observe & throttle** — dashboards, high-churn writes debounced, cache-first on hot reads | You cannot pick a shard key or trigger a cutover without the writes/sec-per-collection dashboard | README §1 (G1), Phase 0 / 2 |
| **G2 de-hotspot** — counters sharded, presence/typing off shared docs, **load-test harness live** | The harness is the *only* way to prove 250K-concurrent headroom; de-hotspotted writes are the precondition for measuring true aggregate write rate | [`G2_DE_HOTSPOT.md`](G2_DE_HOTSPOT.md), README Phase 1 / 0.7 |

The **load-test harness (README Phase 0.7)** is the load-bearing prerequisite: G3's verification (§8) depends on it reproducing the realistic ops mix (45% chat+presence, 25% discovery, 12% events, 8% coins, 6% tags, 4% TTS) at target concurrency.

---

## 5. Tasks

### 5.1 Database-sharding readiness (shard key + routing abstraction, dark-launched)

**Objective:** be able to split the write domain across multiple Firestore databases when writes approach ~8K/s per DB — **without touching feature code.** This is *readiness*, not activation: the routing layer ships dark (single-DB mapping) and is flipped on only when the dashboard shows the ceiling approaching.

**Concrete steps:**
1. **Choose the shard key.** Evaluate against the real write distribution from the G1 dashboard:

   | Shard-key option | Pro | Con | Fit |
   |---|---|---|---|
   | **`userId` hash** (e.g. `crc32(userId) % N`) | Even spread; a user's coins/profile/tags co-locate on one DB | Cross-user ops (chat between users on different shards) need care | **Primary** for per-user data (coins, membership, profile, tags) |
   | **`conversationId` hash** | Co-locates a whole conversation's messages/inbox | Group chats span many users | For messaging/inbox collections |
   | **Geographic / region** | Aligns with multi-region later | Uneven population; hot regions | Defer to G4 multi-region |

   Recommendation: **`userId`-hash for per-user domains, `conversationId`-hash for messaging.** Both are stable, high-cardinality, and already the natural partition of the data model.

2. **Introduce a Firestore-instance provider seam.** Today every data source is handed a single `FirebaseFirestore` via `get_it` — e.g. [`lib/core/di/injection_container.dart`](../../../lib/core/di/injection_container.dart) L664–669 constructs `CoinRemoteDataSource(firestore: sl(), …)`. Insert a `ShardedFirestoreProvider` that returns the correct `FirebaseFirestore` instance for a shard key, and register data sources against it instead of the raw singleton. In dark-launch mode the provider always returns the default instance, so behavior is byte-identical.

3. **Route at the data-source layer, not the repository layer.** The repository interfaces (e.g. [`lib/features/coins/domain/repositories/coin_repository.dart`](../../../lib/features/coins/domain/repositories/coin_repository.dart)) already take `userId` on every method — the shard key is *already in the signature*. The `*RemoteDataSource` resolves `provider.forUser(userId)` before each collection reference. No feature/BLoC/use-case code changes.

4. **Dual-write / dark-launch validation.** For a canary cohort, dual-write to both the default DB and the target shard DB, and reconcile. Flip reads over per cohort via Remote Config once parity holds. Keep the rollback flag.

**Acceptance:** documented shard scheme (key per domain, `N`, rebalancing note) + a `ShardedFirestoreProvider` merged and dark-launched (default mapping), with a canary cohort dual-writing and reconciling clean.
**Effort:** ~6 dev-days (provider + DI rewire + reconciliation job). **Risk:** Med — cross-shard operations (cross-user chat) must be designed to not assume co-location.

---

### 5.2 Migration Phase-B kickoff (strangler-fig, one workload at a time)

**Objective:** open the migration track on schedule and move the **first** workload behind the *existing* app abstractions. This task **only guarantees the trigger and the app-side seam** — the infra depth lives in the migration docs.

**Strangler-fig order (do NOT parallelize the cutovers):**

| Order | Workload | New home | App-side seam | Migration runbook |
|---|---|---|---|---|
| **1st** | **Coins / membership / subscriptions (ledger)** | **AlloyDB Postgres** (ACID) | Swap the `*RemoteDataSource` behind the existing repo interface | [`../migration/00-overview.md`](../../migration/00-overview.md) P4; [`02-target-architecture.md`](../../migration/02-target-architecture.md) §3.2; [`04-data-migration.md`](../../migration/04-data-migration.md); [`adr/0002-alloydb-for-relational.md`](../../migration/adr/0002-alloydb-for-relational.md) |
| **2nd** | **Presence / realtime presence fleet** | **GKE Autopilot WebSocket fleet** + Redis presence | Swap `PresenceService` transport | [`06-gke-platform.md`](../../migration/06-gke-platform.md); [`adr/0003-gke-autopilot.md`](../../migration/adr/0003-gke-autopilot.md) |
| **3rd** | **Fan-out / notifications** | **Pub/Sub** in front of existing Firestore fan-out | Server-side (Cloud Functions → Pub/Sub consumer); no client change | [`adr/0004-pubsub-event-backbone.md`](../../migration/adr/0004-pubsub-event-backbone.md); [`04-data-migration.md`](../../migration/04-data-migration.md) |

**Why coins first:** it is the highest-value, most-bounded, most-obviously-wrong-on-Firestore domain (duplicate schemas `coinTransactions`/`coin_transactions`, `coinBalances`/`coin_balances` per [`../migration/00-overview.md`](../../migration/00-overview.md) §1; ledgers demand ACID). And critically, GreenGo's Clean-Arch seam makes it a **drop-in swap**:

- Interface: [`lib/features/coins/domain/repositories/coin_repository.dart`](../../../lib/features/coins/domain/repositories/coin_repository.dart)
- Impl (pure delegation, no Firestore logic of its own): [`lib/features/coins/data/repositories/coin_repository_impl.dart`](../../../lib/features/coins/data/repositories/coin_repository_impl.dart)
- Firestore-bound data source (the **only** thing that touches `coinBalances` / `coinTransactions` / `coinGifts`): [`lib/features/coins/data/datasources/coin_remote_datasource.dart`](../../../lib/features/coins/data/datasources/coin_remote_datasource.dart)
- Same shape for membership ([`lib/features/membership/data/datasources/membership_remote_datasource.dart`](../../../lib/features/membership/data/datasources/membership_remote_datasource.dart) — already an `abstract class`, redemption already via a `redeemCoupon` **callable**) and subscriptions ([`lib/features/subscription/data/datasources/subscription_remote_datasource.dart`](../../../lib/features/subscription/data/datasources/subscription_remote_datasource.dart)).

**Concrete steps:**
1. Introduce `CoinAlloyDataSource implements` the same data-source contract, calling the `payments/coins-ledger` GKE service instead of Firestore. Register it in [`injection_container.dart`](../../../lib/core/di/injection_container.dart) L664 behind a Remote Config flag; `CoinRepositoryImpl` is unchanged.
2. **Dual-write window:** the ledger service writes AlloyDB (source of truth) and mirrors the balance to Firestore ([`02-target-architecture.md`](../../migration/02-target-architecture.md) §3.2 shows exactly this sequence), so any not-yet-migrated read path still works.
3. **Backfill + reconcile** historical coin data (Dataflow) per [`04-data-migration.md`](../../migration/04-data-migration.md); prove parity before flipping the read path.
4. **Cohort cutover** via Remote Config (already in the app, see [`lib/core/services/feature_flags_service.dart`](../../../lib/core/services/feature_flags_service.dart)); 1% → 10% → 50% → 100% with SLO watch.
5. **Then** presence (§5.3-adjacent — move [`lib/core/services/presence_service.dart`](../../../lib/core/services/presence_service.dart) off its direct `profiles/{uid}` Firestore write to the WS fleet / Redis), **then** Pub/Sub fan-out. One at a time; each with its own canary and rollback.

**Acceptance:** coins/membership reads+writes served by AlloyDB for a canary cohort behind the unchanged `CoinRepository`; Firestore retained elsewhere; dual-write reconciliation clean; rollback flag verified.
**Effort:** app-side seam ~5 dev-days per workload; **the migration itself is a multi-month program** (see [`../migration/10-phased-roadmap.md`](../../migration/10-phased-roadmap.md)). This task owns the *trigger + seam*, not the whole program.
**Risk:** **High** (money domain) — mitigated by dual-write + reconciliation + cohort cutover; never a flag day.

---

### 5.3 Isolates for heavy client work

**Objective:** keep the UI isolate free of jank-inducing CPU work at scale. Audit confirms **`compute()` is currently used nowhere in `lib/`** — all parse/geo/decode runs on the UI isolate today. This is the app-side lever that keeps the client fast independent of backend load (README Phase 4.4).

**Heavy-work sites to offload (real, cited):**

| Site | Work | Offload |
|---|---|---|
| [`lib/features/events/data/datasources/external_events_data_source.dart`](../../../lib/features/events/data/datasources/external_events_data_source.dart) | `Future.wait` over 9 geohash bound queries, then filter + **sort by `GeoQuery.distanceMeters`** across the merged result | `compute()` the merge/distance-sort |
| [`lib/core/utils/geo_query.dart`](../../../lib/core/utils/geo_query.dart) | Geohash `encode` / `queryBounds` bounding-box math (bit ops, `log2`, trig) | Batch encodes via `compute()` when processing large event/candidate lists |
| [`lib/features/matching/domain/usecases/feature_engineer.dart`](../../../lib/features/matching/domain/usecases/feature_engineer.dart) | Match feature engineering (uses geohash math) | Run scoring off the UI isolate |
| [`lib/features/events/data/services/events_cache_service.dart`](../../../lib/features/events/data/services/events_cache_service.dart) | `jsonDecode` of the cached feed + `EventModel.fromJson` mapping | `compute()` the decode+map for large feeds |
| [`lib/core/services/cache_service.dart`](../../../lib/core/services/cache_service.dart) | `jsonDecode` of cached payloads | `compute()` for large payloads |
| Image decode (list thumbnails, chat media) | Decode on UI thread | `cached_network_image` + `memCacheWidth`/`decode` off-thread (README Phase 4.2) |

**Concrete steps:** wrap each above in `compute(topLevelFn, args)` where the payload is large enough to matter (small lists stay inline — an isolate spawn has its own cost); measure UI-thread stalls in DevTools before/after on the minSdk-24 reference device.
**Acceptance:** no UI-thread stall > 16 ms during those operations on the reference device (README Phase 4.4).
**Effort:** ~4 dev-days. **Risk:** Low — arguments must be primitives/`Map`/`List` (isolate message constraints); wrap only large payloads.

---

### 5.4 CDN / Firestore bundles for shared content

**Objective:** serve identical-across-users content **once per client per TTL**, not once per view — trending, featured, static config. Audit confirms **no `loadBundle`/`namedQuery` usage today**; the app already has the right *instinct* in the per-user daily cache ([`events_cache_service.dart`](../../../lib/features/events/data/services/events_cache_service.dart), SharedPreferences, `cachedAtDay` stamp) — G3 generalizes it to shared content served from a CDN edge or Firestore bundle.

**Shared-content candidates:**

| Content | Today | G3 |
|---|---|---|
| Trending / featured feeds | Per-user Firestore reads | **Firestore bundle** built by a scheduled function, served via **Cloud CDN**; client `loadBundle` + `namedQuery` |
| Static config / `app_config` (read by [`lib/core/services/pronunciation_service.dart`](../../../lib/core/services/pronunciation_service.dart), [`lib/core/services/access_control_service.dart`](../../../lib/core/services/access_control_service.dart)) | Firestore doc read | CDN-fronted JSON with a TTL; Remote Config for flags via [`feature_flags_service.dart`](../../../lib/core/services/feature_flags_service.dart) |
| Events feed first page | Per-day SharedPreferences cache (good) | Extend to a bundle for the *shared* (non-personalized) slice |

**Concrete steps:** build the bundle server-side (Cloud CDN cacheable GET — [`02-target-architecture.md`](../../migration/02-target-architecture.md) §2.1), `loadBundle` on the client, read via `namedQuery` so a repeat view does **zero** backend reads within TTL. Keep the existing per-user cache for personalized slices.
**Acceptance:** shared content read once per client per TTL, not per view; backend reads/MAU for these feeds flat (README Phase 3.4).
**Effort:** ~4 dev-days. **Risk:** Low.

---

## 6. Reference material

### 6.1 Shard-key + routing abstraction sketch (Dart repository seam)

The shard key is **already in every repository signature** (`userId`). We insert routing at the data-source construction seam — no feature code changes.

```dart
// core/data/sharded_firestore_provider.dart  (NEW)
class ShardedFirestoreProvider {
  ShardedFirestoreProvider(this._instances, {this.enabled = false});
  final List<FirebaseFirestore> _instances; // [default] while dark-launched
  final bool enabled;                        // Remote Config flag

  FirebaseFirestore forUser(String userId) {
    if (!enabled) return _instances.first;   // dark-launch: single DB, no-op
    final shard = userId.hashCode.abs() % _instances.length; // stable per user
    return _instances[shard];
  }
  FirebaseFirestore forConversation(String conversationId) {
    if (!enabled) return _instances.first;
    return _instances[conversationId.hashCode.abs() % _instances.length];
  }
}

// coin_remote_datasource.dart  — resolve the shard per call instead of a fixed field.
class CoinRemoteDataSource {
  CoinRemoteDataSource({required this.provider, required this.inAppPurchase});
  final ShardedFirestoreProvider provider;
  final InAppPurchase inAppPurchase;

  CollectionReference _balances(String userId) =>
      provider.forUser(userId).collection('coinBalances'); // was: firestore.collection(...)
}
```
DI rewire (single line in [`injection_container.dart`](../../../lib/core/di/injection_container.dart) L664): pass `provider: sl<ShardedFirestoreProvider>()` instead of `firestore: sl()`.

### 6.2 Offloading a heavy parse/sort to an isolate

```dart
// Top-level (isolate entrypoint must be a top-level or static fn).
List<Map<String, dynamic>> _decodeAndSort(_GeoPayload p) {
  final events = (jsonDecode(p.raw) as List).cast<Map<String, dynamic>>();
  events.sort((a, b) => GeoQuery
      .distanceMeters(p.lat, p.lng, a['lat'], a['lng'])
      .compareTo(GeoQuery.distanceMeters(p.lat, p.lng, b['lat'], b['lng'])));
  return events; // primitives only — safe to cross the isolate boundary
}

// In the data source (e.g. external_events_data_source.dart / events_cache_service.dart):
final sorted = await compute(_decodeAndSort, _GeoPayload(raw, lat, lng));
```
Wrap **only large payloads** — spawning an isolate for a 5-item list costs more than it saves.

### 6.3 Firestore bundle usage note

Build the bundle server-side (scheduled function) for shared content; on the client:
```dart
await FirebaseFirestore.instance.loadBundle(bundleBytes); // fetched via Cloud CDN
final trending = await FirebaseFirestore.instance
    .namedQuery('trending')          // named in the bundle
    .get(const GetOptions(source: Source.cache)); // zero backend reads within TTL
```
Keep the existing per-user SharedPreferences cache ([`events_cache_service.dart`](../../../lib/features/events/data/services/events_cache_service.dart)) for **personalized** slices; bundles are for the **shared** slice only.

> **Infra depth (Terraform, GKE manifests, AlloyDB schema, Pub/Sub topology) is intentionally NOT reproduced here.** See [`../migration/05-iac-terraform.md`](../../migration/05-iac-terraform.md), [`../migration/06-gke-platform.md`](../../migration/06-gke-platform.md), [`../migration/04-data-migration.md`](../../migration/04-data-migration.md), and [`terraform/main.tf`](../../../terraform/main.tf).

---

## 7. Rollout & safety

- **Strangler-fig, one workload at a time.** Coins/membership → AlloyDB first; presence fleet second; Pub/Sub fan-out third. Never two cutovers in flight.
- **Dual-write + reconciliation** for the money domain: AlloyDB is source of truth, Firestore mirrored during the window, reconciled continuously; read path flips only after parity holds ([`../migration/04-data-migration.md`](../../migration/04-data-migration.md)).
- **Canary per workload** via Remote Config cohorts ([`feature_flags_service.dart`](../../../lib/core/services/feature_flags_service.dart)): 1% → 10% → 50% → 100%, SLO-watched at each step.
- **Sharding routing dark-launched** (default single-DB mapping) and validated by canary dual-write before `enabled` is flipped.
- **Rollback:** every step has a Remote Config flag that reverts a cohort to the Firestore path in seconds. Reversible by default ([`../migration/00-overview.md`](../../migration/00-overview.md) §3).

---

## 8. Verification

| Check | Method | Pass |
|---|---|---|
| Sustains target concurrency with headroom | Load harness (README Phase 0.7) at **250K-concurrent-equivalent** with the realistic ops mix | writes/sec/DB < 7,000; message-send & feed p95 within SLO; ≥30% write headroom |
| AlloyDB canary serves coins/membership correctly | Cohort cutover + continuous reconciliation vs Firestore mirror | 100% ledger parity; zero reconciliation diffs; coin-spend p95 within SLO |
| Presence fleet handles target sockets | Load-test the GKE WS fleet | target concurrent sockets held; presence staleness < 60 s |
| No UI-thread stall on heavy work | DevTools profile on minSdk-24 device, before/after | no stall > 16 ms during geo-sort / JSON decode / image decode |
| Shared content served from bundle/CDN | Instrument reads/MAU on trending/featured/config | read once per client per TTL, not per view |

---

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Dual-system consistency** (Firestore mirror vs AlloyDB ledger drift) | Med | High | AlloyDB = source of truth; continuous reconciliation; read-flip only after parity; ledger is append-only |
| **Migration started too late** (hit ceiling before AlloyDB is live) | Low | High | Trigger at **3M, not 10M**; begin app-side seam at 2.1M (70%); ceiling alert at 8,500 writes/s/DB is the early warning |
| **Cross-shard operations** assume co-location (cross-user chat) | Med | Med | `conversationId`-hash for messaging; design cross-shard ops explicitly; dark-launch validates before flip |
| **Cost** of running dual systems + AlloyDB + GKE during transition | Med | Med | Strangler-fig one workload at a time bounds spend; FinOps per [`../migration/11-cost-finops.md`](../../migration/11-cost-finops.md); decommission legacy per workload |
| **Isolate argument constraints** break heavy-work offload | Low | Low | Pass only primitives/`Map`/`List`; keep small payloads inline |
| **Presence swap staleness** on WS-fleet cutover | Med | Med | Redis presence + reconcile; canary + Remote Config rollback |

---

## Trade-offs — What this gate adds and what it costs

### ✅ What you gain
- **Features / UX:** the money domain (coins, membership, subscriptions) gains **true transactional integrity** on AlloyDB — atomic balance checks + ledger inserts (see [`02-target-architecture.md`](../../migration/02-target-architecture.md) §3.2 spend-coins sequence), replacing best-effort Firestore document writes and the duplicate schemas (`coinTransactions`/`coin_transactions`) that make reconciliation fragile today. Users get correct balances under concurrency; disputes become auditable.
- **Performance:** you **break the ~10K writes/sec single-database ceiling** — the whole reason this gate exists. Sharding readiness splits the write domain across databases and AlloyDB removes the money domain's writes from Firestore entirely, restoring write headroom. Client-side, isolates make the 9-way geohash fan-out + distance-sort in [`external_events_data_source.dart`](../../../lib/features/events/data/datasources/external_events_data_source.dart) and [`geo_query.dart`](../../../lib/core/utils/geo_query.dart) (where `compute()` is used **nowhere today**) run without UI-thread stalls; CDN/bundles cut per-view reads on shared content to once-per-TTL.
- **Functionality / capability headroom:** the GKE Autopilot WebSocket presence fleet offloads presence/chat from Firestore document writes ([`presence_service.dart`](../../../lib/core/services/presence_service.dart) currently writes `isOnline`/`lastSeen` straight to `profiles/{uid}`), and Pub/Sub gives buffered, replayable fan-out. This is the capacity to actually stand behind a "10M+" claim.

### ⚠️ What you give up / the costs
- **Complexity & maintenance:** you now operate **two backends** (Firestore + AlloyDB/GKE) with **dual-write and hybrid consistency** to manage, monitor, and reconcile — a permanent step-up in operational surface versus the Firebase-native monolith.
- **Performance or UX regressions in specific paths:** you trade Firestore's built-in real-time listeners + offline sync on presence/chat for **WebSocket infra you must run and monitor**; a poorly-tuned WS fleet or Redis presence layer can be *staler or flakier* than the Firestore path it replaces until it's hardened (mitigated by the 60 s reconcile + canary).
- **Feature/behavior changes required:** the **117 files (246 occurrences) that call `FirebaseFirestore.instance` directly** must be funnelled through the DI shard seam (`ShardedFirestoreProvider`) before sharding can be flipped on — until then those call sites are un-shardable. Cross-user operations (chat between users on different `userId` shards) must stop assuming co-location.
- **Engineering cost / dependencies:** this is a **multi-month program**, not a sprint — the deep execution lives in [`../migration/`](../../migration/) (P4 money-domain, GKE platform, Pub/Sub backbone). AlloyDB + GKE Autopilot run **24/7 at real cost** (see [`11-cost-finops.md`](../../migration/11-cost-finops.md)), and each strangler-fig cutover implies a **feature-slowdown or freeze window** for the domain being moved.

### Net verdict
This gate is **unavoidable to pass ~10M** — the single-DB write ceiling is a hard wall, and the money domain genuinely becomes *more correct* on AlloyDB, not just more scalable. It is also the gate where **architectural complexity and run-cost jump sharply**: you go from one managed backend to a hybrid you own end-to-end. The strangler-fig discipline (one workload at a time, dual-write, reconcile, cohort canary, seconds-to-rollback) is precisely what keeps that jump from being a risky big-bang. Skipping G3 doesn't save the complexity — it just means hitting the write ceiling with no escape hatch and stalling growth short of 10M.

---

## 10. Exit criteria → hand-off to G4

G3 is complete when **all** hold:

1. Load harness sustains **250K-concurrent-equivalent** with ≥30% write headroom; all latency SLOs green through the transition.
2. **Sharding routing seam merged and dark-launched**, with a canary cohort proven via dual-write + clean reconciliation.
3. **Coins/membership served by AlloyDB** for a canary cohort behind the unchanged `CoinRepository`; Firestore retained elsewhere; rollback verified.
4. **GKE WebSocket presence fleet** live for a cohort; **Pub/Sub** carries ≥1 fan-out workload.
5. Heavy client work (geo-sort, JSON decode, image decode) runs **off the UI isolate**; shared content served from **bundle/CDN**.

→ Hand off to [`G4_DISTRIBUTED.md`](G4_DISTRIBUTED.md): flip sharding routing `enabled`, complete the migration, full GKE WS fleet, multi-region. G4 is only justified **past** the single-DB ceiling that G3 was built to defer.

---

## 11. Cross-references

- [`README.md`](README.md) — the gate table (§1) and Phase 5 (structural / migration) this document expands.
- [`G2_DE_HOTSPOT.md`](G2_DE_HOTSPOT.md) — the prerequisite gate (de-hotspot single-DB writes + load harness).
- [`G4_DISTRIBUTED.md`](G4_DISTRIBUTED.md) — the next gate (multi-DB sharding active, migration complete, multi-region).
- **Migration program (deep infra — referenced, not duplicated):**
  - [`../migration/00-overview.md`](../../migration/00-overview.md) · [`02-target-architecture.md`](../../migration/02-target-architecture.md) · [`04-data-migration.md`](../../migration/04-data-migration.md) · [`05-iac-terraform.md`](../../migration/05-iac-terraform.md) · [`06-gke-platform.md`](../../migration/06-gke-platform.md) · [`10-phased-roadmap.md`](../../migration/10-phased-roadmap.md) · [`11-cost-finops.md`](../../migration/11-cost-finops.md)
  - ADRs: [`0001-hybrid-strangler-fig`](../../migration/adr/0001-hybrid-strangler-fig.md) · [`0002-alloydb-for-relational`](../../migration/adr/0002-alloydb-for-relational.md) · [`0003-gke-autopilot`](../../migration/adr/0003-gke-autopilot.md) · [`0004-pubsub-event-backbone`](../../migration/adr/0004-pubsub-event-backbone.md)
  - [`terraform/main.tf`](../../../terraform/main.tf)
- **App-side seams cited:** [`lib/core/di/injection_container.dart`](../../../lib/core/di/injection_container.dart) · [`lib/features/coins/domain/repositories/coin_repository.dart`](../../../lib/features/coins/domain/repositories/coin_repository.dart) · [`lib/features/coins/data/repositories/coin_repository_impl.dart`](../../../lib/features/coins/data/repositories/coin_repository_impl.dart) · [`lib/features/coins/data/datasources/coin_remote_datasource.dart`](../../../lib/features/coins/data/datasources/coin_remote_datasource.dart) · [`lib/core/services/presence_service.dart`](../../../lib/core/services/presence_service.dart) · [`lib/core/utils/geo_query.dart`](../../../lib/core/utils/geo_query.dart) · [`lib/features/events/data/datasources/external_events_data_source.dart`](../../../lib/features/events/data/datasources/external_events_data_source.dart) · [`lib/features/events/data/services/events_cache_service.dart`](../../../lib/features/events/data/services/events_cache_service.dart)
