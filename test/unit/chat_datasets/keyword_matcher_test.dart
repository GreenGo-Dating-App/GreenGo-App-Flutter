import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/keyword_matcher.dart';

void main() {
  final index = KeywordIndex.fromJson({
    'a': {
      '1': ['IT', 'rome', 'Colosseum'],
      '2': ['IT', 'rome', 'Roman Forum'],
    },
    'c': {
      'IT:rome': ['Rome'],
      'FR:nice': ['Nice'],
    },
    'k': {'IT': 'Italy'},
    'n': [
      ['colosseum', 'a', '1', 0],
      ['colosseo', 'a', '1', 0],
      ['colisee', 'a', '1', 0],
      ['roman forum', 'a', '2', 0],
      ['rome', 'c', 'IT:rome', 0],
      ['roma', 'c', 'IT:rome', 0],
      ['nice', 'c', 'FR:nice', 1],
      ['italia', 'k', 'IT', 0],
    ],
  });

  test('finds attractions, cities and countries in any language', () {
    final m = index.match('Ieri ho visto il Colosseo a Roma, Italia!');
    expect(m.map((e) => e.kind), [KeywordKind.attraction, KeywordKind.city, KeywordKind.country]);
    expect(m.first.refs, ['1']);
    expect('Ieri ho visto il Colosseo a Roma, Italia!'.substring(m.first.start, m.first.end), 'Colosseo');
  });

  test('accent and case insensitive', () {
    expect(index.match('le COLISÉE est grand').single.refs, ['1']);
  });

  test('longest match wins (Roman Forum, not Rome)', () {
    final m = index.match('Meet me at the roman forum');
    expect(m.single.refs, ['2']);
  });

  test('common-word aliases need a capital letter', () {
    expect(index.match('that was nice'), isEmpty);
    expect(index.match('we flew to Nice').single.refs, ['FR:nice']);
  });

  test('entity json round trip and bounds check', () {
    final m = index.match('Roma').single;
    expect(KeywordMatch.fromJson(m.toJson(), 4)!.refs, ['IT:rome']);
    expect(KeywordMatch.fromJson(m.toJson(), 2), isNull);
    expect(KeywordMatch.fromJson({'s': 'x'}, 10), isNull);
  });

  // Real index (built by tools/chat_datasets/build_keywords.js), when present.
  final real = File('tools/chat_datasets/build/keywords.json');
  test('real index: Colosseo / Kolosseum / Rome / Italia', () {
    final idx = KeywordIndex.fromJson(
        jsonDecode(real.readAsStringSync()) as Map<String, dynamic>);
    final it = idx.match('Domani andiamo al Colosseo e poi in giro per Roma');
    expect(it.map((e) => e.kind), contains(KeywordKind.attraction));
    expect(it.map((e) => e.kind), contains(KeywordKind.city));
    final de = idx.match('Das Kolosseum in Rom ist riesig');
    expect(de.first.kind, KeywordKind.attraction);
    expect(idx.match('I love Italy').single.kind, KeywordKind.country);
    expect(idx.match('that was a nice day'), isEmpty);
  }, skip: real.existsSync() ? false : 'keywords.json not built');
}
