import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/experience_bookings/domain/booking_rules.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';

final DateTime t0 = DateTime.utc(2026, 10, 1, 12);

Booking booking({
  BookingStatus status = BookingStatus.confirmed,
  CancellationPolicy policy = CancellationPolicy.moderate,
  DateTime? start,
  Duration length = const Duration(hours: 2),
  DateTime? createdAt,
  BookingPaymentMode mode = BookingPaymentMode.link,
  DateTime? hostPaid,
  DateTime? guestPaid,
  DateTime? checkedIn,
  int total = 10000,
  DateTime? requestExpiresAt,
}) {
  final s = start ?? t0.add(const Duration(days: 10));
  return Booking(
    id: 'bk_1',
    experienceId: 'e1',
    slotId: 's1',
    hostId: 'host',
    guestId: 'guest',
    guests: 2,
    status: status,
    slotStart: s,
    slotEnd: s.add(length),
    policy: policy,
    price: mode == BookingPaymentMode.free
        ? BookingPrice.free
        : BookingPrice(unitAmount: total ~/ 2, totalAmount: total, currency: 'eur'),
    payment: BookingPayment(
        mode: mode, hostConfirmedPaidAt: hostPaid, guestMarkedPaidAt: guestPaid),
    createdAt: createdAt ?? t0.subtract(const Duration(days: 30)),
    checkedInAt: checkedIn,
    requestExpiresAt: requestExpiresAt,
  );
}

