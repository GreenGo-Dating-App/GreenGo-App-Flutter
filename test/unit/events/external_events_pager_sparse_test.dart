import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/events/data/datasources/external_events_pager.dart';

/// Live Events came back empty for users far from the (city-clustered)
/// Ticketmaster feed: the scanner spent its per-call read budget widening
/// empty rings and returned an empty page while more existed, and the tab
/// treated that as "no events".
void main() {
  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<FakeFirebaseFirestore> seed({
    required int upcoming,
    required int past,
    required double lat,
    required double lng,
  }) async {
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
      await add('past$i', now.subtract(Duration(days: 10 + i)), i * 1e-4);
    }
    for (var i = 0; i < upcoming; i++) {
      await add('up$i', now.add(Duration(days: 5 + i)), i * 1e-4);
    }
    return db;
  }

  test('user far from every event still gets the nearest upcoming ones',
      () async {
    // Events only in New York; the user is in São Paulo (~7,700 km).
    final db = await seed(upcoming: 30, past: 60, lat: 40.71, lng: -74.0);
    final pager = ExternalEventsPager(
      source: 'ticketmaster',
      sort: 'distance',
      userLat: -23.55,
      userLng: -46.63,
      firestore: db,
    );

    final first = await pager.next();

    expect(first, isNotEmpty);
    expect(first.every((e) => e.id.startsWith('up')), isTrue);
  });

  test('nearby cell full of past events does not hide upcoming ones',
      () async {
    final db = await seed(upcoming: 10, past: 200, lat: 45.46, lng: 9.19);
    final pager = ExternalEventsPager(
      source: 'ticketmaster',
      sort: 'distance',
      userLat: 45.46,
      userLng: 9.19,
      firestore: db,
    );

    final seen = <String>[];
    for (var i = 0; i < 5 && seen.length < 10 && pager.hasMore; i++) {
      seen.addAll((await pager.next()).map((e) => e.id));
    }

    expect(seen.toSet(), {for (var i = 0; i < 10; i++) 'up$i'});
  });
}
