# G4 — Distributed (the terminal gate)

**Trigger:** ~10M+ registered · **Peak concurrent:** 250K+ (up to 25M+ at 1B registered)
**Theme:** the fully-distributed configuration that carries 25M+ concurrent to 1B registered.
**Status:** Not started — activates past the single-DB Firestore ceilings · **Date:** 2026-07-13 · **Version:** v1
**Stack today:** Flutter (Clean Arch + BLoC) · Firestore + Cloud Functions + FCM
**Stack at this gate:** multi-database Firestore + AlloyDB shards · GKE Autopilot WebSocket fleet · Pub/Sub · multi-region

> This is the detailed expansion of gate **G4** from [`README.md`](README.md) §1. It **operationalizes at full scale** the infrastructure designed in the GCP migration program — it references that program, it does not duplicate it. Deep IaC/GKE/AlloyDB detail lives in [`../migration/`](../migration/) and is cited inline. No secrets in this document.
>
> G4 is the *terminal* gate. There is no "G5". "Done" here does not mean a shipped feature set — it means **sustained SLOs at target scale** with steady-state operations and recurring capacity reviews.

---

## 1. Gate summary

| | |
|---|---|
| **Registered trigger** | ~10M+ (begin at ~7M — 70% per the README activation rule) |
| **Peak concurrent envelope** | 250K → 25M+ |
| **What activates** | (1) multi-database sharding **ACTIVE**, (2) full GKE WebSocket presence/chat fleet, (3) multi-region + global data placement + regional failover + committed-use cost optimization |
| **Depends on** | G0–G3 complete; migration Phase-B live; routing abstraction dark-launched |
| **Companion migration phases** | Phase **P6** (realtime scale-out) and **P7** (Americas region + DR + decommission) in [`../migration/10-phased-roadmap.md`](../migration/10-phased-roadmap.md) |

---

## 2. When to activate — the two single-DB ceilings

G4 is the only gate justified by hitting a **hard platform ceiling**, not by a soft latency trend. Two Firestore-per-database limits define it:

| Ceiling | Value | Consequence at GreenGo scale |
|---|---|---|
| **Sustained writes/sec per database** | ~10,000 writes/s | At 250K concurrent with the README ops mix (45% chat+presence), aggregate write demand exceeds a single database even after G1–G2 de-hotspotting and G3 write-pressure reduction. |
| **Concurrent snapshot listeners per database** | ~1,000,000 | GreenGo's realtime model (chat streams, presence, feeds) is listener-heavy. Past ~1M simultaneous listeners a single Firestore database cannot fan out; this is the wall the GKE WebSocket fleet exists to climb over. |

The README SLO table already alerts at **writes/sec per database > 8,500** (approaching the ceiling). **That alert firing sustained is the objective trigger to declare G4 active.** Below these ceilings, the G3 single-primary + dark-launched router is the *correct* configuration — do not activate multi-DB sharding early; it multiplies cost and cross-shard query complexity for zero benefit.

**"DONE" (terminal):** G4 is never "finished"; it reaches **steady state** when the SLOs in §3 hold at target concurrency with headroom across every shard and region, failover drills pass, and cost/MAU trends down. Ongoing = quarterly capacity + CUD reviews (§10).

---

## 3. Objectives & SLOs

| Objective | Target | Alert |
|---|---|---|
| Sustain peak concurrent | 250K → 25M+ with headroom per region and per shard | Any region/shard > 70% of its proven ceiling |
| Per-shard writes/sec | < 7,000 sustained per Firestore DB / per AlloyDB shard (README comfort band) | > 8,500 on any single shard → rebalance |
| Concurrent listeners per Firestore DB | < 700K (leave 30% headroom under the 1M ceiling) | > 800K on any DB |
| WebSocket connections per GKE node | within the sized per-node cap (§5.2) | node > 80% of cap → scale out |
| Per-region API latency (p95) | < 400 ms in every active region (ADR-0005 threshold) | > 400 ms sustained for any region |
| Message-send p95 / p99 | < 300 ms / < 800 ms (README §0, held at scale) | p99 > 1.2 s |
| Regional failover (RTO/RPO) | RTO ≤ target, RPO ≤ target, proven by game day (P7) | any drill miss |
| **Cost per MAU** | **trending down** toward the capacity-model ~$0.009 marginal target; migration FinOps models ~$0.024–0.042/MAU optimized ([`../migration/11-cost-finops.md`](../migration/11-cost-finops.md) §7.1) | per-MAU flat or rising quarter-over-quarter |

