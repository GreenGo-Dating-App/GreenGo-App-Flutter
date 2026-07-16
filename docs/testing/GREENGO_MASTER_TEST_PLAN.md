# GreenGo — Master Test Plan (500 tests)

**Author:** QA/Test Engineering
**Scope:** Full-stack — Flutter frontend + Firebase backend (Cloud Functions, Firestore rules/indexes, data integrity) + performance/speed.
**Goal:** 500 automated, categorized tests run against **mocked users** (with login), producing a **PDF report** in `docs/testing/reports/`.
**Status:** PLAN (to be approved before implementation).

---

## 1. Objectives

Measure, for every major feature area:
- **Functionality** — does the feature behave per spec (happy path + edge cases + failure handling)?
- **Speed/Performance** — query latency, pagination, cold start, list-scroll frame budget, bloc throughput, Cloud Function execution time.
- **Security** — Firestore rules allow/deny correctly (owner-only, business exclusion, deleted-user hygiene).
- **Data integrity** — denormalized counters stay consistent (memberCount, unreadCount, attendeeCount, ratingSum/Count).
- **Regression coverage** — every fix shipped this cycle has a guarding test (communities concurrency, business chat identity, live-event date validity, optimistic delete-all, dual business search, no-ID share list, etc.).

---

## 2. Test pyramid & tooling

| Layer | Tool | What it covers | Runs against |
|------|------|----------------|--------------|
| Unit | `flutter_test` | models, mappers, blocs, utils, comparators | pure Dart |
| Bloc | `bloc_test` + `mocktail` | every bloc's events → states | mocked repos |
| Widget | `flutter_test` + `network_image_mock` | screens/widgets render + interaction | `fake_cloud_firestore` + `firebase_auth_mocks` |
| Golden | `flutter_test` goldens | key UI (cards, headers, dividers-removed) | fixed data |
| Integration (frontend) | `integration_test` | end-to-end user journeys | emulator + **mock user login** |
| Backend rules | `@firebase/rules-unit-testing` (Jest) | Firestore security rules | **Firestore emulator** |
| Backend functions | Jest + `firebase-functions-test` | Cloud Functions logic | **emulator** |
| Performance | custom harness (`Stopwatch`, `flutter test` timings, emulator query timers) | latency/throughput budgets | emulator + real prod read (read-only) |

**New dev_dependencies (Flutter):** `mocktail`, `bloc_test`, `fake_cloud_firestore`, `firebase_auth_mocks`, `network_image_mock`, `golden_toolkit`.
**Backend:** `jest`, `ts-jest`, `@firebase/rules-unit-testing`, `firebase-functions-test` (in `functions/`).

---

## 3. Mock users & login strategy

Reuse the **existing seeder** (`functions/src/admin/mockData.ts`) which creates `mock_user_1..5`
(FREE / SILVER / GOLD / PLATINUM / PLATINUM+business) plus events, communities, chats, groups,
tips/announcements — all `isMock:true` and removable.

- **Unit/bloc/widget tests:** no real backend. Inject a **`MockUser`** (uid = `mock_user_1`) via
  `firebase_auth_mocks`, and seed a **`FakeFirebaseFirestore`** with the same document shapes the
  seeder writes. A `MockUsers` fixture exposes all five personas.
- **Integration tests (emulator):** point the app at the **Firebase emulator suite**, run the seeder
  against it, and log in with a dedicated **test Auth account** whose uid is mapped to `mock_user_1`'s
  profile. Personas 2–5 cover tier-gated paths (Platinum-only, business-only).
- **Backend tests:** the rules/functions emulators are seeded with the mock docs; each test asserts
  as a specific persona uid.

**Teardown:** every suite calls `removeMockData` (or resets the emulator) so no test data persists.

---

## 4. The 500 tests — split by category

### FRONTEND — 340

