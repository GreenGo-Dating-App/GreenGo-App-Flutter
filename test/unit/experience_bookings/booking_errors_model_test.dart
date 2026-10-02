import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/experience_bookings/data/datasources/bookings_remote_datasource.dart';
import 'package:greengo_chat/features/experience_bookings/data/models/booking_model.dart';
import 'package:greengo_chat/features/experience_bookings/domain/booking_failure.dart';
import 'package:greengo_chat/features/experience_bookings/domain/entities/booking.dart';
import 'package:greengo_chat/features/experience_bookings/presentation/booking_l10n.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

FirebaseFunctionsException fx(String code, [Map<String, Object?>? details]) =>
    FirebaseFunctionsException(message: code, code: code, details: details);

void main() {
  group('callable error → BookingFailure', () {
    const map = BookingsRemoteDataSource.failureFrom;

    test('server reason codes are definitive and carry their details', () {
      final full = map(fx('resource-exhausted', {'code': 'slot_full', 'seatsLeft': 2}));
      expect(full.code, 'slot_full');
      expect(full.seatsLeft, 2);
      expect(full.definitive, isTrue);
      final dup = map(fx('already-exists', {'code': 'already_booked', 'bookingId': 'bk_9'}));
      expect(dup.existingBookingId, 'bk_9');
      final many = map(fx('invalid-argument', {'code': 'too_many_guests', 'max': 4}));
      expect(many.max, 4);
    });

    test('internal / transport errors are NOT definitive (reuse requestId)', () {
      expect(map(fx('internal', {'code': 'internal'})).definitive, isFalse);
      expect(map(fx('internal')).definitive, isFalse);
      expect(map(fx('unavailable')).definitive, isFalse);
      expect(map(fx('deadline-exceeded')).definitive, isFalse);
      expect(map(TimeoutException('x')).definitive, isFalse);
      expect(map(Exception('socket')).code, BookingFailure.network);
    });

    test('a refusal without details keeps the transport code', () {
      final f = map(fx('unauthenticated'));
      expect(f.code, 'unauthenticated');
      expect(f.definitive, isTrue);
    });
  });

  group('every createBooking code has its own message (7 locales)', () {
    const codes = [
      'slot_full',
      'already_booked',
      'id_document_required',
      'host_not_verified',
      'payment_method_required',
      'payment_method_not_accepted',
      'own_experience',
      'not_available',
      'slot_started',
      'slot_closed',
      'experience_not_bookable',
      'host_unavailable',
      'consent_required',
      'too_many_guests',
      'experience_price_invalid',
      'account_restricted',
      BookingFailure.network,
    ];
    for (final loc in const ['en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR']) {
      test(loc, () {
        final parts = loc.split('_');
        final l = lookupAppLocalizations(
            Locale(parts.first, parts.length > 1 ? parts[1] : null));
        final generic = l.somethingWentWrong;
        final seen = <String>{};
        for (final c in codes) {
          final msg = BookingL10n.error(l, BookingFailure(c, seatsLeft: 1, max: 4));
          expect(msg, isNot(generic), reason: '$loc: $c');
          expect(msg.trim(), isNotEmpty);
          seen.add(msg);
        }
        expect(seen.length, codes.length, reason: 'distinct messages');
        expect(BookingL10n.error(l, const BookingFailure('weird_new_code')),
            generic);
      });
    }
  });

  group('BookingModel', () {
    final start = DateTime.utc(2026, 11, 2, 15);
    final doc = <String, dynamic>{
      'experienceId': 'e1',
      'slotId': 's1',
      'hostId': 'h',
      'guestId': 'g',
      'guests': 2,
      'status': 'confirmed',
      'requestToBook': false,
      'policy': 'strict',
      'experienceTitle': 'Samba night',
      'slotStart': Timestamp.fromDate(start),
      'slotEnd': Timestamp.fromDate(start.add(const Duration(hours: 3))),
      'price': {'unitAmount': 4990, 'currency': 'brl', 'totalAmount': 9980},
      'payment': {
        'mode': 'link',
        'link': {'type': 'pix', 'value': 'chave@pix.com'},
        'guestMarkedPaidAt': null,
        'hostConfirmedPaidAt': null,
      },
      'refundDue': null,
      'cancellation': null,
      'checkIn': {'at': Timestamp.fromDate(start), 'byUid': 'h'},
      'createdAt': Timestamp.fromDate(start.subtract(const Duration(days: 9))),
    };

    test('parses the Firestore document', () {
      final b = BookingModel.fromMap('bk_1', doc);
      expect(b.status, BookingStatus.confirmed);
      expect(b.policy, CancellationPolicy.strict);
      expect(b.price.totalAmount, 9980);
      expect(b.price.currency, 'brl');
      expect(b.payment.mode, BookingPaymentMode.link);
      expect(b.payment.link?.type, PaymentLinkType.pix);
      // Timestamp.toDate() is local time: compare instants.
      expect(b.checkedInAt!.isAtSameMomentAs(start), isTrue);
      expect(
          b.createdAt!
              .isAtSameMomentAs(start.subtract(const Duration(days: 9))),
          isTrue);
      expect(b.counterpartOf('h'), 'g');
    });

    test('a callable view keeps createdAt / title from the previous copy', () {
      final before = BookingModel.fromMap('bk_1', doc);
      final view = {
        'bookingId': 'bk_1',
        'experienceId': 'e1',
        'slotId': 's1',
        'hostId': 'h',
        'guestId': 'g',
        'guests': 2,
        'status': 'cancelled_by_guest',
        'policy': 'strict',
        'price': {'unitAmount': 4990, 'currency': 'brl', 'totalAmount': 9980},
        'payment': {'mode': 'link', 'link': null, 'guestMarkedPaidAt': null},
        'refundDue': {
          'percent': 100,
          'policyPercent': 100,
          'amount': 9980,
          'currency': 'brl',
          'reason': 'guest_cancelled',
          'decidedAt': '2026-10-01T12:00:00.000Z',
        },
        'slotStart': start.toIso8601String(),
        'slotEnd': start.add(const Duration(hours: 3)).toIso8601String(),
        'checkedInAt': null,
        'dispute': null,
      };
      final after = BookingModel.fromView(view, previous: before);
      expect(after.status, BookingStatus.cancelledByGuest);
      expect(after.experienceTitle, 'Samba night');
      expect(after.createdAt, before.createdAt);
      expect(after.refundDue?.amount, 9980);
      expect(after.refundDue?.decidedAt, DateTime.utc(2026, 10, 1, 12));
      expect(after.slotStart, start);
    });

    test('unknown statuses never act; slots parse seats', () {
      expect(BookingStatus.fromWire('refunded'), BookingStatus.unknown);
      final s = BookingModel.slotFromMap('e1', 's1', {
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(start.add(const Duration(hours: 1))),
        'capacity': 8,
        'bookedCount': 6,
        'status': 'open',
      });
      expect(s.seatsLeft, 2);
      expect(s.isOpen, isTrue);
      final payload = BookingModel.slotPayload(
          SlotDraft(start: start, end: start, capacity: 3),
          existing: s);
      expect(payload.containsKey('bookedCount'), isFalse,
          reason: 'never send the server-owned counter on update');
      expect(BookingModel.slotPayload(
              SlotDraft(start: start, end: start, capacity: 3))['bookedCount'],
          0);
    });
  });
}
