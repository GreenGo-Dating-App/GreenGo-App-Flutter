import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/events/data/datasources/external_events_pager.dart';

/// Live Events (ticketmaster) load in chunks of 20 per infinite-scroll load.
void main() {
  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<FakeFirebaseFirestore> seed(
      {required int upcoming, required int past}) async {
    // Events only in New York (the feed is city-clustered).
    const lat = 40.71, lng = -74.0;
    final db = FakeFirebaseFirestore();
    final now = DateTime.now();
    Future<void> add(String id, DateTime date, double dLat) =>
        db.collection('external_events').doc(id).set({
          'source': 'ticketmaster',
          'title': id,
          'startDate': iso(date),
          'lat': lat + dLat,
          'lng': lng,
          'geohash': GeoQuery.encode(lat + dLat, lng),
          'imageUrl': 'https://x/$id.jpg',
        });
    for (var i = 0; i < past; i++) {
      await add('past$i', now.subtract(Duration(days: 10 + i)), i * 1e-3);
    }
    for (var i = 0; i < upcoming; i++) {
      await add('up$i', now.add(Duration(days: 5 + i)), i * 1e-3);
    }
    return db;
  }

  ExternalEventsPager livePager(FakeFirebaseFirestore db) =>
      ExternalEventsPager(
        source: 'ticketmaster',
        sort: 'distance',
        // São Paulo: ~7,700 km from every event.
        userLat: -23.55,
        userLng: -46.63,
        liveChunks: true,
        firestore: db,
      );

  test('each load returns 20 upcoming events until none are left', () async {
    final pager = livePager(await seed(upcoming: 50, past: 40));

    final p1 = await pager.next();
    final p2 = await pager.next();
    final p3 = await pager.next();

    expect(p1.length, 20);
    expect(p2.length, 20);
    expect(p3.length, 10); // only 50 exist
    final ids = [...p1, ...p2, ...p3].map((e) => e.id).toList();
    expect(ids.toSet().length, 50, reason: 'no duplicates across loads');
    expect(ids.every((id) => id.startsWith('up')), isTrue,
        reason: 'past events never shown');
    expect(pager.hasMore, isFalse);
    expect(await pager.next(), isEmpty);
  });

  test('a load is nearest-first', () async {
    final pager = livePager(await seed(upcoming: 30, past: 0));
    final p1 = await pager.next();
    final d = p1
        .map((e) => GeoQuery.distanceMeters(-23.55, -46.63, e.lat!, e.lng!))
        .toList();
    for (var i = 1; i < d.length; i++) {
      expect(d[i] >= d[i - 1], isTrue);
    }
  });
}
