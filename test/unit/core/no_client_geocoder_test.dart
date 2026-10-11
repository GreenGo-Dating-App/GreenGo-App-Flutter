import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/location_share_service.dart';
import 'package:greengo_chat/core/services/place_search_service.dart';

/// Address search runs on the server (`searchAddress` / `resolvePlace` /
/// `reverseGeocode`): no third-party geocoder may be called from the app, and
/// the native Google Maps widget (blank on Android without a Maps SDK key) must
/// not come back.
void main() {
  final banned = <String, RegExp>{
    'Nominatim from the client': RegExp(r'nominatim\.openstreetmap\.org'),
    'Photon from the client': RegExp(r'photon\.komoot\.io'),
    'geocoding plugin forward search': RegExp(r'\blocationFromAddress\('),
    'native Google Maps widget': RegExp(r'google_maps_flutter'),
  };

  test('no client-side geocoder or native Google Map in lib/', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final e in banned.entries) {
          if (e.value.hasMatch(lines[i])) {
            hits.add('${f.path}:${i + 1} ${e.key}');
          }
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });

  test('the scan CAN fail', () {
    expect(banned['Nominatim from the client']!
        .hasMatch("Uri.https('nominatim.openstreetmap.org', '/search')"),
        isTrue);
    expect(banned['native Google Maps widget']!
        .hasMatch("import 'package:google_maps_flutter/google_maps_flutter.dart';"),
        isTrue);
  });

  group('PlaceSuggestion / PickedPlace', () {
    test('parses a server suggestion and normalizes the country', () {
      final s = PlaceSuggestion.fromMap({
        'id': 'osm:W1',
        'primary': 'Piazza Navona',
        'secondary': 'Rome, Italy',
        'lat': 41.9,
        'lng': 12.47,
        'city': 'Rome',
        'country': 'Italia',
      });
      expect(s.hasCoordinates, isTrue);
      expect(s.country, 'Italy');
      expect(s.toPlace()!.address, 'Piazza Navona, Rome, Italy');
    });

    test('a Google suggestion has no coordinates until resolved', () {
      final s = PlaceSuggestion.fromMap(
          {'id': 'g:x', 'primary': 'X', 'secondary': '', 'placeId': 'x'});
      expect(s.toPlace(), isNull);
      expect(s.placeId, 'x');
    });

    test('toLocation falls back to coordinates for an empty address', () {
      const p = PickedPlace(address: '', lat: 1.234567, lng: 2.5);
      expect(p.toLocation().displayAddress, '1.23457, 2.50000');
    });

    test('session tokens are long, url-safe and random', () {
      final a = newPlaceSessionToken();
      expect(a, matches(RegExp(r'^[A-Za-z0-9_-]{32}$')));
      expect(newPlaceSessionToken(), isNot(a));
    });
  });

  group('CallablePlaceSearchRepository', () {
    test('sends query, language, mode, bias and token; parses suggestions',
        () async {
      late String name;
      late Map<String, dynamic> sent;
      final repo = CallablePlaceSearchRepository(call: (n, d) async {
        name = n;
        sent = d;
        return {
          'suggestions': [
            {'id': 'a', 'primary': 'A', 'secondary': 'B', 'lat': 1, 'lng': 2},
            {'id': 'b', 'primary': '', 'secondary': 'dropped'},
          ],
        };
      });
      final list = await repo.search('abc',
          lang: 'pt-BR',
          mode: PlaceSearchMode.city,
          biasLat: 1,
          biasLng: 2,
          sessionToken: 't' * 12);
      expect(name, 'searchAddress');
      expect(sent, {
        'query': 'abc',
        'lang': 'pt-BR',
        'mode': 'city',
        'lat': 1.0,
        'lng': 2.0,
        'sessionToken': 't' * 12,
      });
      expect(list.single.lat, 1.0);
    });

    test('maps transport failures to offline', () async {
      final repo = CallablePlaceSearchRepository(
          call: (_, __) async => throw const SocketException('down'));
      await expectLater(
          repo.search('abc', lang: 'en'),
          throwsA(isA<PlaceSearchException>().having(
              (e) => e.failure, 'failure', PlaceSearchFailure.offline)));
    });

    test('reverse and resolve parse a place or null', () async {
      final repo = CallablePlaceSearchRepository(call: (n, d) async => n ==
              'reverseGeocode'
          ? {
              'place': {'address': 'A', 'lat': 1, 'lng': 2, 'city': 'C'}
            }
          : {'place': null});
      expect((await repo.reverse(1, 2, lang: 'en'))!.city, 'C');
      expect(await repo.resolve('pid'), isNull);
    });
  });

  test('chat location metadata carries an optional, capped address', () {
    expect(LocationShareService.metadataFor(1, 2),
        {'isLocation': true, 'lat': 1.0, 'lng': 2.0});
    final m = LocationShareService.metadataFor(1, 2, address: 'x' * 300);
    expect((m['address'] as String).length, LocationShareService.maxAddressLength);
    expect(LocationShareService.addressOf(m), isNotNull);
    expect(LocationShareService.addressOf({'address': '  '}), isNull);
    expect(LocationShareService.addressOf(null), isNull);
  });
}
