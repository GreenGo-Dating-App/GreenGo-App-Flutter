import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Logs what users SEARCH and CLICK (events, profiles, communities, attractions)
/// to Firestore so the backend can build recommendations later.
///
/// Design notes:
///  - Fire-and-forget: every method returns immediately and NEVER throws. All
///    errors are swallowed — logging must never break a user flow.
///  - Write-only: this service never reads from Firestore (cheap, and keeps
///    security rules trivial — `allow read: if false`).
///  - Free to run: a single small Firestore write per interaction.
///
/// Firestore shape:
///   user_interactions/{userId}/events/{autoId} = {
///     type: String,              // 'search' | 'event_view' | 'profile_view' | ...
///     targetId: String,          // id of the thing interacted with (or query text)
///     meta: Map<String, dynamic>,// optional extra context (e.g. { category })
///     createdAt: serverTimestamp,
///   }
class InteractionLogService {
  InteractionLogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Remembers the last written signature per user to drop identical
  /// back-to-back logs (e.g. rebuilds re-triggering a view log).
  final Map<String, String> _lastSignatureByUser = <String, String>{};

  /// Log a search query the user typed.
  void logSearch(String userId, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _log(userId, type: 'search', targetId: trimmed);
  }

  /// Log the user opening an event's detail view.
  void logEventView(String userId, String eventId, {String? category}) {
    _log(
      userId,
      type: 'event_view',
      targetId: eventId,
      meta: category == null ? null : <String, dynamic>{'category': category},
    );
  }

  /// Log the user opening another user's profile.
  void logProfileView(String userId, String targetUserId) {
    _log(userId, type: 'profile_view', targetId: targetUserId);
  }

  /// Log the user opening a community.
  void logCommunityView(String userId, String communityId) {
    _log(userId, type: 'community_view', targetId: communityId);
  }

  /// Log the user opening an attraction.
  void logAttractionView(String userId, String id) {
    _log(userId, type: 'attraction_view', targetId: id);
  }

  /// Internal fire-and-forget writer. Never throws.
  void _log(
    String userId, {
    required String type,
    required String targetId,
    Map<String, dynamic>? meta,
  }) {
    if (userId.isEmpty || targetId.isEmpty) return;

    // Drop identical consecutive logs from the same user.
    final signature = '$type|$targetId|${meta ?? ''}';
    if (_lastSignatureByUser[userId] == signature) return;
    _lastSignatureByUser[userId] = signature;

    // Fire-and-forget: do not await, swallow every error.
    unawaited(_write(userId, type, targetId, meta));
  }

  Future<void> _write(
    String userId,
    String type,
    String targetId,
    Map<String, dynamic>? meta,
  ) async {
    try {
      await _firestore
          .collection('user_interactions')
          .doc(userId)
          .collection('events')
          .add(<String, dynamic>{
        'type': type,
        'targetId': targetId,
        'meta': meta ?? <String, dynamic>{},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Swallow every error — interaction logging must never break a flow.
    }
  }
}
