import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user PRIVATE tags for PEOPLE.
///
/// Each user can tag any other person they discover with their own labels.
/// Tags are visible ONLY to that owner and never affect the target user's
/// profile or what anyone else sees. Stored in an isolated collection — one doc
/// per owner — so the Network grid costs a single cheap (cache-first) read
/// regardless of how many people were tagged, and no fan-out ever touches it.
///
/// Doc shape:
/// `user_people_tags/{ownerId} = {
///    peopleTags: { targetUserId: [tag, ...] },
///    recentTags: [tag, ...]   // most-recently-used first, capped
/// }`
///
/// `recentTags` only orders the owner's tag library in the tag editor; the
/// source of truth for "which tags exist" is the union of `peopleTags`.
class PeopleTagsService {
  PeopleTagsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _col = 'user_people_tags';
  static const String _tagsField = 'peopleTags';
  static const String _recentField = 'recentTags';
  static const int maxTagLength = 24;
  static const int maxTagsPerPerson = 12;

  /// Upper bound on the distinct tags offered in the editor's library (and on
  /// the persisted `recentTags` list).
  static const int maxLibraryTags = 100;

  /// Session cache of each owner's tag doc, so reopening the editor is instant.
  /// Kept fresh by [watchAll] (the Network grid's live subscription), by
  /// [getLibrary] and optimistically by every write through this service.
  static final Map<String, PeopleTagsLibrary> _cache = {};

  /// Test hook: clears the session cache.
  static void clearCache() => _cache.clear();

  DocumentReference<Map<String, dynamic>> _doc(String ownerId) =>
      _firestore.collection(_col).doc(ownerId);

  /// Streams the owner's full `{targetUserId: [tags]}` map (empty when unset).
  Stream<Map<String, List<String>>> watchAll(String ownerId) =>
      _doc(ownerId).snapshots().map((snap) {
        final lib = _parseLibrary(snap);
        _cache[ownerId] = lib;
        return lib.peopleTags;
      });

  /// One-time read of the owner's `{targetUserId: [tags]}` map.
  Future<Map<String, List<String>>> getAll(String ownerId) async =>
      (await getLibrary(ownerId, forceRefresh: true)).peopleTags;

  /// The session-cached library for [ownerId], or null if not loaded yet.
  PeopleTagsLibrary? cachedLibrary(String ownerId) => _cache[ownerId];

  /// The owner's tag library (per-person tags + MRU order). Served from the
  /// session cache when present; otherwise a single bounded doc read.
  Future<PeopleTagsLibrary> getLibrary(
    String ownerId, {
    bool forceRefresh = false,
  }) async {
    final cached = _cache[ownerId];
    if (cached != null && !forceRefresh) return cached;
    final lib = _parseLibrary(await _doc(ownerId).get());
    _cache[ownerId] = lib;
    return lib;
  }

