import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../domain/booking_failure.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';

/// Every action of the booking detail page.
enum BookingAction {
  accept,
  decline,
  cancel,
  markPaid,
  confirmCash,
  checkIn,
  noShow,
  dispute,
  checkInCode,
  reviewGuest,
}

abstract class BookingDetailEvent extends Equatable {
  const BookingDetailEvent();
  @override
  List<Object?> get props => [];
}

class BookingDetailRequested extends BookingDetailEvent {
  const BookingDetailRequested(this.bookingId, {this.initial});
  final String bookingId;
  final Booking? initial;
  @override
  List<Object?> get props => [bookingId, initial];
}

class BookingActionRequested extends BookingDetailEvent {
  const BookingActionRequested(
    this.action, {
    this.reason,
    this.code,
    this.cashReceived = false,
  });
  final BookingAction action;

  /// cancel (optional) / dispute (required).
  final String? reason;

  /// checkIn.
  final String? code;
  final bool cashReceived;
  @override
  List<Object?> get props => [action, reason, code, cashReceived];
}

class GuestReviewSubmitted extends BookingDetailEvent {
  const GuestReviewSubmitted({required this.rating, required this.comment});
  final int rating;
  final String comment;
  @override
  List<Object?> get props => [rating, comment];
}

enum BookingDetailLoad { loading, ready, notFound, failure }

class BookingDetailState extends Equatable {
  const BookingDetailState({
    this.load = BookingDetailLoad.loading,
    this.booking,
    this.experience,
    this.busy,
    this.guestReview,
    this.guestReviewLoaded = false,
    this.checkInCode,
    this.done,
    this.failure,
    this.seq = 0,
  });

  final BookingDetailLoad load;
  final Booking? booking;

  /// Live listing (meeting point, location); null when deleted / hidden.
  final UserExperience? experience;

  /// The action in flight (buttons show a spinner, others are disabled).
  final BookingAction? busy;

  /// Host: their review of this guest (null = none yet).
  final GuestReview? guestReview;
  final bool guestReviewLoaded;
  final BookingCheckInCode? checkInCode;

  /// One-shot: the action that just succeeded / failed ([seq] bumps).
  final BookingAction? done;
  final BookingFailure? failure;
  final int seq;

  BookingDetailState copyWith({
    BookingDetailLoad? load,
    Booking? booking,
    UserExperience? experience,
    BookingAction? busy,
    bool clearBusy = false,
    GuestReview? guestReview,
    bool? guestReviewLoaded,
    BookingCheckInCode? checkInCode,
    BookingAction? done,
    BookingFailure? failure,
  }) =>
      BookingDetailState(
        load: load ?? this.load,
        booking: booking ?? this.booking,
        experience: experience ?? this.experience,
        busy: clearBusy ? null : (busy ?? this.busy),
        guestReview: guestReview ?? this.guestReview,
        guestReviewLoaded: guestReviewLoaded ?? this.guestReviewLoaded,
        checkInCode: checkInCode ?? this.checkInCode,
        done: done,
        failure: failure,
        seq: (done != null || failure != null) ? seq + 1 : seq,
      );

  @override
  List<Object?> get props => [
        load,
        booking,
        experience,
        busy,
        guestReview,
        guestReviewLoaded,
        checkInCode,
        done,
        failure,
        seq,
      ];
}

class BookingDetailBloc extends Bloc<BookingDetailEvent, BookingDetailState> {
  BookingDetailBloc({
    required BookingsRepository repository,
    required UserExperiencesRepository experiences,
    required this.currentUserId,
  })  : _repo = repository,
        _experiences = experiences,
        super(const BookingDetailState()) {
    on<BookingDetailRequested>(_onRequested);
    on<BookingActionRequested>(_onAction);
    on<GuestReviewSubmitted>(_onGuestReview);
  }

  final BookingsRepository _repo;
  final UserExperiencesRepository _experiences;
  final String currentUserId;

