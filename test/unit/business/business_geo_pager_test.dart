import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/geo_query.dart';
import 'package:greengo_chat/features/business/data/business_geo_pager.dart';
import 'package:greengo_chat/features/explore/presentation/screens/network_discovery_screen.dart';
import 'package:greengo_chat/features/matching/domain/entities/match_candidate.dart';
import 'package:greengo_chat/features/matching/domain/entities/match_score.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

import '../../support/profile_fixtures.dart';

/// Discover's Businesses mode finds businesses by their storefront ADDRESS
/// (owner rule 2026-10-19): nearest-first businessGeohash rings around the
/// viewer, paged, within the distance filter, with the same visibility rules
/// as the people grid. No usable viewer location = the old people-pool path.
void main() {
  // Viewer in São Paulo (Praça da Sé).
  const vLat = -23.5505, vLng = -46.6333;
  const viewer = Location(
    latitude: vLat,
    longitude: vLng,
    city: 'São Paulo',
    country: 'Brazil',
    displayAddress: 'São Paulo, Brazil',
  );

  /// A business whose OWNER lives in Lisbon (fixture location) but whose
  /// storefront is [dLatKm] km north of the viewer.
  Profile biz(String id, double dLatKm, {bool isBusiness = true}) =>
      buildProfile(userId: id, displayName: 'Owner $id', isBusiness: isBusiness)
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

  Future<void> put(FakeFirebaseFirestore db, Profile p,
      {bool withGeohash = true, Map<String, dynamic> extra = const {}}) {
    final a = p.businessAddress!;
    return db.collection('profiles').doc(p.userId).set({
      ...ProfileModel.fromEntity(p).toJson(),
      if (withGeohash)
        'businessGeohash': GeoQuery.encode(a.latitude, a.longitude),
      ...extra,
    });
  }

  Future<List<Profile>> drain(BusinessGeoPager pager) async {
    final out = <Profile>[];
    for (var i = 0; i < 50 && pager.hasMore; i++) {
      out.addAll(await pager.nextPage());
    }
    return out;
  }

  BusinessGeoPager pagerFor(FakeFirebaseFirestore db,
          {int? radiusKm, int pageSize = 20, Set<String> blocked = const {}}) =>
      BusinessGeoPager.forViewer(
        firestore: db,
        viewerId: 'viewer',
        viewer: viewer,
        radiusKm: radiusKm,
        blockedIds: blocked,
        pageSize: pageSize,
      )!;

  test('ring order: nearest storefront address first, owner location ignored',
      () async {
    final db = FakeFirebaseFirestore();
    // Inserted far-to-near so document order can't fake the result.
    for (final d in [300.0, 40.0, 7.0, 0.5, 2.0, 1200.0]) {
      await put(db, biz('b${d.toInt()}_${(d * 10).toInt()}', d));
    }
    final got = await drain(pagerFor(db));
    final km = [
      for (final p in got)
        GeoQuery.distanceMeters(vLat, vLng, p.businessAddress!.latitude,
                p.businessAddress!.longitude) /
            1000
    ];
    expect(got.length, 6);
    for (var i = 1; i < km.length; i++) {
      expect(km[i], greaterThanOrEqualTo(km[i - 1]),
          reason: 'nearest-first by address: $km');
    }
    expect(km.first, closeTo(0.5, 0.05));
  });

  test('radius filter is honoured against the business address', () async {
    final db = FakeFirebaseFirestore();
    for (final d in [1.0, 4.0, 9.5, 12.0, 60.0, 800.0]) {
      await put(db, biz('d${(d * 10).toInt()}', d));
    }
    final pager = pagerFor(db, radiusKm: 10);
    final got = await drain(pager);
    expect(got.map((p) => p.userId).toList(), ['d10', 'd40', 'd95']);
    expect(pager.hasMore, isFalse);
  });

  test('paging: pages of pageSize, no duplicates, globally nearest-first',
      () async {
    final db = FakeFirebaseFirestore();
    for (var i = 0; i < 45; i++) {
      await put(db, biz('p$i', 0.2 + i * 0.3));
    }
    final pager = pagerFor(db, pageSize: 20);
    final p1 = await pager.nextPage();
    final p2 = await pager.nextPage();
    final p3 = await pager.nextPage();
    expect(p1.length, 20);
    expect(p2.length, 20);
    expect(p3.length, 5);
    expect(pager.hasMore, isFalse);
    final ids = [...p1, ...p2, ...p3].map((p) => p.userId).toList();
    expect(ids.toSet().length, 45);
    expect(ids, [for (var i = 0; i < 45; i++) 'p$i']);
    expect(pager.returnedCount, 45);
  });

  test('blocked, ghost, non-business and address-less docs are skipped',
      () async {
    final db = FakeFirebaseFirestore();
    await put(db, biz('ok', 1));
    await put(db, biz('blocked', 1.5));
    await put(db, biz('ghost', 2), extra: {'isGhostMode': true});
    // Stale businessGeohash on a former business: the isBusiness filter wins.
    await put(db, biz('former', 2.5, isBusiness: false));
    // (A business WITHOUT businessGeohash is simply not in the orderBy index
    // in real Firestore; fake_cloud_firestore throws on such docs in cursor
    // queries, so that case is covered by the server-side tests.)
    // The viewer's own business never shows in its own list.
    await put(db, biz('viewer', 3.5));
    final got = await drain(pagerFor(db, blocked: {'blocked'}));
    expect(got.map((p) => p.userId).toList(), ['ok']);
  });

  test('foundNothing when no business has a businessGeohash (pre-backfill)',
      () async {
    final db = FakeFirebaseFirestore();
    // Only non-businesses / stale data: the isBusiness filter matches none.
    await put(db, biz('a', 1, isBusiness: false), withGeohash: false);
    final pager = pagerFor(db);
    expect(await drain(pager), isEmpty);
    expect(pager.foundNothing, isTrue);
  });

  group('fallback: no usable viewer location keeps the people-pool path', () {
    test('forViewer is null without a usable location', () {
      final db = FakeFirebaseFirestore();
      Location at(double la, double ln) => Location(
          latitude: la,
          longitude: ln,
          city: '',
          country: '',
          displayAddress: '');
      for (final v in <Location?>[
        null,
        at(0, 0),
        at(double.nan, 1),
        at(91, 1),
        at(1, 181),
      ]) {
        expect(
            BusinessGeoPager.forViewer(
                firestore: db, viewerId: 'v', viewer: v),
            isNull,
            reason: '$v');
      }
      expect(BusinessGeoPager.forViewer(
              firestore: db, viewerId: 'v', viewer: viewer),
          isNotNull);
    });

    test('a 0 / negative distance filter means worldwide', () {
      final db = FakeFirebaseFirestore();
      expect(
          BusinessGeoPager.forViewer(
                  firestore: db, viewerId: 'v', viewer: viewer, radiusKm: 0)!
              .radiusKm,
          isNull);
    });
  });

  group('orderBusinessTiles honours the distance filter by address', () {
    MatchCandidate cand(Profile p, double distance) => MatchCandidate(
          profile: p,
          matchScore: MatchScore(
            userId1: 'viewer',
            userId2: p.userId,
            overallScore: 0,
            breakdown: const ScoreBreakdown(
                locationScore: 0,
                ageCompatibilityScore: 0,
                interestOverlapScore: 0),
            calculatedAt: DateTime(2026),
          ),
          distance: distance,
          suggestedAt: DateTime(2026),
        );

    test('address farther than the filter is dropped; no address kept', () {
      final near = cand(biz('near', 2), 9000);
      final far = cand(biz('far', 30), 1);
      final noAddr = cand(
          buildProfile(userId: 'noaddr', isBusiness: true), 5);
      final r = orderBusinessTiles([far, noAddr, near], viewer,
          maxDistanceKm: 10);
      expect(r.candidates.map((c) => c.profile.userId).toList(),
          ['near', 'noaddr']);
      final all = orderBusinessTiles([far, noAddr, near], viewer);
      expect(all.candidates.length, 3);
    });
  });
}
