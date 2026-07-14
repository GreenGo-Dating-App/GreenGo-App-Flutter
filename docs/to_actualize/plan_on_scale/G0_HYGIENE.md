# G0 — Hygiene (Detailed Gate Plan)

**Gate:** G0 — Hygiene · **Trigger:** NOW / any scale (do regardless of user count) · **Theme:** cheap, correct-code items that prevent debt — *not* scale-defense complexity · **Status:** Ready to execute · **Date:** 2026-07-13 · **Owner:** Eng lead
**Parent plan:** [`../plan_on_scale/README.md`](./README.md) — this document is the detailed expansion of Gate **G0**.

> G0 is the one gate you execute **today, at any user count**. Everything in it is *correct code*, not premature optimization: a leaked listener is a bug at 100 users and at 10M; an unbounded query bills every document to every client at every scale. The whole gate is ~2–3 dev-days and is permanent hygiene. Do NOT pull any G1–G4 mechanism (counter sharding, RTDB presence, min-instances, CDN/bundles) into this gate — the PR checklist keeps those *options* open by blocking the anti-patterns, so each can be flipped on exactly when its trigger arrives.

---

## 1. When to activate / when this is DONE

**Entry:** always-on. There is no trigger to wait for. Start now.

**Exit (all four must hold):**
1. Every snapshot/stream subscription is owned by exactly one BLoC/State and cancelled in `close()`/`dispose()`; no screen holds more than 3 concurrent Firestore listeners (SLO).
2. Every Firestore query that can return a growing collection carries a `.limit()` at the **server**; long lists paginate with `startAfterDocument`.
3. A PR checklist enforcing the five anti-patterns is committed to `.github/PULL_REQUEST_TEMPLATE.md` **and** a lightweight CI/pre-commit guard fails on a seeded violation.
4. Firebase Performance custom traces (message-send, feed-load, screen-open, cold-start) are wired and visible in the Firebase console.

When these four are true, G0 is closed and the team stops here until it approaches ~70K registered users (70% of the G1 ~100K trigger), at which point [`G1_OBSERVE_THROTTLE.md`](./G1_OBSERVE_THROTTLE.md) opens.

---

## 2. Objectives & the SLOs this gate defends

G0 directly defends the four **hygiene** rows of the master SLO table (§0 of the parent plan). The other rows (latency, writes/sec, cold-start) are *observed* here via traces but *defended* in later gates.

| Metric (master SLO) | Target | Alert threshold | G0 mechanism |
|---|---|---|---|
| Active snapshot listeners per screen | ≤ 3 | > 6 | Task 1 (listener lifecycle + per-screen cap) |
| Unbounded query | none allowed | any | Task 2 (`.limit()` everywhere) + Task 3 (CI guard) |
| Frame jank (build > 16 ms) | < 1% of frames | > 3% | Task 1 (fewer listeners = fewer rebuilds) + Task 4 (trace to *see* it) |
| Crash-free sessions | > 99.5% | < 99% | Task 1 (leaked listeners → OOM/late-callback crashes) |
| Cold start to interactive | < 2.5 s | > 4 s | Task 4 (`app_launch` trace to baseline it) |

**Guiding principle (from parent §0):** *complexity is a cost — add it only when load demands it.* G0 adds **zero** scale-defense complexity. It only removes bugs and adds visibility.

---

## 3. Prerequisites

**None.** This is the base gate. It has no upstream dependency and gates all others. `firebase_performance: ^0.10.0` is already in [`pubspec.yaml`](../../../pubspec.yaml) (line 38) and `firebase_crashlytics` is present, so no new dependency is required for Task 4.

---

## 4. Current-state audit (grounded in the repo)

A full scan of `lib/` was done on 2026-07-13. Summary before the task list, so effort is calibrated to reality:

