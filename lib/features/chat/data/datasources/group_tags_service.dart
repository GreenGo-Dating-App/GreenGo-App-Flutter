import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user PRIVATE tags for groups.
///
/// Each user can tag any group they belong to with their own labels. Tags are
/// visible ONLY to that user and never affect the group document or other
/// members. Stored in an isolated collection — one doc per user — so the Groups
/// page costs a single cheap (cache-first) read regardless of group count, and
/// the group fan-out Cloud Functions never touch it.
///
/// Doc shape: `user_group_tags/{userId} = { groupTags: { groupId: [tag, ...] } }`
class GroupTagsService {
  GroupTagsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _col = 'user_group_tags';
  static const int maxTagLength = 24;
  static const int maxTagsPerGroup = 12;

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection(_col).doc(userId);

  /// Streams the user's full `{groupId: [tags]}` map (empty when unset).
  Stream<Map<String, List<String>>> watchAll(String userId) =>
      _doc(userId).snapshots().map(_parse);

  /// One-time read of the user's `{groupId: [tags]}` map.
  Future<Map<String, List<String>>> getAll(String userId) async =>
      _parse(await _doc(userId).get());

  Map<String, List<String>> _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    final raw = snap.data()?['groupTags'];
    if (raw is! Map) return <String, List<String>>{};
    final out = <String, List<String>>{};
    raw.forEach((key, value) {
      if (value is List) {
        final tags = value.whereType<String>().toList();
        if (tags.isNotEmpty) out[key.toString()] = tags;
      }
    });
    return out;
  }

  /// Replaces the tag list for one group (an empty list clears it entirely).
  Future<void> setTagsForGroup(
    String userId,
    String groupId,
    List<String> tags,
  ) async {
    final cleaned = normalize(tags);
    await _doc(userId).set({
      'groupTags': {
        groupId: cleaned.isEmpty ? FieldValue.delete() : cleaned,
      },
    }, SetOptions(merge: true));
  }

  /// Trim, drop empties, de-dupe case-insensitively, cap length & count.
  static List<String> normalize(List<String> tags) {
    final seen = <String>{};
    final out = <String>[];
    for (var t in tags) {
      t = t.trim();
      if (t.isEmpty) continue;
      if (t.length > maxTagLength) t = t.substring(0, maxTagLength).trim();
      if (seen.add(t.toLowerCase())) out.add(t);
      if (out.length >= maxTagsPerGroup) break;
    }
    return out;
  }
}
