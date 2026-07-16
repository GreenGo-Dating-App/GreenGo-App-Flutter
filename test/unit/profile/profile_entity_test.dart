import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

import '../../support/profile_fixtures.dart';

/// Reference age computation, independent of the getter, used as a regression
/// guard for arbitrary birthdays.
int refAge(DateTime dob) {
  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

void main() {
  group('Profile.age getter', () {
    test('is full years when the birthday already passed this year', () {
      // Born Jan 1 N years ago — that birthday has always occurred by "now".
      final now = DateTime.now();
      final born = DateTime(now.year - 20, 1, 1);
      final profile = buildProfile(dateOfBirth: born);
      expect(profile.age, 20);
    });

    test('counts the birthday on the exact day (>= not >)', () {
      final now = DateTime.now();
      final born = DateTime(now.year - 33, now.month, now.day);
      expect(buildProfile(dateOfBirth: born).age, 33);
    });

    test('matches an independent reference calc for an arbitrary DOB', () {
      final born = DateTime(1990, 3, 27);
      expect(buildProfile(dateOfBirth: born).age, refAge(born));
    });

    test('is never negative for a very recent DOB', () {
      final now = DateTime.now();
      final born = DateTime(now.year, 1, 1);
      expect(buildProfile(dateOfBirth: born).age, greaterThanOrEqualTo(0));
    });
  });

  group('Profile.isBusinessPromoted', () {
    test('true when business + promotedUntil in the future', () {
      final p = buildBusinessProfile(promoted: true);
      expect(p.isBusiness, isTrue);
      expect(p.isBusinessPromoted, isTrue);
    });

    test('false when the promotion window has expired', () {
      final p = buildBusinessProfile(promoted: false);
      expect(p.isBusinessPromoted, isFalse);
    });

    test('false when promotedUntil is null even for a business', () {
      final p = buildProfile(
        isBusiness: true,
        businessName: 'Cafe',
      );
      expect(p.businessPromotedUntil, isNull);
      expect(p.isBusinessPromoted, isFalse);
    });

    test('false for a non-business account even with a future window', () {
      final p = buildProfile(
        businessPromotedUntil: DateTime.now().add(const Duration(days: 5)),
      );
      expect(p.isBusiness, isFalse);
      expect(p.isBusinessPromoted, isFalse);
    });
  });

  group('Profile business / storefront fields', () {
    test('exposes businessName and coverImageUrl on a storefront', () {
      final p = buildBusinessProfile();
      expect(p.businessName, "Elena's Cafe");
      expect(p.coverImageUrl, isNotEmpty);
      expect(p.businessVerified, isTrue);
    });

    test('defaults are business-off with null storefront fields', () {
      final p = buildProfile();
      expect(p.isBusiness, isFalse);
      expect(p.businessName, isNull);
      expect(p.coverImageUrl, isNull);
      expect(p.galleryImages, isEmpty);
      expect(p.openingHours, isEmpty);
    });
  });

  group('Profile derived flags', () {
    test('formattedNickname prefixes @ or is null', () {
      expect(buildProfile(nickname: 'ava_r').formattedNickname, '@ava_r');
      expect(buildProfile().formattedNickname, isNull);
    });

    test('isVerified reflects approved verification only', () {
      expect(
        buildProfile(verificationStatus: VerificationStatus.approved)
            .isVerified,
        isTrue,
      );
      expect(
        buildProfile(verificationStatus: VerificationStatus.pending).isVerified,
        isFalse,
      );
    });

    test('needsVerificationAction covers notSubmitted / rejected', () {
      expect(buildProfile().needsVerificationAction, isTrue);
      expect(
        buildProfile(verificationStatus: VerificationStatus.rejected)
            .needsVerificationAction,
        isTrue,
      );
      expect(
        buildProfile(verificationStatus: VerificationStatus.approved)
            .needsVerificationAction,
        isFalse,
      );
    });

    test('isTravelerActive requires the flag AND a future expiry', () {
      final active = buildProfile(
        isTraveler: true,
        travelerExpiry: DateTime.now().add(const Duration(days: 2)),
      );
      final expired = buildProfile(
        isTraveler: true,
        travelerExpiry: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(active.isTravelerActive, isTrue);
      expect(expired.isTravelerActive, isFalse);
      expect(buildProfile().isTravelerActive, isFalse);
    });

    test('effectiveLocation swaps to traveler location when active', () {
      const travelerLoc = Location(
        latitude: 48.85,
        longitude: 2.35,
        city: 'Paris',
        country: 'France',
        displayAddress: 'Paris, France',
      );
      final active = buildProfile(
        isTraveler: true,
        travelerExpiry: DateTime.now().add(const Duration(days: 2)),
        travelerLocation: travelerLoc,
      );
      expect(active.effectiveLocation.city, 'Paris');
      // Home location when not traveling.
      expect(buildProfile().effectiveLocation.city, 'Lisbon');
    });
  });

  group('Profile.isBaseMembershipActive', () {
    test('true for TEST tier regardless of dates', () {
      expect(
        buildProfile(membershipTier: MembershipTier.test)
            .isBaseMembershipActive,
        isTrue,
      );
    });

    test('true for a paid tier with a future membershipEndDate', () {
      final p = buildProfile(
        membershipTier: MembershipTier.gold,
        membershipEndDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(p.isBaseMembershipActive, isTrue);
    });

    test('true via legacy base membership fields', () {
      final p = buildProfile(
        hasBaseMembership: true,
        baseMembershipEndDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(p.isBaseMembershipActive, isTrue);
    });

    test('false for a free user with no active windows', () {
      expect(buildProfile().isBaseMembershipActive, isFalse);
    });
  });

  group('OpeningHours + SignupGrant value objects', () {
    test('OpeningHours.fromMap round-trips through toMap', () {
      const oh = OpeningHours(weekday: 3, open: '09:00', close: '17:00');
      final restored = OpeningHours.fromMap(oh.toMap());
      expect(restored, oh);
    });

    test('OpeningHours.fromMap defaults weekday to Monday', () {
      final oh = OpeningHours.fromMap(const {});
      expect(oh.weekday, 1);
      expect(oh.isClosed, isFalse);
    });

    test('SignupGrant.fromMap round-trips and copyWith dismisses', () {
      const g = SignupGrant(
        couponId: 'c1',
        couponCode: 'WELCOME',
        grantSummary: '+500 coins',
      );
      expect(SignupGrant.fromMap(g.toMap()), g);
      expect(g.copyWith(dismissed: true).dismissed, isTrue);
      expect(g.dismissed, isFalse);
    });
  });

  test('copyWith updates only the targeted field', () {
    final base = buildProfile(displayName: 'Ava');
    final updated = base.copyWith(displayName: 'Ava Reyes');
    expect(updated.displayName, 'Ava Reyes');
    expect(updated.userId, base.userId);
    expect(base.displayName, 'Ava');
  });
}
