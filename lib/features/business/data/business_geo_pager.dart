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
    this.blockedIds = const <String>{},
    this.pageSize = defaultPageSize,
    DateTime Function()? clock,
    GetOptions options = const GetOptions(),
  }) : _clock = clock ?? DateTime.now {
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
  final Set<String> blockedIds;
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
        blockedIds: blockedIds,
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

  /// The next page, nearest first (empty when nothing more exists).
  Future<List<Profile>> nextPage() async {
    final radius = radiusKm?.toDouble();
    for (var i = 0;
        i < _maxScansPerPage && _buffer.length < pageSize && !_done;
        i++) {
      final ring = await _scanner.next();
      for (final p in ring) {
        // Rings arrive in distance order; anything past the filter is dropped
        // (a later best-effort ring may still hold closer ones, see below).
        if (radius == null || _km(p) <= radius) _buffer.add(p);
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
