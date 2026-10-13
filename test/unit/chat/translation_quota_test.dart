import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/tier_entitlements.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';
import 'package:http/testing.dart';

/// Daily translation allowance by membership (owner rule 2026-10-13).
FirebaseFunctionsException quota([String field = 'translateChars']) =>
    FirebaseFunctionsException(
      code: 'resource-exhausted',
      message: 'Daily limit reached. Please try again tomorrow.',
      details: {
        'code': 'QUOTA_EXCEEDED',
        'details': {'reason': 'QUOTA_EXCEEDED', 'field': field},
      },
    );

void main() {
  tearDown(() => TranslationService.dailyLimitReached.value = false);

  test('allowance per plan mirrors the server', () {
    expect(TierEntitlements.translateCharsNoPlan, 3000);
    expect(TierEntitlements.translateCharsPerDay(MembershipTier.free), 10000);
    expect(TierEntitlements.translateCharsPerDay(MembershipTier.silver), 25000);
    expect(TierEntitlements.translateCharsPerDay(MembershipTier.gold), 50000);
    expect(TierEntitlements.translateCharsPerDay(MembershipTier.platinum), 100000);
  });

  test('only the translation quota counts as the daily limit', () {
    expect(TranslationService.isTranslateQuotaError(quota()), isTrue);
    expect(TranslationService.isTranslateQuotaError(quota('assist')), isFalse);
    expect(
        TranslationService.isTranslateQuotaError(FirebaseFunctionsException(
            code: 'resource-exhausted', message: 'rate', details: null)),
        isFalse);
    expect(TranslationService.isTranslateQuotaError(Exception('x')), isFalse);
  });

  test('after the limit: original text, notice raised, no more server calls today', () async {
    var calls = 0;
    final svc = TranslationService.test(
      client: MockClient((_) async => fail('no HTTP')),
      consentGranted: () => true,
      useServer: () async => true,
      serverCall: (_) async {
        calls++;
        throw quota();
      },
      phrasebookJson: '{}',
    );
    final first = await svc.translateDetailed(
        text: 'Where are we meeting tonight?', targetLanguage: 'it');
    expect(first.text, 'Where are we meeting tonight?');
    expect(TranslationService.dailyLimitReached.value, isTrue);
    final made = calls;
    expect(made, greaterThan(0));
    await svc.translateDetailed(
        text: 'See you at the station at eight', targetLanguage: 'it');
    expect(calls, made);
  });
}
