import 'package:equatable/equatable.dart';

import '../../../user_experiences/domain/entities/user_experience.dart';

/// Booking lifecycle — mirrors BOOKING_STATUSES in
/// functions/src/experience_bookings/model.ts:
///
///   requested ─► confirmed | declined | expired | cancelled_by_guest | cancelled_by_host
///   confirmed ─► completed | no_show | disputed | cancelled_by_guest | cancelled_by_host
///   no_show   ─► disputed
///   disputed  ─► resolved
enum BookingStatus {
  requested('requested'),
  confirmed('confirmed'),
  declined('declined'),
  expired('expired'),
  cancelledByGuest('cancelled_by_guest'),
  cancelledByHost('cancelled_by_host'),
  completed('completed'),
  noShow('no_show'),
  disputed('disputed'),
  resolved('resolved'),

  /// A status this app version does not know (never acted on).
  unknown('unknown');

  const BookingStatus(this.wire);
  final String wire;

  static BookingStatus fromWire(Object? v) => BookingStatus.values
      .firstWhere((s) => s.wire == v, orElse: () => BookingStatus.unknown);

  bool get isCancelled =>
      this == BookingStatus.cancelledByGuest ||
      this == BookingStatus.cancelledByHost;

  /// No further transition is possible.
  bool get isTerminal => const {
        BookingStatus.declined,
        BookingStatus.expired,
        BookingStatus.cancelledByGuest,
        BookingStatus.cancelledByHost,
        BookingStatus.completed,
        BookingStatus.resolved,
        BookingStatus.unknown,
      }.contains(this);
}

/// How the guest pays (always OUTSIDE GreenGo).
enum BookingPaymentMode {
  free,
  cash,
  link;

  static BookingPaymentMode fromWire(Object? v) => BookingPaymentMode.values
      .firstWhere((m) => m.name == v, orElse: () => BookingPaymentMode.free);
}

/// Price snapshot in MINOR units (cents), from the experience doc.
class BookingPrice extends Equatable {
  const BookingPrice({
    required this.unitAmount,
    required this.totalAmount,
    this.currency,
  });

  static const BookingPrice free =
      BookingPrice(unitAmount: 0, totalAmount: 0);

  final int unitAmount;
  final int totalAmount;

  /// ISO 4217, lower case ('eur'); null when free.
  final String? currency;

  bool get isFree => totalAmount <= 0;

  @override
  List<Object?> get props => [unitAmount, totalAmount, currency];
}

class BookingPayment extends Equatable {
  const BookingPayment({
    this.mode = BookingPaymentMode.free,
    this.link,
    this.guestMarkedPaidAt,
    this.hostConfirmedPaidAt,
  });

  final BookingPaymentMode mode;

  /// Snapshot of the host's link (mode link).
  final PaymentLink? link;

  /// Guest: "I paid via the link" (informational).
  final DateTime? guestMarkedPaidAt;

  /// Host: link payment received / cash received.
  final DateTime? hostConfirmedPaidAt;

  BookingPayment copyWith({
    DateTime? guestMarkedPaidAt,
    DateTime? hostConfirmedPaidAt,
  }) =>
      BookingPayment(
        mode: mode,
        link: link,
        guestMarkedPaidAt: guestMarkedPaidAt ?? this.guestMarkedPaidAt,
        hostConfirmedPaidAt: hostConfirmedPaidAt ?? this.hostConfirmedPaidAt,
      );

  @override
  List<Object?> get props =>
      [mode, link, guestMarkedPaidAt, hostConfirmedPaidAt];
}

/// A refund OBLIGATION (GreenGo never moves money): what the host owes back.
class RefundDue extends Equatable {
  const RefundDue({
    required this.percent,
    required this.policyPercent,
    required this.amount,
    required this.reason,
    this.currency,
    this.decidedAt,
  });

  /// Of what the guest actually paid (0 when cash was never handed over).
  final int percent;

  /// The policy band, even when nothing was paid.
  final int policyPercent;

  /// Minor units.
  final int amount;
  final String? currency;

  /// host_cancelled | guest_cancelled | guest_no_show | dispute_resolution |
  /// experience_deleted, with `_cash_unpaid` appended when cash was not paid.
  final String reason;
  final DateTime? decidedAt;

  bool get cashUnpaid => reason.endsWith('_cash_unpaid');

  @override
  List<Object?> get props =>
      [percent, policyPercent, amount, currency, reason, decidedAt];
}

class BookingDispute extends Equatable {
  const BookingDispute({
    required this.isOpen,
    this.openedAt,
    this.refundPercent,
    this.hostAction,
    this.note,
  });

  final bool isOpen;
  final DateTime? openedAt;
  final int? refundPercent;
  final String? hostAction;
  final String? note;

  @override
  List<Object?> get props => [isOpen, openedAt, refundPercent, hostAction, note];
}

/// `bookings/{bookingId}` — every write is server-side (callables / jobs).
class Booking extends Equatable {
  const Booking({
    required this.id,
    required this.experienceId,
    required this.slotId,
    required this.hostId,
    required this.guestId,
    required this.guests,
    required this.status,
    required this.slotStart,
    required this.slotEnd,
    this.requestToBook = false,
    this.policy = CancellationPolicy.moderate,
    this.experienceTitle,
    this.price = BookingPrice.free,
    this.payment = const BookingPayment(),
    this.refundDue,
    this.cancelledBy,
    this.cancellationReason,
    this.checkedInAt,
    this.dispute,
    this.requestExpiresAt,
    this.createdAt,
    this.confirmedAt,
  });

