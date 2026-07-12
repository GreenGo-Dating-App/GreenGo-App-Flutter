# ADR-0004 — Pub/Sub + Eventarc + Cloud Tasks event backbone

**Status:** Accepted · **Date:** 2026-07-07

## Context
Today, cross-domain reactions are implemented as inline Firestore triggers (~26) and scheduled functions (~31). This couples domains, offers no buffering/replay, and makes fan-out spikes (group messages, event broadcasts) risky at scale.

## Decision
Introduce an **event backbone**: **Pub/Sub** for domain events (decoupled, buffered, replayable, at-least-once), **Eventarc** to bridge Firestore/GCS/Audit-Log changes into Pub/Sub, **Cloud Tasks** for work queues with backpressure and per-task retries, and **Cloud Scheduler** for cron (replacing scheduled functions). Services publish domain events (`coins.spent`, `message.created`, `match.created`) and subscribe to what they need.

## Consequences
- **+** Domains decouple; consumers can be added without touching producers.
- **+** Spikes are absorbed; failures retried; events replayable for backfills and debugging.
- **+** Fan-out (`group_chat`, `events/broadcast`) becomes buffered and observable.
- **−** At-least-once delivery ⇒ consumers must be **idempotent** (documented pattern in [04](../04-data-migration.md)).
- **−** Eventual consistency between domains — acceptable; strong consistency stays within a service's AlloyDB transaction.

## Alternatives considered
| Option | Verdict |
|--------|---------|
| Keep Firestore triggers | Rejected — coupling, no buffering/replay, spike risk. |
| Kafka (self-managed / Confluent) | Rejected — operational burden vs managed Pub/Sub; no compelling need. |
| Direct synchronous service-to-service calls | Rejected as default — fragile fan-out, tight coupling; used only where a sync response is required. |
