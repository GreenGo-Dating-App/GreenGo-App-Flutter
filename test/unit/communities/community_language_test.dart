import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/community_language.dart';

/// Profiles store languages as English display names ("Portuguese (Brazil)")
/// or codes/locales; communities store 2-letter codes. The normaliser maps
/// every profile value to the community format.
void main() {
  group('normalizeCommunityLanguage', () {
    test('display names (onboarding chips) map to codes', () {
      expect(normalizeCommunityLanguage('English'), 'en');
      expect(normalizeCommunityLanguage('Portuguese'), 'pt');
      expect(normalizeCommunityLanguage('Portuguese (Brazil)'), 'pt');
      expect(normalizeCommunityLanguage('Chinese'), 'zh');
      expect(normalizeCommunityLanguage('Mandarin'), 'zh');
      expect(normalizeCommunityLanguage('Catalan'), 'ca');
      expect(normalizeCommunityLanguage('Norwegian'), 'no');
      expect(normalizeCommunityLanguage('Greek'), 'el');
    });

    test('codes pass through, case-insensitively', () {
      expect(normalizeCommunityLanguage('pt'), 'pt');
      expect(normalizeCommunityLanguage('EN'), 'en');
      expect(normalizeCommunityLanguage('ca'), 'ca');
      expect(normalizeCommunityLanguage('uk'), 'uk');
    });

    test('mixed case + whitespace', () {
      expect(normalizeCommunityLanguage('  sPaNiSh '), 'es');
      expect(normalizeCommunityLanguage('FRENCH'), 'fr');
      expect(normalizeCommunityLanguage('Español'), 'es');
      expect(normalizeCommunityLanguage('Deutsch'), 'de');
    });

    test('locales reduce to the 2-letter base', () {
      expect(normalizeCommunityLanguage('pt_BR'), 'pt');
      expect(normalizeCommunityLanguage('pt-PT'), 'pt');
      expect(normalizeCommunityLanguage('en_US'), 'en');
      expect(normalizeCommunityLanguage('zh-Hant'), 'zh');
      expect(normalizeCommunityLanguage('cs_CZ'), 'cs');
      expect(normalizeCommunityLanguage('nb_NO'), 'no');
      expect(normalizeCommunityLanguage('iw'), 'he');
    });

    test('unknown / empty values are dropped', () {
      expect(normalizeCommunityLanguage(null), isNull);
      expect(normalizeCommunityLanguage(''), isNull);
      expect(normalizeCommunityLanguage('   '), isNull);
      expect(normalizeCommunityLanguage('Klingon'), isNull);
    });
  });

  group('normalizeCommunityLanguages', () {
    test('dedupes names and codes of the same language, keeps order', () {
      expect(
        normalizeCommunityLanguages(
            ['Portuguese (Brazil)', 'pt', 'pt_BR', 'English', 'en', null, 'x']),
        ['pt', 'en'],
      );
    });

    test('caps at 10 for arrayContainsAny', () {
      final many = [
        'English', 'Spanish', 'French', 'German', 'Italian', 'Portuguese',
        'Russian', 'Chinese', 'Japanese', 'Korean', 'Arabic', 'Hindi',
      ];
      final out = normalizeCommunityLanguages(many);
      expect(out.length, kMaxCommunityLanguageFilters);
      expect(out.first, 'en');
      expect(out, isNot(contains('ar')));
    });
  });
}
