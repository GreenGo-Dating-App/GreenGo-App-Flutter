import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Watches `achievement_progress` (the collection achievements are actually
/// written to: doc `{uid}_{achievementId}`, fields `userId`, `achievementId`,
/// `isUnlocked`, `unlockedAt`) and reports achievements unlocked DURING this
/// session, each at most once — ever.
///
/// Guarantees (so popups never replay old unlocks):
///  * the first snapshot is a baseline and never reported;
///  * docs whose `unlockedAt` is older than the listener start (minus a small
///    clock-skew allowance for server timestamps) are ignored;
///  * every reported id is persisted in SharedPreferences per user, so an app
///    restart or a re-created listener never shows it again.
///
/// Query: `userId == uid && isUnlocked == true orderBy unlockedAt desc
/// limit 10` (composite index achievement_progress(userId, isUnlocked,
/// unlockedAt DESC)). If that query errors (index not built yet) it falls back
/// to the equality-only query (no composite index needed), bounded by the
/// catalogue size.
class AchievementUnlockWatcher {
  AchievementUnlockWatcher({
    required this.firestore,
    required this.userId,
    required this.onUnlocked,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final FirebaseFirestore firestore;
  final String userId;

  /// Called with the achievementId of each newly unlocked achievement.
  final void Function(String achievementId) onUnlocked;
  final DateTime Function() _clock;

  static const int primaryLimit = 10;
  static const int fallbackLimit = 200;
  static const int maxPersistedIds = 300;

  /// Server timestamps vs device clock: tolerate this much skew.
  static const Duration clockSkew = Duration(minutes: 2);

  static String prefsKey(String userId) => 'achievement_popups_shown_$userId';

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  late DateTime _startedAt;
  final Set<String> _baselineDocIds = {};
  final List<String> _shownIds = [];
  bool _sawFirstSnapshot = false;
  bool _usingFallback = false;
  bool _disposed = false;

  Query<Map<String, dynamic>> get _baseQuery => firestore
      .collection('achievement_progress')
      .where('userId', isEqualTo: userId)
      .where('isUnlocked', isEqualTo: true);

  Future<void> start() async {
    _startedAt = _clock();
    try {
      final prefs = await SharedPreferences.getInstance();
      _shownIds.addAll(prefs.getStringList(prefsKey(userId)) ?? const []);
    } catch (e) {
      debugPrint('AchievementUnlockWatcher: prefs read failed: $e');
    }
    if (_disposed) return;
    _listen(
      _baseQuery.orderBy('unlockedAt', descending: true).limit(primaryLimit),
    );
  }

  void _listen(Query<Map<String, dynamic>> query) {
    _sawFirstSnapshot = false;
    _sub = query.snapshots().listen(
      _onSnapshot,
      onError: (Object e) {
        debugPrint('AchievementUnlockWatcher: query failed: $e');
        if (_usingFallback || _disposed) return;
        _usingFallback = true;
        _sub?.cancel();
        _listen(_baseQuery.limit(fallbackLimit));
      },
    );
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (_disposed) return;
    if (!_sawFirstSnapshot) {
      _sawFirstSnapshot = true;
      _baselineDocIds.addAll(snapshot.docs.map((d) => d.id));
      return;
    }
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.removed) continue;
      final doc = change.doc;
      final data = doc.data();
      if (data == null || data['isUnlocked'] != true) continue;
      if (_baselineDocIds.contains(doc.id)) continue;
      _baselineDocIds.add(doc.id);

      final achievementId = data['achievementId'] as String? ??
          (doc.id.startsWith('${userId}_')
              ? doc.id.substring(userId.length + 1)
              : doc.id);
      if (_shownIds.contains(achievementId)) continue;

      final unlockedAt = data['unlockedAt'];
      // null = pending server timestamp of a write made just now -> new.
      if (unlockedAt is Timestamp &&
          unlockedAt.toDate().isBefore(_startedAt.subtract(clockSkew))) {
        continue;
      }

      _markShown(achievementId);
      onUnlocked(achievementId);
    }
  }

  void _markShown(String achievementId) {
    _shownIds.add(achievementId);
    if (_shownIds.length > maxPersistedIds) {
      _shownIds.removeRange(0, _shownIds.length - maxPersistedIds);
    }
    final snapshot = List<String>.of(_shownIds);
    unawaited(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(prefsKey(userId), snapshot);
      } catch (e) {
        debugPrint('AchievementUnlockWatcher: prefs write failed: $e');
      }
    }());
  }

  Future<void> dispose() async {
    _disposed = true;
    await _sub?.cancel();
    _sub = null;
  }
}