  Future<void> _onRequested(
      BookingDetailRequested e, Emitter<BookingDetailState> emit) async {
    if (e.initial != null) {
      emit(state.copyWith(load: BookingDetailLoad.ready, booking: e.initial));
    }
    final r = await _repo.getBooking(e.bookingId);
    Booking? b;
    var failed = false;
    r.fold((_) => failed = true, (x) => b = x);
    if (failed) {
      if (state.booking == null) {
        emit(state.copyWith(load: BookingDetailLoad.failure));
      }
      return;
    }
    if (b == null) {
      emit(const BookingDetailState(load: BookingDetailLoad.notFound));
      return;
    }
    emit(state.copyWith(load: BookingDetailLoad.ready, booking: b));
    // Secondary reads, in parallel.
    final expF = _experiences.getExperience(b!.experienceId);
    final reviewF = b!.isHost(currentUserId)
        ? _repo.guestReviewFor(b!.id)
        : Future.value(const Right<Failure, GuestReview?>(null));
    final exp = (await expF).fold((_) => null, (x) => x);
    final review = (await reviewF).fold((_) => null, (x) => x);
    emit(state.copyWith(
      experience: exp,
      guestReview: review,
      guestReviewLoaded: true,
    ));
  }

  Future<void> _onAction(
      BookingActionRequested e, Emitter<BookingDetailState> emit) async {
    final b = state.booking;
    if (b == null || state.busy != null) return;
    emit(state.copyWith(busy: e.action));
    if (e.action == BookingAction.checkInCode) {
      final r = await _repo.checkInCode(b.id);
      r.fold(
        (f) => emit(state.copyWith(clearBusy: true, failure: _bf(f))),
        (code) => emit(state.copyWith(
            clearBusy: true, checkInCode: code, done: e.action)),
      );
      return;
    }
    final Either<Failure, Booking> r;
    switch (e.action) {
      case BookingAction.accept:
        r = await _repo.respond(b, accept: true);
      case BookingAction.decline:
        r = await _repo.respond(b, accept: false);
      case BookingAction.cancel:
        r = await _repo.cancel(b, reason: e.reason);
      case BookingAction.markPaid:
        r = await _repo.markPaid(b);
      case BookingAction.confirmCash:
        r = await _repo.confirmCashReceived(b);
      case BookingAction.checkIn:
        r = await _repo.checkIn(b,
            code: e.code ?? '', cashReceived: e.cashReceived);
      case BookingAction.noShow:
        r = await _repo.markNoShow(b);
      case BookingAction.dispute:
        r = await _repo.openDispute(b, reason: e.reason ?? '');
      case BookingAction.checkInCode:
      case BookingAction.reviewGuest:
        emit(state.copyWith(clearBusy: true));
        return;
    }
    r.fold(
      (f) => emit(state.copyWith(clearBusy: true, failure: _bf(f))),
      (updated) => emit(state.copyWith(
          clearBusy: true, booking: updated, done: e.action)),
    );
  }

  Future<void> _onGuestReview(
      GuestReviewSubmitted e, Emitter<BookingDetailState> emit) async {
    final b = state.booking;
    if (b == null || state.busy != null || state.guestReview != null) return;
    emit(state.copyWith(busy: BookingAction.reviewGuest));
    final r = await _repo.submitGuestReview(b,
        rating: e.rating, comment: e.comment.trim());
    r.fold(
      (f) => emit(state.copyWith(clearBusy: true, failure: _bf(f))),
      (_) => emit(state.copyWith(
        clearBusy: true,
        done: BookingAction.reviewGuest,
        guestReview: GuestReview(
          bookingId: b.id,
          hostId: b.hostId,
          guestId: b.guestId,
          experienceId: b.experienceId,
          rating: e.rating,
          comment: e.comment.trim(),
          createdAt: DateTime.now(),
        ),
      )),
    );
  }

  static BookingFailure _bf(Failure f) => f is BookingFailure
      ? f
      : const BookingFailure(BookingFailure.network, definitive: false);
}