  final String id;
  final String experienceId;
  final String slotId;
  final String hostId;
  final String guestId;
  final int guests;
  final BookingStatus status;
  final bool requestToBook;
  final CancellationPolicy policy;
  final String? experienceTitle;
  final DateTime slotStart;
  final DateTime slotEnd;
  final BookingPrice price;
  final BookingPayment payment;
  final RefundDue? refundDue;

  /// 'guest' | 'host'.
  final String? cancelledBy;
  final String? cancellationReason;
  final DateTime? checkedInAt;
  final BookingDispute? dispute;
  final DateTime? requestExpiresAt;

  /// When the guest booked (grace rule of the refund preview). Not part of
  /// the callable view: kept from the Firestore document.
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  bool get isFree => payment.mode == BookingPaymentMode.free || price.isFree;
  bool get isCheckedIn => checkedInAt != null;

  bool isHost(String uid) => uid == hostId;
  bool isGuest(String uid) => uid == guestId;

  /// The other party for [uid].
  String counterpartOf(String uid) => uid == hostId ? guestId : hostId;

  Booking copyWith({
    BookingStatus? status,
    BookingPayment? payment,
    RefundDue? refundDue,
    DateTime? checkedInAt,
    String? experienceTitle,
    DateTime? createdAt,
  }) =>
      Booking(
        id: id,
        experienceId: experienceId,
        slotId: slotId,
        hostId: hostId,
        guestId: guestId,
        guests: guests,
        status: status ?? this.status,
        slotStart: slotStart,
        slotEnd: slotEnd,
        requestToBook: requestToBook,
        policy: policy,
        experienceTitle: experienceTitle ?? this.experienceTitle,
        price: price,
        payment: payment ?? this.payment,
        refundDue: refundDue ?? this.refundDue,
        cancelledBy: cancelledBy,
        cancellationReason: cancellationReason,
        checkedInAt: checkedInAt ?? this.checkedInAt,
        dispute: dispute,
        requestExpiresAt: requestExpiresAt,
        createdAt: createdAt ?? this.createdAt,
        confirmedAt: confirmedAt,
      );

  @override
  List<Object?> get props => [
        id,
        experienceId,
        slotId,
        hostId,
        guestId,
        guests,
        status,
        slotStart,
        slotEnd,
        requestToBook,
        policy,
        experienceTitle,
        price,
        payment,
        refundDue,
        cancelledBy,
        cancellationReason,
        checkedInAt,
        dispute,
        requestExpiresAt,
        createdAt,
        confirmedAt,
      ];
}

/// `user_experiences/{expId}/slots/{slotId}` — host-managed; bookedCount is
/// server-owned (booking transactions).
class ExperienceSlot extends Equatable {
  const ExperienceSlot({
    required this.id,
    required this.experienceId,
    required this.start,
    required this.end,
    required this.capacity,
    this.bookedCount = 0,
    this.cancelled = false,
  });

  final String id;
  final String experienceId;
  final DateTime start;
  final DateTime end;
  final int capacity;
  final int bookedCount;
  final bool cancelled;

  int get seatsLeft => (capacity - bookedCount).clamp(0, capacity);
  bool get isOpen => !cancelled;
  bool get hasBookings => bookedCount > 0;

  /// A guest can pick it: open, in the future, seats left.
  bool isBookableAt(DateTime now) =>
      isOpen && start.isAfter(now) && seatsLeft > 0;

  @override
  List<Object?> get props =>
      [id, experienceId, start, end, capacity, bookedCount, cancelled];
}

/// What the host types / picks when adding or editing a slot.
class SlotDraft extends Equatable {
  const SlotDraft({
    required this.start,
    required this.end,
    required this.capacity,
  });

  final DateTime start;
  final DateTime end;
  final int capacity;

  @override
  List<Object?> get props => [start, end, capacity];
}

/// Result of cancelExperienceSlot.
class SlotCancelResult extends Equatable {
  const SlotCancelResult({required this.cancelledBookings, this.more = false});
  final int cancelledBookings;

  /// More active bookings remain (call again).
  final bool more;

  @override
  List<Object?> get props => [cancelledBookings, more];
}

/// getBookingCheckInCode.
class BookingCheckInCode extends Equatable {
  const BookingCheckInCode({
    required this.bookingId,
    required this.code,
    required this.qrPayload,
  });
  final String bookingId;
  final String code;
  final String qrPayload;

  @override
  List<Object?> get props => [bookingId, code, qrPayload];
}

/// Host → guest review, `guest_reviews/{bookingId}`.
class GuestReview extends Equatable {
  const GuestReview({
    required this.bookingId,
    required this.hostId,
    required this.guestId,
    required this.experienceId,
    required this.rating,
    required this.comment,
    this.status = 'held',
    this.createdAt,
  });

  final String bookingId;
  final String hostId;
  final String guestId;
  final String experienceId;
  final int rating;
  final String comment;

  /// held | visible | rejected (server-set; absent right after the write).
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [bookingId, hostId, guestId, experienceId, rating, comment, status, createdAt];
}

/// Which bookings a list shows.
enum BookingRole { guest, host }

class BookingsQuery extends Equatable {
  const BookingsQuery({
    required this.role,
    required this.uid,
    required this.upcoming,
    this.experienceId,
  });

  final BookingRole role;
  final String uid;

  /// true: from [BookingRules.upcomingCutoff] on, soonest first; false:
  /// before it, most recent first.
  final bool upcoming;

  /// Host only: one experience.
  final String? experienceId;

  @override
  List<Object?> get props => [role, uid, upcoming, experienceId];
}
