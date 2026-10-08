import 'dart:math';

import '../../user_experiences/domain/cancellation_rules.dart';
import '../../user_experiences/domain/entities/user_experience.dart';
import 'entities/booking.dart';

/// Server tunables the client mirrors (DEFAULT_CONFIG in
/// functions/src/experience_bookings/model.ts). The server stays the
/// authority: these only decide which buttons are shown.
class BookingConfig {
  const BookingConfig._();
  static const int maxGuestsPerBooking = 20;
  static const Duration noShowGrace = Duration(minutes: 30);
  static const Duration disputeWindow = Duration(hours: 24);
  static const Duration checkInEarly = Duration(hours: 2);
  static const Duration checkInLate = Duration(hours: 12);
  static const Duration hostReviewWindow = Duration(days: 30);
  static const Duration reviewReveal = Duration(days: 14);
  static const int slotCapacityMax = 500;
  static const Duration slotMaxLength = Duration(hours: 24);
  static const Duration slotMaxAhead = Duration(days: 366);

  /// Most dates one "Repeat" can create (same bound as the host's list).
  static const int maxRepeatDates = 60;
  static const int disputeReasonMin = 10;
  static const int disputeReasonMax = 1000;
  static const int guestReviewMax = 500;

  /// Bookings that started less than this ago still count as "upcoming"
  /// (the host checks guests in, the guest shows the QR).
  static const Duration upcomingGrace = Duration(hours: 12);
}

/// Why a slot draft is refused (mirrors the slot rules in firestore.rules).
enum SlotError {
  startInPast,
  endBeforeStart,
  tooLong,
  tooFarAhead,
  capacityRange,
  capacityBelowBooked,
  timesFrozen,
}

/// Pure booking rules (unit-tested; the refund math is tested against the
/// SAME fixture as the server: functions/__tests__/fixtures/
/// booking_refund_cases.json).
class BookingRules {
  const BookingRules._();

  // ─────────────────────────────────────────────── refund (server parity)

  /// Percent (0..100) the guest is owed back — refundFor() on the server.
  static int refundPercent(
    CancellationPolicy? policy, {
    required DateTime now,
    required DateTime slotStart,
    required DateTime bookedAt,
    required bool byHost,
  }) {
    if (byHost) return 100;
    final toStart = slotStart.difference(now);
    if (toStart <= Duration.zero) return 0;
    final fraction = CancellationRules.refund(
      policy ?? CancellationPolicy.fallback,
      beforeStart: toStart,
      sinceBooking: now.difference(bookedAt),
    );
    return (fraction * 100).round();
  }

  /// The obligation for [percent] — refundDueFor() on the server.
  ///   free → null; link → percent of the total; cash not yet received → 0
  ///   (nothing changed hands), cash received → percent of the total.
  static RefundDue? refundDue(
    BookingPrice? price,
    BookingPayment payment,
    int percent,
    String reason,
  ) {
    final mode = payment.mode;
    if (price == null ||
        price.totalAmount <= 0 ||
        (mode != BookingPaymentMode.link && mode != BookingPaymentMode.cash)) {
      return null;
    }
    final policyPercent = percent.clamp(0, 100);
    final paidCash =
        mode == BookingPaymentMode.cash && payment.hostConfirmedPaidAt != null;
    final unpaidCash = mode == BookingPaymentMode.cash && !paidCash;
    final pct = unpaidCash ? 0 : policyPercent;
    return RefundDue(
      percent: pct,
      policyPercent: policyPercent,
      amount: (price.totalAmount * pct / 100).round(),
      currency: price.currency,
      reason: unpaidCash
          ? '${reason}_cash_unpaid'
          : (mode == BookingPaymentMode.link &&
                  payment.guestMarkedPaidAt == null &&
                  payment.hostConfirmedPaidAt == null)
              ? '${reason}_link_unconfirmed'
              : reason,
    );
  }

  /// What cancelling [b] now would owe the guest (null = nothing to refund:
  /// free, a request not yet accepted, or not cancellable).
  static RefundDue? cancelPreview(Booking b, DateTime now,
      {required bool byHost}) {
    if (b.status != BookingStatus.confirmed) return null;
    final percent = refundPercent(
      b.policy,
      now: now,
      slotStart: b.slotStart,
      // The 24 h grace window starts when the host confirms the request.
      bookedAt: b.confirmedAt ?? b.createdAt ?? now,
      byHost: byHost,
    );
    return refundDue(b.price, b.payment, percent,
        byHost ? 'host_cancelled' : 'guest_cancelled');
  }

