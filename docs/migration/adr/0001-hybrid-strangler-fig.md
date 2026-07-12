# ADR-0001 — Hybrid strangler-fig migration (keep Firestore for realtime)

**Status:** Accepted · **Date:** 2026-07-07

## Context
GreenGo is a Firebase-native monolith (~200 Cloud Functions, ~90 Firestore collections) that must serve millions of users. Two extremes were on the table: (a) a full de-Firebase rewrite onto GKE + Postgres + a custom realtime tier, or (b) leaving everything on Firestore. Option (a) is ~18–24 months, high risk, and discards realtime infrastructure Firestore does exceptionally well. Option (b) leaves ledgers, graph queries, and cost/scale ceilings unresolved.

## Decision
Adopt a **hybrid strangler-fig** migration. Keep **Firestore** as the system of record for realtime workloads (chat messages, presence, feeds, fan-out inboxes, notification inbox). Migrate **relational/transactional/analytical** domains (coins ledger, payments, subscriptions, social graph, catalog, analytics) onto a GKE + managed-data platform, **one domain at a time**, behind a facade, with the old path retired only after the new one proves out.

## Consequences
- **+** App stays live and revenue-generating throughout; risk is bounded per domain.
- **+** We keep GreenGo's already-good realtime patterns (fan-out, sharded index, geohash, candidate pools).
- **+** Each phase is independently valuable and reversible.
- **−** Temporary dual-run complexity (dual-write, reconciliation) for stateful domains.
- **−** Two operational models (Firestore + AlloyDB) to run concurrently — mitigated by unified observability.

## Alternatives considered
| Option | Verdict |
|--------|---------|
| Full de-Firebase rewrite | Rejected — cost/risk/timeline disproportionate; throws away working realtime. |
| Stay entirely on Firestore | Rejected — leaves ledger integrity, relational queries, and cost ceilings unsolved. |
| Lift-and-shift functions to GKE, no data change | Rejected — containerizes the problem without fixing the data model. |
