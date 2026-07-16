import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/data/models/conversation_model.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/group_info.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';

import '../../support/chat_fixtures.dart';

/// Master Test Plan — Chat/Messaging. ConversationModel serialization.
/// Guards toFirestore / fromFirestore / toGroupFirestore round-trips plus the
/// businessInquiry field and 1:1 helpers that the Exchanges list relies on.
void main() {
  group('ConversationModel.toFirestore', () {
    test('serializes core 1:1 fields including businessInquiry=true', () {
      final conv = ChatFixtures.conversation(
        userId1: 'ava',
        userId2: 'elena',
        businessInquiry: true,
        conversationType: ConversationType.search,
        unreadCount: 3,
      );

      final map = conv.toFirestore();

      expect(map['userId1'], 'ava');
      expect(map['userId2'], 'elena');
      expect(map['matchId'], 'match_1');
      expect(map['businessInquiry'], true);
      expect(map['conversationType'], 'search');
      expect(map['unreadCount'], 3);
      expect(map['theme'], 'gold');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('businessInquiry defaults to false and lastMessage null → null', () {
      final map = ChatFixtures.conversation().toFirestore();
      expect(map['businessInquiry'], false);
      expect(map['lastMessage'], isNull);
      expect(map['lastMessageAt'], isNull);
    });

    test('nests lastMessage with type.value wire string', () {
      final conv = ChatFixtures.conversation(
        lastMessage: ChatFixtures.message(
          content: 'hi',
          type: MessageType.voiceNote,
        ),
        lastMessageAt: DateTime(2026, 7, 15, 13),
      );

      final map = conv.toFirestore();
      final lm = map['lastMessage'] as Map<String, dynamic>;

      expect(lm['content'], 'hi');
      expect(lm['type'], 'voice_note');
      expect(lm['messageId'], 'msg_1');
      expect(lm['sentAt'], isA<Timestamp>());
      expect(map['lastMessageAt'], isA<Timestamp>());
    });
  });

  group('ConversationModel.fromFirestore', () {
    late FakeFirebaseFirestore db;

    setUp(() => db = FakeFirebaseFirestore());

    test('round-trips a businessInquiry conversation through Firestore',
        () async {
      final original = ChatFixtures.conversation(
        conversationId: 'conv_biz',
        userId1: 'ava',
        userId2: 'elena',
        businessInquiry: true,
        unreadCount: 2,
        lastMessage: ChatFixtures.message(content: 'Table for two?'),
        lastMessageAt: DateTime(2026, 7, 15, 14),
      );
      await db
          .collection('conversations')
          .doc('conv_biz')
          .set(original.toFirestore());

      final snap = await db.collection('conversations').doc('conv_biz').get();
      final parsed = ConversationModel.fromFirestore(snap);

      expect(parsed.conversationId, 'conv_biz');
      expect(parsed.userId1, 'ava');
      expect(parsed.userId2, 'elena');
      expect(parsed.businessInquiry, isTrue);
      expect(parsed.unreadCount, 2);
      expect(parsed.lastMessage, isNotNull);
      expect(parsed.lastMessage!.content, 'Table for two?');
      expect(parsed.lastMessage!.type, MessageType.text);
    });

    test('missing fields fall back to safe defaults', () async {
      await db.collection('conversations').doc('bare').set({
        'matchId': 'm',
        'userId1': 'a',
        'userId2': 'b',
      });

      final snap = await db.collection('conversations').doc('bare').get();
      final parsed = ConversationModel.fromFirestore(snap);

      expect(parsed.businessInquiry, isFalse);
      expect(parsed.unreadCount, 0);
      expect(parsed.conversationType, ConversationType.match);
      expect(parsed.theme, ChatTheme.gold);
      expect(parsed.isGroup, isFalse);
      expect(parsed.lastMessage, isNull);
    });

    test('unknown conversationType falls back to match', () async {
      await db.collection('conversations').doc('weird').set({
        'matchId': 'm',
        'userId1': 'a',
        'userId2': 'b',
        'conversationType': 'not_a_real_type',
      });

      final snap = await db.collection('conversations').doc('weird').get();
      final parsed = ConversationModel.fromFirestore(snap);

      expect(parsed.conversationType, ConversationType.match);
    });
  });

  group('ConversationModel.toGroupFirestore', () {
    test('emits isGroup + group type + participants + groupInfo map', () {
      final group = ChatFixtures.groupConversation(
        participants: const ['a', 'b', 'c'],
        groupInfo: const GroupInfo(
          name: 'Lisbon Explorers',
          createdBy: 'a',
          language: 'pt',
        ),
        roles: const {'a': 'admin', 'b': 'member', 'c': 'member'},
        unreadCounts: const {'a': 0, 'b': 2, 'c': 5},
        lastMessage: ChatFixtures.message(content: 'welcome'),
      );

      final map = group.toGroupFirestore();

      expect(map['isGroup'], true);
      expect(map['conversationType'], 'group');
      expect(map['participants'], ['a', 'b', 'c']);
      expect((map['groupInfo'] as Map)['name'], 'Lisbon Explorers');
      expect((map['groupInfo'] as Map)['language'], 'pt');
      expect(map['roles'], {'a': 'admin', 'b': 'member', 'c': 'member'});
      expect(map['unreadCounts'], {'a': 0, 'b': 2, 'c': 5});
    });

    test('group lastMessage omits receiverId (group-shaped)', () {
      final group = ChatFixtures.groupConversation(
        lastMessage: ChatFixtures.message(
          content: 'gif!',
          type: MessageType.gif,
        ),
      );

      final lm = group.toGroupFirestore()['lastMessage'] as Map<String, dynamic>;

      expect(lm.containsKey('receiverId'), isFalse);
      expect(lm['type'], 'gif');
      expect(lm['content'], 'gif!');
    });

    test('participants come from participantIds when set', () async {
      final db = FakeFirebaseFirestore();
      final group = ChatFixtures.groupConversation(
        conversationId: 'g_round',
        participants: const ['a', 'b', 'c', 'd'],
      );
      await db.collection('groups').doc('g_round').set(group.toGroupFirestore());

      final snap = await db.collection('groups').doc('g_round').get();
      final parsed = ConversationModel.fromFirestore(snap);

      expect(parsed.isGroup, isTrue);
      expect(parsed.participants, ['a', 'b', 'c', 'd']);
      expect(parsed.isGroupConversation, isTrue);
      expect(parsed.memberCount, 4);
    });
  });

  group('Conversation.getOtherUserId + participant helpers', () {
    test('getOtherUserId returns the counterpart for either side', () {
      final conv = ChatFixtures.conversation(userId1: 'ava', userId2: 'elena');
      expect(conv.getOtherUserId('ava'), 'elena');
      expect(conv.getOtherUserId('elena'), 'ava');
    });

    test('getOtherUserId returns userId1 for an unknown caller', () {
      // Impl: currentUserId == userId1 ? userId2 : userId1 — so any caller that
      // is not userId1 (incl. a stranger) resolves to userId1.
      final conv = ChatFixtures.conversation(userId1: 'ava', userId2: 'elena');
      expect(conv.getOtherUserId('stranger'), 'ava');
    });

    test('participantIds derives from userId1/userId2 for 1:1', () {
      final conv = ChatFixtures.conversation(userId1: 'ava', userId2: 'elena');
      expect(conv.participantIds, ['ava', 'elena']);
      expect(conv.isGroupConversation, isFalse);
      expect(conv.memberCount, 2);
    });

    test('group unreadCountFor reads the per-member map', () {
      final group = ChatFixtures.groupConversation(
        unreadCounts: const {'a': 0, 'b': 7},
      );
      expect(group.unreadCountFor('b'), 7);
      expect(group.unreadCountFor('a'), 0);
    });

    test('roleOf/isAdmin reflect the roles map (default member)', () {
      final group = ChatFixtures.groupConversation(
        roles: const {'a': 'admin', 'b': 'member'},
      );
      expect(group.isAdmin('a'), isTrue);
      expect(group.isAdmin('b'), isFalse);
      expect(group.roleOf('nobody'), GroupRole.member);
    });
  });
}
