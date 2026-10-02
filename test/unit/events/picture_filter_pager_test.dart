import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/display_image.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/events/data/datasources/events_remote_datasource.dart';
import 'package:greengo_chat/features/events/data/datasources/external_events_pager.dart';
import 'package:greengo_chat/features/user_experiences/data/datasources/user_experiences_remote_datasource.dart';

/// "Only elements with pictures are shown" is applied at the data layer, and
/// pages stay FULL: a page thinned by the filter is topped up from the next
/// reads — but only for a bounded number of reads.
void main() {
  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final now = DateTime.now();

  group('ExternalEventsPager (partner events)', () {
    Future<FakeFirebaseFirestore> seed({
      required int withoutImage,
      required int withImage,
    }) async {
      const lat = 40.71, lng = -74.0;
      final db = FakeFirebaseFirestore();
      var day = 1;
      Future<void> add(String id, String? image, int i) =>
          db.collection('external_events').doc(id).set({
            'source': 'ticketmaster',
            'title': id,
            // Picture-less events are the SOONEST / NEAREST, so a naive page
            // would be all of them.
            'startDate': iso(now.add(Duration(days: day++))),
            'lat': lat + i * 1e-3,
            'lng': lng,
            'geohash': GeoQuery.encode(lat + i * 1e-3, lng),
            'imageUrl': image,
          });
      for (var i = 0; i < withoutImage; i++) {
        await add('bare$i', i.isEven ? null : '', i);
      }
      for (var i = 0; i < withImage; i++) {
        await add('pic$i', 'https://s1.ticketm.net/pic$i.jpg', withoutImage + i);
      }
      return db;
    }

    test('date order: a page thinned by the filter is topped up to a full '
        'chunk of pictured events, still soonest first', () async {
      final pager = ExternalEventsPager(
        source: 'ticketmaster',
        sort: 'date',
        liveChunks: true,
        firestore: await seed(withoutImage: 30, withImage: 25),
      );
      final page = await pager.next();
      expect(page.length, greaterThanOrEqualTo(ExternalEventsPager.liveChunk));
      expect(page.every(externalEventHasPicture), isTrue);
      for (var i = 1; i < page.length; i++) {
        expect(page[i].startDate!.compareTo(page[i - 1].startDate!) >= 0,
            isTrue);
      }
    });

    test('date order: the top-up is bounded — a page of only picture-less '
        'events costs a fixed number of reads, then paging resumes', () async {
      final pager = ExternalEventsPager(
        source: 'ticketmaster',
        sort: 'date',
        liveChunks: true,
        firestore: await seed(withoutImage: 400, withImage: 5),
      );
      final first = await pager.next();
      expect(first, isEmpty, reason: 'read budget spent on dropped items');
      expect(pager.hasMore, isTrue, reason: 'the cursor kept its place');
      // Later calls continue from the cursor and reach the pictured events.
      final shown = <String>[];
      for (var i = 0; i < 10 && pager.hasMore; i++) {
        shown.addAll((await pager.next()).map((e) => e.id));
      }
      expect(shown, hasLength(5));
      expect(shown.every((id) => id.startsWith('pic')), isTrue);
    });

    test('distance order (Live chunks): only pictured events, a full chunk',
        () async {
      final pager = ExternalEventsPager(
        source: 'ticketmaster',
        sort: 'distance',
        userLat: 40.71,
        userLng: -74.0,
        liveChunks: true,
        firestore: await seed(withoutImage: 40, withImage: 30),
      );
      final page = await pager.next();
      expect(page, hasLength(ExternalEventsPager.liveChunk));
      expect(page.every((e) => e.id.startsWith('pic')), isTrue);
    });
  });

  group('community feeds', () {
    test('member experiences: the public feed tops a page up to full with '
        'pictured experiences (bounded reads)', () async {
      final db = FakeFirebaseFirestore();
      Future<void> add(String id, String photo, int minutesAgo) =>
          db.collection('user_experiences').doc(id).set({
            'hostId': 'h',
            'title': id,
            'status': 'published',
            'mainPhotoUrl': photo,
            'createdAt': Timestamp.fromDate(
                now.subtract(Duration(minutes: minutesAgo))),
          });
      // The 25 NEWEST have no photo; 40 older ones do.
      for (var i = 0; i < 25; i++) {
        await add('bare$i', '', i);
      }
      for (var i = 0; i < 40; i++) {
        await add('pic$i', 'https://a/pic$i.jpg', 100 + i);
      }
      final pager =
          UserExperiencesRemoteDataSource(firestore: db).communityFeed();
      final page = await pager.next();
      // 1st read: 20 bare; 2nd: 5 bare + 15; 3rd (last allowed): 20 more.
      expect(page.length, inInclusiveRange(20, 35));
      expect(page.every(experienceHasPicture), isTrue);
      expect(pager.hasMore, isTrue);

      // The host's own list keeps everything.
      final own =
          await UserExperiencesRemoteDataSource(firestore: db).hostFeed('h').next();
      expect(own.where((e) => !experienceHasPicture(e)), isNotEmpty);
    });

    Map<String, dynamic> event(String id, String? image, int day,
            {double lat = 41.9, double lng = 12.5}) =>
        {
          'title': id,
          'organizerId': 'o',
          'status': 'published',
          'visibility': 'public',
          'imageUrl': image,
          'startDate': Timestamp.fromDate(now.add(Duration(days: day))),
          'endDate': Timestamp.fromDate(now.add(Duration(days: day, hours: 2))),
          'latitude': lat,
          'longitude': lng,
          'geohash': GeoQuery.encode(lat, lng),
        };

    test('community events (upcoming list): picture-less dropped and the list '
        'topped up by one extra page', () async {
      final db = FakeFirebaseFirestore();
      // 60 picture-less SOONEST, then 90 with a cover.
      for (var i = 0; i < 60; i++) {
        await db.collection('events').doc('bare$i').set(event('bare$i', null, 1 + i));
      }
      for (var i = 0; i < 90; i++) {
        await db
            .collection('events')
            .doc('pic$i')
            .set(event('pic$i', 'https://a/pic$i.jpg', 100 + i));
      }
      final list = await EventsRemoteDataSourceImpl(
              firestore: db, currentUserId: () => 'viewer')
          .getEvents(upcoming: true);
      expect(list.every(eventHasPicture), isTrue);
      // 40 from the first page of 100 + 50 more from ONE extra page.
      expect(list, hasLength(90));
    });

    test('community events (nearest-first): the scan returns the closest '
        'events WITH a picture', () async {
      final db = FakeFirebaseFirestore();
      for (var i = 0; i < 10; i++) {
        await db
            .collection('events')
            .doc('bare$i')
            .set(event('bare$i', '', 1 + i, lat: 41.9 + i * 1e-4));
        await db.collection('events').doc('pic$i').set(event(
            'pic$i', 'https://a/pic$i.jpg', 1 + i,
            lat: 41.95 + i * 1e-4));
      }
      final list = await EventsRemoteDataSourceImpl(
              firestore: db, currentUserId: () => 'viewer')
          .getNearbyCommunityEvents(lat: 41.9, lng: 12.5, limit: 5);
      expect(list, hasLength(5));
      expect(list.every((e) => e.id.startsWith('pic')), isTrue);
    });
  });
}
