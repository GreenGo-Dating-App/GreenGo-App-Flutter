import 'package:flutter_test/flutter_test.dart';

/// Master Test Plan — F4/F6/B5: the date + validity rules the Explore event
/// rails and the external-events pager rely on. These are pure re-implementations
/// of the shipped rules so they run deterministically (fixed "today").
void main() {
  // A fixed "today" so assertions never depend on the wall clock.
  const today = '2026-07-15';
  final isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  bool wellFormed(String? d) => d != null && isoDate.hasMatch(d);
  bool todayOnward(String d) => d.compareTo(today) >= 0;
  bool withinWeek(String d) {
    // today .. today+7 (2026-07-22) inclusive, lexical compare on ISO dates.
    const weekEnd = '2026-07-22';
    return d.compareTo(today) >= 0 && d.compareTo(weekEnd) <= 0;
  }

  group('ISO date validity (live events must have a clear date)', () {
    test('accepts well-formed yyyy-MM-dd', () {
      expect(wellFormed('2026-07-15'), isTrue);
      expect(wellFormed('2026-12-31'), isTrue);
    });

    test('rejects junk / partial / null / empty dates', () {
      expect(wellFormed('1'), isFalse);
      expect(wellFormed('2026'), isFalse);
      expect(wellFormed('2026-7-5'), isFalse); // not zero-padded
      expect(wellFormed(''), isFalse);
      expect(wellFormed(null), isFalse);
      expect(wellFormed('yesterday'), isFalse);
    });
  });

  group('today-onward filter (no past events)', () {
    test('keeps today and future', () {
      expect(todayOnward('2026-07-15'), isTrue);
      expect(todayOnward('2026-08-01'), isTrue);
    });
    test('drops past', () {
      expect(todayOnward('2026-07-14'), isFalse);
      expect(todayOnward('2020-01-01'), isFalse);
    });
  });

  group('within-1-week live fallback window', () {
    test('keeps dates in [today, today+7]', () {
      expect(withinWeek('2026-07-15'), isTrue);
      expect(withinWeek('2026-07-18'), isTrue);
      expect(withinWeek('2026-07-22'), isTrue);
    });
    test('drops dates beyond a week or in the past', () {
      expect(withinWeek('2026-07-23'), isFalse);
      expect(withinWeek('2026-07-14'), isFalse);
    });
  });

  group('combined live-event gate (ticketmaster)', () {
    // The shipped rule: valid ISO && today-onward (pager); the "happening soon"
    // fallback additionally requires within-1-week.
    bool liveTabAllowed(String? d) => wellFormed(d) && todayOnward(d!);
    bool happeningFallbackAllowed(String? d) =>
        wellFormed(d) && withinWeek(d!);

    test('live tab: valid + today-onward only', () {
      expect(liveTabAllowed('2026-07-20'), isTrue);
      expect(liveTabAllowed('2026-07-14'), isFalse); // past
      expect(liveTabAllowed('1'), isFalse); // junk
      expect(liveTabAllowed(null), isFalse);
    });

    test('happening-soon fallback: valid + within a week', () {
      expect(happeningFallbackAllowed('2026-07-19'), isTrue);
      expect(happeningFallbackAllowed('2026-08-19'), isFalse); // >1wk
      expect(happeningFallbackAllowed('2026-07-14'), isFalse); // past
      expect(happeningFallbackAllowed('1'), isFalse); // junk
    });
  });

  group('ascending date sort (earliest first)', () {
    test('sorts ISO date strings chronologically (lexical == chronological)',
        () {
      final dates = ['2026-08-01', '2026-07-15', '2026-07-20', '2026-07-16']
        ..sort();
      expect(dates,
          ['2026-07-15', '2026-07-16', '2026-07-20', '2026-08-01']);
    });

    test('sorts DateTime events earliest first', () {
      final events = <DateTime>[
        DateTime(2026, 8, 1),
        DateTime(2026, 7, 15),
        DateTime(2026, 7, 20),
      ]..sort((a, b) => a.compareTo(b));
      expect(events.first, DateTime(2026, 7, 15));
      expect(events.last, DateTime(2026, 8, 1));
    });
  });
}