The load-bearing cost signal is **direction, not the point value** — cost per MAU must *fall* as fixed overhead amortizes and CUDs cover the predictable baseline (migration FinOps §7).

---

## 4. Prerequisites (state explicitly)

G4 must not begin until all of the following hold. If any is missing, the corresponding earlier gate or migration phase is the blocker — do that first.

- **G0–G3 complete.** Hygiene (listeners cancelled, queries capped), de-hotspotting (sharded counters, presence off the shared doc), structural readiness (shard key + routing abstraction) are all live. See [`README.md`](README.md) §1 and the sibling **`G3_STRUCTURAL.md`**.
- **Migration Phase-B live.** AlloyDB serves coins/membership in production (P4 complete), Pub/Sub is the event backbone (P3), and at least one domain runs on GKE Autopilot (P2). Per [`../migration/10-phased-roadmap.md`](../migration/10-phased-roadmap.md).
- **Routing abstraction dark-launched.** The G3 shard-router (README Phase 5.2 — "documented sharding scheme + a dark-launched routing abstraction") is deployed and returns the correct shard for every key **while still resolving to the single primary**. G4 flips it from single-target to N-target; it does not build it.
- **Observability at target fidelity.** Per-shard and per-region dashboards + SLOs from [`../migration/08-observability-slo.md`](../migration/08-observability-slo.md) are live, with the README hotspot/latency alerts promoted to prod (Phase 6.3).

---

## 5. Tasks

Each subsection: **Objective · Steps (real paths/infra) · Acceptance · Effort · Risk.**

### 5.1 Activate multi-database sharding

**Objective:** turn the G3 dark-launched router from single-target to **N live Firestore databases and/or AlloyDB shards**, so no single database carries more than its comfort-band writes/sec or listener count.

**Steps**
- The seam the router plugs into is already Clean-Arch-clean: every feature's remote access goes through an **abstract data source** — e.g. `abstract class ChatRemoteDataSource` in `lib/features/chat/data/datasources/chat_remote_datasource.dart`, `coin_remote_datasource.dart`, `discovery_remote_datasource.dart`, etc. Impls (`lib/features/chat/data/repositories/chat_repository_impl.dart`) never see Firestore directly — they hold a datasource. **This is the injection point.**
- **The one real hazard:** there are **246 direct `FirebaseFirestore.instance` references across 117 files in `lib/`** plus singleton services in `lib/core/services/` (`presence_service.dart`, `candidate_pool_service.dart`, `activity_tracking_service.dart`, …). G3 must have already funnelled these through the DI container (`lib/core/di/injection_container.dart`) so a **shard-aware `FirebaseFirestore` provider** is injected in one place. Confirm zero un-routed `FirebaseFirestore.instance` calls remain before flipping. If any remain, they will silently keep hitting the primary and become hotspots — this is the top pre-flip audit item.
- Server-side, the router lives in the GKE domain services (`messaging`, `profile/discovery`, `groups`, `notifications` per [`../migration/02-target-architecture.md`](../migration/02-target-architecture.md) §2.3). The client sends logical keys; services resolve `key → shard`. Prefer server-side resolution so shard topology is not baked into shipped app binaries.
- **Shard key:** partition by a stable high-cardinality entity (userId for per-user data: presence, inbox, feeds; conversationId for chat; groupId for group fan-out). Chat messages already write to auto-ID subcollections (`conversations/{id}/messages`) — naturally distributable; shard at the conversation/DB level, never per-message.
- **Rebalancing:** use consistent-hashing / virtual-node ranges so adding shard N+1 moves ~1/N of keys, not all of them. Dual-read (new shard, fall back to old) during a key's move window; cut the write path last.
- **Cross-shard queries:** GreenGo has few true cross-shard reads because most reads are per-user or per-conversation (single shard by construction). For the exceptions — global discovery, admin, analytics — **do not** scatter-gather across N Firestore DBs. Route them to the analytics/AlloyDB plane: `analytics` → BigQuery (`greengo_analytics`), global discovery → AlloyDB + Vertex Vector Search (migration P5), leaderboards → Memorystore Redis sorted sets. This keeps Firestore queries single-shard.

