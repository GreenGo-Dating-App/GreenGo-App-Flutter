import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Warms the local Firestore cache for the heaviest first-load queries as early
/// as possible (right after login / main navigation init), in parallel.
///
/// Firestore offline persistence is already enabled, so once these documents
/// are in the local cache every screen renders instantly from cache while the
/// live listeners reconcile in the background. This service simply fires those
/// reads concurrently and up-front so the data is ready before the user taps a
/// tab. All reads are best-effort and never throw.
class DataPreloadService {
  DataPreloadService._();
  static final DataPreloadService instance = DataPreloadService._();

  bool _done = false;

  /// Fire-and-forget; safe to call multiple times (runs once per session).
  Future<void> warm(String userId) async {
    if (_done || userId.isEmpty) return;
    _done = true;
    final fs = FirebaseFirestore.instance;

    Future<void> guard(Future<Object?> f) async {
      try {
        await f;
      } catch (_) {/* best-effort cache warming */}
    }

    await Future.wait([
      // Own profile (used everywhere).
      guard(fs.collection('profiles').doc(userId).get()),
      // 1:1 conversations inbox.
      guard(fs
          .collection('conversations')
          .where(Filter.or(
            Filter('userId1', isEqualTo: userId),
            Filter('userId2', isEqualTo: userId),
          ))
          .limit(30)
          .get()),
      // Group conversations (per-user inbox index).
      guard(fs
          .collection('user_group_inbox')
          .doc(userId)
          .collection('threads')
          .orderBy('updatedAt', descending: true)
          .limit(30)
          .get()),
      // Upcoming events (Events tab first paint).
      guard(fs
          .collection('events')
          .where('status', isEqualTo: 'published')
          .orderBy('startDate')
          .limit(30)
          .get()),
    ]);
    debugPrint('DataPreloadService: cache warmed for $userId');
  }

  /// Reset for a new session (e.g. after sign-out).
  void reset() => _done = false;
}
