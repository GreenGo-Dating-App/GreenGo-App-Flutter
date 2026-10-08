import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/utils/geo_query.dart';
import 'private_profile.dart';
import 'profile_geohash.dart';

/// Nearest-first reads of `profiles` by location (security P1-4).
///
/// Profiles are found by the PUBLIC, server-computed `geohash5`
/// (precision 5, ~4.9 x 4.9 km cells): up to 9 parallel
/// `orderBy('geohash5').startAt().endBefore()` range reads around the viewer,
/// each limited to [perRange] documents (single-field index; with
/// [onlyShowOnMap] the composite profiles(showOnMap, geohash5)). The 9-char
/// `geohash` is private now, so it is no longer the query key.
///
/// Until the server has computed `geohash5` for existing profiles (backfill
/// script), a scan that finds NOBODY falls back once to the legacy `geohash`
/// ranges, so discovery keeps working in the window between the app release
/// and the backfill. Once every profile has `geohash5` that fallback only
/// runs where nobody is nearby, where it costs one empty read per range.
class ProfileGeoScan {
  const ProfileGeoScan(this.firestore, {this.perRange = 40});

  final FirebaseFirestore firestore;
  final int perRange;

  /// Profiles whose discoverable cell lies within [radiusKm] of the point,
  /// de-duplicated. Throws when the queries fail (callers fall back).
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> near(
    double lat,
    double lng,
    double radiusKm, {
    bool onlyShowOnMap = false,
  }) async {
    final radiusM = radiusKm * 1000;
    final out = await _scan(
      kGeohash5Field,
      GeoQuery.queryBounds(lat, lng, radiusM, maxPrecision: kGeohash5Precision),
      onlyShowOnMap: onlyShowOnMap,
    );
    if (out.isNotEmpty) return out;
    debugPrint('[ProfileGeoScan] no geohash5 hits; legacy geohash ranges');
    return _scan(
      kProfileGeohashField,
      GeoQuery.queryBounds(lat, lng, radiusM),
      onlyShowOnMap: onlyShowOnMap,
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _scan(
    String field,
    List<List<String>> bounds, {
    required bool onlyShowOnMap,
  }) async {
    final snaps = await Future.wait(bounds.map((b) {
      Query<Map<String, dynamic>> q = firestore.collection('profiles');
      if (onlyShowOnMap) q = q.where('showOnMap', isEqualTo: true);
      return q
          .orderBy(field)
          .startAt([b[0]])
          .endBefore([b[1]])
          .limit(perRange)
          .get();
    }));
    final seen = <String>{};
    return [
      for (final s in snaps)
        for (final d in s.docs)
          if (seen.add(d.id)) d,
    ];
  }
}
