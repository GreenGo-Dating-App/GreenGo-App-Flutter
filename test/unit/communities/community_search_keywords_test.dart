import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/community_search_keywords.dart';

/// Dart side of the shared keyword algorithm. The vectors file is generated
/// from functions/src/communities/searchKeywords.ts, so a pass here proves the
/// app and the Cloud Function / backfill produce IDENTICAL arrays.
void main() {
  final vectors = jsonDecode(
    File('test/fixtures/community_search_keywords_vectors.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;

  group('parity with functions/src/communities/searchKeywords.ts', () {
    for (final v in (vectors['keywords'] as List).cast<Map<String, dynamic>>()) {
      final input = v['input'] as Map<String, dynamic>;
      test('keywords for ${jsonEncode(input)}', () {
        expect(
          buildCommunitySearchKeywords(
            name: input['name'] as String?,
            city: input['city'] as String?,
            tags: ((input['tags'] as List?) ?? const []).cast<String>(),
          ),
          (v['expected'] as List).cast<String>(),
        );
      });
    }
    for (final v
        in (vectors['normalize'] as List).cast<Map<String, dynamic>>()) {
      test('normalise "${v['input']}"', () {
        expect(normalizeCommunitySearchText(v['input'] as String),
            v['normalized']);
        expect(communitySearchTokens(v['input'] as String),
            (v['tokens'] as List).cast<String>());
      });
    }
  });

  test('prefixes of each word, accents stripped', () {
    expect(buildCommunitySearchKeywords(name: 'Café'), ['c', 'ca', 'caf', 'cafe']);
  });

  test('capped at 100 entries and 15 chars per prefix', () {
    final kw = buildCommunitySearchKeywords(
        name: List.generate(30, (i) => 'word${i}abcdefghijklmnop').join(' '));
    expect(kw.length, kMaxCommunitySearchKeywords);
    expect(kw.every((k) => k.runes.length <= kMaxCommunitySearchPrefixLength),
        isTrue);
  });

  group('communitySearchQueryToken', () {
    test('picks the longest word, normalised', () {
      expect(communitySearchQueryToken('Café Lisboa'), 'lisboa');
      expect(communitySearchQueryToken('  SÃO  '), 'sao');
    });
    test('truncates to the stored prefix length', () {
      expect(communitySearchQueryToken('Internationalization'),
          'internationaliz');
    });
    test('null for no searchable word', () {
      expect(communitySearchQueryToken('!!!'), isNull);
      expect(communitySearchQueryToken(''), isNull);
    });
  });

  group('communityMatchesSearchQuery', () {
    test('every query word must prefix a name/city/tag word', () {
      expect(
          communityMatchesSearchQuery(
              query: 'spanish lear', name: 'Spanish Learners Worldwide'),
          isTrue);
      expect(
          communityMatchesSearchQuery(
              query: 'spanish cooking', name: 'Spanish Learners Worldwide'),
          isFalse);
      expect(
          communityMatchesSearchQuery(
              query: 'cafe lisbon', name: 'Café Club', city: 'Lisbon'),
          isTrue);
      expect(
          communityMatchesSearchQuery(
              query: 'hiking', name: 'Weekend', tags: const ['Hiking']),
          isTrue);
    });
  });
}
