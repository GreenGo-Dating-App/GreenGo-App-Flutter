import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_exception.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/bloc/buddy_chat_bloc.dart';

import '../../support/buddies_fakes.dart';

Future<void> _settle([int n = 3]) async {
  for (var i = 0; i < n; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeBuddiesRepository repo;
  late BuddyChatBloc bloc;
  final t0 = DateTime(2026, 10, 20, 12);

  setUp(() {
    repo = FakeBuddiesRepository();
    bloc = BuddyChatBloc(repository: repo, pageSize: 2);
  });

  tearDown(() async {
    await bloc.close();
    await repo.dispose();
  });

  Future<void> start({bool locked = false}) async {
    bloc.add(BuddyChatStarted(uid: 'u1', buddyId: 'b1', locked: locked));
    await _settle();
  }

  group('pure helpers', () {
    test('mergeServerMessages dedupes by id and sorts by time', () {
      final a = fakeMessage('a', BuddyMessageRole.user, 'hi', t0);
      final b = fakeMessage('b', BuddyMessageRole.buddy, 'hey', t0.add(const Duration(seconds: 1)));
      expect(mergeServerMessages([b], [a, b]).map((m) => m.id), ['a', 'b']);
    });

    test('mergeServerMessages never drops a known translation', () {
      final withT = fakeMessage('a', BuddyMessageRole.buddy, 'hey', t0, translation: 'ciao');
      final without = fakeMessage('a', BuddyMessageRole.buddy, 'hey', t0);
      expect(mergeServerMessages([withT], [without]).single.translation?.text, 'ciao');
    });

    test('reconcileLocal: each server message replaces one delivered local message', () {
      final local = [
        BuddyMessage(id: 'local_1', role: BuddyMessageRole.user, text: 'hi', createdAt: t0),
        BuddyMessage(
            id: 'local_2',
            role: BuddyMessageRole.user,
            text: 'hi',
            createdAt: t0,
            delivery: BuddyDelivery.failed),
      ];
      final r = reconcileLocal(local, [
        fakeMessage('s1', BuddyMessageRole.user, 'hi', t0),
        fakeMessage('s2', BuddyMessageRole.buddy, 'checkin', t0),
      ]);
      expect(r.local.map((m) => m.id), ['local_2'], reason: 'failed messages stay');
      expect(r.unmatched.map((m) => m.id), ['s2']);
    });
  });

  test('start: newest page, status and hasMore', () async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Hello', t0),
      fakeMessage('m2', BuddyMessageRole.user, 'Hi', t0.add(const Duration(minutes: 1))),
    ], hasMore: true);
    await start();
    expect(bloc.state.loading, isFalse);
    expect(bloc.state.messages.map((m) => m.id), ['m1', 'm2']);
    expect(bloc.state.hasMore, isTrue);
    expect(bloc.state.freeRepliesLeft, kFreeStatus.freeRepliesLeft);
    expect(bloc.state.status, kFreeStatus);
  });

  test('older page loads before the oldest message (pagination)', () async {
    repo.latest = BuddyMessagePage(
        messages: [fakeMessage('m5', BuddyMessageRole.user, 'x', t0)], hasMore: true);
    repo.older = BuddyMessagePage(messages: [
      fakeMessage('m3', BuddyMessageRole.user, 'a', t0.subtract(const Duration(hours: 2))),
      fakeMessage('m4', BuddyMessageRole.buddy, 'b', t0.subtract(const Duration(hours: 1))),
    ], hasMore: false);
    await start();
    bloc.add(const BuddyChatOlderRequested());
    await _settle();
    expect(repo.olderBefore, t0);
    expect(bloc.state.messages.map((m) => m.id), ['m3', 'm4', 'm5']);
    expect(bloc.state.hasMore, isFalse);
    // No more pages: nothing is requested again.
    repo.olderBefore = null;
    bloc.add(const BuddyChatOlderRequested());
    await _settle();
    expect(repo.olderBefore, isNull);
  });

  test('send: optimistic message, typing, reply, free replies left, reply signal', () async {
    await start();
    repo.sendGate = Completer<void>();
    bloc.add(const BuddyChatSendPressed('  Ciao!  '));
    await _settle();
    expect(bloc.state.waitingReply, isTrue);
    expect(bloc.state.local.single.text, 'Ciao!');
    expect(bloc.state.local.single.delivery, BuddyDelivery.sending);

    repo.sendGate!.complete();
    await _settle();
    expect(repo.sent.single, {'text': 'Ciao!', 'requestId': 'req-1-abcdef'});
    expect(bloc.state.waitingReply, isFalse);
    expect(bloc.state.freeRepliesLeft, 5);
    expect(bloc.state.replySeq, 1);
    expect(bloc.state.messages.map((m) => m.text), ['Ciao!', 'Reply to Ciao!']);

    // Firestore delivers both stored messages: local copies disappear, no duplicates.
    repo.newMessages.add([
      fakeMessage('s1', BuddyMessageRole.user, 'Ciao!', t0),
      fakeMessage('s2', BuddyMessageRole.buddy, 'Reply to Ciao!', t0.add(const Duration(seconds: 1))),
    ]);
    await _settle();
    expect(bloc.state.local, isEmpty);
    expect(bloc.state.messages.map((m) => m.id), ['s1', 's2']);
  });

  test('listener faster than the callable: still no duplicates', () async {
    await start();
    repo.sendGate = Completer<void>();
    bloc.add(const BuddyChatSendPressed('Hey'));
    await _settle();
    repo.newMessages.add([
      fakeMessage('s1', BuddyMessageRole.user, 'Hey', t0),
      fakeMessage('s2', BuddyMessageRole.buddy, 'Reply to Hey', t0),
    ]);
    await _settle();
    repo.sendGate!.complete();
    await _settle();
    expect(bloc.state.local, isEmpty);
    expect(bloc.state.messages.map((m) => m.id), ['s1', 's2']);
  });

  test('empty, too long, or while waiting: nothing is sent', () async {
    await start();
    bloc.add(const BuddyChatSendPressed('   '));
    bloc.add(BuddyChatSendPressed('x' * 501));
    await _settle();
    expect(repo.sent, isEmpty);
  });

  test('failure keeps the message as failed; retry reuses the same requestId', () async {
    await start();
    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'unavailable', message: 'x', details: const {'code': 'AI_UNAVAILABLE'}));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await _settle();
    final failed = bloc.state.local.single;
    expect(failed.delivery, BuddyDelivery.failed);
    expect(bloc.state.error?.kind, BuddyErrorKind.unavailable);
    expect(bloc.state.errorSeq, 1);
    expect(bloc.state.errorLocalId, failed.id);

    bloc.add(BuddyChatRetryPressed(failed.id));
    await _settle();
    expect(repo.sent.map((s) => s['requestId']).toSet(), {'req-1-abcdef'},
        reason: 'same idempotency id: never charged twice');
    expect(bloc.state.local.first.delivery, BuddyDelivery.sent);
    expect(bloc.state.messages.last.text, 'Reply to Hi');
  });

  test('insufficient coins -> 0 free replies; tier-required -> locked', () async {
    await start();
    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'failed-precondition', message: 'insufficient-coins: x', details: const {'reason': 'insufficient-coins'}));
    bloc.add(const BuddyChatSendPressed('a'));
    await _settle();
    expect(bloc.state.error?.kind, BuddyErrorKind.insufficientCoins);
    expect(bloc.state.freeRepliesLeft, 0);

    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'failed-precondition', message: 'tier-required: x', details: const {'reason': 'tier-required'}));
    bloc.add(const BuddyChatSendPressed('b'));
    await _settle();
    expect(bloc.state.error?.kind, BuddyErrorKind.tierRequired);
    expect(bloc.state.locked, isTrue);
    expect(bloc.state.errorSeq, 2);

    // Locked: nothing more is sent.
    bloc.add(const BuddyChatSendPressed('c'));
    await _settle();
    expect(repo.sent.length, 2);
  });

  test('locked from the list: sending is disabled', () async {
    await start(locked: true);
    bloc.add(const BuddyChatSendPressed('hi'));
    await _settle();
    expect(repo.sent, isEmpty);
  });

  test('live Buddy doc and clear chat', () async {
    repo.latest = BuddyMessagePage(messages: [fakeMessage('m1', BuddyMessageRole.user, 'x', t0)], hasMore: true);
    await start();
    repo.buddy.add(fakeBuddy('b1', name: 'Luca'));
    await _settle();
    expect(bloc.state.buddy?.name, 'Luca');
    bloc.add(const BuddyChatCleared());
    await _settle();
    expect(bloc.state.messages, isEmpty);
    expect(bloc.state.hasMore, isFalse);
    repo.buddy.add(null);
    await _settle();
    expect(bloc.state.buddyDeleted, isTrue);
  });

  test('status with 0 free replies', () async {
    repo.status = const BuddyStatus(
        tier: 'GOLD', buddyLimit: 5, buddyCount: 1, freeRepliesPerDay: 50, freeRepliesLeft: 0, coinsPerReply: 1);
    await start();
    expect(bloc.state.freeRepliesLeft, 0);
    expect(bloc.state.status?.buddyLimit, 5);
  });

  test('send: the callable translations go on the local copies until the docs arrive', () async {
    await start();
    repo.buddy.add(fakeBuddy('b1', chatLanguage: 'it'));
    await _settle();
    repo.sendAnswers.add(const BuddySendResult(
      reply: 'Hello\nHow are you?',
      replies: ['Hello', 'How are you?'],
      translations: ['Ciao', null],
      userTranslation: 'Buongiorno',
      kind: 'chat',
      charged: 'free',
      freeRepliesLeft: 4,
    ));
    bloc.add(const BuddyChatSendPressed('Good morning'));
    await _settle();
    final local = bloc.state.local;
    expect(local.map((m) => m.text), ['Good morning', 'Hello', 'How are you?']);
    expect(local[0].translation, const BuddyTranslation(text: 'Buongiorno', lang: 'it'));
    expect(local[1].translation, const BuddyTranslation(text: 'Ciao', lang: 'it'));
    expect(local[2].translation, isNull);

    // A stored copy without its translation keeps the callable's one.
    repo.newMessages.add([
      fakeMessage('s1', BuddyMessageRole.user, 'Good morning', t0),
      fakeMessage('s2', BuddyMessageRole.buddy, 'Hello', t0.add(const Duration(seconds: 1)),
          translation: 'Ciao', lang: 'it'),
    ]);
    await _settle();
    final byId = {for (final m in bloc.state.messages) m.id: m};
    expect(byId['s1']!.translation?.text, 'Buongiorno');
    expect(byId['s2']!.translation?.text, 'Ciao');
  });

  test('local cache: painted before the server page (with translations), then replaced and saved',
      () async {
    repo.cache['b1'] = [
      fakeMessage('c1', BuddyMessageRole.buddy, 'Cached hello', t0, translation: 'Ciao in cache'),
      fakeMessage('gone', BuddyMessageRole.user, 'Deleted on the server', t0),
    ];
    repo.latestGate = Completer<void>();
    repo.latest = BuddyMessagePage(messages: [
      // The stored copy without its translation keeps the cached one.
      fakeMessage('c1', BuddyMessageRole.buddy, 'Cached hello', t0),
      fakeMessage('s2', BuddyMessageRole.buddy, 'New', t0.add(const Duration(minutes: 1)),
          translation: 'Nuovo'),
    ], hasMore: true);
    bloc.add(const BuddyChatStarted(uid: 'u1', buddyId: 'b1'));
    await _settle();
    expect(bloc.state.loading, isFalse);
    expect(bloc.state.server.map((m) => m.id), ['c1', 'gone']);
    expect(bloc.state.server.first.translation?.text, 'Ciao in cache');
    expect(bloc.state.hasMore, isFalse, reason: 'older pages wait for the server page');

    repo.latestGate!.complete();
    await _settle();
    expect(bloc.state.server.map((m) => m.id), ['c1', 's2']);
    expect(bloc.state.server.first.translation?.text, 'Ciao in cache');
    expect(bloc.state.hasMore, isTrue);
    expect(repo.cache['b1']!.map((m) => m.id), ['c1', 's2']);
    expect(repo.cache['b1']!.last.translation?.text, 'Nuovo');

    // New stored messages update the cache too.
    repo.newMessages.add([
      fakeMessage('s3', BuddyMessageRole.buddy, 'Later', t0.add(const Duration(minutes: 2)),
          translation: 'Dopo'),
    ]);
    await _settle();
    expect(repo.cache['b1']!.map((m) => m.id), ['c1', 's2', 's3']);
  });
}
