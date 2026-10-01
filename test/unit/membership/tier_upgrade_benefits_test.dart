import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/core/services/tier_entitlements.dart';
import 'package:greengo_chat/core/services/tier_upgrade_benefits.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';

/// "Upgrade Benefits" on My Usage: only the REAL, differing entitlements
/// between the user's effective tier and the next tier up.
void main() {
  const count = BenefitValue.count;
  const flag = BenefitValue.flag;

  group('nextTierUp', () {
    test('walks Free → Silver → Gold → Platinum, nothing above', () {
      expect(nextTierUp(MembershipTier.free), MembershipTier.silver);
      expect(nextTierUp(MembershipTier.silver), MembershipTier.gold);
      expect(nextTierUp(MembershipTier.gold), MembershipTier.platinum);
      expect(nextTierUp(MembershipTier.platinum), isNull);
      expect(nextTierUp(MembershipTier.test), isNull);
    });
  });

  group('nextTierBenefits (Explore-first build, no swipe deck)', () {
    test('Free → Silver', () {
      expect(nextTierBenefits(MembershipTier.free), [
        UpgradeBenefit(UpgradeBenefitKind.dailyConnects, count(10), count(50)),
        UpgradeBenefit(UpgradeBenefitKind.events, count(1), count(3)),
        UpgradeBenefit(UpgradeBenefitKind.groups, count(1), count(null)),
        UpgradeBenefit(UpgradeBenefitKind.experiences, count(1), count(5)),
        UpgradeBenefit(UpgradeBenefitKind.boostsPerMonth, count(0), count(1)),
        UpgradeBenefit(UpgradeBenefitKind.monthlyCoins, count(100), count(500)),
        UpgradeBenefit(
            UpgradeBenefitKind.discoveryReveal, count(100), count(200)),
        UpgradeBenefit(UpgradeBenefitKind.travelMode, flag(false), flag(true)),
      ]);
    });

    test('Silver → Gold', () {
      expect(nextTierBenefits(MembershipTier.silver), [
        UpgradeBenefit(UpgradeBenefitKind.dailyConnects, count(50), count(200)),
        UpgradeBenefit(UpgradeBenefitKind.events, count(3), count(5)),
        UpgradeBenefit(UpgradeBenefitKind.experiences, count(5), count(10)),
        UpgradeBenefit(UpgradeBenefitKind.boostsPerMonth, count(1), count(4)),
        UpgradeBenefit(
            UpgradeBenefitKind.monthlyCoins, count(500), count(1500)),
        UpgradeBenefit(
            UpgradeBenefitKind.discoveryReveal, count(200), count(300)),
        UpgradeBenefit(
            UpgradeBenefitKind.seeWhoConnected, flag(false), flag(true)),
      ]);
    });

    test('Gold → Platinum', () {
      expect(nextTierBenefits(MembershipTier.gold), [
        UpgradeBenefit(
            UpgradeBenefitKind.dailyConnects, count(200), count(null)),
        UpgradeBenefit(UpgradeBenefitKind.events, count(5), count(null)),
        UpgradeBenefit(
            UpgradeBenefitKind.experiences, count(10), count(null)),
        UpgradeBenefit(UpgradeBenefitKind.boostsPerMonth, count(4), count(30)),
        UpgradeBenefit(
            UpgradeBenefitKind.monthlyCoins, count(1500), count(5000)),
        UpgradeBenefit(
            UpgradeBenefitKind.discoveryReveal, count(300), count(500)),
        UpgradeBenefit(UpgradeBenefitKind.analytics, flag(false), flag(true)),
        UpgradeBenefit(
            UpgradeBenefitKind.businessAccount, flag(false), flag(true)),
      ]);
    });

    test('top tiers have nothing to upgrade to', () {
      expect(nextTierBenefits(MembershipTier.platinum), isEmpty);
      expect(nextTierBenefits(MembershipTier.test), isEmpty);
    });

    test('never lists a row whose value does not change', () {
      for (final t in MembershipTier.values) {
        for (final b in nextTierBenefits(t, includeSwipeLimits: true)) {
          expect(b.from, isNot(b.to), reason: '$t ${b.kind}');
        }
      }
    });

    test('no swipe-deck rows unless asked for', () {
      const swipe = {
        UpgradeBenefitKind.hourlyConnects,
        UpgradeBenefitKind.hourlyPasses,
        UpgradeBenefitKind.hourlyPriorityConnects,
        UpgradeBenefitKind.dailyPriorityConnects,
      };
      for (final t in MembershipTier.values) {
        expect(
          nextTierBenefits(t).where((b) => swipe.contains(b.kind)),
          isEmpty,
        );
      }
    });
  });

  group('values follow the entitlement source (no duplicated numbers)', () {
    test('experiences = TierEntitlements.maxExperiences', () {
      for (final t in MembershipTier.values) {
        expect(
          benefitValueFor(UpgradeBenefitKind.experiences, t),
          count(TierEntitlements.maxExperiences(t)),
        );
      }
      expect(TierEntitlements.maxExperiences(MembershipTier.free), 1);
      expect(TierEntitlements.maxExperiences(MembershipTier.silver), 5);
      expect(TierEntitlements.maxExperiences(MembershipTier.gold), 10);
      expect(TierEntitlements.maxExperiences(MembershipTier.platinum), isNull);
      expect(TierEntitlements.maxExperiences(MembershipTier.test), isNull);
    });

    test('daily connects = TierEntitlements.maxDailyConnects', () {
      for (final t in MembershipTier.values) {
        expect(
          benefitValueFor(UpgradeBenefitKind.dailyConnects, t),
          count(TierEntitlements.maxDailyConnects(t)),
        );
      }
    });
  });

  group('full build (swipe deck on)', () {
    test('Free → Silver adds the MembershipRules swipe limits', () {
      final rows = nextTierBenefits(
        MembershipTier.free,
        includeSwipeLimits: true,
      );
      expect(
        rows,
        containsAll([
          UpgradeBenefit(
              UpgradeBenefitKind.hourlyConnects, count(5), count(10)),
          UpgradeBenefit(UpgradeBenefitKind.hourlyPasses, count(10), count(25)),
          UpgradeBenefit(
              UpgradeBenefitKind.hourlyPriorityConnects, count(1), count(2)),
          UpgradeBenefit(
              UpgradeBenefitKind.dailyPriorityConnects, count(1), count(3)),
        ]),
      );
    });

    test('-1 in MembershipRules reads as unlimited', () {
      final rows = nextTierBenefits(
        MembershipTier.gold,
        includeSwipeLimits: true,
      );
      expect(
        rows,
        contains(UpgradeBenefit(
            UpgradeBenefitKind.dailyPriorityConnects, count(5), count(null))),
      );
    });
  });
}
