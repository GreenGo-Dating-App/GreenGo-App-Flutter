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
      durationMinutes: 120,
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

ExperienceSlot slot(String id, {int capacity = 10, int booked = 0}) {
  final start = DateTime.now().add(const Duration(days: 3));
  return ExperienceSlot(
    id: id,
    experienceId: 'e1',
    start: start,
    end: start.add(const Duration(hours: 2)),
    capacity: capacity,
    bookedCount: booked,
  );
}

Booking bookingFor(String slotId, int guests, String status) => Booking(
      id: 'bk_x',
      experienceId: 'e1',
      slotId: slotId,
      hostId: 'host',
      guestId: 'guest',
      guests: guests,
      status: BookingStatus.fromWire(status),
      slotStart: DateTime.now().add(const Duration(days: 3)),
      slotEnd: DateTime.now().add(const Duration(days: 3, hours: 2)),
    );

class _Call {
  _Call(this.slotId, this.guests, this.requestId, this.method, this.consent);
  final String slotId;
  final int guests;
  final String requestId;
  final PaymentMethod? method;
  final int consent;
}

class _Repo extends Fake implements BookingsRepository {
  _Repo(this.slotList, this.outcomes);
  List<ExperienceSlot> slotList;

  /// One outcome per createBooking call (Left failure / Right booking).
  final List<Either<Failure, Booking>> outcomes;
  final List<_Call> calls = [];

  @override
  Future<Either<Failure, List<ExperienceSlot>>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  }) async =>
      Right(slotList);

  @override
  Future<Either<Failure, Booking>> createBooking({
    required UserExperience experience,
    required String slotId,
    required int guests,
    required String requestId,
    PaymentMethod? method,
    required int consentVersion,
  }) async {
    calls.add(_Call(slotId, guests, requestId, method, consentVersion));
    return outcomes.removeAt(0);
  }
}

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  var n = 0;
  String ids() => 'rq_test_${++n}';

  Future<BookingFlowBloc> started(_Repo repo, UserExperience e) async {
    final bloc = BookingFlowBloc(repository: repo, newRequestId: ids)
      ..add(BookingFlowStarted(e));
    await pump();
    await pump();
    return bloc;
  }

  setUp(() => n = 0);

  test('loads slots; submit needs a date and (two methods) a method',
      () async {
    final repo = _Repo([slot('s1'), slot('s2', capacity: 4, booked: 4)], [
      Right(bookingFor('s1', 2, 'confirmed')),
    ]);
    final bloc = await started(repo, experience());
    expect(bloc.state.slotsLoading, isFalse);
    expect(bloc.state.slots.map((s) => s.id), ['s1', 's2']);
    expect(bloc.state.canSubmit, isFalse);

    // A full slot cannot be picked.
    bloc.add(const BookingSlotSelected('s2'));
    await pump();
    expect(bloc.state.selectedSlotId, isNull);

    bloc.add(const BookingSlotSelected('s1'));
    await pump();
    expect(bloc.state.needsMethodChoice, isTrue);
    expect(bloc.state.canSubmit, isFalse, reason: 'cash + link: must choose');

    bloc.add(const BookingMethodChanged(PaymentMethod.cash));
    bloc.add(const BookingGuestsChanged(2));
    await pump();
    expect(bloc.state.canSubmit, isTrue);

    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(repo.calls.single.method, PaymentMethod.cash);
    expect(repo.calls.single.guests, 2);
    expect(repo.calls.single.consent, 1);
    expect(bloc.state.result?.status, BookingStatus.confirmed);
    expect(bloc.state.canSubmit, isFalse, reason: 'done: no double submit');
    await bloc.close();
  });

  test('guests are clamped to the group size and the seats left', () async {
    final repo = _Repo([slot('s1', capacity: 10, booked: 7)], []);
    final bloc = await started(repo, experience(maxGroup: 6));
    bloc.add(const BookingSlotSelected('s1'));
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
    bloc.add(const BookingSlotSelected('s1'));
    await pump();
    expect(bloc.state.methods, isEmpty);
    expect(bloc.state.canSubmit, isTrue);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(repo.calls.single.method, isNull);
    await bloc.close();

    final repo2 = _Repo([slot('s1')], [Right(bookingFor('s1', 1, 'requested'))]);
    final bloc2 = await started(
        repo2, experience(methods: const {PaymentMethod.cash}, requestToBook: true));
    bloc2.add(const BookingSlotSelected('s1'));
    await pump();
    expect(bloc2.state.effectiveMethod, PaymentMethod.cash);
    bloc2.add(const BookingSubmitted(consentVersion: 1));
    await pump();
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
    bloc.add(const BookingSlotSelected('s1'));
    await pump();
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(bloc.state.failure?.code, BookingFailure.network);
    expect(bloc.state.failureSeq, 1);
    final first = bloc.requestId;
    expect(first, isNotNull);

    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
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
    bloc.add(const BookingSlotSelected('s1'));
    await pump();
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(bloc.state.failure?.code, 'host_unavailable');
    expect(bloc.requestId, isNull);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(repo.calls[0].requestId, isNot(repo.calls[1].requestId));
    await bloc.close();
  });

  test('slot_full updates the seats left and clamps the guests', () async {
    final repo = _Repo([slot('s1', capacity: 10, booked: 2)], [
      const Left(BookingFailure('slot_full', seatsLeft: 1)),
    ]);
    final bloc = await started(repo, experience(isFree: true));
    bloc.add(const BookingSlotSelected('s1'));
    bloc.add(const BookingGuestsChanged(4));
    await pump();
    expect(bloc.state.guests, 4);
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(bloc.state.failure?.code, 'slot_full');
    expect(bloc.state.selectedSlot?.seatsLeft, 1);
    expect(bloc.state.guests, 1);
    await bloc.close();
  });

  test('slot_closed removes the date and clears the selection', () async {
    final repo = _Repo([slot('s1'), slot('s2')], [
      const Left(BookingFailure('slot_closed')),
    ]);
    final bloc = await started(repo, experience(isFree: true));
    bloc.add(const BookingSlotSelected('s1'));
    await pump();
    bloc.add(const BookingSubmitted(consentVersion: 1));
    await pump();
    await pump();
    expect(bloc.state.slots.map((s) => s.id), ['s2']);
    expect(bloc.state.selectedSlotId, isNull);
    await bloc.close();
  });
}
