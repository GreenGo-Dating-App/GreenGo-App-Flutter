import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/effective_tier.dart';
import 'package:greengo_chat/core/services/tier_entitlements.dart';
import 'package:greengo_chat/core/utils/base_membership_gate.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/profile_fixtures.dart';

/// Owner rule (2026-10-11): joining events / booking experiences needs the
/// Base membership, or an active Silver / Gold / Platinum, or TEST - the same
/// predicate as 1:1 chat. Server mirror: functions/src/shared/participation.ts
/// + rules canParticipate() (participation-base.emulator.test.ts).
void main() {
  final now = DateTime(2026, 10, 11, 12);
  final future = now.add(const Duration(days: 30));
  final past = now.subtract(const Duration(days: 1));

  group('canParticipateFromDoc (raw profiles/{uid})', () {
    // Owner rule 2026-10-25: the free version may join events and book
    // experiences, so every existing profile participates (the verified
    // phone is checked separately by PhoneVerificationGate).
    final cases = <String, (Map<String, dynamic>?, bool)>{
      'missing profile': (null, false),
      'free, no Base': ({'membershipTier': 'FREE'}, true),
      'legacy BASIC tier string, no Base flag': ({'membershipTier': 'BASIC'}, true),
      'active Base': (
        {'hasBaseMembership': true, 'baseMembershipEndDate': Timestamp.fromDate(future)},
        true
      ),
      'expired Base': (
        {'hasBaseMembership': true, 'baseMembershipEndDate': Timestamp.fromDate(past)},
        true
      ),
      'expired Gold without Base': (
        {'membershipTier': 'GOLD', 'membershipEndDate': Timestamp.fromDate(past)},
        true
      ),
      'TEST': ({'membershipTier': 'TEST'}, true),
    };
    cases.forEach((name, c) {
      test(name, () => expect(canParticipateFromDoc(c.$1, now: now), c.$2));
    });
    test('chat is still Base-or-better (participation no longer is)', () {
      expect(isBaseMembershipActiveFromDoc({'membershipTier': 'FREE'}, now: now), isFalse);
      expect(canParticipateFromDoc({'membershipTier': 'FREE'}, now: now), isTrue);
    });
  });

  group('BaseMembershipGate.canParticipate (Profile)', () {
    final realPast = DateTime.now().subtract(const Duration(days: 1));
    test('every known account may participate; an unknown one may not', () {
      expect(BaseMembershipGate.canParticipate(null), isFalse);
      expect(BaseMembershipGate.canParticipate(buildProfile()), isTrue);
      expect(
          BaseMembershipGate.canParticipate(buildProfile(
              hasBaseMembership: true, baseMembershipEndDate: realPast)),
          isTrue);
      expect(
          BaseMembershipGate.canParticipate(
              buildProfile(membershipTier: MembershipTier.gold, membershipEndDate: realPast)),
          isTrue);
    });
  });

  group('server refusal mapping', () {
    test('callable details.code base_membership_required', () {
      final e = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: kBaseMembershipRequiredCode,
        details: {'code': kBaseMembershipRequiredCode},
      );
      expect(BaseMembershipGate.errorCodeOf(e), kBaseMembershipRequiredCode);
    });
    test('wrapped in a Failure / exception message', () {
      expect(
          BaseMembershipGate.errorCodeOf(
              const ServerFailure('Failed: base_membership_required')),
          kBaseMembershipRequiredCode);
      expect(
          BaseMembershipGate.errorCodeOf(
              Exception('TicketPaymentException(base_membership_required)')),
          kBaseMembershipRequiredCode);
    });
    test('Firestore rules refusal -> permission-denied', () {
      expect(
          BaseMembershipGate.errorCodeOf(FirebaseException(
              plugin: 'cloud_firestore', code: 'permission-denied')),
          'permission-denied');
      expect(
          BaseMembershipGate.errorCodeOf(Exception(
              'ServerException: Failed to join event: [cloud_firestore/permission-denied] ...')),
          'permission-denied');
    });
    test('unrelated errors are not mapped', () {
      expect(BaseMembershipGate.errorCodeOf(null), isNull);
      expect(BaseMembershipGate.errorCodeOf(Exception('sold_out')), isNull);
    });
  });

  test('comparison table: every plan (Base -> Platinum) joins events and books experiences', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final rows = TierEntitlements.comparisonRows(l10n, travelCoinsPerDay: 100);
    final row = rows.firstWhere((r) => r.label == l10n.membershipBenefitJoinEvents);
    expect(row.values, List.filled(4, TierEntitlements.yesMark));
  });
}
