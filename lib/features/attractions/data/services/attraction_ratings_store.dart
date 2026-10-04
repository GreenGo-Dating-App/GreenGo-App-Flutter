import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../domain/attraction_rating.dart';

/// Reads the GreenGo rating of up to 30 attractions in ONE query.
typedef AttractionStatsChunkFetcher = Future<Map<int, AttractionRatingSummary>>
    Function(List<int> ids);

/// Session memo of GreenGo users' attraction ratings for the cards (grid,
/// list, Explore "Featured attractions").
///
/// The catalogue comes from static index shards, so ratings live apart in
/// `attraction_stats/{id}`. Cards never read per tile: a screen hands the ids
/// it is ACTUALLY displaying to [ensure], which reads only the ones not yet
/// fetched this session, in `whereIn(documentId)` chunks of [chunkSize]
/// running in parallel, then notifies listeners once so the cards repaint.
/// Never the whole country, never blocking the first screen.
///
/// The last values are persisted (LastResultCache.saveJson) so a cold start
/// paints the rating lines instantly; they are still refreshed once per
/// session.
class AttractionRatingsStore extends ChangeNotifier {
  AttractionRatingsStore({
    AttractionStatsChunkFetcher? fetchChunk,
    Future<Object?> Function()? loadPersisted,
    Future<void> Function(Object? value)? savePersisted,
    FirebaseFirestore? firestore,
    this.persistDelay = const Duration(seconds: 2),
  })  : _fetchChunk = fetchChunk,
        _loadPersisted = loadPersisted,
        _savePersisted = savePersisted,
        _firestore = firestore;

  /// App-wide instance (one memo per session).
  static final AttractionRatingsStore instance = AttractionRatingsStore();

  /// Firestore's `whereIn` limit.
  static const int chunkSize = 30;
  static const String persistKey = 'attraction_ratings_v1';
  static const int maxPersisted = 500;

  /// A failed chunk is not retried for this long (no read storm offline).
  static const Duration retryAfter = Duration(seconds: 60);

  final AttractionStatsChunkFetcher? _fetchChunk;
  final Future<Object?> Function()? _loadPersisted;
  final Future<void> Function(Object? value)? _savePersisted;
  final FirebaseFirestore? _firestore;
  final Duration persistDelay;

  /// Most-recently-touched last, so the persisted cap keeps the newest.
  final LinkedHashMap<int, AttractionRatingSummary> _values = LinkedHashMap();

  /// Ids read from the server this session.
  final Set<int> _fresh = {};
  final Map<int, Future<void>> _inflight = {};
  final Map<int, DateTime> _failedAt = {};
  Future<void>? _restoring;
  Timer? _persistTimer;

  /// The known rating of [id] (persisted or fetched), or null when unknown.
  AttractionRatingSummary? peek(int id) => _values[id];

  /// True once [id] was read from the server this session.
  @visibleForTesting
  bool isFresh(int id) => _fresh.contains(id);

  /// Splits [xs] into lists of at most [size].
  static List<List<T>> chunk<T>(List<T> xs, int size) => [
        for (var i = 0; i < xs.length; i += size)
          xs.sublist(i, i + size > xs.length ? xs.length : i + size),
      ];

  /// Makes sure the ratings of [ids] are loaded (no-op for those already read
  /// this session or in flight). Never throws.
  Future<void> ensure(Iterable<int> ids) async {
    await _restore();
    final now = DateTime.now();
    final waits = <Future<void>>[];
    final missing = <int>[];
    for (final id in ids.toSet()) {
      if (_fresh.contains(id)) continue;
      final inflight = _inflight[id];
      if (inflight != null) {
        waits.add(inflight);
        continue;
      }
      final failed = _failedAt[id];
      if (failed != null && now.difference(failed) < retryAfter) continue;
      missing.add(id);
    }
    if (missing.isEmpty) {
      if (waits.isNotEmpty) await Future.wait(waits);
      return;
    }
    var changed = false;
    for (final part in chunk(missing, chunkSize)) {
      final f = _load(part).then((c) => changed |= c);
      for (final id in part) {
        _inflight[id] = f;
      }
      waits.add(f);
    }
    await Future.wait(waits);
    if (changed) {
      notifyListeners();
      _schedulePersist();
    }
  }

  /// One chunk; returns true when any visible value changed.
  Future<bool> _load(List<int> ids) async {
    try {
      final got = await (_fetchChunk ?? _firestoreChunk)(ids);
      var changed = false;
      for (final id in ids) {
        final v = got[id] ?? AttractionRatingSummary.empty;
        _fresh.add(id);
        _failedAt.remove(id);
        if (_values[id] != v) changed = true;
        _touch(id, v);
      }
      return changed;
    } catch (e) {
      debugPrint('AttractionRatingsStore: chunk failed ($e)');
      final now = DateTime.now();
      for (final id in ids) {
        _failedAt[id] = now;
      }
      return false;
    } finally {
      for (final id in ids) {
        _inflight.remove(id);
      }
    }
  }

  /// A value known first-hand (the detail page's live stats doc, or the
  /// user's optimistic rating). Repaints the cards.
  void put(int id, AttractionRatingSummary value) {
    _fresh.add(id);
    if (_values[id] == value) return;
    _touch(id, value);
    notifyListeners();
    _schedulePersist();
  }

  void _touch(int id, AttractionRatingSummary v) {
    _values.remove(id);
    _values[id] = v;
  }

  Future<Map<int, AttractionRatingSummary>> _firestoreChunk(
      List<int> ids) async {
    final db = _firestore ?? FirebaseFirestore.instance;
    final snap = await db
        .collection('attraction_stats')
        .where(FieldPath.documentId, whereIn: [for (final id in ids) '$id'])
        .get();
    return {
      for (final d in snap.docs)
        if (int.tryParse(d.id) != null)
          int.parse(d.id): AttractionRatingSummary.fromStats(d.data()),
    };
  }

  // ------------------------------------------------------------ persistence

  Future<void> _restore() => _restoring ??= () async {
        try {
          final raw = await (_loadPersisted ??
              () => LastResultCache.loadJson(persistKey))();
          if (raw is! Map) return;
          var added = false;
          raw.forEach((k, v) {
            final id = int.tryParse('$k');
            final s = AttractionRatingSummary.fromJson(v);
            if (id == null || s == null || _values.containsKey(id)) return;
            _values[id] = s;
            added = true;
          });
          if (added) notifyListeners();
        } catch (_) {/* no cache: cards fill in when the reads land */}
      }();

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(persistDelay, () {
      final rated = _values.entries.where((e) => e.value.hasRatings).toList();
      final keep = rated.length > maxPersisted
          ? rated.sublist(rated.length - maxPersisted)
          : rated;
      final json = {for (final e in keep) '${e.key}': e.value.toJson()};
      unawaited((_savePersisted ??
              (v) => LastResultCache.saveJson(persistKey, v))(json)
          .catchError((_) {}));
    });
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}
