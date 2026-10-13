import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/widgets/gg_calendar.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/my_space/presentation/screens/my_space_screen.dart';

import '../../support/events_fixtures.dart';
import '../../support/my_space_fixtures.dart';

void main() {
  // A fixed "now": 2030-01-01 10:00; the calendars open on that day.
  final now = DateTime(2030, 1, 1, 10);
  DateTime clock() => now;

  final hosted = EventFixtures.build(
    id: 'e-host',
    organizerId: 'me',
    title: 'Language café',
    startDate: DateTime(2030, 1, 1, 19),
  );
  final going = EventFixtures.build(
    id: 'e-go',
    organizerId: 'someone',
    title: 'Board games night',
    startDate: DateTime(2030, 1, 1, 20),
    attendees: [testAttendee('e-go', 'me')],
  );
  final pastHosted = EventFixtures.build(
    id: 'e-past',
    organizerId: 'me',
    title: 'Old picnic',
    startDate: DateTime(2029, 12, 30, 12),
  );

  final sessionStart = DateTime(2030, 1, 1, 18);
  FakeMySpaceRepository repo({bool failCalendar = false}) =>
      FakeMySpaceRepository(
        events: [hosted, going, pastHosted],
        hostBookings: [
          testBooking(id: 'h1', start: sessionStart),
          testBooking(
              id: 'h2',
              guestId: 'g2',
              start: sessionStart,
              status: BookingStatus.requested),
          testBooking(
              id: 'h3',
              guestId: 'g3',
              start: sessionStart,
              status: BookingStatus.cancelledByGuest),
        ],
        guestBookings: [
          testBooking(
              id: 'g1',
              experienceId: 'y1',
              hostId: 'host',
              guestId: 'me',
              title: 'Pottery',
              start: DateTime(2030, 1, 1, 9)),
        ],
        failCalendar: failCalendar,
      );

  Future<void> pump(WidgetTester tester, FakeMySpaceRepository r,
      {double width = 400}) async {
    await pumpLocalized(
      tester,
      MySpaceScreen(currentUserId: 'me', repository: r, clock: clock),
      width: width,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openExperiences(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('ms-seg-experiences')));
    await tester.pumpAndSettle();
  }

  Finder key(String k) => find.byKey(ValueKey(k));
  final sessionId = 'xh_x1_${sessionStart.millisecondsSinceEpoch}';
  final sessionItem = 'cal-item-$sessionId';

  /// Ids of the items handed to a calendar.
  List<String> ids(WidgetTester tester, String grid) => [
        for (final i in tester.widget<GgCalendar>(key(grid)).items) i.id,
      ];

  testWidgets('Events tab: calendar with hosting + going, past included',
      (tester) async {
    await pump(tester, repo());
    expect(key('ms-cal-events'), findsOneWidget);
    expect(key('ms-cal-experiences'), findsNothing);
    expect(find.text('CALENDAR'), findsOneWidget);
    expect(find.text('I host'), findsOneWidget);
    expect(find.text("I'm going"), findsOneWidget);
    // Past events stay on the calendar, while the Hosting list below only
    // shows what is not over.
    expect(ids(tester, 'ms-cal-events-grid'),
        ['ev_e-past', 'ev_e-host', 'ev_e-go']);
    expect(key('ms-hosted-e-past'), findsNothing);
    // Today's agenda (rendered) with the role tags.
    expect(key('cal-item-ev_e-host'), findsOneWidget);
    expect(find.textContaining('Hosting · Somewhere'), findsOneWidget);
    // The lists below still work.
    expect(key('ms-hosted-e-host'), findsOneWidget);
    expect(key('ms-attending-e-go'), findsOneWidget);
  });

  testWidgets('Events tab: "I\'m going" / "I host" filters', (tester) async {
    await pump(tester, repo());
    const grid = 'ms-cal-events-grid';
    await tester.tap(key('ms-cal-filter-going'));
    await tester.pumpAndSettle();
    expect(ids(tester, grid), ['ev_e-go']);
    expect(key('cal-item-ev_e-host'), findsNothing);
    await tester.tap(key('ms-cal-filter-hosting'));
    await tester.pumpAndSettle();
    expect(ids(tester, grid), ['ev_e-past', 'ev_e-host']);
    await tester.tap(key('ms-cal-filter-all'));
    await tester.pumpAndSettle();
    expect(ids(tester, grid), ['ev_e-past', 'ev_e-host', 'ev_e-go']);
    // The colors of the two roles.
    final items = tester.widget<GgCalendar>(key(grid)).items;
    expect(items[1].color, isNot(items[2].color));
  });

  testWidgets('Experiences tab: own calendar loads only the visible range',
      (tester) async {
    final r = repo();
    await pump(tester, r);
    expect(r.rangeCalls, isEmpty); // nothing read until the tab is shown
    await openExperiences(tester);
    expect(key('ms-cal-experiences'), findsOneWidget);
    expect(key('ms-cal-events'), findsNothing);
    expect(r.rangeCalls.map((c) => c.$1), unorderedEquals(['host', 'guest']));
    for (final c in r.rangeCalls) {
      expect(c.$2.isAfter(now), isFalse);
      expect(c.$3.difference(c.$2).inDays, lessThanOrEqualTo(42));
    }
    // Hosted session (confirmed + request, cancelled left out) + my booking.
    const grid = 'ms-cal-experiences-grid';
    expect(ids(tester, grid), ['xg_g1', sessionId]);
    final session = tester
        .widget<GgCalendar>(key(grid))
        .items
        .singleWhere((i) => i.id == sessionId);
    expect(session.subtitle, 'Hosting · 2 guests');
    expect(session.filled, isTrue);
    expect(key('cal-item-xg_g1'), findsOneWidget);
    expect(find.textContaining('Going · 1 guest'), findsOneWidget);
    // The rest of the tab is still there.
    expect(key('ms-my-experiences'), findsOneWidget);

    await tester.tap(key('ms-cal-filter-hosting'));
    await tester.pumpAndSettle();
    expect(ids(tester, grid), [sessionId]);
    expect(key('cal-item-xg_g1'), findsNothing);
  });

  testWidgets('a failing calendar load never breaks the tab', (tester) async {
    await pump(tester, repo(failCalendar: true));
    await openExperiences(tester);
    expect(key('ms-cal-error'), findsOneWidget);
    expect(key('ms-cal-experiences'), findsOneWidget);
    expect(key('ms-my-experiences'), findsOneWidget);
    expect(key('my-bookings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full screen: same calendar + filters; long-press actions',
      (tester) async {
    await pump(tester, repo());
    await tester.tap(key('ms-cal-fullscreen'));
    await tester.pumpAndSettle();
    expect(key('ms-cal-fullscreen-page'), findsOneWidget);
    expect(key('ms-cal-events-grid-full'), findsOneWidget);
    expect(key('ms-cal-filter-hosting'), findsOneWidget);
    await tester.longPress(key('cal-item-ev_e-host'));
    await tester.pumpAndSettle();
    expect(key('ms-cal-sheet'), findsOneWidget);
    expect(find.text('Check-in'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('experiences full screen: session sheet lists its bookings',
      (tester) async {
    await pump(tester, repo());
    await openExperiences(tester);
    await tester.tap(key('ms-cal-fullscreen'));
    await tester.pumpAndSettle();
    expect(key('ms-cal-experiences-grid-full'), findsOneWidget);
    await tester.longPress(key(sessionItem));
    await tester.pumpAndSettle();
    expect(find.text('Check-in'), findsOneWidget);
    expect(find.text('Open booking'), findsNWidgets(2));
  });

  testWidgets('both calendars fit a 320 px phone', (tester) async {
    await pump(tester, repo(), width: 320);
    expect(tester.takeException(), isNull);
    await openExperiences(tester);
    expect(tester.takeException(), isNull);
  });
}
