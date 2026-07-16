import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:greengo_chat/features/communities/data/datasources/communities_remote_datasource.dart';

/// Master Test Plan — Universal Search / Community tab.
/// The screen's `_searchCommunities` delegates to
/// `CommunitiesRepository.getCommunities(searchQuery:)`, which runs the
/// datasource's client-side substring search over name / description / tags of
/// public communities. These tests exercise that search directly against a fake
/// Firestore.
void main() {
  final now = DateTime(2026, 7, 15, 12);

  Future<FakeFirebaseFirestore> seed() async {
    final db = FakeFirebaseFirestore();

    Future<void> add(
      String id, {
      required String name,
      required String description,
      required List<String> tags,
      bool isPublic = true,
    }) async {
      await db.collection('communities').doc(id).set({
        'name': name,
        'description': description,
        'type': 'general',
        'createdByUserId': 'system',
        'createdByName': 'GreenGo',
        'createdAt': Timestamp.fromDate(now),
        'memberCount': 10,
        'languages': const ['en'],
        'tags': tags,
        'isPublic': isPublic,
        'lastActivityAt': Timestamp.fromDate(now),
      });
    }

    await add('c_spanish',
        name: 'Spanish Learners Worldwide',
        description: 'Practice conversation with native speakers',
        tags: const ['spanish', 'language-learning']);
    await add('c_japan',
        name: 'Japanese Culture Explorers',
        description: 'From anime to tea ceremonies',
        tags: const ['japan', 'culture', 'anime']);
    await add('c_private',
        name: 'Secret Spanish Society',
        description: 'invite only',
        tags: const ['spanish'],
        isPublic: false);
    return db;
  }

  test('matches on community NAME (case-insensitive)', () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: 'japanese');
    expect(result.map((c) => c.id), ['c_japan']);
  });

  test('matches on DESCRIPTION text', () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: 'anime');
    expect(result.map((c) => c.id), contains('c_japan'));
  });

  test('matches on a TAG', () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: 'language-learning');
    expect(result.map((c) => c.id), ['c_spanish']);
  });

  test('a query hitting several public communities returns them all', () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: 'spanish');
    // Both the public Spanish community (name) — private one is excluded.
    expect(result.map((c) => c.id), ['c_spanish']);
  });

  test('never surfaces a non-public community even on a match', () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: 'secret');
    expect(result, isEmpty);
  });

  test('a no-match query yields an empty list', () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: 'zzz-nothing-zzz');
    expect(result, isEmpty);
  });

  test('empty searchQuery returns all public communities (no narrowing)',
      () async {
    final ds = CommunitiesRemoteDataSourceImpl(firestore: await seed());
    final result = await ds.getCommunities(searchQuery: '');
    expect(result.length, 2);
    expect(result.every((c) => c.isPublic), isTrue);
  });
}
