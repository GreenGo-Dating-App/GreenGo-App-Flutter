import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/domain/repositories/user_experiences_repository.dart';
import '../entities/booking.dart';

/// Experience bookings (functions/src/experience_bookings). Booking writes go
/// through the callables; slots and the host's guest review are direct
/// writes the rules validate. Failures of the callables are BookingFailure.
abstract class BookingsRepository {
  // ── slots ──

  /// Slots from [from] on (default: now), soonest first, at most [limit].
  /// [includeCancelled] false drops cancelled slots (guest picker).
  Future<Either<Failure, List<ExperienceSlot>>> slots(
    String experienceId, {
    DateTime? from,
    int limit = 30,
    bool includeCancelled = false,
  });

  /// Creates ([slotId] null) or updates a slot.
  Future<Either<Failure, ExperienceSlot>> saveSlot(
    String experienceId,
    SlotDraft draft, {
    ExperienceSlot? existing,
  });

  /// Only while nothing is booked on it.
  Future<Either<Failure, void>> deleteSlot(String experienceId, String slotId);

  /// Cancels the slot AND every active booking on it (100% owed back).
  Future<Either<Failure, SlotCancelResult>> cancelSlot(
    String experienceId,
    String slotId, {
    String? reason,
  });

  // ── bookings ──

  /// [requestId] must be REUSED when retrying after a non-definitive failure.
  Future<Either<Failure, Booking>> createBooking({
    required UserExperience experience,
    required String slotId,
    required int guests,
    required String requestId,
    PaymentMethod? method,
    required int consentVersion,
  });

  Future<Either<Failure, ExperiencePage<Booking>>> bookings(
    BookingsQuery query, {
    Object? cursor,
    int limit = 20,
  });

  Future<Either<Failure, Booking?>> getBooking(String bookingId);

  Future<Either<Failure, Booking>> respond(Booking b, {required bool accept});
  Future<Either<Failure, Booking>> cancel(Booking b, {String? reason});
  Future<Either<Failure, BookingCheckInCode>> checkInCode(String bookingId);
  Future<Either<Failure, Booking>> checkIn(Booking b,
      {required String code, bool cashReceived = false});
  Future<Either<Failure, Booking>> markNoShow(Booking b);

  /// Guest (link) or host (link / cash after the start).
  Future<Either<Failure, Booking>> markPaid(Booking b);
  Future<Either<Failure, Booking>> confirmCashReceived(Booking b);
  Future<Either<Failure, Booking>> openDispute(Booking b,
      {required String reason});

  // ── host → guest review (double-blind) ──

  /// The host's review of this booking's guest (null = not written yet).
  Future<Either<Failure, GuestReview?>> guestReviewFor(String bookingId);

  Future<Either<Failure, void>> submitGuestReview(
    Booking b, {
    required int rating,
    required String comment,
  });
}
