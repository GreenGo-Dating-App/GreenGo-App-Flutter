// ISO week key — must agree with functions/src/gamification/weekKey.ts on the
// SAME fixture file (test/unit/gamification/fixtures/iso_week_keys.json).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/gamification/domain/utils/week_key.dart';

void main() {
  final fixture = jsonDecode(
    File('test/unit/gamification/fixtures/iso_week_keys.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final cases = (fixture['cases'] as List).cast<Map<String, dynamic>>();

  group('isoWeekKey (shared fixtures)', () {
    test('has fixtures', () => expect(cases.length, greaterThan(10)));

    for (final c in cases) {
      final instant = c['instant'] as String;
      final expected = c['weekKey'] as String;
      test('$instant -> $expected (${c['note'] ?? ''})', () {
        expect(isoWeekKey(DateTime.parse(instant)), expected);
      });
    }

    test('weeks are 7 days long and start on Monday (2020-2030)', () {
      var day = DateTime.utc(2019, 12, 30);
      var prev = isoWeekKey(day);
      var daysInWeek = 1;
      final end = DateTime.utc(2031);
      day = day.add(const Duration(days: 1));
      while (day.isBefore(end)) {
        final key = isoWeekKey(day);
        if (key == prev) {
          daysInWeek++;
        } else {
          expect(daysInWeek, 7, reason: 'week $prev');
          expect(day.weekday, DateTime.monday);
          daysInWeek = 1;
          prev = key;
        }
        day = day.add(const Duration(days: 1));
      }
    });

    test('local times are converted to UTC first', () {
      final utc = DateTime.utc(2026, 10, 4, 23, 30);
      expect(isoWeekKey(utc.toLocal()), isoWeekKey(utc));
    });
  });

  group('weeklyXpFields', () {
    final now = DateTime.utc(2026, 10, 1, 12); // 2026-W40

    test('starts the counter when there is no doc', () {
      expect(weeklyXpFields(null, 25, now: now),
          {'weekKey': '2026-W40', 'weeklyXP': 25});
    });

    test('increments within the same week', () {
      expect(
          weeklyXpFields({'weekKey': '2026-W40', 'weeklyXP': 100}, 25,
              now: now),
          {'weekKey': '2026-W40', 'weeklyXP': 125});
    });

    test('resets to the grant amount when the stored week is stale', () {
      expect(
          weeklyXpFields({'weekKey': '2026-W39', 'weeklyXP': 900}, 25,
              now: now),
          {'weekKey': '2026-W40', 'weeklyXP': 25});
    });

    test('treats a doc without weekly fields as a fresh week', () {
      expect(weeklyXpFields(<String, dynamic>{}, 7, now: now),
          {'weekKey': '2026-W40', 'weeklyXP': 7});
    });
  });
}