**Acceptance:** load harness at target concurrency shows **no single Firestore DB > 7,000 writes/s and no DB > 700K listeners**; adding a shard rebalances ≤ ~1/N of keys with zero message/coin loss; **zero un-routed `FirebaseFirestore.instance` calls** in a codebase grep.
**Effort:** L (multi-sprint). **Risk:** High — cross-shard consistency + the 246-callsite funnel (117 files).

### 5.2 Full GKE WebSocket presence/chat fleet cutover

**Objective:** move presence and realtime chat delivery **fully off Firestore listeners** onto the GKE Autopilot WebSocket fleet, breaking the ~1M-listener-per-DB ceiling.

**Steps**
- Today presence is Firestore-doc based: `lib/core/services/presence_service.dart` writes `isOnline`/`lastSeen` to the user profile doc on a 1-min activity timer. G2 already moved the shared hot path off Firestore; G4 completes the cutover to the **Memorystore Redis presence bitmaps + GKE WebSocket** tier from [`../migration/02-target-architecture.md`](../migration/02-target-architecture.md) §2.5 and the optional WS tier in migration **P6**.
- Client seam: `PresenceService` and the chat streams (`getMessagesStream` in `chat_repository_impl.dart`) swap their transport from `.snapshots()` to a WebSocket channel behind the **same repository interface** — BLoCs and UI are untouched (that is the point of the Clean-Arch seam). Gate the swap behind a Remote Config flag for cohort cutover.
- **Autoscaling:** HPA + VPA on the WS deployment ([`../migration/06-gke-platform.md`](../migration/06-gke-platform.md)); scale on **active connection count and CPU**, not just CPU — WebSocket pods are memory/FD-bound, not CPU-bound. PodDisruptionBudgets so rolling updates never drain more than a safe fraction of connections at once.
- **Connection limits per node:** size a per-pod connection cap (file descriptors, memory per connection, heartbeat overhead) and let Autopilot add pods past it. Sticky routing via the Global LB + session affinity; graceful drain + client auto-reconnect with backoff on pod recycle. Sizing detail → reference the migration GKE platform doc; do not hardcode a number here.
- Fan-out still runs through Pub/Sub → `notifications` service → FCM for offline users (unchanged from `functions/src/group_chat/fanout.ts`, now Pub/Sub-fronted per migration §2.4). WS delivers to *online* connections; FCM covers offline. No double-delivery.

**Acceptance:** presence and chat delivery serve target concurrency with **Firestore listener count per DB well under the ceiling**; WS nodes stay under the per-node connection cap with autoscale headroom; pod recycle causes reconnect, not message loss (verified in a chaos drill).
**Effort:** L. **Risk:** High — connection storms on mass reconnect; presence staleness during cutover.

### 5.3 Multi-region deployment, placement & regional failover

**Objective:** place data and compute near user clusters, replicate for durability, and prove regional failover — this is migration **P7** operationalized.

**Steps**
- Baseline is **single-region `europe-west1`** by [`../migration/adr/0005-region-strategy.md`](../migration/adr/0005-region-strategy.md), everything already **region-parametrized** (`primary_region` Terraform variable in [`terraform/variables.tf`](../../terraform/variables.tf)); global LB is anycast. `firebase.json` shows a single Firestore location today (`greengo-chat`). Multi-region config is **designed-ready but not yet present** — G4 is where it is stood up.
- **Trigger to add a region** (ADR-0005, any one): non-EU MAU share > 40% sustained, non-EU p95 > 400 ms sustained, or a DR/regulatory demand. At 10M+ global registered these are almost certainly met — add **Americas** (`southamerica-east1` or `us-central1`) and **Asia** as clusters grow.
- **Placement table (region ↔ user cluster):** see §6.3. Pin each user's home shard/region by residency + latency; keep per-user data (chat, presence, inbox) **in-region** to hold p95 < 400 ms.
- **Replication:** stateless GKE services deploy to every region (identical containers via Argo CD). Data: Firestore multi-region location for durability where needed; AlloyDB cross-region read pools / async replication for the money + graph plane (promote-to-primary on failover); Redis is regional (rebuild on failover, it is cache/presence). Deep IaC → [`../migration/05-iac-terraform.md`](../migration/05-iac-terraform.md), [`../migration/06-gke-platform.md`](../migration/06-gke-platform.md).
- **Regional failover:** anycast LB + health checks drain a failed region to the next-nearest; AlloyDB replica promotion; DNS/session re-affinity for WS reconnect. **DR game days** with proven RPO/RTO are the P7 capstone.
- **Data residency:** keep EU-resident user data in EU regions; do not replicate PII cross-jurisdiction beyond what residency allows. Enforce via VPC Service Controls + placement policy ([`../migration/09-security-compliance.md`](../migration/09-security-compliance.md)).

