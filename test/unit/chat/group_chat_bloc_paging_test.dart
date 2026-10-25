import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/chat/data/datasources/chat_message_cache.dart';
import 'package:greengo_chat/features/chat/domain/entities/message.dart';
import 'package:greengo_chat/features/chat/domain/entities/message_page.dart';
import 'package:greengo_chat/features/chat/domain/repositories/group_chat_repository.dart';
import 'package:greengo_chat/features/chat/domain/usecases/get_group_messages.dart';
import 'package:greengo_chat/features/chat/domain/usecases/group_membership.dart';
import 'package:greengo_chat/features/chat/domain/usecases/mark_group_read.dart';
import 'package:greengo_chat/features/chat/domain/usecases/send_group_message.dart';
import 'package:greengo_chat/features/chat/presentation/bloc/group_chat_bloc.dart';
import 'package:greengo_chat/features/chat/presentation/bloc/group_chat_event.dart';
import 'package:greengo_chat/features/chat/presentation/bloc/group_chat_state.dart';

final _t0 = DateTime(2026, 10, 24, 9);

Message msg(int i, {String sender = 'b'}) => Message(
  messageId: 'm$i',
  matchId: 'g1',
  conversationId: 'g1',
  senderId: sender,
  receiverId: '',
  content: 'text $i',
  type: MessageType.text,
  sentAt: _t0.add(Duration(minutes: i)),
);

MessagePage page(int from, int to, {int limit = 20}) {
  final read = [for (var i = to; i >= from; i--) i];
  return MessagePage(
    messages: [for (final i in read) msg(i)],
    hasMore: read.length >= limit,
    cursor: read.isEmpty ? null : msg(read.last).sentAt,
  );
}

class FakeGroupChatRepository implements GroupChatRepository {
  final live = StreamController<Either<Failure, MessagePage>>.broadcast();
  final latestLimits = <int?>[];
  final olderCalls = <(DateTime, int?)>[];
  int markReadCalls = 0;

  @override
  Stream<Either<Failure, MessagePage>> watchLatestGroupMessages({
    required String groupId,
    int? limit,
  }) {
    latestLimits.add(limit);
    return live.stream;
  }

  @override
  Future<Either<Failure, MessagePage>> getOlderGroupMessages({
    required String groupId,
    required DateTime before,
    int? limit,
  }) async {
    olderCalls.add((before, limit));
    return Right(page(20, 39));
  }

  @override
  Future<Either<Failure, void>> markGroupRead({
    required String groupId,
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
  late FakeGroupChatRepository repo;
  late JsonChatMessageCache cache;
  late GroupChatBloc bloc;

  setUp(() {
    repo = FakeGroupChatRepository();
    cache = JsonChatMessageCache(store: MemoryChatMessageCacheStore());
    bloc = GroupChatBloc(
      getGroupMessages: GetGroupMessages(repo),
      sendGroupMessage: SendGroupMessage(repo),
      markGroupRead: MarkGroupRead(repo),
      addGroupMembers: AddGroupMembers(repo),
      removeGroupMember: RemoveGroupMember(repo),
      leaveGroup: LeaveGroup(repo),
      updateGroupInfo: UpdateGroupInfo(repo),
      changeGroupRole: ChangeGroupRole(repo),
      repository: repo,
      messageCache: cache,
    );
  });

  tearDown(() async {
    await bloc.close();
    await repo.live.close();
  });

  List<String> shown() => [
    for (final m in (bloc.state as GroupChatLoaded).messages) m.messageId,
  ];

  test('cache first, then a live window of 20', () async {
    await cache.save(ChatMessageCache.group('g1'), [
      for (var i = 0; i < 10; i++) msg(i),
    ]);
    bloc.add(const GroupChatStarted(groupId: 'g1', userId: 'a'));
    await _settle();
    expect(shown().length, 10);
    expect(repo.latestLimits, [20]);

    repo.live.add(Right(page(5, 12)));
    await _settle();
    expect(shown(), [for (var i = 12; i >= 0; i--) 'm$i']);
  });

  test('scrolling loads an older page with a cursor and never adds a '
      'second listener', () async {
    bloc.add(const GroupChatStarted(groupId: 'g1', userId: 'a'));
    await _settle();
    repo.live.add(Right(page(40, 59)));
    await _settle();

    bloc.add(const GroupChatOlderRequested());
    await _settle();
    expect(repo.olderCalls.single, (msg(40).sentAt, 20));
    expect(shown().length, 40);
    expect(shown().toSet().length, 40);
    expect(repo.latestLimits, [20]); // still ONE live listener
  });

  test('marks read on open and when someone else posts while open', () async {
    bloc.add(const GroupChatStarted(groupId: 'g1', userId: 'a'));
    await _settle();
    expect(repo.markReadCalls, 1);
    repo.live.add(Right(page(1, 5)));
    await _settle();
    repo.live.add(Right(page(1, 5))); // no new message
    await _settle();
    expect(repo.markReadCalls, 1);
    repo.live.add(
      Right(
        MessagePage(
          messages: [msg(6), ...page(1, 5).messages],
          hasMore: false,
          cursor: msg(1).sentAt,
        ),
      ),
    );
    await _settle();
    expect(repo.markReadCalls, 2);
  });
}
