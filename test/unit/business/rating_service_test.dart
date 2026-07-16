import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/services/rating_service.dart';

/// Master Test Plan — Business/Storefront. RatingService denormalized aggregate.
/// Guards the scale-safe design: one rating doc per (user, business) and a
/// transactionally-maintained ratingSum/ratingCount on profiles/{businessId}.
///
/// NOTE: fake_cloud_firestore does NOT reliably emulate `runTransaction` +
/// `FieldValue.increment` accumulation across sequential transactions, nor the
/// initial frame of `.snapshots()`. The multi-rate aggregate + stream cases are
/// therefore `skip`ped here and are covered instead by the emulator/E2E layer
/// (see docs/testing/GREENGO_MASTER_TEST_PLAN.md, B2/B4). The single-rate and
/// self-rating-rejection cases below run against the fake and DO pass.
const _fakeTxnLimit =
    'fake_cloud_firestore does not emulate runTransaction+FieldValue.increment '
    'accumulation / snapshots first-frame — covered by the emulator layer';

void main() {
  late FakeFirebaseFirestore db;
  late RatingService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = RatingService(firestore: db);
  });

  Future<Map<String, dynamic>?> profileData(String biz) async =>
      (await db.collection('profiles').doc(biz).get()).data();

  group('rateBusiness', () {
    test('first rating sets sum and count and writes the rating doc', () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 4);

      final prof = await profileData('biz');
      expect(prof?['ratingSum'], 4);
      expect(prof?['ratingCount'], 1);

      final rating = await db
          .collection('business_ratings')
          .doc('biz')
          .collection('ratings')
          .doc('ava')
          .get();
      expect(rating.data()?['stars'], 4);
    });

    test('a second distinct rater increments sum and count', skip: _fakeTxnLimit, () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 5);
      await service.rateBusiness(businessId: 'biz', raterId: 'bruno', stars: 3);

      final prof = await profileData('biz');
      expect(prof?['ratingSum'], 8);
      expect(prof?['ratingCount'], 2);
    });

    test('re-rating shifts sum by delta, count unchanged', skip: _fakeTxnLimit, () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 2);
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 5);

      final prof = await profileData('biz');
      expect(prof?['ratingSum'], 5); // 2 then +3 delta
      expect(prof?['ratingCount'], 1);
    });

    test('stars are clamped to 1..5', () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 99);
      expect((await profileData('biz'))?['ratingSum'], 5);

      await service.rateBusiness(businessId: 'biz2', raterId: 'ava', stars: -3);
      expect((await profileData('biz2'))?['ratingSum'], 1);
    });

    test('a business cannot rate itself (raterId == businessId)', () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'biz', stars: 5);

      expect(await profileData('biz'), isNull);
      final rating = await db
          .collection('business_ratings')
          .doc('biz')
          .collection('ratings')
          .doc('biz')
          .get();
      expect(rating.exists, isFalse);
    });
  });

  group('aggregate reads', () {
    test('getAggregate computes avg = sum / count', skip: _fakeTxnLimit, () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 4);
      await service.rateBusiness(businessId: 'biz', raterId: 'bruno', stars: 2);

      final agg = await service.getAggregate('biz');
      expect(agg.count, 2);
      expect(agg.avg, 3.0);
    });

    test('getAggregate is (0,0) for a business with no ratings', () async {
      final agg = await service.getAggregate('unknown_biz');
      expect(agg.avg, 0.0);
      expect(agg.count, 0);
    });

    test('myRating stream emits the viewer current stars', skip: _fakeTxnLimit, () async {
      await service.rateBusiness(businessId: 'biz', raterId: 'ava', stars: 3);

      final stars =
          await service.myRating(businessId: 'biz', raterId: 'ava').first;
      expect(stars, 3);
    });

    test('myRating stream is null when the viewer never rated', () async {
      final stars =
          await service.myRating(businessId: 'biz', raterId: 'ghost').first;
      expect(stars, isNull);
    });
  });
}
