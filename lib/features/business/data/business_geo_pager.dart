import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../discovery/domain/discovery_visibility.dart';
import '../../events/data/datasources/geo_ring_scanner.dart';
import '../../profile/data/models/profile_model.dart';
import '../../profile/domain/entities/location.dart';
import '../../profile/domain/entities/profile.dart';

/// Discover's Businesses mode (owner rule 2026-10-19): businesses are FOUND
/// by their public storefront address ([Profile.businessAddress]), not by the
/// owner's personal location.
///
/// Reads `profiles` with `where('isBusiness', ==, true)
/// .orderBy('businessGeohash')` range queries (index
/// profiles(isBusiness ASC, businessGeohash ASC)) around the VIEWER's own
/// location through the shared [GeoRingScanner] (bounded, nearest-first rings,
/// the events pattern). `businessGeohash` is server-maintained (precision 9 of
/// the address; absent when the profile is not a business or has no usable
/// address), so every document read is a business with an address.
///
/// [nextPage] returns up to [pageSize] businesses ordered by real distance to
/// the address, each within [radiusKm] (null = worldwide). Pages concatenate
/// globally nearest-first. Visibility (blocked both ways, removed, ghost /
/// incognito, testers, incomplete) is [DiscoveryVisibility.isVisible], the
/// same predicate as the people grid.
class BusinessGeoPager {
  BusinessGeoPager({
    required FirebaseFirestore firestore,
    required this.viewerId,
    required this.lat,
    required this.lng,
    this.radiusKm,
    Set<String> blockedIds = const <String>{},
    this.pageSize = defaultPageSize,
    DateTime Function()? clock,
    GetOptions options = const GetOptions(),
  })  : _blocked = {...blockedIds},
        _clock = clock ?? DateTime.now {
    final radiusM = radiusKm == null ? null : radiusKm! * 1000.0;
    _scanner = GeoRingScanner<Profile>(
      base: firestore
          .collection('profiles')
          .where('isBusiness', isEqualTo: true),
      geohashField: kBusinessGeohashField,
      lat: lat,
      lng: lng,
      // First ring (and so the geohash precision of the first range reads)
      // from the distance filter, like events: a 10 km filter starts with
      // ~10 km cells, no filter with the scanner's default 50 km.
      startRadiusM: radiusM == null ? 50000 : math.min(radiusM, 50000),
      perQueryLimit: math.max(pageSize * 2, 20),
      options: options,
      parse: _parse,
      position: (p) {
        final a = p.businessAddress;
        return a == null ? null : (lat: a.latitude, lng: a.longitude);
      },
    );
  }

  /// Nullable factory: null when the viewer's location is unknown or not
  /// usable (callers then keep the people-pool behaviour).
  static BusinessGeoPager? forViewer({
    required FirebaseFirestore firestore,
    required String viewerId,
    required Location? viewer,
    int? radiusKm,
    Set<String> blockedIds = const <String>{},
    int pageSize = defaultPageSize,
    DateTime Function()? clock,
    GetOptions options = const GetOptions(),
  }) {
    final center = searchCenter(viewer);
    if (center == null) return null;
    return BusinessGeoPager(
      firestore: firestore,
      viewerId: viewerId,
      lat: center.lat,
      lng: center.lng,
      radiusKm: (radiusKm == null || radiusKm <= 0) ? null : radiusKm,
      blockedIds: blockedIds,
      pageSize: pageSize,
      clock: clock,
      options: options,
    );
  }

  /// The viewer's coordinates when usable (finite, in range, not 0/0).
  static ({double lat, double lng})? searchCenter(Location? viewer) {
    if (viewer == null) return null;
    final la = viewer.latitude, ln = viewer.longitude;
    if (!la.isFinite || !ln.isFinite) return null;
    if (la.abs() > 90 || ln.abs() > 180 || (la == 0 && ln == 0)) return null;
    return (lat: la, lng: ln);
  }

  static const String kBusinessGeohashField = 'businessGeohash';
  static const int defaultPageSize = 20;

  /// Scanner calls one [nextPage] may spend (each a few bounded read rounds),
  /// so a page in a sparse area can never page the whole collection.
  static const int _maxScansPerPage = 12;

  final String viewerId;
  final double lat;
  final double lng;
  final int? radiusKm;
  final Set<String> _blocked;

  /// The ids hidden from this search (blocked both ways). Grows through
  /// [addBlockedIds]; never shrinks during a search.
  Set<String> get blockedIds => Set.unmodifiable(_blocked);
  final int pageSize;
  final DateTime Function() _clock;

  late final GeoRingScanner<Profile> _scanner;
  final List<Profile> _buffer = [];
  bool _done = false;
  int _returned = 0;

  /// Whether a later [nextPage] can return more businesses.
  bool get hasMore => _buffer.isNotEmpty || !_done;

  /// Total businesses handed out so far.
  int get returnedCount => _returned;

  /// True once the scan finished without finding a single business (e.g.
  /// before the businessGeohash backfill): callers may fall back.
  bool get foundNothing => _done && _returned == 0 && _buffer.isEmpty;

