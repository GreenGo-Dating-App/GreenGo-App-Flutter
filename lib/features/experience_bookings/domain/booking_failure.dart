import '../../../core/error/failures.dart';

/// A refusal from a booking callable (HttpsError `details.code`) or a
/// transport problem.
///
/// [definitive] = the server answered with a reason, so nothing was written
/// (createBooking: a new requestId is safe). Network errors, timeouts and
/// `internal` are NOT definitive: the booking may exist, so a retry must
/// reuse the same requestId (the server then returns the existing booking).
class BookingFailure extends Failure {
  const BookingFailure(
    this.code, {
    this.definitive = true,
    this.seatsLeft,
    this.max,
    this.existingBookingId,
  }) : super(code);

  /// Wire reason: slot_full, already_booked, id_document_required, …;
  /// `network` for transport errors, `internal` for server crashes.
  final String code;
  final bool definitive;

  /// slot_full.
  final int? seatsLeft;

  /// invalid_guests / too_many_guests.
  final int? max;

  /// already_booked: the guest's active booking on this slot.
  final String? existingBookingId;

  static const String network = 'network';
  static const String internal = 'internal';

  @override
  List<Object?> get props =>
      [message, code, definitive, seatsLeft, max, existingBookingId];
}
