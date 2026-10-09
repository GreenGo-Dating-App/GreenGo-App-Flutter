import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/arb_loader.dart';

/// Guard: GreenGo is a cross-cultural discovery, language-exchange, local
/// events and friendship app - NOT a dating app (Apple guideline 4.3(b) and
/// misleading-advertising risk). User-facing English copy must not drift back
/// to dating / romance wording.
///
/// Checked sources:
///  * every value in the base English ARB (`lib/l10n/app_en.arb`) - the other
///    locales are translations of it and are kept in step by review;
///  * the English column of the server e-mail subject table
///    (`functions/src/shared/i18n/emailSubjects.ts`).
///
/// Calendar "date" (date of birth, date range, "Choose a date") is fine; only
/// the romantic sense is banned. The single phrase allowlist is the explicit
/// "not a dating app" disclaimer in the community guidelines.
void main() {
  /// Romance / dating vocabulary. Case-insensitive.
  final banned = <String, RegExp>{
    'dating': RegExp(r'\bdating\b', caseSensitive: false),
    'romantic date': RegExp(
      r'\b(first|blind|video|virtual|coffee|dinner|speed)[ -]dat(e|es|er|ers|ing)\b'
      r"|\bdate[ -](night|ideas?|planning)\b"
      r"|\b(go|going|went|on) (on )?a date\b"
      r"|\byour date(?!s? of birth)(?!\s*(range|and time|& time))\b"
      r"|\bmy dates\b",
      caseSensitive: false,
    ),
    'flirt': RegExp(r'\bflirt\w*', caseSensitive: false),
    'romantic': RegExp(r'\bromantic\w*', caseSensitive: false),
    'romance': RegExp(r'\bromance\b', caseSensitive: false),
    'love': RegExp(r'\blov(e|es|ed|ing|er|ers)\b', caseSensitive: false),
    'perfect match': RegExp(r'\bperfect match', caseSensitive: false),
    "it's a match": RegExp(r"\bit['’]s a match\b", caseSensitive: false),
    'valentine': RegExp(r'\bvalentine', caseSensitive: false),
    'swipe right to like': RegExp(r'\bswipe right to like\b', caseSensitive: false),
    'hookup': RegExp(r'\bhook[ -]?ups?\b', caseSensitive: false),
    'sexy': RegExp(r'\bsexy\b', caseSensitive: false),
    'soulmate': RegExp(r'\bsoul ?mates?\b', caseSensitive: false),
    'super like': RegExp(r'\bsuper[ -]?lik(e|es|ed|er)\b', caseSensitive: false),
  };

  /// Phrases removed before matching (explicitly NOT dating wording).
  final allowedPhrases = <RegExp>[
    // "GreenGo ... is not a dating app." disclaimers (community guidelines).
    RegExp(r'(is )?not a dating app', caseSensitive: false),
  ];

  List<String> violations(String text) {
    var t = text;
    for (final a in allowedPhrases) {
      t = t.replaceAll(a, ' ');
    }
    return [
      for (final e in banned.entries)
        if (e.value.hasMatch(t)) e.key,
    ];
  }

  group('guard self-check (the check CAN fail)', () {
    const mustFlag = <String>[
      'Discover Your Perfect Match',
      'Find love this holiday season!',
      'Cross-Cultural Dating Do\'s',
      'Share your date\'s profile',
      'Become a master of the dating game',
      'Flirty',
      'Romance scams',
      "It's a Match!",
      'Valentine’s Week',
      'swipe right to like, left to pass',
      'Send a super like',
      'Virtual Date Night',
      'Speed Dater',
    ];
    const mustPass = <String>[
      'Date of Birth',
      'Your date of birth cannot be changed',
      'Choose a date',
      'Passwords do not match',
      'No attractions match your filters',
      'GreenGo is for genuine cultural connection — it is not a dating app.',
      'Priority Connect',
      'Language exchange partner',
      'Date & Time',
    ];
    for (final s in mustFlag) {
      test('flags "$s"', () => expect(violations(s), isNotEmpty));
    }
    for (final s in mustPass) {
      test('allows "$s"', () => expect(violations(s), isEmpty));
    }
  });

  test('en ARB values contain no dating / romance wording', () {
    final en = loadArb(kBaseLocale);
    final entries = translationEntries(en).toList();
    expect(entries.length, greaterThan(1000),
        reason: 'ARB not loaded - the guard would pass vacuously');
    final hits = <String>[
      for (final e in entries)
        if (violations(e.value).isNotEmpty)
          '${e.key} ${violations(e.value)}: ${e.value}',
    ];
    expect(hits, isEmpty,
        reason: 'Dating wording in app_en.arb (rewrite as connection / people / '
            'exchange partner / meetup):\n${hits.join('\n')}');
  });

  test('server e-mail subjects (en) contain no dating / romance wording', () {
    final file = File('functions/src/shared/i18n/emailSubjects.ts');
    expect(file.existsSync(), isTrue, reason: 'missing ${file.path}');
    final src = file.readAsStringSync();
    // Each row: 'email.<key>': { en: '<subject>', de: ... }
    final row = RegExp(r"'(email\.[\w.]+)':\s*\{\s*en:\s*'((?:[^'\\]|\\.)*)'");
    final rows = row.allMatches(src).toList();
    expect(rows.length, greaterThan(50),
        reason: 'subject table not parsed - the guard would pass vacuously');
    final hits = <String>[
      for (final m in rows)
        if (violations(m.group(2)!).isNotEmpty)
          '${m.group(1)} ${violations(m.group(2)!)}: ${m.group(2)}',
    ];
    expect(hits, isEmpty,
        reason: 'Dating wording in emailSubjects.ts:\n${hits.join('\n')}');
  });
}
