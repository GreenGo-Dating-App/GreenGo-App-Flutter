import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/widgets/gg_calendar.dart';
import 'package:greengo_chat/features/experience_bookings/data/datasources/experience_availability_service.dart';
import 'package:greengo_chat/features/experience_bookings/domain/availability_rules.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/experience_bookings/domain/repositories/bookings_repository.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/widgets/experience_dates_calendar.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// "Dates & availability" calendar: bookings are shown and protected, open
/// recurring times can be edited in place and saved together.
void main() {
  final now = DateTime.now();
  // Two days ahead keeps every time in the future whatever the clock says.
  final day = DateTime(now.year, now.month, now.day + 2);
  final dayKey = dateKey(day);
  final rules = AvailabilityRules(
    timezone: defaultTimeZone(now.timeZoneOffset),
    windowStart: '09:00',
    windowEnd: '15:00',
    durationMinutes: 120,
    weekdays: const [1, 2, 3, 4, 5, 6, 7],
    dateFrom: dateKey(now),
  );

  late _Avail svc;
  late _Repo repo;

  setUp(() {
    svc = _Avail(rules);
    repo = _Repo([
      Booking(
        id: 'b1',
        experienceId: 'e1',
        slotId: 'r',
        hostId: 'host',
        guestId: 'g1',
        guests: 2,
        status: BookingStatus.confirmed,
        slotStart: DateTime(day.year, day.month, day.day, 9),
        slotEnd: DateTime(day.year, day.month, day.day, 11),
      ),
    ]);
  });

  Future<GlobalKey<ExperienceDatesCalendarState>> open(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.5;
    addTearDown(t.view.reset);
    final key = GlobalKey<ExperienceDatesCalendarState>();
    await t.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ExperienceDatesCalendar(
          key: key,
          experience: _experience,
          currentUserId: 'host',
          slots: const [],
          onAddSlot: (_) {},
          onSlotAction: (_, __) {},
          service: svc,
          repository: repo,
        ),
      ),
    ));
    await t.pumpAndSettle();
    return key;
  }

  Future<void> selectDay(WidgetTester t) async {
    // The day may sit in next month's grid: move there first if needed.
    final cell = find.byKey(ValueKey('cal-day-${day.year}-${day.month}-${day.day}'));
    if (cell.evaluate().isEmpty) {
      await t.tap(find.byKey(const ValueKey('cal-next')));
      await t.pumpAndSettle();
    }
    // A month grid can show the same date twice only across months; take the
    // first match.
    await t.tap(cell.first);
    // A cell also listens for double-taps: the tap lands after that window.
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
  }

  testWidgets('loads only the visible range and shows bookings + open times',
      (t) async {
    await open(t);
    expect(repo.ranges, isNotEmpty);
    await selectDay(t);
    // 09:00 is booked; 11:00 and 13:00 are still open.
    expect(find.byKey(const ValueKey('cal-item-b-b1')), findsOneWidget);
    expect(find.byKey(ValueKey('cal-item-r-${dayKey}T09:00')), findsNothing);
    expect(find.byKey(ValueKey('cal-item-r-${dayKey}T11:00')), findsOneWidget);
    expect(find.byKey(ValueKey('cal-item-r-${dayKey}T13:00')), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);
  });

  testWidgets('a booked appointment can be opened but never deleted',
      (t) async {
    await open(t);
    await selectDay(t);
    await t.longPress(find.byKey(const ValueKey('cal-item-b-b1')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('dc-locked-note')), findsOneWidget);
    expect(find.byKey(const ValueKey('dc-open-booking')), findsOneWidget);
    expect(find.byKey(const ValueKey('dc-remove-time')), findsNothing);
  });

  testWidgets('remove an open time, then save the schedule', (t) async {
    final cal = await open(t);
    await selectDay(t);
    await t.longPress(find.byKey(ValueKey('cal-item-r-${dayKey}T11:00')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('dc-remove-time')));
    await t.pumpAndSettle();
    expect(cal.currentState!.dirty, isTrue);
    expect(find.byKey(ValueKey('cal-item-r-${dayKey}T11:00')), findsNothing);
    await t.tap(find.byKey(const ValueKey('dc-save')));
    await t.pumpAndSettle();
    expect(svc.saved, hasLength(1));
    expect(svc.saved.single.removedSlots, contains('${dayKey}T11:00'));
    expect(cal.currentState!.dirty, isFalse);
  });

  testWidgets('a day with bookings cannot be closed', (t) async {
    final cal = await open(t);
    await selectDay(t);
    final cell = find.byKey(ValueKey('cal-day-${day.year}-${day.month}-${day.day}'));
    await t.longPress(cell.first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('dc-close-day')));
    await t.pumpAndSettle();
    expect(cal.currentState!.dirty, isFalse);
    expect(find.textContaining("can't be closed"), findsOneWidget);
  });

  testWidgets('day editor keeps booked times locked', (t) async {
    await open(t);
    await selectDay(t);
    final cell = find.byKey(ValueKey('cal-day-${day.year}-${day.month}-${day.day}'));
    await t.longPress(cell.first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('dc-edit-day')));
    await t.pumpAndSettle();
    final booked = find.byKey(const ValueKey('mt-time-09:00'));
    expect(booked, findsOneWidget);
    expect(find.descendant(of: booked, matching: find.byIcon(Icons.lock)),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('mt-time-11:00')),
            matching: find.byTooltip('Remove time')),
        findsOneWidget);
  });

  testWidgets('week and day views; double-tap a day opens it', (t) async {
    final cal = await open(t);
    await t.tap(find.byKey(const ValueKey('cal-view-week')));
    await t.pumpAndSettle();
    expect(cal.currentState!.dirty, isFalse);
    expect(find.byKey(const ValueKey('cal-grid')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cal-view-month')));
    await t.pumpAndSettle();
    final cell = find.byKey(ValueKey('cal-day-${day.year}-${day.month}-${day.day}'));
    if (cell.evaluate().isEmpty) {
      await t.tap(find.byKey(const ValueKey('cal-next')));
      await t.pumpAndSettle();
    }
    await t.tap(cell.first);
    await t.pump(const Duration(milliseconds: 50));
    await t.tap(cell.first);
    await t.pumpAndSettle();
    final state = t.state<GgCalendarState>(find.byType(GgCalendar));
    expect(state.view, GgCalendarView.day);
    expect(find.byKey(const ValueKey('cal-block-b-b1')), findsOneWidget);
  });
}

class _Avail extends ExperienceAvailabilityService {
  _Avail(this.rules);
  final AvailabilityRules rules;
  final saved = <AvailabilityOverrides>[];

  @override
  Future<HostSchedule> load(String experienceId) async =>
      HostSchedule(rules: rules, overrides: const AvailabilityOverrides());

  @override
  Future<AvailabilitySaveResult> save(String experienceId,
      AvailabilityRules rules, AvailabilityOverrides overrides,
      {bool confirm = false}) async {
    saved.add(overrides);
    return const AvailabilitySaveResult(needsConfirm: false, affected: 0);
  }
}

class _Repo extends Fake implements BookingsRepository {
  _Repo(this.items);
  final List<Booking> items;
  final ranges = <(DateTime, DateTime)>[];

  @override
  Future<Either<Failure, List<Booking>>> hostBookingsInRange({
    required String hostId,
    required String experienceId,
    required DateTime from,
    required DateTime to,
    int limit = 300,
  }) async {
    ranges.add((from, to));
    return Right([
      for (final b in items)
        if (!b.slotStart.isBefore(from) && b.slotStart.isBefore(to)) b,
    ]);
  }
}

const _experience = UserExperience(
  id: 'e1',
  hostId: 'host',
  title: 'Street food walk',
  description: 'dddddddddddddddddddddddddddddddddddddddd',
  category: ExperienceCategory.foodDrink,
  mainPhotoUrl: '',
  included: ['Snacks'],
  locationName: 'São Paulo',
  durationMinutes: 120,
  languages: ['English'],
  maxGroupSize: 6,
  isFree: true,
  price: 0,
  status: ExperienceStatus.published,
);
