# ADR-0003 — GKE Autopilot + Anthos Service Mesh for compute

**Status:** Accepted · **Date:** 2026-07-07

## Context
~200 Cloud Functions must consolidate into ~14 domain services. Compute options: keep Cloud Functions, move to Cloud Run, or run on GKE. The platform must support long-lived connections (future WebSocket tier), sidecar-based mTLS/traffic-splitting, HPA/VPA, and a uniform golden path.

## Decision
Run domain services on **GKE Autopilot** (regional, 3 zones, `europe-west1`) with **Anthos Service Mesh** (managed Istio). Autopilot removes node management and bills per pod; ASM provides automatic mTLS, L7 canary traffic-splitting, and mesh-wide telemetry. **Cloud Run** is retained for spiky, stateless webhook endpoints (Stripe/Play/App-Store) where scale-to-zero wins.

## Consequences
- **+** No node ops; secure-by-default; strong autoscaling; supports stateful/long-lived workloads.
- **+** Mesh gives mTLS + progressive delivery + tracing without app code changes.
- **+** One golden path (repo template + Helm/Kustomize + Argo Rollouts).
- **−** More platform surface than pure serverless — owned by the Platform/SRE squad.
- **−** Autopilot constrains some low-level pod tuning; acceptable for these workloads.

## Alternatives considered
| Option | Verdict |
|--------|---------|
| Cloud Run only | Rejected as primary — weaker for mesh/mTLS, stateful, and future WebSocket tiers; kept for webhooks. |
| GKE Standard | Rejected — node management overhead not justified vs Autopilot. |
| Keep Cloud Functions | Rejected — the sprawl is the problem we are solving. |
