import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/session_cache_gate.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/events/domain/entities/event_country_stat.dart';
import 'package:greengo_chat/features/events/domain/repositories/events_repository.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_bloc.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_event.dart';
import 'package:greengo_chat/features/events/presentation/bloc/events_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/events_fixtures.dart';

class MockEventsRepository extends Mock implements EventsRepository {}

/// EventsBloc behaviour with a mocked repository (dartz Either). No bloc_test —
/// asserts via expectLater(bloc.stream, emitsInOrder([...])).
void main() {
  late MockEventsRepository repo;
  late EventsBloc bloc;

  final e1 = EventFixtures.build(id: 'e1', startDate: DateTime(2030, 1, 1));
  final e2 = EventFixtures.build(id: 'e2', startDate: DateTime(2030, 2, 1));

  setUp(() {
    // The cache gate is static/process-wide — reset it so each test starts
    // "cold" (network-first), giving deterministic single-emission loads.
    SessionCacheGate.reset();
    repo = MockEventsRepository();
    bloc = EventsBloc(repository: repo);
  });

  tearDown(() => bloc.close());

  group('LoadEvents', () {
    test('emits [Loading, Loaded] on success', () async {
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: any(named: 'preferCache'),
          )).thenAnswer((_) async => Right([e1, e2]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoading>(),
          isA<EventsLoaded>().having(
              (s) => s.events.map((e) => e.id).toList(),
              'event ids',
              ['e1', 'e2']),
        ]),
      );

      bloc.add(const LoadEvents());
      await expectation;
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: any(named: 'preferCache'),
          )).thenAnswer((_) async => const Left(ServerFailure('boom')));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoading>(),
          isA<EventsError>().having((s) => s.message, 'message', 'boom'),
        ]),
      );

      bloc.add(const LoadEvents());
      await expectation;
    });

    test('emits Loaded with an empty list when there are no events', () async {
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: any(named: 'preferCache'),
          )).thenAnswer((_) async => const Right(<Event>[]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoading>(),
          isA<EventsLoaded>().having((s) => s.events, 'events', isEmpty),
        ]),
      );

      bloc.add(const LoadEvents());
      await expectation;
    });
  });

  group('LoadUserEvents', () {
    test('emits Loaded carrying userEvents from an unloaded state', () async {
      when(() => repo.getUserEvents(any(), preferCache: any(named: 'preferCache')))
          .thenAnswer((_) async => Right([e1]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoaded>().having(
              (s) => s.userEvents.map((e) => e.id).toList(),
              'userEvents',
              ['e1']),
        ]),
      );

      bloc.add(const LoadUserEvents(userId: 'u1'));
      await expectation;
    });

    test('emits Error from an unloaded state on failure', () async {
      when(() => repo.getUserEvents(any(), preferCache: any(named: 'preferCache')))
          .thenAnswer((_) async => const Left(ServerFailure('no user events')));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsError>()
              .having((s) => s.message, 'message', 'no user events'),
        ]),
      );

      bloc.add(const LoadUserEvents(userId: 'u1'));
      await expectation;
    });

    test('updates userEvents in place when already loaded', () async {
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: any(named: 'preferCache'),
          )).thenAnswer((_) async => Right([e1]));
      when(() => repo.getUserEvents(any(), preferCache: any(named: 'preferCache')))
          .thenAnswer((_) async => Right([e2]));
      // Cache pass returns empty (cold cache in a unit test) so only the server
      // pass emits — keeps the single-emission ordering below.
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: true,
          )).thenAnswer((_) async => Right(<Event>[]));
      when(() => repo.getUserEvents(any(), preferCache: true))
          .thenAnswer((_) async => Right(<Event>[]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoading>(),
          isA<EventsLoaded>(),
          isA<EventsLoaded>().having(
              (s) => s.userEvents.map((e) => e.id).toList(),
              'userEvents',
              ['e2']),
        ]),
      );

      bloc.add(const LoadEvents());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LoadUserEvents(userId: 'u1'));
      await expectation;
    });
  });

  group('LoadNearbyEvents', () {
    test('emits Loaded carrying nearbyEvents from an unloaded state', () async {
      when(() => repo.getEventsNearLocation(any(), any(), any()))
          .thenAnswer((_) async => Right([e1]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoaded>().having(
              (s) => s.nearbyEvents.map((e) => e.id).toList(),
              'nearbyEvents',
              ['e1']),
        ]),
      );

      bloc.add(const LoadNearbyEvents(latitude: 1, longitude: 2));
      await expectation;
    });

    test('emits Error from an unloaded state on failure', () async {
      when(() => repo.getEventsNearLocation(any(), any(), any()))
          .thenAnswer((_) async => const Left(NetworkFailure('offline')));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsError>().having((s) => s.message, 'message', 'offline'),
        ]),
      );

      bloc.add(const LoadNearbyEvents(latitude: 1, longitude: 2));
      await expectation;
    });
  });

  group('RSVP', () {
    test('emits RsvpSuccess then re-emits the list', () async {
      when(() => repo.rsvpEvent(any(), any(), any()))
          .thenAnswer((_) async => const Right(null));
      when(() => repo.getEventAttendees(any()))
          .thenAnswer((_) async => const Right(<EventAttendee>[]));
      when(() => repo.getEventById(any()))
          .thenAnswer((_) async => Right(e1));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventRsvpSuccess>()
              .having((s) => s.eventId, 'eventId', 'e1')
              .having((s) => s.status, 'status', 'going'),
          isA<EventsLoaded>(),
        ]),
      );

      bloc.add(const RsvpEvent(
          eventId: 'e1', userId: 'u1', status: 'going'));
      await expectation;
    });

    test('emits Error when the RSVP write fails', () async {
      when(() => repo.rsvpEvent(any(), any(), any())).thenAnswer(
          (_) async => const Left(ServerFailure('rsvp failed')));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsError>().having((s) => s.message, 'message', 'rsvp failed'),
        ]),
      );

      bloc.add(const RsvpEvent(
          eventId: 'e1', userId: 'u1', status: 'going'));
      await expectation;
    });

    test('CancelRsvp emits RsvpSuccess with status "cancelled"', () async {
      when(() => repo.cancelRsvp(any(), any()))
          .thenAnswer((_) async => const Right(null));
      when(() => repo.getEventAttendees(any()))
          .thenAnswer((_) async => const Right(<EventAttendee>[]));
      when(() => repo.getEventById(any()))
          .thenAnswer((_) async => Right(e1));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventRsvpSuccess>()
              .having((s) => s.status, 'status', 'cancelled'),
          isA<EventsLoaded>(),
        ]),
      );

      bloc.add(const CancelRsvp(eventId: 'e1', userId: 'u1'));
      await expectation;
    });
  });

  group('FilterByCategory', () {
    test('applies the category filter on the loaded state', () async {
      final food = EventFixtures.build(id: 'f', category: EventCategory.food);
      final arts = EventFixtures.build(id: 'a', category: EventCategory.arts);
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: any(named: 'preferCache'),
          )).thenAnswer((_) async => Right([food, arts]));
      // Cold cache: cache pass emits nothing, so LoadEvents emits once.
      when(() => repo.getEvents(
            category: any(named: 'category'),
            city: any(named: 'city'),
            upcoming: any(named: 'upcoming'),
            preferCache: true,
          )).thenAnswer((_) async => Right(<Event>[]));

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<EventsLoading>(),
          isA<EventsLoaded>(),
          isA<EventsLoaded>()
              .having((s) => s.selectedCategory, 'selectedCategory',
                  EventCategory.food)
              .having((s) => s.filteredEvents.map((e) => e.id).toList(),
                  'filtered', ['f']),
        ]),
      );

      bloc.add(const LoadEvents());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const FilterByCategory(category: EventCategory.food));
      await expectation;
    });
  });

  test('country stats stub compiles against the repo interface', () async {
    when(() => repo.getCountryStats())
        .thenAnswer((_) async => const Right(<EventCountryStat>[]));
    final result = await repo.getCountryStats();
    expect(result.isRight(), isTrue);
  });
}