  Profile? _parse(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final p = ProfileModel.fromFirestore(doc);
      if (!p.isBusiness || p.businessAddress == null) return null;
      if (!DiscoveryVisibility.isVisible(
        p,
        viewerId: viewerId,
        blockedIds: _blocked,
        allowSupport: true,
        now: _clock(),
      )) {
        return null;
      }
      return p;
    } catch (_) {
      return null; // unparseable document
    }
  }

  double _km(Profile p) {
    final a = p.businessAddress!;
    return _haversineKm(lat, lng, a.latitude, a.longitude);
  }

  /// Documents read from Firestore so far by this search (each billed once).
  int get docsRead => _scanner.docsRead;

  /// Sequential read rounds issued so far (each one network round trip; the
  /// range queries inside a round run in parallel).
  int get readRounds => _scanner.rounds;

  /// Hides more ids from now on (e.g. the fresh block list arrived after the
  /// search started with the last known one): drops buffered matches too.
  /// Callers filter what they already showed.
  void addBlockedIds(Iterable<String> ids) {
    _blocked.addAll(ids);
    _buffer.removeWhere((p) => _blocked.contains(p.userId));
  }

  /// The next page, nearest first (empty when nothing more exists).
  ///
  /// [minResults] (default [pageSize]) lets the FIRST page return as soon as
  /// a ring produced that many businesses instead of scanning on until a
  /// whole page is full: the grid paints the nearest storefronts after one
  /// ring and the endless-scroll footer fetches the rest. The page never
  /// holds more than [pageSize].
  Future<List<Profile>> nextPage({int? minResults}) async {
    final want = math.min(pageSize, math.max(1, minResults ?? pageSize));
    final radius = radiusKm?.toDouble();
    for (var i = 0;
        i < _maxScansPerPage && _buffer.length < want && !_done;
        i++) {
      final ring = await _scanner.next();
      for (final p in ring) {
        // Rings arrive in distance order; anything past the filter is dropped
        // (a later best-effort ring may still hold closer ones, see below).
        if ((radius == null || _km(p) <= radius) &&
            !_blocked.contains(p.userId)) {
          _buffer.add(p);
        }
      }
      if (!_scanner.hasMore) {
        _done = true;
      } else if (radius != null &&
          _scanner.lastRingComplete &&
          _scanner.emittedRadiusM >= radius * 1000) {
        // Everything within the filter has been read.
        _done = true;
      }
    }
    final n = math.min(pageSize, _buffer.length);
    final page = _buffer.sublist(0, n);
    _buffer.removeRange(0, n);
    _returned += page.length;
    return page;
  }

  /// Whether the viewer moved far enough from [a] to [b] for a new search to
  /// be worth its reads. GPS jitter (and the own-profile document being
  /// re-published for unrelated fields) used to restart the whole scan, and
  /// with it the first-page wait, on every few metres of movement.
  static bool centerMoved(
    ({double lat, double lng})? a,
    ({double lat, double lng})? b, {
    double thresholdKm = kRestartDistanceKm,
  }) {
    if (a == null || b == null) return a != b;
    return _haversineKm(a.lat, a.lng, b.lat, b.lng) > thresholdKm;
  }

  /// Movement that restarts the search (see [centerMoved]).
  static const double kRestartDistanceKm = 1.0;

  static double _haversineKm(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}


/// One Discover-Businesses search kept for the app session, so re-opening the
/// screen (or switching People -> Businesses again) repaints the businesses
/// already loaded with ZERO reads and continues paging from where the
/// previous visit stopped, instead of scanning the rings again.
///
/// A single entry per app session (the last search); reused only for the same
/// viewer and distance filter, a centre within
/// [BusinessGeoPager.kRestartDistanceKm] and younger than [ttl].
class BusinessGeoSessionCache {
  BusinessGeoSessionCache._();

  static const Duration ttl = Duration(minutes: 10);

  static BusinessGeoSessionEntry? _entry;

  /// The kept search for this viewer / centre / filter, or null.
  static BusinessGeoSessionEntry? lookup({
    required String viewerId,
    required ({double lat, double lng}) center,
    required int? radiusKm,
    DateTime? now,
  }) {
    final e = _entry;
    if (e == null) return null;
    final t = now ?? DateTime.now();
    if (e.pager.viewerId != viewerId ||
        e.pager.radiusKm != radiusKm ||
        t.difference(e.savedAt) > ttl ||
        BusinessGeoPager.centerMoved(
            (lat: e.pager.lat, lng: e.pager.lng), center)) {
      return null;
    }
    return e;
  }

  /// Remembers [pager] and everything it returned so far.
  static void save(BusinessGeoPager pager, List<Profile> loaded,
      {DateTime? now}) {
    _entry = BusinessGeoSessionEntry._(
        pager, List.unmodifiable(loaded), now ?? DateTime.now());
  }

  /// Forgets the kept search (sign-out, pull-to-refresh).
  static void clear() => _entry = null;
}

class BusinessGeoSessionEntry {
  BusinessGeoSessionEntry._(this.pager, this.loaded, this.savedAt);
  final BusinessGeoPager pager;
  final List<Profile> loaded;
  final DateTime savedAt;
}
