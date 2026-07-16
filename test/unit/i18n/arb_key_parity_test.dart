import 'package:flutter_test/flutter_test.dart';

import '../../support/arb_loader.dart';

/// Master Test Plan — i18n key parity.
/// Every translatable key in the base (en) ARB must exist in every other locale,
/// so no screen falls back to a missing string. A small, DOCUMENTED allowlist
/// covers strings that are staged in en but not yet translated — the test still
/// fails if any NEW untranslated key appears, so the gap can only shrink.
void main() {
  /// Keys present in en but intentionally not yet translated in the other
  /// locales (recently-added storefront/event strings). Reported by the QA
  /// batch; remove entries here as translations land.
  const knownUntranslated = <String>{
    'eventScanUseMobileApp',
    'storefrontFeaturedImage',
    'storefrontFeaturedImageSubtitle',
    'storefrontAddFeaturedImage',
    'storefrontProfileImage',
    'storefrontProfileImageSubtitle',
    'storefrontAddProfileImage',
    'storefrontReplaceProfileImage',
  };

  final en = loadArb(kBaseLocale);
  final enKeys = translationKeys(en);

  test('base en ARB declares @@locale == en and is non-empty', () {
    expect(en['@@locale'], 'en');
    expect(enKeys, isNotEmpty);
  });

  for (final locale in kOtherLocales) {
    group('locale $locale', () {
      final arb = loadArb(locale);
      final keys = translationKeys(arb);

      test('declares the correct @@locale', () {
        expect(arb['@@locale'], locale);
      });

      test('has no keys that are absent from en (no orphans)', () {
        final orphans = keys.difference(enKeys);
        expect(orphans, isEmpty,
            reason: 'keys in $locale but not en: $orphans');
      });

      test('contains every en key except the known-untranslated allowlist', () {
        final missing = enKeys.difference(keys);
        final unexpected = missing.difference(knownUntranslated);
        expect(unexpected, isEmpty,
            reason: 'NEW untranslated keys in $locale: $unexpected');
      });
    });
  }
}
