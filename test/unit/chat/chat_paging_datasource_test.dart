import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/blocked_users_service.dart';
import 'package:greengo_chat/features/chat/data/chat_constants.dart';
import 'package:greengo_chat/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:greengo_chat/features/chat/data/datasources/group_chat_remote_datasource.dart';

final _t0 = DateTime(2026, 10, 24, 9);

Map<String, dynamic> _doc(int i, {Map<String, dynamic>? metadata}) => {
  'matchId': 'match1',
  'conversationId': 'c1',
  'senderId': i.isEven ? 'a' : 'b',
  'receiverId': i.isEven ? 'b' : 'a',
  'content': 'text $i',
  'type': 'text',
  'sentAt': Timestamp.fromDate(_t0.add(Duration(minutes: i))),
  'metadata': metadata,
};

void main() {
  late FakeFirebaseFirestore db;
  late ChatRemoteDataSourceImpl ds;

  Future<void> seed(
    String path,
    int count, {
    Set<int> deletedForA = const {},
  }) async {
    final col = db.collection(path);
    for (var i = 0; i < count; i++) {
      await col
          .doc('m$i')
          .set(
            _doc(
              i,
              metadata: deletedForA.contains(i)
                  ? {
                      'deletedFor': {'a': true},
                    }
                  : null,
            ),
          );
    }
  }

  setUp(() {
    db = FakeFirebaseFirestore();
    ds = ChatRemoteDataSourceImpl(
      firestore: db,
      blockedUsersService: BlockedUsersService(firestore: db),
    );
  });

  test('the live window reads ONLY the newest 20 messages', () async {
    expect(kChatPageSize, 20);
    await seed('conversations/c1/messages', 75);
    final page = await ds.watchLatestMessages(conversationId: 'c1').first;
    expect(page.messages.length, 20);
    expect(page.messages.first.messageId, 'm74');
    expect(page.messages.last.messageId, 'm55');
    expect(page.hasMore, isTrue);
    expect(page.cursor, _t0.add(const Duration(minutes: 55)));
  });

  test('older pages: 20 each, cursor-based, until the history ends', () async {
    await seed('conversations/c1/messages', 45);
    final live = await ds.watchLatestMessages(conversationId: 'c1').first;
    final p1 = await ds.getOlderMessages(
      conversationId: 'c1',
      before: live.cursor!,
    );
    expect(p1.messages.map((m) => m.messageId).first, 'm24');
    expect(p1.messages.length, 20);
    expect(p1.hasMore, isTrue);

    final p2 = await ds.getOlderMessages(
      conversationId: 'c1',
      before: p1.cursor!,
    );
    expect(p2.messages.map((m) => m.messageId), ['m4', 'm3', 'm2', 'm1', 'm0']);
    expect(p2.hasMore, isFalse);

    final all = {
      ...live.messages.map((m) => m.messageId),
      ...p1.messages.map((m) => m.messageId),
      ...p2.messages.map((m) => m.messageId),
    };
    expect(all.length, 45); // every message exactly once
  });

  test(
    'deleted-for-me messages are hidden but the cursor passes them',
    () async {
      await seed(
        'conversations/c1/messages',
        30,
        deletedForA: {for (var i = 0; i < 10; i++) i},
      );
      final live = await ds
          .watchLatestMessages(conversationId: 'c1', userId: 'a')
          .first;
      final older = await ds.getOlderMessages(
        conversationId: 'c1',
        userId: 'a',
        before: live.cursor!,
      );
      expect(older.messages, isEmpty);
      expect(older.cursor, _t0); // m0 was read
      expect(older.hasMore, isFalse);
    },
  );

  test('group chats page the same way', () async {
    final groups = GroupChatRemoteDataSourceImpl(firestore: db);
    await seed('groups/g1/messages', 33);
    final live = await groups.watchLatestGroupMessages(groupId: 'g1').first;
    expect(live.messages.length, 20);
    expect(live.messages.first.messageId, 'm32');
    final older = await groups.getOlderGroupMessages(
      groupId: 'g1',
      before: live.cursor!,
    );
    expect(older.messages.length, 13);
    expect(older.messages.first.messageId, 'm12');
    expect(older.hasMore, isFalse);
  });
}
