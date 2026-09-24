import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/geo_query.dart';

/// Nearest-first scan of a geohash-indexed collection with BOUNDED reads.
///
/// Each [next] returns the next ring (annulus) of matching documents ordered
/// by true distance, so concatenated pages are globally closest-first.
///
/// Why not "query every geohash range of radius r, then 3r, ...": each ring
/// re-read everything inside the previous one with no limit, so a dense city
/// cost thousands of reads per open. Here:
///  * every range query carries `.limit(perQueryLimit)`;
///  * geohash intervals already read are remembered and subtracted, so an outer
///    ring only reads its NEW area (the annulus), never the inner rings again;
///  * a ring whose ranges hit the limit (dense area) is shrunk rather than read
///    to exhaustion, so a ring is only emitted once everything inside it has
///    been read — which is what keeps the order correct, since geohash ranges
///    are rectangles, not circles;
///  * a truncated range resumes from a document cursor, so many documents on
///    ONE geohash (a venue, a city centroid) are paged through, never skipped;
///  * each [next] issues at most [maxRoundsPerCall] read rounds.
class GeoRingScanner<T> {
  GeoRingScanner({
    required Query<Map<String, dynamic>> base,
    required this.lat,
    required this.lng,
    required this.parse,
    required this.position,
    this.perQueryLimit = 50,
    double startRadiusM = 50000,
    this.minRadiusM = 200,
    this.maxRoundsPerCall = 6,
    this.options = const GetOptions(),
  })  : _base = base.orderBy('geohash'),
        _radiusM = startRadiusM;

  final Query<Map<String, dynamic>> _base;
  final double lat;
  final double lng;

  /// Builds an item, or null to drop the document (filtered out).
  final T? Function(QueryDocumentSnapshot<Map<String, dynamic>> doc) parse;

  /// The item's coordinates, or null (dropped: can't be distance-ordered).
  final ({double lat, double lng})? Function(T item) position;

  final int perQueryLimit;
  final double minRadiusM;

  /// Latency/read budget for one [next]. When it runs out the ring read so far
  /// is returned best-effort (possibly empty while [hasMore]); unread documents
  /// are never lost, they surface in a later ring.
  final int maxRoundsPerCall;
  final GetOptions options;

  /// Half the Earth's circumference: every point is within this radius.
  static const double _globalM = 20040000;

  /// Extra limited reads allowed for a ring that cannot shrink any further
  /// before it is emitted best-effort.
  static const int _maxTopUps = 4;

  double _radiusM;
  double _emittedM = 0;
  bool _exhausted = false;
  int _rounds = 0;

  /// Geohash intervals fully read so far, half-open [start, end).
  final List<(String, String)> _covered = [];

  /// Where a truncated range continues: keyed by the geohash the uncovered
  /// remainder starts at, the last document read there. Resuming AFTER that
  /// document (geohash, then document id — Firestore's implicit tie-break, so
  /// no extra index) reads the rest of that geohash instead of re-reading or
  /// skipping it.
  final Map<String, DocumentSnapshot<Map<String, dynamic>>> _resume = {};

  /// Read but not yet emitted (outside the rings emitted so far).
  final Map<String, (T, double)> _pending = {};
  final Set<String> _fetched = {};

  bool get hasMore => !_exhausted;

  /// Number of parallel read rounds issued so far (for callers' latency caps).
  int get rounds => _rounds;

  /// Once the bounding box reaches a pole (or half the globe) GeoQuery's
  /// 9-point box degenerates onto one longitude half, so from there on the ring
  /// is simply "the whole geohash range".
  bool _isGlobal(double r) =>
      r >= _globalM || lat.abs() + r / _metersPerDegreeLat >= 90;
  static const double _metersPerDegreeLat = 110574;

