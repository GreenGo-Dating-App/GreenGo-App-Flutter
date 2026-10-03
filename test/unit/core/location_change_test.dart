import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greengo_chat/core/services/location_change.dart';
import 'package:greengo_chat/core/services/location_refresh_service.dart';
import 'package:greengo_chat/features/profile/data/profile_geohash.dart';

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  const lisbon = LocationPoint(
      lat: 38.7223, lng: -9.1393, city: 'Lisbon', country: 'Portugal');

  group('isMeaningfulLocationChange (shared rule)', () {
    test('no previous position -> changed', () {
      expect(
          isMeaningfulLocationChange(
              null, const LocationPoint(lat: 38.72, lng: -9.14)),
          isTrue);
      expect(
          isMeaningfulLocationChange(const LocationPoint(lat: 0, lng: 0),
              const LocationPoint(lat: 38.72, lng: -9.14)),
          isTrue,
          reason: '(0, 0) is the "unset" placeholder');
    });

    test('jitter below 1 km in the same city -> unchanged', () {
      // ~0.5 km east, same city in another case.
      expect(
          isMeaningfulLocationChange(lisbon,
              const LocationPoint(lat: 38.7223, lng: -9.1336, city: 'lisbon')),
          isFalse);
    });

    test('more than 1 km -> changed', () {
      // ~2 km north.
      expect(
          isMeaningfulLocationChange(
              lisbon, const LocationPoint(lat: 38.7400, lng: -9.1393)),
          isTrue);
      expect(
          isMeaningfulLocationChange(lisbon,
              const LocationPoint(lat: 41.1579, lng: -8.6291, city: 'Porto')),
          isTrue);
    });

    test('different city / country -> changed even when close', () {
      expect(
          isMeaningfulLocationChange(lisbon,
              const LocationPoint(lat: 38.7223, lng: -9.1393, city: 'Amadora')),
          isTrue);
      expect(
          isMeaningfulLocationChange(lisbon,
              const LocationPoint(lat: 38.7223, lng: -9.1393, country: 'Spain')),
          isTrue);
    });

    test('unknown names never count as a change', () {
      expect(
          isMeaningfulLocationChange(
              lisbon, const LocationPoint(lat: 38.7223, lng: -9.1393, city: '')),
          isFalse);
      expect(isMeaningfulLocationChange(lisbon, const LocationPoint()), isFalse);
    });

    test('distanceKm is sane (Lisbon -> Porto ~274 km)', () {
      expect(distanceKm(38.7223, -9.1393, 41.1579, -8.6291), closeTo(274, 5));
    });
  });

  group('reloadIfLocationChanged (pull-to-refresh)', () {
    test('reloads when the location changed', () async {
      var reloads = 0;
      final ran = await reloadIfLocationChanged(
        refreshLocation: () async => LocationRefreshOutcome.changed,
        reload: () async => reloads++,
      );
      expect(ran, isTrue);
      expect(reloads, 1);
    });

    for (final outcome in [
      LocationRefreshOutcome.unchanged,
      LocationRefreshOutcome.skipped,
    ]) {
      test('keeps current data when $outcome', () async {
        var reloads = 0;
        final ran = await reloadIfLocationChanged(
          refreshLocation: () async => outcome,
          reload: () async => reloads++,
        );
        expect(ran, isFalse);
        expect(reloads, 0);
      });
    }

    test('a slow refresh is bounded and does not reload', () async {
      var reloads = 0;
      final never = Completer<LocationRefreshOutcome>();
      final sw = Stopwatch()..start();
      final ran = await reloadIfLocationChanged(
        refreshLocation: () => never.future,
        reload: () async => reloads++,
        timeout: const Duration(milliseconds: 50),
      );
      expect(ran, isFalse);
      expect(reloads, 0);
      expect(sw.elapsedMilliseconds, lessThan(1000));
    });

    test('a throwing refresh does not reload', () async {
      var reloads = 0;
      final ran = await reloadIfLocationChanged(
        refreshLocation: () => Future.error(StateError('gps')),
        reload: () async => reloads++,
      );
      expect(ran, isFalse);
      expect(reloads, 0);
    });
  });

  group('LocationRefreshService', () {
    late FakeFirebaseFirestore fs;
    const uid = 'u1';

    Future<Map<String, dynamic>?> reader(String id) async =>
        (await fs.collection('profiles').doc(id).get()).data();

    LocationRefreshService service(Position? position,
            {List<String>? geocoded}) =>
        LocationRefreshService(
          firestore: fs,
          profileReader: reader,
          positionProvider: (_) async => position,
          reverseGeocoder: (lat, lng) async {
            geocoded?.add('$lat,$lng');
            return (city: 'Porto', country: 'Portugal');
          },
        );

    Future<Map<String, dynamic>> profile() async =>
        (await fs.collection('profiles').doc(uid).get()).data()!;

    setUp(() async {
      LocationRefreshService.resetSession();
      fs = FakeFirebaseFirestore();
      await fs.collection('profiles').doc(uid).set({
        'location': {
          'latitude': 38.7223,
          'longitude': -9.1393,
          'city': 'Lisbon',
          'country': 'Portugal',
        },
        'geohash': geohashFor(38.7223, -9.1393),
      });
    });

    test('unchanged position: no geocode, no write', () async {
      final geocoded = <String>[];
      final outcome = await service(_pos(38.7224, -9.1394), geocoded: geocoded)
          .refreshIfAllowed(uid);
      expect(outcome, LocationRefreshOutcome.unchanged);
      expect(geocoded, isEmpty);
      expect((await profile())['location']['latitude'], 38.7223);
    });

    test('moved: writes location + geohash in step', () async {
      final outcome =
          await service(_pos(41.1579, -8.6291)).refreshIfAllowed(uid);
      expect(outcome, LocationRefreshOutcome.changed);
      final data = await profile();
      final loc = data['location'] as Map;
      expect(loc['latitude'], 41.1579);
      expect(loc['city'], 'Porto');
      expect(loc['countryLower'], 'portugal');
      expect(data[kProfileGeohashField], geohashFor(41.1579, -8.6291));
    });

    test('traveler mode active: skipped, nothing written', () async {
      await fs.collection('profiles').doc(uid).update({
        'isTraveler': true,
        'travelerExpiry':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      });
      final outcome =
          await service(_pos(41.1579, -8.6291)).refreshIfAllowed(uid);
      expect(outcome, LocationRefreshOutcome.skipped);
      expect((await profile())['location']['city'], 'Lisbon');
    });

    test('no fix: skipped', () async {
      expect(await service(null).refreshIfAllowed(uid),
          LocationRefreshOutcome.skipped);
    });

    test('concurrent calls share one refresh; maxAge reuses the result',
        () async {
      var reads = 0;
      final s = LocationRefreshService(
        firestore: fs,
        profileReader: reader,
        positionProvider: (_) async {
          reads++;
          return _pos(38.7224, -9.1394);
        },
      );
      await Future.wait([s.refreshIfAllowed(uid), s.refreshIfAllowed(uid)]);
      expect(reads, 1);
      await s.refreshIfAllowed(uid, maxAge: const Duration(minutes: 2));
      expect(reads, 1);
      await s.refreshIfAllowed(uid); // no maxAge: a fresh read
      expect(reads, 2);
    });

    test('awaitSessionRefresh returns at once without a session', () async {
      final sw = Stopwatch()..start();
      await LocationRefreshService.awaitSessionRefresh(uid,
          budget: const Duration(seconds: 5));
      expect(sw.elapsedMilliseconds, lessThan(500));
    });
  });
}