**Acceptance:** every active region holds p95 < 400 ms for its cluster; a killed region fails over within RTO with RPO within target in a game day; residency policy verified (no cross-jurisdiction PII replication).
**Effort:** L (migration P7 program). **Risk:** High — cross-region consistency and failover correctness.

### 5.4 Cost / committed-use optimization

**Objective:** bend cost-per-MAU **down** as scale rises, per migration FinOps.

**Steps**
- **Committed Use Discounts (CUD):** commit to the **measured P95 always-on baseline, never the peak** ([`../migration/11-cost-finops.md`](../migration/11-cost-finops.md) §5 "CUD discipline"). Steady 24/7 workloads — AlloyDB money primary, GKE baseline pods, WS fleet floor — are CUD-eligible; burst on-demand above the commitment. Quarterly review against billing export; sweep unattached CUDs, idle read replicas, orphaned disks/IPs (FinOps §6 waste sweeps).
- **Caching hit-rate is a cost lever at this scale:**
  - **TTS (Chirp 3 HD)** is coin-gated **and cached** — cache hit-rate directly cuts per-synthesis Vertex/TTS spend at millions of MAU. Keep the cache key stable (text+voice) and TTL long; the client TTS key is proxied server-side (migration §2.8, §5). Higher hit-rate = lower marginal cost per active user.
  - **`external_events` cache-first** (sharded index + geohash, `functions/src/external_events/`) means shared event reads are served once per client per TTL, not per view — this is a shared-read amortization that flattens read cost as users grow (README Phase 3.2). Superseded by AlloyDB catalog + Redis geo in migration P5 but the cache-first *pattern* stays.
  - Extend cache-first to hot profiles, discovery feed, trending/featured via Firestore bundles / Cloud CDN (README Phase 3.2/3.4). Higher CDN cache-hit at volume is an explicit per-MAU reducer (FinOps §7.1).
- **Storage tiering:** GCS lifecycle rules move cold media/backups to Nearline/Coldline/Archive; BigQuery long-term storage pricing for cold analytics partitions.

**Acceptance:** cost-per-MAU flat-or-falling QoQ against the FinOps model; CUD utilization > 90% (no stranded spend); TTS + external_events + CDN cache-hit ratios tracked and trending up.
**Effort:** M, then ongoing. **Risk:** Med — over-committing CUD strands spend; under-caching inflates variable cost.

---

## 6. Reference material

### 6.1 Sharding router activation notes
- Router lives server-side in GKE domain services; client sends logical keys through the **abstract datasource seam** (`lib/features/*/data/datasources/*_remote_datasource.dart`) injected via `lib/core/di/injection_container.dart`.
- Key → shard by consistent hashing with virtual nodes; adding a shard moves ~1/N of keys. Dual-read during a key's move; cut writes last.
- Shard by: userId (per-user data), conversationId (chat), groupId (group fan-out). Never per-message.
- Pre-flip gate: **grep must show zero un-routed `FirebaseFirestore.instance`** (246 occurrences across 117 files today — must all be behind DI before G4).
- Cross-shard reads go to the analytics/AlloyDB/Redis plane, never scatter-gather across Firestore DBs.

### 6.2 GKE autoscaling & connection sizing notes
- WS deployment scales on **active connections + CPU** (HPA/VPA); PDBs cap simultaneous drain.
- Per-pod connection cap sized on FD + memory-per-connection + heartbeat overhead — value lives in [`../migration/06-gke-platform.md`](../migration/06-gke-platform.md), not here.
- Sticky routing via anycast LB + session affinity; graceful drain + client backoff reconnect.
- Presence via Redis bitmaps; fan-out via Pub/Sub → FCM for offline.

### 6.3 Multi-region placement (region ↔ user cluster)
| User cluster | Home region | Firestore/AlloyDB placement | Failover target |
|---|---|---|---|
| Europe / Africa / Middle East | `europe-west1` (primary, ADR-0005) | EU-resident shards | secondary EU zone → Americas |
| Americas | `southamerica-east1` or `us-central1` (P7) | in-region shards | `europe-west1` |
| Asia-Pacific | `asia-*` (added as cluster grows) | in-region shards | nearest active region |

