# GreenGo — Improvement Plan (7 points)

Post-repositioning hardening plan. Sequenced so each phase de-risks the next, ending in a clean App Store submission. **Requires a feature freeze to converge.**

> Two phases need the owner: **Phase 1** (real-device QA — physical iPhone) and **Phase 5** (App Store Connect submission). Everything else is engineering I can execute.

---

## Phase 0 — Spec lock  ·  point #7 (process)
Freeze the final **Explore + Network + Community + Membership** spec in one doc (layout, filters, actions, tiers) so screens stop being rebuilt. One source of truth → no more churn.
- **Exit:** written spec approved; feature queue frozen.

## Phase 1 — Real-device QA + fix  ·  point #2  *(needs owner + device)*
- Build to a **real iPhone + real Android** (glass/Impeller only render correctly on device).
- Walk **every flow**: login → Explore → carousel → Network filters → photo→chat → tags → Events → create event → Community → Membership → coins.
- Log bugs, fix the broken ones (e.g. the tags-rules bug that only surfaced in use).
- **Exit:** every core flow verified on a physical device.

## Phase 2 — Cleanup + scale  ·  points #3 + #4
- **Delete/quarantine dead dating code** (swipe/match/blind-date/date-scheduler/second-chance/share-my-date/special-modes/virtual-gifts/video-profiles) — removes the 4.3(b) liability and dead weight.
- Fix **non-scalable queries** — the `limit(80)` "random worldwide", discovery pool → server-side sampling / sharded random keys (scales to millions).
- **Audit glass blur** (structural surfaces only), image caching, list virtualization.
- Clear the **~195 analyzer warnings** so real issues stop hiding.
- **Exit:** dead code gone, hot queries scalable, 0 warnings.

## Phase 3 — i18n + accessibility  ·  point #5
- Translate the **110+ missing strings** across `app_de/es/fr/it/pt/pt_BR.arb`.
- A11y labels, dynamic-type, reduced-motion coverage on the new screens.
- **Exit:** all locales complete; a11y pass on new screens.

## Phase 4 — Automated tests  ·  point #6
- Tests for critical paths: connect→chat, tag save, tier limits/coins, event create, filter persistence.
- Wire into the existing test framework + CI.
- **Exit:** green test suite on the critical paths.

## Phase 5 — Submission  ·  point #1  *(needs owner)*
- iOS **Xcode scheme** for the culture flavor + **splash screens** + PWA assets.
- **Store metadata**: Travel/Education category, de-dated description/keywords, **screenshots** of the new UI.
- **Resolution Center reply** (drafted).
- Build, upload, **submit**.

---

## Sequencing
`0 spec-lock → 1 device-QA → 2 cleanup+scale → 3 i18n+a11y → 4 tests → 5 submit`
Phases 2–4 can partly overlap. Phase 5 is last so we submit a **verified** build.

**Rough total:** ~1.5–2 weeks focused.
