import 'package:cloud_firestore/cloud_firestore.dart';

import '../../discovery/domain/entities/match_preferences.dart';
import '../domain/entities/saved_search.dart';

/// Persists a user's named discovery searches.
///
/// A "search" is the full Network Discovery filter state: the discovery
/// [MatchPreferences], the selected private people-tags and the nickname query.
/// Saving one lets the user re-apply that exact filter set later, and optionally
/// opt into "new matches" alerts for it.
///
/// Storage: `saved_searches/{userId}/searches/{id}` — a private per-user
/// subcollection. Reads are a single bounded, index-free
/// `collection().limit(...)` query (sorted client-side), so cost is constant
/// regardless of how many users exist and no composite index is ever required.
///
/// Doc shape:
/// ```
/// {
///   name: String,
///   preferences: Map,   // MatchPreferences.toMap()
///   tags: List<String>, // selected private people-tags
///   query: String,      // nickname search text
///   alertsEnabled: bool,
///   createdAt: Timestamp,
/// }
/// ```
class SavedSearchesService {
  SavedSearchesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _rootCol = 'saved_searches';
  static const String _subCol = 'searches';

  /// Upper bound on how many saved searches we read/keep per user — keeps the
  /// list bounded and the single query cheap.
  static const int maxSaved = 100;

  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection(_rootCol)
      .doc(userId)
      .collection(_subCol);

  /// Creates a new saved search from the current filter state. Returns the new
  /// document id.
  Future<String> save({
    required String userId,
    required String name,
    required MatchPreferences preferences,
    List<String> tags = const [],
    String query = '',
    bool alertsEnabled = false,
  }) async {
    final ref = _col(userId).doc();
    await ref.set({
      'name': name.trim(),
      'preferences': preferences.toMap(),
      'tags': tags,
      'query': query.trim(),
      'alertsEnabled': alertsEnabled,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Streams the user's saved searches, newest first. Sorted client-side so the
  /// query itself needs no index.
  Stream<List<SavedSearch>> watch(String userId) {
    return _col(userId).limit(maxSaved).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => SavedSearch.fromMap(d.id, d.data()))
          .toList()
        ..sort((a, b) {
          final ad = a.createdAt;
          final bd = b.createdAt;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad); // newest first
        });
      return list;
    });
  }

  /// Permanently removes one saved search.
  Future<void> delete({required String userId, required String id}) =>
      _col(userId).doc(id).delete();

  /// Persists the alerts opt-in flag for one saved search.
  Future<void> setAlerts({
    required String userId,
    required String id,
    required bool enabled,
  }) =>
      _col(userId).doc(id).update({'alertsEnabled': enabled});
}
