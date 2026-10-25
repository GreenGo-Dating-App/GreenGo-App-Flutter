import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/data/datasources/chat_message_cache.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';

final _t0 = DateTime(2026, 10, 24, 9);

Message msg(int i, {Map<String, dynamic>? metadata}) => Message(
  messageId: 'm$i',
  matchId: 'match1',
  conversationId: 'c1',
  senderId: 'a',
  receiverId: 'b',
  content: 'text $i',
  type: MessageType.text,
  sentAt: _t0.add(Duration(minutes: i)),
  metadata: metadata,
);

void main() {
  late MemoryChatMessageCacheStore store;
  late JsonChatMessageCache cache;

  setUp(() {
    store = MemoryChatMessageCacheStore();
    cache = JsonChatMessageCache(store: store);
  });

  test('round trip keeps the message, its stored translation and the '
      'conversation', () async {
    final m = Message(
      messageId: 'm1',
      matchId: 'match1',
      conversationId: 'c1',
      senderId: 'a',
      receiverId: 'b',
      content: 'Olá',
      type: MessageType.text,
      sentAt: _t0,
      readAt: _t0.add(const Duration(minutes: 1)),
      reactions: const {'b': '❤️'},
      tr: const {'en': 'Hello'},
      trHash: 'h1',
      lang: 'pt',
    );
    final conv = Conversation(
      conversationId: 'c1',
      matchId: 'match1',
      userId1: 'a',
      userId2: 'b',
      createdAt: _t0,
    );
    await cache.save(ChatMessageCache.direct('match1'), [
      m,
    ], conversation: conv);
    // Stored as plain JSON (what Hive keeps).
    jsonEncode(store.values);

    final back = await cache.load(ChatMessageCache.direct('match1'));
    expect(back, isNotNull);
    expect(back!.messages.single.props, m.props);
    expect(back.messages.single.tr, {'en': 'Hello'});
    expect(back.conversation?.conversationId, 'c1');
    expect(back.conversation?.userId2, 'b');
  });

  test('metadata with Firestore values survives JSON', () async {
    final ts = Timestamp.fromDate(_t0);
    await cache.save(ChatMessageCache.group('g1'), [
      msg(
        1,
        metadata: {
          'deletedFor': {'x': true},
          'at': ts,
          'where': const GeoPoint(38.7, -9.1),
          'entities': [
            {
              'k': 'city',
              'refs': ['lisbon'],
            },
          ],
        },
      ),
    ]);
    jsonEncode(store.values);
    final md = (await cache.load(
      ChatMessageCache.group('g1'),
    ))!.messages.single.metadata!;
    expect(md['deletedFor'], {'x': true});
    expect(md['at'], ts);
    expect(md['where'], const GeoPoint(38.7, -9.1));
    expect((md['entities'] as List).single, {
      'k': 'city',
      'refs': ['lisbon'],
    });
  });

  test('bounded: the newest 50 messages per chat, newest first', () async {
    await cache.save('k', [for (var i = 0; i < 80; i++) msg(i)]);
    final kept = (await cache.load('k'))!.messages;
    expect(kept.length, JsonChatMessageCache.maxMessages);
    expect(kept.first.messageId, 'm79');
    expect(kept.last.messageId, 'm30');
  });

  test('bounded: the most recently used chats only', () async {
    for (var c = 0; c <= JsonChatMessageCache.maxChats; c++) {
      await cache.save('chat$c', [msg(c)]);
    }
    // The first chat was dropped; the others are kept.
    expect(await cache.load('chat0'), isNull);
    expect(await cache.load('chat1'), isNotNull);
    expect(await cache.load('chat${JsonChatMessageCache.maxChats}'), isNotNull);
  });

  test('clear removes one chat; an empty list is not saved', () async {
    await cache.save('a', [msg(1)]);
    await cache.save('b', []);
    expect(await cache.load('b'), isNull);
    await cache.clear('a');
    expect(await cache.load('a'), isNull);
  });

  test('a corrupt entry reads as no cache', () async {
    store.values[JsonChatMessageCache.keyOf('x')] = {'m': 'garbage'};
    expect(await cache.load('x'), isNull);
    store.values[JsonChatMessageCache.keyOf('y')] = 42;
    expect(await cache.load('y'), isNull);
  });
}
