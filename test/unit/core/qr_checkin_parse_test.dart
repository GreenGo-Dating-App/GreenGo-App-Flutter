import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/qr_checkin_service.dart';
import 'package:greengo_chat/core/widgets/met_in_person_badge.dart';

void main() {
  group('ScannedCheckInCode.parse', () {
    test('signed event ticket', () {
      final c = ScannedCheckInCode.parse('greengo:ev:ev1:u1:abcdefgh');
      expect(c, isA<EventTicketCode>());
      c as EventTicketCode;
      expect(c.eventId, 'ev1');
      expect(c.userId, 'u1');
      expect(c.signed, isTrue);
    });

    test('legacy event ticket (pre-4.4.0) still parses, unsigned', () {
      final c = ScannedCheckInCode.parse('greengo:{"e":"ev1","u":"u1"}');
      expect(c, isA<EventTicketCode>());
      expect((c as EventTicketCode).signed, isFalse);
    });

    test('experience booking code', () {
      final c = ScannedCheckInCode.parse('greengo:checkin:bk_123:ABCD2345');
      expect(c, isA<BookingTicketCode>());
      c as BookingTicketCode;
      expect(c.bookingId, 'bk_123');
      expect(c.code, 'ABCD2345');
    });

    test('rejects anything else', () {
      for (final raw in [
        null,
        '',
        'https://example.com',
        'greengo:ev:ev1:u1:SHORT',
        'greengo:ev:ev1:u1:ABCDEFGI', // I is not in the alphabet
        'greengo:ev:ev/1:u1:ABCDEFGH',
        'greengo:checkin:bk_1:SHORT',
        'greengo:{"e":"ev1"}',
      ]) {
        expect(ScannedCheckInCode.parse(raw), isNull, reason: '$raw');
      }
    });
  });

  test('met-in-person pair id is the same whatever the order (matches server)',
      () {
    expect(MetInPersonBadge.pairIdOf('b', 'a'), 'a_b');
    expect(MetInPersonBadge.pairIdOf('a', 'b'), 'a_b');
  });
}
