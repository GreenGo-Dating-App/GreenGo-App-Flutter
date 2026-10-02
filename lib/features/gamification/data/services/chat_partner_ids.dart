import 'package:cloud_firestore/cloud_firestore.dart';

/// The other participants of a user's 1:1 conversations, capped, shared by
/// the Missions and Cultural Passport derivations.
///
/// Both screens need exactly the same list and are often opened back to
/// back, so the result is memoised briefly and concurrent callers share one
/// in-flight request (2 bounded queries instead of 4).
class ChatPartnerIds {
  ChatPartnerIds._();

  /// Max conversations read per side (`userId1` / `userId2`).
  static const int maxConversationsPerSide = 40;

  /// Max partner ids returned.
  static const int maxPartners = 30;

  static const Duration _ttl = Duration(minutes: 2);

  static final Map<String, ({DateTime at, List<String> ids})> _memo = {};
  static final Map<String, Future<List<String>>> _inFlight = {};

  /// Partner ids for [userId]. Uses two single-field equality queries (no
  /// composite index) read in parallel; the `userId1` side takes precedence
  /// when capping.
  static Future<List<String>> load(
    FirebaseFirestore firestore,
    String userId, {
    String conversationsCollection = 'conversations',
  }) {
    final hit = _memo[userId];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
      return Future.value(hit.ids);
    }
    final pending = _inFlight[userId];
    if (pending != null) return pending;

    final future = _query(firestore, userId, conversationsCollection)
        .then((ids) {
      _memo[userId] = (at: DateTime.now(), ids: ids);
      return ids;
    }).whenComplete(() => _inFlight.remove(userId));
    _inFlight[userId] = future;
    return future;
  }

  /// Drop the memo (e.g. after the user starts a new conversation).
  static void invalidate(String userId) => _memo.remove(userId);

  static Future<List<String>> _query(
    FirebaseFirestore firestore,
    String userId,
    String conversationsCollection,
  ) async {
    final snaps = await Future.wait([
      for (final field in const ['userId1', 'userId2'])
        firestore
            .collection(conversationsCollection)
            .where(field, isEqualTo: userId)
            .limit(maxConversationsPerSide)
            .get(),
    ]);

    final ids = <String>{};
    for (final snap in snaps) {
      for (final doc in snap.docs) {
        if (ids.length >= maxPartners) break;
        final data = doc.data();
        final u1 = data['userId1'] as String?;
        final u2 = data['userId2'] as String?;
        final other = u1 == userId ? u2 : u1;
        if (other != null && other.isNotEmpty && other != userId) {
          ids.add(other);
        }
      }
    }
    return List.unmodifiable(ids);
  }
}
