import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../generated/app_localizations.dart';
import '../../user_experiences/presentation/experience_l10n.dart';
import '../domain/booking_failure.dart';
import '../domain/booking_rules.dart';
import '../domain/entities/booking.dart';

/// Localized labels / formatting for experience bookings.
class BookingL10n {
  const BookingL10n._();

  static String status(AppLocalizations l, BookingStatus s) => switch (s) {
        BookingStatus.requested => l.bkStatusRequested,
        BookingStatus.confirmed => l.bkStatusConfirmed,
        BookingStatus.declined => l.bkStatusDeclined,
        BookingStatus.expired => l.bkStatusExpired,
        BookingStatus.cancelledByGuest => l.bkStatusCancelledGuest,
        BookingStatus.cancelledByHost => l.bkStatusCancelledHost,
        BookingStatus.completed => l.bkStatusCompleted,
        BookingStatus.noShow => l.bkStatusNoShow,
        BookingStatus.disputed => l.bkStatusDisputed,
        BookingStatus.resolved => l.bkStatusResolved,
        BookingStatus.unknown => l.bkStatusUnknown,
      };

  static Color statusColor(BookingStatus s) => switch (s) {
        BookingStatus.requested => AppColors.warningAmber,
        BookingStatus.confirmed => AppColors.successGreen,
        BookingStatus.completed => AppColors.richGold,
        BookingStatus.disputed => AppColors.errorRed,
        BookingStatus.noShow => AppColors.errorRed,
        BookingStatus.resolved => AppColors.infoBlue,
        _ => AppColors.textTertiary,
      };

  static String paymentMode(AppLocalizations l, BookingPaymentMode m) =>
      switch (m) {
        BookingPaymentMode.free => l.uexpFree,
        BookingPaymentMode.cash => l.uexpMethodCash,
        BookingPaymentMode.link => l.uexpMethodLink,
      };

  /// Decimal places of [currency] (mirrors currencyExponent on the server).
  static int exponent(String? currency) {
    const zero = {
      'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf',
      'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf',
    };
    const three = {'bhd', 'jod', 'kwd', 'omr', 'tnd'};
    final c = currency?.toLowerCase();
    if (zero.contains(c)) return 0;
    if (three.contains(c)) return 3;
    return 2;
  }

  /// Minor units → localized money ("R$ 99,80"); free / no currency → "Free".
  static String money(BuildContext context, int minor, String? currency) {
    final l = AppLocalizations.of(context)!;
    if (currency == null || currency.isEmpty) {
      return minor <= 0 ? l.uexpFree : '$minor';
    }
    final digits = exponent(currency);
    final major = minor / _pow10(digits);
    final locale = Localizations.localeOf(context).toString();
    try {
      return NumberFormat.simpleCurrency(
              locale: locale,
              name: currency.toUpperCase(),
              decimalDigits: digits)
          .format(major);
    } catch (_) {
      return '${currency.toUpperCase()} ${major.toStringAsFixed(digits)}';
    }
  }

  static int _pow10(int n) {
    var v = 1;
    for (var i = 0; i < n; i++) {
      v *= 10;
    }
    return v;
  }

  static String total(BuildContext context, BookingPrice p) =>
      money(context, p.totalAmount, p.currency);

  /// "Tue, 12 Mar 2026" .
  static String day(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat.yMMMEd(locale).format(d);
    } catch (_) {
      return DateFormat.yMMMEd().format(d);
    }
  }

  static String time(BuildContext context, DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat.Hm(locale).format(d);
    } catch (_) {
      return DateFormat.Hm().format(d);
    }
  }

  /// "Tue, 12 Mar 2026 14:00".
  static String dateTime(BuildContext context, DateTime d) =>
      '${day(context, d.toLocal())} ${time(context, d.toLocal())}';

  /// "Tue, 12 Mar 2026 · 14:00–16:00" (end date shown when it differs).
  static String range(BuildContext context, DateTime start, DateTime end) {
    final s = start.toLocal();
    final e = end.toLocal();
    final sameDay =
        s.year == e.year && s.month == e.month && s.day == e.day;
    return sameDay
        ? '${day(context, s)} · ${time(context, s)}–${time(context, e)}'
        : '${day(context, s)} ${time(context, s)} – ${day(context, e)} ${time(context, e)}';
  }

  static String percent(BuildContext context, int pct) =>
      ExperienceL10n.percent(context, pct / 100);

  /// Message for a booking callable refusal.
  static String error(AppLocalizations l, BookingFailure f) {
    switch (f.code) {
      case 'slot_full':
        return l.bkErrSlotFull(f.seatsLeft ?? 0);
      case 'already_booked':
        return l.bkErrAlreadyBooked;
      case 'id_document_required':
        return l.bkErrIdRequired;
      case 'host_not_verified':
        return l.bkErrHostNotVerified;
      case 'payment_method_required':
        return l.bkErrPaymentMethodRequired;
      case 'payment_method_not_accepted':
      case 'no_payment_method':
        return l.bkErrPaymentMethodNotAccepted;
      case 'own_experience':
        return l.bkErrOwnExperience;
      case 'not_available':
        return l.bkErrNotAvailable;
      case 'slot_started':
      case 'already_started':
        return l.bkErrSlotStarted;
      case 'slot_closed':
      case 'slot_not_found':
      case 'slot_invalid':
        return l.bkErrSlotClosed;
      case 'experience_not_bookable':
      case 'experience_not_found':
        return l.bkErrNotBookable;
      case 'experience_price_invalid':
        return l.bkErrPriceInvalid;
      case 'host_unavailable':
        return l.bkErrHostUnavailable;
      case 'consent_required':
        return l.bkErrConsentRequired;
      case 'invalid_guests':
      case 'too_many_guests':
        return l.bkErrTooManyGuests(
            f.max ?? BookingConfig.maxGuestsPerBooking);
      case 'account_restricted':
        return l.bkErrAccountRestricted;
      case 'request_expired':
        return l.bkErrRequestExpired;
      case 'not_cancellable':
      case 'invalid_transition':
      case 'not_pending':
      case 'not_confirmed':
      case 'not_disputable':
        return l.bkErrStateChanged;
      case 'invalid_code':
        return l.bkErrInvalidCode;
      case 'outside_checkin_window':
        return l.bkErrOutsideCheckIn;
      case 'too_early':
        return l.bkErrTooEarlyNoShow;
      case 'guest_checked_in':
        return l.bkErrGuestCheckedIn;
      case 'cash_before_meeting':
        return l.bkErrCashBeforeMeeting;
      case 'outside_dispute_window':
        return l.bkErrOutsideDispute;
      case 'reason_required':
        return l.bkErrReasonRequired(BookingConfig.disputeReasonMin);
      case 'booking_not_found':
        return l.bkNotFound;
      case BookingFailure.network:
      case BookingFailure.internal:
        return l.bkErrNetwork;
      default:
        return l.somethingWentWrong;
    }
  }

  static String slotError(AppLocalizations l, SlotError e,
          {int booked = 0}) =>
      switch (e) {
        SlotError.startInPast => l.bkSlotErrPast,
        SlotError.endBeforeStart => l.bkSlotErrEnd,
        SlotError.tooLong => l.bkSlotErrTooLong,
        SlotError.tooFarAhead => l.bkSlotErrTooFar,
        SlotError.capacityRange =>
          l.bkSlotErrCapacity(BookingConfig.slotCapacityMax),
        SlotError.capacityBelowBooked => l.bkSlotErrBelowBooked(booked),
        SlotError.timesFrozen => l.bkTimesFrozen,
      };
}
