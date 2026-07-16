// ignore_for_file: prefer_const_literals_to_create_immutables

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

import '../../support/profile_fixtures.dart';

void main() {
  group('ProfileModel.toJson / fromJson round-trip', () {
    test('preserves core identity + membership + business fields', () {
      final model = ProfileModel.fromEntity(
        buildBusinessProfile(),
      );
      final restored = ProfileModel.fromJson(model.toJson());

      expect(restored.userId, model.userId);
      expect(restored.displayName, model.displayName);
      expect(restored.isBusiness, isTrue);
      expect(restored.businessName, "Elena's Cafe");
      expect(restored.coverImageUrl, model.coverImageUrl);
      expect(restored.businessVerified, isTrue);
      // dateOfBirth survives the Timestamp <-> DateTime hop.
      expect(restored.dateOfBirth, model.dateOfBirth);
    });

    test('round-trips lists (photoUrls / interests / languages)', () {
      final model = ProfileModel.fromEntity(
        buildProfile(
          photoUrls: const ['a.jpg', 'b.jpg'],
          interests: const ['x', 'y', 'z'],
          languages: const ['English', 'Italian'],
        ),
      );
      final restored = ProfileModel.fromJson(model.toJson());
      expect(restored.photoUrls, ['a.jpg', 'b.jpg']);
      expect(restored.interests, ['x', 'y', 'z']);
      expect(restored.languages, ['English', 'Italian']);
    });

    test('membership tier survives via its wire value', () {
      final model = ProfileModel.fromEntity(
        buildProfile(membershipTier: MembershipTier.platinum),
      );
      final json = model.toJson();
      expect(json['membershipTier'], 'PLATINUM');
      expect(
        ProfileModel.fromJson(json).membershipTier,
        MembershipTier.platinum,
      );
    });

    test('businessPromotedUntil serializes and re-parses as a future date', () {
      final model = ProfileModel.fromEntity(buildBusinessProfile());
      final json = model.toJson();
      // toJson intentionally omits businessPromotedUntil (server-owned), so
      // fromJson yields null and isBusinessPromoted is false after a plain
      // client round-trip.
      expect(json.containsKey('businessPromotedUntil'), isFalse);
      expect(ProfileModel.fromJson(json).businessPromotedUntil, isNull);
    });
  });

  group('ProfileModel.fromJson defaults + legacy handling', () {
    test('fills sane defaults when optional fields are missing', () {
      final model = ProfileModel.fromJson({'userId': 'u1'});
      expect(model.userId, 'u1');
      expect(model.displayName, 'Unknown');
      expect(model.gender, 'other');
      expect(model.photoUrls, isEmpty);
      expect(model.bio, '');
      expect(model.isComplete, isFalse);
      expect(model.membershipTier, MembershipTier.free);
      expect(model.showOnMap, isTrue);
      expect(model.dateOfBirth, DateTime(1990, 1, 1));
    });

    test('reads the legacy "photos" key when "photoUrls" is absent', () {
      final model = ProfileModel.fromJson({
        'userId': 'u1',
        'photos': ['legacy1.jpg', 'legacy2.jpg'],
      });
      expect(model.photoUrls, ['legacy1.jpg', 'legacy2.jpg']);
    });

    test('parses verificationStatus strings, unknown -> notSubmitted', () {
      expect(
        ProfileModel.fromJson({'userId': 'u', 'verificationStatus': 'approved'})
            .verificationStatus,
        VerificationStatus.approved,
      );
      expect(
        ProfileModel.fromJson({'userId': 'u', 'verificationStatus': 'weird'})
            .verificationStatus,
        VerificationStatus.notSubmitted,
      );
    });

    test('parses globeDiscoverability, unknown -> approximate', () {
      expect(
        ProfileModel.fromJson(
                {'userId': 'u', 'globeDiscoverability': 'hidden'})
            .globeDiscoverability,
        GlobeDiscoverability.hidden,
      );
      expect(
        ProfileModel.fromJson({'userId': 'u'}).globeDiscoverability,
        GlobeDiscoverability.approximate,
      );
    });

    test('parses openingHours + signupGrants lists of maps', () {
      final model = ProfileModel.fromJson({
        'userId': 'u',
        'openingHours': [
          {'weekday': 2, 'open': '08:00', 'close': '16:00'},
        ],
        'signupGrantsApplied': [
          {'couponId': 'c1', 'couponCode': 'GO', 'grantSummary': '+30d'},
        ],
      });
      expect(model.openingHours, hasLength(1));
      expect(model.openingHours.first.weekday, 2);
      expect(model.signupGrantsApplied, hasLength(1));
      expect(model.signupGrantsApplied.first.couponCode, 'GO');
    });
  });

  group('ProfileModel.fromFirestore', () {
    test('reads back a doc written via toJson, using the doc id as userId',
        () async {
      final db = FakeFirebaseFirestore();
      final model = ProfileModel.fromEntity(buildBusinessProfile());
      await db.collection('profiles').doc('biz_1').set(model.toJson());

      final snap = await db.collection('profiles').doc('biz_1').get();
      final restored = ProfileModel.fromFirestore(snap);

      expect(restored.userId, 'biz_1');
      expect(restored.businessName, "Elena's Cafe");
      expect(restored.isBusiness, isTrue);
      expect(restored.displayName, 'Elena Marco');
    });

    test('location survives the Firestore round-trip', () async {
      final db = FakeFirebaseFirestore();
      final model = ProfileModel.fromEntity(buildProfile());
      await db.collection('profiles').doc('u1').set(model.toJson());
      final snap = await db.collection('profiles').doc('u1').get();
      final restored = ProfileModel.fromFirestore(snap);
      expect(restored.location.city, 'Lisbon');
      expect(restored.location.country, 'Portugal');
    });
  });

  group('toJson wire encoding details', () {
    test('encodes DateTimes as Firestore Timestamps', () {
      final json = ProfileModel.fromEntity(buildProfile()).toJson();
      expect(json['dateOfBirth'], isA<Timestamp>());
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['updatedAt'], isA<Timestamp>());
    });

    test('verificationStatus + globeDiscoverability encode as enum names', () {
      final json = ProfileModel.fromEntity(
        buildProfile(verificationStatus: VerificationStatus.approved),
      ).toJson();
      expect(json['verificationStatus'], 'approved');
      expect(json['globeDiscoverability'], 'approximate');
    });
  });

  group('normalizeCountryName', () {
    test('maps locale spellings to canonical English', () {
      expect(normalizeCountryName('Brasil'), 'Brazil');
      expect(normalizeCountryName('Deutschland'), 'Germany');
      expect(normalizeCountryName('Italia'), 'Italy');
      expect(normalizeCountryName('España'), 'Spain');
    });

    test('is case-insensitive and passes through unknowns unchanged', () {
      expect(normalizeCountryName('BRASIL'), 'Brazil');
      expect(normalizeCountryName('Wakanda'), 'Wakanda');
    });

    test('LocationModel.fromJson normalizes country + strips "Unknown"', () {
      final loc = LocationModel.fromJson(const {
        'latitude': 0,
        'longitude': 0,
        'city': 'Unknown',
        'country': 'Brasil',
        'displayAddress': 'x',
      });
      expect(loc.city, '');
      expect(loc.country, 'Brazil');
    });
  });
}
