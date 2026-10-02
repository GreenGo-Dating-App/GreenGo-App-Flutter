import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_remote_datasource.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  BookingsRepositoryImpl({BookingsRemoteDataSource? remote})
      : _remote = remote ?? BookingsRemoteDataSource();

  final BookingsRemoteDataSource _remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } catch (e) {
      debugPrint('BookingsRepository: $e');
      return Left(BookingsRemoteDataSource.failureFrom(e));
    }
  }

  @override
  Future<Either<Failure, List<ExperienceSlot>>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  }) =>
      _guard(() => _remote.slots(experienceId,
          from: from, limit: limit, includeCancelled: includeCancelled));

  @override
  Future<Either<Failure, ExperienceSlot>> saveSlot(
    String experienceId,
    SlotDraft draft, {
    ExperienceSlot? existing,
  }) =>
      _guard(() => _remote.saveSlot(experienceId, draft, existing: existing));

  @override
  Future<Either<Failure, void>> deleteSlot(String experienceId, String slotId) =>
      _guard(() => _remote.deleteSlot(experienceId, slotId));

  @override
  Future<Either<Failure, SlotCancelResult>> cancelSlot(
    String experienceId,
    String slotId, {
    String? reason,
  }) =>
      _guard(() => _remote.cancelSlot(experienceId, slotId, reason: reason));

  @override
  Future<Either<Failure, Booking>> createBooking({
    required UserExperience experience,
    required String slotId,
    required int guests,
    required String requestId,
    PaymentMethod? method,
    required int consentVersion,
  }) =>
      _guard(() => _remote.createBooking(
            experience: experience,
            slotId: slotId,
            guests: guests,
            requestId: requestId,
            method: method,
            consentVersion: consentVersion,
          ));

  @override
  Future<Either<Failure, ExperiencePage<Booking>>> bookings(
    BookingsQuery query, {
    Object? cursor,
    int limit = 20,
  }) =>
      _guard(() => _remote.bookings(query, cursor: cursor, limit: limit));

  @override
  Future<Either<Failure, Booking?>> getBooking(String bookingId) =>
      _guard(() => _remote.getBooking(bookingId));

  @override
  Future<Either<Failure, Booking>> respond(Booking b, {required bool accept}) =>
      _guard(() => _remote.respond(b, accept: accept));

  @override
  Future<Either<Failure, Booking>> cancel(Booking b, {String? reason}) =>
      _guard(() => _remote.cancel(b, reason: reason));

  @override
  Future<Either<Failure, BookingCheckInCode>> checkInCode(String bookingId) =>
      _guard(() => _remote.checkInCode(bookingId));

  @override
  Future<Either<Failure, Booking>> checkIn(Booking b,
          {required String code, bool cashReceived = false}) =>
      _guard(() => _remote.checkIn(b, code: code, cashReceived: cashReceived));

  @override
  Future<Either<Failure, Booking>> markNoShow(Booking b) =>
      _guard(() => _remote.markNoShow(b));

  @override
  Future<Either<Failure, Booking>> markPaid(Booking b) =>
      _guard(() => _remote.markPaid(b));

  @override
  Future<Either<Failure, Booking>> confirmCashReceived(Booking b) =>
      _guard(() => _remote.confirmCashReceived(b));

  @override
  Future<Either<Failure, Booking>> openDispute(Booking b,
          {required String reason}) =>
      _guard(() => _remote.openDispute(b, reason: reason));

  @override
  Future<Either<Failure, GuestReview?>> guestReviewFor(String bookingId) =>
      _guard(() => _remote.guestReviewFor(bookingId));

  @override
  Future<Either<Failure, void>> submitGuestReview(
    Booking b, {
    required int rating,
    required String comment,
  }) =>
      _guard(() =>
          _remote.submitGuestReview(b, rating: rating, comment: comment));
}
