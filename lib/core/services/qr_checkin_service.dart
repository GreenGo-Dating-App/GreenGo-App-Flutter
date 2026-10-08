import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/app_localizations.dart';

/// A GreenGo QR code read at a door.
sealed class ScannedCheckInCode {
  const ScannedCheckInCode(this.raw);
  final String raw;

  static const String eventSignedPrefix = 'greengo:ev:';
  static const String bookingPrefix = 'greengo:checkin:';

  /// Paid ticket (events + experiences): `greengo:tk:{ticketId}:{sig}`,
  /// verified + re-checked (refunds) by the server; single use per ticket.
  static const String paidTicketPrefix = 'greengo:tk:';
  static final RegExp _id = RegExp(r'^[A-Za-z0-9_-]{1,128}$');
  static final RegExp _code = RegExp(r'^[ABCDEFGHJKMNPQRSTVWXYZ0-9]{8}$');

  /// Parses an event ticket (signed `greengo:ev:{event}:{user}:{code}` or the
  /// legacy JSON `greengo:{"e":..,"u":..}`) or an experience booking code
  /// (`greengo:checkin:{bookingId}:{code}`). Null for anything else.
  static ScannedCheckInCode? parse(String? input) {
    final raw = input?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith(paidTicketPrefix)) {
      final rest = raw.substring(paidTicketPrefix.length);
      final i = rest.lastIndexOf(':');
      if (i <= 0) return null;
      final id = rest.substring(0, i);
      if (!_id.hasMatch(id) || rest.length - i - 1 < 10) return null;
      return PaidTicketCode(raw, ticketId: id);
    }
    if (raw.startsWith(eventSignedPrefix)) {
      final p = raw.substring(eventSignedPrefix.length).split(':');
      if (p.length != 3) return null;
      final code = p[2].toUpperCase();
      if (!_id.hasMatch(p[0]) || !_id.hasMatch(p[1]) || !_code.hasMatch(code)) {
        return null;
      }
      return EventTicketCode(raw, eventId: p[0], userId: p[1], signed: true);
    }
    if (raw.startsWith(bookingPrefix)) {
      final rest = raw.substring(bookingPrefix.length);
      final i = rest.lastIndexOf(':');
      if (i <= 0) return null;
      final id = rest.substring(0, i);
      final code = rest.substring(i + 1).toUpperCase();
      if (!_id.hasMatch(id) || !_code.hasMatch(code)) return null;
      return BookingTicketCode(raw, bookingId: id, code: code);
    }
    if (raw.startsWith('greengo:{')) {
      final m = RegExp(r'"e"\s*:\s*"([^"]+)".*"u"\s*:\s*"([^"]+)"').firstMatch(raw);
      if (m == null || !_id.hasMatch(m[1]!) || !_id.hasMatch(m[2]!)) return null;
      return EventTicketCode(raw, eventId: m[1]!, userId: m[2]!, signed: false);
    }
    return null;
  }
}

class EventTicketCode extends ScannedCheckInCode {
  const EventTicketCode(super.raw,
      {required this.eventId, required this.userId, required this.signed});
  final String eventId;
  final String userId;
  final bool signed;
}

class PaidTicketCode extends ScannedCheckInCode {
  const PaidTicketCode(super.raw, {required this.ticketId});
  final String ticketId;
}

class BookingTicketCode extends ScannedCheckInCode {
  const BookingTicketCode(super.raw,
      {required this.bookingId, required this.code});
  final String bookingId;
  final String code;
}

/// What the server answered at the door.
class CheckInOutcome {
  const CheckInOutcome({
    required this.approved,
    this.alreadyCheckedIn = false,
    this.name = '',
    this.photoUrl,
    this.guestCount = 0,
    this.reason,
    this.ticketTypeName,
    this.partySize = 1,
  });

  /// Paid tickets: the ticket type (VIP, General…) shown big at the door.
  final String? ticketTypeName;

  /// Group tickets (per-group experiences): people admitted by this QR.
  final int partySize;

  /// Checked in now (true) or refused (false). Already-in counts as refused
  /// at the door, with [alreadyCheckedIn] set.
  final bool approved;
  final bool alreadyCheckedIn;
  final String name;
  final String? photoUrl;
  final int guestCount;

  /// Server reason code when refused (invalid_code, wrong_event, ...).
  final String? reason;

  /// The line under DENIED on the result screen.
  String reasonText(AppLocalizations l10n) {
    if (alreadyCheckedIn) return l10n.eventAlreadyCheckedIn(name);
    switch (reason) {
      case 'not_scanner':
      case 'not_host':
        return l10n.qrScanNotAuthorized;
      case 'wrong_event':
      case 'wrong_experience':
        return l10n.checkinWrongPlace;
      case 'outside_checkin_window':
        return l10n.checkinOutsideWindow;
      case 'not_confirmed':
      case 'not_going':
      case 'not_registered':
        return l10n.checkinNotConfirmed;
      case 'legacy_ticket_rejected':
        return l10n.checkinUpdateApp;
      case 'ticket_not_valid':
        return l10n.tpScanTicketNotValid;
      case 'ticket_required':
      case 'not_paid':
        return l10n.tpScanNotPaid;
      case 'network':
        return l10n.checkinNetwork;
      default:
        return l10n.eventInvalidTicket;
    }
  }
}

