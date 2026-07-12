# ADR-0002 — AlloyDB for PostgreSQL for ledger/graph/vectors (not Spanner)

**Status:** Accepted · **Date:** 2026-07-07

## Context
The money domains (coins, payments, subscriptions) and the social graph (matches/likes/swipes) need ACID transactions, reconciliation, relational queries, and horizontal read scale. Discovery needs vector similarity. Candidate stores: Cloud Spanner (global, strongly-consistent), Cloud SQL Postgres, AlloyDB Postgres, or staying on Firestore.

## Decision
Anchor these domains on **AlloyDB for PostgreSQL**:
- ACID + standard SQL + mature Postgres ecosystem — the team's least-surprise choice for a ledger.
- **Read pool** nodes give horizontal read scaling to millions of users.
- **Columnar engine** accelerates analytical queries in-place.
- **pgvector** co-locates discovery embeddings with the relational data — no separate vector DB for the common case (Vertex Vector Search still used for very-large-scale ANN in P5).
- Regional HA (99.99%) with cross-region read replicas available.

## Consequences
- **+** Familiar Postgres; far lower cost than Spanner (esp. multi-region); vectors built in.
- **+** Clean reconciliation and audit for the ledger.
- **−** Not globally strongly-consistent for writes (regional primary). Acceptable now (single-region strategy, [ADR-0005](0005-region-strategy.md)).
- **Escape hatch:** if global write-consistency becomes a hard requirement, the money domain can be promoted to **Cloud Spanner** later; the service boundary and event contracts make this a contained change.

## Alternatives considered
| Option | Verdict |
|--------|---------|
| Cloud Spanner | Deferred — global strong consistency not needed at single-region launch; significantly pricier. Kept as future escape hatch for the ledger. |
| Cloud SQL Postgres | Viable, but AlloyDB's read pools + columnar + pgvector performance justify it for the hot path. Cloud SQL may host low-traffic auxiliary DBs. |
| Stay on Firestore | Rejected for money/graph — weak for ledgers, reconciliation, and relational/vector queries. |
