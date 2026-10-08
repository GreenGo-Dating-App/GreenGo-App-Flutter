import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:greengo_chat/features/experience_bookings/domain/booking_rules.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/experience_bookings/domain/repositories/bookings_repository.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/screens/experience_slots_screen.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// "Dates & availability" → Repeat: the switch in the Add-date sheet and the
/// "Repeat this date" menu both create one slot per chosen day in the range.
void main() {
  late _Repo repo;

  setUp(() {
    repo = _Repo();
    GetIt.I.registerSingleton<BookingsRepository>(repo);
  });
  tearDown(() => GetIt.I.reset());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ExperienceSlotsScreen(
          experience: _experience, currentUserId: 'host'),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const ValueKey('slot-save')));
    await tester.tap(find.byKey(const ValueKey('slot-save')));
    await tester.pumpAndSettle();
  }

  testWidgets('Add date → Repeat → Every day creates 28 dates', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('slot-add')));
    await tester.pumpAndSettle();

    // Single-date mode first: the date field, no range.
    expect(find.byKey(const ValueKey('slot-date')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('slot-repeat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slot-date')), findsNothing);
    expect(find.byKey(const ValueKey('slot-repeat-range')), findsOneWidget);

    // Default: 4 weeks from tomorrow, on tomorrow's weekday.
    expect(find.text('4 dates will be added'), findsOneWidget);
    await tester.tap(find.text('Every day'));
    await tester.pumpAndSettle();
    expect(find.text('28 dates will be added'), findsOneWidget);
    expect(find.text('Add 28 dates'), findsOneWidget);

    await save(tester);
    expect(repo.created.length, 28);
    expect(find.text('28 dates added'), findsOneWidget);
  });

  testWidgets('no weekday chosen blocks the save', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('slot-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slot-repeat')));
    await tester.pumpAndSettle();
    final wd = DateTime.now().add(const Duration(days: 1)).weekday;
    await tester.tap(find.byKey(ValueKey('slot-repeat-day-$wd')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No dates match'), findsOneWidget);
    await save(tester);
    expect(repo.created, isEmpty);
    expect(find.byKey(const ValueKey('slot-repeat-range')), findsOneWidget);
  });

  testWidgets('"Repeat this date" repeats weekly from the next day',
      (tester) async {
    final start = DateTime.now().add(const Duration(days: 3));
    final day = DateTime(start.year, start.month, start.day, 18, 30);
    repo.existing = [
      ExperienceSlot(
        id: 's1',
        experienceId: 'e1',
        start: day,
        end: day.add(const Duration(hours: 2)),
        capacity: 7,
      ),
    ];
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('slot-menu-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repeat this date'));
    await tester.pumpAndSettle();

    expect(find.text('4 dates will be added'), findsOneWidget);
    await save(tester);
    expect(repo.created.length, 4);
    for (var i = 0; i < 4; i++) {
      final d = repo.created[i];
      expect(d.start,
          DateTime(day.year, day.month, day.day + 7 * (i + 1), 18, 30));
      expect(d.end.difference(d.start), const Duration(hours: 2));
      // Private time slots: seats no longer limit a window.
      expect(d.capacity, BookingConfig.slotCapacityMax);
    }
  });
}

const _experience = UserExperience(
  id: 'e1',
  hostId: 'host',
  title: 'Street food walk',
  description: 'dddddddddddddddddddddddddddddddddddddddd',
  category: ExperienceCategory.foodDrink,
  mainPhotoUrl: 'https://a/b.jpg',
  included: ['Snacks'],
  locationName: 'São Paulo',
  durationMinutes: 120,
  languages: ['English'],
  maxGroupSize: 6,
  isFree: true,
  price: 0,
  status: ExperienceStatus.published,
);

class _Repo extends Fake implements BookingsRepository {
  List<ExperienceSlot> existing = const [];
  final List<SlotDraft> created = [];

  @override
  Future<Either<Failure, List<ExperienceSlot>>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  }) async =>
      Right(existing);

  @override
  Future<Either<Failure, List<ExperienceSlot>>> createSlots(
    String experienceId,
    List<SlotDraft> drafts,
  ) async {
    created.addAll(drafts);
    return Right([
      for (var i = 0; i < drafts.length; i++)
        ExperienceSlot(
          id: 'new$i',
          experienceId: experienceId,
          start: drafts[i].start,
          end: drafts[i].end,
          capacity: drafts[i].capacity,
        ),
    ]);
  }
}
