# ADR-0006 — Terraform for infra + Argo CD GitOps for Kubernetes

**Status:** Accepted · **Date:** 2026-07-07

## Context
The repo's existing `terraform/` references five modules that do not exist and hardcodes `nodejs18`; it cannot `apply`. There is no Kubernetes delivery mechanism. We need reproducible infra and cluster state across dev/staging/prod.

## Decision
Two complementary control planes:
1. **Terraform** provisions **cloud infrastructure** (projects, VPC, GKE clusters, AlloyDB, Firestore, Pub/Sub, IAM, Secret Manager, buckets, BigQuery). Remote state in a GCS backend with state locking; one workspace/dir per environment; reusable modules. Replaces the broken `terraform/`.
2. **Argo CD** delivers **Kubernetes workloads** via GitOps: desired state (Helm/Kustomize manifests) lives in Git; Argo CD continuously reconciles each cluster. **Argo Rollouts** does canary/progressive delivery through the service mesh. **Config Connector** optionally lets a small set of GCP resources be managed as K8s CRDs where that is cleaner.

CI is **Cloud Build** (or GitHub Actions) → build/test → push image to **Artifact Registry** → update the GitOps repo → Argo CD deploys. No `firebase deploy` scripts, no console click-ops in staging/prod.

## Consequences
- **+** Reproducible, reviewable, auditable infra and deployments; easy rollback (git revert).
- **+** Clear split: Terraform = infra lifecycle, Argo CD = app lifecycle.
- **−** Two tools to learn; mitigated by the golden-path template and Platform squad ownership.
- **−** Requires disciplined repo structure (infra repo vs GitOps repo vs app repos) — defined in [05](../05-iac-terraform.md)/[07](../07-cicd.md).

## Alternatives considered
| Option | Verdict |
|--------|---------|
| Terraform for everything (incl. K8s manifests) | Rejected — Terraform is poor at continuous reconciliation of cluster state; GitOps is purpose-built. |
| Pulumi / CDKTF | Rejected — Terraform HCL is the team/most-common standard; no compelling gain. |
| Keep `firebase deploy` scripts | Rejected — not viable for GKE + multi-service + canary. |
| Flux instead of Argo CD | Viable; Argo CD chosen for its UI, Rollouts integration, and mesh-native canaries. |
