import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../domain/booking_rules.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

abstract class SlotsEvent extends Equatable {
  const SlotsEvent();
  @override
  List<Object?> get props => [];
}

class SlotsStarted extends SlotsEvent {
  const SlotsStarted(this.experience);
  final UserExperience experience;
  @override
  List<Object?> get props => [experience];
}

class SlotsRefreshed extends SlotsEvent {
  const SlotsRefreshed();
}

class SlotSaveRequested extends SlotsEvent {
  const SlotSaveRequested(this.draft, {this.existing});
  final SlotDraft draft;
  final ExperienceSlot? existing;
  @override
  List<Object?> get props => [draft, existing];
}

class SlotDeleteRequested extends SlotsEvent {
  const SlotDeleteRequested(this.slot);
  final ExperienceSlot slot;
  @override
  List<Object?> get props => [slot];
}

/// Cancels the slot and every booking on it (callable).
class SlotCancelRequested extends SlotsEvent {
  const SlotCancelRequested(this.slot, {this.reason});
  final ExperienceSlot slot;
  final String? reason;
  @override
  List<Object?> get props => [slot, reason];
}

class RequestToBookToggled extends SlotsEvent {
  const RequestToBookToggled(this.value);
  final bool value;
  @override
  List<Object?> get props => [value];
}

enum SlotsFlash { saved, deleted, cancelled, toggled, invalid, failed }

class SlotsState extends Equatable {
  const SlotsState({
    this.experience,
    this.slots = const [],
    this.loading = true,
    this.failed = false,
    this.busy = false,
    this.flash,
    this.failure,
    this.errors = const [],
    this.cancelledBookings = 0,
    this.seq = 0,
  });

  final UserExperience? experience;

  /// Upcoming slots (including cancelled ones), soonest first.
  final List<ExperienceSlot> slots;
  final bool loading;
  final bool failed;
  final bool busy;
  final SlotsFlash? flash;
  final Failure? failure;

  /// Validation errors of the last refused save.
  final List<SlotError> errors;
  final int cancelledBookings;
  final int seq;

  SlotsState copyWith({
    UserExperience? experience,
    List<ExperienceSlot>? slots,
    bool? loading,
    bool? failed,
    bool? busy,
    SlotsFlash? flash,
    Failure? failure,
    List<SlotError>? errors,
    int? cancelledBookings,
  }) =>
      SlotsState(
        experience: experience ?? this.experience,
        slots: slots ?? this.slots,
        loading: loading ?? this.loading,
        failed: failed ?? this.failed,
        busy: busy ?? this.busy,
        flash: flash,
        failure: failure,
        errors: errors ?? (flash == null ? this.errors : const []),
        cancelledBookings: cancelledBookings ?? this.cancelledBookings,
        seq: flash != null ? seq + 1 : seq,
      );

  @override
  List<Object?> get props => [
        experience,
        slots,
        loading,
        failed,
        busy,
        flash,
        failure,
        errors,
        cancelledBookings,
        seq,
      ];
}

/// Host: "Dates & availability" of one experience.
class SlotsBloc extends Bloc<SlotsEvent, SlotsState> {
  SlotsBloc({
    required BookingsRepository repository,
    required UserExperiencesRepository experiences,
  })  : _repo = repository,
        _experiences = experiences,
        super(const SlotsState()) {
    on<SlotsStarted>(_onStarted);
    on<SlotsRefreshed>((e, emit) => _load(emit));
    on<SlotSaveRequested>(_onSave);
    on<SlotDeleteRequested>(_onDelete);
    on<SlotCancelRequested>(_onCancel);
    on<RequestToBookToggled>(_onToggle);
  }

  /// Bounded: the next [limit] dates (hosts rarely plan more ahead).
  static const int limit = 60;

  final BookingsRepository _repo;
  final UserExperiencesRepository _experiences;

