import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_state.dart';

import '../../support/events_fixtures.dart';

/// Pure getter tests for EventsLoaded — the sorting/filtering the Events screen
/// relies on. No bloc, no async.
void main() {
  final past = EventFixtures.build(
      id: 'past', startDate: DateTime(2020, 1, 1));
  final soon = EventFixtures.build(
      id: 'soon', startDate: DateTime(2030, 1, 1));
  final later = EventFixtures.build(
      id: 'later', startDate: DateTime(2030, 6, 1));
  final latest = EventFixtures.build(
      id: 'latest', startDate: DateTime(2031, 1, 1));

  group('EventsLoaded.upcomingEvents', () {
    test('sorts upcoming events ascending by startDate', () {
      final state = EventsLoaded(events: [latest, soon, later]);

      expect(state.upcomingEvents.map((e) => e.id).toList(),
          ['soon', 'later', 'latest']);
    });

    test('excludes events whose startDate is in the past', () {
      final state = EventsLoaded(events: [past, soon]);

      final ids = state.upcomingEvents.map((e) => e.id).toList();
      expect(ids, contains('soon'));
      expect(ids, isNot(contains('past')));
    });

    test('is empty when every event is in the past', () {
      final state = EventsLoaded(events: [past]);

      expect(state.upcomingEvents, isEmpty);
    });

    test('respects the selected category filter', () {
      final food = EventFixtures.build(
          id: 'food',
          category: EventCategory.food,
          startDate: DateTime(2030, 2, 1));
      final sports = EventFixtures.build(
          id: 'sports',
          category: EventCategory.sports,
          startDate: DateTime(2030, 1, 1));
      final state = EventsLoaded(
        events: [food, sports],
        selectedCategory: EventCategory.food,
      );

      expect(state.upcomingEvents.map((e) => e.id).toList(), ['food']);
    });
  });

  group('EventsLoaded.filteredEvents', () {
    test('returns all events when no category is selected', () {
      final state = EventsLoaded(events: [soon, later]);

      expect(state.filteredEvents.length, 2);
    });

    test('returns only events of the selected category', () {
      final food = EventFixtures.build(id: 'f', category: EventCategory.food);
      final arts = EventFixtures.build(id: 'a', category: EventCategory.arts);
      final state = EventsLoaded(
        events: [food, arts],
        selectedCategory: EventCategory.arts,
      );

      expect(state.filteredEvents.map((e) => e.id).toList(), ['a']);
    });
  });

  group('EventsLoaded.copyWith', () {
    test('clearCategory drops the selected category', () {
      final state = EventsLoaded(
        events: [soon],
        selectedCategory: EventCategory.food,
      );

      final cleared = state.copyWith(clearCategory: true);

      expect(cleared.selectedCategory, isNull);
    });

    test('preserves existing lists when not overridden', () {
      final state = EventsLoaded(
        events: [soon],
        userEvents: [later],
        nearbyEvents: [latest],
      );

      final copy = state.copyWith(selectedCategory: EventCategory.food);

      expect(copy.events, [soon]);
      expect(copy.userEvents, [later]);
      expect(copy.nearbyEvents, [latest]);
      expect(copy.selectedCategory, EventCategory.food);
    });
  });
}
