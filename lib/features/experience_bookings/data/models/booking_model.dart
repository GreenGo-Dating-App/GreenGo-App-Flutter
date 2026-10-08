import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../user_experiences/data/models/user_experience_model.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../domain/entities/booking.dart';

/// Callable results arrive as Map<Object?, Object?> (web: LinkedMap); this
/// normalises any map to Map<String, dynamic> (null for non-maps).
Map<String, dynamic>? bookingMap(Object? v) {
  if (v is! Map) return null;
  return {for (final e in v.entries) '${e.key}': e.value};
}

int _int(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

String? _str(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

/// (De)serialisation of bookings: the Firestore document (Timestamps) and the
/// callables' `bookingView` (ISO strings, no createdAt / title / cancellation).
class BookingModel {
  const BookingModel._();

  static BookingPrice _price(Object? raw) {
    final p = bookingMap(raw);
    if (p == null) return BookingPrice.free;
    return BookingPrice(
      unitAmount: _int(p['unitAmount']),
      totalAmount: _int(p['totalAmount']),
      currency: _str(p['currency'])?.toLowerCase(),
    );
  }

  static BookingPayment _payment(Object? raw) {
    final p = bookingMap(raw);
    if (p == null) return const BookingPayment();
    final link = bookingMap(p['link']);
    return BookingPayment(
      mode: BookingPaymentMode.fromWire(p['mode']),
      link: link != null && _str(link['value']) != null
          ? PaymentLink(
              type: PaymentLinkType.fromWire(link['type']),
              value: _str(link['value'])!,
            )
          : null,
      guestMarkedPaidAt: experienceDateFrom(p['guestMarkedPaidAt']),
      hostConfirmedPaidAt: experienceDateFrom(p['hostConfirmedPaidAt']),
      provider: _str(p['provider']),
      status: _str(p['status']),
      orderId: _str(p['orderId']),
    );
  }

  static RefundDue? _refund(Object? raw) {
    final r = bookingMap(raw);
    if (r == null) return null;
    return RefundDue(
      percent: _int(r['percent']),
      policyPercent: _int(r['policyPercent'], _int(r['percent'])),
      amount: _int(r['amount']),
      currency: _str(r['currency'])?.toLowerCase(),
      reason: _str(r['reason']) ?? '',
      decidedAt: experienceDateFrom(r['decidedAt']),
    );
  }

  static BookingDispute? _dispute(Object? raw) {
    final d = bookingMap(raw);
    if (d == null) return null;
    final res = bookingMap(d['resolution']);
    return BookingDispute(
      isOpen: d['status'] != 'resolved',
      openedAt: experienceDateFrom(d['openedAt']),
      refundPercent: res == null ? null : _int(res['refundPercent']),
      hostAction: res == null ? null : _str(res['hostAction']),
      note: res == null ? null : _str(res['note']),
    );
  }

  /// Firestore `bookings/{id}`.
  static Booking fromMap(String id, Map<String, dynamic> d) {
    final cancellation = bookingMap(d['cancellation']);
    final checkIn = bookingMap(d['checkIn']);
    final start = experienceDateFrom(d['slotStart']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return Booking(
      id: id,
      experienceId: d['experienceId'] as String? ?? '',
      slotId: d['slotId'] as String? ?? '',
      hostId: d['hostId'] as String? ?? '',
      guestId: d['guestId'] as String? ?? '',
      guests: _int(d['guests'], 1),
      status: BookingStatus.fromWire(d['status']),
      slotStart: start,
      slotEnd: experienceDateFrom(d['slotEnd']) ?? start,
      requestToBook: d['requestToBook'] == true,
      policy: CancellationPolicy.tryWire(d['policy']) ??
          CancellationPolicy.fallback,
      experienceTitle: _str(d['experienceTitle']),
      price: _price(d['price']),
      payment: _payment(d['payment']),
      refundDue: _refund(d['refundDue']),
      cancelledBy: cancellation == null ? null : _str(cancellation['by']),
      cancellationReason:
          cancellation == null ? null : _str(cancellation['reason']),
      checkedInAt: checkIn == null
          ? experienceDateFrom(d['checkedInAt'])
          : experienceDateFrom(checkIn['at']),
      dispute: _dispute(d['dispute']),
      requestExpiresAt: experienceDateFrom(d['requestExpiresAt']),
      createdAt: experienceDateFrom(d['createdAt']),
      confirmedAt: experienceDateFrom(d['confirmedAt']),
    );
  }

  static Booking fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      fromMap(doc.id, doc.data() ?? const {});

  /// A callable's booking view. Fields the view does not carry (createdAt,
  /// title, cancellation) come from [previous] when given.
  static Booking fromView(Object? raw, {Booking? previous, String? title}) {
    final v = bookingMap(raw) ?? const <String, dynamic>{};
    final base = fromMap(
      _str(v['bookingId']) ?? previous?.id ?? '',
      {
        ...v,
        'experienceTitle': title ?? previous?.experienceTitle,
      },
    );
    if (previous == null) return base;
    return Booking(
      id: base.id.isEmpty ? previous.id : base.id,
      experienceId:
          base.experienceId.isEmpty ? previous.experienceId : base.experienceId,
      slotId: base.slotId.isEmpty ? previous.slotId : base.slotId,
      hostId: base.hostId.isEmpty ? previous.hostId : base.hostId,
      guestId: base.guestId.isEmpty ? previous.guestId : base.guestId,
      guests: v['guests'] is num ? base.guests : previous.guests,
      status: base.status == BookingStatus.unknown && v['status'] == null
          ? previous.status
          : base.status,
      slotStart: v['slotStart'] == null ? previous.slotStart : base.slotStart,
      slotEnd: v['slotEnd'] == null ? previous.slotEnd : base.slotEnd,
      requestToBook: base.requestToBook,
      policy: v['policy'] == null ? previous.policy : base.policy,
      experienceTitle: base.experienceTitle ?? previous.experienceTitle,
      price: v['price'] == null ? previous.price : base.price,
      payment: v['payment'] == null ? previous.payment : base.payment,
      refundDue: base.refundDue,
      cancelledBy: previous.cancelledBy,
      cancellationReason: previous.cancellationReason,
      checkedInAt: base.checkedInAt ?? previous.checkedInAt,
      dispute: base.dispute ?? previous.dispute,
      requestExpiresAt: base.requestExpiresAt,
      createdAt: previous.createdAt,
      confirmedAt: previous.confirmedAt,
    );
  }

  // ── slots ──

  static ExperienceSlot slotFromMap(
      String experienceId, String id, Map<String, dynamic> d) {
    final start = experienceDateFrom(d['start']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return ExperienceSlot(
      id: id,
      experienceId: experienceId,
      start: start,
      end: experienceDateFrom(d['end']) ?? start,
      capacity: _int(d['capacity'], 1),
      bookedCount: _int(d['bookedCount']),
      cancelled: d['status'] == 'cancelled',
    );
  }

  /// The client-writable slot fields (the rules: start, end, capacity,
  /// bookedCount, status, createdAt, updatedAt). An UPDATE never sends
  /// bookedCount (server-owned; a stale copy would be refused) — the merge
  /// keeps the stored value.
  static Map<String, dynamic> slotPayload(SlotDraft d,
          {ExperienceSlot? existing}) =>
      {
        'start': Timestamp.fromDate(d.start),
        'end': Timestamp.fromDate(d.end),
        'capacity': d.capacity,
        if (existing == null) 'bookedCount': 0,
        if (existing == null) 'status': 'open',
        if (existing == null) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ── guest reviews ──

  static GuestReview guestReviewFromMap(String bookingId, Map<String, dynamic> d) =>
      GuestReview(
        bookingId: bookingId,
        hostId: d['hostId'] as String? ?? '',
        guestId: d['guestId'] as String? ?? '',
        experienceId: d['experienceId'] as String? ?? '',
        rating: _int(d['rating'], 1).clamp(1, 5),
        comment: d['comment'] as String? ?? '',
        status: _str(d['status']) ?? 'held',
        createdAt: experienceDateFrom(d['createdAt']),
      );
}
