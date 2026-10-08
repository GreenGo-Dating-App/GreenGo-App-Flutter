import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../domain/booking_failure.dart';
import '../../domain/booking_rules.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

// ───────────────────────────────────────────────────────────── events

abstract class BookingFlowEvent extends Equatable {
  const BookingFlowEvent();
  @override
  List<Object?> get props => [];
}

class BookingFlowStarted extends BookingFlowEvent {
  const BookingFlowStarted(
    this.experience, {
    this.initialSlotId,
    this.initialSlots,
    this.initialSlotsAt,
  });
  final UserExperience experience;
  final String? initialSlotId;

  /// Slots the caller already read (the experience page), so the flow opens
  /// with its dates at once instead of re-reading them. Used when read less
  /// than [BookingFlowBloc.initialSlotsMaxAge] ago ([initialSlotsAt]).
  final List<ExperienceSlot>? initialSlots;
  final DateTime? initialSlotsAt;
  @override
  List<Object?> get props =>
      [experience, initialSlotId, initialSlots, initialSlotsAt];
}

class BookingSlotsRefreshed extends BookingFlowEvent {
  const BookingSlotsRefreshed();
}

class BookingSlotSelected extends BookingFlowEvent {
  const BookingSlotSelected(this.slotId);
  final String slotId;
  @override
  List<Object?> get props => [slotId];
}

/// The guest picked a start time inside the selected window.
class BookingTimeSelected extends BookingFlowEvent {
  const BookingTimeSelected(this.start);
  final DateTime start;
  @override
  List<Object?> get props => [start];
}

/// Re-read the selected window's free times.
class BookingTimesRefreshed extends BookingFlowEvent {
  const BookingTimesRefreshed();
}

class BookingGuestsChanged extends BookingFlowEvent {
  const BookingGuestsChanged(this.guests);
  final int guests;
  @override
  List<Object?> get props => [guests];
}

class BookingMethodChanged extends BookingFlowEvent {
  const BookingMethodChanged(this.method);
  final PaymentMethod method;
  @override
  List<Object?> get props => [method];
}

/// Send createBooking (after the ID gate + consent the screen runs).
class BookingSubmitted extends BookingFlowEvent {
  const BookingSubmitted({required this.consentVersion});
  final int consentVersion;
  @override
  List<Object?> get props => [consentVersion];
}

// ───────────────────────────────────────────────────────────── state

class BookingFlowState extends Equatable {
  const BookingFlowState({
    this.experience,
    this.slots = const [],
    this.slotsLoading = true,
    this.slotsFailed = false,
    this.selectedSlotId,
    this.availability,
    this.timesLoading = false,
    this.timesFailed = false,
    this.selectedStart,
    this.guests = 1,
    this.method,
    this.submitting = false,
    this.result,
    this.failure,
    this.failureSeq = 0,
  });

  final UserExperience? experience;

  /// Bookable slots (open, future), soonest first.
  final List<ExperienceSlot> slots;
  final bool slotsLoading;
  final bool slotsFailed;
  final String? selectedSlotId;

  /// Start times of the selected window (null until read).
  final SlotAvailability? availability;
  final bool timesLoading;
  final bool timesFailed;

  /// The start time the guest picked inside the selected window.
  final DateTime? selectedStart;
  final int guests;

  /// The guest's choice when the listing accepts both cash and the link.
  final PaymentMethod? method;
  final bool submitting;

  /// The created (or already existing) booking.
  final Booking? result;
  final BookingFailure? failure;

  /// Bumped per failure so the same failure twice still notifies.
  final int failureSeq;

  ExperienceSlot? get selectedSlot {
    for (final s in slots) {
      if (s.id == selectedSlotId) return s;
    }
    return null;
  }

  /// The picked time, while it is still listed as free for this window.
  SlotTime? get selectedTime {
    final a = availability;
    final t = selectedStart;
    if (a == null || t == null || a.slotId != selectedSlotId) return null;
    for (final x in a.times) {
      if (x.free && x.start.isAtSameMomentAs(t)) return x;
    }
    return null;
  }

  /// Methods the guest picks from (link first); empty when free.
  List<PaymentMethod> get methods {
    final e = experience;
    if (e == null || e.isFree) return const [];
    return [
      if (e.acceptsLink) PaymentMethod.link,
      if (e.acceptsCash) PaymentMethod.cash,
    ];
  }

  bool get needsMethodChoice => methods.length > 1;

  /// The method sent to the server (null = free, or not chosen yet).
  PaymentMethod? get effectiveMethod =>
      method ?? (methods.length == 1 ? methods.first : null);

  int get maxGuests => experience == null
      ? 0
      : BookingRules.maxGuests(experience!, selectedSlot);

  bool get canSubmit {
    final slot = selectedSlot;
    final e = experience;
    if (e == null || slot == null || submitting || result != null) {
      return false;
    }
    if (!slot.isBookableAt(DateTime.now())) return false;
    final time = selectedTime;
    if (time == null || !time.start.isAfter(DateTime.now())) return false;
    if (guests < 1 || guests > maxGuests) return false;
    if (!e.isFree && effectiveMethod == null) return false;
    return true;
  }

