import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/membership/domain/entities/membership.dart';

/// Master Test Plan — Membership tier enum + rules gating.
/// Guards the UPPERCASE wire value vs lowercase enum name, the tolerant
/// `fromString` mapping (incl. the legacy BASIC alias), priority ordering, and
/// per-tier default rules (the feature-gating table).
void main() {
  group('MembershipTier wire value vs enum name', () {
    test('value() is UPPERCASE for every tier', () {
      expect(MembershipTier.free.value, 'FREE');
      expect(MembershipTier.silver.value, 'SILVER');
      expect(MembershipTier.gold.value, 'GOLD');
      expect(MembershipTier.platinum.value, 'PLATINUM');
      expect(MembershipTier.test.value, 'TEST');
    });

    test('enum name is lowercase (the "user tier" casing)', () {
      expect(MembershipTier.gold.name, 'gold');
      expect(MembershipTier.platinum.name, 'platinum');
    });
  });

  group('MembershipTier.fromString', () {
    test('round-trips the canonical UPPERCASE values', () {
      for (final t in MembershipTier.values) {
        expect(MembershipTier.fromString(t.value), t);
      }
    });

    test('is case-insensitive', () {
      expect(MembershipTier.fromString('gold'), MembershipTier.gold);
      expect(MembershipTier.fromString('Platinum'), MembershipTier.platinum);
    });

    test('legacy BASIC alias maps to silver', () {
      expect(MembershipTier.fromString('BASIC'), MembershipTier.silver);
    });

    test('unknown / empty falls back to free', () {
      expect(MembershipTier.fromString('WHATEVER'), MembershipTier.free);
      expect(MembershipTier.fromString(''), MembershipTier.free);
    });
  });

  group('MembershipTier ordering & flags', () {
    test('priority is strictly increasing free < silver < gold < platinum', () {
      expect(MembershipTier.free.priority, 0);
      expect(MembershipTier.silver.priority, 1);
      expect(MembershipTier.gold.priority, 2);
      expect(MembershipTier.platinum.priority, 3);
      expect(MembershipTier.test.priority, 99);
    });

    test('only the TEST tier bypasses the countdown', () {
      expect(MembershipTier.test.bypassesCountdown, isTrue);
      for (final t in [
        MembershipTier.free,
        MembershipTier.silver,
        MembershipTier.gold,
        MembershipTier.platinum,
      ]) {
        expect(t.bypassesCountdown, isFalse, reason: '$t must not bypass');
      }
    });

    test('every tier has a non-empty displayName', () {
      for (final t in MembershipTier.values) {
        expect(t.displayName, isNotEmpty);
      }
    });
  });

  group('MembershipRules gating defaults', () {
    test('FREE cannot use advanced filters; PLATINUM can', () {
      expect(MembershipRules.getDefaultsForTier(MembershipTier.free)
          .canUseAdvancedFilters, isFalse);
      expect(MembershipRules.getDefaultsForTier(MembershipTier.platinum)
          .canUseAdvancedFilters, isTrue);
    });

    test('incognito mode unlocks at GOLD (not SILVER)', () {
      expect(MembershipRules.getDefaultsForTier(MembershipTier.silver)
          .canUseIncognitoMode, isFalse);
      expect(MembershipRules.getDefaultsForTier(MembershipTier.gold)
          .canUseIncognitoMode, isTrue);
    });

    test('video chat is a PLATINUM-only perk among the paid tiers', () {
      expect(MembershipRules.getDefaultsForTier(MembershipTier.gold)
          .canUseVideoChat, isFalse);
      expect(MembershipRules.getDefaultsForTier(MembershipTier.platinum)
          .canUseVideoChat, isTrue);
    });

    test('daily direct-match allowance grows with tier', () {
      int limit(MembershipTier t) =>
          MembershipRules.getDefaultsForTier(t).dailyDirectMatchLimit;
      expect(limit(MembershipTier.free), 2);
      expect(limit(MembershipTier.silver), 5);
      expect(limit(MembershipTier.gold), 10);
      expect(limit(MembershipTier.platinum), -1); // unlimited
    });

    test('isUnlimited recognizes the -1 sentinel', () {
      const rules = MembershipRules.platinumDefaults;
      expect(rules.isUnlimited(-1), isTrue);
      expect(rules.isUnlimited(10), isFalse);
    });
  });

  group('Membership validity', () {
    Membership make({
      required bool isActive,
      DateTime? endDate,
      MembershipTier tier = MembershipTier.gold,
    }) =>
        Membership(
          membershipId: 'm1',
          userId: 'u1',
          tier: tier,
          startDate: DateTime(2026, 1, 1),
          endDate: endDate,
          isActive: isActive,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

    test('a null endDate is never expired (lifetime/free)', () {
      final m = make(isActive: true);
      expect(m.isExpired, isFalse);
      expect(m.isValid, isTrue);
      expect(m.remainingDays, isNull);
    });

    test('a past endDate is expired and therefore invalid', () {
      final m = make(
          isActive: true,
          endDate: DateTime.now().subtract(const Duration(days: 1)));
      expect(m.isExpired, isTrue);
      expect(m.isValid, isFalse);
      expect(m.remainingDays, 0);
    });

    test('inactive membership is invalid even if not expired', () {
      final m = make(
          isActive: false,
          endDate: DateTime.now().add(const Duration(days: 30)));
      expect(m.isExpired, isFalse);
      expect(m.isValid, isFalse);
    });

    test('isExpiringShow is true within the 7-day window', () {
      final m = make(
          isActive: true,
          endDate: DateTime.now().add(const Duration(days: 3)));
      expect(m.isExpiringShow, isTrue);
    });

    test('rules falls back to tier defaults when no custom rules set', () {
      final m = make(isActive: true, tier: MembershipTier.gold);
      expect(m.rules, MembershipRules.goldDefaults);
    });
  });
}
