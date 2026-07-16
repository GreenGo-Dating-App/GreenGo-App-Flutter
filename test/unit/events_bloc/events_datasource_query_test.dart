import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/data/datasources/events_remote_datasource.dart';

import '../../support/events_fixtures.dart';

/// Master Test Plan — Events datasource / query validity.
/// Exercises EventsRemoteDataSourceImpl against a fake Firestore. Guards the
/// live/public gating, the ascending startDate ordering, and the
/// organized+attending union in getUserEvents.
void main() {
  group('EventsRemoteDataSource.getEvents against fake Firestore', () {
    test('returns only live, public events ordered by startDate ascending',
        () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_late', organizerId: 'o1', startDate: DateTime(2030, 6, 1));
      await EventFixtures.seedEvent(db,
          id: 'e_early', organizerId: 'o1', startDate: DateTime(2030, 1, 1));
      await EventFixtures.seedEvent(db,
          id: 'e_mid', organizerId: 'o1', startDate: DateTime(2030, 3, 1));
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getEvents();

      expect(events.map((e) => e.id).toList(),
          ['e_early', 'e_mid', 'e_late'],
          reason: 'must be ordered ascending by startDate');
    });

    test('excludes draft (not-live) events', () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_pub', organizerId: 'o1', startDate: DateTime(2030, 1, 1));
      await EventFixtures.seedEvent(db,
          id: 'e_draft',
          organizerId: 'o1',
          startDate: DateTime(2030, 2, 1),
          status: 'draft');
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getEvents();

      expect(events.map((e) => e.id), ['e_pub']);
    });

    test('excludes private events from discovery', () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_public', organizerId: 'o1', startDate: DateTime(2030, 1, 1));
      await EventFixtures.seedEvent(db,
          id: 'e_private',
          organizerId: 'o1',
          startDate: DateTime(2030, 2, 1),
          visibility: 'private');
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getEvents();

      expect(events.map((e) => e.id), ['e_public']);
      expect(events.every((e) => e.isPublic), isTrue);
    });

    test('upcoming:true excludes past events', () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_past', organizerId: 'o1', startDate: DateTime(2020, 1, 1));
      await EventFixtures.seedEvent(db,
          id: 'e_future', organizerId: 'o1', startDate: DateTime(2030, 1, 1));
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getEvents(upcoming: true);

      expect(events.map((e) => e.id), ['e_future']);
    });

    test('category filter narrows to the requested category', () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_food',
          organizerId: 'o1',
          startDate: DateTime(2030, 1, 1),
          category: 'food');
      await EventFixtures.seedEvent(db,
          id: 'e_sports',
          organizerId: 'o1',
          startDate: DateTime(2030, 2, 1),
          category: 'sports');
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getEvents(category: 'food');

      expect(events.map((e) => e.id), ['e_food']);
    });

    test('returns empty list when there are no events', () async {
      final db = FakeFirebaseFirestore();
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      expect(await ds.getEvents(), isEmpty);
    });
  });

  group('EventsRemoteDataSource.getEventById', () {
    test('returns the event when it exists', () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_x', organizerId: 'o1', startDate: DateTime(2030, 1, 1));
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final event = await ds.getEventById('e_x');

      expect(event, isNotNull);
      expect(event!.id, 'e_x');
    });

    test('returns null when the event is missing', () async {
      final db = FakeFirebaseFirestore();
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      expect(await ds.getEventById('nope'), isNull);
    });
  });

  group('EventsRemoteDataSource.getUserEvents', () {
    test('unions organized + attending(going) events, deduped and sorted',
        () async {
      final db = FakeFirebaseFirestore();
      // Organized by u1 (later start).
      await EventFixtures.seedEvent(db,
          id: 'e_org', organizerId: 'u1', startDate: DateTime(2030, 5, 1));
      // Organized by someone else, but u1 is attending (earlier start).
      await EventFixtures.seedEvent(db,
          id: 'e_att', organizerId: 'u2', startDate: DateTime(2030, 2, 1));
      await EventFixtures.seedAttendee(db, eventId: 'e_att', userId: 'u1');
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getUserEvents('u1');

      expect(events.map((e) => e.id).toList(), ['e_att', 'e_org'],
          reason: 'attending event starts earlier so it sorts first');
    });

    test('does not duplicate an event the user both organized and joined',
        () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_self', organizerId: 'u1', startDate: DateTime(2030, 3, 1));
      await EventFixtures.seedAttendee(db, eventId: 'e_self', userId: 'u1');
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getUserEvents('u1');

      expect(events.where((e) => e.id == 'e_self').length, 1);
    });

    test('returns empty for a user with no organized/attending events',
        () async {
      final db = FakeFirebaseFirestore();
      await EventFixtures.seedEvent(db,
          id: 'e_other', organizerId: 'someone', startDate: DateTime(2030, 1, 1));
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      expect(await ds.getUserEvents('nobody'), isEmpty);
    });
  });
}