  Future<void> _onStarted(SlotsStarted e, Emitter<SlotsState> emit) async {
    emit(SlotsState(experience: e.experience));
    await _load(emit);
  }

  Future<void> _load(Emitter<SlotsState> emit) async {
    final e = state.experience;
    if (e == null) return;
    emit(state.copyWith(loading: true, failed: false));
    final r = await _repo.slots(e.id,
        from: BookingRules.upcomingCutoff(DateTime.now()),
        limit: limit,
        includeCancelled: true);
    r.fold(
      (_) => emit(state.copyWith(loading: false, failed: true)),
      (list) => emit(state.copyWith(loading: false, slots: list)),
    );
  }

  List<ExperienceSlot> _sorted(Iterable<ExperienceSlot> s) =>
      s.toList()..sort((a, b) => a.start.compareTo(b.start));

  Future<void> _onSave(SlotSaveRequested e, Emitter<SlotsState> emit) async {
    final exp = state.experience;
    if (exp == null || state.busy) return;
    final errors =
        BookingRules.validateSlot(e.draft, DateTime.now(), existing: e.existing);
    if (errors.isNotEmpty) {
      emit(state.copyWith(flash: SlotsFlash.invalid, errors: errors));
      return;
    }
    emit(state.copyWith(busy: true));
    final r = await _repo.saveSlot(exp.id, e.draft, existing: e.existing);
    r.fold(
      (f) => emit(state.copyWith(
          busy: false, flash: SlotsFlash.failed, failure: f)),
      (slot) => emit(state.copyWith(
        busy: false,
        flash: SlotsFlash.saved,
        slots: _sorted([
          for (final s in state.slots)
            if (s.id != slot.id) s,
          slot,
        ]),
      )),
    );
  }

  Future<void> _onDelete(SlotDeleteRequested e, Emitter<SlotsState> emit) async {
    final exp = state.experience;
    if (exp == null || state.busy || e.slot.hasBookings) return;
    emit(state.copyWith(busy: true));
    final r = await _repo.deleteSlot(exp.id, e.slot.id);
    r.fold(
      (f) => emit(state.copyWith(
          busy: false, flash: SlotsFlash.failed, failure: f)),
      (_) => emit(state.copyWith(
        busy: false,
        flash: SlotsFlash.deleted,
        slots: [for (final s in state.slots) if (s.id != e.slot.id) s],
      )),
    );
  }

  Future<void> _onCancel(SlotCancelRequested e, Emitter<SlotsState> emit) async {
    final exp = state.experience;
    if (exp == null || state.busy || e.slot.cancelled) return;
    emit(state.copyWith(busy: true));
    final r = await _repo.cancelSlot(exp.id, e.slot.id, reason: e.reason);
    r.fold(
      (f) => emit(state.copyWith(
          busy: false, flash: SlotsFlash.failed, failure: f)),
      (res) => emit(state.copyWith(
        busy: false,
        flash: SlotsFlash.cancelled,
        cancelledBookings: res.cancelledBookings,
        slots: [
          for (final s in state.slots)
            s.id == e.slot.id
                ? ExperienceSlot(
                    id: s.id,
                    experienceId: s.experienceId,
                    start: s.start,
                    end: s.end,
                    capacity: s.capacity,
                    cancelled: true,
                  )
                : s,
        ],
      )),
    );
  }

  Future<void> _onToggle(
      RequestToBookToggled e, Emitter<SlotsState> emit) async {
    final exp = state.experience;
    if (exp == null || state.busy || exp.requestToBook == e.value) return;
    emit(state.copyWith(busy: true, experience: exp.copyWith(requestToBook: e.value)));
    final r = await _experiences.setRequestToBook(exp.id, e.value);
    r.fold(
      (f) => emit(state.copyWith(
          busy: false,
          experience: exp,
          flash: SlotsFlash.failed,
          failure: f)),
      (_) => emit(state.copyWith(busy: false, flash: SlotsFlash.toggled)),
    );
  }
}