  BookingFlowState copyWith({
    UserExperience? experience,
    List<ExperienceSlot>? slots,
    bool? slotsLoading,
    bool? slotsFailed,
    String? selectedSlotId,
    bool clearSlot = false,
    SlotAvailability? availability,
    bool clearAvailability = false,
    bool? timesLoading,
    bool? timesFailed,
    DateTime? selectedStart,
    bool clearTime = false,
    int? guests,
    PaymentMethod? method,
    bool? submitting,
    Booking? result,
    BookingFailure? failure,
  }) =>
      BookingFlowState(
        experience: experience ?? this.experience,
        slots: slots ?? this.slots,
        slotsLoading: slotsLoading ?? this.slotsLoading,
        slotsFailed: slotsFailed ?? this.slotsFailed,
        selectedSlotId:
            clearSlot ? null : (selectedSlotId ?? this.selectedSlotId),
        availability: clearAvailability || clearSlot
            ? null
            : (availability ?? this.availability),
        timesLoading: timesLoading ?? this.timesLoading,
        timesFailed: timesFailed ?? this.timesFailed,
        selectedStart: clearTime || clearSlot
            ? null
            : (selectedStart ?? this.selectedStart),
        guests: guests ?? this.guests,
        method: method ?? this.method,
        submitting: submitting ?? this.submitting,
        result: result ?? this.result,
        failure: failure ?? this.failure,
        failureSeq: failure != null ? failureSeq + 1 : failureSeq,
      );

  @override
  List<Object?> get props => [
        experience,
        slots,
        slotsLoading,
        slotsFailed,
        selectedSlotId,
        availability,
        timesLoading,
        timesFailed,
        selectedStart,
        guests,
        method,
        submitting,
        result,
        failure,
        failureSeq,
      ];
}

// ───────────────────────────────────────────────────────────── bloc

/// Guest booking: pick a date (an availability window), a free start time
/// in it (private time slots: one booking per time), guests, payment method,
/// then
/// createBooking — idempotent through a client requestId that is REUSED on a
/// retry after a non-definitive failure (network / timeout / internal), so a
/// booking that did go through is returned instead of booked twice.
class BookingFlowBloc extends Bloc<BookingFlowEvent, BookingFlowState> {
  BookingFlowBloc({
    required BookingsRepository repository,
    String Function()? newRequestId,
  })  : _repo = repository,
        _newRequestId = newRequestId ?? BookingRules.newRequestId,
        super(const BookingFlowState()) {
    on<BookingFlowStarted>(_onStarted);
    on<BookingSlotsRefreshed>((e, emit) => _loadSlots(emit));
    on<BookingSlotSelected>(_onSlot);
    on<BookingTimeSelected>(_onTime);
    on<BookingTimesRefreshed>((e, emit) => _loadTimes(emit));
    on<BookingGuestsChanged>(_onGuests);
    on<BookingMethodChanged>(
        (e, emit) => emit(state.copyWith(method: e.method)));
    on<BookingSubmitted>(_onSubmit);
  }

  final BookingsRepository _repo;
  final String Function() _newRequestId;
  String? _requestId;
  String? _initialSlotId;

  /// The idempotency key of the attempt in progress (tests).
  String? get requestId => _requestId;

  /// How old [BookingFlowStarted.initialSlots] may be to skip the re-read
  /// (the server re-checks seats on submit either way).
  static const Duration initialSlotsMaxAge = Duration(minutes: 2);

  Future<void> _onStarted(
      BookingFlowStarted e, Emitter<BookingFlowState> emit) async {
    _initialSlotId = e.initialSlotId;
    emit(BookingFlowState(experience: e.experience));
    final initial = e.initialSlots;
    final at = e.initialSlotsAt;
    if (initial != null &&
        at != null &&
        DateTime.now().difference(at) < initialSlotsMaxAge) {
      await _applySlots(initial, emit);
      return;
    }
    await _loadSlots(emit);
  }

  Future<void> _loadSlots(Emitter<BookingFlowState> emit) async {
    final e = state.experience;
    if (e == null) return;
    emit(state.copyWith(slotsLoading: true, slotsFailed: false));
    final r = await _repo.slots(e.id);
    await r.fold(
      (_) async =>
          emit(state.copyWith(slotsLoading: false, slotsFailed: true)),
      (list) => _applySlots(list, emit),
    );
  }

