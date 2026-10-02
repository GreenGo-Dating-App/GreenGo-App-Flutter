import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../cache/last_result_cache.dart';

/// Shared service for fetching and caching blocked user IDs.
///
/// Provides a single source of truth for blocked-user lookups across
/// discovery, chat, and any other feature that needs to filter by blocks.
///
/// Caching, fastest first:
///  * in memory, fresh for 5 minutes;
///  * on disk ([LastResultCache], key `blocked_ids:<uid>`), so a cold start
///    knows the last set without a round trip;
///  * the server: the two directions are queried TOGETHER (one round trip).
///
/// [getBlockedUserIds] answers from a fresh memory copy, otherwise refreshes
/// from the server; when a server refresh is needed but an older copy (memory
/// or disk) exists, that copy is returned immediately and the refresh runs in
/// the background (stale-while-revalidate). After [invalidate] (a block or
/// unblock just happened) the next call always waits for the server.
///
/// [lastKnownBlockedIds] gives the last known set synchronously, for callers
/// that want to filter a first paint without awaiting anything.
class BlockedUsersService {
  BlockedUsersService({required this.firestore});
  final FirebaseFirestore firestore;

  static const _cacheTtl = Duration(minutes: 5);
  static const _diskMaxAge = Duration(days: 1);
  static const _queryLimit = 1000;

  final Map<String, _CachedBlockedIds> _cache = {};
  final Map<String, Future<Set<String>?>> _inflight = {};
  final Set<String> _diskChecked = {};
  // Users whose cached set is known to be out of date (block/unblock just
  // happened); their next lookup must wait for the server.
  final Set<String> _mustRefresh = {};
  // Bumped by [invalidate]/[clearAll] so a fetch that started before a block
  // or unblock can't store its (now outdated) result.
  final Map<String, int> _generation = {};

  // Broadcasts the BLOCKED user's id each time a block happens anywhere, so live
  // lists (discovery, network, chat) can drop that user IMMEDIATELY without a
  // refetch (the fetch-time filter alone only reflects a block on next reload).
  final StreamController<String> _blockedController =
      StreamController<String>.broadcast();

  /// Fires with the blocked user's id whenever any block is performed.
  Stream<String> get onUserBlocked => _blockedController.stream;

  /// Announce that [blockedUserId] was just blocked (call after the block write).
  void notifyBlocked(String blockedUserId) {
    if (!_blockedController.isClosed) _blockedController.add(blockedUserId);
  }

  static String _diskKey(String userId) => 'blocked_ids:$userId';

  /// The last known blocked set for [userId], without waiting (may be empty
  /// or slightly stale). Pair it with [getBlockedUserIds] for the fresh set.
  Set<String> lastKnownBlockedIds(String userId) =>
      _cache[userId]?.ids ?? const <String>{};

  /// Returns the set of user IDs that are blocked bidirectionally
  /// (users the given [userId] blocked + users who blocked [userId]).
  Future<Set<String>> getBlockedUserIds(String userId) async {
    final cached = _cache[userId];
    if (cached != null && cached.isValid && !_mustRefresh.contains(userId)) {
      return cached.ids;
    }

    // Cold start: pick up the set this device saw last time.
    if (cached == null && !_diskChecked.contains(userId)) {
      _diskChecked.add(userId);
      final disk = await _loadFromDisk(userId);
      if (disk != null && _cache[userId] == null) {
        _cache[userId] = _CachedBlockedIds(disk, stale: true);
      }
    }

    final refresh = _refresh(userId);
    final known = _cache[userId];
    if (known != null && !_mustRefresh.contains(userId)) {
      // Serve the older copy now; the refresh updates it in the background.
      unawaited(refresh);
      return known.ids;
    }

    // Never let a blocklist hiccup take down the caller. This runs inside the
    // conversations stream's asyncMap, where a thrown error kills the whole
    // stream — which is how the Exchanges chat list ended up permanently
    // empty. Degrading to "no blocks known" is the safe failure mode.
    final fresh = await refresh;
    return fresh ?? _cache[userId]?.ids ?? <String>{};
  }

  /// One shared server refresh per user at a time. Null on failure.
  Future<Set<String>?> _refresh(String userId) {
    final running = _inflight[userId];
    if (running != null) return running;
    final f = _fetch(userId);
    _inflight[userId] = f;
    f.whenComplete(() {
      if (identical(_inflight[userId], f)) _inflight.remove(userId);
    });
    return f;
  }

  Future<Set<String>?> _fetch(String userId) async {
    final gen = _generation[userId] ?? 0;
    try {
      final col = firestore.collection('blockedUsers');
      // Both directions in parallel: one round trip instead of two.
      final results = await Future.wait([
        // Users I blocked
        col.where('blockerId', isEqualTo: userId).limit(_queryLimit).get(),
        // Users who blocked me
        col.where('blockedUserId', isEqualTo: userId).limit(_queryLimit).get(),
      ]);

      final blockedIds = <String>{};
      for (final doc in results[0].docs) {
        final blockedUserId = doc.data()['blockedUserId'] as String?;
        if (blockedUserId != null) blockedIds.add(blockedUserId);
      }
      for (final doc in results[1].docs) {
        final blockerId = doc.data()['blockerId'] as String?;
        if (blockerId != null) blockedIds.add(blockerId);
      }

      if ((_generation[userId] ?? 0) != gen) {
        // A block/unblock happened meanwhile: this result may predate it, so
        // hand the caller a fresh read instead.
        return _refresh(userId);
      }
      _cache[userId] = _CachedBlockedIds(blockedIds);
      _mustRefresh.remove(userId);
      unawaited(
          LastResultCache.saveJson(_diskKey(userId), blockedIds.toList()));
      debugPrint(
          '[BlockedUsersService] Cache stored for $userId (${blockedIds.length} ids)');
      return blockedIds;
    } catch (e) {
      // Not cached: a transient failure should be retried on the next read.
      debugPrint('[BlockedUsersService] Lookup failed for $userId: $e');
      return null;
    }
  }

  Future<Set<String>?> _loadFromDisk(String userId) async {
    try {
      final v = await LastResultCache.loadJson(_diskKey(userId),
          maxAge: _diskMaxAge);
      if (v is List) return v.whereType<String>().toSet();
    } catch (_) {}
    return null;
  }

  /// Invalidate the cache for a specific user (call after block/unblock).
  void invalidate(String userId) {
    _cache.remove(userId);
    _inflight.remove(userId);
    _generation[userId] = (_generation[userId] ?? 0) + 1;
    _mustRefresh.add(userId);
    // Never serve the pre-change set from disk either.
    _diskChecked.add(userId);
    unawaited(LastResultCache.saveJson(_diskKey(userId), null));
    debugPrint('[BlockedUsersService] Cache invalidated for $userId');
  }

  /// Clear all cached data.
  void clearAll() {
    _cache.clear();
    _inflight.clear();
    for (final k in _generation.keys.toList()) {
      _generation[k] = _generation[k]! + 1;
    }
    _diskChecked.clear();
    _mustRefresh.clear();
    debugPrint('[BlockedUsersService] All caches cleared');
  }
}

class _CachedBlockedIds {
  _CachedBlockedIds(this.ids, {bool stale = false})
      : fetchedAt = stale
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.now();
  final Set<String> ids;
  final DateTime fetchedAt;

  bool get isValid =>
      DateTime.now().difference(fetchedAt) < BlockedUsersService._cacheTtl;
}
