import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';

/// Master Test Plan — F4/B5: distance math behind the "within 50km" event
/// filters (Explore happening-soon, community-events-near-you, featured).
void main() {
  const kmToM = 1000.0;
  double km(double a) => a * kmToM;

  group('GeoQuery.distanceMeters', () {
    test('identical points are ~0m apart', () {
      final d = GeoQuery.distanceMeters(38.7223, -9.1393, 38.7223, -9.1393);
      expect(d, lessThan(1));
    });

    test('one degree of latitude is ~111km', () {
      final d = GeoQuery.distanceMeters(0, 0, 1, 0);
      // Haversine on a sphere: ~111.19 km.
      expect(d, greaterThan(km(110)));
      expect(d, lessThan(km(112)));
    });

    test('~11km separation is within the 50km radius', () {
      final d = GeoQuery.distanceMeters(38.7223, -9.1393, 38.8223, -9.1393);
      expect(d, lessThan(km(50)));
    });

    test('~55km separation is OUTSIDE the 50km radius', () {
      final d = GeoQuery.distanceMeters(0, 0, 0.5, 0);
      expect(d, greaterThan(km(50)));
    });
  });

  group('within-50km predicate', () {
    bool within50km(double lat1, double lng1, double lat2, double lng2) =>
        GeoQuery.distanceMeters(lat1, lng1, lat2, lng2) <= km(50);

    test('near point passes, far point fails', () {
      expect(within50km(38.72, -9.13, 38.75, -9.15), isTrue);
      expect(within50km(38.72, -9.13, 40.0, -9.13), isFalse); // ~140km north
    });
  });
}
