import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/web_location_fallback.dart';

/// Parsing of Nominatim `/search?format=jsonv2` responses used to geocode a
/// hand-typed event location.
void main() {
  group('WebLocationFallback.parseSearchResponse', () {
    test('parses the first result (string lat/lon, address, display name)',
        () {
      final body = jsonEncode([
        {
          'lat': '45.4642',
          'lon': '9.1900',
          'display_name': 'Piazza del Duomo, Milano, Lombardia, Italia',
          'address': {'city': 'Milano', 'country': 'Italia'},
        },
        {'lat': '1', 'lon': '1'},
      ]);
      final loc = WebLocationFallback.parseSearchResponse(body)!;
      expect(loc.latitude, closeTo(45.4642, 1e-9));
      expect(loc.longitude, closeTo(9.19, 1e-9));
      expect(loc.city, 'Milano');
      expect(loc.country, isNotEmpty);
      expect(loc.displayAddress, 'Piazza del Duomo, Milano, Lombardia, Italia');
    });

    test('falls back town -> village for the city', () {
      final body = jsonEncode([
        {
          'lat': '10',
          'lon': '20',
          'address': {'village': 'Smallville'},
        },
      ]);
      final loc = WebLocationFallback.parseSearchResponse(body)!;
      expect(loc.city, 'Smallville');
      expect(loc.country, '');
      expect(loc.displayAddress, 'Smallville');
    });

    test('accepts numeric lat/lon and a missing address', () {
      final loc = WebLocationFallback.parseSearchResponse(
          jsonEncode([
        {'lat': 1.5, 'lon': -2.25}
      ]))!;
      expect(loc.latitude, 1.5);
      expect(loc.longitude, -2.25);
      expect(loc.city, '');
      expect(loc.displayAddress, '1.5000, -2.2500');
    });

    test('returns null for no match / malformed / out-of-range', () {
      expect(WebLocationFallback.parseSearchResponse('[]'), isNull);
      expect(WebLocationFallback.parseSearchResponse('not json'), isNull);
      expect(WebLocationFallback.parseSearchResponse('{"lat":"1"}'), isNull);
      expect(
          WebLocationFallback.parseSearchResponse(
              jsonEncode([
            {'lat': 'x', 'lon': '2'}
          ])),
          isNull);
      expect(
          WebLocationFallback.parseSearchResponse(
              jsonEncode([
            {'lat': '95', 'lon': '2'}
          ])),
          isNull);
    });

    test('forwardGeocode short-circuits an empty query', () async {
      expect(await WebLocationFallback.forwardGeocode('   '), isNull);
    });
  });
}
