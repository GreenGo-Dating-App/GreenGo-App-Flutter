import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/events/domain/entities/external_event.dart';

/// Loads the **full** set of external events for a given source ONCE per
/// session and keeps it in memory, so the UI can order them globally by
/// distance / date / stars / reviews and paginate locally — true global
/// ordering instead of per-page sorting.
///
/// Read strategy (scales to millions of users):
///   1. Preferred — a compact **sharded index** at
///      `external_events_index/{source}_meta` + `{source}_{i}`, each shard a
///      single document holding an array of up to ~500 compact event records.
///      A whole source (5k–12k events) is then ~5–24 document reads.
///   2. Fallback — if the index hasn't been built yet, page through the raw
///      `external_events` collection (bounded) so the app still works.
///
/// Cache-first via Firestore offline persistence; memoized per source so
/// repeat tab opens are instant and cost zero extra reads.
class ExternalEventsIndexService {
  ExternalEventsIndexService._();
  static final ExternalEventsIndexService instance =
      ExternalEventsIndexService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, List<ExternalEvent>> _cache = {};
  final Map<String, Future<List<ExternalEvent>>> _inflight = {};

  /// Hard cap for the fallback full-collection read (safety bound).
  static const int _fallbackCap = 20000;

  /// All events for [source], loaded once and memoized. Safe to call repeatedly.
  Future<List<ExternalEvent>> ensureLoaded(String source) {
    final cached = _cache[source];
    if (cached != null) return Future.value(cached);
    return _inflight[source] ??= _load(source).then((list) {
      _cache[source] = list;
      _inflight.remove(source);
      return list;
    });
  }

  /// Synchronously returns what's already cached (empty if not loaded yet).
  List<ExternalEvent> cached(String source) => _cache[source] ?? const [];

  /// Force a reload on next access (used by pull-to-refresh): drops the in-memory
  /// copy and the stored version so the next load re-reads shards from the
  /// server even if the server index is unchanged.
  void invalidate(String source) {
    _cache.remove(source);
    _inflight.remove(source);
    SharedPreferences.getInstance()
        .then((p) => p.remove('extidx_${source}_ver'));
  }

  Future<List<ExternalEvent>> _load(String source) async {
    final fromIndex = await _loadFromIndex(source);
    if (fromIndex.isNotEmpty) return fromIndex;
    return _loadFromCollection(source);
  }

  /// Read the sharded compact index. Only re-downloads the shard documents when
  /// the server's index version (the meta doc's `updatedAt`) differs from what
  /// we last cached; otherwise the shards are served from the on-device
  /// Firestore cache (no network), and event images stay in the image disk
  /// cache. So nothing is re-downloaded unless the server actually refreshed.
  Future<List<ExternalEvent>> _loadFromIndex(String source) async {
    try {
      // Meta: prefer the server so we notice a refresh; fall back to cache when
      // offline so the app still loads.
      final metaRef =
          _db.collection('external_events_index').doc('${source}_meta');
      DocumentSnapshot<Map<String, dynamic>> meta;
      try {
        meta = await metaRef.get(const GetOptions(source: Source.server));
      } catch (_) {
        meta = await metaRef.get(const GetOptions(source: Source.cache));
      }
      if (!meta.exists) return const [];
      final shardCount = (meta.data()?['shardCount'] as num?)?.toInt() ?? 0;
      if (shardCount <= 0) return const [];
      final serverVer =
          (meta.data()?['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              shardCount;

      final prefs = await SharedPreferences.getInstance();
      final verKey = 'extidx_${source}_ver';
      final unchanged = prefs.getInt(verKey) == serverVer;

      // Unchanged → read shards from the local cache (no network). On a cache
      // miss (e.g. first run, cleared cache) fall back to the server.
      List<ExternalEvent> list = await _readShards(
          source, shardCount, unchanged ? Source.cache : Source.server);
      if (list.isEmpty) {
        list = await _readShards(source, shardCount, Source.server);
      }
      if (list.isNotEmpty) await prefs.setInt(verKey, serverVer);
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Read all shards for [source] from the given Firestore [src]. Returns empty
  /// if any shard is missing from that source (e.g. a cache miss), so the caller
  /// can retry against the server.
  Future<List<ExternalEvent>> _readShards(
      String source, int shardCount, Source src) async {
    try {
      final opts = GetOptions(source: src);
      final futures = <Future<DocumentSnapshot<Map<String, dynamic>>>>[];
      for (var i = 0; i < shardCount; i++) {
        futures.add(_db
            .collection('external_events_index')
            .doc('${source}_$i')
            .get(opts));
      }
      final shards = await Future.wait(futures);
      final out = <ExternalEvent>[];
      for (final s in shards) {
        if (!s.exists) return const []; // missing shard → treat as miss
        final events = s.data()?['events'];
        if (events is List) {
          for (final e in events) {
            if (e is Map) {
              out.add(ExternalEvent.fromMap(
                  null,
                  Map<String, dynamic>.from(e)
                    ..putIfAbsent('source', () => source)));
            }
          }
        }
      }
      return out;
    } catch (_) {
      // Cache miss throws for Source.cache → signal the caller to use server.
      return const [];
    }
  }

  /// Fallback: page through the raw collection (bounded) when no index exists.
  Future<List<ExternalEvent>> _loadFromCollection(String source) async {
    final out = <ExternalEvent>[];
    try {
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      while (out.length < _fallbackCap) {
        Query<Map<String, dynamic>> q = _db
            .collection('external_events')
            .where('source', isEqualTo: source)
            .orderBy('rating', descending: true)
            .limit(500);
        if (cursor != null) q = q.startAfterDocument(cursor);
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        out.addAll(snap.docs.map(ExternalEvent.fromFirestore));
        cursor = snap.docs.last;
        if (snap.docs.length < 500) break;
      }
    } catch (_) {
      // Return whatever we managed to read.
    }
    return out;
  }
}
