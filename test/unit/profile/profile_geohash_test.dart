import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/profile/data/profile_geohash.dart';

void main() {
  group('profile geohash (discoverable location)', () {
    const home = {'latitude': 41.9028, 'longitude': 12.4964}; // Rome
    const travel = {'latitude': 48.8566, 'longitude': 2.3522}; // Paris

    test('uses home location when not travelling', () {
      final gh = profileGeohash({'location': home});
      expect(gh, GeoQuery.encode(41.9028, 12.4964, kProfileGeohashPrecision));
      expect(gh!.length, kProfileGeohashPrecision);
    });

    test('uses the travel location while traveller mode is active', () {
      final data = {
        'location': home,
        'isTraveler': true,
        'travelerExpiry': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 5))),
        'travelerLocation': travel,
      };
      expect(profileGeohash(data),
          GeoQuery.encode(48.8566, 2.3522, kProfileGeohashPrecision));
    });

    test('falls back to home when the trip has expired', () {
      final data = {
        'location': home,
        'isTraveler': true,
        'travelerExpiry': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1))),
        'travelerLocation': travel,
      };
      expect(profileGeohash(data),
          GeoQuery.encode(41.9028, 12.4964, kProfileGeohashPrecision));
    });

    test('unknown / placeholder coordinates give no geohash', () {
      expect(profileGeohash({}), isNull);
      expect(
          profileGeohash({
            'location': {'latitude': 0, 'longitude': 0}
          }),
          isNull);
      expect(geohashFor(null, 10), isNull);
      expect(geohashFor(95, 10), isNull);
    });

    test('a nearby profile falls inside the query ranges', () {
      final gh = GeoQuery.encode(41.91, 12.50, kProfileGeohashPrecision);
      final bounds = GeoQuery.queryBounds(41.9028, 12.4964, 50 * 1000);
      final inside = bounds.any(
          (b) => gh.compareTo(b[0]) >= 0 && gh.compareTo(b[1]) <= 0);
      expect(inside, isTrue);
    });
  });
}