| # | Category | Tests | Focus (incl. regression guards) |
|---|----------|------:|--------------------------------|
| F1 | Authentication & Session | 25 | login (valid/invalid/version), signup optional referral, consents default-checked, mock-user login, session persistence, logout, reauth-before-delete |
| F2 | Onboarding (8-step) | 25 | each step, photo upload (web XFile path), skip/validation, resume, completion writes profile |
| F3 | Profile (view/edit) | 30 | view-my-profile, edit dropdown, **age+flags UNDER name**, business toggle, hero image, GDPR entry hidden |
| F4 | Discovery / Explore | 35 | section order + **dividers removed**, **Happening soon = community-only ≤50km by date, else live ≤50km ≤1wk**, Featured always-appears boosted→random nearby, **50km event filter**, business section removed |
| F5 | Communities | 45 | Discover **random 50 joinable** (excludes joined) + endless scroll + prefetch, **My communities loads (concurrency-merge)** + search bar + loader + create-appears, join + **business-join confirm dialog**, **tips/announcements/chat display (message race)**, create + **preview featured image**, list-not-grid |
| F6 | Events | 35 | list date-asc, **live events valid-date-only + not-endless-loading**, RSVP counts, QR scanner, **share sheet shows names not IDs + hides deleted users**, happening/featured buckets |
| F7 | Chat / Messaging | 35 | 1:1 send/receive, group chat + inbox, **business identity in card+header (Elena's Cafe not Elena Marco)**, **business-inquiry routes to Business tab (not Messages)**, favorites, delete |
| F8 | Business / Storefront | 30 | storefront view, **events/communities tap-through**, **rating hides after rating**, **leads show name+image not id**, follow, opening hours |
| F9 | Search | 20 | universal search, **dual business listing (personal + business hero-image → storefront)**, partial-name match, **deleted/inactive excluded** |
| F10 | Notifications | 20 | list, tap-routing (like/match/message/community/group/profile), delete one, **optimistic delete-all/clear-unread** |
| F11 | Membership / Coins / Shop | 20 | tiers, VIP→shop membership tab, coin spend/grant, invoices, TTS coin-gating |
| F12 | Localization (7 locales) | 15 | no hardcoded strings, ASCII non-English, ARB key coverage, `gen-l10n` parity |
| F13 | Widgets / Golden / UI | 20 | CommunityCard, ConversationCard, profile header, storefront hero, dividers-removed golden |

### BACKEND — 160

| # | Category | Tests | Focus |
|---|----------|------:|-------|
| B1 | Firestore Security Rules | 40 | communities/members create (self-join incl. business, mod can't add others' storefront), notifications owner-only, conversations/messages/matches/likes scoped, coins/invoices owner-only, join_requests mod-only, user_interactions scoped |
| B2 | Cloud Functions | 45 | seeder + remover round-trip, `onProfileDeleted` cascade (counters, auth, storage), group_chat fanout + membership strip-business, community announcement fanout, push triggers idempotency + actor payload, event reminders windows, backfill creator members |
| B3 | Indexes / Query validity | 15 | every composite/collection-group query used by the client resolves (isPublic+lastActivityAt, members.userId, messages/threads.isMock, events status+publishAt) |
| B4 | Data integrity / counters | 20 | memberCount join/leave, unreadCount send/read, attendeeCount RSVP, ratingSum/Count, deleted-user removal from aggregates |
| B5 | Performance / Speed | 25 | query latency budgets (discover ≤300ms warm, my-communities ≤300ms), pagination page-time, cold start, list scroll ≥55fps, bloc event throughput, CF exec time (512MiB fns) |
| B6 | Integration E2E (mock user) | 15 | login→explore→join community→chat→rate business→get notification→delete-all; business persona storefront flow; tier-gated flow |

**Total: 340 + 160 = 500.**

---

## 5. Performance budgets (measured, not just pass/fail)

| Metric | Budget | Method |
|--------|--------|--------|
| Discover first paint (warm cache) | ≤ 300 ms | Stopwatch around bloc load |
| My-communities query | ≤ 300 ms | Stopwatch around `getCreatedCommunities` |
| Community list page (50) | ≤ 400 ms | pager timing |
| List scroll | ≥ 55 fps | `integration_test` frame timing |
| Cold start to Explore | ≤ 3.5 s | integration timing |
| CF `seedMockData` | ≤ 8 s | emulator exec time |
| CF `onProfileDeleted` cascade | ≤ 5 s | emulator exec time |

Each budget is a test that **records the actual number** into the report (green if within budget, amber if 1–1.5×, red if >1.5×).

---

## 6. PDF report

1. Extend the existing `test/userTests/test_report_generator.dart` to emit a **single self-contained HTML** with: executive summary (pass/fail/rate), per-category tables, **performance dashboard** (budget vs actual), failure details + stack traces, and environment metadata.
2. Aggregate results from all layers: `flutter test --machine` JSON (frontend) + Jest JSON (backend) + the perf harness JSON.
3. Convert HTML → **PDF via Edge headless** (the established no-install method on this machine):
   `msedge --headless=new --print-to-pdf=docs/testing/reports/GreenGo_Test_Report_<date>.pdf file:///.../report.html`
4. Output: `docs/testing/reports/GreenGo_Test_Report_<date>.pdf` + the HTML alongside it.

---

## 7. Execution phases

- **Phase 0 — Harness (foundation):** add dev deps, mock fixtures (`MockUsers`, `FakeFirestore` seeding mirroring the seeder shapes), emulator config, unified results aggregator, PDF pipeline. *(no feature tests yet)*
- **Phase 1 — Frontend unit/bloc (F1–F13 unit+bloc portion):** fast, no emulator.
- **Phase 2 — Frontend widget/golden/integration:** emulator + mock login.
- **Phase 3 — Backend rules + functions (B1–B4):** emulator + Jest.
- **Phase 4 — Performance (B5) + E2E (B6).**
- **Phase 5 — Aggregate → HTML → PDF report.**

Each phase is independently runnable and committed separately. A single top-level script
(`dart run test/userTests/run_tests_with_report.dart --full`) orchestrates all layers and produces the PDF.

---

## 8. Deliverables

- `test/` — ~500 tests across the categories above (extending `test/userTests/`).
- `functions/test/` — Jest rules + functions suites.
- `test/perf/` — performance harness.
- `docs/testing/reports/GreenGo_Test_Report_<date>.pdf` — the QA report.
- Updated `README` with run instructions.

---

## 9. Risks / notes

- **Mock users have no Firebase Auth** — integration login needs a dedicated emulator test account mapped to `mock_user_1`. (Unit/widget use `firebase_auth_mocks`, no real auth.)
- **Prod safety** — performance tests that read prod are **read-only**; all write/seed happens on the **emulator**. `removeMockData` teardown guarantees no residue.
- **Scale** — 500 tests is large; Phase 0 harness must make adding tests cheap (shared fixtures/builders) or the suite becomes unmaintainable.
- **CI** — the suite should run in Codemagic; emulator-dependent phases gated behind a job that boots the emulator suite.