/// QR check-in, server-verified, for events AND experiences.
///
///  * Tickets are SIGNED by the server (an HMAC only it can produce) and
///    cached on the device, so they still show at a venue without signal.
///  * The door never writes Firestore: `checkInEventAttendee` /
///    `checkInBooking` verify the code, the scanner's rights and the time
///    window, check the person in and record that host and guest met in
///    person (`met_in_person`).
class QrCheckinService {
  QrCheckinService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  static String _eventKey(String eventId, String uid) =>
      'ticket_ev_v1_${eventId}_$uid';
  static String _bookingKey(String bookingId) => 'ticket_bk_v1_$bookingId';

  Future<Map<String, dynamic>> _call(String name, Map<String, dynamic> data) async {
    final res = await _functions
        .httpsCallable(name,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)))
        .call<Object?>(data);
    final d = res.data;
    return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
  }

  static String _reasonOf(Object e) {
    if (e is FirebaseFunctionsException) {
      final d = e.details;
      if (d is Map && d['code'] is String) return d['code'] as String;
      if (e.code == 'unavailable' || e.code == 'deadline-exceeded') {
        return 'network';
      }
      return e.code;
    }
    return 'network';
  }

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  /// The QR payload of the user's ticket for [eventId]: the cached signed
  /// ticket, else a fresh one from the server (then cached), else - offline on
  /// first open - the legacy unsigned ticket, which the server still accepts
  /// during the transition (and records as an unverified meeting).
  Future<String> eventTicketPayload(String eventId, String uid,
      {required String legacyPayload}) async {
    final prefs = await _prefs();
    final cached = prefs?.getString(_eventKey(eventId, uid));
    if (cached != null && _isServerTicket(cached)) {
      return cached;
    }
    try {
      final m = await _call('getEventTicketCode', {'eventId': eventId});
      final p = m['qrPayload'] as String?;
      if (p != null && _isServerTicket(p)) {
        await prefs?.setString(_eventKey(eventId, uid), p);
        return p;
      }
    } catch (e) {
      debugPrint('[QrCheckin] event ticket for $eventId: $e');
    }
    return legacyPayload;
  }

  static bool _isServerTicket(String v) =>
      v.startsWith(ScannedCheckInCode.eventSignedPrefix) ||
      v.startsWith(ScannedCheckInCode.paidTicketPrefix);

  /// The signed event ticket already cached on this device, or null.
  Future<String?> cachedEventTicket(String eventId, String uid) async {
    final v = (await _prefs())?.getString(_eventKey(eventId, uid));
    return v != null && _isServerTicket(v) ? v : null;
  }

  /// Last booking check-in QR shown on this device (offline fallback).
  Future<String?> cachedBookingPayload(String bookingId) async =>
      (await _prefs())?.getString(_bookingKey(bookingId));

  Future<void> cacheBookingPayload(String bookingId, String payload) async {
    if (!payload.startsWith(ScannedCheckInCode.bookingPrefix) &&
        !payload.startsWith(ScannedCheckInCode.paidTicketPrefix)) {
      return;
    }
    await (await _prefs())?.setString(_bookingKey(bookingId), payload);
  }

  /// Door check-in of an event ticket. [eventId] = the event the scanner has
  /// open (refuses tickets of other events); null from the QR hub.
  Future<CheckInOutcome> checkInEvent(EventTicketCode code, {String? eventId}) async {
    try {
      final m = await _call('checkInEventAttendee', {
        'payload': code.raw,
        if (eventId != null) 'eventId': eventId,
      });
      final already = m['alreadyCheckedIn'] == true;
      return CheckInOutcome(
        approved: !already,
        alreadyCheckedIn: already,
        name: (m['userName'] as String?) ?? '',
        photoUrl: m['userPhotoUrl'] as String?,
        guestCount: (m['guestCount'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return CheckInOutcome(approved: false, reason: _reasonOf(e));
    }
  }

  /// Door check-in of a PAID ticket (event or experience); each QR works once.
  Future<CheckInOutcome> checkInPaidTicket(PaidTicketCode code,
      {String? eventId, String? experienceId}) async {
    try {
      final m = await _call('checkInTicket', {
        'payload': code.raw,
        if (eventId != null) 'eventId': eventId,
        if (experienceId != null) 'experienceId': experienceId,
      });
      final already = m['alreadyCheckedIn'] == true;
      return CheckInOutcome(
        approved: !already,
        alreadyCheckedIn: already,
        name: (m['userName'] as String?) ?? (m['guestName'] as String?) ?? '',
        photoUrl: (m['userPhotoUrl'] as String?) ?? (m['guestPhotoUrl'] as String?),
        guestCount: ((m['partySize'] as num?)?.toInt() ?? 1) - 1,
        ticketTypeName: m['ticketTypeName'] as String?,
        partySize: (m['partySize'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      return CheckInOutcome(approved: false, reason: _reasonOf(e));
    }
  }

  /// Door check-in of an experience booking. [experienceId] = the experience
  /// the door scanner has open (refuses codes of other experiences).
  Future<CheckInOutcome> checkInBooking(BookingTicketCode code,
      {String? experienceId}) async {
    try {
      final m = await _call('checkInBooking', {
        'bookingId': code.bookingId,
        'code': code.code,
        if (experienceId != null) 'experienceId': experienceId,
      });
      final already = m['alreadyCheckedIn'] == true;
      return CheckInOutcome(
        approved: !already,
        alreadyCheckedIn: already,
        name: (m['guestName'] as String?) ?? '',
        photoUrl: m['guestPhotoUrl'] as String?,
        guestCount: (m['guests'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      return CheckInOutcome(approved: false, reason: _reasonOf(e));
    }
  }
}
