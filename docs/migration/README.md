# GreenGo — Google Cloud Enterprise Migration

> Migration of GreenGo (`greengo-chat`, app **v2.2.4+100**) from a Firebase-native monolith to a **hybrid GKE + managed-data platform** on Google Cloud, engineered to serve **millions of users** reliably.

This directory is the **source of truth** for the migration. It is written for the engineering team that will execute it. Every document is grounded in the *actual* GreenGo codebase, not a generic template.

---

## The one-paragraph version

GreenGo today is a Flutter client over **~200 Cloud Functions** and **~90 Firestore collections**. We are **not** doing a big-bang rewrite. We keep **Firestore for what it is best at** (realtime chat, presence, feeds, fan-out) and migrate the **relational, transactional, and analytical** domains onto a proper platform: **GKE Autopilot** for compute, **AlloyDB for PostgreSQL** for the money-ledger, social-graph, and vector workloads, a **Pub/Sub** event backbone, and **BigQuery + Vertex AI** for analytics and ML — all provisioned with **Terraform + Argo CD GitOps**. We move domain-by-domain with the **Strangler-Fig pattern**, keeping the app live and revenue-generating through every phase, and every step is reversible.

---

## Locked decisions (approved 2026-07-07)

| # | Decision | Choice | ADR |
|---|----------|--------|-----|
| 1 | Migration posture | **Hybrid strangler-fig** — keep Firestore for realtime | [ADR-0001](adr/0001-hybrid-strangler-fig.md) |
| 2 | Money & graph datastore | **AlloyDB for PostgreSQL** (pgvector for discovery) | [ADR-0002](adr/0002-alloydb-for-relational.md) |
| 3 | Compute platform | **GKE Autopilot + Anthos Service Mesh** | [ADR-0003](adr/0003-gke-autopilot.md) |
| 4 | Event backbone | **Pub/Sub + Eventarc + Cloud Tasks** | [ADR-0004](adr/0004-pubsub-event-backbone.md) |
| 5 | Geography | **Single region first** (`europe-west1`), multi-region in Phase 7 | [ADR-0005](adr/0005-region-strategy.md) |
| 6 | IaC & delivery | **Terraform (infra) + Argo CD (K8s GitOps)** | [ADR-0006](adr/0006-iac-and-gitops.md) |

---

## Document index

| # | Document | Audience | Purpose |
|---|----------|----------|---------|
| 00 | [Overview](00-overview.md) | All | Vision, principles, glossary, how to read this |
| 01 | [Current-state assessment](01-current-state.md) | Eng | Full inventory of what exists today |
| 02 | [Target architecture](02-target-architecture.md) | Eng / Arch | Canonical target design, per layer |
| 03 | [GCP service catalog](03-gcp-service-catalog.md) | Eng / SRE | Service-by-service configuration |
| 04 | [Data migration](04-data-migration.md) | Backend / Data | Per-domain dual-write / backfill / reconciliation runbooks |
| 05 | [IaC & Terraform](05-iac-terraform.md) | Platform | Landing zone, module design, environments |
| 06 | [GKE platform](06-gke-platform.md) | Platform / SRE | Cluster, mesh, GitOps, progressive delivery |
| 07 | [CI/CD](07-cicd.md) | Platform | Pipelines, Artifact Registry, canary |
| 08 | [Observability & SLOs](08-observability-slo.md) | SRE | SLOs, dashboards, alerting, error budgets |
| 09 | [Security & compliance](09-security-compliance.md) | Security | IAM, VPC-SC, WAF, secrets, GDPR |
| 10 | [Phased roadmap](10-phased-roadmap.md) | All | Per-phase runbooks, entry/exit, rollback |
| 11 | [Cost & FinOps](11-cost-finops.md) | Leadership / SRE | Detailed cost model + optimization |
| 12 | [Team & RACI](12-team-raci.md) | Leadership / EM | Squads, ownership, ways of working |
| — | [ADRs](adr/) | Arch | Architecture Decision Records |

## How to read this

- **Leadership / stakeholders** → [00-overview](00-overview.md) + [11-cost-finops](11-cost-finops.md) + the HTML executive deck.
- **New engineer joining** → [00](00-overview.md) → [01](01-current-state.md) → [02](02-target-architecture.md) → your squad's domain doc.
- **Starting a phase** → [10-phased-roadmap](10-phased-roadmap.md) → the referenced runbook.

## Status

| Item | State |
|------|-------|
| Plan approved | ✅ 2026-07-07 |
| Documentation | ✅ this set |
| Execution | ⏳ pending team kickoff (Phase 0) |
