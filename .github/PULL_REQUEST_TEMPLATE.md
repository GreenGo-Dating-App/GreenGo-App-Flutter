<!-- Describe the change and link the issue. Then complete the checklist below. -->

## Summary

<!-- what & why -->

## Performance & scale hygiene (Gate G0 — required)

See `docs/to_actualize/plan_on_scale/G0_HYGIENE.md` for the rationale.

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

## Testing

<!-- how it was verified -->
