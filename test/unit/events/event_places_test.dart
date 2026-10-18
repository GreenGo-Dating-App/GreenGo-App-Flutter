import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/data/datasources/events_remote_datasource.dart';

/// Owner rule 2026-10-18: a free event counts PLACES (1 + plus-ones per going
/// attendee) and plus-ones are refused on paid events. The datasource keeps
/// events.attendeeCount in step in the same transaction (the Firestore rules
/// check it: functions/__tests__/security/ticket-rules.emulator.test.ts).
void main() {
  late FakeFirebaseFirestore db;
  late EventsRemoteDataSourceImpl ds;

  Future<void> event(String id, Map<String, dynamic> d) => db.collection('events').doc(id).set({
        'organizerId': 'org', 'title': 'Picnic', 'maxAttendees': 20, 'attendeeCount': 0,
        'guestsAllowedPerAttendee': 2, ...d,
      });
  Future<void> going(String eventId, String uid, {int guests = 0, String status = 'going'}) =>
      db.collection('events').doc(eventId).collection('attendees').doc(uid).set({
        'eventId': eventId, 'userId': uid, 'userName': uid, 'status': status, 'guestCount': guests,
        'rsvpDate': DateTime(2026),
      });
  Future<Map<String, dynamic>> ev(String id) async => (await db.collection('events').doc(id).get()).data()!;
  Future<int> guests(String id, String uid) async =>
      ((await db.collection('events').doc(id).collection('attendees').doc(uid).get()).data()!['guestCount'] as num).toInt();

  setUp(() {
    db = FakeFirebaseFirestore();
    ds = EventsRemoteDataSourceImpl(firestore: db, currentUserId: () => 'u1');
  });

  test('capacity 20, one +1 RSVP -> 18 places left', () async {
    await event('e', {'attendeeCount': 1});
    await going('e', 'u1');
    await ds.setAttendeeGuestCount(eventId: 'e', userId: 'u1', guestCount: 1);
    expect(await guests('e', 'u1'), 1);
    final d = await ev('e');
    expect(d['maxAttendees'] - d['attendeeCount'], 18);
    // Back to 0 gives the place back; above the organizer setting is clamped.
    await ds.setAttendeeGuestCount(eventId: 'e', userId: 'u1', guestCount: 0);
    expect((await ev('e'))['attendeeCount'], 1);
    await ds.setAttendeeGuestCount(eventId: 'e', userId: 'u1', guestCount: 9);
    expect(await guests('e', 'u1'), 2);
    expect((await ev('e'))['attendeeCount'], 3);
  });

  test('plus-ones never go past the capacity', () async {
    await event('full', {'maxAttendees': 3, 'attendeeCount': 2});
    await going('full', 'u1', guests: 1);
    await expectLater(ds.setAttendeeGuestCount(eventId: 'full', userId: 'u1', guestCount: 2), completes);
    expect((await ev('full'))['attendeeCount'], 3);
    await event('full2', {'maxAttendees': 3, 'attendeeCount': 3});
    await going('full2', 'u1', guests: 1);
    await expectLater(ds.setAttendeeGuestCount(eventId: 'full2', userId: 'u1', guestCount: 2),
        throwsA(isA<NotEnoughPlacesException>()));
    expect(await guests('full2', 'u1'), 1);
    expect((await ev('full2'))['attendeeCount'], 3);
  });

  test('paid events refuse plus-ones (older settings read as 0)', () async {
    await event('paid', {'price': 20, 'ticketProvider': 'stripe', 'guestsAllowedPerAttendee': 2});
    await going('paid', 'u1');
    await expectLater(ds.setAttendeeGuestCount(eventId: 'paid', userId: 'u1', guestCount: 1),
        throwsA(isA<PlusOnesNotAllowedException>()));
    expect(await guests('paid', 'u1'), 0);
  });

  test('cancelling frees 1 + plus-ones; promotion only when all their places fit', () async {
    await event('w', {'maxAttendees': 3, 'attendeeCount': 3});
    await going('w', 'u1', guests: 1); // 2 places
    await going('w', 'u2'); // 1 place
    await going('w', 'u3', status: 'waitlist', guests: 2); // wants 3 places
    await going('w', 'u4', status: 'waitlist'); // wants 1 place
    // Only Base members are promoted (owner rule 2026-10-11).
    for (final u in ['u3', 'u4']) {
      await db.collection('profiles').doc(u).set({
        'hasBaseMembership': true, 'baseMembershipEndDate': DateTime.now().add(const Duration(days: 30)),
      });
    }
    // u2 leaves: 1 place free -> u3 (3 places) does not fit, so nobody is promoted.
    await ds.cancelRsvpWithPromotion('w', 'u2');
    expect((await ev('w'))['attendeeCount'], 2);
    // u1 leaves (2 places): 3 free -> the oldest waitlisted (u3, 3 places) fits.
    await ds.cancelRsvpWithPromotion('w', 'u1');
    expect((await ev('w'))['attendeeCount'], 3);
    final u3 = (await db.collection('events').doc('w').collection('attendees').doc('u3').get()).data()!;
    expect(u3['status'], 'going');
  });

  test('re-joining while going keeps the plus-ones', () async {
    await event('j', {'attendeeCount': 2});
    await going('j', 'u1', guests: 1);
    await ds.joinEventWithTier(eventId: 'j', userId: 'u1');
    expect(await guests('j', 'u1'), 1);
    expect((await ev('j'))['attendeeCount'], 2);
  });

  test('attendeePlaces / plusOnesAllowedFrom', () {
    expect(attendeePlaces({'status': 'going', 'guestCount': 2}), 3);
    expect(plusOnesAllowedFrom({'guestsAllowedPerAttendee': 3}), 3);
    expect(plusOnesAllowedFrom({'guestsAllowedPerAttendee': 3, 'ticketProvider': 'mercadopago'}), 0);
  });
}
