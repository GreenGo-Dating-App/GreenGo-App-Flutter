import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/globe_explore/data/country_centroids.dart';
import 'package:greengo_chat/features/globe_explore/data/datasources/globe_remote_datasource.dart';
import 'package:greengo_chat/features/globe_explore/data/models/globe_user_model.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';

/// Privacy rules of the network map: who is drawn, and how precisely.
///
/// Every person on the map is part of the user's network (here: someone
/// they follow, half of them also following back). They are left
/// out when inactive, incognito (unexpired), in ghost mode, "Hidden" in Globe
/// Discoverability, blocked, or without a known location; the rest are drawn
/// at the precision they chose, computed from the PUBLIC approximate
/// location, never the exact one.

const _exactLat = 41.95123, _exactLng = 12.40001; // legacy exact coords
const _approxLat = 41.9010, _approxLng = 12.4990; // server approxLocation

Map<String, dynamic> _profile({
  String? discoverability,
  String status = 'active',
  bool? incognito,
  DateTime? incognitoExpiry,
  bool? ghost,
  bool withLocation = true,
}) =>
    {
      'displayName': 'Ana',
      'accountStatus': status,
      if (discoverability != null) 'globeDiscoverability': discoverability,
      if (incognito != null) 'isIncognito': incognito,
      if (incognitoExpiry != null)
        'incognitoExpiry': Timestamp.fromDate(incognitoExpiry),
      if (ghost != null) 'isGhostMode': ghost,
      if (withLocation) ...{
        'location': {
          'latitude': _exactLat,
          'longitude': _exactLng,
          'city': 'Rome',
          'country': 'Italy',
        },
        kApproxLocationField: {'lat': _approxLat, 'lng': _approxLng},
      },
    };

Future<GlobeData> _load(Map<String, Map<String, dynamic>> others,
    {Set<String> blocked = const {}}) async {
  final fs = FakeFirebaseFirestore();
  PrivateProfileCache.instance.reset();
  // Own exact location comes from the private document.
  PrivateProfileCache.instance.seed('me', {
    'location': {'latitude': 38.72, 'longitude': -9.14},
  });
  await fs.collection('profiles').doc('me').set({
    'displayName': 'Me',
    'accountStatus': 'active',
    'globeDiscoverability': 'exact',
    'location': {'city': 'Lisbon', 'country': 'Portugal'},
  });
  for (final id in blocked) {
    await fs
        .collection('profiles')
        .doc('me')
        .collection('blocked_users')
        .doc(id)
        .set({'blockedAt': Timestamp.now()});
  }
  var i = 0;
  for (final e in others.entries) {
    await fs.collection('profiles').doc(e.key).set(e.value);
    // Followed by me; every other one also follows me back.
    final at = Timestamp.fromDate(DateTime(2026, 1, 1 + i));
    await fs
        .collection('user_business_following')
        .doc('me')
        .collection('businesses')
        .doc(e.key)
        .set({'createdAt': at});
    if (i.isEven) {
      await fs
          .collection('business_followers')
          .doc('me')
          .collection('followers')
          .doc(e.key)
          .set({'createdAt': at});
    }
    i++;
  }
  return GlobeRemoteDataSourceImpl(firestore: fs).getGlobeData(userId: 'me');
}

Set<String> _ids(GlobeData d) => d.matchedUsers.map((u) => u.userId).toSet();

