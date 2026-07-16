import 'package:flutter_test/flutter_test.dart';

import '../../support/arb_loader.dart';

/// Master Test Plan — i18n encoding integrity (no mojibake).
///
/// NOTE ON "ASCII-only": GreenGo's de/es/fr/it/pt/pt_BR translations legitimately
/// contain accented characters (ü, é, ã, ç, …) and even en uses typographic
/// punctuation (… · ). A literal ASCII-only assertion would reject valid,
/// correctly-encoded translations. The real risk these files face is MOJIBAKE —
/// UTF-8 bytes wrongly decoded as Latin-1 (BOM / encoding mishaps), which is a
/// known gotcha on this toolchain. So this test asserts the meaningful property:
/// no value contains the Unicode replacement character or a classic mojibake
/// digraph.
void main() {
  // Classic UTF-8-as-Latin-1 mojibake digraphs + the replacement character.
  // Each of these is unambiguous corruption; none occurs in well-formed text.
  const mojibakeMarkers = <String>[
    '�', // replacement character
    'Ã©', 'Ã¨', 'Ã¤', 'Ã¶', 'Ã¼', 'Ã±', 'Ã§', 'Ã ', 'Ã¡', 'Ã­', 'Ã³', 'Ãº',
    'Ã¢', 'Ã£', 'Ãµ', 'Ã‰', 'Ã„', 'Ã–', 'Ãœ',
    'â€™', 'â€œ', 'â€', 'â€“', 'â€”', 'Â«', 'Â»', 'Â·', 'Â ',
  ];

  for (final locale in [kBaseLocale, ...kOtherLocales]) {
    test('$locale ARB has no mojibake markers', () {
      final arb = loadArb(locale);
      final offenders = <String>[];
      for (final entry in translationEntries(arb)) {
        for (final marker in mojibakeMarkers) {
          if (entry.value.contains(marker)) {
            offenders.add('${entry.key}: ${marker.codeUnits}');
            break;
          }
        }
      }
      expect(offenders, isEmpty,
          reason: 'mojibake found in $locale: $offenders');
    });
  }
}
