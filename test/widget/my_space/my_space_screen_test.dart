import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/my_space/presentation/screens/my_space_screen.dart';
import 'package:greengo_chat/features/my_space/presentation/widgets/space_widgets.dart';

import '../../support/events_fixtures.dart';
import '../../support/my_space_fixtures.dart';

void main() {
  // A fixed "now": 2030-01-01 10:00 (morning).
  final now = DateTime(2030, 1, 1, 10);
  DateTime clock() => now;

  Future<void> pump(WidgetTester tester, FakeMySpaceRepository repo,
      {double width = 400}) async {
    await pumpLocalized(
      tester,
      MySpaceScreen(currentUserId: 'me', repository: repo, clock: clock),
      width: width,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('header: greeting + Scan tickets / My tickets tiles',
      (tester) async {
    await pump(tester, FakeMySpaceRepository());
    expect(find.text('My Space'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.byKey(const ValueKey('ms-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('ms-tickets')), findsOneWidget);
    expect(find.text('Scan tickets'), findsOneWidget);
    expect(find.text('My tickets'), findsOneWidget);
  });

  testWidgets('To do: "All done" when nothing needs attention', (tester) async {
    await pump(tester, FakeMySpaceRepository());
    expect(find.byKey(const ValueKey('todo-all-done')), findsOneWidget);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.byKey(const ValueKey('todo-requests')), findsNothing);
  });

  testWidgets('To do: aggregated items with counts (plural copy)',
      (tester) async {
    final today = EventFixtures.build(
      id: 'e-today',
      organizerId: 'me',
      title: 'Language café',
      startDate: DateTime(2030, 1, 1, 19),
      endDate: DateTime(2030, 1, 1, 22),
      attendeeCount: 3,
    );
    await pump(
        tester,
        FakeMySpaceRepository(
          requests: 2,
          payments: 1,
          guestUpcoming: 3,
          events: [today],
          attendees: {
            'e-today': [
              testAttendee('e-today', 'a', checkedIn: true),
              testAttendee('e-today', 'b'),
            ],
          },
        ));
    expect(find.byKey(const ValueKey('todo-all-done')), findsNothing);
    expect(find.text('2 booking requests to confirm'), findsOneWidget);
    expect(find.text('1 payment to confirm'), findsOneWidget);
    expect(
        find.text('Check guests in today: 1 event or session'), findsOneWidget);
    expect(find.text('3 upcoming bookings as a guest'), findsOneWidget);
    // Total badge on the card header: 2 + 1 + 1 actionable.
    expect(
        find.descendant(
            of: find.byType(SpaceCountBadge), matching: find.text('4')),
        findsOneWidget);
  });

  testWidgets('Events segment: hosting card with check-in progress',
      (tester) async {
    final hosted = EventFixtures.build(
      id: 'e1',
      organizerId: 'me',
      title: 'Rooftop samba',
      startDate: DateTime(2030, 1, 3, 20),
      attendeeCount: 3,
    );
    await pump(
        tester,
        FakeMySpaceRepository(events: [
          hosted
        ], attendees: {
          'e1': [
            testAttendee('e1', 'a', checkedIn: true),
            testAttendee('e1', 'b'),
            testAttendee('e1', 'c'),
          ],
        }));
    expect(find.byKey(const ValueKey('ms-hosted-e1')), findsOneWidget);
    expect(find.text('Rooftop samba'), findsOneWidget);
    expect(find.text('1 / 3 checked in'), findsOneWidget);
    expect(find.byKey(const ValueKey('ms-no-attending')), findsOneWidget);
  });

  testWidgets('Events segment: attending list shows events I am going to',
      (tester) async {
    final going = EventFixtures.build(
      id: 'e2',
      organizerId: 'someone',
      title: 'Board games night',
      startDate: DateTime(2030, 1, 5, 19),
      attendees: [testAttendee('e2', 'me')],
    );
    await pump(tester, FakeMySpaceRepository(events: [going]));
    expect(find.byKey(const ValueKey('ms-attending-e2')), findsOneWidget);
    expect(find.byKey(const ValueKey('ms-no-hosting')), findsOneWidget);
  });

  testWidgets('segmented control switches to Experiences (cards + sessions)',
      (tester) async {
    await pump(
        tester,
        FakeMySpaceRepository(requests: 1, hostBookings: [
          testBooking(id: 'b1', start: DateTime(2030, 1, 2, 18)),
          testBooking(
              id: 'b2',
              start: DateTime(2030, 1, 2, 18),
              guestId: 'g2',
              guests: 2,
              checkedInAt: DateTime(2030, 1, 2, 18, 2)),
        ]));
    expect(find.byKey(const ValueKey('my-bookings')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('ms-seg-experiences')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('my-bookings')), findsOneWidget);
    expect(find.byKey(const ValueKey('host-bookings')), findsOneWidget);
    expect(find.byKey(const ValueKey('ms-my-experiences')), findsOneWidget);
    // One session (same experience + start) with 2 bookings, 1 checked in.
    expect(find.textContaining('Cooking class'), findsOneWidget);
    expect(find.text('1 / 2 checked in'), findsOneWidget);
    expect(find.textContaining('3 guests'), findsOneWidget);
  });

  testWidgets('Experiences: empty sessions state', (tester) async {
    await pump(tester, FakeMySpaceRepository());
    await tester.tap(find.byKey(const ValueKey('ms-seg-experiences')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ms-no-sessions')), findsOneWidget);
  });

  testWidgets('a failing events load shows retry, the To do card still works',
      (tester) async {
    await pump(tester, FakeMySpaceRepository(failEvents: true, requests: 1));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('1 booking request to confirm'), findsOneWidget);
  });

  testWidgets('fits a 320 px wide phone without overflow', (tester) async {
    await pump(
        tester,
        FakeMySpaceRepository(
            requests: 12,
            payments: 3,
            guestUpcoming: 1,
            events: [
              EventFixtures.build(
                  id: 'e1',
                  organizerId: 'me',
                  title: 'A very long event title that keeps going and going',
                  startDate: DateTime(2030, 1, 1, 19)),
            ]),
        width: 320);
    expect(tester.takeException(), isNull);
    // Tiles stack vertically on narrow widths.
    final scan = tester.getTopLeft(find.byKey(const ValueKey('ms-scan')));
    final tickets = tester.getTopLeft(find.byKey(const ValueKey('ms-tickets')));
    expect(tickets.dy, greaterThan(scan.dy));
  });

  testWidgets('tap targets are at least 44 px', (tester) async {
    await pump(tester, FakeMySpaceRepository(requests: 1));
    for (final k in ['ms-seg-events', 'ms-seg-experiences', 'todo-requests']) {
      final size = tester.getSize(find.byKey(ValueKey(k)));
      expect(size.height, greaterThanOrEqualTo(44), reason: k);
    }
  });
}
