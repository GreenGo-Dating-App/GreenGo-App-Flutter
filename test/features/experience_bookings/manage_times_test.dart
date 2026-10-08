import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/experience_bookings/data/datasources/experience_availability_service.dart';
import 'package:greengo_chat/features/experience_bookings/domain/availability_rules.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/screens/manage_times_screen.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/widgets/recurring_time_picker.dart';
import 'package:greengo_chat/features/ticket_payments/domain/ticket_payments.dart';
import 'package:greengo_chat/features/ticket_payments/presentation/screens/ticket_types_screen.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

class _FakeAvail extends ExperienceAvailabilityService {
  _FakeAvail({this.affected = 0});
  final int affected;
  final saves = <bool>[];
  AvailabilityOverrides? lastOverrides;
  AvailabilityRules? lastRules;

  @override
  Future<AvailabilitySaveResult> save(String experienceId, AvailabilityRules rules, AvailabilityOverrides overrides,
      {bool confirm = false}) async {
    saves.add(confirm);
    lastRules = rules;
    lastOverrides = overrides;
    if (affected > 0 && !confirm) return AvailabilitySaveResult(needsConfirm: true, affected: affected);
    return AvailabilitySaveResult(needsConfirm: false, affected: affected, cancelled: confirm ? affected : 0);
  }
}

const _rules = AvailabilityRules(
  timezone: 'America/Sao_Paulo',
  windowStart: '09:00',
  windowEnd: '20:00',
  durationMinutes: 120,
  weekdays: [1, 2, 3, 4, 5, 6, 7],
  capacityPerSlot: 4,
);

