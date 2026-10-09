import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/blocked_users_service.dart';
import 'package:greengo_chat/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:greengo_chat/features/chat/domain/chat_system_message.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';

/// Write side of client-written chat texts: every app-written line stores a
/// stable `metadata.systemKey` (+ params) AND keeps the English `content`
/// that older app versions and server push code read.
void main() {
  late FakeFirebaseFirestore fs;
  late ChatRemoteDataSourceImpl ds;

  setUp(() async {
    fs = FakeFirebaseFirestore();
    ds = ChatRemoteDataSourceImpl(
      firestore: fs,
      blockedUsersService: BlockedUsersService(firestore: fs),
    );
    await fs.collection('conversations').doc('c1').set({
      'matchId': 'm1',
      'userId1': 'a',
      'userId2': 'b',
      'createdAt': Timestamp.now(),
      'lastMessage': {
        'messageId': 'msg1',
        'senderId': 'a',
        'receiverId': 'b',
        'content': 'secret text',
        'type': 'text',
        'sentAt': Timestamp.now(),
      },
    });
  });

  Future<Map<String, dynamic>> onlyMessage() async {
    final snap =
        await fs.collection('conversations').doc('c1').collection('messages').get();
    expect(snap.docs, hasLength(1));
    return snap.docs.single.data();
  }

  test('delete for everyone stores the key and clears the inbox preview',
      () async {
    await fs
        .collection('conversations')
        .doc('c1')
        .collection('messages')
        .doc('msg1')
        .set({
      'senderId': 'a',
      'receiverId': 'b',
      'content': 'secret text',
      'type': 'text',
      'sentAt': Timestamp.now(),
    });

    await ds.deleteMessageForBoth(
        messageId: 'msg1', conversationId: 'c1', userId: 'a');

    final msg = await onlyMessage();
    expect(msg['content'], 'This message was deleted');
    expect((msg['metadata'] as Map)['systemKey'], ChatSystemKey.messageDeleted);

    final conv = (await fs.collection('conversations').doc('c1').get()).data()!;
    final last = conv['lastMessage'] as Map;
    expect(last['content'], isNot('secret text'));
    expect((last['metadata'] as Map)['systemKey'], ChatSystemKey.messageDeleted);
  });

  test('support status line stores status key + English fallback', () async {
    await ds.updateSupportTicketStatus(
        conversationId: 'c1', status: SupportTicketStatus.waitingOnUser);
    final msg = await onlyMessage();
    expect(msg['type'], 'system');
    expect(msg['content'], "We're waiting for your response.");
    final meta = msg['metadata'] as Map;
    expect(meta['systemKey'], ChatSystemKey.supportStatus);
    expect((meta['systemParams'] as Map)['status'], 'waitingOnUser');
  });

  test('agent joined stores the raw (possibly empty) name as a param',
      () async {
    await ds.assignSupportAgent(conversationId: 'c1', agentId: 'agent1');
    final msg = await onlyMessage();
    expect(msg['content'],
        'Support Agent has joined the conversation and will assist you.');
    final meta = msg['metadata'] as Map;
    expect(meta['systemKey'], ChatSystemKey.supportAgentJoined);
    expect((meta['systemParams'] as Map)['name'], '');
  });
}
