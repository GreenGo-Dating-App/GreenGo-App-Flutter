import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/services/usage_limit_service.dart';
import 'package:greengo_chat/features/chat/data/datasources/chat_message_cache.dart';
import 'package:greengo_chat/features/chat/domain/entities/conversation.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/domain/entities/message_page.dart';
import 'package:greengo_chat/features/chat/domain/repositories/chat_repository.dart';
import 'package:greengo_chat/features/chat/domain/usecases/block_user.dart';
import 'package:greengo_chat/features/chat/domain/usecases/delete_conversation.dart';
import 'package:greengo_chat/features/chat/domain/usecases/delete_message.dart';
import 'package:greengo_chat/features/chat/domain/usecases/forward_message.dart';
import 'package:greengo_chat/features/chat/domain/usecases/get_conversation.dart';
import 'package:greengo_chat/features/chat/domain/usecases/get_messages.dart';
import 'package:greengo_chat/features/chat/domain/usecases/mark_as_read.dart';
import 'package:greengo_chat/features/chat/domain/usecases/report_user.dart';
import 'package:greengo_chat/features/chat/domain/usecases/send_message.dart';
import 'package:greengo_chat/features/chat/domain/usecases/set_typing_indicator.dart';
import 'package:greengo_chat/features/chat/domain/usecases/star_message.dart';
import 'package:greengo_chat/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:greengo_chat/features/chat/presentation/bloc/chat_event.dart';
import 'package:greengo_chat/features/chat/presentation/bloc/chat_state.dart';

final _t0 = DateTime(2026, 10, 24, 9);

/// `m<i>` from b to a, sent [i] minutes after 9:00 (already read).
Message msg(int i) => Message(
  messageId: 'm$i',
  matchId: 'match1',
  conversationId: 'c1',
  senderId: 'b',
  receiverId: 'a',
  content: 'text $i',
  type: MessageType.text,
  sentAt: _t0.add(Duration(minutes: i)),
  readAt: _t0,
);

MessagePage page(int from, int to, {int limit = 20, bool fromCache = false}) {
  final read = [for (var i = to; i >= from; i--) i];
  return MessagePage(
    messages: [for (final i in read) msg(i)],
    hasMore: read.length >= limit,
    cursor: read.isEmpty ? null : msg(read.last).sentAt,
    fromCache: fromCache,
  );
}

final _conversation = Conversation(
  conversationId: 'c1',
  matchId: 'match1',
  userId1: 'a',
  userId2: 'b',
  createdAt: _t0,
);

/// Records what the bloc reads; the live window is driven by the test.
class FakeChatRepository implements ChatRepository {
  final live = StreamController<Either<Failure, MessagePage>>.broadcast();
  final latestLimits = <int?>[];
  final olderCalls = <(DateTime, int?)>[];
  MessagePage Function(DateTime before) olderAnswer = (_) =>
      const MessagePage(messages: [], hasMore: false);
  int getConversationCalls = 0;
  int markReadCalls = 0;

  /// getConversation answers only when this completes (null = at once).
  Completer<void>? conversationGate;

  /// getOlderMessages answers only when this completes (null = at once).
  Completer<void>? olderGate;

  @override
  Future<Either<Failure, Conversation>> getConversation(String matchId) async {
    getConversationCalls++;
    await conversationGate?.future;
    return Right(_conversation);
  }

  @override
  Stream<Either<Failure, MessagePage>> watchLatestMessages({
    required String conversationId,
    String? userId,
    int? limit,
  }) {
    latestLimits.add(limit);
    return live.stream;
  }

  @override
  Future<Either<Failure, MessagePage>> getOlderMessages({
    required String conversationId,
    required DateTime before,
    String? userId,
    int? limit,
  }) async {
    olderCalls.add((before, limit));
    await olderGate?.future;
    return Right(olderAnswer(before));
  }

