# ADR-0005 — Single region first (`europe-west1`), multi-region in Phase 7

**Status:** Accepted · **Date:** 2026-07-07

## Context
GreenGo is a cross-cultural discovery/networking app with a globally-distributed user base. Multi-region from day one maximizes latency/availability but multiplies cost and complexity (multi-region Firestore/AlloyDB, global data consistency, cross-region eventing).

## Decision
Launch **single-region** in **`europe-west1`** (Belgium) — globally central for a mixed EU/Americas/global audience — while designing every layer **multi-region-ready** (stateless services, region-agnostic config, global LB already anycast). Add a **second region in the Americas** (`southamerica-east1` São Paulo, or `us-central1`) in **Phase 7**, triggered by the thresholds below.

### Multi-region trigger thresholds (any one)
| Signal | Threshold |
|--------|-----------|
| MAU share outside Europe | > 40% sustained |
| p95 API latency for a non-EU region | > 400 ms sustained |
| Availability / DR requirement | Regulatory or SLA demand for in-region failover |

## Consequences
- **+** Faster, cheaper launch; one region to operate while the platform matures.
- **+** Design stays multi-region-ready so Phase 7 is additive, not a rewrite.
- **−** Non-EU users see higher latency until Phase 7. Mitigated by Cloud CDN at the edge for cacheable content.
- **−** Single-region DR is zone-redundant only until Phase 7 adds cross-region failover.

## How to flip the primary region
If Phase-0 data shows the majority of MAU is in the Americas, change the primary to `southamerica-east1` or `us-central1`: it is a Terraform variable (`primary_region`) plus a Firestore location decision (the only location that is *not* easily changed later — decide it in Phase 0). Everything else is region-parametrized.

## Alternatives considered
| Option | Verdict |
|--------|---------|
| Global multi-region from day one | Deferred — cost/complexity not justified before product-market scale is proven. |
| Americas-primary (`southamerica-east1`) | Kept as an easy flip pending Phase-0 MAU geography data. |
