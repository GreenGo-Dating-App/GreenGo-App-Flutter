import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/domain/country_resolver.dart';

/// Real published-city coordinates, so the tests exercise the same geometry the
/// app does.
const _usCities = <(double, double)>[
  (34.0522, -118.2437), // Los Angeles
  (40.7128, -74.0060), // New York
  (41.8781, -87.6298), // Chicago
  (37.7749, -122.4194), // San Francisco
  (36.1699, -115.1398), // Las Vegas
  (42.3601, -71.0589), // Boston
];
const _itCities = <(double, double)>[
  (41.9028, 12.4964), // Rome
  (45.4642, 9.1900), // Milan
  (45.4408, 12.3155), // Venice
];
const _brCities = <(double, double)>[
  (-22.9068, -43.1729), // Rio
  (-23.5505, -46.6333), // Sao Paulo
];

final _candidates = <CountryCandidate>[
  // bbox derived from our own attraction coordinates — deliberately too tight
  // for the real USA (northernmost published city is Boston, ~42.4N).
  const CountryCandidate(
      iso2: 'US',
      name: 'United States',
      bbox: [24.23, -123.98, 43.87, -69.55],
      cities: _usCities),
  const CountryCandidate(
      iso2: 'IT', name: 'Italy', bbox: [35.0, 6.0, 47.5, 18.8], cities: _itCities),
  const CountryCandidate(
      iso2: 'BR',
      name: 'Brazil',
      bbox: [-34.0, -74.0, 5.5, -34.0],
      cities: _brCities),
];

String? _resolve({String? country, double? lat, double? lng}) =>
    CountryResolver.resolve(
        candidates: _candidates, countryName: country, lat: lat, lng: lng);

void main() {
  group('tier 1 — country name from the profile', () {
    test('matches the registry name exactly', () {
      expect(_resolve(country: 'United States'), 'US');
      expect(_resolve(country: 'Italy'), 'IT');
    });

    test('accepts common aliases and casing', () {
      for (final v in ['USA', 'usa', 'U.S.A.', 'United States of America', 'America']) {
        expect(_resolve(country: v), 'US', reason: v);
      }
      expect(_resolve(country: 'Brasil'), 'BR');
      expect(_resolve(country: 'Italia'), 'IT');
    });

    test('accepts an ISO2 code in the country field', () {
      expect(_resolve(country: 'US'), 'US');
      expect(_resolve(country: 'br'), 'BR');
    });

    test('wins over geography — Traveler mode to LA while sitting in Milan', () {
      // Position is Milan, but the traveler location says United States.
      expect(_resolve(country: 'United States', lat: 45.4642, lng: 9.19), 'US');
    });
  });

  group('tier 2/3 — geography when no usable country name', () {
    test('Los Angeles resolves to the USA', () {
      expect(_resolve(lat: 34.0522, lng: -118.2437), 'US');
    });

    test('Denver resolves to the USA (inside bbox, no published city near)', () {
      expect(_resolve(lat: 39.7392, lng: -104.9903), 'US');
    });

    test('Seattle resolves to the USA even though it is OUTSIDE our bbox', () {
      // 47.6N is north of the 43.87N box top — this is exactly the case the
      // old 250km nearest-city rule got wrong.
      expect(_resolve(lat: 47.6062, lng: -122.3321), 'US');
    });

    test('Rome resolves to Italy', () {
      expect(_resolve(lat: 41.9028, lng: 12.4964), 'IT');
    });

    test('a point far from every country still resolves to the nearest', () {
      // Mid-Atlantic: no bbox contains it, nearest published city is US.
      expect(_resolve(lat: 30.0, lng: -45.0), 'US');
    });

    test('an unknown country name falls through to geography', () {
      expect(_resolve(country: 'Atlantis', lat: 41.9028, lng: 12.4964), 'IT');
    });
  });

  group('degenerate input', () {
    test('no candidates yields null', () {
      expect(
          CountryResolver.resolve(
              candidates: const [], countryName: 'Italy', lat: 1, lng: 1),
          isNull);
    });

    test('no name and no position yields null', () {
      expect(_resolve(), isNull);
    });

    test('name only, no position, no match yields null', () {
      expect(_resolve(country: 'Narnia'), isNull);
    });
  });
}
