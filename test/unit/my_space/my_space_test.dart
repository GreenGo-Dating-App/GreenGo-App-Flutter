import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/qr_checkin_service.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/my_space/data/my_space_repository.dart';
import 'package:greengo_chat/features/my_space/domain/my_space_models.dart';
import 'package:greengo_chat/features/my_space/presentation/bloc/my_space_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/events_fixtures.dart';
import '../../support/my_space_fixtures.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

void main() {
  group('MySpaceRules', () {
    final now = DateTime(2030, 1, 10, 12);

    test('check-in day: starts today, or the door window is open', () {
      expect(
          MySpaceRules.isCheckInDay(
              DateTime(2030, 1, 10, 22), DateTime(2030, 1, 10, 23), now),
          isTrue);
      // Started yesterday evening, ended at 02:00: still inside +12 h.
      expect(
          MySpaceRules.isCheckInDay(
              DateTime(2030, 1, 9, 22), DateTime(2030, 1, 10, 2), now),
          isTrue);
      expect(
          MySpaceRules.isCheckInDay(
              DateTime(2030, 1, 12, 18), DateTime(2030, 1, 12, 20), now),
          isFalse);
      // Starts in 2 h tomorrow-morning edge: 3 h early window.
      expect(
          MySpaceRules.isCheckInDay(DateTime(2030, 1, 11, 0, 30),
              DateTime(2030, 1, 11, 3), DateTime(2030, 1, 10, 22)),
          isTrue);
    });

    test('hosting = creator or co-owner, door not closed; attending = going',
        () {
      final mine = EventFixtures.build(
          id: 'mine', organizerId: 'me', startDate: DateTime(2030, 1, 11, 18));
      final co = EventFixtures.build(
              id: 'co', organizerId: 'x', startDate: DateTime(2030, 1, 10, 19))
          .copyWith(coOrganizerIds: ['me']);
      final old = EventFixtures.build(
          id: 'old',
          organizerId: 'me',
          startDate: DateTime(2030, 1, 1, 18),
          endDate: DateTime(2030, 1, 1, 20));
      final going = EventFixtures.build(
          id: 'going',
          organizerId: 'x',
          startDate: DateTime(2030, 1, 15, 18),
          attendees: [testAttendee('going', 'me')]);
      final interested = EventFixtures.build(
          id: 'int',
          organizerId: 'x',
          startDate: DateTime(2030, 1, 15, 18),
          attendees: [
            testAttendee('int', 'me', status: RSVPStatus.interested)
          ]);
      final all = [mine, co, old, going, interested];
      expect(MySpaceRules.hosting(all, 'me', now).map((e) => e.id),
          ['co', 'mine']);
      expect(
          MySpaceRules.attending(all, 'me', now).map((e) => e.id), ['going']);
    });
  });

  group('MySpaceCubit', () {
    test('loads counts, events and sessions independently', () async {
      final repo = FakeMySpaceRepository(
        requests: 2,
        payments: 1,
        guestUpcoming: 4,
        hostUpcoming: 3,
        events: [
          EventFixtures.build(
              id: 'h', organizerId: 'me', startDate: DateTime(2030, 1, 10, 19)),
        ],
        hostBookings: [
          testBooking(id: 'b1', start: DateTime(2030, 1, 10, 18)),
          testBooking(id: 'b2', start: DateTime(2030, 1, 12, 18)),
        ],
      );
      final cubit = MySpaceCubit(
          repository: repo, uid: 'me', clock: () => DateTime(2030, 1, 10, 9));
      await cubit.load();
      final s = cubit.state;
      expect(
          s.counts,
          const MySpaceCounts(
              bookingRequestsToConfirm: 2,
              paymentsToConfirm: 1,
              guestUpcomingBookings: 4,
              hostUpcomingBookings: 3));
      expect(s.hosting.map((e) => e.id), ['h']);
      expect(s.sessions, hasLength(2));
      // Today's door: the hosted event + the 18:00 session.
      expect(s.todayCheckIns(DateTime(2030, 1, 10, 9)), hasLength(2));
      cubit.selectSection(MySpaceSection.experiences);
      expect(cubit.state.section, MySpaceSection.experiences);
      await cubit.close();
    });

    test('a failing source never blanks the others', () async {
      final repo = FakeMySpaceRepository(requests: 5, failEvents: true);
      final cubit = MySpaceCubit(repository: repo, uid: 'me');
      await cubit.load();
      expect(cubit.state.eventsFailed, isTrue);
      expect(cubit.state.eventsLoad, MySpaceLoad.ready);
      expect(cubit.state.counts.bookingRequestsToConfirm, 5);
      expect(cubit.state.sessionsFailed, isFalse);
      await cubit.close();
    });
  });

  group('FirestoreMySpaceRepository (fake Firestore)', () {
    late FakeFirebaseFirestore db;
    late FirestoreMySpaceRepository repo;
    final soon = DateTime.now().add(const Duration(days: 2));

    Future<void> booking(String id, Map<String, Object?> data) =>
        db.collection('bookings').doc(id).set({
          'experienceId': 'x1',
          'slotId': 's1',
          'guests': 1,
          'slotStart': Timestamp.fromDate(soon),
          'slotEnd': Timestamp.fromDate(soon.add(const Duration(hours: 2))),
          ...data,
        });

    setUp(() async {
      db = FakeFirebaseFirestore();
      repo = FirestoreMySpaceRepository(
        firestore: db,
        checkin: QrCheckinService(functions: _MockFunctions()),
      );
      await booking(
          'r1', {'hostId': 'me', 'guestId': 'g', 'status': 'requested'});
      await booking(
          'r2', {'hostId': 'me', 'guestId': 'g', 'status': 'requested'});
      await booking(
          'c1', {'hostId': 'me', 'guestId': 'g', 'status': 'confirmed'});
      await booking(
          'x', {'hostId': 'other', 'guestId': 'me', 'status': 'confirmed'});
      await booking(
          'y', {'hostId': 'other', 'guestId': 'me', 'status': 'requested'});
      await booking(
          'z', {'hostId': 'other', 'guestId': 'me', 'status': 'declined'});
      await booking('old', {
        'hostId': 'me',
        'guestId': 'g',
        'status': 'confirmed',
        'slotStart': Timestamp.fromDate(DateTime(2020)),
      });
      for (final s in [
        'awaiting_confirmation',
        'awaiting_confirmation',
        'paid'
      ]) {
        await db
            .collection('ticket_orders')
            .add({'organizerId': 'me', 'status': s});
      }
      final att = db.collection('events').doc('e1').collection('attendees');
      await att
          .doc('a')
          .set({'userId': 'a', 'status': 'going', 'checkedIn': true});
      await att.doc('b').set({'userId': 'b', 'status': 'going'});
      await att.doc('c').set({'userId': 'c', 'status': 'going'});
      await att.doc('d').set({'userId': 'd', 'status': 'interested'});
    });

    test('count() badges', () async {
      expect(await repo.bookingRequestsToConfirm('me'), 2);
      expect(await repo.paymentsToConfirm('me'), 2);
      expect(await repo.upcomingBookings('me', BookingRole.guest), 2);
      expect(await repo.upcomingBookings('me', BookingRole.host), 1);
    });

    test('event check-in stats and the paginated going roster', () async {
      expect(await repo.eventCheckInStats('e1'),
          const EventCheckInStats(going: 3, checkedIn: 1));
      final p1 = await repo.goingAttendees('e1', limit: 2);
      expect(p1.items.map((a) => a.userId), ['a', 'b']);
      expect(p1.hasMore, isTrue);
      // (startAfter on the document id is not supported by
      // fake_cloud_firestore; the same cursor pattern as
      // EventsRemoteDataSource.getAttendeesPage is used.)
      final all = await repo.goingAttendees('e1');
      expect(all.items.map((a) => a.userId), ['a', 'b', 'c']);
      expect(all.hasMore, isFalse);
    });

    test('host sessions: upcoming confirmed only; one session by start',
        () async {
      final up = await repo.hostUpcomingConfirmed('me');
      expect(up.map((b) => b.id), ['c1']);
      final session = await repo.sessionBookings(
          hostId: 'me', experienceId: 'x1', slotStart: soon);
      // Requests are not on a check-in list.
      expect(session.map((b) => b.id), ['c1']);
    });
  });
}
