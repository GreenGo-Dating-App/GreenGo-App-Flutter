import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/communities_remote_datasource.dart';

import '../../support/mock_data.dart';

/// Master Test Plan — F5 Communities + B3 query validity.
/// Exercises the datasource against a fake Firestore preloaded with the mock
/// communities. Guards the "My communities" fix (getCreatedCommunities queries
/// createdByUserId directly, independent of member docs) and Discover.
void main() {
  group('CommunitiesRemoteDataSource against fake Firestore', () {
    test('getCommunities returns only public communities (joinable)', () async {
      final db = await MockFirestore.withCommunities();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);

      final result = await ds.getCommunities();

      expect(result.length, 5);
      expect(result.every((c) => c.isPublic), isTrue);
    });

    test('getCreatedCommunities returns ONLY the caller-created communities',
        () async {
      final db = await MockFirestore.withCommunities();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);

      // mock_user_1 created mock_comm_1 (owner rotation i%5 -> user1 owns comm1).
      final mine = await ds.getCreatedCommunities(MockUsers.free);

      expect(mine, isNotEmpty, reason: 'creator must see their community');
      expect(
        mine.every((c) => c.createdByUserId == MockUsers.free),
        isTrue,
        reason: 'no community created by another user should leak in',
      );
    });

    test('getCreatedCommunities is empty for a user who created none', () async {
      final db = await MockFirestore.withCommunities();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);

      final none = await ds.getCreatedCommunities('nobody_uid_xyz');

      expect(none, isEmpty);
    });

    test('getUserCommunities finds communities via member docs', () async {
      final db = await MockFirestore.withCommunities();
      final ds = CommunitiesRemoteDataSourceImpl(firestore: db);

      final joined = await ds.getUserCommunities(MockUsers.free);

      expect(joined, isNotEmpty,
          reason: 'creator has a member doc so it is a "joined" community too');
    });
  });

  group('getRecommendedCommunities language matching', () {
    Future<FakeFirebaseFirestore> seed() async {
      final db = FakeFirebaseFirestore();
      Future<void> add(String id, List<String> langs, int members) =>
          db.collection('communities').doc(id).set({
            'name': id,
            'description': '',
            'type': 'general',
            'createdByUserId': 'system',
            'createdByName': 'GreenGo',
            'createdAt': Timestamp.fromDate(DateTime(2026)),
            'memberCount': members,
            'languages': langs,
            'tags': const <String>[],
            'isPublic': true,
            'lastActivityAt': Timestamp.fromDate(DateTime(2026)),
          });
      // 12 popular English communities fill the "popular" slot (limit 10)…
      for (var i = 0; i < 12; i++) {
        await add('popular_$i', const ['en'], 1000 + i);
      }
      // …so these only surface through the LANGUAGE query.
      await add('c_pt', const ['pt', 'en'], 3);
      await add('c_ca', const ['ca'], 2);
      return db;
    }

    test('profile display names ("Portuguese (Brazil)") match code "pt"',
        () async {
      final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
      final result = await ds.getRecommendedCommunities(
        userId: 'u',
        languages: const ['Portuguese (Brazil)', 'Catalan'],
      );
      expect(result.map((c) => c.id), containsAll(['c_pt', 'c_ca']));
    });

    test('locales and mixed case are normalised too', () async {
      final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
      final result = await ds.getRecommendedCommunities(
        userId: 'u',
        languages: const ['pt_BR', 'PT'],
      );
      expect(result.map((c) => c.id), contains('c_pt'));
      expect(result.map((c) => c.id), isNot(contains('c_ca')));
    });
  });
}
