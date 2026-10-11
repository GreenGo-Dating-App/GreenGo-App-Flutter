import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/my_space/domain/my_space_models.dart';
import 'package:greengo_chat/features/my_space/presentation/screens/event_check_in_checklist_screen.dart';
import 'package:greengo_chat/features/my_space/presentation/screens/session_check_in_checklist_screen.dart';

import '../../support/events_fixtures.dart';
import '../../support/my_space_fixtures.dart';

void main() {
  group('EventCheckInChecklistScreen', () {
    final event = EventFixtures.build(
        id: 'e1', organizerId: 'me', title: 'Language café');

    FakeMySpaceRepository repoWith() => FakeMySpaceRepository(attendees: {
          'e1': [
            testAttendee('e1', 'u1', name: 'Ana', checkedIn: true),
            testAttendee('e1', 'u2', name: 'Bruno', guests: 2),
            testAttendee('e1', 'u3', name: 'Carla'),
            testAttendee('e1', 'u4',
                name: 'Not going', status: RSVPStatus.interested),
          ],
        });

    Future<int> pump(WidgetTester tester, FakeMySpaceRepository repo) async {
      var scans = 0;
      await pumpLocalized(
        tester,
        EventCheckInChecklistScreen(
          event: event,
          currentUserId: 'me',
          repository: repo,
          openScanner: (_) async => scans++,
        ),
      );
      await tester.pumpAndSettle();
      return scans;
    }

    testWidgets('lists going attendees with ticks and the counts',
        (tester) async {
      await pump(tester, repoWith());
      expect(find.text('Language café'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Carla'), findsOneWidget);
      expect(find.text('Not going'), findsNothing);
      expect(find.text('+2 guests'), findsOneWidget);
      // Summary: 1 / 3.
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.byKey(const ValueKey('checklist-scan')), findsOneWidget);
      expect(tester.getSemantics(find.byKey(const ValueKey('check-u1'))),
          containsSemantics(isChecked: true));
    });

    testWidgets('search and filters narrow the list', (tester) async {
      await pump(tester, repoWith());
      await tester.enterText(
          find.byKey(const ValueKey('checklist-search')), 'bru');
      await tester.pumpAndSettle();
      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Ana'), findsNothing);
      await tester.enterText(
          find.byKey(const ValueKey('checklist-search')), '');
      await tester
          .tap(find.byKey(const ValueKey('checklist-filter-checkedIn')));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Carla'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('checklist-filter-pending')));
      await tester.pumpAndSettle();
      expect(find.text('Ana'), findsNothing);
      expect(find.text('Carla'), findsOneWidget);
    });

    testWidgets('manual check-in: confirm, server call, tick + counter',
        (tester) async {
      final repo = repoWith();
      await pump(tester, repo);
      await tester.tap(find.byKey(const ValueKey('check-u3')));
      await tester.pumpAndSettle();
      expect(find.text('Check in without a code?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('checklist-confirm')));
      await tester.pumpAndSettle();
      expect(repo.checkInCalls, [('e1', 'u3', true)]);
      expect(tester.getSemantics(find.byKey(const ValueKey('check-u3'))),
          containsSemantics(isChecked: true));
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('Carla checked in'), findsOneWidget);
    });

    testWidgets('undo asks first and calls the server with false',
        (tester) async {
      final repo = repoWith();
      await pump(tester, repo);
      await tester.tap(find.byKey(const ValueKey('check-u1')));
      await tester.pumpAndSettle();
      expect(find.text('Undo check-in?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('checklist-confirm')));
      await tester.pumpAndSettle();
      expect(repo.checkInCalls, [('e1', 'u1', false)]);
      expect(tester.getSemantics(find.byKey(const ValueKey('check-u1'))),
          containsSemantics(isChecked: false));
    });

    testWidgets('a server refusal reverts the optimistic tick', (tester) async {
      final repo = repoWith()..refuseCheckIn = 'outside_checkin_window';
      await pump(tester, repo);
      await tester.tap(find.byKey(const ValueKey('check-u2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checklist-confirm')));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(find.byKey(const ValueKey('check-u2'))),
          containsSemantics(isChecked: false));
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('cancel in the dialog changes nothing', (tester) async {
      final repo = repoWith();
      await pump(tester, repo);
      await tester.tap(find.byKey(const ValueKey('check-u3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.checkInCalls, isEmpty);
    });

    testWidgets('Scan opens the scanner preset to this event', (tester) async {
      var scans = 0;
      await pumpLocalized(
        tester,
        EventCheckInChecklistScreen(
          event: event,
          currentUserId: 'me',
          repository: repoWith(),
          openScanner: (_) async => scans++,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('checklist-scan')));
      await tester.pumpAndSettle();
      expect(scans, 1);
    });

    testWidgets('paginates: "Load more" fetches the next page', (tester) async {
      final repo = FakeMySpaceRepository(attendees: {
        'e1': [
          for (var i = 0; i < 60; i++)
            testAttendee('e1', 'u${i.toString().padLeft(2, '0')}',
                name: 'Guest $i'),
        ],
      });
      await pump(tester, repo);
      final list = find.byKey(const ValueKey('checklist-list'));
      await tester.dragUntilVisible(
          find.byKey(const ValueKey('checklist-more')),
          list,
          const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Guest 59'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('checklist-more')));
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
          find.text('Guest 59'), list, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('Guest 59'), findsOneWidget);
      expect(find.byKey(const ValueKey('checklist-more')), findsNothing);
    });

    testWidgets('empty roster', (tester) async {
      await pump(tester, FakeMySpaceRepository(attendees: {'e1': []}));
      expect(find.byKey(const ValueKey('checklist-empty')), findsOneWidget);
      expect(find.text('No one is going yet.'), findsOneWidget);
    });
  });

  group('SessionCheckInChecklistScreen', () {
    final start = DateTime(2030, 1, 1, 18);
    final b1 = testBooking(id: 'b1', guestId: 'g1', start: start, guests: 2);
    final b2 =
        testBooking(id: 'b2', guestId: 'g2', start: start, checkedInAt: start);

    Future<FakeMySpaceRepository> pump(WidgetTester tester) async {
      final repo = FakeMySpaceRepository(hostBookings: [b1, b2]);
      final session = CheckInSession.group([b1, b2]).single;
      await pumpLocalized(
        tester,
        SessionCheckInChecklistScreen(
          session: session,
          currentUserId: 'me',
          repository: repo,
          guestBuilder: (_, uid) => Text('guest:$uid'),
          openScanner: (_) async {},
        ),
      );
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('lists the session guests with their state', (tester) async {
      await pump(tester);
      expect(find.text('Cooking class'), findsOneWidget);
      expect(find.text('guest:g1'), findsOneWidget);
      expect(find.text('guest:g2'), findsOneWidget);
      expect(find.text('3 guests'), findsOneWidget); // summary subtitle
      expect(tester.getSemantics(find.byKey(const ValueKey('check-b2'))),
          containsSemantics(isChecked: true));
    });

    testWidgets('manual check-in through the host callable', (tester) async {
      final repo = await pump(tester);
      await tester.tap(find.byKey(const ValueKey('check-b1')));
      await tester.pumpAndSettle();
      expect(find.text('Check in without a code?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('checklist-confirm')));
      await tester.pumpAndSettle();
      expect(repo.manualBookingCalls, ['b1']);
      expect(tester.getSemantics(find.byKey(const ValueKey('check-b1'))),
          containsSemantics(isChecked: true));
    });

    testWidgets('a checked-in booking cannot be unticked', (tester) async {
      final repo = await pump(tester);
      final toggle =
          tester.widget<InkResponse>(find.byKey(const ValueKey('check-b2')));
      expect(toggle.onTap, isNull);
      expect(repo.manualBookingCalls, isEmpty);
    });

    test('grouping: same experience + start = one session', () {
      final other =
          testBooking(id: 'b3', start: start.add(const Duration(hours: 3)));
      final cancelled = testBooking(
          id: 'b4', start: start, status: BookingStatus.cancelledByGuest);
      final s = CheckInSession.group([other, b2, b1, cancelled]);
      expect(s.map((x) => x.bookings.map((b) => b.id).toList()).toList(), [
        ['b2', 'b1'],
        ['b3'],
      ]);
      expect(s.first.guests, 3);
      expect(s.first.checkedIn, 1);
      expect(s.first.progress, 0.5);
    });
  });
}