void main() {
  group('refund parity with the server (shared fixture)', () {
    // Same file functions/__tests__/unit/experienceBookings.test.ts reads.
    final fixture = jsonDecode(
            File('functions/__tests__/fixtures/booking_refund_cases.json')
                .readAsStringSync()) as Map<String, dynamic>;
    final start = t0.add(const Duration(days: 60));

    for (final c in (fixture['refundFor'] as List).cast<Map<String, dynamic>>()) {
      test('refundFor ${c['policy']} ${c['beforeStartMs']} ms before, '
          'booked ${c['sinceBookingMs']} ms earlier, by ${c['by']}', () {
        final now = start.subtract(Duration(milliseconds: c['beforeStartMs'] as int));
        final got = BookingRules.refundPercent(
          CancellationPolicy.tryWire(c['policy']),
          now: now,
          slotStart: start,
          bookedAt: now.subtract(Duration(milliseconds: c['sinceBookingMs'] as int)),
          byHost: c['by'] == 'host',
        );
        expect(got, c['expected']);
      });
    }

    final dueCases =
        (fixture['refundDueFor'] as List).cast<Map<String, dynamic>>();
    for (var i = 0; i < dueCases.length; i++) {
      final c = dueCases[i];
      test('refundDueFor case $i', () {
        final p = c['price'] as Map<String, dynamic>?;
        final pay = c['payment'] as Map<String, dynamic>;
        final got = BookingRules.refundDue(
          p == null
              ? null
              : BookingPrice(
                  unitAmount: p['unitAmount'] as int,
                  totalAmount: p['totalAmount'] as int,
                  currency: p['currency'] as String?,
                ),
          BookingPayment(
            mode: BookingPaymentMode.fromWire(pay['mode']),
            hostConfirmedPaidAt: pay['hostConfirmedPaid'] == true ? t0 : null,
          ),
          c['percent'] as int,
          c['reason'] as String,
        );
        final want = c['expected'] as Map<String, dynamic>?;
        if (want == null) {
          expect(got, isNull);
        } else {
          expect(got, isNotNull);
          expect(got!.percent, want['percent']);
          expect(got.policyPercent, want['policyPercent']);
          expect(got.amount, want['amount']);
          expect(got.currency, want['currency']);
          expect(got.reason, want['reason']);
        }
      });
    }
  });

  group('cancel preview', () {
    test('guest, moderate, 3 days before → 50% of the total', () {
      final b = booking(start: t0.add(const Duration(days: 3)));
      final r = BookingRules.cancelPreview(b, t0, byHost: false)!;
      expect(r.percent, 50);
      expect(r.amount, 5000);
      // Link payment nobody marked as made: owed only if the guest paid.
      expect(r.reason, 'guest_cancelled_link_unconfirmed');
      expect(r.linkUnconfirmed, isTrue);
    });

    test('host always owes 100%', () {
      final b = booking(
          start: t0.add(const Duration(hours: 2)),
          policy: CancellationPolicy.strict);
      expect(BookingRules.cancelPreview(b, t0, byHost: true)!.percent, 100);
    });

    test('unpaid cash owes nothing; a request owes nothing', () {
      final cash = booking(mode: BookingPaymentMode.cash);
      final r = BookingRules.cancelPreview(cash, t0, byHost: true)!;
      expect(r.percent, 0);
      expect(r.policyPercent, 100);
      expect(r.cashUnpaid, isTrue);
      expect(
          BookingRules.cancelPreview(
              booking(status: BookingStatus.requested), t0,
              byHost: false),
          isNull);
      expect(
          BookingRules.cancelPreview(booking(mode: BookingPaymentMode.free), t0,
              byHost: false),
          isNull);
    });

    test('grace: booked < 24 h ago and start > 48 h away → 100% even strict',
        () {
      final b = booking(
          policy: CancellationPolicy.strict,
          start: t0.add(const Duration(days: 3)),
          createdAt: t0.subtract(const Duration(hours: 2)));
      expect(BookingRules.cancelPreview(b, t0, byHost: false)!.percent, 100);
    });
  });

  group('what can be done when', () {
    test('cancel only before the start, requested / confirmed only', () {
      final b = booking(start: t0.add(const Duration(hours: 1)));
      expect(BookingRules.canCancel(b, t0), isTrue);
      expect(BookingRules.canCancel(b, t0.add(const Duration(hours: 1))), isFalse);
      expect(
          BookingRules.canCancel(
              booking(status: BookingStatus.completed), t0),
          isFalse);
    });

    test('respond: requested, before expiry and start', () {
      final b = booking(
          status: BookingStatus.requested,
          requestExpiresAt: t0.add(const Duration(hours: 1)));
      expect(BookingRules.canRespond(b, t0), isTrue);
      expect(BookingRules.canRespond(b, t0.add(const Duration(hours: 1))),
          isFalse);
      expect(BookingRules.canRespond(booking(), t0), isFalse);
    });

    test('check-in window: 2 h before start .. 12 h after end', () {
      final b = booking(start: t0);
      expect(
          BookingRules.canCheckIn(b, t0.subtract(const Duration(hours: 2))),
          isTrue);
      expect(
          BookingRules.canCheckIn(
              b, t0.subtract(const Duration(hours: 2, minutes: 1))),
          isFalse);
      expect(BookingRules.canCheckIn(b, t0.add(const Duration(hours: 14))),
          isTrue);
      expect(
          BookingRules.canCheckIn(
              b, t0.add(const Duration(hours: 14, minutes: 1))),
          isFalse);
      expect(BookingRules.canCheckIn(booking(start: t0, checkedIn: t0), t0),
          isFalse);
    });

    test('no-show from start + 30 min, not after check-in', () {
      final b = booking(start: t0);
      expect(BookingRules.canMarkNoShow(b, t0.add(const Duration(minutes: 29))),
          isFalse);
      expect(BookingRules.canMarkNoShow(b, t0.add(const Duration(minutes: 30))),
          isTrue);
      expect(
          BookingRules.canMarkNoShow(
              booking(start: t0, checkedIn: t0), t0.add(const Duration(hours: 1))),
          isFalse);
    });

    test('dispute from the start until end + 24 h (confirmed / no-show)', () {
      final b = booking(start: t0);
      expect(BookingRules.canDispute(b, t0.subtract(const Duration(minutes: 1))),
          isFalse);
      expect(BookingRules.canDispute(b, t0), isTrue);
      expect(BookingRules.canDispute(b, t0.add(const Duration(hours: 26))),
          isTrue);
      expect(
          BookingRules.canDispute(
              b, t0.add(const Duration(hours: 26, minutes: 1))),
          isFalse);
      expect(
          BookingRules.canDispute(
              booking(start: t0, status: BookingStatus.noShow),
              t0.add(const Duration(hours: 3))),
          isTrue);
      expect(
          BookingRules.canDispute(
              booking(start: t0, status: BookingStatus.completed),
              t0.add(const Duration(hours: 3))),
          isFalse);
    });

    test('paid marks: guest link only; host cash only once met', () {
      expect(BookingRules.guestCanMarkPaid(booking()), isTrue);
      expect(BookingRules.guestCanMarkPaid(booking(guestPaid: t0)), isFalse);
      expect(BookingRules.guestCanMarkPaid(booking(mode: BookingPaymentMode.cash)),
          isFalse);
      expect(
          BookingRules.guestCanMarkPaid(
              booking(status: BookingStatus.requested)),
          isFalse);
      final cash = booking(mode: BookingPaymentMode.cash, start: t0);
      expect(
          BookingRules.hostCanConfirmPaid(
              cash, t0.subtract(const Duration(minutes: 1))),
          isFalse);
      expect(BookingRules.hostCanConfirmPaid(cash, t0), isTrue);
      expect(
          BookingRules.hostCanConfirmPaid(
              booking(mode: BookingPaymentMode.cash,
                  start: t0.add(const Duration(hours: 1)), checkedIn: t0),
              t0),
          isTrue);
      expect(BookingRules.hostCanConfirmPaid(booking(), t0), isTrue);
      expect(BookingRules.hostCanConfirmPaid(booking(hostPaid: t0), t0),
          isFalse);
      expect(
          BookingRules.hostCanConfirmPaid(
              booking(mode: BookingPaymentMode.free), t0),
          isFalse);
    });

    test('host reviews the guest after check-in / completion / no-show, 30 days',
        () {
      final end = t0.add(const Duration(hours: 2));
      expect(
          BookingRules.hostCanReviewGuest(
              booking(start: t0, status: BookingStatus.completed), end),
          isTrue);
      expect(
          BookingRules.hostCanReviewGuest(
              booking(start: t0, checkedIn: t0), end),
          isTrue);
      expect(BookingRules.hostCanReviewGuest(booking(start: t0), end), isFalse);
      expect(
          BookingRules.hostCanReviewGuest(
              booking(start: t0, status: BookingStatus.noShow),
              end.add(const Duration(days: 30))),
          isFalse);
    });
  });

  group('check-in QR + request ids', () {
    test('parses the server payload, rejects others', () {
      final p = BookingRules.parseCheckInQr('greengo:checkin:bk_abc123:abcd2345');
      expect(p?.bookingId, 'bk_abc123');
      expect(p?.code, 'ABCD2345');
      expect(BookingRules.parseCheckInQr('greengo:ticket:x:y'), isNull);
      expect(BookingRules.parseCheckInQr('greengo:checkin:bk_1:SHORT'), isNull);
      // I / L / O / U are not in the server alphabet.
      expect(BookingRules.parseCheckInQr('greengo:checkin:bk_1:ILOUABCD'), isNull);
      expect(BookingRules.parseCheckInQr('greengo:checkin::ABCD2345'), isNull);
    });

    test('request ids match the server pattern and differ', () {
      final r = Random(1);
      final a = BookingRules.newRequestId(r);
      final b = BookingRules.newRequestId(r);
      expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(a), isTrue);
      expect(a, isNot(b));
    });
  });

  group('slot validation', () {
    final now = t0;
    SlotDraft d(Duration fromNow, Duration length, int capacity) => SlotDraft(
        start: now.add(fromNow),
        end: now.add(fromNow).add(length),
        capacity: capacity);

    test('a good slot passes', () {
      expect(
          BookingRules.validateSlot(
              d(const Duration(days: 1), const Duration(hours: 2), 8), now),
          isEmpty);
    });

    test('past start, end before start, too long, too far, capacity', () {
      expect(
          BookingRules.validateSlot(
              d(const Duration(hours: -1), const Duration(hours: 2), 8), now),
          contains(SlotError.startInPast));
      expect(
          BookingRules.validateSlot(
              d(const Duration(days: 1), Duration.zero, 8), now),
          contains(SlotError.endBeforeStart));
      expect(
          BookingRules.validateSlot(
              d(const Duration(days: 1), const Duration(hours: 25), 8), now),
          contains(SlotError.tooLong));
      expect(
          BookingRules.validateSlot(
              d(const Duration(days: 400), const Duration(hours: 2), 8), now),
          contains(SlotError.tooFarAhead));
      expect(
          BookingRules.validateSlot(
              d(const Duration(days: 1), const Duration(hours: 2), 0), now),
          contains(SlotError.capacityRange));
      expect(
          BookingRules.validateSlot(
              d(const Duration(days: 1), const Duration(hours: 2), 501), now),
          contains(SlotError.capacityRange));
    });

    test('a booked slot keeps its times and at least its booked seats', () {
      final existing = ExperienceSlot(
        id: 's1',
        experienceId: 'e1',
        start: now.add(const Duration(days: 2)),
        end: now.add(const Duration(days: 2, hours: 2)),
        capacity: 10,
        bookedCount: 4,
      );
      expect(
          BookingRules.validateSlot(
              SlotDraft(start: existing.start, end: existing.end, capacity: 6),
              now,
              existing: existing),
          isEmpty);
      expect(
          BookingRules.validateSlot(
              SlotDraft(start: existing.start, end: existing.end, capacity: 3),
              now,
              existing: existing),
          contains(SlotError.capacityBelowBooked));
      expect(
          BookingRules.validateSlot(
              SlotDraft(
                  start: existing.start.add(const Duration(hours: 1)),
                  end: existing.end.add(const Duration(hours: 1)),
                  capacity: 10),
              now,
              existing: existing),
          contains(SlotError.timesFrozen));
    });
  });
}
