import 'dart:math' as math;

/// Geohash helpers for querying `external_events` nearest-first from Firestore
/// (server-ordered). Ported from geofire-common; the geohash encoding matches
/// the Cloud Function's geohashEncode (standard base32, longitude on even bits).
class GeoQuery {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const int _bitsPerChar = 5;
  static const int _maxBits = 22 * _bitsPerChar;
  static const double _earthMeridional = 40007860; // m
  static const double _metersPerDegreeLat = 110574;
  static const double _earthEqRadius = 6378137;
  static const double _e2 = 0.00669447819799;
  static const double _epsilon = 1e-12;

  static double _log2(double x) => math.log(x) / math.ln2;

  static double _degToRad(double d) => d * math.pi / 180;

  /// Great-circle distance in **meters** between two coordinates.
  static double distanceMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static String encode(double lat, double lng, [int precision = 9]) {
    var idx = 0;
    var bit = 0;
    var evenBit = true;
    var geohash = '';
    var latMin = -90.0, latMax = 90.0, lngMin = -180.0, lngMax = 180.0;
    while (geohash.length < precision) {
      if (evenBit) {
        final mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          idx = idx * 2 + 1;
          lngMin = mid;
        } else {
          idx = idx * 2;
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          idx = idx * 2 + 1;
          latMin = mid;
        } else {
          idx = idx * 2;
          latMax = mid;
        }
      }
      evenBit = !evenBit;
      if (++bit == 5) {
        geohash += _base32[idx];
        bit = 0;
        idx = 0;
      }
    }
    return geohash;
  }

  static double _metersToLngDegrees(double distance, double latitude) {
    final radians = _degToRad(latitude);
    final num = math.cos(radians) * _earthEqRadius * math.pi / 180;
    final denom =
        1 / math.sqrt(1 - _e2 * math.sin(radians) * math.sin(radians));
    final deltaDeg = num * denom;
    if (deltaDeg < _epsilon) return distance > 0 ? 360 : 0;
    return math.min(360, distance / deltaDeg);
  }

  static double _lngBitsForResolution(double resolution, double latitude) {
    final degs = _metersToLngDegrees(resolution, latitude);
    return (degs.abs() > 0.000001) ? math.max(1, _log2(360 / degs)) : 1;
  }

  static double _latBitsForResolution(double resolution) =>
      math.min(_log2(_earthMeridional / 2 / resolution), _maxBits.toDouble());

  static double _wrapLng(double lng) {
    if (lng <= 180 && lng >= -180) return lng;
    final adjusted = lng + 180;
    if (adjusted > 0) return (adjusted % 360) - 180;
    return 180 - (-adjusted % 360);
  }

  static int _boundingBoxBits(double lat, double lng, double size) {
    final latDelta = size / _metersPerDegreeLat;
    final latN = math.min(90.0, lat + latDelta);
    final latS = math.max(-90.0, lat - latDelta);
    final bitsLat = _latBitsForResolution(size).floor() * 2;
    final bitsLngN = _lngBitsForResolution(size, latN).floor() * 2 - 1;
    final bitsLngS = _lngBitsForResolution(size, latS).floor() * 2 - 1;
    return [bitsLat, bitsLngN, bitsLngS, _maxBits]
        .reduce((a, b) => math.min(a, b));
  }

  static List<List<double>> _boundingBoxCoordinates(
      double lat, double lng, double radius) {
    final latDeg = radius / _metersPerDegreeLat;
    final latN = math.min(90.0, lat + latDeg);
    final latS = math.max(-90.0, lat - latDeg);
    final lngDeg = math.max(
        _metersToLngDegrees(radius, latN), _metersToLngDegrees(radius, latS));
    return [
      [lat, lng],
      [lat, _wrapLng(lng - lngDeg)],
      [lat, _wrapLng(lng + lngDeg)],
      [latS, lng],
      [latS, _wrapLng(lng - lngDeg)],
      [latS, _wrapLng(lng + lngDeg)],
      [latN, lng],
      [latN, _wrapLng(lng - lngDeg)],
      [latN, _wrapLng(lng + lngDeg)],
    ];
  }

  static List<String> _geohashQuery(String geohash, int bits) {
    final precision = (bits / _bitsPerChar).ceil();
    if (geohash.length < precision) return [geohash, '$geohash~'];
    final g = geohash.substring(0, precision);
    final base = g.substring(0, g.length - 1);
    final lastValue = _base32.indexOf(g[g.length - 1]);
    final significantBits = bits - base.length * _bitsPerChar;
    final unusedBits = _bitsPerChar - significantBits;
    final startValue = (lastValue >> unusedBits) << unusedBits;
    final endValue = startValue + (1 << unusedBits);
    if (endValue > 31) return ['$base${_base32[startValue]}', '$base~'];
    return ['$base${_base32[startValue]}', '$base${_base32[endValue]}'];
  }

  /// Up to 9 [start, end] geohash ranges covering a circle of [radiusMeters]
  /// around the center. Query Firestore with
  /// `orderBy('geohash').startAt([start]).endAt([end])` for each.
  static List<List<String>> queryBounds(
      double lat, double lng, double radiusMeters) {
    final queryBits = math.max(1, _boundingBoxBits(lat, lng, radiusMeters));
    final precision = (queryBits / _bitsPerChar).ceil();
    final coords = _boundingBoxCoordinates(lat, lng, radiusMeters);
    final queries = coords
        .map((c) => _geohashQuery(encode(c[0], c[1], precision), queryBits))
        .toList();
    // De-duplicate identical ranges.
    final out = <List<String>>[];
    for (final q in queries) {
      if (!out.any((o) => o[0] == q[0] && o[1] == q[1])) out.add(q);
    }
    return out;
  }
}
