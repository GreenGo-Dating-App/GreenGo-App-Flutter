import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/follow_name_normalizer.dart';

/// The app's search query must be normalized EXACTLY like the server writes
/// `followerNameLower` / `followeeNameLower` (functions social/followNames.ts),
/// or a prefix search silently misses people. Both sides read this fixture.
void main() {
  final fixture = jsonDecode(
          File('test/fixtures/follow_name_normalization.json').readAsStringSync())
      as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<List<dynamic>>();

  test('fixture is not empty', () => expect(cases.length, greaterThan(10)));

  for (final c in cases) {
    final raw = c[0] as String;
    final want = c[1] as String;
    test('${jsonEncode(raw)} -> ${jsonEncode(want)}', () {
      expect(normalizeFollowName(raw), want);
    });
  }

  test('caps the length at 80 characters', () {
    expect(normalizeFollowName('a' * 200).length, 80);
  });
}
