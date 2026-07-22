# Legacy architecture diagrams (superseded)

These Python `diagrams`-library scripts and their rendered PNGs lived at the repo
root and described the **17-feature MVP**. The app now has 49 feature slices and
275 Cloud Functions, so they are inaccurate and are kept only for history.

Superseded by **`../GreenGo-Architecture.drawio`** (12-page HLD + LLD atlas,
generated from source by `../generate_architecture_drawio.py`).

Moved here 2026-07-21. `ARCHITECTURE_DIAGRAMS_README.md` is the original
instructions file for these scripts (they need `pip install diagrams` +
Graphviz).

## ⚠ Do not read these as documentation of the running system

Two of them are not just out of date — they describe things that **do not exist
in the codebase**. Verified 2026-07-21:

**`greengo_microservices_architecture.png`** draws a Django/DRF backend behind an
Nginx API gateway, with Celery Beat + Celery Worker, and five Python
microservices (Messaging/WebSockets, Auth JWT-OAuth, User CRUD, Matching
Algorithm, Payment/Stripe) on PostgreSQL + Redis.

None of that is implemented. `backend/` contains exactly **three files** —
`manage.py`, `config/settings.py`, `requirements.txt`. There are no Django apps,
models, views or urls. `docker/docker-compose.yml` has no `django` or `celery`
service either; it runs the Firebase emulator, postgres, redis, adminer,
redis-commander and nginx. Treat that diagram as a **proposal that was never
built**, not as architecture.

The same file also labels the backend "160+ serverless functions". The audited
count is **275** across 63 modules — see the current atlas.

The real, implemented backend is Firebase + Cloud Functions. If a relational
service is ever wanted, the live plan is the approved GCP migration
(hybrid strangler-fig onto AlloyDB + GKE Autopilot + Pub/Sub, `docs/migration/`)
— not this Django design.
