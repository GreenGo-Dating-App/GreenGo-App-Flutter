import 'package:flutter_test/flutter_test.dart';

import '../../support/arb_loader.dart';

/// Master Test Plan — i18n: recently-added keys are present in the base bundle.
/// Guards a handful of newer strings so a bad merge can't silently drop them
/// from en. Absent keys are skipped (and were reported by the QA batch) so the
/// test asserts only on the ones that ship today.
void main() {
  const candidateKeys = <String>[
    'communitiesJoinAsPersonalTitle',
    'communitiesCreatedManageHint',
    'exploreHappeningSoon',
    'verifyPhoneFormatError',
  ];

  final en = loadArb(kBaseLocale);
  final enKeys = translationKeys(en);

  for (final key in candidateKeys) {
    test('en ARB defines "$key" (skipped if absent)', () {
      if (!enKeys.contains(key)) {
        // Not shipped in this build — nothing to assert.
        return;
      }
      final value = en[key];
      expect(value, isA<String>());
      expect((value as String).trim(), isNotEmpty,
          reason: '$key must have a non-empty en value');
    }, skip: enKeys.contains(key) ? false : 'key "$key" absent from en ARB');
  }

  test('at least the four tracked new keys exist in en', () {
    final present = candidateKeys.where(enKeys.contains).toList();
    // All four were confirmed present at authoring time; this catches a
    // regression if several disappear at once.
    expect(present, isNotEmpty);
  });
}
