import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/business/data/business_geo_pager.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

import '../../support/profile_fixtures.dart';

/// Discover > Businesses load speed (owner notes 2026-10-20): the first page
/// paints after the first ring with any business, the block list can arrive
/// after the scan started, small moves don't restart the search and a
/// session cache lets a re-open reuse the loaded businesses.
void main() {
  const vLat = -23.5505, vLng = -46.6333;
  const viewer = Location(
    latitude: vLat,
    longitude: vLng,
    city: 'São Paulo',
    country: 'Brazil',
    displayAddress: 'São Paulo, Brazil',
  );

  Profile biz(String id, double dLatKm) =>
      buildProfile(userId: id, displayName: 'Owner $id', isBusiness: true)
          .copyWith(
        businessName: 'Shop $id',
        businessAddress: BusinessAddress(
          address: 'Rua $id, 1',
          latitude: vLat + dLatKm / 111.2,
          longitude: vLng,
          city: 'São Paulo',
          country: 'Brazil',
        ),
      );

  Future<void> put(FakeFirebaseFirestore db, Profile p) {
    final a = p.businessAddress!;
    return db.collection('profiles').doc(p.userId).set({
      ...ProfileModel.fromEntity(p).toJson(),
      'businessGeohash': GeoQuery.encode(a.latitude, a.longitude),
    });
  }

  BusinessGeoPager pagerFor(FakeFirebaseFirestore db,
          {Set<String> blocked = const {}}) =>
      BusinessGeoPager.forViewer(
        firestore: db,
        viewerId: 'viewer',
        viewer: viewer,
        blockedIds: blocked,
      )!;

  Future<FakeFirebaseFirestore> seeded() async {
    final db = FakeFirebaseFirestore();
    await put(db, biz('near1', 1));
    await put(db, biz('near2', 2));
    for (var i = 0; i < 25; i++) {
      await put(db, biz('far$i', 400 + i.toDouble()));
    }
    return db;
  }

  test('first page returns after the first ring with a business', () async {
    final fast = pagerFor(await seeded());
    final first = await fast.nextPage(minResults: 1);
    expect(first.map((p) => p.userId).toList(), ['near1', 'near2']);
    expect(fast.hasMore, isTrue);

    // The old behaviour (fill a whole page) scans on to the far ring: more
    // sequential rounds and more documents read before the first paint.
    final full = pagerFor(await seeded());
    final page = await full.nextPage();
    expect(page.length, 20);
    expect(fast.readRounds, lessThan(full.readRounds));
    expect(fast.docsRead, lessThan(full.docsRead));

    // The rest still pages in, nearest-first, without duplicates.
    final rest = <Profile>[];
    while (fast.hasMore) {
      rest.addAll(await fast.nextPage());
    }
    final ids = [...first, ...rest].map((p) => p.userId).toList();
    expect(ids.length, 27);
    expect(ids.toSet().length, 27);
  });

  test('minResults never exceeds pageSize', () async {
    final pager = BusinessGeoPager.forViewer(
      firestore: await seeded(),
      viewerId: 'viewer',
      viewer: viewer,
      pageSize: 5,
    )!;
    final page = await pager.nextPage(minResults: 50);
    expect(page.length, 5);
  });

  test('addBlockedIds hides ids from buffered and later pages', () async {
    final pager = pagerFor(await seeded());
    await pager.nextPage(minResults: 1);
    pager.addBlockedIds({'far0', 'far1'});
    expect(pager.blockedIds, containsAll(<String>['far0', 'far1']));
    final rest = <Profile>[];
    while (pager.hasMore) {
      rest.addAll(await pager.nextPage());
    }
    final ids = rest.map((p) => p.userId).toSet();
    expect(ids.contains('far0'), isFalse);
    expect(ids.contains('far1'), isFalse);
    expect(ids.length, 23);
  });

  test('centerMoved ignores GPS jitter, restarts on a real move', () {
    const a = (lat: -23.5505, lng: -46.6333);
    const jitter = (lat: -23.5510, lng: -46.6330); // ~60 m
    const moved = (lat: -23.5700, lng: -46.6333); // ~2.2 km
    expect(BusinessGeoPager.centerMoved(a, jitter), isFalse);
    expect(BusinessGeoPager.centerMoved(a, moved), isTrue);
    expect(BusinessGeoPager.centerMoved(null, a), isTrue);
    expect(BusinessGeoPager.centerMoved(null, null), isFalse);
  });

  group('BusinessGeoSessionCache', () {
    tearDown(BusinessGeoSessionCache.clear);

    test('reused for the same viewer, filter and nearby centre', () async {
      final pager = pagerFor(await seeded());
      final page = await pager.nextPage(minResults: 1);
      final t0 = DateTime(2026, 10, 20, 12);
      BusinessGeoSessionCache.save(pager, page, now: t0);

      final hit = BusinessGeoSessionCache.lookup(
        viewerId: 'viewer',
        center: (lat: vLat + 0.001, lng: vLng),
        radiusKm: null,
        now: t0.add(const Duration(minutes: 5)),
      );
      expect(hit, isNotNull);
      expect(identical(hit!.pager, pager), isTrue);
      expect(hit.loaded.map((p) => p.userId), ['near1', 'near2']);
    });

    test('not reused: other viewer, filter, far centre or expired',
        () async {
      final pager = pagerFor(await seeded());
      final t0 = DateTime(2026, 10, 20, 12);
      BusinessGeoSessionCache.save(pager, const [], now: t0);
      const c = (lat: vLat, lng: vLng);
      expect(
          BusinessGeoSessionCache.lookup(
              viewerId: 'other', center: c, radiusKm: null, now: t0),
          isNull);
      expect(
          BusinessGeoSessionCache.lookup(
              viewerId: 'viewer', center: c, radiusKm: 10, now: t0),
          isNull);
      expect(
          BusinessGeoSessionCache.lookup(
              viewerId: 'viewer',
              center: (lat: vLat + 0.1, lng: vLng),
              radiusKm: null,
              now: t0),
          isNull);
      expect(
          BusinessGeoSessionCache.lookup(
              viewerId: 'viewer',
              center: c,
              radiusKm: null,
              now: t0.add(const Duration(minutes: 11))),
          isNull);
      BusinessGeoSessionCache.clear();
      expect(
          BusinessGeoSessionCache.lookup(
              viewerId: 'viewer', center: c, radiusKm: null, now: t0),
          isNull);
    });
  });
}