  @override
  Future<Either<Failure, void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    markReadCalls++;
    return const Right(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle([int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeChatRepository repo;
  late MemoryChatMessageCacheStore store;
  late JsonChatMessageCache cache;
  late ChatBloc bloc;

  ChatBloc build() => ChatBloc(
    getConversation: GetConversation(repo),
    getMessages: GetMessages(repo),
    sendMessage: SendMessage(repo),
    markAsRead: MarkAsRead(repo),
    setTypingIndicator: SetTypingIndicator(repo),
    deleteMessage: DeleteMessage(repo),
    deleteMessageForMe: DeleteMessageForMe(repo),
    deleteMessageForBoth: DeleteMessageForBoth(repo),
    blockUser: BlockUser(repo),
    unblockUser: UnblockUser(repo),
    reportUser: ReportUser(repo),
    starMessage: StarMessage(repo),
    forwardMessage: ForwardMessage(repo),
    deleteConversationForMe: DeleteConversationForMe(repo),
    deleteConversationForBoth: DeleteConversationForBoth(repo),
    usageLimitService: UsageLimitService(firestore: FakeFirebaseFirestore()),
    messageCache: cache,
  );

  void open({Conversation? conversation}) => bloc.add(
    ChatConversationLoaded(
      matchId: 'match1',
      currentUserId: 'a',
      otherUserId: 'b',
      conversation: conversation,
    ),
  );

  List<String> shown() {
    final st = bloc.state;
    expect(st, isA<ChatLoaded>());
    return [for (final m in (st as ChatLoaded).messages) m.messageId];
  }

  setUp(() {
    repo = FakeChatRepository();
    store = MemoryChatMessageCacheStore();
    cache = JsonChatMessageCache(store: store);
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await repo.live.close();
  });

  test('cache first: cached messages paint before the conversation read and '
      'before any snapshot', () async {
    await cache.save(ChatMessageCache.direct('match1'), [
      for (var i = 0; i < 30; i++) msg(i),
    ], conversation: _conversation);
    repo.conversationGate = Completer<void>(); // the read never answers

    open();
    await _settle();

    expect(shown().length, 30);
    expect(shown().first, 'm29');
    expect((bloc.state as ChatLoaded).messagesReady, isTrue);
    // The live window is already subscribed (conversation from the cache),
    // and the conversation is only refreshed in the background.
    expect(repo.latestLimits, [20]);
    expect(repo.getConversationCalls, 1);
    repo.conversationGate!.complete();
  });

  test('without a cache the list waits for the first snapshot (no empty '
      '"say hi" flash)', () async {
    open(conversation: _conversation);
    await _settle();
    final st = bloc.state as ChatLoaded;
    expect(st.messages, isEmpty);
    expect(st.messagesReady, isFalse);

    repo.live.add(Right(page(1, 3)));
    await _settle();
    expect(shown(), ['m3', 'm2', 'm1']);
    expect((bloc.state as ChatLoaded).messagesReady, isTrue);
  });

  test('the first (and only live) query is limited to 20; nothing older is '
      'read on open', () async {
    open(conversation: _conversation);
    await _settle();
    repo.live.add(Right(page(40, 59)));
    await _settle();
    expect(repo.latestLimits, [20]);
    expect(repo.olderCalls, isEmpty);
    expect(shown().length, 20);
    expect((bloc.state as ChatLoaded).hasMore, isTrue);
  });

  test('scrolling up loads older pages of 20 with a cursor', () async {
    repo.olderAnswer = (before) => before == msg(40).sentAt
        ? page(20, 39)
        : page(5, 19); // 15 read: the history ends
    open(conversation: _conversation);
    await _settle();
    repo.live.add(Right(page(40, 59)));
    await _settle();

    bloc.add(const ChatOlderMessagesRequested());
    await _settle();
    expect(repo.olderCalls.single, (msg(40).sentAt, 20));
    expect(shown().length, 40);
    expect(shown().last, 'm20');

    bloc.add(const ChatOlderMessagesRequested());
    await _settle();
    expect(repo.olderCalls.last, (msg(20).sentAt, 20));
    expect(shown().last, 'm5');
    expect((bloc.state as ChatLoaded).hasMore, isFalse);

    // History complete: no more reads.
    bloc.add(const ChatOlderMessagesRequested());
    await _settle();
    expect(repo.olderCalls.length, 2);
    // Older pages are never re-read by the live listener.
    expect(repo.latestLimits, [20]);
  });

  test('repeated scroll events while a page loads read it once', () async {
    repo
      ..olderAnswer = ((_) => page(20, 39))
      ..olderGate = Completer<void>();
    open(conversation: _conversation);
    await _settle();
    repo.live.add(Right(page(40, 59)));
    await _settle();
    bloc
      ..add(const ChatOlderMessagesRequested())
      ..add(const ChatOlderMessagesRequested())
      ..add(const ChatOlderMessagesRequested());
    await _settle();
    expect(repo.olderCalls.length, 1);
    expect((bloc.state as ChatLoaded).loadingOlder, isTrue);
    repo.olderGate!.complete();
    await _settle();
    expect((bloc.state as ChatLoaded).loadingOlder, isFalse);
    expect(shown().length, 40);
  });

  test('no duplicates when the cache and the server overlap', () async {
    await cache.save(ChatMessageCache.direct('match1'), [
      for (var i = 10; i <= 59; i++) msg(i),
    ], conversation: _conversation);
    open(conversation: _conversation);
    await _settle();
    expect(shown().length, 50);

    repo.live.add(Right(page(45, 64)));
    await _settle();
    final ids = shown();
    expect(ids.toSet().length, ids.length);
    expect(ids.length, 55); // m10..m64
    expect(ids.first, 'm64');
  });

  test('an empty local-cache snapshot keeps the painted copy', () async {
    await cache.save(ChatMessageCache.direct('match1'), [
      msg(1),
      msg(2),
    ], conversation: _conversation);
    open(conversation: _conversation);
    await _settle();
    repo.live.add(Right(page(0, -1, fromCache: true)));
    await _settle();
    expect(shown(), ['m2', 'm1']);
  });

  test('server snapshots are written to the bounded cache', () async {
    open(conversation: _conversation);
    await _settle();
    repo.live.add(Right(page(40, 59)));
    await _settle();
    final saved = await cache.load(ChatMessageCache.direct('match1'));
    expect(saved?.messages.length, 20);
    expect(saved?.conversation?.conversationId, 'c1');
  });

  test('mark-as-read runs on open and for new unread messages, not on '
      'every snapshot', () async {
    open(conversation: _conversation);
    await _settle();
    repo.live.add(Right(page(1, 5)));
    await _settle();
    expect(repo.markReadCalls, 1);

    // A read-receipt / reaction update: nothing unread → no new write.
    repo.live.add(Right(page(1, 5)));
    await _settle();
    expect(repo.markReadCalls, 1);

    // A new incoming unread message.
    final unread = Message(
      messageId: 'm6',
      matchId: 'match1',
      conversationId: 'c1',
      senderId: 'b',
      receiverId: 'a',
      content: 'new',
      type: MessageType.text,
      sentAt: _t0.add(const Duration(minutes: 6)),
    );
    repo.live.add(
      Right(
        MessagePage(
          messages: [unread, ...page(1, 5).messages],
          hasMore: false,
          cursor: msg(1).sentAt,
        ),
      ),
    );
    await _settle();
    expect(repo.markReadCalls, 2);
  });
}
