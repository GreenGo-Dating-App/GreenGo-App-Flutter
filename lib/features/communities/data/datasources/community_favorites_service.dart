import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user PRIVATE favorite communities.
///
/// Each user can star any community to save it as a favorite. Favorites are
/// visible ONLY to that user and never touch the community document or other
/// members. Stored in an isolated collection — ONE doc per user holding an id
/// array — so the Communities page costs a single cheap read regardless of how
/// many favorites, and toggling is an atomic arrayUnion/arrayRemove.
///
/// Doc shape: `user_favorite_communities/{userId} = { communityIds: [id, ...] }`
class CommunityFavoritesService {
  CommunityFavoritesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _col = 'user_favorite_communities';

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_col).doc(userId);

  /// One-time read of the user's favorite community-id set (empty when unset).
  Future<Set<String>> getAll(String userId) async =>
      _parse(await _doc(userId).get());

  /// Streams the user's favorite community-id set (empty when unset).
  Stream<Set<String>> watchAll(String userId) =>
      _doc(userId).snapshots().map(_parse);

  Set<String> _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    final raw = snap.data()?['communityIds'];
    if (raw is! List) return <String>{};
    return raw.whereType<String>().toSet();
  }

  /// Atomically add/remove [communityId] from the user's favorites.
  Future<void> setFavorite(
    String userId,
    String communityId,
    bool favorite,
  ) async {
    await _doc(userId).set({
      'communityIds': favorite
          ? FieldValue.arrayUnion([communityId])
          : FieldValue.arrayRemove([communityId]),
    }, SetOptions(merge: true));
  }
}
