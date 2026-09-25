import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/core/services/effective_tier.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';

import '../../support/profile_fixtures.dart';

/// Expiry-aware tier resolution: when a paid tier lapses every feature must
/// fall back to what the user had before, even while `profiles/{uid}` still
/// says PLATINUM (the server downgrade job runs on a schedule).
void main() {
  final now = DateTime(2026, 9, 24, 12);
  final future = now.add(const Duration(days: 3));
  final past = now.subtract(const Duration(minutes: 1));

  group('effectiveTier', () {
    test('an ACTIVE paid tier is kept', () {
      for (final raw in ['SILVER', 'GOLD', 'PLATINUM']) {
        expect(
          effectiveTier(rawTier: raw, endDate: future, now: now),
          MembershipTier.fromString(raw),
          reason: raw,
        );
      }
    });

    test('an EXPIRED paid tier resolves to free', () {
      for (final raw in ['SILVER', 'GOLD', 'PLATINUM']) {
        expect(effectiveTier(rawTier: raw, endDate: past, now: now),
            MembershipTier.free,
            reason: raw);
      }
    });

    test('the end instant itself is already expired (not after now)', () {
      expect(effectiveTier(rawTier: 'PLATINUM', endDate: now, now: now),
          MembershipTier.free);
    });

    test('a paid tier with NO end date is not active', () {
      expect(effectiveTier(rawTier: 'PLATINUM', now: now), MembershipTier.free);
      expect(effectiveTier(rawTier: 'GOLD', now: now), MembershipTier.free);
    });

    test('admins keep their stored tier (admin seed has no end date)', () {
      expect(effectiveTier(rawTier: 'GOLD', isAdmin: true, now: now),
          MembershipTier.gold);
      expect(
          effectiveTier(
              rawTier: 'PLATINUM', endDate: past, isAdmin: true, now: now),
          MembershipTier.platinum);
    });

    test('TEST stays TEST with or without an end date', () {
      expect(effectiveTier(rawTier: 'TEST', now: now), MembershipTier.test);
      expect(effectiveTier(rawTier: 'test', endDate: past, now: now),
          MembershipTier.test);
    });

    test("'BASIC' / 'BASE' / 'FREE' / unknown / null are free", () {
      for (final raw in ['BASIC', 'basic', 'BASE', 'FREE', 'free', 'VIP', '', null]) {
        expect(effectiveTier(rawTier: raw, endDate: future, now: now),
            MembershipTier.free,
            reason: '$raw');
      }
    });
  });

  group('effectiveTierFromDoc', () {
    test('reads Timestamp end dates from a raw profiles doc', () {
      expect(
        effectiveTierFromDoc({
          'membershipTier': 'PLATINUM',
          'membershipEndDate': Timestamp.fromDate(future),
        }, now: now),
        MembershipTier.platinum,
      );
      expect(
        effectiveTierFromDoc({
          'membershipTier': 'PLATINUM',
          'membershipEndDate': Timestamp.fromDate(past),
        }, now: now),
        MembershipTier.free,
      );
    });

    test('honours isAdmin on the doc', () {
      expect(
        effectiveTierFromDoc(
            {'membershipTier': 'GOLD', 'membershipEndDate': null, 'isAdmin': true},
            now: now),
        MembershipTier.gold,
      );
    });

    test('null / empty doc is free', () {
      expect(effectiveTierFromDoc(null, now: now), MembershipTier.free);
      expect(effectiveTierFromDoc(const {}, now: now), MembershipTier.free);
    });
  });

  group('isBaseMembershipActive', () {
    test('active paid tier counts as a membership', () {
      expect(isBaseMembershipActive(effective: MembershipTier.gold), isTrue);
    });

    test('active Base membership counts', () {
      expect(
        isBaseMembershipActive(
          effective: MembershipTier.free,
          hasBaseMembership: true,
          baseMembershipEndDate: future,
          now: now,
        ),
        isTrue,
      );
    });

    test('expired Base + expired paid tier is NOT a membership', () {
      final data = {
        'membershipTier': 'BASIC',
        'membershipEndDate': Timestamp.fromDate(past),
        'hasBaseMembership': true,
        'baseMembershipEndDate': Timestamp.fromDate(past),
      };
      expect(isBaseMembershipActiveFromDoc(data, now: now), isFalse);
    });

    test('expired PLATINUM still stored + active Base = Base only', () {
      final data = {
        'membershipTier': 'PLATINUM',
        'membershipEndDate': Timestamp.fromDate(past),
        'hasBaseMembership': true,
        'baseMembershipEndDate': Timestamp.fromDate(future),
      };
      expect(effectiveTierFromDoc(data, now: now), MembershipTier.free);
      expect(isBaseMembershipActiveFromDoc(data, now: now), isTrue);
    });
  });

  group('nextEntitlementChange', () {
    test('is the paid end date when it comes first', () {
      expect(
        nextEntitlementChange(
          stored: MembershipTier.platinum,
          endDate: future,
          hasBaseMembership: true,
          baseMembershipEndDate: future.add(const Duration(days: 30)),
          now: now,
        ),
        future,
      );
    });

    test('ignores lapsed dates, admins and TEST', () {
      expect(
        nextEntitlementChange(
            stored: MembershipTier.gold, endDate: past, now: now),
        isNull,
      );
      expect(
        nextEntitlementChange(
            stored: MembershipTier.gold,
            endDate: future,
            isAdmin: true,
            now: now),
        isNull,
      );
      expect(
        nextEntitlementChange(
            stored: MembershipTier.test, endDate: future, now: now),
        isNull,
      );
    });
  });

  group('Profile.effectiveTier', () {
    test('expired PLATINUM profile gates as free', () {
      final p = buildProfile(
        membershipTier: MembershipTier.platinum,
        membershipEndDate: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(p.membershipTier, MembershipTier.platinum); // raw stored value
      expect(p.effectiveTier, MembershipTier.free);
    });

    test('active GOLD profile keeps gold', () {
      final p = buildProfile(
        membershipTier: MembershipTier.gold,
        membershipEndDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(p.effectiveTier, MembershipTier.gold);
      expect(p.isBaseMembershipActive, isTrue);
    });

    test('admin profile with no end date keeps its tier', () {
      final p = buildProfile(membershipTier: MembershipTier.gold)
          .copyWith(isAdmin: true);
      expect(p.effectiveTier, MembershipTier.gold);
    });
  });
}
