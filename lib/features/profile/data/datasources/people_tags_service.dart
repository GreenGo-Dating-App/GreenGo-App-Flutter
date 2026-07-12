import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user PRIVATE tags for PEOPLE.
///
/// Each user can tag any other person they discover with their own labels.
/// Tags are visible ONLY to that owner and never affect the target user's
/// profile or what anyone else sees. Stored in an isolated collection — one doc
/// per owner — so the Network grid costs a single cheap (cache-first) read
/// regardless of how many people were tagged, and no fan-out ever touches it.
///
/// Doc shape: `user_people_tags/{ownerId} = { peopleTags: { targetUserId: [tag, ...] } }`
class PeopleTagsService {
  PeopleTagsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _col = 'user_people_tags';
  static const int maxTagLength = 24;
  static const int maxTagsPerPerson = 12;

  DocumentReference<Map<String, dynamic>> _doc(String ownerId) =>
      _firestore.collection(_col).doc(ownerId);

  /// Streams the owner's full `{targetUserId: [tags]}` map (empty when unset).
  Stream<Map<String, List<String>>> watchAll(String ownerId) =>
      _doc(ownerId).snapshots().map(_parse);

  /// One-time read of the owner's `{targetUserId: [tags]}` map.
  Future<Map<String, List<String>>> getAll(String ownerId) async =>
      _parse(await _doc(ownerId).get());

  Map<String, List<String>> _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    final raw = snap.data()?['peopleTags'];
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

  /// Replaces the tag list for one person (an empty list clears it entirely).
  Future<void> setTagsForPerson({
    required String ownerId,
    required String targetUserId,
    required List<String> tags,
  }) async {
    final cleaned = normalize(tags);
    await _doc(ownerId).set({
      'peopleTags': {
        targetUserId: cleaned.isEmpty ? FieldValue.delete() : cleaned,
      },
    }, SetOptions(merge: true));
  }

  /// Adds a single tag to a person (merged with any existing tags).
  Future<void> addTagForPerson({
    required String ownerId,
    required String targetUserId,
    required String tag,
    List<String> existing = const [],
  }) async {
    await setTagsForPerson(
      ownerId: ownerId,
      targetUserId: targetUserId,
      tags: [...existing, tag],
    );
  }

  /// Removes a single tag from a person (case-insensitive).
  Future<void> removeTagForPerson({
    required String ownerId,
    required String targetUserId,
    required String tag,
    required List<String> existing,
  }) async {
    final lower = tag.trim().toLowerCase();
    final next =
        existing.where((t) => t.toLowerCase() != lower).toList();
    await setTagsForPerson(
      ownerId: ownerId,
      targetUserId: targetUserId,
      tags: next,
    );
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
      if (out.length >= maxTagsPerPerson) break;
    }
    return out;
  }
}