All regions run identical stateless GKE services (Argo CD). Data pinned in-region for p95 < 400 ms and residency; deep IaC deferred to [`../migration/05-iac-terraform.md`](../migration/05-iac-terraform.md).

---

## 7. Rollout & safety

**No big-bang.** Every step is reversible and cohort-gated via Remote Config (the migration cohort-cutover control plane, §2.4/§4 target-arch).

- **Shard-by-shard.** Bring up shard N+1, dark-read it, dual-write a small cohort's keys, reconcile sums (mirror the counter dual-write/reconcile discipline in README §2), then cut the read path. One shard at a time.
- **Region-by-region.** Stand up the new region in shadow (health-checked, no user traffic), route an internal cohort, then a % of that region's real cluster (1% → 10% → 50% → 100%) with per-region SLO watch.
- **WS cutover cohorted.** Flip presence, then chat delivery, per cohort behind flags; keep the Firestore-listener path warm for instant rollback until a cohort soaks clean.
- **Auto-rollback** tied to the README SLO alerts (per-shard writes/s, per-region p95, crash-free sessions). Any breach reverts the last cohort/shard/region step.

---

## 8. Verification

- **Load harness at target concurrency.** Extend the README Phase 0.7 harness (staging project, realistic mix: 45% chat+presence, 25% discovery, 12% events, 8% coins, 6% tags, 4% TTS) to drive **250K → 25M+ concurrent across regions and shards**; confirm every shard < 7,000 writes/s, every DB < 700K listeners, every region p95 < 400 ms — **with headroom**.
- **Failover drill (game day).** Kill a region; verify RTO/RPO within target, WS clients reconnect, no message/coin loss, AlloyDB replica promotes cleanly (migration P7 DR game days).
- **Shard rebalance drill.** Add a shard under load; verify ~1/N key movement, zero loss, no SLO breach.
- **Cost/MAU measured.** Reconcile actual per-MAU against the FinOps model (~$0.024–0.042 optimized, [`../migration/11-cost-finops.md`](../migration/11-cost-finops.md) §7.1) and track the trend toward the capacity-model ~$0.009 marginal target; confirm the curve is **bending down**, CUD utilization > 90%, and TTS/external_events/CDN cache-hit ratios rising.
- **Chaos on the WS fleet.** Recycle pods under peak; confirm reconnect (not loss) and no connection-storm cascade.

---

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Cross-shard consistency (a read spans shards / a move loses writes) | Med | High | Shard by single-entity keys so reads stay single-shard; dual-read + reconcile on moves; route true cross-shard reads to BigQuery/AlloyDB/Redis, never scatter-gather Firestore |
| Un-routed `FirebaseFirestore.instance` becomes a silent hotspot | Med | High | Pre-flip grep gate = zero direct calls; all Firestore behind DI provider before activating multi-DB |
| Region failover incorrect (data loss / split-brain) | Low | High | P7 DR game days with proven RPO/RTO; AlloyDB replica-promote runbook; anycast LB drain; residency-aware placement |
| WebSocket connection storm on mass reconnect | Med | High | Client backoff + jitter; PDB-limited drain; scale on connection count; warm Firestore-listener fallback during cutover |
| Cost blowout | Med | High | CUD on P95 baseline (not peak); monthly waste sweeps; per-MAU trend as a leadership SLO; cache-hit ratios as cost levers |
| Operational complexity (N shards × M regions) exceeds team capacity | Med | High | Strangler-fig, one shard/region at a time; per-shard & per-region SLOs + on-call (migration §08, §12); quarterly capacity review; automate rebalance/failover, never manual |

---

## Trade-offs — What this gate adds and what it costs

### ✅ What you gain
- **Features / UX:** presence and chat delivered over the GKE WebSocket fleet feels the same to users but now scales past the ~1M-listener wall; multi-region (ADR-0005 / migration P7) puts each user's home shard near their cluster, holding p95 < 400 ms for Americas/Asia instead of trans-Atlantic latency; regional failover means a region outage degrades, not downs, the app.
- **Performance:** no single-database ceiling — writes/sec and concurrent listeners are spread across N Firestore DBs + AlloyDB shards, so 250K → 25M+ concurrent stays inside per-shard comfort bands with headroom.
- **Functionality / capability headroom:** effectively unlimited horizontal scale toward 1B registered; adding a shard/region is additive (the DI seam flips single-target → N-target), not a rewrite; cost-per-MAU trends *down* as CUDs cover the predictable baseline and the TTS (Chirp 3 HD) and `external_events` caches amortize shared reads across millions.

