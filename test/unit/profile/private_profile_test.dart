import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';
import 'package:greengo_chat/features/profile/data/profile_geohash.dart';

/// A legacy public profile (as old app versions write it) with the server's
/// coarse fields on top.
Map<String, dynamic> legacyPublic() => {
      'userId': 'other',
      'displayName': 'Ana',
      'dateOfBirth': Timestamp.fromDate(DateTime(1990, 6, 15)),
      'gender': 'female',
      'location': {
        'latitude': 38.722301,
        'longitude': -9.139301,
        'city': 'Lisbon',
        'country': 'Portugal',
      },
      'geohash': geohashFor(38.722301, -9.139301),
      kGeohash5Field: 'eycs0',
      kApproxLocationField: {'lat': 38.7301, 'lng': -9.1502},
      kPublicAgeField: 36,
      'createdAt': Timestamp.fromDate(DateTime(2024)),
      'updatedAt': Timestamp.fromDate(DateTime(2024)),
    };

void main() {
  setUp(() => PrivateProfileCache.instance.reset());

  group('other users: public approximate view', () {
    test('exact legacy coordinates are replaced by approxLocation', () {
      final p = ProfileModel.fromJson(legacyPublic());
      expect(p.location.latitude, 38.7301);
      expect(p.location.longitude, -9.1502);
      expect(p.location.city, 'Lisbon');
    });

    test('age comes from the public `age`, not a birth date', () {
      final json = legacyPublic()..remove('dateOfBirth');
      final p = ProfileModel.fromJson(json);
      expect(p.age, 36);
    });

    test('profiles the server has not processed keep their legacy data', () {
      final json = legacyPublic()
        ..remove(kApproxLocationField)
        ..remove(kPublicAgeField);
      final p = ProfileModel.fromJson(json);
      expect(p.location.latitude, 38.722301);
    });

    test('active travel location is approximated too', () {
      final json = legacyPublic()
        ..['isTraveler'] = true
        ..['travelerExpiry'] =
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)))
        ..['travelerLocation'] = {
          'latitude': 48.8566,
          'longitude': 2.3522,
          'city': 'Paris',
          'country': 'France',
        };
      final v = publicProfileView(json);
      expect((v['travelerLocation'] as Map)['latitude'], 38.7301);
      expect((v['travelerLocation'] as Map)['city'], 'Paris');
    });
  });

  group('own profile: private overlay', () {
    test('exact values from profiles_private win over the public doc', () {
      PrivateProfileCache.instance.seed('me', {
        'location': {'latitude': 41.1579, 'longitude': -8.6291},
        'dateOfBirth': Timestamp.fromDate(DateTime(1995, 2, 3)),
        'sexualOrientation': 'straight',
        'privatePhotoUrls': ['https://x/p1.jpg'],
        kVerificationPhotoPathField: 'verifications/me/1.jpg',
      });
      final json = legacyPublic()
        ..['userId'] = 'me'
        ..remove('dateOfBirth');
      final p = ProfileModel.fromJson(json);
      expect(p.location.latitude, 41.1579);
      expect(p.location.city, 'Lisbon'); // coarse place stays public
      expect(p.dateOfBirth, DateTime(1995, 2, 3));
      expect(p.publicAge, isNull, reason: 'own age from the exact birth date');
      expect(p.age, ageFromDateOfBirth(DateTime(1995, 2, 3)));
      expect(p.sexualOrientation, 'straight');
      expect(p.privatePhotoUrls, ['https://x/p1.jpg']);
      expect(p.verificationPhotoPath, 'verifications/me/1.jpg');
    });

    test('before the private doc loads, legacy own coordinates are kept', () {
      PrivateProfileCache.instance.seed('me', null);
      final json = legacyPublic()..['userId'] = 'me';
      final p = ProfileModel.fromJson(json);
      expect(p.location.latitude, 38.722301);
    });
  });

  group('publicSafeProfileJson', () {
    test('drops every sensitive value, keeps the coarse place', () {
      final json = {
        ...legacyPublic(),
        'sexualOrientation': 'gay',
        'email': 'a@b.c',
        'verificationPhone': '+351900000000',
        'verificationPhotoUrl': 'https://token',
        'privatePhotoUrls': ['x'],
        kVerificationPhotoPathField: 'verifications/u/1.jpg',
        'travelerLocation': {'latitude': 1.5, 'longitude': 2.5, 'city': 'X'},
      };
      final out = publicSafeProfileJson(json);
      for (final k in [
        'dateOfBirth',
        'sexualOrientation',
        'email',
        'verificationPhone',
        'verificationPhotoUrl',
        'privatePhotoUrls',
        'geohash',
        kVerificationPhotoPathField,
        kGeohash5Field,
        kApproxLocationField,
        kPublicAgeField,
      ]) {
        expect(out.containsKey(k), isFalse, reason: k);
      }
      expect(out['location'], {'city': 'Lisbon', 'country': 'Portugal'});
      expect(out['travelerLocation'], {'city': 'X'});
      expect(out['displayName'], 'Ana');
    });

    test('forUpdate flattens location so legacy coordinates are not deleted',
        () {
      final out = publicSafeProfileJson(legacyPublic(), forUpdate: true);
      expect(out.containsKey('location'), isFalse);
      expect(out['location.city'], 'Lisbon');
      expect(out.containsKey('location.latitude'), isFalse);
    });
  });

  group('privateProfileWrite', () {
    final exactJson = {
      'location': {'latitude': 41.1579, 'longitude': -8.6291, 'city': 'Porto'},
      'dateOfBirth': Timestamp.fromDate(DateTime(1995, 2, 3)),
      'sexualOrientation': 'straight',
      'privatePhotoUrls': ['p1'],
      kVerificationPhotoPathField: 'verifications/me/1.jpg',
      'travelerLocation': null,
    };

    test('a new profile writes all exact values + the 9-char geohash', () {
      final w = privateProfileWrite(exactJson);
      expect(w['location'], {'latitude': 41.1579, 'longitude': -8.6291});
      expect(w[kProfileGeohashField], geohashFor(41.1579, -8.6291));
      expect(w['dateOfBirth'], Timestamp.fromDate(DateTime(1995, 2, 3)));
      expect(w['sexualOrientation'], 'straight');
      expect(w['privatePhotoUrls'], ['p1']);
      expect(w[kVerificationPhotoPathField], 'verifications/me/1.jpg');
      expect(w.containsKey('verificationPhotoUrl'), isFalse);
      expect(w['updatedAt'], isA<FieldValue>());
    });

    test('unchanged values write nothing', () {
      final current = {
        'location': {'latitude': 41.1579, 'longitude': -8.6291},
        kProfileGeohashField: geohashFor(41.1579, -8.6291),
        'dateOfBirth': Timestamp.fromDate(DateTime(1995, 2, 3)),
        'sexualOrientation': 'straight',
        'privatePhotoUrls': ['p1'],
        kVerificationPhotoPathField: 'verifications/me/1.jpg',
      };
      expect(privateProfileWrite(exactJson, current: current), isEmpty);
    });

    test('approximate coordinates are never stored as the exact location',
        () {
      final json = {
        'location': {'latitude': 38.7301, 'longitude': -9.1502},
      };
      final w = privateProfileWrite(json,
          current: {
            'location': {'latitude': 38.7223, 'longitude': -9.1393},
          },
          publicData: legacyPublic());
      expect(w.containsKey('location'), isFalse);
    });

    test('fallback values never overwrite real private data', () {
      final json = {
        'dateOfBirth': Timestamp.fromDate(kUnknownDateOfBirth),
        'sexualOrientation': null,
        'privatePhotoUrls': <String>[],
        'location': {'latitude': 0, 'longitude': 0},
      };
      final w = privateProfileWrite(json, current: {
        'dateOfBirth': Timestamp.fromDate(DateTime(1995, 2, 3)),
        'sexualOrientation': 'straight',
        'privatePhotoUrls': ['p1'],
      });
      expect(w, isEmpty);
    });

    test('traveller mode off deletes the private travel point', () {
      final w = privateProfileWrite({...exactJson}, current: {
        'location': {'latitude': 41.1579, 'longitude': -8.6291},
        'travelerLocation': {'latitude': 48.85, 'longitude': 2.35},
        kProfileGeohashField: geohashFor(48.85, 2.35),
        'dateOfBirth': Timestamp.fromDate(DateTime(1995, 2, 3)),
      });
      expect(w['travelerLocation'], isA<FieldValue>());
      expect(w[kProfileGeohashField], geohashFor(41.1579, -8.6291));
    });
  });

  test('ageFromDateOfBirth counts whole years', () {
    final now = DateTime(2026, 10, 8);
    expect(ageFromDateOfBirth(DateTime(2000, 10, 8), now: now), 26);
    expect(ageFromDateOfBirth(DateTime(2000, 10, 9), now: now), 25);
    expect(ageFromDateOfBirth(DateTime(2008, 2, 29), now: now), 18);
  });

  test('geohash5 query ranges are whole precision-5 cells at most', () {
    for (final r in [0.5, 2.0, 10.0, 50.0, 300.0]) {
      final bounds = GeoQuery.queryBounds(38.7223, -9.1393, r * 1000,
          maxPrecision: kGeohash5Precision);
      expect(bounds, isNotEmpty);
      for (final b in bounds) {
        expect(b[0].length, lessThanOrEqualTo(kGeohash5Precision));
        expect(b[0].compareTo(b[1]), lessThan(0));
      }
      // The viewer's own cell is always covered.
      final own = geohash5For(38.7223, -9.1393)!;
      expect(
          bounds.any((b) => own.compareTo(b[0]) >= 0 && own.compareTo(b[1]) < 0),
          isTrue,
          reason: '$r km');
    }
  });

  test('geohash5For is the 5-char prefix of the 9-char geohash', () {
    expect(geohash5For(38.7223, -9.1393), geohashFor(38.7223, -9.1393)!
        .substring(0, kGeohash5Precision));
    expect(geohash5For(0, 0), isNull);
  });
}