- **BLoC layer is disciplined.** Every stream-owning BLoC inspected stores its `StreamSubscription` in a field and cancels it in `close()`: `MatchesBloc` ([`lib/features/discovery/presentation/bloc/matches_bloc.dart`](../../../lib/features/discovery/presentation/bloc/matches_bloc.dart) lines 36–37, 287–290), `CoinBloc` ([`lib/features/coins/presentation/bloc/coin_bloc.dart`](../../../lib/features/coins/presentation/bloc/coin_bloc.dart) lines 104, 558–559), `GlobeBloc` ([`lib/features/globe_explore/presentation/bloc/globe_bloc.dart`](../../../lib/features/globe_explore/presentation/bloc/globe_bloc.dart) lines 28–29, 194–196), `CommunitiesBloc` ([`lib/features/communities/presentation/bloc/communities_bloc.dart`](../../../lib/features/communities/presentation/bloc/communities_bloc.dart) lines 42, 346–347). **This is the house style — match it everywhere.**
- **The leaks are in `StatefulWidget` State classes, not BLoCs.** Confirmed un-cancelled subscriptions (see Task 1).
- **`.limit()` is used broadly** (187 call sites) but **not universally** — several list/stream queries are unbounded (see Task 2).
- **Firebase Performance is half-built and dead.** A complete `PerformanceMonitoringService` exists at [`lib/features/analytics/data/services/performance_monitoring_service.dart`](../../../lib/features/analytics/data/services/performance_monitoring_service.dart) but is **never registered** in [`lib/core/di/injection_container.dart`](../../../lib/core/di/injection_container.dart) and **never called** from any feature. `lib/main.dart` touches `FirebasePerformance` only to *disable* collection in emulator mode (lines 132–133). Task 4 wires the existing service in; it does not write a new one.
- **No PR template, no GitHub Actions.** There is no `.github/` directory. CI is Codemagic ([`codemagic.yaml`](../../../codemagic.yaml)) with `ios-testflight`, `web-release`, `android-release` workflows; its only `flutter analyze` step runs with `ignore_failure: true` (line 41) so it never blocks. A [`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml) exists (flutter-analyze, dart-fix, detect-secrets) — the natural host for Task 3's static guard.

---

## 5. Tasks

### Task 1 — Cancel every listener on dispose; cap listeners per screen ≤ 3

**Objective.** No `StreamSubscription` outlives the widget/BLoC that created it. No screen holds more than 3 concurrent Firestore snapshot listeners. Leaked listeners cause late `setState`-after-dispose crashes (hurts crash-free SLO), duplicated rebuilds (hurts jank SLO), and phantom Firestore reads (hurts cost).

**Concrete steps (real files):**

1. **Fix the confirmed audio-stream leaks.** These capture no subscription and cancel nothing:
   - [`lib/features/profile/presentation/screens/edit_voice_screen.dart`](../../../lib/features/profile/presentation/screens/edit_voice_screen.dart) lines 71, 79, 87 — `_audioPlayer.onPositionChanged.listen(...)`, `onDurationChanged.listen(...)`, `onPlayerComplete.listen(...)` are fire-and-forget; `dispose()` (line 98) disposes the player but never cancels these three subs.
   - [`lib/features/discovery/presentation/screens/profile_detail_screen.dart`](../../../lib/features/discovery/presentation/screens/profile_detail_screen.dart) lines 90, 93, 96 — same pattern, same omission at `dispose()` (line 107).
   - **Fix:** store each in a `StreamSubscription? _posSub` / `_durSub` / `_completeSub` field and `?.cancel()` them in `dispose()` (pattern §6.1).

2. **Reduce the listener count on the heaviest screen.** [`lib/features/main/presentation/screens/main_navigation_screen.dart`](../../../lib/features/main/presentation/screens/main_navigation_screen.dart) holds **5 concurrent Firestore snapshot listeners** (`_matchCountSub`, `_messageCountSub`, `_groupCountSub`, `_levelUpSub`, `_achievementSub`, lines 157–163; each a `.snapshots().listen(...)` at lines 1100, 1149, 1203, 1230, 1277). They *are* cancelled in `dispose()` (lines 1296–1301) — good — but 5 > the ≤3 SLO. **Fix:** collapse the three badge-count listeners (match/message/group) into a single aggregate counters doc per user (one listener), or move them behind the BLoC that already owns that data. Target ≤ 3.
   - Also review [`lib/features/profile/presentation/screens/usage_stats_screen.dart`](../../../lib/features/profile/presentation/screens/usage_stats_screen.dart) (3 listeners, lines 45–47 — at the SLO ceiling, cancelled correctly at 62–65; acceptable but do not add a 4th).

3. **Audit the short-lived upload listeners.** `uploadTask.snapshotEvents.listen(...)` in [`lib/features/chat/presentation/screens/chat_screen.dart`](../../../lib/features/chat/presentation/screens/chat_screen.dart) (lines 959, 1122) is bounded (completes when the upload finishes) — low risk, but capture the sub and cancel in `dispose()` for safety so an in-flight upload on a closed screen can't call back.

4. **Establish the rule in code review** (feeds Task 3): *one BLoC/State → owns its subscriptions → cancels in `close()`/`dispose()`; no raw `.snapshots()` in a `StatefulWidget` unless the sub is a field.*

**Acceptance criteria (measurable):**
- DevTools "Stream/subscription" count returns to the pre-navigation baseline after pushing then popping every one of the 4 heavy screens (chat, discovery, network grid, events).
- `main_navigation_screen` holds ≤ 3 Firestore listeners.
- No `_audioPlayer.*.listen(` without a matching `?.cancel()` in `dispose()` (grep clean).

**Effort:** ~1 dev-day. **Risk:** Low — mechanical; regression risk only if a badge count is dropped during the counter-merge (covered by a widget test asserting badge values).

---

### Task 2 — Cap every query with `.limit()`; paginate long lists

**Objective.** No query streams or fetches an unbounded collection. Every growing list is server-limited and paginated. This is the single highest-leverage cost/latency item in G0: an unbounded `.snapshots()` bills *every* document to *every* client on *every* change.

**Concrete steps (real, confirmed unbounded sites):**

| File · line | Query | Problem | Fix |
|---|---|---|---|
| [`chat_remote_datasource.dart`](../../../lib/features/chat/data/datasources/chat_remote_datasource.dart) 382–394 (`getMessagesStream`) | `messages.orderBy('sentAt', desc)` with `if (limit != null) query = query.limit(limit)` | `limit` is `int?`; when a caller passes `null` the `.snapshots()` at 394 is **unbounded** — the entire message history streams on every new message | Make `limit` non-nullable with a default of 30; paginate older pages with `startAfterDocument` (pattern §6.2) |
| [`chat_remote_datasource.dart`](../../../lib/features/chat/data/datasources/chat_remote_datasource.dart) 667–676 (`getConversationsStream`) | `conversations.where(or userId1/userId2).orderBy('lastMessageAt', desc).snapshots()` | **No `.limit()` at all** — streams every conversation the user has ever had | Add `.limit(30)`; load older conversations via infinite scroll |
| [`notification_remote_datasource.dart`](../../../lib/features/notifications/data/datasources/notification_remote_datasource.dart) 81–99 | `notifications.where('userId').snapshots()` then `sublist(0, cap)` **client-side** (line 94) | Server query is unbounded — reads and **bills all N docs**, caps to 100 only after download | Add server `.limit(cap)` to the query. (Comment at 74–78 avoids a composite index by sorting client-side; a `.limit()` on the single-field `where` is still valid and bounds reads — order within the cap is acceptable for a notifications badge, or add the composite index if strict ordering matters) |
| [`events_remote_datasource.dart`](../../../lib/features/events/data/datasources/events_remote_datasource.dart) 707–718 | attendee/RSVP `.snapshots()` and `.orderBy('rsvpDate').get()` with no limit | Unbounded for a popular event | Add `.limit()` + pagination on the "Going" list |
| [`events_remote_datasource.dart`](../../../lib/features/events/data/datasources/events_remote_datasource.dart) 837–838 | `.orderBy('startDate').get()` no limit | Unbounded events fetch | Add `.limit(100)` (matches the pattern already used at line 246) |
| [`coin_remote_datasource.dart`](../../../lib/features/coins/data/datasources/coin_remote_datasource.dart) 420–421, 891–904 | coin-claim / ledger `.orderBy(...).get()` no limit | Unbounded ledger reads grow forever per user | Add `.limit()` + pagination on ledger history |

**General step:** grep the codebase for the anti-pattern and triage each hit — `\.snapshots\(\)` and `\.get\(\)` on a `collection(...)`/`where(...)`/`orderBy(...)` chain with no `.limit(` on the same statement. Single-document reads (`.doc(id).get()` / `.doc(id).snapshots()`) are exempt. Prefer a shared paginated-query helper in [`lib/core/utils/firestore_helpers.dart`](../../../lib/core/utils/firestore_helpers.dart) (already exists) so callers can't forget.

**Acceptance criteria:**
- No collection query returns more than one page (default 30, or the screen's page size) from the server.
- All confirmed sites in the table above carry a server `.limit()`; long lists (chat, conversations, notifications, event attendees, coin ledger) infinite-scroll.
- Task 3's CI guard passes on the whole tree (no un-limited list query remains).

**Effort:** ~1 dev-day. **Risk:** Low–Med — pagination changes list UX; add a "load more" sentinel and a widget test that the first page renders and a second page appends.

---

### Task 3 — PR review checklist + lightweight static guard

**Objective.** The five anti-patterns can never merge again. This is what keeps the slowdown point at 10M instead of silently collapsing back to hundreds (parent §6.1). It also keeps the G1–G4 options open: by *blocking* un-sharded counters and hot shared docs now, each scale-defense mechanism can be switched on cleanly at its trigger.

**Concrete steps (real paths — these files do not exist yet, create them):**

1. **Create `.github/PULL_REQUEST_TEMPLATE.md`** (no `.github/` dir exists today) containing the checklist block in §6.4. GitHub renders it into every PR description automatically.

2. **Add a static guard to [`.pre-commit-config.yaml`](../../../.pre-commit-config.yaml)** as a new `repo: local` hook (that file already hosts `flutter-analyze`, `dart-fix`, `detect-secrets`). A grep-based hook is enough for G0 — it fails commit on an obvious unbounded list query or a raw counter increment outside the sharded helper. See §6.5.

3. **Add a blocking CI job.** The only CI today is [`codemagic.yaml`](../../../codemagic.yaml), where `flutter analyze` runs with `ignore_failure: true` (line 41) — it never blocks. Add a small `.github/workflows/pr-guard.yml` (GitHub Actions) that runs `flutter analyze --fatal-warnings`, `flutter test`, and the grep guard script, and is a **required check** on `main`. Do **not** flip Codemagic's analyze to blocking — Codemagic is the release pipeline; keep the fast correctness gate on PRs.

4. **Train reviewers:** link this file from the PR template so the checklist has a rationale.

**Acceptance criteria:**
- A seeded PR that adds `FirebaseFirestore.instance.collection('messages').snapshots()` (no `.limit()`) **fails CI** and is blocked from merge.
- A seeded PR that adds `_audioPlayer.onPositionChanged.listen(...)` with no field/cancel is caught in review via the checklist.
- The checklist appears pre-filled in every new PR.

**Effort:** ~0.5 dev-day. **Risk:** Low — additive tooling; risk is false positives from the grep guard (mitigate with an inline `// perf-ignore: bounded-elsewhere` opt-out comment the guard respects).

---

### Task 4 — Wire the existing Firebase Performance traces

**Objective.** Get real p50/p95/p99 baselines for message-send, feed-load, screen-open, and cold-start into the Firebase console — so the later gates have data to trigger on and jank/latency SLO regressions become visible. The code already exists; it is just not connected.

**Concrete steps (real files):**

1. **Register the service in DI.** Add to [`lib/core/di/injection_container.dart`](../../../lib/core/di/injection_container.dart) (registration style there is `sl.registerLazySingleton(...)`, e.g. line 230):
   ```dart
   sl.registerLazySingleton<PerformanceMonitoringService>(
     () => PerformanceMonitoringService(),
   );
   ```
2. **Initialize once at startup.** In [`lib/main.dart`](../../../lib/main.dart), after Firebase init (line ~95) and outside the emulator branch (lines 129–133, which correctly *disable* collection under the emulator), call `await sl<PerformanceMonitoringService>().initialize();`. Guard it with the same `!kDebugMode || !AppConfig.useLocalEmulators` condition so emulator runs stay off.
3. **Instrument the four critical flows** using the already-built `trackOperation` / `startTrace` / `stopTrace` API (`performance_monitoring_service.dart` lines 36–122):
   - `message_send` — wrap the send call in `chat_remote_datasource.dart`.
   - `feed_load` — wrap the discovery/network first-page load.
   - `screen_open_<name>` — start on `initState`, stop on first frame (`WidgetsBinding.instance.addPostFrameCallback`).
   - `app_launch` — already scaffolded via `trackAppLaunch()` / `completeAppLaunch()` (lines 228–235); call `trackAppLaunch()` before `runApp` and `completeAppLaunch()` in the first post-frame callback of the root widget.
4. Keep it lightweight — 4 traces, no HTTP-metric fleet, no ANR/memory pollers yet (those methods exist in the service but stay dormant until G1's observability work).

**Acceptance criteria:**
- The four custom traces appear in Firebase Console → Performance within 24 h of a release build running on a real device.
- p95 baselines for each flow are recorded in the gate's exit notes (feeds the G1 dashboard trigger).
- Emulator/debug runs still show `Performance disabled` (no pollution of prod metrics).

**Effort:** ~0.5 dev-day. **Risk:** Low — the service is written and tested-shaped; risk is forgetting to exclude debug builds (mitigated by the existing emulator guard).

---

## 6. Reference code patterns (Dart)

### 6.1 Correct listener lifecycle — BLoC (house style) and State

```dart
// BLoC — matches MatchesBloc/CoinBloc/GlobeBloc house style.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  StreamSubscription<QuerySnapshot>? _messagesSub;
  ChatBloc(this._repo) : super(ChatInitial()) {
    on<ChatStarted>((e, emit) {
      _messagesSub?.cancel();                       // never double-subscribe
      _messagesSub = _repo.messages(e.chatId).listen(
        (m) => add(ChatMessagesUpdated(m)),
        onError: addError,
      );
    });
  }

  @override
  Future<void> close() {
    _messagesSub?.cancel();                         // the fix that stops leaks
    return super.close();
  }
}
```

```dart
// StatefulWidget State — the pattern the audio screens are MISSING.
class _EditVoiceScreenState extends State<EditVoiceScreen> {
  StreamSubscription? _posSub, _durSub, _completeSub;

  @override
  void initState() {
    super.initState();
    _posSub      = _audioPlayer.onPositionChanged.listen(_onPos);
    _durSub      = _audioPlayer.onDurationChanged.listen(_onDur);
    _completeSub = _audioPlayer.onPlayerComplete.listen(_onDone);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();                          // <-- currently absent
    _audioPlayer.dispose();
    super.dispose();
  }
}
```

### 6.2 Paginated query with `.limit()` + `startAfterDocument`

```dart
// Put in lib/core/utils/firestore_helpers.dart so callers can't forget the cap.
Query<Map<String, dynamic>> messagesPage(
  String conversationId, {
  DocumentSnapshot? startAfter,
  int limit = 30,                                    // never unbounded
}) {
  var q = FirebaseFirestore.instance
      .collection('conversations/$conversationId/messages')
      .orderBy('sentAt', descending: true)
      .limit(limit);
  if (startAfter != null) q = q.startAfterDocument(startAfter);
  return q;
}

// getConversationsStream — add the cap that is missing today (line 675):
Stream<List<ConversationModel>> conversationsStream(String uid, {int limit = 30}) =>
    FirebaseFirestore.instance
        .collection('conversations')
        .where(Filter.or(Filter('userId1', isEqualTo: uid),
                         Filter('userId2', isEqualTo: uid)))
        .orderBy('lastMessageAt', descending: true)
        .limit(limit)                                // <-- the fix
        .snapshots()
        .map((s) => s.docs.map(ConversationModel.fromFirestore).toList());
```

### 6.3 Firebase Performance custom trace (via the existing service)

```dart
// The service already exists (performance_monitoring_service.dart:87). Just call it.
final perf = sl<PerformanceMonitoringService>();

Future<void> sendMessage(Message m) => perf.trackOperation(
  operation: CriticalTrace.messageSend,             // enum in performance_metrics.dart
  attributes: {'conversation': m.conversationId},
  execute: () => _repo.send(m),
);

// Manual start/stop for screen-open:
@override
void initState() {
  super.initState();
  sl<PerformanceMonitoringService>().startTrace('screen_open_discovery');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    sl<PerformanceMonitoringService>().stopTrace('screen_open_discovery');
  });
}
```

### 6.4 PR checklist — paste into `.github/PULL_REQUEST_TEMPLATE.md`

```markdown
## Performance & scale hygiene (Gate G0 — required)
- [ ] **No un-cancelled listener** — every `.snapshots()` / `.listen()` is stored in a
      field and cancelled in `close()` / `dispose()`. No screen holds > 3 Firestore listeners.
- [ ] **No un-paginated query** — every collection query has a server `.limit()`; long lists
      paginate with `startAfterDocument`. (Client-side `sublist` does NOT count.)
- [ ] **No shared hot doc** — no write path that concentrates on a single doc that scales with
      users (member/online/unread/like counts, presence). Defer sharding, but don't create the hotspot.
- [ ] **No un-sharded counter** — counters go through the sharded-counter helper, not a raw
      `FieldValue.increment` on a shared doc.
- [ ] **No per-keystroke / per-frame write** — typing, presence, scroll, "last seen" are
      debounced (≤ 1 write / 3 s per user).
- [ ] Perf-sensitive change carries a before/after metric (trace or DevTools capture).
```

### 6.5 Static guard — pre-commit hook (add to `.pre-commit-config.yaml`)

```yaml
  - repo: local
    hooks:
      - id: no-unbounded-firestore-query
        name: No unbounded Firestore list query
        language: system
        files: '\.dart$'
        # Flag collection().snapshots()/.get() with no .limit() on the same statement.
        # Opt out on a verified-bounded line with:  // perf-ignore: bounded-elsewhere
        entry: bash scripts/check_unbounded_queries.sh
        pass_filenames: true
```

```bash
#!/usr/bin/env bash
# scripts/check_unbounded_queries.sh — grep guard, not a full analyzer.
status=0
for f in "$@"; do
  # lines that stream/fetch a collection chain but carry no .limit( and no opt-out
  if grep -nE '\.(snapshots|get)\(\)' "$f" \
       | grep -vE '\.doc\(' \
       | grep -vE '\.limit\(' \
       | grep -vE 'perf-ignore: bounded-elsewhere' \
       | grep -qE 'collection\(|where\(|orderBy\('; then
    echo "Unbounded Firestore query in $f — add .limit() or // perf-ignore"; status=1
  fi
done
exit $status
```

---

## 7. Rollout & safety

G0 is low-risk by construction — it removes bugs and adds visibility; it changes no data model and adds no scale-defense mechanism, so there is nothing to feature-flag or canary here (unlike G1+). Ship as small PRs, each with its own before/after capture:

- **Test coverage expectation.** Each listener-lifecycle fix (Task 1) ships with a widget/bloc test that asserts the subscription is cancelled on `dispose`/`close` (e.g. `bloc.close()` completes and the underlying controller has no listeners). Each pagination change (Task 2) ships with a test that the first page renders and "load more" appends without duplicates.
- **No behavioral flags needed**, with one exception: if the `main_navigation` counter-merge (Task 1 step 2) changes how badge counts are computed, guard the new aggregate-doc read behind a trivial flag in [`lib/core/services/feature_flags_service.dart`](../../../lib/core/services/feature_flags_service.dart) so it can be reverted without a redeploy.
- **Perf init (Task 4)** stays disabled in debug/emulator via the existing guard in `main.dart` — verify no debug run reports traces.

---

## 8. Verification

| Item | How to prove it |
|---|---|
| Listeners cancelled | DevTools → Memory/instances: subscription count returns to baseline after push→pop of chat, discovery, network grid, events. Grep shows no `_audioPlayer.*.listen(` without a matching `?.cancel()`. |
| ≤ 3 listeners/screen | Manual count + a debug-only assert that logs active Firestore listeners per route; `main_navigation` reads ≤ 3. |
| No unbounded query | Run `scripts/check_unbounded_queries.sh lib/**/*.dart` → exit 0. Seed one unbounded `.snapshots()` → CI job **fails** (proves the guard works). |
| Checklist enforced | Open a draft PR: template renders pre-filled; the seeded-violation PR is blocked by the required check. |
| Traces live | Firebase Console → Performance shows `message_send`, `feed_load`, `screen_open_*`, `app_launch` with p50/p95 after a release run; debug run shows none. |

**Reference device:** run the profile-mode DevTools capture on a low-end minSdk-24 Android device (per parent §5 dependencies) so the jank baseline is honest.

---

## 9. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Counter-merge on `main_navigation` drops a badge count | Med | Med | Widget test asserting each badge value; flag-guard the new aggregate read |
| Pagination changes list UX (jump/scroll reset) | Med | Low | Keep page size ≥ 30; append-only "load more"; test first+second page |
| Grep guard false positives block legit commits | Med | Low | `// perf-ignore: bounded-elsewhere` opt-out; guard is advisory in pre-commit, authoritative only in the CI job |
| Notification server `.limit()` changes ordering (no composite index) | Low | Low | For a badge, arbitrary order within the cap is fine; add the composite index only if strict ordering is required |
| Perf traces pollute prod metrics from debug builds | Low | Low | Existing emulator/debug guard in `main.dart`; verify no debug traces appear |
| Hidden un-cancelled listener missed by the audit | Low | Med | The CI grep guard runs on every future PR; late-callback crashes surface in Crashlytics (already wired) |

---

## Trade-offs — What this gate adds and what it costs

### ✅ What you gain
- **Features / UX:** No more stale/ghost UI or late-callback crashes from leaked listeners — the un-cancelled audio streams in `edit_voice_screen.dart` (71/79/87) and `profile_detail_screen.dart` (90/93/96) stop firing into disposed screens, so the play/pause/seek UI stays correct and the app is less crash-prone (defends the crash-free SLO). Screens feel faster because fewer duplicate rebuilds fire.
- **Performance:** Lower memory and battery use (dangling `StreamSubscription`s and their Firestore listeners are released on navigate-away); measurably fewer/cheaper Firestore reads once the unbounded queries are capped — `getConversationsStream` (`chat_remote_datasource.dart:667`) stops streaming a user's entire conversation history on every change, `getMessagesStream` (382–394) stops falling back to unbounded, and `notification_remote_datasource.dart:81-99` stops billing every notification doc before capping client-side. `main_navigation` drops from 5 to ≤3 concurrent listeners.
- **Functionality / capability headroom:** The dead `PerformanceMonitoringService` becomes live telemetry — real p50/p95/p99 for message-send, feed-load, screen-open, and cold-start, which is the data every later gate triggers on. The PR checklist + pre-commit guard mean leaks and unbounded reads can't silently re-enter, keeping the G1–G4 scale-defense options open without building them yet.

### ⚠️ What you give up / the costs
- **Complexity & maintenance:** Near-zero net — this gate mostly *removes* code paths. The only additions are one grep guard script, a PR template, and ~4 trace call-sites; all small and self-documenting.
- **Performance or UX regressions in specific paths:** Capping currently-"load everything" lists turns them into paginated/infinite-scroll (conversations, notifications, event attendees, coin ledger). Users who previously saw an entire list at once now see the first page and scroll for more — a minor, expected UX change, not a loss of data access.
- **Feature/behavior changes required:** The `main_navigation` counter-merge changes how three badge counts are computed (one aggregate doc instead of three listeners); the notification server `.limit()` may make within-cap ordering arbitrary unless a composite index is added. Both are covered by tests/flags in §7.
- **Engineering cost / dependencies:** ~2–3 dev-days one-time, no new package dependencies (Firebase Performance is already in `pubspec.yaml`). Small ongoing dev friction from the pre-commit guard (mitigated by the `// perf-ignore: bounded-elsewhere` opt-out).

### Net verdict
At any scale this gate is essentially pure win: it removes real bugs (listener leaks, crashes), cuts the Firestore read bill on paths that only get more expensive as users grow, and turns on the visibility the rest of the plan depends on — for a couple dev-days and no meaningful feature loss. The only genuine risk here is *not* doing it: the leaks and unbounded reads are cheap to fix today and turn into painful, costly slowdowns once the user base grows.

---

## 10. Exit criteria → hand-off to G1

G0 is **done** when the four exit conditions in §1 hold and §8 verification passes. Record the perf-trace p95 baselines (message-send, feed-load, screen-open, cold-start) in the gate notes — these become the reference the **G1** dashboards trigger on.

**Hand-off to [`G1_OBSERVE_THROTTLE.md`](./G1_OBSERVE_THROTTLE.md)** (starts at ~70K registered / 70% of the 100K trigger): G1 promotes the raw traces into Cloud Monitoring dashboards, adds debounce on high-churn writes (typing/presence/scroll), and turns on cache-first for measured-hot reads. G0's PR checklist and CI guard remain live permanently and are the substrate G1's automated guards extend.

---

## 11. Cross-references

- Parent plan / gate model / master SLO table: [`./README.md`](./README.md) (see §0 SLOs, §1 gates, Phases 3.1 / 4.1 / 6.1, Appendix A patterns)
- Next gate: [`./G1_OBSERVE_THROTTLE.md`](./G1_OBSERVE_THROTTLE.md) — Observe & throttle (~100K)
- Later gates: [`./G2_DEHOTSPOT.md`](./G2_DEHOTSPOT.md) (~1M), [`./G3_STRUCTURAL_SCALE.md`](./G3_STRUCTURAL_SCALE.md) (~3M), [`./G4_DISTRIBUTED.md`](./G4_DISTRIBUTED.md) (~10M+)
- Migration program (G3+ trigger): [`../migration/`](../../migration/) (see `08-observability-slo.md`, `01-current-state.md`)
- Key code anchors: `lib/features/analytics/data/services/performance_monitoring_service.dart` · `lib/core/di/injection_container.dart` · `lib/main.dart` · `lib/core/utils/firestore_helpers.dart` · `codemagic.yaml` · `.pre-commit-config.yaml`
