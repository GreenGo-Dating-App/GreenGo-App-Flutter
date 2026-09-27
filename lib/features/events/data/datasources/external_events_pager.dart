import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/cache/last_result_cache.dart';
import '../../domain/entities/external_event.dart';
import 'geo_ring_scanner.dart';

/// Pages `external_events` **server-ordered** so the app downloads results
/// already filtered and in order (no client-side global re-sort):
///   • distance (default) → bounded nearest-first geohash rings around the
///     user ([GeoRingScanner]); each `next()` returns the next ring, ordered by
///     exact distance.
///   • date / rating / reviews → Firestore `orderBy(field)` + cursor pagination.
/// Optional category filter is a server `where('category', ==)`.
///
/// Attractions (geoapify) and experiences (viator) only surface WITH an image.
class ExternalEventsPager {
  ExternalEventsPager({
    required this.source,
    required this.sort,
    this.category,
    this.userLat,
    this.userLng,
    this.liveChunks = false,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final String source;
  final String sort; // distance | rating | reviews | date
  final String? category;
  final double? userLat;
  final double? userLng;

  /// Events > Live Events tab only: load ticketmaster in chunks of
  /// [liveChunk]. Other callers (e.g. Explore's carousels) keep the
  /// original one-ring-per-page behaviour.
  final bool liveChunks;

  /// [LastResultCache] key for the first page of a given view.
  static String cacheKey(String source, String sort, String? category) =>
      'ext_${source}_${sort}_${category ?? ''}';

  /// Records the first server page of this view so the next open paints it
  /// instantly (see [loadCached]).
  Future<void> saveFirstPage(List<ExternalEvent> page) =>
      LastResultCache.saveIds(
          cacheKey(source, sort, category), page.map((e) => e.id));

  /// The first page last shown for this view, read by id from the local cache
  /// and re-checked against today's date / image gates. Empty when nothing
  /// usable is cached. Never throws.
  Future<List<ExternalEvent>> loadCached() async {
    try {
      final docs = await LastResultCache.loadDocs(
          cacheKey(source, sort, category), _db.collection('external_events'));
      return docs
          .map((d) => ExternalEvent.fromMap(d.id, d.data() ?? const {}))
          .where(_imageOk)
          .where(_dateOk)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static const int pageSize = 24;

  /// Live Events tab (see [liveChunks]) loads in chunks of exactly this many per
  /// infinite-scroll load (fewer only when nothing more exists).
  static const int liveChunk = 20;

  /// Cap on scanner calls spent filling one Live chunk (each call is a few
  /// bounded read rounds), so a chunk can never page the whole collection.
  static const int _maxScansPerChunk = 12;

  bool get _isLive => liveChunks && source == 'ticketmaster';
  int get _chunk => _isLive ? liveChunk : pageSize;

  // Field-mode cursor.
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _fieldDone = false;

  // Distance mode: created on the first distance page.
  GeoRingScanner<ExternalEvent>? _scanner;

  bool get _useDistance =>
      sort == 'distance' && userLat != null && userLng != null;

  bool get hasMore => _useDistance
      ? (_scanner?.hasMore ?? true) || _liveBuffer.isNotEmpty
      : !_fieldDone;

  /// Only show sources that must carry an image when one is present.
  bool _imageOk(ExternalEvent e) {
    if (source == 'geoapify' || source == 'viator') {
      return e.imageUrl != null && e.imageUrl!.isNotEmpty;
    }
    return true;
  }

  /// Today (yyyy-MM-dd) — ISO strings compare lexicographically == chronological.
  String get _todayStr {
    final n = DateTime.now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}-$mm-$dd';
  }

  /// A well-formed calendar date PREFIX, e.g. `2026-07-15` or the date part of
  /// `2026-07-15T20:00:00Z` (rejects junk like `1`). Unanchored at the end so a
  /// datetime doesn't get dropped — we compare on the first 10 chars.
  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');

  /// Date gate:
  ///  • LIVE events (ticketmaster) MUST carry a well-formed, today-onward date —
  ///    null/empty/malformed values (e.g. "1") are dropped so the app never
  ///    shows a non-compliant date.
  ///  • Attractions/experiences (geoapify/viator) may be undated (they pass);
  ///    a dated one is dropped only if it's in the past.
  bool _dateOk(ExternalEvent e) {
    final d = e.startDate;
    if (source == 'ticketmaster') {
      if (d == null || !_isoDate.hasMatch(d)) return false;
      return d.substring(0, 10).compareTo(_todayStr) >= 0;
    }
    if (d == null || d.isEmpty) return true;
    if (_isoDate.hasMatch(d)) return d.substring(0, 10).compareTo(_todayStr) >= 0;
    return true;
  }

  Query<Map<String, dynamic>> get _base {
    Query<Map<String, dynamic>> q =
        _db.collection('external_events').where('source', isEqualTo: source);
    if (category != null && category!.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }
    return q;
  }

  Future<List<ExternalEvent>> next() async {
    return _useDistance ? _nextDistance() : _nextField();
  }

  Future<List<ExternalEvent>> _nextField() async {
    if (_fieldDone) return const [];
    final orderField = sort == 'reviews'
        ? 'reviewCount'
        : sort == 'date'
            ? 'startDate'
            : 'rating';
    final descending = sort != 'date'; // soonest dates first; others highest
    final out = <ExternalEvent>[];
    // Keep fetching until we have a page of image-bearing items or run out.
    while (out.length < _chunk && !_fieldDone) {
      Query<Map<String, dynamic>> q =
          _base.orderBy(orderField, descending: descending).limit(_chunk);
      if (_cursor != null) {
        q = q.startAfterDocument(_cursor!);
      } else if (sort == 'date') {
        // Skip PAST events server-side: startDate is ascending, so start the
        // ordered range at today. This avoids paging through the whole past
        // (which made the Live tab load endlessly) and drops malformed dates
        // like "1" (they sort before today). No new index — same orderBy field.
        q = q.startAt([_todayStr]);
      }
      final snap = await q.get();
      if (snap.docs.isEmpty) {
        _fieldDone = true;
        break;
      }
      _cursor = snap.docs.last;
      if (snap.docs.length < _chunk) _fieldDone = true;
      out.addAll(snap.docs
          .map(ExternalEvent.fromFirestore)
          .where(_imageOk)
          .where(_dateOk));
    }
    return out;
  }

  /// Live events not yet handed out (a ring can hold more than one chunk).
  final List<ExternalEvent> _liveBuffer = [];

  Future<List<ExternalEvent>> _nextDistance() async {
    final scanner = _scanner ??= GeoRingScanner<ExternalEvent>(
      base: _base,
      lat: userLat!,
      lng: userLng!,
      perQueryLimit: pageSize * 2,
      parse: (doc) {
        final e = ExternalEvent.fromFirestore(doc);
        return _imageOk(e) && _dateOk(e) ? e : null;
      },
      position: (e) =>
          (e.lat == null || e.lng == null) ? null : (lat: e.lat!, lng: e.lng!),
    );
    if (!_isLive) return scanner.next();

    // Live: fill a chunk of [liveChunk], nearest first. Rings arrive in
    // distance order, so appending them keeps the chunk closest-first.
    for (var i = 0;
        i < _maxScansPerChunk &&
            _liveBuffer.length < liveChunk &&
            scanner.hasMore;
        i++) {
      _liveBuffer.addAll(await scanner.next());
    }
    final n = _liveBuffer.length < liveChunk ? _liveBuffer.length : liveChunk;
    final chunk = _liveBuffer.sublist(0, n);
    _liveBuffer.removeRange(0, n);
    return chunk;
  }
}
