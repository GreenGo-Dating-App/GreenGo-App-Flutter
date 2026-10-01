import 'package:flutter/foundation.dart';

/// Optimistic follow/unfollow state for one (viewer → target) pair.
///
/// [toggle] flips [following] (and the displayed follower count) IMMEDIATELY,
/// runs the write, and rolls both back if the write throws. Taps while a write
/// is in flight are ignored, so a double-tap can never queue two writes.
///
/// Live server state is fed in through [syncFromServer]; while a write is
/// pending, server echoes are ignored so the button does not flicker back.
class FollowToggleController extends ChangeNotifier {
  FollowToggleController({
    required Future<void> Function() follow,
    required Future<void> Function() unfollow,
    bool initiallyFollowing = false,
    int initialFollowers = 0,
  })  : _follow = follow,
        _unfollow = unfollow,
        _following = initiallyFollowing,
        _followers = initialFollowers < 0 ? 0 : initialFollowers;

  final Future<void> Function() _follow;
  final Future<void> Function() _unfollow;

  bool _following;
  int _followers;
  bool _busy = false;
  bool _disposed = false;

  bool get following => _following;
  int get followers => _followers;
  bool get busy => _busy;

  /// Apply the latest server-side values (follow edge + counter). Ignored while
  /// an optimistic write is pending.
  void syncFromServer({bool? following, int? followers}) {
    if (_busy) return;
    var changed = false;
    if (following != null && following != _following) {
      _following = following;
      changed = true;
    }
    if (followers != null) {
      final f = followers < 0 ? 0 : followers;
      if (f != _followers) {
        _followers = f;
        changed = true;
      }
    }
    if (changed) _notify();
  }

  /// Flip the follow state optimistically. Returns `true` when the write
  /// succeeded; `false` when the tap was ignored (a write is pending) or the
  /// write failed. Never throws — on failure the state is rolled back and
  /// [lastError] holds the cause.
  Future<bool> toggle() async {
    if (_busy) return false;
    final wasFollowing = _following;
    final prevFollowers = _followers;

    _busy = true;
    lastError = null;
    _following = !wasFollowing;
    _followers = wasFollowing
        ? (prevFollowers > 0 ? prevFollowers - 1 : 0)
        : prevFollowers + 1;
    _notify();

    try {
      if (wasFollowing) {
        await _unfollow();
      } else {
        await _follow();
      }
      _busy = false;
      _notify();
      return true;
    } catch (e) {
      lastError = e;
      _following = wasFollowing;
      _followers = prevFollowers;
      _busy = false;
      _notify();
      return false;
    }
  }

  /// The error of the last failed [toggle], if any.
  Object? lastError;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
