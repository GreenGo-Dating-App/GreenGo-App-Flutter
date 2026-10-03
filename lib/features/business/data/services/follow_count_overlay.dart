import 'dart:async';

import 'package:flutter/foundation.dart';

/// Which server-maintained profile counter a pending change applies to.
enum FollowCounter { followers, following }

class _Pending {
  _Pending(this.delta, this.base);

  /// Net change this device made that the server has not reflected yet.
  int delta;

  /// The server value right BEFORE the change was written (null = unknown).
  /// The change counts as reflected as soon as the server moves off it.
  final int? base;

  Timer? timer;
}

/// Optimistic follower / following counts, shared by every [FollowService]
/// instance in the app.
///
/// The counters are maintained by Cloud Function triggers, which can take
/// seconds (a cold start) to run after the edge is written. Meanwhile every
/// screen that shows the counts — the followee's "N followers" AND the
/// follower's own "M following" — would keep showing the old number, and any
/// unrelated profile update (presence, location) would re-deliver it.
///
/// This overlay records the change locally the moment the edge write commits
/// and adds it to the server value until the server catches up:
///   * reconciled as soon as the server value moves off [_Pending.base]
///     (the trigger ran), or after [ttl] as a safety net;
///   * follow + unfollow of the same pair before the trigger ran cancel out
///     (the trigger then counts nothing, so neither do we);
///   * the displayed value is clamped at 0.
class FollowCountOverlay {
  FollowCountOverlay({this.ttl = const Duration(seconds: 45)});

  /// The app-wide instance.
  static final FollowCountOverlay shared = FollowCountOverlay();

  final Duration ttl;

  final Map<FollowCounter, Map<String, _Pending>> _pending = {
    FollowCounter.followers: <String, _Pending>{},
    FollowCounter.following: <String, _Pending>{},
  };
  final StreamController<String> _changes = StreamController<String>.broadcast();

  /// Emits a uid whenever its overlay changed (apply / reconcile / expiry).
  Stream<String> get changes => _changes.stream;

  /// Record a committed change of [delta] to [uid]'s [counter].
  /// [serverBefore] is the server value read just before the write.
  void record(String uid, FollowCounter counter, int delta, {int? serverBefore}) {
    if (uid.isEmpty || delta == 0) return;
    final map = _pending[counter]!;
    var entry = map[uid];
    // The server already moved off the old base: that change has landed.
    if (entry != null &&
        serverBefore != null &&
        entry.base != null &&
        entry.base != serverBefore) {
      _drop(map, uid);
      entry = null;
    }
    if (entry != null) {
      entry.delta += delta;
      if (entry.delta == 0) _drop(map, uid);
    } else {
      entry = _Pending(delta, serverBefore);
      map[uid] = entry;
      final e = entry;
      e.timer = Timer(ttl, () {
        if (identical(map[uid], e)) {
          map.remove(uid);
          _emit(uid);
        }
      });
    }
    _emit(uid);
  }

  /// Feed a fresh server value; drops pending changes the server reflects.
  void observeServer(String uid, FollowCounter counter, int serverValue) {
    final map = _pending[counter]!;
    final entry = map[uid];
    if (entry == null || entry.base == null) return;
    if (serverValue != entry.base) {
      _drop(map, uid);
      // No _emit: the caller is about to publish this server value anyway.
    }
  }

  /// [serverValue] adjusted by any pending local change, never negative.
  int apply(String uid, FollowCounter counter, int serverValue) {
    final delta = _pending[counter]![uid]?.delta ?? 0;
    final v = serverValue + delta;
    return v < 0 ? 0 : v;
  }

  /// Pending delta for [uid] (0 when none) — for tests / diagnostics.
  @visibleForTesting
  int pendingDelta(String uid, FollowCounter counter) =>
      _pending[counter]![uid]?.delta ?? 0;

  /// Forget everything (tests, sign-out).
  void clear() {
    for (final map in _pending.values) {
      for (final p in map.values) {
        p.timer?.cancel();
      }
      map.clear();
    }
  }

  void _drop(Map<String, _Pending> map, String uid) {
    map.remove(uid)?.timer?.cancel();
  }

  void _emit(String uid) {
    if (!_changes.isClosed) _changes.add(uid);
  }
}
