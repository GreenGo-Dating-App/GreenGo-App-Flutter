# GreenGo — Architecture Blueprint (draw.io)

`GreenGo-Architecture.drawio` — one file, 12 pages, ~2 040 shapes. Generated
from the repository, not hand-drawn.

## How to open

- **draw.io Desktop** — File ▸ Open
- **app.diagrams.net** — File ▸ Open from ▸ Device
- **VS Code** — the *Draw.io Integration* extension renders `.drawio` inline

## Structure

| Page | Contents |
|---|---|
| **00 · MASTER** | The single schema. An always-visible 9-box HLD strip, then 9 collapsible bands that expand into the full LLD: actors → client runtime & flavor gate → Flutter app (49 feature slices, 40 core services, layer anatomy) → Firebase edge (110 rule-guarded collections, 12 storage prefixes, index shapes) → all 275 Cloud Functions in 63 modules → external SaaS → cross-cutting concerns → infra/CI → 4 end-to-end runtime traces |
| 01 | Identity, Onboarding & Profile |
| 02 | Explore, Discovery, Map & Globe |
| 03 | Messaging & Chat |
| 04 | Events & External Ingesters |
| 05 | Communities & Business |
| 06 | Monetization — Coins, Tiers, Payments |
| 07 | Notifications & Email |
| 08 | Safety, Moderation & Admin |
| 09 | Gamification & Language Learning |
| 10 | Media, Voice & Video Calling |
| 11 | Platform, Data Model & DevOps |

Page 00 carries an **ATLAS INDEX** strip — click any button to jump to that
domain's deep dive. Every deep-dive page has a **◀ back to MASTER** button.

## Reading the overlays

- **Dashed / grey ⚪** — the component is **OFF in the default `culture` flavor**.
  It exists in code but must not mount, listen or count usage in the shipped
  build (Apple guideline 4.3(b) repositioning).
- **🔒** — gated behind a paid membership tier. This is not a guess: the marked
  features are exactly those with a call site of `TierGate` / `TierEntitlements`
  / `TierLimitsService` inside `lib/features` — `analytics`, `business`, `chat`,
  `communities`, `events`, `explore`, `profile`, `subscription`. Page 06 lists
  the full entitlement ladder (Base / Silver / Gold / Platinum) with the real
  numbers from `tier_entitlements.dart`.
- **Coloured trace boxes (band 9)** — four end-to-end sequences:
  ① send group message ② spend/grant coins ③ ingest external event
  ④ deliver push notification.

## Zooming

Every band and every module is a **collapsible container**. Click the ▸/▾ in a
container's top-left corner to fold it back to a single HLD box, or right-click
the canvas ▸ *Collapse All* to reduce the whole page to the high-level view.
Layout was authored so nothing overlaps in either state.

## Regenerating

```bash
python docs/architecture/generate_architecture_drawio.py
```

The generator holds the extracted inventory near the top of the file
(`FEATURES`, `CORE_SERVICES`, `FN`, `COLLECTIONS`, `STORAGE_PATHS`, `EXTERNAL`,
`INFRA`, `CROSS`). Update those lists when the code changes and re-run — do not
hand-edit the `.drawio`, or the next regeneration will overwrite it.

Source of truth for each list:

| List | Extracted from |
|---|---|
| `FEATURES` | `lib/features/*/` file counts |
| `CORE_SERVICES` | `lib/core/services/` |
| `FN` | `functions/src/index.ts` export blocks |
| `COLLECTIONS` | `firestore.rules` `match /…` paths |
| `STORAGE_PATHS` | `storage.rules` `match /…` paths |
| `EXTERNAL` | `pubspec.yaml` dependencies + function integrations |
| `INFRA` | `codemagic.yaml`, `terraform/`, `docker/`, `firebase.json` |

Snapshot taken 2026-07-21 from `main` @ `1e952ac`.

## Audits baked into this snapshot

**Cloud Functions memory** (band 5 of page 00, and page 07). Counted from
`memory:` declarations across `functions/src/**/*.ts`:

| Setting | Declarations | Verdict |
|---|---|---|
| 128 MiB | 17 | ⚠ highest risk |
| 256 MiB | 99 | ⚠ at risk |
| 512 MiB | 63 | ✓ safe — the push path lives here |
| 1 GiB / 2 GiB / 1 GB / 2 GB / 512 MB | 15 / 2 / 3 / 3 / 1 | ✓ |

53 of the 102 `.ts` files declare no memory at all and inherit the platform
default. The index needs ~200 MB RSS just to load, so anything at or below
256 MiB can be OOM-killed on cold start — and a killed trigger drops its event
silently. Worst 256 MiB concentrations: `admin/index.ts` (25),
`video/index.ts` (20), `analytics/index.ts` (10). The 128 MiB files are
`backup/`, `messaging/`, `notification/`, `notifications/brevoEmailService`
and `safety/`.

## `legacy/`

The old root-level `greengo_*.py` diagram scripts and their PNGs (17-feature MVP
era) were moved to `legacy/`. They are superseded by this atlas — see
`legacy/README.md`.
