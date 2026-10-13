import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/constants/app_colors.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/my_space/data/my_space_repository.dart';
import 'package:greengo_chat/features/my_space/domain/my_space_calendar.dart';
import 'package:greengo_chat/features/my_space/presentation/bloc/my_space_calendar_cubit.dart';
import 'package:greengo_chat/features/my_space/presentation/widgets/my_space_calendar_widgets.dart';
import 'package:greengo_chat/generated/app_localizations_en.dart';

import '../../support/events_fixtures.dart';
import '../../support/my_space_fixtures.dart';

void main() {
  const me = 'me';
  final l = AppLocalizationsEn();

  group('events calendar', () {
    final hosted = EventFixtures.build(
        id: 'h', organizerId: me, startDate: DateTime(2030, 1, 3, 20));
    final coOwned = EventFixtures.build(
            id: 'co', organizerId: 'x', startDate: DateTime(2030, 1, 2, 20))
        .copyWith(coOrganizerIds: [me]);
    final going = EventFixtures.build(
        id: 'g',
        organizerId: 'x',
        startDate: DateTime(2030, 1, 5, 19),
        attendees: [testAttendee('g', me)]);
    final maybe = EventFixtures.build(
        id: 'm',
        organizerId: 'x',
        attendees: [testAttendee('m', me, status: RSVPStatus.interested)]);
    final past = EventFixtures.build(
        id: 'p', organizerId: me, startDate: DateTime(2020, 5, 1, 20));
    final all = [hosted, coOwned, going, maybe, past, hosted];

    test('roles: owner / co-owner host, going attendee goes, else nothing',
        () {
      expect(MySpaceCalendar.eventRole(hosted, me), MsCalendarRole.hosting);
      expect(MySpaceCalendar.eventRole(coOwned, me), MsCalendarRole.hosting);
      expect(MySpaceCalendar.eventRole(going, me), MsCalendarRole.going);
      expect(MySpaceCalendar.eventRole(maybe, me), isNull);
    });

    test('an owner who also RSVPd is hosting, not going', () {
      final both = EventFixtures.build(
          id: 'b', organizerId: me, attendees: [testAttendee('b', me)]);
      expect(MySpaceCalendar.eventRole(both, me), MsCalendarRole.hosting);
    });

    test('All keeps every event incl. past ones, deduped, sorted', () {
      final r = MySpaceCalendar.events(all, me, MsCalendarFilter.all);
      expect(r.map((x) => x.event.id), ['p', 'co', 'h', 'g']);
    });

    test('I host / I\'m going split', () {
      expect(
          MySpaceCalendar.events(all, me, MsCalendarFilter.hosting)
              .map((x) => x.event.id),
          ['p', 'co', 'h']);
      expect(
          MySpaceCalendar.events(all, me, MsCalendarFilter.going)
              .map((x) => x.event.id),
          ['g']);
    });

    test('image: cover, else first gallery photo, else none', () {
      expect(
          MySpaceCalendar.eventImage(
              hosted.copyWith(imageUrl: 'cover', photoUrls: ['p1'])),
          'cover');
      expect(
          MySpaceCalendar.eventImage(
              hosted.copyWith(imageUrl: ' ', photoUrls: ['', 'p1', 'p2'])),
          'p1');
      expect(MySpaceCalendar.eventImage(hosted), isNull);
    });

    test('item mapping: gold hosting / blue going, tag + location', () {
      final r = MySpaceCalendar.events(
          [hosted.copyWith(imageUrl: 'img'), going], me, MsCalendarFilter.all);
      final h = MsCalendarItems.event(l, r[0]);
      final g = MsCalendarItems.event(l, r[1]);
      expect(h.color, AppColors.richGold);
      expect(h.subtitle, 'Hosting · Somewhere');
      expect(h.imageUrl, 'img');
      expect(h.payload, r[0]);
      expect(g.color, AppColors.infoBlue);
      expect(g.subtitle, 'Going · Somewhere');
      expect(g.imageUrl, isNull);
      expect(g.start, going.startDate);
    });
  });

  group('experiences calendar', () {
    final t = DateTime(2030, 1, 2, 18);
    final bookings = [
      // Hosting: one session (x1 @ t) = confirmed + requested + cancelled.
      testBooking(id: 'h1', guestId: 'a', guests: 2, start: t),
      testBooking(
          id: 'h2', guestId: 'b', start: t, status: BookingStatus.requested),
      testBooking(
          id: 'h3',
          guestId: 'c',
          start: t,
          status: BookingStatus.cancelledByGuest),
      // Hosting: a request-only session.
      testBooking(
          id: 'h4',
          experienceId: 'x2',
          guestId: 'd',
          start: t.add(const Duration(days: 1)),
          status: BookingStatus.requested),
      // Hosting: declined / expired never show.
      testBooking(
          id: 'h5',
          experienceId: 'x3',
          start: t,
          status: BookingStatus.declined),
      testBooking(
          id: 'h6', experienceId: 'x3', start: t, status: BookingStatus.expired),
      // Going.
      testBooking(
          id: 'g1',
          experienceId: 'y1',
          hostId: 'host',
          guestId: me,
          start: t.add(const Duration(days: 2)),
          title: 'Pottery'),
      testBooking(
          id: 'g2',
          experienceId: 'y2',
          hostId: 'host',
          guestId: me,
          start: t.add(const Duration(days: 3)),
          status: BookingStatus.requested),
      testBooking(
          id: 'g3',
          experienceId: 'y3',
          hostId: 'host',
          guestId: me,
          start: t,
          status: BookingStatus.cancelledByHost),
      testBooking(
          id: 'g4',
          experienceId: 'y4',
          hostId: 'host',
          guestId: me,
          start: t,
          status: BookingStatus.noShow),
    ];

    test('host sessions grouped (requests included), cancelled excluded', () {
      final r = MySpaceCalendar.experiences(
          bookings, me, MsCalendarFilter.hosting);
      expect(r, hasLength(2));
      final s = r.first;
      expect(s.role, MsCalendarRole.hosting);
      expect(s.bookings.map((b) => b.id), unorderedEquals(['h1', 'h2']));
      expect(s.guests, 3);
      expect(s.onlyRequested, isFalse);
      // The check-in session holds only the accepted booking.
      expect(s.checkInSession!.bookings.map((b) => b.id), ['h1']);
      final req = r.last;
      expect(req.experienceId, 'x2');
      expect(req.onlyRequested, isTrue);
      expect(req.checkInSession, isNull);
    });

    test('going = requested + confirmed + completed own bookings', () {
      final r =
          MySpaceCalendar.experiences(bookings, me, MsCalendarFilter.going);
      expect(r.map((x) => x.bookings.single.id), ['g1', 'g2']);
      expect(r.every((x) => x.role == MsCalendarRole.going), isTrue);
      expect(r.first.checkInSession, isNull);
    });

    test('All = both, soonest first', () {
      final r = MySpaceCalendar.experiences(bookings, me, MsCalendarFilter.all);
      expect(r.map((x) => x.id), [
        'xh_x1_${t.millisecondsSinceEpoch}',
        'xh_x2_${t.add(const Duration(days: 1)).millisecondsSinceEpoch}',
        'xg_g1',
        'xg_g2',
      ]);
    });

    test('item mapping: photo, outlined requests, guests + status', () {
      final r = MySpaceCalendar.experiences(bookings, me, MsCalendarFilter.all);
      final session = MsCalendarItems.experience(l, r[0], 'photo');
      expect(session.imageUrl, 'photo');
      expect(session.filled, isTrue);
      expect(session.color, AppColors.richGold);
      expect(session.subtitle, 'Hosting · 3 guests');
      final request = MsCalendarItems.experience(l, r[1], null);
      expect(request.filled, isFalse);
      expect(request.subtitle, 'Hosting · 1 guest · Requested');
      final mine = MsCalendarItems.experience(l, r[2], null);
      expect(mine.color, AppColors.infoBlue);
      expect(mine.title, 'Pottery');
      expect(mine.subtitle, 'Going · 1 guest');
    });
  });

  test('experience photo: main photo, else first of the gallery', () {
    expect(
        FirestoreMySpaceRepository.firstExperiencePhoto(
            {'mainPhotoUrl': 'm', 'photoUrls': ['a']}),
        'm');
    expect(
        FirestoreMySpaceRepository.firstExperiencePhoto(
            {'mainPhotoUrl': '', 'photoUrls': ['', 'a']}),
        'a');
    expect(FirestoreMySpaceRepository.firstExperiencePhoto({}), isNull);
  });

  group('MySpaceCalendarCubit', () {
    final from = DateTime(2029, 12, 31);
    final to = DateTime(2030, 2, 4);

    FakeMySpaceRepository repo() => FakeMySpaceRepository(
          hostBookings: [
            testBooking(id: 'h1', start: DateTime(2030, 1, 2, 18)),
            testBooking(
                id: 'h2',
                experienceId: 'x9',
                start: DateTime(2030, 3, 2, 18)),
          ],
          guestBookings: [
            testBooking(
                id: 'g1',
                experienceId: 'y1',
                hostId: 'host',
                guestId: me,
                start: DateTime(2030, 1, 9, 10)),
          ],
          experiencePhotoUrls: {'x1': 'px1', 'y1': 'py1'},
        );

    test('loads only the visible range, once, plus photos once', () async {
      final r = repo();
      final c = MySpaceCalendarCubit(
          repository: r, uid: me, debounce: Duration.zero);
      addTearDown(c.close);
      c.rangeChanged(from, to);
      await pumpEventQueue();
      expect(c.state.bookings.keys, unorderedEquals(['h1', 'g1']));
      expect(c.state.loading, isFalse);
      expect(c.state.failed, isFalse);
      expect(c.state.photos, {'x1': 'px1', 'y1': 'py1'});
      expect(r.rangeCalls, hasLength(2));
      String call((List<String>, bool) c) => '${c.$1.join(',')}:${c.$2}';
      expect(r.photoCalls.map(call), ['x1:true', 'y1:false']);

      // Same range again: memoised, no query.
      c.rangeChanged(from, to);
      await pumpEventQueue();
      expect(r.rangeCalls, hasLength(2));

      // Another range: debounced load; photos of known ids not re-read.
      c.rangeChanged(DateTime(2030, 3, 1), DateTime(2030, 4, 1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await pumpEventQueue();
      expect(r.rangeCalls, hasLength(4));
      expect(c.state.bookings.keys, unorderedEquals(['h1', 'g1', 'h2']));
      expect(call(r.photoCalls.last), 'x9:true');
    });

    test('rapid range changes only load the last one', () async {
      final r = repo();
      final c = MySpaceCalendarCubit(
          repository: r,
          uid: me,
          debounce: const Duration(milliseconds: 20));
      addTearDown(c.close);
      c.rangeChanged(from, to);
      await pumpEventQueue();
      c.rangeChanged(DateTime(2030, 2, 1), DateTime(2030, 3, 1));
      c.rangeChanged(DateTime(2030, 3, 1), DateTime(2030, 4, 1));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await pumpEventQueue();
      expect(r.rangeCalls.map((x) => x.$2),
          [from, from, DateTime(2030, 3, 1), DateTime(2030, 3, 1)]);
    });

    test('a failing load flags failed, retry recovers', () async {
      final r = repo()..failCalendar = true;
      final c = MySpaceCalendarCubit(
          repository: r, uid: me, debounce: Duration.zero);
      addTearDown(c.close);
      c.rangeChanged(from, to);
      await pumpEventQueue();
      expect(c.state.failed, isTrue);
      expect(c.state.loading, isFalse);
      expect(c.state.bookings, isEmpty);
      r.failCalendar = false;
      await c.retry();
      await pumpEventQueue();
      expect(c.state.failed, isFalse);
      expect(c.state.bookings.keys, unorderedEquals(['h1', 'g1']));
    });

    test('refresh replaces the range: a cancelled booking updates', () async {
      final r = repo();
      final c = MySpaceCalendarCubit(
          repository: r, uid: me, debounce: Duration.zero);
      addTearDown(c.close);
      c.rangeChanged(from, to);
      await pumpEventQueue();
      r.hostBookings = [
        testBooking(
            id: 'h1',
            start: DateTime(2030, 1, 2, 18),
            status: BookingStatus.cancelledByHost),
      ];
      await c.refresh();
      expect(c.state.bookings['h1']!.status, BookingStatus.cancelledByHost);
      expect(
          MySpaceCalendar.experiences(
                  c.state.bookings.values, me, MsCalendarFilter.hosting)
              .isEmpty,
          isTrue);
    });

    test('filters are independent per calendar', () {
      final c = MySpaceCalendarCubit(repository: repo(), uid: me);
      addTearDown(c.close);
      c.setEventFilter(MsCalendarFilter.going);
      expect(c.state.eventFilter, MsCalendarFilter.going);
      expect(c.state.experienceFilter, MsCalendarFilter.all);
      c.setExperienceFilter(MsCalendarFilter.hosting);
      expect(c.state.experienceFilter, MsCalendarFilter.hosting);
    });
  });
}
