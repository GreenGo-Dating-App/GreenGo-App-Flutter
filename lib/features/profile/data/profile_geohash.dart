import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/geo_query.dart';

/// `profiles/{uid}.geohash` — the geohash (9 chars) of the profile's
/// DISCOVERABLE location: the active travel location while traveller mode is
/// on, else the home `location`. Discovery / Explore Map query it with
/// `orderBy('geohash')` range reads (GeoQuery.queryBounds) to fetch people
/// near the viewer first instead of scanning the collection.
///
/// Must match functions/src/discovery/profileGeohash.ts (backfill), which
/// applies the same rules server-side.
const String kProfileGeohashField = 'geohash';
const int kProfileGeohashPrecision = 9;

/// Coordinates are usable when finite, in range and not the (0, 0) "unset"
/// placeholder the app writes for unknown locations.
bool _validCoords(double? lat, double? lng) =>
    lat != null &&
    lng != null &&
    lat.isFinite &&
    lng.isFinite &&
    lat.abs() <= 90 &&
    lng.abs() <= 180 &&
    !(lat == 0 && lng == 0);

/// Discoverable (lat, lng) from raw profile data, or null when unknown.
(double, double)? discoverableCoords(Map<String, dynamic> data) {
  final expiryRaw = data['travelerExpiry'];
  final expiry = expiryRaw is Timestamp
      ? expiryRaw.toDate()
      : expiryRaw is DateTime
          ? expiryRaw
          : null;
  final travelerActive = data['isTraveler'] == true &&
      expiry != null &&
      expiry.isAfter(DateTime.now());
  final travel = data['travelerLocation'];
  if (travelerActive && travel is Map) {
    final lat = (travel['latitude'] as num?)?.toDouble();
    final lng = (travel['longitude'] as num?)?.toDouble();
    if (_validCoords(lat, lng)) return (lat!, lng!);
  }
  final home = data['location'];
  if (home is Map) {
    final lat = (home['latitude'] as num?)?.toDouble();
    final lng = (home['longitude'] as num?)?.toDouble();
    if (_validCoords(lat, lng)) return (lat!, lng!);
  }
  return null;
}

/// Geohash for a coordinate, or null when the coordinate is unusable.
String? geohashFor(double? lat, double? lng) => _validCoords(lat, lng)
    ? GeoQuery.encode(lat!, lng!, kProfileGeohashPrecision)
    : null;

/// Geohash of the discoverable location in [data], or null.
String? profileGeohash(Map<String, dynamic> data) {
  final c = discoverableCoords(data);
  return c == null ? null : geohashFor(c.$1, c.$2);
}
