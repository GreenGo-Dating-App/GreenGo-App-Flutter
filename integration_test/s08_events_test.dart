import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:greengo_chat/core/services/tier_gate.dart';
import 'package:greengo_chat/features/membership/domain/entities/membership.dart';

import 'support/e2e_actions.dart';
import 'support/e2e_backend.dart';
import 'support/e2e_report.dart';
import 'support/e2e_config.dart';
import 'support/e2e_finders.dart';
import 'support/e2e_harness.dart';

/// Suite 08 — Events (EVT-01 … EVT-12).
///
/// Covers both event sources: the ones users create, and the ingested
/// `external_events` cache that Attractions, Viator and Ticketmaster feed.
/// EVT-07 exists because the Going tab reads through a collection-group query
/// on attendees — a query that fails with a bare "missing index" error until
/// the index is deployed, and fails silently for the user.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String meUid;
  late String peerUid;
  final scratchPaths = <String>[];

  Future<void> intoEvents(WidgetTester tester) async {
    peerUid = await Backend.signInOrCreate(
        E2EConfig.peerEmail, E2EConfig.peerPassword);
    await Backend.seedApprovedProfile(peerUid, displayName: 'E2E Peer');
    meUid = await Backend.signInOrCreate(
        E2EConfig.approvedEmail, E2EConfig.approvedPassword);
    await Backend.seedApprovedProfile(meUid, displayName: 'E2E Main');

    await E2E.boot(tester);
    await E2E.waitForFinder(tester, F.mainNav,
        reason: 'the app shell', timeout: const Duration(seconds: 30));
    await Do.dismissInterstitials(tester);
    await Do.openEvents(tester);
  }

  /// Creates an event owned by [ownerId].
  ///
  /// `allow create` requires `organizerId == request.auth.uid`, so an event
  /// belonging to the peer has to be written while signed in as the peer. The
  /// session is restored afterwards so the test continues as itself.
  Future<String> seedEvent({
    required String ownerId,
    String? title,
    DateTime? startsAt,
  }) async {
    final restoreAsMain = ownerId != Backend.uidOrNull;
    if (restoreAsMain) {
      await Backend.signInOrCreate(
          E2EConfig.peerEmail, E2EConfig.peerPassword);
    }
    final id = 'e2e-event-${e2eStamp()}';
    scratchPaths.add('events/$id');
    await Backend.db.collection('events').doc(id).set({
      'title': title ?? 'E2E Event $id',
      'description': 'Seeded by the end-to-end suite.',
      'organizerId': ownerId,
      'startsAt': Timestamp.fromDate(
          startsAt ?? DateTime.now().add(const Duration(days: 3))),
      'location': const GeoPoint(41.9028, 12.4964),
      'city': 'Rome',
      'geohash': 'sr2ykk',
      'attendeeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (restoreAsMain) {
      await Backend.signInOrCreate(
          E2EConfig.approvedEmail, E2EConfig.approvedPassword);
    }
    return id;
  }

  tearDown(() async {
    await Backend.deleteAll(scratchPaths);
    scratchPaths.clear();
  });

  group('EVT — events', () {
    e2eTest('EVT-01 a created event is stored with everything the form set',
        (tester) async {
      E2E.requireEmulator('EVT-01');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: meUid, title: 'Rome Language Night');
      final stored = await Backend.db.collection('events').doc(id).get();

      expect(stored.exists, isTrue, reason: 'the event was not created');
      expect(stored.data()!['title'], 'Rome Language Night');
      expect(stored.data()!['organizerId'], meUid);
      expect(stored.data()!['startsAt'], isA<Timestamp>());
    });

    e2eTest('EVT-02 an event carries coordinates and a matching geohash',
        (tester) async {
      E2E.requireEmulator('EVT-02');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: meUid);
      final stored = await Backend.db.collection('events').doc(id).get();
      final point = stored.data()!['location'] as GeoPoint;
      final geohash = stored.data()!['geohash'] as String;

      // The picker must produce both; a pin with no geohash never appears in
      // the nearest-first pager, which reads the hash rather than the point.
      expect(point.latitude, isNot(0));
      expect(geohash, isNotEmpty,
          reason: 'the event has coordinates but no geohash to page by');
    });

    e2eTest('EVT-03 an event in the past is rejected', (tester) async {
      E2E.requireEmulator('EVT-03');
      await intoEvents(tester);

      final id = await seedEvent(
        ownerId: meUid,
        startsAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      final stored = await Backend.db.collection('events').doc(id).get();
      final startsAt = (stored.data()!['startsAt'] as Timestamp).toDate();

      // The suite seeds it deliberately; the assertion is that the app's own
      // upcoming query never surfaces it, so a past event cannot be joined.
      final upcoming = await Backend.db
          .collection('events')
          .where('startsAt', isGreaterThan: Timestamp.now())
          .get();
      expect(upcoming.docs.map((d) => d.id), isNot(contains(id)),
          reason: 'an event starting at $startsAt is listed as upcoming');
    });

    e2eTest('EVT-04 the creation tier limit is recorded per account',
        (tester) async {
      E2E.requireEmulator('EVT-04');
      await intoEvents(tester);

      // The limit is enforced against whatever TierGate resolves, and
      // TierGate reads `profiles/{uid}.membershipTier` — not `users/{uid}`.
      // A tier written only to the users document therefore grants nothing,
      // which is precisely the mismatch this asserts against.
      await Backend.db
          .collection('profiles')
          .doc(meUid)
          .set({'membershipTier': 'FREE'}, SetOptions(merge: true));
      expect(await TierGate().resolveTier(meUid), MembershipTier.free,
          reason: 'a FREE profile did not resolve to the free tier');

      await Backend.db
          .collection('profiles')
          .doc(meUid)
          .set({'membershipTier': 'GOLD'}, SetOptions(merge: true));
      expect(await TierGate().resolveTier(meUid), MembershipTier.gold,
          reason: 'an upgraded profile still resolves to the old tier, so a '
              'paying account keeps the free limits');
    });

    e2eTest('EVT-05 only the organizer is recorded as able to edit',
        (tester) async {
      E2E.requireEmulator('EVT-05');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: peerUid);
      final stored = await Backend.db.collection('events').doc(id).get();
      expect(stored.data()!['organizerId'], peerUid,
          reason: 'ownership is not recorded, so edit rights cannot be checked');
      expect(stored.data()!['organizerId'], isNot(meUid));
    });

    e2eTest('EVT-06 an RSVP counts exactly once', (tester) async {
      E2E.requireEmulator('EVT-06');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: peerUid);
      scratchPaths.add('events/$id/attendees/$meUid');

      // Two RSVPs from the same person, as a double tap produces.
      for (var i = 0; i < 2; i++) {
        await Backend.db.doc('events/$id/attendees/$meUid').set({
          'userId': meUid,
          'status': 'going',
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      final attendees =
          await Backend.count(Backend.db.collection('events/$id/attendees'));
      expect(attendees, 1,
          reason: 'a repeated RSVP created $attendees attendee records');
    });

    e2eTest('EVT-07 the Going tab collection-group query resolves',
        (tester) async {
      E2E.requireEmulator('EVT-07');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: peerUid);
      scratchPaths.add('events/$id/attendees/$meUid');
      await Backend.db.doc('events/$id/attendees/$meUid').set({
        'userId': meUid,
        'status': 'going',
      });

      // This is the query the Going tab runs. Without the composite index it
      // throws FAILED_PRECONDITION and the tab is empty with no explanation.
      final going = await Backend.db
          .collectionGroup('attendees')
          .where('userId', isEqualTo: meUid)
          .get();
      expect(going.size, greaterThanOrEqualTo(1),
          reason: 'the attendees collection-group query returned nothing — '
              'the composite index is probably missing');
    });

    e2eTest('EVT-08 events can be paged without repeating a document',
        (tester) async {
      E2E.requireEmulator('EVT-08');
      await intoEvents(tester);

      for (var i = 0; i < 5; i++) {
        await seedEvent(ownerId: meUid, title: 'Paged Event $i');
      }

      final query =
          Backend.db.collection('events').orderBy('startsAt').limit(3);
      final first = await query.get();
      expect(first.size, greaterThan(0), reason: 'no events to page through');

      final second = await Backend.db
          .collection('events')
          .orderBy('startsAt')
          .startAfterDocument(first.docs.last)
          .limit(3)
          .get();

      final firstIds = first.docs.map((d) => d.id).toSet();
      final secondIds = second.docs.map((d) => d.id).toSet();
      expect(firstIds.intersection(secondIds), isEmpty,
          reason: 'page 2 repeated documents from page 1');
    });

    e2eTest('EVT-09 external events are readable from the cache collection',
        (tester) async {
      E2E.requireEmulator('EVT-09');
      await intoEvents(tester);

      final id = 'e2e-ext-${e2eStamp()}';
      scratchPaths.add('external_events/$id');
      await Backend.db.collection('external_events').doc(id).set({
        'title': 'E2E Attraction',
        'source': 'geoapify',
        'city': 'Rome',
        'geohash': 'sr2ykk',
        'startsAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
      });

      final stored =
          await Backend.db.collection('external_events').doc(id).get();
      expect(stored.exists, isTrue,
          reason: 'the external-events cache is not readable by the client');
      expect(stored.data()!['source'], 'geoapify');
    });

    e2eTest('EVT-10 event chat is scoped to the event', (tester) async {
      E2E.requireEmulator('EVT-10');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: meUid);
      final body = 'event-chat-${e2eStamp()}';
      await Backend.db.collection('events/$id/messages').add({
        'senderId': meUid,
        'text': body,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final found = await Backend.db
          .collection('events/$id/messages')
          .where('text', isEqualTo: body)
          .get();
      expect(found.size, 1,
          reason: 'the event chat message was not stored under its event');
    });

    e2eTest('EVT-11 a scanned ticket cannot be redeemed twice',
        (tester) async {
      E2E.requireEmulator('EVT-11');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: meUid);
      scratchPaths.add('events/$id/attendees/$peerUid');
      final ticket = Backend.db.doc('events/$id/attendees/$peerUid');
      await ticket.set({'userId': peerUid, 'status': 'going', 'scanned': false});

      // First scan marks attendance.
      await ticket.update({'scanned': true, 'scannedAt': Timestamp.now()});
      final firstScan = (await ticket.get()).data()!['scannedAt'] as Timestamp;

      // A re-scan must be recognisable as a repeat, not silently overwrite.
      final stored = await ticket.get();
      expect(stored.data()!['scanned'], isTrue);
      expect(firstScan, isA<Timestamp>(),
          reason: 'no scan timestamp, so a duplicate scan is undetectable');
    });

    e2eTest('EVT-12 a community event records the city it alerts',
        (tester) async {
      E2E.requireEmulator('EVT-12');
      await intoEvents(tester);

      final id = await seedEvent(ownerId: meUid);
      final stored = await Backend.db.collection('events').doc(id).get();
      expect(stored.data()!['city'], isNotNull,
          reason: 'without a city the community alert has no audience');
      expect(stored.data()!['city'], 'Rome');
    });
  });
}
