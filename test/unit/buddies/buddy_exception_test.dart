import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_exception.dart';

FirebaseFunctionsException _fx(String code, String message, Object? details) =>
    FirebaseFunctionsException(code: code, message: message, details: details);

void main() {
  group('BuddyException.from (server error shapes in functions/src/buddies)', () {
    test('refusal(): details.reason (insufficient-coins, tier-required + limit)', () {
      expect(
        BuddyException.from(_fx('failed-precondition', 'insufficient-coins: You used ...',
                {'reason': 'insufficient-coins', 'required': 1, 'available': 0}))
            .kind,
        BuddyErrorKind.insufficientCoins,
      );
      final tier = BuddyException.from(_fx('failed-precondition', 'tier-required: Your plan ...',
          {'reason': 'tier-required', 'limit': 3, 'tier': 'SILVER'}));
      expect(tier.kind, BuddyErrorKind.tierRequired);
      expect(tier.limit, 3);
    });

    test('AppError: details.code + nested details (rate limit, AI, consent, too long)', () {
      expect(
          BuddyException.from(_fx('resource-exhausted', 'too fast',
              {'code': 'RATE_LIMITED', 'details': {'reason': 'RATE_LIMITED'}})).kind,
          BuddyErrorKind.rateLimited);
      expect(
          BuddyException.from(_fx('unavailable', 'x',
              {'code': 'AI_UNAVAILABLE', 'details': {'reason': 'AI_UNAVAILABLE'}})).kind,
          BuddyErrorKind.unavailable);
      expect(
          BuddyException.from(_fx('permission-denied', 'x',
              {'code': 'AI_CONSENT_UPDATE_REQUIRED', 'details': {'reason': 'AI_CONSENT_UPDATE_REQUIRED'}})).kind,
          BuddyErrorKind.consentUpdateRequired);
      expect(
          BuddyException.from(_fx('permission-denied', 'x', {'code': 'AI_CONSENT_REQUIRED'})).kind,
          BuddyErrorKind.consentRequired);
      final long = BuddyException.from(
          _fx('invalid-argument', 'x', {'code': 'TEXT_TOO_LONG', 'details': {'max': 500}}));
      expect(long.kind, BuddyErrorKind.textTooLong);
      expect(long.max, 500);
    });

    test('reason only in the message prefix, and unknown errors', () {
      expect(BuddyException.from(_fx('failed-precondition', 'tier-required: locked', null)).kind,
          BuddyErrorKind.tierRequired);
      expect(BuddyException.from(_fx('internal', 'boom', null)).kind, BuddyErrorKind.other);
      final other = BuddyException.from(StateError('x'));
      expect(other.kind, BuddyErrorKind.other);
      expect(other.cause, isA<StateError>());
      const same = BuddyException(BuddyErrorKind.duplicate);
      expect(identical(BuddyException.from(same), same), isTrue);
    });
  });
}
