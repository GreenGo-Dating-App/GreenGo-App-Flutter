# Architecture Decision Records

ADRs capture the *why* behind load-bearing choices, so future engineers can tell a deliberate decision from an accident. Format: Context → Decision → Consequences → Alternatives. Status one of `Proposed | Accepted | Superseded`.

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-hybrid-strangler-fig.md) | Hybrid strangler-fig migration (keep Firestore for realtime) | Accepted |
| [0002](0002-alloydb-for-relational.md) | AlloyDB for PostgreSQL for ledger/graph/vectors (not Spanner) | Accepted |
| [0003](0003-gke-autopilot.md) | GKE Autopilot + Anthos Service Mesh for compute | Accepted |
| [0004](0004-pubsub-event-backbone.md) | Pub/Sub + Eventarc + Cloud Tasks event backbone | Accepted |
| [0005](0005-region-strategy.md) | Single region first (`europe-west1`), multi-region in Phase 7 | Accepted |
| [0006](0006-iac-and-gitops.md) | Terraform for infra + Argo CD GitOps for Kubernetes | Accepted |

## Writing a new ADR
Copy an existing one, bump the number, set status `Proposed`, open a PR. It becomes `Accepted` on merge. Never edit an accepted ADR's decision — write a new one that supersedes it and flip the old to `Superseded`.
