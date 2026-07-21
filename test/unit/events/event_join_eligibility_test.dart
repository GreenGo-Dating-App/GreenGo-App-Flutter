import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/events/domain/entities/event.dart';

import '../../support/events_fixtures.dart';

/// Master Test Plan — Events / join eligibility, capacity & auto-publish gate.
/// Covers E2E matrix items #208 (RSVP/full-disabled), #210 (open details),
/// #211 (Join/Waitlist/Going status), #213 (join full → waitlist), and the
/// scheduled auto-publish visibility gate (#222). Pure tests against the real
/// [Event] and [EventAttendee] entities.
void main() {
  final now = DateTime.now();

  EventAttendee attendee({
    String id = 'a1',
    String userId = 'u1',
    RSVPStatus status = RSVPStatus.going,
    int guestCount = 0,
    bool isInvisible = false,
    bool isAnonymous = false,
    bool visibleToOrganizerOnly = false,
  }) =>
      EventAttendee(
        id: id,
        eventId: 'evt_1',
        userId: userId,
        userName: 'User $userId',
        status: status,
        rsvpDate: DateTime(2026, 6, 1),
        guestCount: guestCount,
        isInvisible: isInvisible,
        isAnonymous: isAnonymous,
        visibleToOrganizerOnly: visibleToOrganizerOnly,
      );

  group('capacity math (spotsLeft / isFull / isUnlimited)', () {
    test('a partially-filled event has spots and is not full', () {
      final e = EventFixtures.build(maxAttendees: 20, attendeeCount: 5);
      expect(e.spotsLeft, 15);
      expect(e.isFull, isFalse);
      expect(e.isUnlimited, isFalse);
    });

    test('a full event reports isFull and no spots', () {
      final e = EventFixtures.build(maxAttendees: 10, attendeeCount: 10);
      expect(e.spotsLeft, 0);
      expect(e.isFull, isTrue);
    });

    test('an over-subscribed event is still full (never negative-eligible)', () {
      final e = EventFixtures.build(maxAttendees: 10, attendeeCount: 12);
      expect(e.isFull, isTrue);
    });

    test('maxAttendees <= 0 means unlimited and never full', () {
      final e = EventFixtures.build(maxAttendees: 0, attendeeCount: 9999);
      expect(e.isUnlimited, isTrue);
      expect(e.isFull, isFalse);
    });

    test('goingCount uses the larger of counter vs loaded attendee array', () {
      // Counter (denormalized) larger than loaded array.
      final counterWins =
          EventFixtures.build(maxAttendees: 50, attendeeCount: 8, attendees: [
        attendee(id: 'a1', userId: 'u1'),
      ]);
      expect(counterWins.goingCount, 8);

      // Loaded array larger than a stale counter.
      final arrayWins = EventFixtures.build(
        maxAttendees: 50,
        attendeeCount: 1,
        attendees: [
          attendee(id: 'a1', userId: 'u1'),
          attendee(id: 'a2', userId: 'u2'),
          attendee(id: 'a3', userId: 'u3'),
        ],
      );
      expect(arrayWins.goingCount, 3);
    });

    test('interestedCount only counts interested RSVPs', () {
      final e = EventFixtures.build(attendees: [
        attendee(id: 'a1', userId: 'u1', status: RSVPStatus.going),
        attendee(id: 'a2', userId: 'u2', status: RSVPStatus.interested),
        attendee(id: 'a3', userId: 'u3', status: RSVPStatus.interested),
        attendee(id: 'a4', userId: 'u4', status: RSVPStatus.waitlist),
      ]);
      expect(e.interestedCount, 2);
    });
  });

  group('auto-publish "isLive" gate', () {
    test('published events are always live', () {
      expect(EventFixtures.build(status: EventStatus.published).isLive, isTrue);
    });

    test('draft & cancelled & completed events are never live', () {
      for (final s in [
        EventStatus.draft,
        EventStatus.cancelled,
        EventStatus.completed,
      ]) {
        expect(EventFixtures.build(status: s).isLive, isFalse, reason: '$s');
      }
    });

    test('scheduled event is live only once publishAt has passed', () {
      final due = EventFixtures.build(status: EventStatus.scheduled).copyWith(
        publishAt: now.subtract(const Duration(minutes: 1)),
      );
      final pending = EventFixtures.build(status: EventStatus.scheduled)
          .copyWith(publishAt: now.add(const Duration(hours: 1)));
      expect(due.isLive, isTrue);
      expect(pending.isLive, isFalse);
      expect(pending.isPendingSchedule, isTrue);
      expect(due.isPendingSchedule, isFalse);
    });

    test('scheduled event with no publishAt is not live', () {
      expect(EventFixtures.build(status: EventStatus.scheduled).isLive, isFalse);
    });
  });

  group('timing & pricing flags', () {
    test('isUpcoming true for a future start, false for a past start', () {
      final future = EventFixtures.build(
          startDate: now.add(const Duration(days: 2)));
      final past = EventFixtures.build(
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.subtract(const Duration(days: 2, hours: -2)),
      );
      expect(future.isUpcoming, isTrue);
      expect(past.isUpcoming, isFalse);
    });

    test('isOngoing true only between start and end', () {
      final ongoing = EventFixtures.build(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 1)),
      );
      expect(ongoing.isOngoing, isTrue);
      expect(EventFixtures.build(startDate: now.add(const Duration(days: 1)))
          .isOngoing, isFalse);
    });

    test('isFree when price is null or zero', () {
      expect(EventFixtures.build().isFree, isTrue); // no price set
    });

    test('isCurrentlyFeatured requires the flag AND an unexpired window', () {
      final base = EventFixtures.build();
      expect(base.isCurrentlyFeatured, isFalse);
      expect(
        base.copyWith(isFeatured: true).isCurrentlyFeatured,
        isTrue,
        reason: 'featured with null featuredUntil is currently featured',
      );
      expect(
        base
            .copyWith(
              isFeatured: true,
              featuredUntil: now.subtract(const Duration(hours: 1)),
            )
            .isCurrentlyFeatured,
        isFalse,
        reason: 'an expired featured window is not currently featured',
      );
    });
  });

  group('visibility enum mapping', () {
    test('public/private helpers agree with the enum', () {
      expect(EventFixtures.build(visibility: EventVisibility.public).isPublic,
          isTrue);
      expect(EventFixtures.build(visibility: EventVisibility.private).isPrivate,
          isTrue);
    });

    test('EventVisibility.fromString falls back to public on junk/null', () {
      expect(EventVisibilityExtension.fromString('private'),
          EventVisibility.private);
      expect(EventVisibilityExtension.fromString('nonsense'),
          EventVisibility.public);
      expect(EventVisibilityExtension.fromString(null), EventVisibility.public);
    });
  });

  group('EventAttendee waitlist, headcount & privacy', () {
    test('isWaitlisted reflects a waitlist RSVP', () {
      expect(attendee(status: RSVPStatus.waitlist).isWaitlisted, isTrue);
      expect(attendee(status: RSVPStatus.going).isWaitlisted, isFalse);
    });

    test('headcount is self plus (clamped) guests', () {
      expect(attendee(guestCount: 0).headcount, 1);
      expect(attendee(guestCount: 3).headcount, 4);
      expect(attendee(guestCount: -5).headcount, 1,
          reason: 'negative guest counts must not reduce headcount below 1');
    });

    test('isVisibleTo: self and organizer always see the RSVP', () {
      final hidden = attendee(userId: 'u1', isInvisible: true);
      expect(hidden.isVisibleTo('u1', 'org'), isTrue); // self
      expect(hidden.isVisibleTo('org', 'org'), isTrue); // organizer
    });

    test('isVisibleTo: invisible / organizer-only hidden from other viewers',
        () {
      expect(attendee(userId: 'u1', isInvisible: true).isVisibleTo('u2', 'org'),
          isFalse);
      expect(
          attendee(userId: 'u1', visibleToOrganizerOnly: true)
              .isVisibleTo('u2', 'org'),
          isFalse);
      expect(attendee(userId: 'u1').isVisibleTo('u2', 'org'), isTrue);
    });

    test('displayNameFor honors anonymity for third-party viewers only', () {
      final anon = attendee(userId: 'u1', isAnonymous: true);
      expect(anon.displayNameFor('u1', 'org'), 'User u1'); // self
      expect(anon.displayNameFor('org', 'org'), 'User u1'); // organizer
      expect(anon.displayNameFor('u2', 'org'), 'Someone'); // other viewer
    });
  });
}
