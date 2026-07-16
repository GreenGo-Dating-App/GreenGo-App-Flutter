import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/geo_query.dart';
import '../../domain/entities/external_event.dart';

/// Pages `external_events` **server-ordered** so the app downloads results
/// already filtered and in order (no client-side global re-sort):
///   • distance (default) → expanding geohash rings around the user, nearest
///     first; each `next()` returns the next ring, ordered by exact distance.
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
    this.preferCache = false,
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final String source;
  final String sort; // distance | rating | reviews | date
  final String? category;
  final double? userLat;
  final double? userLng;

  /// When true, reads come from the LOCAL cache only (instant paint on a warm
  /// session); a cold cache yields empty pages. See SessionCacheGate.
  final bool preferCache;

  GetOptions get _getOpts => GetOptions(
        source: preferCache ? Source.cache : Source.serverAndCache,
      );

  static const int pageSize = 24;

  // Field-mode cursor.
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _fieldDone = false;

  // Distance-mode (expanding rings).
  double _radiusM = 50000; // 50 km first ring
  static const double _maxRadiusM = 20000000; // ~global
  bool _distDone = false;
  final Set<String> _seen = {};

  bool get _useDistance =>
      sort == 'distance' && userLat != null && userLng != null;

  bool get hasMore => _useDistance ? !_distDone : !_fieldDone;

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

  /// A well-formed calendar date, e.g. `2026-07-15` (rejects junk like `1`).
  static final RegExp _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

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
      return d.compareTo(_todayStr) >= 0;
    }
    if (d == null || d.isEmpty) return true;
    if (_isoDate.hasMatch(d)) return d.compareTo(_todayStr) >= 0;
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
    while (out.length < pageSize && !_fieldDone) {
      Query<Map<String, dynamic>> q =
          _base.orderBy(orderField, descending: descending).limit(pageSize);
      if (_cursor != null) {
        q = q.startAfterDocument(_cursor!);
      } else if (sort == 'date') {
        // Skip PAST events server-side: startDate is ascending, so start the
        // ordered range at today. This avoids paging through the whole past
        // (which made the Live tab load endlessly) and drops malformed dates
        // like "1" (they sort before today). No new index — same orderBy field.
        q = q.startAt([_todayStr]);
      }
      final snap = await q.get(_getOpts);
      if (snap.docs.isEmpty) {
        _fieldDone = true;
        break;
      }
      _cursor = snap.docs.last;
      if (snap.docs.length < pageSize) _fieldDone = true;
      out.addAll(snap.docs
          .map(ExternalEvent.fromFirestore)
          .where(_imageOk)
          .where(_dateOk));
    }
    return out;
  }

  Future<List<ExternalEvent>> _nextDistance() async {
    final out = <ExternalEvent>[];
    // Expand rings until we collect something or cover the globe.
    while (out.isEmpty && !_distDone) {
      final radius = _radiusM;
      final bounds = GeoQuery.queryBounds(userLat!, userLng!, radius);
      final snaps = await Future.wait(bounds.map((b) {
        return _base
            .orderBy('geohash')
            .startAt([b[0]]).endAt([b[1]]).get(_getOpts);
      }));
      final ring = <ExternalEvent>[];
      for (final s in snaps) {
        for (final doc in s.docs) {
          if (_seen.contains(doc.id)) continue;
          final e = ExternalEvent.fromFirestore(doc);
          if (e.lat == null || e.lng == null) continue;
          if (!_imageOk(e)) continue;
          if (!_dateOk(e)) continue;
          final d =
              GeoQuery.distanceMeters(userLat!, userLng!, e.lat!, e.lng!);
          // Only emit within the current radius; leave farther ones (and don't
          // mark them seen) for a later, larger ring.
          if (d <= radius) {
            _seen.add(doc.id);
            ring.add(e);
          }
        }
      }
      ring.sort((a, b) => GeoQuery.distanceMeters(userLat!, userLng!, a.lat!, a.lng!)
          .compareTo(
              GeoQuery.distanceMeters(userLat!, userLng!, b.lat!, b.lng!)));
      out.addAll(ring);
      if (radius >= _maxRadiusM) {
        _distDone = true;
      } else {
        _radiusM = (radius * 3).clamp(0, _maxRadiusM).toDouble();
      }
    }
    return out;
  }
}
