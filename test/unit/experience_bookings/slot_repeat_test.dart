import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/experience_bookings/domain/booking_rules.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/experience_bookings/domain/repositories/bookings_repository.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/bloc/slots_bloc.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';

// Wednesday 2026-10-07, 12:00 local.
final DateTime now = DateTime(2026, 10, 7, 12);

/// 10:00–12:00, 8 seats; only its time of day / length / seats matter.
final SlotDraft template = SlotDraft(
  start: DateTime(2026, 10, 8, 10),
  end: DateTime(2026, 10, 8, 12),
  capacity: 8,
);

void main() {
  group('BookingRules.repeatSlot', () {
    test('every chosen weekday in the range, same times and seats', () {
      final drafts = BookingRules.repeatSlot(
        template,
        from: DateTime(2026, 10, 8), // Thu
        to: DateTime(2026, 10, 21), // Wed
        weekdays: {DateTime.monday, DateTime.thursday},
        now: now,
      );
      expect(drafts.map((d) => d.start), [
        DateTime(2026, 10, 8, 10),
        DateTime(2026, 10, 12, 10),
        DateTime(2026, 10, 15, 10),
        DateTime(2026, 10, 19, 10),
      ]);
      for (final d in drafts) {
        expect(d.end.difference(d.start), const Duration(hours: 2));
        expect(d.capacity, 8);
      }
    });

    test('range ends are inclusive and every day works', () {
      final drafts = BookingRules.repeatSlot(
        template,
        from: DateTime(2026, 10, 8),
        to: DateTime(2026, 10, 14),
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        now: now,
      );
      expect(drafts.length, 7);
      expect(drafts.last.start, DateTime(2026, 10, 14, 10));
    });

    test('skips past starts, taken starts and stops at max', () {
      final drafts = BookingRules.repeatSlot(
        template,
        from: DateTime(2026, 10, 6), // before today
        to: DateTime(2027, 3, 1),
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        now: now,
        existingStarts: [DateTime(2026, 10, 9, 10)],
        max: 5,
      );
      expect(drafts.map((d) => d.start), [
        // 10-06 and 10-07 10:00 are not after `now`; 10-09 is taken.
        DateTime(2026, 10, 8, 10),
        DateTime(2026, 10, 10, 10),
        DateTime(2026, 10, 11, 10),
        DateTime(2026, 10, 12, 10),
        DateTime(2026, 10, 13, 10),
      ]);
    });

    test('nothing beyond slotMaxAhead, nothing without weekdays', () {
      final far = BookingRules.repeatSlot(
        template,
        from: now.add(BookingConfig.slotMaxAhead + const Duration(days: 1)),
        to: now.add(BookingConfig.slotMaxAhead + const Duration(days: 30)),
        weekdays: {1, 2, 3, 4, 5, 6, 7},
        now: now,
      );
      expect(far, isEmpty);
      expect(
        BookingRules.repeatSlot(template,
            from: DateTime(2026, 10, 8),
            to: DateTime(2026, 10, 30),
            weekdays: const {},
            now: now),
        isEmpty,
      );
    });

    test('keeps overnight length (ends next day)', () {
      final late = SlotDraft(
        start: DateTime(2026, 10, 8, 22),
        end: DateTime(2026, 10, 9, 1),
        capacity: 4,
      );
      final drafts = BookingRules.repeatSlot(late,
          from: DateTime(2026, 10, 10),
          to: DateTime(2026, 10, 10),
          weekdays: {DateTime.saturday},
          now: now);
      expect(drafts.single.start, DateTime(2026, 10, 10, 22));
      expect(drafts.single.end, DateTime(2026, 10, 11, 1));
    });
  });

  group('SlotsBloc repeat', () {
    test('creates the dates and reports created / skipped', () async {
      final repo = _Repo();
      final bloc = SlotsBloc(repository: repo)..add(SlotsStarted(_experience()));
      await _pump();

      final start = DateTime.now().add(const Duration(days: 2));
      final drafts = [
        for (var i = 0; i < 3; i++)
          SlotDraft(
            start: start.add(Duration(days: i)),
            end: start.add(Duration(days: i, hours: 2)),
            capacity: 5,
          ),
      ];
      repo.skip = 1; // the server-side range read found one already taken
      bloc.add(SlotsRepeatRequested(drafts));
      await _pump();

      expect(repo.created.length, 3);
      expect(bloc.state.flash, SlotsFlash.repeated);
      expect(bloc.state.repeatCreated, 2);
      expect(bloc.state.repeatSkipped, 1);
      expect(bloc.state.slots.length, 2);
      await bloc.close();
    });

    test('refuses drafts that are all invalid without writing', () async {
      final repo = _Repo();
      final bloc = SlotsBloc(repository: repo)..add(SlotsStarted(_experience()));
      await _pump();
      final past = DateTime.now().subtract(const Duration(days: 1));
      bloc.add(SlotsRepeatRequested([
        SlotDraft(start: past, end: past.add(const Duration(hours: 1)), capacity: 3),
      ]));
      await _pump();
      expect(repo.created, isEmpty);
      expect(bloc.state.flash, SlotsFlash.invalid);
      await bloc.close();
    });
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

UserExperience _experience() => const UserExperience(
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
  final List<SlotDraft> created = [];

  /// How many of the next createSlots drafts to treat as already taken.
  int skip = 0;

  @override
  Future<Either<Failure, List<ExperienceSlot>>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  }) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<ExperienceSlot>>> createSlots(
    String experienceId,
    List<SlotDraft> drafts,
  ) async {
    created.addAll(drafts);
    final kept = drafts.skip(skip).toList();
    return Right([
      for (var i = 0; i < kept.length; i++)
        ExperienceSlot(
          id: 's$i',
          experienceId: experienceId,
          start: kept[i].start,
          end: kept[i].end,
          capacity: kept[i].capacity,
        ),
    ]);
  }
}