  // ─────────────────────────────────────────────── what can be done now

  static bool canCancel(Booking b, DateTime now) =>
      (b.status == BookingStatus.requested ||
          b.status == BookingStatus.confirmed) &&
      now.isBefore(b.slotStart);

  /// Host: accept / decline a request.
  static bool canRespond(Booking b, DateTime now) =>
      b.status == BookingStatus.requested &&
      now.isBefore(b.slotStart) &&
      (b.requestExpiresAt == null || now.isBefore(b.requestExpiresAt!));

  static bool inCheckInWindow(Booking b, DateTime now) =>
      !now.isBefore(b.slotStart.subtract(BookingConfig.checkInEarly)) &&
      !now.isAfter(b.slotEnd.add(BookingConfig.checkInLate));

  /// Host: check the guest in (or record cash at check-in).
  static bool canCheckIn(Booking b, DateTime now) =>
      b.status == BookingStatus.confirmed &&
      !b.isCheckedIn &&
      inCheckInWindow(b, now);

  /// Guest: the QR code is only issued for confirmed bookings.
  static bool canShowCheckInCode(Booking b, DateTime now) =>
      b.status == BookingStatus.confirmed &&
      !b.isCheckedIn &&
      now.isBefore(b.slotEnd.add(BookingConfig.checkInLate));

  static bool canMarkNoShow(Booking b, DateTime now) =>
      b.status == BookingStatus.confirmed &&
      !b.isCheckedIn &&
      !now.isBefore(b.slotStart.add(BookingConfig.noShowGrace));

  /// Guest: "Report a problem" from the start until end + 24 h.
  static bool inDisputeWindow(Booking b, DateTime now) =>
      !now.isBefore(b.slotStart) &&
      !now.isAfter(b.slotEnd.add(BookingConfig.disputeWindow));

  static bool canDispute(Booking b, DateTime now) =>
      (b.status == BookingStatus.confirmed ||
          b.status == BookingStatus.noShow) &&
      inDisputeWindow(b, now);

  static const Set<BookingStatus> _payable = {
    BookingStatus.confirmed,
    BookingStatus.completed,
    BookingStatus.noShow,
    BookingStatus.disputed,
    BookingStatus.resolved,
  };

  /// Guest: "I paid via the link".
  static bool guestCanMarkPaid(Booking b) =>
      b.payment.mode == BookingPaymentMode.link &&
      b.payment.guestMarkedPaidAt == null &&
      _payable.contains(b.status);

  /// Host: "Payment received" (link) / "Cash received" (cash, at / after
  /// check-in or once the experience started).
  static bool hostCanConfirmPaid(Booking b, DateTime now) {
    if (b.payment.hostConfirmedPaidAt != null) return false;
    if (!_payable.contains(b.status)) return false;
    switch (b.payment.mode) {
      case BookingPaymentMode.link:
        return true;
      case BookingPaymentMode.cash:
        return b.isCheckedIn || !now.isBefore(b.slotStart);
      case BookingPaymentMode.free:
        return false;
    }
  }

  /// Host: "Review your guest" (the rules' window: 30 days after the end).
  static bool hostCanReviewGuest(Booking b, DateTime now) {
    final reviewable = b.status == BookingStatus.completed ||
        b.status == BookingStatus.noShow ||
        (b.status == BookingStatus.confirmed && b.isCheckedIn);
    return reviewable &&
        now.isBefore(b.slotEnd.add(BookingConfig.hostReviewWindow));
  }

  /// Upcoming / past split used by the lists (on slotStart).
  static DateTime upcomingCutoff(DateTime now) =>
      now.subtract(BookingConfig.upcomingGrace);

  // ─────────────────────────────────────────────── guests / slots

  /// Most guests one booking may hold on [slot].
  /// Party size of ONE booking. Private time slots: the window's seats no
  /// longer apply (one booking per time), so [slot] is not a limit.
  static int maxGuests(UserExperience e, ExperienceSlot? slot) {
    final max = min(e.maxGroupSize, BookingConfig.maxGuestsPerBooking);
    return max < 1 ? 0 : max;
  }

