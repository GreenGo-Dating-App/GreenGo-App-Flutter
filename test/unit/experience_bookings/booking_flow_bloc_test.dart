import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/experience_bookings/domain/booking_failure.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/experience_bookings/domain/repositories/bookings_repository.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/bloc/booking_flow_bloc.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';

UserExperience experience({
  bool isFree = false,
  Set<PaymentMethod> methods = const {PaymentMethod.cash, PaymentMethod.link},
  int maxGroup = 6,
  bool requestToBook = false,
}) =>
    UserExperience(
      id: 'e1',
      hostId: 'host',
      title: 'Street food walk',
      description: 'd' * 40,
      category: ExperienceCategory.foodDrink,
      mainPhotoUrl: 'https://a/b.jpg',
      included: const ['Snacks'],
      locationName: 'São Paulo',
      durationMinutes: 60,
      languages: const ['English'],
      maxGroupSize: maxGroup,
      isFree: isFree,
      price: isFree ? 0 : 25,
      currency: isFree ? null : '€',
      paymentMethods: isFree ? const {} : methods,
      paymentLink: methods.contains(PaymentMethod.link) && !isFree
          ? const PaymentLink(type: PaymentLinkType.pix, value: 'host@pix.com')
          : null,
      requestToBook: requestToBook,
      status: ExperienceStatus.published,
    );

final DateTime windowStart = DateTime.now()
    .add(const Duration(days: 3))
    .copyWith(minute: 0, second: 0, millisecond: 0, microsecond: 0);
DateTime at(int hour) => windowStart.add(Duration(hours: hour));

/// A 3-hour availability window: times at +0h, +1h, +2h (60 min each).
ExperienceSlot slot(String id) => ExperienceSlot(
      id: id,
      experienceId: 'e1',
      start: windowStart,
      end: windowStart.add(const Duration(hours: 3)),
      capacity: 500,
    );

Booking bookingFor(String slotId, int guests, String status) => Booking(
      id: 'bk_x',
      experienceId: 'e1',
      slotId: slotId,
      hostId: 'host',
      guestId: 'guest',
      guests: guests,
      status: BookingStatus.fromWire(status),
      slotStart: at(0),
      slotEnd: at(1),
    );

class _Call {
  _Call(this.slotId, this.guests, this.requestId, this.method, this.consent,
      this.startAt);
  final String slotId;
  final int guests;
  final String requestId;
  final PaymentMethod? method;
  final int consent;
  final DateTime? startAt;
}

class _Repo extends Fake implements BookingsRepository {
  _Repo(this.slotList, this.outcomes);
  List<ExperienceSlot> slotList;

  /// One outcome per createBooking call (Left failure / Right booking).
  final List<Either<Failure, Booking>> outcomes;
  final List<_Call> calls = [];

  /// Start hours (0..2) already taken by other bookings of the host.
  Set<int> taken = {};
  int availabilityReads = 0;

  @override
  Future<Either<Failure, List<ExperienceSlot>>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  }) async =>
      Right(slotList);

  @override
  Future<Either<Failure, SlotAvailability>> slotAvailability(
      String experienceId, String slotId) async {
    availabilityReads++;
    return Right(SlotAvailability(
      slotId: slotId,
      lengthMinutes: 60,
      times: [
        for (var h = 0; h < 3; h++)
          SlotTime(start: at(h), end: at(h + 1), free: !taken.contains(h)),
      ],
    ));
  }

  @override
  Future<Either<Failure, Booking>> createBooking({
    required UserExperience experience,
    required String slotId,
    required int guests,
    required String requestId,
    PaymentMethod? method,
    required int consentVersion,
    DateTime? startAt,
  }) async {
    calls.add(
        _Call(slotId, guests, requestId, method, consentVersion, startAt));
    return outcomes.removeAt(0);
  }
}

