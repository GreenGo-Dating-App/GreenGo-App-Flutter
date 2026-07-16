import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Shared test fixtures — mirrors the production seeder
/// (`functions/src/admin/mockData.ts`) so tests exercise the SAME document
/// shapes the app reads in prod. See docs/testing/GREENGO_MASTER_TEST_PLAN.md.
class MockUsers {
  static const free = 'mock_user_1'; // Ava Reyes
  static const silver = 'mock_user_2'; // Bruno Costa
  static const gold = 'mock_user_3'; // Clara Nunes
  static const platinum = 'mock_user_4'; // Diego Alves
  static const business = 'mock_user_5'; // Elena Marco / Elena's Cafe

  static const all = [free, silver, gold, platinum, business];
  static const names = {
    free: 'Ava Reyes',
    silver: 'Bruno Costa',
    gold: 'Clara Nunes',
    platinum: 'Diego Alves',
    business: 'Elena Marco',
  };
}

/// Builds a FakeFirebaseFirestore preloaded with mock communities so query
/// tests run without a real backend.
class MockFirestore {
  static Future<FakeFirebaseFirestore> withCommunities() async {
    final db = FakeFirebaseFirestore();
    final now = DateTime(2026, 7, 15, 12);

    // 5 public communities, each created by a different mock user.
    for (var i = 0; i < 5; i++) {
      final id = 'mock_comm_${i + 1}';
      final ownerN = (i % 5) + 1;
      final ownerUid = 'mock_user_$ownerN';
      await db.collection('communities').doc(id).set({
        'name': 'Mock Community ${i + 1}',
        'description': 'A test community',
        'type': 'general',
        'imageUrl': 'https://example.com/$id.png',
        'createdByUserId': ownerUid,
        'createdByName': MockUsers.names[ownerUid],
        'createdAt': Timestamp.fromDate(now),
        'memberCount': 3,
        'languages': ['en', 'pt'],
        'tags': const ['community', 'test'],
        'isPublic': true,
        'city': 'Lisbon',
        'country': 'Portugal',
        'lastActivityAt': Timestamp.fromDate(
          now.subtract(Duration(hours: i)),
        ),
        'isMock': true,
      });
      // Creator member doc (so membership-based reads see it too).
      await db
          .collection('communities')
          .doc(id)
          .collection('members')
          .doc(ownerUid)
          .set({
        'userId': ownerUid,
        'displayName': MockUsers.names[ownerUid],
        'role': 'owner',
        'joinedAt': Timestamp.fromDate(now),
        'isMock': true,
      });
    }
    return db;
  }
}
