import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/data/datasources/events_remote_datasource.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';

import '../../support/events_fixtures.dart';

/// Event co-owners (coOrganizerIds) + manually typed (coordinate-less)
/// locations.
void main() {
  EventAttendee attendee(String uid,
          {bool organizerOnly = false, bool anonymous = false}) =>
      EventAttendee(
        id: uid,
        eventId: 'evt_1',
        userId: uid,
        userName: 'Name $uid',
        status: RSVPStatus.going,
        rsvpDate: DateTime(2030),
        visibleToOrganizerOnly: organizerOnly,
        isAnonymous: anonymous,
      );

  group('Event.isOwner / isCreator', () {
    final e = EventFixtures.build(organizerId: 'creator')
        .copyWith(coOrganizerIds: ['co1', 'co2']);

    test('creator and co-owners are owners; others are not', () {
      expect(e.isOwner('creator'), isTrue);
      expect(e.isOwner('co1'), isTrue);
      expect(e.isOwner('co2'), isTrue);
      expect(e.isOwner('stranger'), isFalse);
      expect(e.isOwner(''), isFalse);
    });

    test('only the creator is the creator', () {
      expect(e.isCreator('creator'), isTrue);
      expect(e.isCreator('co1'), isFalse);
      expect(e.isCreator(''), isFalse);
    });

    test('co-owner sees a private guest list; a stranger does not', () {
      final priv =
          e.copyWith(attendeeListVisibility: AttendeeListVisibility.private);
      expect(priv.canViewAttendeeList('co1'), isTrue);
      expect(priv.canViewAttendeeList('creator'), isTrue);
      expect(priv.canViewAttendeeList('stranger'), isFalse);
    });

    test('co-owner sees organizer-only / anonymous attendees like the creator',
        () {
      final hidden = attendee('a1', organizerOnly: true, anonymous: true);
      expect(hidden.isVisibleTo('co1', e.organizerViewIdFor('co1')), isTrue);
      expect(hidden.displayNameFor('co1', e.organizerViewIdFor('co1')),
          'Name a1');
      expect(hidden.isVisibleTo('stranger', e.organizerViewIdFor('stranger')),
          isFalse);
      expect(e.organizerViewIdFor('stranger'), 'creator');
    });

    test('defaults to no co-owners', () {
      expect(EventFixtures.build().coOrganizerIds, isEmpty);
    });
  });

  group('EventModel co-owner JSON', () {
    test('round-trips coOrganizerIds through toJson/fromJson', () {
      final e = EventFixtures.build(organizerId: 'creator')
          .copyWith(coOrganizerIds: ['co1', 'co2']);
      final json = EventModel.fromEntity(e).toJson();
      expect(json['coOrganizerIds'], ['co1', 'co2']);
      final back = EventModel.fromJson({...json, 'id': e.id});
      expect(back.coOrganizerIds, ['co1', 'co2']);
      expect(back.isOwner('co2'), isTrue);
    });

    test('missing / malformed field reads as empty', () {
      final base = EventModel.fromEntity(EventFixtures.build()).toJson()
        ..remove('coOrganizerIds');
      expect(EventModel.fromJson({...base, 'id': 'x'}).coOrganizerIds, isEmpty);
      expect(
          EventModel.fromJson({...base, 'id': 'x', 'coOrganizerIds': 'oops'})
              .coOrganizerIds,
          isEmpty);
    });

    test('drops the creator, duplicates, non-strings and caps at 5', () {
      final base =
          EventModel.fromEntity(EventFixtures.build(organizerId: 'creator'))
              .toJson();
      final parsed = EventModel.fromJson({
        ...base,
        'id': 'x',
        'coOrganizerIds': [
          'creator', 'a', 'a', 7, '', 'b', 'c', 'd', 'e', 'f', //
        ],
      });
      expect(parsed.coOrganizerIds, ['a', 'b', 'c', 'd', 'e']);
      expect(parsed.coOrganizerIds.length, kMaxEventCoOrganizers);
    });

    test('copyWith keeps co-owners unless replaced; props include them', () {
      final e = EventFixtures.build().copyWith(coOrganizerIds: ['co1']);
      expect(e.copyWith(title: 'x').coOrganizerIds, ['co1']);
      expect(e == e.copyWith(coOrganizerIds: ['co2']), isFalse);
    });
  });

  group('Manual location (no coordinates)', () {
    test('clearCoordinates drops lat/lng/city/country; no geohash written', () {
      final picked = EventFixtures.build(city: 'Rome').copyWith(
          latitude: 41.9, longitude: 12.5, country: 'Italy');
      expect(EventModel.fromEntity(picked).toJson().containsKey('geohash'),
          isTrue);
      final typed = picked.copyWith(
          locationName: 'Bar Luce, Milano',
          address: 'Bar Luce, Milano',
          clearCoordinates: true);
      expect(typed.latitude, isNull);
      expect(typed.longitude, isNull);
      expect(typed.city, isNull);
      expect(typed.country, isNull);
      expect(typed.locationName, 'Bar Luce, Milano');
      final json = EventModel.fromEntity(typed).toJson();
      expect(json.containsKey('geohash'), isFalse);
      expect(json['latitude'], isNull);
    });
  });

  group('EventsRemoteDataSource co-owner paths', () {
    test('getUserEvents includes events the user co-owns (deduped)', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('events').doc('e_co').set({
        ...EventFixtures.doc(organizerId: 'creator', startDate: DateTime(2030, 4)),
        'coOrganizerIds': ['u1'],
      });
      await EventFixtures.seedEvent(db,
          id: 'e_mine', organizerId: 'u1', startDate: DateTime(2030, 2));
      await EventFixtures.seedEvent(db,
          id: 'e_other', organizerId: 'x', startDate: DateTime(2030, 3));
      final ds = EventsRemoteDataSourceImpl(firestore: db);

      final events = await ds.getUserEvents('u1');

      expect(events.map((e) => e.id).toList(), ['e_mine', 'e_co']);
      expect(events.last.isOwner('u1'), isTrue);
    });

    test('a co-owner can edit and boost, never change ownership or co-owners',
        () async {
      final db = FakeFirebaseFirestore();
      await db.collection('events').doc('e1').set({
        ...EventFixtures.doc(organizerId: 'creator', startDate: DateTime(2030)),
        'coOrganizerIds': ['co1'],
        'isFeatured': false,
      });
      final ds =
          EventsRemoteDataSourceImpl(firestore: db, currentUserId: () => 'co1');
      final loaded = (await ds.getEventById('e1'))!;
      // Co-owner edits + boosts; a stale copy also has the co-owner list
      // emptied, which must NOT be written.
      await ds.updateEvent(loaded.copyWith(
        title: 'Edited by co-owner',
        isFeatured: true,
        featuredUntil: DateTime(2031),
        coOrganizerIds: const [],
      ));
      final data = (await db.collection('events').doc('e1').get()).data()!;
      expect(data['title'], 'Edited by co-owner');
      expect(data['isFeatured'], isTrue);
      expect(data['coOrganizerIds'], ['co1']);
      expect(data['organizerId'], 'creator');
    });

    test('the creator can change the co-owner list', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('events').doc('e1').set({
        ...EventFixtures.doc(organizerId: 'creator', startDate: DateTime(2030)),
        'coOrganizerIds': ['co1'],
      });
      final ds = EventsRemoteDataSourceImpl(
          firestore: db, currentUserId: () => 'creator');
      final e = (await ds.getEventById('e1'))!;
      await ds.updateEvent(e.copyWith(coOrganizerIds: ['co1', 'co2']));
      final data = (await db.collection('events').doc('e1').get()).data()!;
      expect(data['coOrganizerIds'], ['co1', 'co2']);
    });

    test('an edit that loses coordinates removes the stale geohash', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('events').doc('e1').set({
        ...EventFixtures.doc(organizerId: 'creator', startDate: DateTime(2030)),
        'latitude': 41.9,
        'longitude': 12.5,
        'geohash': 'sr2yk',
      });
      final ds = EventsRemoteDataSourceImpl(
          firestore: db, currentUserId: () => 'creator');
      final e = (await ds.getEventById('e1'))!;
      await ds.updateEvent(
          e.copyWith(locationName: 'Typed place', clearCoordinates: true));
      final data = (await db.collection('events').doc('e1').get()).data()!;
      expect(data.containsKey('geohash'), isFalse);
      expect(data['latitude'], isNull);
      expect(data['locationName'], 'Typed place');
    });
  });
}
