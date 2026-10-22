import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/domain/community_text_guard.dart';

/// Apple 4.3(b): the app warns about dating wording with the SAME lists and
/// results as the server (functions/src/communities/communityTextGuard.ts).
void main() {
  final fixture = jsonDecode(
          File('test/fixtures/community_dating_terms.json').readAsStringSync())
      as Map<String, dynamic>;

  test('lists are identical to the shared fixture (server parity)', () {
    expect(kCommunityDatingTerms, List<String>.from(fixture['terms'] as List));
    expect(kCommunityDatingTermExceptions,
        List<String>.from(fixture['exceptions'] as List));
  });

  for (final v in (fixture['vectors'] as List).cast<Map<String, dynamic>>()) {
    final text = v['text'] as String;
    final expected = List<String>.from(v['expected'] as List);
    test('${expected.isEmpty ? 'ignores' : 'flags'}: $text', () {
      final hits = findCommunityDatingTerms(text);
      if (expected.isEmpty) {
        expect(hits, isEmpty);
      } else {
        expect(hits, containsAll(expected));
      }
    });
  }

  test('null / empty are safe; any field with a hit counts', () {
    expect(findCommunityDatingTerms(null), isEmpty);
    expect(findCommunityDatingTerms(''), isEmpty);
    expect(hasCommunityDatingWording(['Hiking', null, 'Paquera']), isTrue);
    expect(hasCommunityDatingWording(['Hiking', 'Save the date']), isFalse);
  });
}