void main() {
  tearDown(() => PrivateProfileCache.instance.reset());

  group('who is drawn', () {
    test('a plain active connection is drawn, with its relations', () async {
      final d = await _load({'ok': _profile()});
      expect(_ids(d), {'ok'});
      expect(d.matchedUsers.single.relations,
          {GlobeRelation.following, GlobeRelation.follower});
      expect(d.matchedUsers.single.pinType, GlobePinType.matched);
      expect(d.matchedUsers.single.isBusiness, isFalse);
    });

    test('incognito is left out unless it has expired', () async {
      final now = DateTime.now();
      final d = await _load({
        'incognitoActive': _profile(
            incognito: true, incognitoExpiry: now.add(const Duration(days: 1))),
        'incognitoForever': _profile(incognito: true),
        'incognitoExpired': _profile(
            incognito: true,
            incognitoExpiry: now.subtract(const Duration(days: 1))),
      });
      expect(_ids(d), {'incognitoExpired'});
    });

    test('ghost mode is left out', () async {
      final d = await _load({'ghost': _profile(ghost: true), 'ok': _profile()});
      expect(_ids(d), {'ok'});
    });

    test('"Hidden" globe discoverability is left out, connections included',
        () async {
      final d = await _load({
        'hidden': _profile(discoverability: 'hidden'),
        'ok': _profile(discoverability: 'country'),
      });
      expect(_ids(d), {'ok'});
    });

    test('inactive, blocked and location-less users are left out', () async {
      final d = await _load({
        'suspended': _profile(status: 'suspended'),
        'blocked': _profile(),
        'nowhere': _profile(withLocation: false),
        'ok': _profile(),
      }, blocked: {
        'blocked'
      });
      expect(_ids(d), {'ok'});
    });
  });

  group('precision (from the public approximate location)', () {
    test('exact: within ~500 m of approxLocation, never the exact coords',
        () async {
      final u = (await _load({'x': _profile(discoverability: 'exact')}))
          .matchedUsers
          .single;
      expect(u.discoverability, GlobeDiscoverability.exact);
      expect((u.pinLatitude - _approxLat).abs(), lessThanOrEqualTo(0.005));
      expect((u.pinLongitude - _approxLng).abs(), lessThanOrEqualTo(0.005));
      expect((u.pinLatitude - _exactLat).abs(), greaterThan(0.04));
    });

    test('exact + server preciseLocation (±100 m): pin is exactly it, no client jitter',
        () async {
      const pLat = 41.95180, pLng = 12.40090;
      final u = (await _load({
        'x': {
          ..._profile(discoverability: 'exact'),
          kPreciseLocationField: {'lat': pLat, 'lng': pLng},
        },
      }))
          .matchedUsers
          .single;
      expect(u.pinLatitude, pLat);
      expect(u.pinLongitude, pLng);
    });

    test('a stale preciseLocation is ignored once the user left "exact"',
        () async {
      final u = (await _load({
        'x': {
          ..._profile(discoverability: 'country'),
          kPreciseLocationField: {'lat': 41.9518, 'lng': 12.4009},
        },
      }))
          .matchedUsers
          .single;
      final c = countryCentroids['Italy']!;
      expect((u.pinLatitude - c[0]).abs(), lessThanOrEqualTo(1.5));
      expect((u.pinLongitude - c[1]).abs(), lessThanOrEqualTo(1.5));
    });

    test('approximate (the default): snapped to a ~50 km cell', () async {
      final u = (await _load({'x': _profile()})).matchedUsers.single;
      expect(u.discoverability, GlobeDiscoverability.approximate);
      const cell = 0.45;
      final cellLat = (_approxLat / cell).floor() * cell + cell / 2;
      final cellLng = (_approxLng / cell).floor() * cell + cell / 2;
      expect((u.pinLatitude - cellLat).abs(), lessThanOrEqualTo(0.1 + 1e-9));
      expect((u.pinLongitude - cellLng).abs(), lessThanOrEqualTo(0.1 + 1e-9));
    });

    test('country: around the country centroid only', () async {
      final u = (await _load({'x': _profile(discoverability: 'country')}))
          .matchedUsers
          .single;
      final c = countryCentroids['Italy']!;
      expect((u.pinLatitude - c[0]).abs(), lessThanOrEqualTo(1.5));
      expect((u.pinLongitude - c[1]).abs(), lessThanOrEqualTo(1.5));
    });
  });

  group('GlobeUserModel', () {
    test('an active traveler is placed at the destination (and its country)',
        () {
      final data = <String, dynamic>{
        'displayName': 'T',
        'globeDiscoverability': 'exact',
        'location': {
          'latitude': 41.9,
          'longitude': 12.5,
          'city': 'Rome',
          'country': 'Italy',
        },
        'isTraveler': true,
        'travelerExpiry':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'travelerLocation': {
          'latitude': 38.72,
          'longitude': -9.14,
          'country': 'Portugal',
        },
      };
      final u = GlobeUserModel.fromFirestore(
        data: data,
        odcId: 't',
        pinType: GlobePinType.matched,
        random: Random(1),
      );
      expect(u.isTravelerActive, isTrue);
      expect(u.country, 'Portugal');
      expect((u.pinLatitude - 38.72).abs(), lessThanOrEqualTo(0.005));
      // Flight path starts at the home country's centroid.
      expect(u.realCountryLatitude, countryCentroids['Italy']![0]);
    });

    test('pinCoordsFor: exact uses the precise point as is, else jitter', () {
      final rng = Random(3);
      expect(
          GlobeUserModel.pinCoordsFor(
              GlobeDiscoverability.exact, 1, 2, 'Italy', rng,
              precise: (41.5, 12.5)),
          [41.5, 12.5]);
      final j = GlobeUserModel.pinCoordsFor(
          GlobeDiscoverability.exact, 41.9, 12.5, 'Italy', rng);
      expect((j[0] - 41.9).abs(), lessThanOrEqualTo(0.005));
      // Other levels never use the precise point.
      final a = GlobeUserModel.pinCoordsFor(
          GlobeDiscoverability.approximate, 41.9, 12.5, 'Italy', rng,
          precise: (41.5, 12.5));
      expect(a, isNot([41.5, 12.5]));
    });

    test('own pin with exact uses the own preciseLocation too', () {
      final u = GlobeUserModel.fromFirestore(
        data: const {
          'globeDiscoverability': 'exact',
          'location': {'latitude': 41.9, 'longitude': 12.5, 'country': 'Italy'},
          kPreciseLocationField: {'lat': 41.9007, 'lng': 12.5004},
        },
        odcId: 'me',
        pinType: GlobePinType.currentUser,
        random: Random(1),
      );
      expect([u.pinLatitude, u.pinLongitude], [41.9007, 12.5004]);
    });

    test('an unknown discoverability value is treated as country level', () {
      final u = GlobeUserModel.fromFirestore(
        data: const {
          'globeDiscoverability': 'bogus',
          'location': {'latitude': 41.9, 'longitude': 12.5, 'country': 'Italy'},
        },
        odcId: 'u',
        pinType: GlobePinType.matched,
        random: Random(1),
      );
      expect(u.discoverability, GlobeDiscoverability.country);
    });
  });
}
