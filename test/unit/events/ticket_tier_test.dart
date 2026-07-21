import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/events/domain/entities/event_scheduling.dart';

/// Master Test Plan — Events / paid ticket tiers + recurring-series safety.
/// Covers E2E matrix items #212 (paid event ticket tiers: price + capacity)
/// and the recurring-series cap behind #237. Pure tests against the real
/// [TicketTier] and [EventRecurrence] value objects.
void main() {
  group('TicketTier pricing & capacity flags', () {
    test('a default tier is free and unlimited', () {
      const t = TicketTier(id: 't', name: 'General');
      expect(t.isFree, isTrue);
      expect(t.isUnlimited, isTrue);
      expect(t.priceCoins, 0);
      expect(t.capacity, 0);
    });

    test('a positive priceCoins makes the tier paid', () {
      const t = TicketTier(id: 't', name: 'VIP', priceCoins: 250);
      expect(t.isFree, isFalse);
    });

    test('non-positive priceCoins is treated as free', () {
      expect(const TicketTier(id: 't', name: 'x', priceCoins: 0).isFree, isTrue);
      expect(
          const TicketTier(id: 't', name: 'x', priceCoins: -5).isFree, isTrue);
    });

    test('a positive capacity makes the tier limited', () {
      const t = TicketTier(id: 't', name: 'VIP', capacity: 50);
      expect(t.isUnlimited, isFalse);
    });

    test('toMap / fromMap round-trips all fields', () {
      const t = TicketTier(
          id: 'vip', name: 'VIP Pass', priceCoins: 300, capacity: 25);
      final restored = TicketTier.fromMap(t.toMap());
      expect(restored, t);
    });

    test('fromMap defaults missing/garbage fields safely', () {
      final t = TicketTier.fromMap(const {});
      expect(t.id, '');
      expect(t.name, '');
      expect(t.priceCoins, 0);
      expect(t.capacity, 0);
    });
  });

  group('EventRecurrence series safety', () {
    test('none frequency is never recurring', () {
      const r = EventRecurrence(count: 12);
      expect(r.isRecurring, isFalse);
    });

    test('a repeating frequency with count > 1 is recurring', () {
      const r = EventRecurrence(
          frequency: RecurrenceFrequency.weekly, count: 4);
      expect(r.isRecurring, isTrue);
    });

    test('a repeating frequency with a single occurrence is NOT recurring', () {
      const r = EventRecurrence(
          frequency: RecurrenceFrequency.weekly, count: 1);
      expect(r.isRecurring, isFalse);
    });

    test('safeInterval clamps sub-1 intervals to 1', () {
      expect(const EventRecurrence(interval: 0).safeInterval, 1);
      expect(const EventRecurrence(interval: -3).safeInterval, 1);
      expect(const EventRecurrence(interval: 2).safeInterval, 2);
    });

    test('safeCount clamps to [1, kMaxSeriesOccurrences]', () {
      expect(const EventRecurrence(count: 0).safeCount, 1);
      expect(const EventRecurrence(count: 5).safeCount, 5);
      expect(
        const EventRecurrence(count: 99).safeCount,
        kMaxSeriesOccurrences,
        reason: 'series fan-out must be capped',
      );
    });

    test('toMap emits the clamped (safe) interval & count', () {
      final map = const EventRecurrence(
        frequency: RecurrenceFrequency.daily,
        interval: 0,
        count: 999,
      ).toMap();
      expect(map['interval'], 1);
      expect(map['count'], kMaxSeriesOccurrences);
      expect(map['frequency'], 'daily');
    });

    test('RecurrenceFrequency.fromString falls back to none on junk/null', () {
      expect(RecurrenceFrequencyX.fromString('monthly'),
          RecurrenceFrequency.monthly);
      expect(RecurrenceFrequencyX.fromString('yearly'),
          RecurrenceFrequency.none);
      expect(RecurrenceFrequencyX.fromString(null), RecurrenceFrequency.none);
    });
  });
}