  /// Slot add / edit checks ([existing] = the slot being edited).
  static List<SlotError> validateSlot(
    SlotDraft d,
    DateTime now, {
    ExperienceSlot? existing,
  }) {
    final errors = <SlotError>[];
    final frozen = existing != null && existing.hasBookings;
    if (frozen &&
        (d.start != existing.start || d.end != existing.end)) {
      errors.add(SlotError.timesFrozen);
    }
    if (!frozen) {
      if (!d.start.isAfter(now)) errors.add(SlotError.startInPast);
      if (d.start.isAfter(now.add(BookingConfig.slotMaxAhead))) {
        errors.add(SlotError.tooFarAhead);
      }
    }
    if (!d.end.isAfter(d.start)) {
      errors.add(SlotError.endBeforeStart);
    } else if (d.end.difference(d.start) > BookingConfig.slotMaxLength) {
      errors.add(SlotError.tooLong);
    }
    if (d.capacity < 1 || d.capacity > BookingConfig.slotCapacityMax) {
      errors.add(SlotError.capacityRange);
    } else if (existing != null && d.capacity < existing.bookedCount) {
      errors.add(SlotError.capacityBelowBooked);
    }
    return errors;
  }

  /// "Repeat": the [template]'s time of day, length and seats on every day
  /// in [from]..[to] (inclusive, local calendar days) whose weekday
  /// (DateTime.monday..sunday) is in [weekdays]. Days whose start is not in
  /// the future, beyond [BookingConfig.slotMaxAhead], or already taken by a
  /// start in [existingStarts] are skipped. At most [max] drafts, soonest
  /// first. Built from local wall-clock times so a DST change keeps "10:00".
  static List<SlotDraft> repeatSlot(
    SlotDraft template, {
    required DateTime from,
    required DateTime to,
    required Set<int> weekdays,
    required DateTime now,
    Iterable<DateTime> existingStarts = const [],
    int max = BookingConfig.maxRepeatDates,
  }) {
    final t = template.start.toLocal();
    final length = template.end.difference(template.start);
    final taken = {for (final s in existingStarts) s.millisecondsSinceEpoch};
    final last = DateTime(to.year, to.month, to.day);
    final out = <SlotDraft>[];
    for (var day = DateTime(from.year, from.month, from.day);
        !day.isAfter(last) && out.length < max;
        day = DateTime(day.year, day.month, day.day + 1)) {
      if (!weekdays.contains(day.weekday)) continue;
      final start =
          DateTime(day.year, day.month, day.day, t.hour, t.minute);
      if (!start.isAfter(now) ||
          start.isAfter(now.add(BookingConfig.slotMaxAhead)) ||
          taken.contains(start.millisecondsSinceEpoch)) {
        continue;
      }
      out.add(SlotDraft(
          start: start, end: start.add(length), capacity: template.capacity));
    }
    return out;
  }

  // ─────────────────────────────────────────────── identity

  static const String _qrPrefix = 'greengo:checkin:';

  /// `greengo:checkin:{bookingId}:{code}` (checkInQrPayload on the server).
  static ({String bookingId, String code})? parseCheckInQr(String raw) {
    final v = raw.trim();
    if (!v.startsWith(_qrPrefix)) return null;
    final rest = v.substring(_qrPrefix.length);
    final i = rest.lastIndexOf(':');
    if (i <= 0 || i == rest.length - 1) return null;
    final id = rest.substring(0, i);
    final code = rest.substring(i + 1).toUpperCase();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(id)) return null;
    if (!isCheckInCode(code)) return null;
    return (bookingId: id, code: code);
  }

  /// 8 characters of the server's base-32 alphabet (no I, L, O, U).
  static bool isCheckInCode(String v) =>
      RegExp(r'^[ABCDEFGHJKMNPQRSTVWXYZ0-9]{8}$').hasMatch(v.trim().toUpperCase());

  static const String _idChars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// Client idempotency key for createBooking ([A-Za-z0-9_-]{8,64}).
  static String newRequestId([Random? random]) {
    final r = random ?? Random.secure();
    return 'rq_${List.generate(24, (_) => _idChars[r.nextInt(_idChars.length)]).join()}';
  }
}
