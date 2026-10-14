import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/guest_identity.dart';
import 'package:greengo_chat/features/events/data/models/event_attendee_model.dart';
import 'package:greengo_chat/features/events/data/models/event_model.dart';
import 'package:greengo_chat/features/events/domain/entities/event.dart';
import 'package:greengo_chat/features/experience_bookings/data/models/booking_model.dart';
import 'package:greengo_chat/features/user_experiences/data/models/user_experience_model.dart';

import '../../support/events_fixtures.dart';

/// Shared-link guest booking (functions/src/guest): the host opt-in
/// (`guestsAllowed`, public events only) and how guests are recognised in
/// attendee / booking data.
void main() {
  final guestKey = 'guest_${'a1' * 20}';

  group('guest key', () {
    test('only the server-issued shape is a guest', () {
      expect(isGuestUserId(guestKey), isTrue);
      expect(isGuestUserId('AbC123xyzUSERuid0001xyzABCD'), isFalse);
      expect(isGuestUserId('guest_ABC'), isFalse);
      expect(isGuestUserId('guest_${'A1' * 20}'), isFalse);
      expect(isGuestUserId(null), isFalse);
    });
  });

  group('Event.guestBookingAllowed <-> guestsAllowed', () {
    test('round-trips on a public event, defaults to off', () {
      final e = EventFixtures.build().copyWith(guestBookingAllowed: true);
      final json = EventModel.fromEntity(e).toJson();
      expect(json['guestsAllowed'], isTrue);
      expect(EventModel.fromJson({...json, 'id': 'x'}).guestBookingAllowed,
          isTrue);
      final off = EventModel.fromEntity(EventFixtures.build()).toJson();
      expect(off['guestsAllowed'], isFalse);
      expect(
          EventModel.fromJson({...off, 'id': 'x'}..remove('guestsAllowed'))
              .guestBookingAllowed,
          isFalse);
    });

    test('a private event never writes guestsAllowed: true (rules refuse it)',
        () {
      final e = EventFixtures.build().copyWith(
          guestBookingAllowed: true, visibility: EventVisibility.private);
      expect(EventModel.fromEntity(e).toJson()['guestsAllowed'], isFalse);
    });

    test('the plus-ones getter is unchanged', () {
      final e = EventFixtures.build()
          .copyWith(guestsAllowedPerAttendee: 2, guestBookingAllowed: false);
      expect(e.guestsAllowed, isTrue);
      expect(e.guestBookingAllowed, isFalse);
    });
  });

  group('guest attendees', () {
    test('isGuest is read and kept on re-save; members never write it', () {
      final a = EventAttendeeModel.fromJson({
        'id': guestKey,
        'eventId': 'e1',
        'userId': guestKey,
        'userName': 'Ana Souza',
        'status': 'going',
        'isGuest': true,
      });
      expect(a.isGuest, isTrue);
      expect(a.userName, 'Ana Souza');
      expect(a.toJson()['isGuest'], isTrue);
      expect(EventAttendeeModel.fromEntity(a.copyWith(checkedIn: true)).isGuest,
          isTrue);
      final m = EventAttendeeModel.fromJson(
          {'id': 'u', 'eventId': 'e1', 'userId': 'u', 'status': 'going'});
      expect(m.isGuest, isFalse);
      expect(m.toJson().containsKey('isGuest'), isFalse);
    });
  });

  group('guest bookings', () {
    test('guest name only for guest bookings', () {
      final b = BookingModel.fromMap('bk1', {
        'experienceId': 'x1',
        'hostId': 'h',
        'guestId': guestKey,
        'guests': 2,
        'status': 'requested',
        'isGuest': true,
        'guestName': 'Ana Souza',
      });
      expect(b.bookedByGuest, isTrue);
      expect(b.guestName, 'Ana Souza');
      final m = BookingModel.fromMap('bk2', {
        'guestId': 'memberUid',
        'guestName': 'Spoofed',
        'status': 'requested',
      });
      expect(m.bookedByGuest, isFalse);
      expect(m.guestName, isNull);
    });
  });

  group('experience opt-in', () {
    test('guestsAllowed is read and written by the editor payload', () {
      final x = UserExperienceModel.fromMap('x1', {'guestsAllowed': true});
      expect(x.guestBookingAllowed, isTrue);
      expect(UserExperienceModel.editablePayload(x)['guestsAllowed'], isTrue);
      expect(UserExperienceModel.fromMap('x2', {}).guestBookingAllowed, isFalse);
    });
  });
}
