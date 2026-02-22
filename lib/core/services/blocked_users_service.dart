import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Shared service for fetching and caching blocked user IDs.
///
/// Provides a single source of truth for blocked-user lookups across
/// discovery, chat, and any other feature that needs to filter by blocks.
/// Uses an in-memory cache with a 5-minute TTL to avoid redundant
/// Firestore reads within the same session.
class BlockedUsersService {
  final FirebaseFirestore firestore;

  static const _cacheTtl = Duration(minutes: 5);
  static const _queryLimit = 1000;

  final Map<String, _CachedBlockedIds> _cache = {};

  BlockedUsersService({required this.firestore});

  /// Returns the set of user IDs that are blocked bidirectionally
  /// (users the given [userId] blocked + users who blocked [userId]).
  Future<Set<String>> getBlockedUserIds(String userId) async {
    final cached = _cache[userId];
    if (cached != null && cached.isValid) {
      debugPrint('[BlockedUsersService] Cache hit for $userId (${cached.ids.length} ids)');
      return cached.ids;
    }

    final Set<String> blockedIds = {};

    // Users I blocked
    final blockedByMe = await firestore
        .collection('blockedUsers')
        .where('blockerId', isEqualTo: userId)
        .limit(_queryLimit)
        .get();

    for (final doc in blockedByMe.docs) {
      final blockedUserId = doc.data()['blockedUserId'] as String?;
      if (blockedUserId != null) blockedIds.add(blockedUserId);
    }

    // Users who blocked me
    final blockedMe = await firestore
        .collection('blockedUsers')
        .where('blockedUserId', isEqualTo: userId)
        .limit(_queryLimit)
        .get();

    for (final doc in blockedMe.docs) {
      final blockerId = doc.data()['blockerId'] as String?;
      if (blockerId != null) blockedIds.add(blockerId);
    }

    _cache[userId] = _CachedBlockedIds(blockedIds);
    debugPrint('[BlockedUsersService] Cache stored for $userId (${blockedIds.length} ids)');

    return blockedIds;
  }

  /// Invalidate the cache for a specific user (call after block/unblock).
  void invalidate(String userId) {
    _cache.remove(userId);
    debugPrint('[BlockedUsersService] Cache invalidated for $userId');
  }

  /// Clear all cached data.
  void clearAll() {
    _cache.clear();
    debugPrint('[BlockedUsersService] All caches cleared');
  }
}

class _CachedBlockedIds {
  final Set<String> ids;
  final DateTime fetchedAt;

  _CachedBlockedIds(this.ids) : fetchedAt = DateTime.now();

  bool get isValid =>
      DateTime.now().difference(fetchedAt) < BlockedUsersService._cacheTtl;
}
