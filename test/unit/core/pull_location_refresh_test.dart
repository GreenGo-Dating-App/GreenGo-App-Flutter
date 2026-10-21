import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:greengo_chat/core/services/location_change.dart';
import 'package:greengo_chat/core/services/location_refresh_service.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';
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
  // ~100 m north / ~330 m north of [lisbon].
  const near = LocationPoint(lat: 38.7232, lng: -9.1393);
  const moved300m = LocationPoint(lat: 38.7253, lng: -9.1393);
  final now = DateTime(2026, 10, 21, 12);

  group('shouldWritePulledLocation (pull-to-refresh write throttle)', () {
    test('moved < 200 m and saved < 10 min ago -> no write', () {
      expect(
          shouldWritePulledLocation(
              stored: lisbon,
              storedAt: now.subtract(const Duration(minutes: 3)),
              fix: near,
              now: now),
          isFalse);
    });

    test('moved >= 200 m -> write, however recent the last save', () {
      expect(
          shouldWritePulledLocation(
              stored: lisbon,
              storedAt: now.subtract(const Duration(seconds: 5)),
              fix: moved300m,
              now: now),
          isTrue);
    });

    test('same spot but the saved position is >= 10 min old -> write', () {
      expect(
          shouldWritePulledLocation(
              stored: lisbon,
              storedAt: now.subtract(kPullRefreshMinInterval),
              fix: near,
              now: now),
          isTrue);
    });

    test('unknown previous position or save time -> write', () {
      expect(
          shouldWritePulledLocation(
              stored: null, storedAt: null, fix: near, now: now),
          isTrue);
      expect(
          shouldWritePulledLocation(
              stored: const LocationPoint(lat: 0, lng: 0),
              storedAt: now,
              fix: near,
              now: now),
          isTrue,
          reason: '(0, 0) is the "unset" placeholder');
      expect(
          shouldWritePulledLocation(
              stored: lisbon, storedAt: null, fix: near, now: now),
          isTrue);
    });

    test('a fix without usable coordinates is never written', () {
      expect(
          shouldWritePulledLocation(
              stored: lisbon,
              storedAt: null,
              fix: const LocationPoint(lat: 0, lng: 0),
              now: now),
          isFalse);
    });
  });

  group('LocationRefreshService.refreshOnPull', () {
    late FakeFirebaseFirestore fs;
    late DateTime now;
    late DateTime clock;
    late List<String> geocoded;
    const uid = 'u1';

    Future<Map<String, dynamic>?> reader(String id) async =>
        (await fs.collection('profiles').doc(id).get()).data();

    LocationRefreshService service(PositionRead read) => LocationRefreshService(
          firestore: fs,
          profileReader: reader,
          positionReader: (_) async => read,
          clock: () => clock,
          reverseGeocoder: (lat, lng) async {
            geocoded.add('$lat,$lng');
            return (city: 'Porto', country: 'Portugal');
          },
        );

    PositionRead at(double lat, double lng) =>
        (position: _pos(lat, lng), reason: null);

    Future<Map<String, dynamic>?> privateDoc() async =>
        (await fs.collection(kPrivateProfilesCollection).doc(uid).get())
            .data();

    setUp(() async {
      LocationRefreshService.resetSession();
      fs = FakeFirebaseFirestore();
      // Real time: the fake stamps serverTimestamp() with DateTime.now().
      now = DateTime.now();
      clock = now;
      geocoded = <String>[];
      await fs.collection('profiles').doc(uid).set({
        'location': {
          'latitude': 38.7223,
          'longitude': -9.1393,
          'city': 'Lisbon',
          'country': 'Portugal',
        },
        'locationUpdatedAt':
            Timestamp.fromDate(now.subtract(const Duration(minutes: 2))),
      });
    });

    test('moved: saved through the existing write (private coords, geohash, '
        'public city) and reported with the new city', () async {
      final r = await service(at(41.1579, -8.6291)).refreshOnPull(uid);
      expect(r.outcome, LocationRefreshOutcome.changed);
      expect(r.written, isTrue);
      expect(r.city, 'Porto');
      final pub = (await fs.collection('profiles').doc(uid).get()).data()!;
      expect((pub['location'] as Map)['city'], 'Porto');
      final priv = (await privateDoc())!;
      expect((priv['location'] as Map)['latitude'], 41.1579);
      expect(priv[kProfileGeohashField], geohashFor(41.1579, -8.6291));
    });

    test('same spot, saved recently: throttled (no write, no geocode)',
        () async {
      final r = await service(at(38.7232, -9.1393)).refreshOnPull(uid);
      expect(r.outcome, LocationRefreshOutcome.unchanged);
      expect(r.written, isFalse);
      expect(r.city, 'Lisbon');
      expect(geocoded, isEmpty);
      expect(await privateDoc(), isNull);
    });

    test('a second pull right after a save is throttled by the in-memory '
        'last write; after 10 min it re-saves without geocoding', () async {
      final first = await service(at(41.1579, -8.6291)).refreshOnPull(uid);
      expect(first.written, isTrue);
      expect(geocoded, hasLength(1));

      clock = now.add(const Duration(minutes: 1));
      final second = await service(at(41.1580, -8.6291)).refreshOnPull(uid);
      expect(second.written, isFalse);

      clock = now.add(const Duration(minutes: 11));
      final third = await service(at(41.1580, -8.6291)).refreshOnPull(uid);
      expect(third.written, isTrue);
      expect(third.outcome, LocationRefreshOutcome.unchanged);
      expect(third.city, 'Porto');
      expect(geocoded, hasLength(1), reason: 'no geocoding for a re-stamp');
      expect(((await privateDoc())!['location'] as Map)['latitude'], 41.1580);
    });

    test('traveler mode: the travel location is kept, GPS not read', () async {
      var reads = 0;
      await fs.collection('profiles').doc(uid).update({
        'isTraveler': true,
        'travelerExpiry':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'travelerLocation': {'city': 'Tokyo', 'country': 'Japan'},
      });
      final s = LocationRefreshService(
        firestore: fs,
        profileReader: reader,
        positionReader: (_) async {
          reads++;
          return at(41.1579, -8.6291);
        },
      );
      final r = await s.refreshOnPull(uid);
      expect(r.skipReason, LocationSkipReason.traveler);
      expect(reads, 0);
      final pub = (await fs.collection('profiles').doc(uid).get()).data()!;
      expect((pub['travelerLocation'] as Map)['city'], 'Tokyo');
      expect((pub['location'] as Map)['city'], 'Lisbon');
      expect(await privateDoc(), isNull);
    });

    test('permission denied / location off: skipped with the reason',
        () async {
      for (final reason in [
        LocationSkipReason.permissionDenied,
        LocationSkipReason.permissionDeniedForever,
        LocationSkipReason.serviceDisabled,
      ]) {
        final r = await service((position: null, reason: reason))
            .refreshOnPull(uid);
        expect(r.outcome, LocationRefreshOutcome.skipped);
        expect(r.skipReason, reason);
      }
      expect(await privateDoc(), isNull);
    });
  });
}