  PeopleTagsLibrary _parseLibrary(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    final out = <String, List<String>>{};
    final raw = data?[_tagsField];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is List) {
          final tags = value.whereType<String>().toList();
          if (tags.isNotEmpty) out[key.toString()] = tags;
        }
      });
    }
    final rawRecent = data?[_recentField];
    final recent = rawRecent is List
        ? rawRecent.whereType<String>().take(maxLibraryTags).toList()
        : const <String>[];
    return PeopleTagsLibrary(peopleTags: out, recent: recent);
  }

  /// Replaces the tag list for one person (an empty list clears it entirely).
  ///
  /// [bump] are tags just used by the owner; they move to the front of the
  /// library's most-recently-used order.
  Future<void> setTagsForPerson({
    required String ownerId,
    required String targetUserId,
    required List<String> tags,
    List<String> bump = const [],
  }) async {
    final cleaned = normalize(tags);
    final before = _cache[ownerId] ?? await getLibrary(ownerId);

    final nextMap = Map<String, List<String>>.of(before.peopleTags);
    if (cleaned.isEmpty) {
      nextMap.remove(targetUserId);
    } else {
      nextMap[targetUserId] = cleaned;
    }
    final nextRecent = _nextRecent(
      bump: bump,
      previous: before.recent,
      peopleTags: nextMap,
    );
    final after = PeopleTagsLibrary(peopleTags: nextMap, recent: nextRecent);

    // Optimistic cache update so the editor/grid reflect the change instantly;
    // rolled back if the write fails.
    _cache[ownerId] = after;
    try {
      await _doc(ownerId).set({
        _tagsField: {
          targetUserId: cleaned.isEmpty ? FieldValue.delete() : cleaned,
        },
        _recentField: nextRecent,
      }, SetOptions(merge: true));
    } catch (_) {
      if (identical(_cache[ownerId], after)) _cache[ownerId] = before;
      rethrow;
    }
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
      bump: [tag],
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

  /// New MRU list: [bump] first, then the previous order, then any in-use tag
  /// not yet ranked; restricted to tags still applied to someone, de-duped
  /// case-insensitively and capped at [maxLibraryTags].
  static List<String> _nextRecent({
    required List<String> bump,
    required List<String> previous,
    required Map<String, List<String>> peopleTags,
  }) {
    final inUse = <String>{
      for (final tags in peopleTags.values)
        for (final t in tags) t.toLowerCase(),
    };
    final seen = <String>{};
    final out = <String>[];
    for (final t in [
      ...bump.map((t) => t.trim()),
      ...previous,
      ...PeopleTagsLibrary.rankUnordered(peopleTags),
    ]) {
      final key = t.toLowerCase();
      if (t.isEmpty || !inUse.contains(key) || !seen.add(key)) continue;
      out.add(t);
      if (out.length >= maxLibraryTags) break;
    }
    return out;
  }

  /// Trim, drop empties, de-dupe case-insensitively, cap length & count.
  static List<String> normalize(List<String> tags) {
    final seen = <String>{};
    final out = <String>[];
    for (var t in tags) {
      t = cleanTag(t);
      if (t.isEmpty) continue;
      if (seen.add(t.toLowerCase())) out.add(t);
      if (out.length >= maxTagsPerPerson) break;
    }
    return out;
  }

  /// Trims a single raw tag and caps it at [maxTagLength].
  static String cleanTag(String raw) {
    var t = raw.trim();
    if (t.length > maxTagLength) t = t.substring(0, maxTagLength).trim();
    return t;
  }
}

/// Snapshot of an owner's private people tags plus their MRU ordering.
class PeopleTagsLibrary {
  const PeopleTagsLibrary({required this.peopleTags, required this.recent});

  /// `{targetUserId: [tags]}`.
  final Map<String, List<String>> peopleTags;

  /// Most-recently-used tags first (may be empty for legacy docs).
  final List<String> recent;

  /// Tags currently applied to [targetUserId].
  List<String> tagsFor(String targetUserId) =>
      peopleTags[targetUserId] ?? const <String>[];

  /// Every distinct tag the owner uses (case-insensitive), most-recently-used
  /// first; tags never ranked (legacy data) follow by usage count, then A–Z.
  /// Capped at [PeopleTagsService.maxLibraryTags].
  List<String> get allTags {
    final inUse = <String>{
      for (final tags in peopleTags.values)
        for (final t in tags) t.toLowerCase(),
    };
    final seen = <String>{};
    final out = <String>[];
    for (final t in [...recent, ...rankUnordered(peopleTags)]) {
      final key = t.toLowerCase();
      if (!inUse.contains(key) || !seen.add(key)) continue;
      out.add(t);
      if (out.length >= PeopleTagsService.maxLibraryTags) break;
    }
    return out;
  }

  /// All tags in [peopleTags] ordered by usage count desc, then A–Z.
  static List<String> rankUnordered(Map<String, List<String>> peopleTags) {
    final counts = <String, int>{};
    final spelling = <String, String>{};
    for (final tags in peopleTags.values) {
      for (final t in tags) {
        final key = t.toLowerCase();
        counts[key] = (counts[key] ?? 0) + 1;
        spelling.putIfAbsent(key, () => t);
      }
    }
    final keys = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    return [for (final k in keys) spelling[k]!];
  }
}