void main() {
  group('availability generation (mirror of the server)', () {
    test('last slot must fit; start every; buffer', () {
      expect(dayTimes(_rules, '2026-10-12'), ['09:00', '11:00', '13:00', '15:00', '17:00']);
      expect(dayTimes(_rules.copyWith(startEveryMinutes: 60), '2026-10-12').length, 10);
      expect(dayTimes(_rules.copyWith(bufferMinutes: 30), '2026-10-12'), ['09:00', '11:30', '14:00', '16:30']);
      expect(_rules.copyWith(startEveryMinutes: 60).error, 'overlapping_slots');
    });
    test('precedence: closed > explicit slots > window change > generated - removed + added', () {
      var o = const AvailabilityOverrides();
      o = setDay(o, '2026-10-13', const DayOverride(slots: ['10:00', '14:00']));
      o = setDay(o, '2026-10-14', const DayOverride(windowStart: '12:00', windowEnd: '16:00'));
      o = closeRange(o, '2026-10-12', '2026-10-12');
      o = removeTime(o, '2026-10-15', '11:00');
      o = addTime(o, '2026-10-15', '19:30');
      o = addTime(o, '2026-10-12', '19:00');
      expect(effectiveDayTimes(_rules, o, '2026-10-12'), isEmpty);
      expect(effectiveDayTimes(_rules, o, '2026-10-13'), ['10:00', '14:00']);
      expect(effectiveDayTimes(_rules, o, '2026-10-14'), ['12:00', '14:00']);
      expect(effectiveDayTimes(_rules, o, '2026-10-15'), ['09:00', '13:00', '15:00', '17:00', '19:30']);
    });
    test('add time validates fit + overlap; bulk ops; copy day; reset', () {
      const o = AvailabilityOverrides();
      expect(addTimeError(_rules, o, '2026-10-12', '10:00'), 'overlaps');
      expect(addTimeError(_rules, o, '2026-10-12', '09:00'), 'exists');
      expect(addTimeError(_rules, o, '2026-10-12', '23:00'), 'does_not_fit');
      expect(addTimeError(_rules, o, '2026-10-12', '19:00'), isNull);
      final mondays = removeTimeOnWeekday(_rules, o, 1, '09:00', '2026-10-01', '2026-10-31');
      expect(mondays.removedSlots, containsAll(['2026-10-05T09:00', '2026-10-12T09:00', '2026-10-19T09:00', '2026-10-26T09:00']));
      expect(mondays.removedSlots.length, 4);
      var c = setDay(o, '2026-10-12', const DayOverride(slots: ['10:00'], priceOverride: 90));
      c = copyDay(_rules, c, '2026-10-12', ['2026-10-19']);
      expect(effectiveDayTimes(_rules, c, '2026-10-19'), ['10:00']);
      expect(c.dayOverrides['2026-10-19']!.priceOverride, 90);
      expect(c.hasOverride('2026-10-19'), isTrue);
      expect(resetDay(c, '2026-10-19').hasOverride('2026-10-19'), isFalse);
      expect(isWeekendDay('2026-10-17', const [6, 7]), isTrue);
      expect(isWeekendDay('2026-10-16', const [6, 7]), isFalse);
      expect(defaultTimeZone(const Duration(hours: -3)), isNotEmpty);
    });
  });

  group('ManageTimesScreen', () {
    testWidgets('live preview follows the setup; save asks to confirm when booked times disappear', (t) async {
      final svc = _FakeAvail(affected: 2);
      t.view.physicalSize = const Size(1200, 2600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(ManageTimesScreen(
        experienceId: 'x1',
        service: svc,
        initial: const HostSchedule(rules: _rules, overrides: AvailabilityOverrides(), weekendPrice: 70, currency: 'R\$'),
      )));
      await t.pumpAndSettle();
      for (final time in ['09:00', '11:00', '13:00', '15:00', '17:00']) {
        expect(find.descendant(of: find.byKey(const ValueKey('mt-preview')), matching: find.text(time)), findsOneWidget);
      }
      await t.tap(find.byKey(const ValueKey('mt-save')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('2 booked times'), findsOneWidget);
      await t.tap(find.text('Cancel those bookings'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(svc.saves, [false, true]);
      expect(find.textContaining('2 bookings cancelled'), findsOneWidget);
    });

    testWidgets('day editor: remove a time, close the day', (t) async {
      final svc = _FakeAvail();
      t.view.physicalSize = const Size(1200, 2600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      final key = dateKey(day);
      await t.pumpWidget(_app(ManageTimesScreen(
        experienceId: 'x1',
        service: svc,
        initial: const HostSchedule(rules: _rules, overrides: AvailabilityOverrides()),
      )));
      await t.pumpAndSettle();
      if (day.month != now.month) {
        await t.tap(find.byIcon(Icons.chevron_right));
        await t.pumpAndSettle();
      }
      await t.ensureVisible(find.byKey(ValueKey('mt-day-$key')));
      await t.tap(find.byKey(ValueKey('mt-day-$key')));
      await t.pumpAndSettle();
      await t.tap(find.descendant(of: find.byKey(const ValueKey('mt-time-11:00')), matching: find.byTooltip('Remove time')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('mt-time-11:00')), findsNothing);
      await t.tap(find.byKey(const ValueKey('mt-day-done')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('mt-save')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(svc.lastOverrides!.removedSlots, contains('${key}T11:00'));
    });
  });

  group('RecurringTimePicker', () {
    UserExperience exp({bool group = false}) => UserExperience(
          id: 'x1', hostId: 'h', title: 'Walk', description: 'd' * 40, category: ExperienceCategory.other,
          mainPhotoUrl: '', included: const ['a'], locationName: 'Lapa', durationMinutes: 120,
          languages: const ['English'], maxGroupSize: 8, price: 50, currency: 'R\$',
          pricingMode: group ? 'per_group' : 'per_person', hasRecurringAvailability: true,
        );
    AvailableTime slot(String date, String time, int left, int amount, {String rule = 'base'}) {
      final p = parseDateKey(date);
      final h = int.parse(time.split(':')[0]);
      return AvailableTime(
        key: '${date}T$time', date: date, time: time, remaining: left, unitAmount: amount, currency: 'brl', priceRule: rule,
        start: DateTime.utc(p.year, p.month, p.day, h + 3), end: DateTime.utc(p.year, p.month, p.day, h + 5),
      );
    }

    testWidgets('only bookable days; times show seats left and the date price; picking reports the time', (t) async {
      final now = DateTime.now().add(const Duration(days: 2));
      final d1 = dateKey(now);
      AvailableTime? picked;
      await t.pumpWidget(_app(Scaffold(
        body: SingleChildScrollView(
          child: RecurringTimePicker(
            experience: exp(),
            onPicked: (x) => picked = x,
            initialPage: AvailabilityPage(timezone: 'America/Sao_Paulo', times: [
              slot(d1, '10:00', 3, 9000, rule: 'day'),
              slot(d1, '12:00', 1, 5000),
            ]),
          ),
        ),
      )));
      await t.pumpAndSettle();
      expect(find.textContaining('10:00 – 3 seats left'), findsOneWidget);
      expect(find.textContaining('12:00 – 1 seat left'), findsOneWidget);
      expect(find.text('special price'), findsOneWidget);
      expect(find.textContaining('America/Sao_Paulo'), findsOneWidget);
      await t.tap(find.byKey(ValueKey('recurring-time-${d1}T12:00')));
      expect(picked!.time, '12:00');
      final cal = t.widget<CalendarDatePicker>(find.byKey(const ValueKey('recurring-calendar')));
      expect(cal.selectableDayPredicate!(DateTime(now.year, now.month, now.day)), isTrue);
      final other = now.add(const Duration(days: 1));
      expect(cal.selectableDayPredicate!(DateTime(other.year, other.month, other.day)), isFalse);
    });
  });

  testWidgets('ticket types sales summary totals', (t) async {
    await t.pumpWidget(_app(const Scaffold(
      body: TicketTypesSummary(currency: 'brl', types: [
        TicketType(id: 'ga', name: 'General', price: 2000, sold: 3, held: 1, quantity: 10),
        TicketType(id: 'vip', name: 'VIP', price: 8000, sold: 1),
      ]),
    )));
    await t.pumpAndSettle();
    expect(find.textContaining('3 sold · 1 reserved · 6 left'), findsOneWidget);
    expect((t.widget(find.byKey(const ValueKey('ticket-types-revenue'))) as Text).data, contains('140'));
  });
}
