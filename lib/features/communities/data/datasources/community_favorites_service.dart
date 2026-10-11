import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/community.dart';
import '../models/community_model.dart';

/// Per-user PRIVATE favorite communities.
///
/// Each user can star any community to save it as a favorite. Favorites are
/// visible ONLY to that user and never touch the community document or other
/// members. Stored in an isolated collection — ONE doc per user holding an id
/// array — so the Communities page costs a single cheap read regardless of how
/// many favorites, and toggling is an atomic arrayUnion/arrayRemove.
///
/// Doc shape: `user_favorite_communities/{userId} = { communityIds: [id, ...] }`
///
/// `arrayUnion` appends, so the array is in STARRING order (oldest first): the
/// Joined tab pins favorites newest-starred first. Capped at [maxFavorites]
/// (also enforced by firestore.rules), so the favorites section is always a
/// small bounded read — at most 2 `whereIn` queries — whatever the size of
/// the user's joined list.
class CommunityFavoritesService {
  CommunityFavoritesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _col = 'user_favorite_communities';

  /// Most communities a user can star (mirrored in firestore.rules).
  static const int maxFavorites = 50;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_col).doc(userId);

  /// One-time read of the user's favorite community-id set (empty when unset).
  Future<Set<String>> getAll(String userId) async =>
      (await getOrdered(userId)).toSet();

  /// The favorite ids in starring order (oldest first), de-duplicated.
  Future<List<String>> getOrdered(String userId) async {
    final raw = (await _doc(userId).get()).data()?['communityIds'];
    if (raw is! List) return <String>[];
    final seen = <String>{};
    return [
      for (final v in raw)
        if (v is String && seen.add(v)) v,
    ];
  }

  /// The community documents of [ids] (at most [maxFavorites]), fetched by id
  /// in chunks of 30 (the `whereIn` limit). Deleted communities are skipped.
  Future<Map<String, Community>> loadCommunities(List<String> ids) async {
    final wanted = ids.take(maxFavorites).toList();
    if (wanted.isEmpty) return <String, Community>{};
    const chunk = 30;
    final col = _firestore.collection('communities');
    final snaps = await Future.wait([
      for (var i = 0; i < wanted.length; i += chunk)
        col
            .where(FieldPath.documentId,
                whereIn: wanted.sublist(
                    i, i + chunk > wanted.length ? wanted.length : i + chunk))
            .get(),
    ]);
    return {
      for (final s in snaps)
        for (final d in s.docs) d.id: CommunityModel.fromFirestore(d),
    };
  }

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