### ⚠️ What you give up / the costs
- **Complexity & maintenance:** the highest operational tier GreenGo will ever run — N shards × M regions, a stateful WS fleet, AlloyDB replica promotion, per-shard/per-region SLOs and on-call. SRE burden and blast-radius surface grow accordingly.
- **Performance or UX regressions in specific paths:** WebSocket cutover introduces reconnect-storm risk on mass pod recycle (mitigated by backoff/PDBs, but real); brief presence staleness during cohort cutover; cross-region reads for the rare global path are slower than a single-region lookup.
- **Feature/behavior changes required:** **global "query across all users" is no longer free.** Any feature that scans all users — global leaderboards, global search, "browse everyone" — cannot fan out across N Firestore DBs and **must be redesigned shard-aware or backed by a separate index/warehouse** (BigQuery `greengo_analytics`, AlloyDB + Vertex Vector Search, Redis sorted sets). Cross-shard reads lose global strong consistency (eventual only). Data-residency rules constrain where EU/other user data may physically live.
- **Engineering cost / dependencies:** depends on the entire migration program (Phase-B live: AlloyDB, Pub/Sub, GKE) plus G0–G3; a high fixed-cost floor (always-on primaries, LB, baseline pods, observability) that only amortizes at scale. **Hard pre-flip gate:** the 246 direct `FirebaseFirestore.instance` references (across 117 files) must all sit behind the DI shard-aware provider first — any missed one silently hotspots the single primary and defeats sharding.

### Net verdict
Only justify G4 past ~10M registered — it is the terminal complexity tier where you deliberately trade simplicity and some global-query functionality for effectively unlimited scale and multi-region resilience. From here on, features must be **designed shard-aware**: "just query all users" is gone, replaced by per-shard reads plus a warehouse/index for anything global. Reaching this gate is a good problem — it means GreenGo scaled to tens of millions concurrent — but the complexity it adds is not reversible: you do not un-shard or un-multi-region a live 1B-user platform. Activate it because a measured ceiling forced you to, never preemptively.

---

## 10. Exit criteria (terminal)

G4 has no "next gate". It reaches **steady state** when:
- Multi-DB sharding is live with every shard inside its comfort band and rebalancing is automated and drilled.
- The GKE WebSocket fleet serves all presence/chat with autoscale headroom; Firestore listener counts stay under the per-DB ceiling.
- Multi-region is live with proven regional failover (RPO/RTO met in game days) and enforced data residency.
- Cost-per-MAU is **trending down** with CUD utilization > 90%.
- **Ongoing operations:** quarterly capacity reviews (headroom per shard/region), quarterly CUD reviews vs billing export, recurring load tests before each expansion, and DR game days on a schedule. These never stop — they are the definition of "done" for a system at 1B scale.

---

## 11. Cross-references

- [`README.md`](README.md) — the gate model (G0–G4), SLO table, activation triggers, reference code patterns.
- **`G3_STRUCTURAL.md`** (sibling) — where the shard key, routing abstraction, and migration Phase-B kickoff were built; G4 activates what G3 dark-launched.
- [`../migration/10-phased-roadmap.md`](../migration/10-phased-roadmap.md) — P6 (realtime scale-out) and P7 (Americas region + DR + decommission) that G4 operationalizes.
- [`../migration/02-target-architecture.md`](../migration/02-target-architecture.md) — canonical target platform (data plane, GKE, Pub/Sub, Redis presence).
- [`../migration/adr/0005-region-strategy.md`](../migration/adr/0005-region-strategy.md) — single-region-first, multi-region triggers, `primary_region` flip.
- [`../migration/06-gke-platform.md`](../migration/06-gke-platform.md) · [`../migration/05-iac-terraform.md`](../migration/05-iac-terraform.md) — GKE autoscaling/connection sizing & Terraform (deep infra lives here).
- [`../migration/11-cost-finops.md`](../migration/11-cost-finops.md) — cost-per-MAU model, CUD discipline, waste sweeps.
- Code seams cited: `lib/features/*/data/datasources/*_remote_datasource.dart`, `lib/features/chat/data/repositories/chat_repository_impl.dart`, `lib/core/services/presence_service.dart`, `lib/core/di/injection_container.dart`, `functions/src/group_chat/fanout.ts`, `functions/src/external_events/`.
