import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/business_categories.dart';

void main() {
  test('every category sits in exactly one type, so both select boxes can show it', () {
    for (final c in BusinessCategories.all) {
      final groups = BusinessCategories.grouped.entries.where((e) => e.value.contains(c)).toList();
      expect(groups.length, 1, reason: '$c must be in exactly one group');
    }
  });

  test('groupOf finds the type of a saved category, null for unknown/none', () {
    final first = BusinessCategories.grouped.entries.first;
    expect(BusinessCategories.groupOf(first.value.first), first.key);
    expect(BusinessCategories.groupOf(null), isNull);
    expect(BusinessCategories.groupOf('no-such-category'), isNull);
  });
}