Future<void> pump() async {
  for (var i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  var n = 0;
  String ids() => 'rq_test_${++n}';

  Future<BookingFlowBloc> started(_Repo repo, UserExperience e) async {
    final bloc = BookingFlowBloc(repository: repo, newRequestId: ids)
      ..add(BookingFlowStarted(e));
    await pump();
    return bloc;
  }

  Future<void> pick(BookingFlowBloc bloc, String slotId, int hour) async {
    bloc.add(BookingSlotSelected(slotId));
    await pump();
    bloc.add(BookingTimeSelected(at(hour)));
    await pump();
  }

  setUp(() => n = 0);

  test('date -> free times; submit needs a time and (two methods) a method',
      () async {
    final repo = _Repo([slot('s1'), slot('s2')], [
      Right(bookingFor('s1', 2, 'confirmed')),
    ])
      ..taken = {0};
    final bloc = await started(repo, experience());
    expect(bloc.state.slotsLoading, isFalse);
    expect(bloc.state.slots.map((s) => s.id), ['s1', 's2']);
    expect(bloc.state.canSubmit, isFalse);

    bloc.add(const BookingSlotSelected('s1'));
    await pump();
    expect(bloc.state.availability?.times.map((t) => t.free),
        [false, true, true]);
    expect(bloc.state.canSubmit, isFalse, reason: 'no time picked yet');

    // A taken time cannot be picked.
    bloc.add(BookingTimeSelected(at(0)));
    await pump();
    expect(bloc.state.selectedStart, isNull);

    bloc.add(BookingTimeSelected(at(1)));
    await pump();
    expect(bloc.state.selectedTime?.start, at(1));
    expect(bloc.state.needsMethodChoice, isTrue);
    expect(bloc.state.canSubmit, isFalse, reason: 'cash + link: must choose');

    bloc.add(const BookingMethodChanged(PaymentMethod.cash));
    bloc.add(const BookingGuestsChanged(2));
    await pump();
    expect(bloc.state.canSubmit, isTrue);

    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    final call = repo.calls.single;
    expect(call.method, PaymentMethod.cash);
    expect(call.guests, 2);
    expect(call.consent, 1);
    expect(call.startAt, at(1), reason: 'the picked time is sent');
    expect(bloc.state.result?.status, BookingStatus.confirmed);
    expect(bloc.state.canSubmit, isFalse, reason: 'done: no double submit');
    await bloc.close();
  });

  test('changing the date clears the picked time', () async {
    final repo = _Repo([slot('s1'), slot('s2')], []);
    final bloc = await started(repo, experience(isFree: true));
    await pick(bloc, 's1', 1);
    expect(bloc.state.selectedStart, at(1));
    bloc.add(const BookingSlotSelected('s2'));
    await pump();
    expect(bloc.state.selectedSlotId, 's2');
    expect(bloc.state.selectedStart, isNull);
    expect(bloc.state.availability?.slotId, 's2');
    await bloc.close();
  });

  test('guests are clamped to the group size (seats no longer apply)',
      () async {
    final repo = _Repo([slot('s1')], []);
    final bloc = await started(repo, experience(maxGroup: 3));
    await pick(bloc, 's1', 0);
    bloc.add(const BookingGuestsChanged(9));
    await pump();
    expect(bloc.state.maxGuests, 3);
    expect(bloc.state.guests, 3);
    bloc.add(const BookingGuestsChanged(0));
    await pump();
    expect(bloc.state.guests, 1);
    await bloc.close();
  });

  test('free: no method sent; single method is implied', () async {
    final repo = _Repo([slot('s1')], [Right(bookingFor('s1', 1, 'confirmed'))]);
    final bloc = await started(repo, experience(isFree: true));
    await pick(bloc, 's1', 2);
    expect(bloc.state.methods, isEmpty);
    expect(bloc.state.canSubmit, isTrue);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(repo.calls.single.method, isNull);
    await bloc.close();

    final repo2 = _Repo([slot('s1')], [Right(bookingFor('s1', 1, 'requested'))]);
    final bloc2 = await started(repo2,
        experience(methods: const {PaymentMethod.cash}, requestToBook: true));
    await pick(bloc2, 's1', 0);
    expect(bloc2.state.effectiveMethod, PaymentMethod.cash);
    bloc2.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(repo2.calls.single.method, PaymentMethod.cash);
    expect(bloc2.state.result?.status, BookingStatus.requested);
    await bloc2.close();
  });

  test('a network failure keeps the requestId for the retry (idempotent)',
      () async {
    final repo = _Repo([slot('s1')], [
      const Left(BookingFailure(BookingFailure.network, definitive: false)),
      Right(bookingFor('s1', 1, 'confirmed')),
    ]);
    final bloc = await started(repo, experience(isFree: true));
    await pick(bloc, 's1', 0);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(bloc.state.failure?.code, BookingFailure.network);
    expect(bloc.state.failureSeq, 1);
    final first = bloc.requestId;
    expect(first, isNotNull);

    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(repo.calls.map((c) => c.requestId).toSet(), {first},
        reason: 'retry reuses the same key');
    expect(bloc.state.result, isNotNull);
    expect(bloc.requestId, isNull, reason: 'cleared after success');
    await bloc.close();
  });

  test('a definitive refusal gets a fresh requestId next time', () async {
    final repo = _Repo([slot('s1')], [
      const Left(BookingFailure('host_unavailable')),
      Right(bookingFor('s1', 1, 'confirmed')),
    ]);
    final bloc = await started(repo, experience(isFree: true));
    await pick(bloc, 's1', 0);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(bloc.state.failure?.code, 'host_unavailable');
    expect(bloc.requestId, isNull);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(repo.calls[0].requestId, isNot(repo.calls[1].requestId));
    await bloc.close();
  });

  test('time_taken re-reads the times and clears the pick', () async {
    final repo = _Repo([slot('s1')], [
      const Left(BookingFailure('time_taken')),
    ]);
    final bloc = await started(repo, experience(isFree: true));
    await pick(bloc, 's1', 1);
    final readsBefore = repo.availabilityReads;
    repo.taken = {1}; // someone else got 11:00 meanwhile
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(bloc.state.failure?.code, 'time_taken');
    expect(repo.availabilityReads, readsBefore + 1);
    expect(bloc.state.selectedStart, isNull);
    expect(bloc.state.availability?.times.map((t) => t.free),
        [true, false, true]);
    expect(bloc.state.canSubmit, isFalse);
    await bloc.close();
  });

  test('slot_closed removes the date and clears the selection', () async {
    final repo = _Repo([slot('s1'), slot('s2')], [
      const Left(BookingFailure('slot_closed')),
    ]);
    final bloc = await started(repo, experience(isFree: true));
    await pick(bloc, 's1', 0);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    expect(bloc.state.slots.map((s) => s.id), ['s2']);
    expect(bloc.state.selectedSlotId, isNull);
    expect(bloc.state.selectedStart, isNull);
    await bloc.close();
  });
}
