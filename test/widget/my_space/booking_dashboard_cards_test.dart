import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/my_space/presentation/widgets/booking_dashboard_cards.dart';

import '../../support/my_space_fixtures.dart';

void main() {
  Future<List<(BookingRole, bool)>> pump(
    WidgetTester tester,
    FakeMySpaceRepository repo, {
    double width = 400,
  }) async {
    final opened = <(BookingRole, bool)>[];
    await pumpLocalized(
      tester,
      Scaffold(
        body: BookingDashboardCards(
          currentUserId: 'me',
          repository: repo,
          onOpen: (role, {toConfirm = false}) async =>
              opened.add((role, toConfirm)),
        ),
      ),
      width: width,
    );
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('guest card: live "N upcoming"; host card: "N upcoming"',
      (tester) async {
    await pump(
        tester, FakeMySpaceRepository(guestUpcoming: 2, hostUpcoming: 5));
    expect(find.byKey(const ValueKey('my-bookings')), findsOneWidget);
    expect(find.byKey(const ValueKey('host-bookings')), findsOneWidget);
    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Bookings received'), findsOneWidget);
    expect(find.text('2 upcoming'), findsOneWidget);
    expect(find.text('5 upcoming'), findsOneWidget);
  });

  testWidgets('host requests: "N to confirm" + a prominent badge',
      (tester) async {
    await pump(tester, FakeMySpaceRepository(requests: 3, hostUpcoming: 5));
    expect(find.text('3 to confirm'), findsOneWidget);
    // The count pill.
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('host-bookings')),
            matching: find.text('3')),
        findsOneWidget);
    expect(find.text('5 upcoming'), findsNothing);
  });

  testWidgets('no badge and "None upcoming" when all zero', (tester) async {
    await pump(tester, FakeMySpaceRepository());
    expect(find.text('None upcoming'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('taps open the right list (host opens on To confirm)',
      (tester) async {
    final opened = await pump(tester, FakeMySpaceRepository(requests: 1));
    await tester.tap(find.byKey(const ValueKey('my-bookings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('host-bookings')));
    await tester.pumpAndSettle();
    expect(opened, [(BookingRole.guest, false), (BookingRole.host, true)]);
  });

  testWidgets('counts refresh after the opened list closes', (tester) async {
    final repo = FakeMySpaceRepository(requests: 2);
    await pump(tester, repo);
    expect(find.text('2 to confirm'), findsOneWidget);
    repo.requests = 0;
    repo.hostUpcoming = 4;
    await tester.tap(find.byKey(const ValueKey('host-bookings')));
    await tester.pumpAndSettle();
    expect(find.text('4 upcoming'), findsOneWidget);
  });

  testWidgets('side by side on phones, stacked at very narrow widths',
      (tester) async {
    await pump(tester, FakeMySpaceRepository(), width: 400);
    var a = tester.getTopLeft(find.byKey(const ValueKey('my-bookings')));
    var b = tester.getTopLeft(find.byKey(const ValueKey('host-bookings')));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx));

    await pump(tester, FakeMySpaceRepository(requests: 7), width: 320);
    expect(tester.takeException(), isNull);
    a = tester.getTopLeft(find.byKey(const ValueKey('my-bookings')));
    b = tester.getTopLeft(find.byKey(const ValueKey('host-bookings')));
    expect(b.dy, greaterThan(a.dy));
    expect(tester.getSize(find.byKey(const ValueKey('host-bookings'))).height,
        greaterThanOrEqualTo(44));
  });
}