  /// The next ring, nearest first. Empty once the collection is exhausted, or
  /// when this call's read budget ran out before anything matched.
  Future<List<T>> next() async {
    final budget = _rounds + maxRoundsPerCall;
    bool spent() => _rounds >= budget;
    while (!_exhausted) {
      final r = _radiusM;
      final global = _isGlobal(r);
      var complete = await _cover(r, global);
      // Dense: emit a smaller ring first instead of reading this one out.
      final smaller = _emittedM + (r - _emittedM) / 3;
      if (!complete &&
          !global &&
          !spent() &&
          smaller >= minRadiusM &&
          smaller - _emittedM >= minRadiusM / 2) {
        _radiusM = smaller;
        continue;
      }
      // The global ring pages instead (one limited read per gap per call).
      for (var i = 0; !complete && !global && !spent() && i < _maxTopUps; i++) {
        complete = await _cover(r, global);
      }

      final ring = <(T, double)>[];
      _pending.removeWhere((_, v) {
        if (global || v.$2 <= r) {
          ring.add(v);
          return true;
        }
        return false;
      });
      ring.sort((a, b) => a.$2.compareTo(b.$2));
      _emittedM = r;
      if (global) {
        if (complete) _exhausted = true;
      } else {
        _radiusM = math.min(r * 3, _globalM);
      }
      if (ring.isNotEmpty || spent()) return ring.map((e) => e.$1).toList();
    }
    return const [];
  }

  /// Reads the not-yet-covered parts of the geohash ranges for radius [r]
  /// (one limited query each, in parallel). True when nothing was truncated,
  /// i.e. every document inside those ranges has now been read.
  Future<bool> _cover(double r, bool global) async {
    final bounds = global
        ? const [
            ['0', '~']
          ]
        : GeoQuery.queryBounds(lat, lng, r);
    final todo = <(String, String)>[];
    for (final b in bounds) {
      todo.addAll(_uncovered(b[0], b[1]));
    }
    if (todo.isEmpty) return true;
    _rounds++;
    final snaps = await Future.wait(todo.map((iv) {
      final cursor = _resume[iv.$1];
      final from = cursor != null
          ? _base.startAfterDocument(cursor)
          : _base.startAt([iv.$1]);
      return from.endBefore([iv.$2]).limit(perQueryLimit).get(options);
    }));

    var complete = true;
    for (var i = 0; i < todo.length; i++) {
      final (start, end) = todo[i];
      final docs = snaps[i].docs;
      for (final doc in docs) {
        if (!_fetched.add(doc.id)) continue;
        final item = parse(doc);
        if (item == null) continue;
        final p = position(item);
        if (p == null) continue;
        _pending[doc.id] =
            (item, GeoQuery.distanceMeters(lat, lng, p.lat, p.lng));
      }
      final last = docs.isEmpty ? null : docs.last.data()['geohash'];
      if (docs.length < perQueryLimit || last is! String) {
        _covered.add((start, end));
        _resume.remove(start);
        continue;
      }
      complete = false;
      // Truncated: [start, last) is fully read; geohash `last` is read up to
      // docs.last, so the remainder resumes right after that document.
      if (last.compareTo(start) > 0) {
        _covered.add((start, last));
        _resume.remove(start);
      }
      _resume[last] = docs.last;
    }
    return complete;
  }

  /// Parts of [start, end) not already covered.
  List<(String, String)> _uncovered(String start, String end) {
    var parts = <(String, String)>[(start, end)];
    for (final (cs, ce) in _covered) {
      final nextParts = <(String, String)>[];
      for (final (s, e) in parts) {
        if (ce.compareTo(s) <= 0 || cs.compareTo(e) >= 0) {
          nextParts.add((s, e)); // no overlap
          continue;
        }
        if (s.compareTo(cs) < 0) nextParts.add((s, cs));
        if (ce.compareTo(e) < 0) nextParts.add((ce, e));
      }
      parts = nextParts;
      if (parts.isEmpty) break;
    }
    return parts;
  }
}