  Future<void> _applySlots(
      List<ExperienceSlot> list, Emitter<BookingFlowState> emit) async {
    final now = DateTime.now();
    // A window is bookable until it ends: later times may still be free.
    final bookable = list.where((s) => s.isBookableAt(now)).toList();
    final keep = bookable.any((s) => s.id == state.selectedSlotId)
        ? state.selectedSlotId
        : (bookable.any((s) => s.id == _initialSlotId)
            ? _initialSlotId
            : null);
    final changed = keep != state.selectedSlotId;
    emit(state.copyWith(
      slots: bookable,
      slotsLoading: false,
      selectedSlotId: keep,
      clearSlot: keep == null,
    ));
    _clampGuests(emit);
    if (keep != null && (changed || state.availability == null)) {
      await _loadTimesInto(emit);
    }
  }

  /// Reads the selected window's start times (free / taken).
  Future<void> _loadTimes(Emitter<BookingFlowState> emit) => _loadTimesInto(emit);

  Future<void> _loadTimesInto(Emitter<BookingFlowState> emit) async {
    final e = state.experience;
    final slotId = state.selectedSlotId;
    if (e == null || slotId == null) return;
    emit(state.copyWith(timesLoading: true, timesFailed: false));
    final r = await _repo.slotAvailability(e.id, slotId);
    if (emit.isDone || state.selectedSlotId != slotId) return;
    r.fold(
      (_) => emit(state.copyWith(timesLoading: false, timesFailed: true)),
      (a) {
        // Keep the pick only while it is still free.
        final still = state.selectedStart != null &&
            a.times.any((t) =>
                t.free && t.start.isAtSameMomentAs(state.selectedStart!));
        emit(state.copyWith(
          availability: a,
          timesLoading: false,
          clearTime: !still,
        ));
      },
    );
  }

  void _onTime(BookingTimeSelected e, Emitter<BookingFlowState> emit) {
    if (state.submitting) return;
    final a = state.availability;
    if (a == null || a.slotId != state.selectedSlotId) return;
    final ok = a.times.any((t) => t.free && t.start.isAtSameMomentAs(e.start));
    if (!ok) return;
    emit(state.copyWith(selectedStart: e.start));
  }

  Future<void> _onSlot(
      BookingSlotSelected e, Emitter<BookingFlowState> emit) async {
    if (state.submitting) return;
    final slot = state.slots.where((s) => s.id == e.slotId).firstOrNull;
    if (slot == null) return;
    if (e.slotId == state.selectedSlotId && state.availability != null) return;
    emit(state.copyWith(
        selectedSlotId: e.slotId, clearAvailability: true, clearTime: true));
    _clampGuests(emit);
    await _loadTimesInto(emit);
  }

  void _onGuests(BookingGuestsChanged e, Emitter<BookingFlowState> emit) {
    if (state.submitting) return;
    final max = state.maxGuests;
    final g = max < 1 ? 1 : e.guests.clamp(1, max);
    emit(state.copyWith(guests: g));
  }

  void _clampGuests(Emitter<BookingFlowState> emit) {
    final max = state.maxGuests;
    if (max >= 1 && state.guests > max) emit(state.copyWith(guests: max));
  }

  Future<void> _onSubmit(
      BookingSubmitted e, Emitter<BookingFlowState> emit) async {
    if (!state.canSubmit) return;
    final exp = state.experience!;
    final slot = state.selectedSlot!;
    _requestId ??= _newRequestId();
    emit(state.copyWith(submitting: true));
    final r = await _repo.createBooking(
      experience: exp,
      slotId: slot.id,
      guests: state.guests,
      requestId: _requestId!,
      method: exp.isFree ? null : state.effectiveMethod,
      consentVersion: e.consentVersion,
      startAt: state.selectedStart,
    );
    var retime = false;
    r.fold(
      (f) {
        final bf = f is BookingFailure
            ? f
            : const BookingFailure(BookingFailure.network, definitive: false);
        // The server refused: nothing exists under this key, so a later
        // attempt (maybe another date) gets a fresh one.
        if (bf.definitive) _requestId = null;
        var slots = state.slots;
        if (bf.code == 'slot_full' && bf.seatsLeft != null) {
          slots = [
            for (final s in state.slots)
              s.id == slot.id
                  ? ExperienceSlot(
                      id: s.id,
                      experienceId: s.experienceId,
                      start: s.start,
                      end: s.end,
                      capacity: s.capacity,
                      bookedCount: s.capacity - bf.seatsLeft!,
                      cancelled: s.cancelled,
                    )
                  : s,
          ];
        } else if (bf.code == 'slot_closed') {
          slots = [for (final s in state.slots) if (s.id != slot.id) s];
        }
        // The time was taken meanwhile (or has started): re-read the window.
        retime = bf.code == 'time_taken' ||
            bf.code == 'invalid_start' ||
            bf.code == 'slot_started';
        emit(state.copyWith(
          submitting: false,
          slots: slots,
          failure: bf,
          clearSlot: !slots.any((s) => s.id == slot.id),
          clearTime: retime,
        ));
        _clampGuests(emit);
      },
      (booking) {
        _requestId = null;
        emit(state.copyWith(submitting: false, result: booking));
      },
    );
    if (retime && state.selectedSlotId == slot.id) await _loadTimesInto(emit);
  }
}
