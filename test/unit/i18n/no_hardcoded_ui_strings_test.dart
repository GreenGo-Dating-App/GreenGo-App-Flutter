import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// i18n guard: no hard-coded, user-visible English in `lib/`.
///
/// Every string a user can see must come from the ARB files
/// (`AppLocalizations.of(context)!.key`). This test scans the Dart sources of
/// every file the app can actually load (reachable from a `lib/main*.dart`
/// entrypoint through imports/exports/parts) and fails on string literals with
/// letters in UI positions:
///
/// * the text argument of `Text`, `SelectableText`, `TextSpan`, `Tab`,
///   `Tooltip`, ...;
/// * params that are always user-visible (`labelText`, `hintText`,
///   `helperText`, `errorText`, `tooltip`, `semanticLabel`, ...);
/// * params that are usually user-visible (`title`, `label`, `message`,
///   `description`, `name`, ...) when the literal reads like prose (starts
///   upper-case or contains a space) — this catches entity/seed display text.
///
/// Deliberate exceptions are marked in the source with a comment containing
/// `i18n-ignore: <reason>` on the same line, or on a comment-only line directly
/// above (brand names, language autonyms, CSV formats, Firestore seed content,
/// ...). Brand names listed in [_brands] are accepted without a marker.
///
/// Files that no entrypoint reaches (dead code) are skipped and listed in the
/// test output; once a file is wired into the app it is checked automatically.
void main() {
  test('no hard-coded user-visible strings in reachable lib/ files', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the package root');

    final files = <String, File>{};
    for (final e in libDir.listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final rel = _norm(e.path);
      if (_excludedDirs.any(rel.startsWith)) continue;
      files[rel] = e;
    }

    final live = _reachable(files);
    final dead = files.keys.where((f) => !live.contains(f)).toList()..sort();
    // ignore: avoid_print
    print('i18n guard: ${live.length} reachable files checked, '
        '${dead.length} unreachable skipped');

    final violations = <String>[];
    for (final rel in live.toList()..sort()) {
      for (final hit in scanSource(files[rel]!.readAsStringSync())) {
        violations.add('$rel:${hit.line}: ${hit.text}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Hard-coded UI text found. Move it to lib/l10n/app_*.arb (all 7 '
          'locales), run `flutter gen-l10n` and use AppLocalizations — or, '
          'if it truly must stay literal, add `// i18n-ignore: <reason>`.\n'
          '${violations.join('\n')}',
    );
  });

  group('scanner self-test (the guard CAN fail)', () {
    test('flags literal Text, hintText, and prose title', () {
      const src = '''
Widget build(BuildContext c) => Column(children: [
  const Text('Hello world'),
  Text(
    "Save changes",
  ),
  TextField(decoration: InputDecoration(hintText: 'Search people')),
  Quest(title: 'Daily Explorer'),
  Tooltip(message: 'Close'),
]);
''';
      final hits = scanSource(src).map((h) => h.text).toList();
      expect(hits, containsAll(<String>[
        'Hello world',
        'Save changes',
        'Search people',
        'Daily Explorer',
        'Close',
      ]));
    });

    test('ignores l10n, ids, interpolation-only, brands, markers, comments', () {
      const src = '''
Widget build(BuildContext c) => Column(children: [
  Text(l10n.saveButton),
  Text('\$count'),
  Text('GreenGo'),
  Thing(title: 'user_profile_id'),
  Text('Deutsch'), // i18n-ignore: language autonym
  // i18n-ignore: CSV column names
  Text('EMAIL,DAYS,TIER'),
  // Text('commented out'),
]);
''';
      expect(scanSource(src), isEmpty);
    });
  });
}

const _excludedDirs = ['lib/generated/', 'lib/l10n/'];

const _brands = <String>{
  'GreenGo', 'Facebook', 'Instagram', 'WhatsApp', 'Pix', 'PayPal', 'Stripe',
  'Mercado Pago', 'TikTok', 'LinkedIn', 'Telegram', 'X', 'YouTube', 'Google',
  'Apple', 'Ticketmaster', 'Viator', 'Snapchat', 'Twitter', 'Spotify',
  'Revolut', 'Wise', 'Venmo', 'Cash App', 'Zelle', 'MB WAY', 'Bizum',
  'Satispay', 'Lydia', 'Twint', 'Swish', 'Vipps', 'MobilePay', 'Paysafecard',
  'Klarna', 'Discord', 'Threads', 'Bluesky', 'Pinterest', 'Reddit', 'Twitch',
  'WeChat', 'LINE', 'Line', 'Signal', 'Viber', 'Skype',
};

// Widgets whose first positional (or text/message/data) arg is visible text.
const _widget = r'\b(?:Text|SelectableText|AutoSizeText|Text\.rich|TextSpan|Tab|Tooltip)\s*\(\s*(?:(?:text|message|data)\s*:\s*)?';
// Params that are always user-visible text.
const _paramAlways = r'\b(?:labelText|hintText|helperText|errorText|counterText|prefixText|suffixText|tooltip|semanticLabel|semanticsLabel)\s*:\s*';
// Params that are usually user-visible text (flagged only for prose).
const _paramProse = r'\b(?:label|title|subtitle|message|description|content|buttonText|buttonLabel|actionLabel|confirmLabel|cancelLabel|confirmText|cancelText|emptyText|emptyMessage|placeholder|heading|body|text|name|displayName|hint|tip|question|answer|prompt|explanation)\s*:\s*';
const _lit = r'''(?:const\s+)?r?('|")((?:(?!\1)[^\\\n]|\\.)*)\1''';

final _rxAlways = RegExp('(?:$_widget|$_paramAlways)$_lit');
final _rxProse = RegExp('$_paramProse$_lit');
final _interp = RegExp(r'\$\{[^}]*\}|\$\w+');
final _escapes = RegExp(r'\\[nrtu]');
final _letters = RegExp(r'[A-Za-zÀ-ɏ]{2,}');
final _upperStart = RegExp(r'^[A-ZÀ-Þ]');

class GuardHit {
  const GuardHit(this.line, this.text);
  final int line;
  final String text;
}

/// Returns the hard-coded UI literals in [source] (see the file doc).
List<GuardHit> scanSource(String source) {
  final lines = source.split('\n');
  // Blank out comment-only lines so commented-out code is not flagged.
  final code = lines
      .map((l) => l.trimLeft().startsWith('//') ? '' : l)
      .join('\n');

  bool ignored(int line) {
    if (lines[line - 1].contains('i18n-ignore')) return true;
    if (line >= 2) {
      final above = lines[line - 2].trimLeft();
      if (above.startsWith('//') && above.contains('i18n-ignore')) return true;
    }
    return false;
  }

  final hits = <String, GuardHit>{};
  void collect(RegExp rx, {required bool proseOnly}) {
    for (final m in rx.allMatches(code)) {
      final s = m.group(2)!;
      final bare = s.replaceAll(_interp, '');
      if (!_letters.hasMatch(bare.replaceAll(_escapes, ' '))) continue;
      final t = bare.trim();
      if (proseOnly && !(t.contains(' ') || _upperStart.hasMatch(t))) continue;
      if (_brands.contains(s.trim())) continue;
      final start = m.start + m.group(0)!.indexOf(m.group(1)!) + 1;
      final line = '\n'.allMatches(code.substring(0, start)).length + 1;
      if (ignored(line)) continue;
      hits['$line:$s'] = GuardHit(line, s);
    }
  }

  collect(_rxAlways, proseOnly: false);
  collect(_rxProse, proseOnly: true);
  return hits.values.toList()..sort((a, b) => a.line.compareTo(b.line));
}

String _norm(String p) => p.replaceAll('\\', '/').replaceFirst(RegExp(r'^\./'), '');

/// Files reachable from `lib/main*.dart` through import/export/part
/// directives (including conditional `if (...) '...'` imports).
Set<String> _reachable(Map<String, File> files) {
  final pkg = RegExp(r'^name:\s*(\S+)', multiLine: true)
      .firstMatch(File('pubspec.yaml').readAsStringSync())!
      .group(1)!;
  final directive = RegExp(
      r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
      multiLine: true);
  final conditional = RegExp(r'''\bif\s*\([^)]*\)\s*['"]([^'"]+)['"]''');

  List<String> deps(String rel) {
    final src = files[rel]!.readAsStringSync();
    final dir = rel.substring(0, rel.lastIndexOf('/'));
    final uris = [
      ...directive.allMatches(src).map((m) => m.group(1)!),
      ...conditional.allMatches(src).map((m) => m.group(1)!),
    ];
    final out = <String>[];
    for (final u in uris) {
      if (u.startsWith('package:$pkg/')) {
        out.add('lib/${u.substring('package:$pkg/'.length)}');
      } else if (!u.startsWith('package:') && !u.startsWith('dart:')) {
        out.add(_resolve(dir, u));
      }
    }
    return out;
  }

  final entry = RegExp(r'^lib/main[^/]*\.dart$');
  final seen = <String>{};
  final stack = files.keys.where(entry.hasMatch).toList();
  while (stack.isNotEmpty) {
    final f = stack.removeLast();
    if (!files.containsKey(f) || !seen.add(f)) continue;
    stack.addAll(deps(f));
  }
  return seen;
}

String _resolve(String dir, String rel) {
  final parts = dir.split('/');
  for (final seg in rel.split('/')) {
    if (seg == '..') {
      parts.removeLast();
    } else if (seg != '.') {
      parts.add(seg);
    }
  }
  return parts.join('/');
}
