import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_catalog.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/bloc/buddy_chat_bloc.dart';

import '../../support/buddies_fakes.dart';

/// Multi-bubble turns (owner 2026-10-24): the bubbles of one turn appear one
/// by one, 1 s apart, in order, with the typing indicator in between, even
/// when they all arrive at once. History is never delayed.
void main() {
  final t0 = DateTime(2026, 10, 24, 10);
  const gap = Duration(seconds: 1);

  List<String> visible(BuddyChatBloc b) => b.state.visibleMessages.map((m) => m.text).toList();

  /// Runs [body] in fake time (testWidgets' FakeAsync zone: the bloc's
  /// reveal timer only fires when the test pumps time) with a started bloc.
  void run(String name,
      Future<void> Function(WidgetTester t, BuddyChatBloc bloc, FakeBuddiesRepository repo) body,
      {void Function(FakeBuddiesRepository repo)? setup}) {
    testWidgets(name, (t) async {
      final repo = FakeBuddiesRepository();
      setup?.call(repo);
      final bloc = BuddyChatBloc(repository: repo);
      bloc.add(const BuddyChatStarted(uid: 'u1', buddyId: 'b1'));
      await t.pump();
      await body(t, bloc, repo);
      // Not awaited: closing completes through the fake clock.
      unawaited(bloc.close());
      unawaited(repo.dispose());
      await t.pump(const Duration(seconds: 2));
    });
  }

  run('one bubble: shown at once, no extra typing', (t, bloc, repo) async {
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'Ciao!', replies: ['Ciao!'], kind: 'chat', charged: 'free', freeRepliesLeft: 4));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await t.pump();
    expect(visible(bloc), ['Hi', 'Ciao!']);
    expect(bloc.state.hidden, isEmpty);
    expect(bloc.state.buddyTyping, isFalse);
  });

  run('two bubbles from the callable: second one 1 s later, typing in between',
      (t, bloc, repo) async {
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'First.\nSecond?',
        replies: ['First.', 'Second?'],
        kind: 'chat',
        charged: 'free',
        freeRepliesLeft: 4));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await t.pump();
    expect(visible(bloc), ['Hi', 'First.']);
    expect(bloc.state.messages.map((m) => m.text), ['Hi', 'First.', 'Second?'],
        reason: 'received, just not shown yet');
    expect(bloc.state.buddyTyping, isTrue, reason: 'typing indicator between bubbles');
    expect(bloc.state.replySeq, 1, reason: 'one turn = one reply signal');

    await t.pump(gap - const Duration(milliseconds: 1));
    expect(visible(bloc), ['Hi', 'First.']);
    await t.pump(const Duration(milliseconds: 1));
    expect(visible(bloc), ['Hi', 'First.', 'Second?']);
    expect(bloc.state.buddyTyping, isFalse);
  });

  run('three bubbles (generic N): one per second, in order', (t, bloc, repo) async {
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'a\nb\nc', replies: ['a', 'b', 'c'], kind: 'chat', charged: 'free', freeRepliesLeft: 4));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await t.pump();
    expect(visible(bloc), ['Hi', 'a']);
    await t.pump(gap);
    expect(visible(bloc), ['Hi', 'a', 'b']);
    await t.pump(gap);
    expect(visible(bloc), ['Hi', 'a', 'b', 'c']);
  });

  run('two bubbles from the listener at the same time (createdAt not spaced, listed '
      'out of order): one by one, in createdAt order', (t, bloc, repo) async {
    repo.newMessages.add([
      fakeMessage('s2', BuddyMessageRole.buddy, 'Second', t0.add(const Duration(milliseconds: 5))),
      fakeMessage('s1', BuddyMessageRole.buddy, 'First', t0),
    ]);
    await t.pump();
    expect(visible(bloc), ['First']);
    expect(bloc.state.buddyTyping, isTrue);
    await t.pump(gap);
    expect(visible(bloc), ['First', 'Second']);
    expect(bloc.state.buddyTyping, isFalse);
  });

  run('stored copies arriving while the 2nd bubble is hidden keep it hidden; no duplicates',
      (t, bloc, repo) async {
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'One.\nTwo.', replies: ['One.', 'Two.'], kind: 'chat', charged: 'free', freeRepliesLeft: 4));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await t.pump();
    repo.newMessages.add([
      fakeMessage('u', BuddyMessageRole.user, 'Hi', t0),
      fakeMessage('s1', BuddyMessageRole.buddy, 'One.', t0.add(gap)),
      fakeMessage('s2', BuddyMessageRole.buddy, 'Two.', t0.add(gap * 2)),
    ]);
    await t.pump();
    expect(bloc.state.local, isEmpty);
    expect(bloc.state.messages.map((m) => m.id), ['u', 's1', 's2']);
    expect(visible(bloc), ['Hi', 'One.'], reason: 's2 replaced the hidden local copy');
    await t.pump(gap);
    expect(visible(bloc), ['Hi', 'One.', 'Two.']);
  });

  run('listener faster than the callable: still revealed one by one, no duplicates',
      (t, bloc, repo) async {
    repo.sendGate = Completer<void>();
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'One.\nTwo.', replies: ['One.', 'Two.'], kind: 'chat', charged: 'free', freeRepliesLeft: 4));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await t.pump();
    repo.newMessages.add([
      fakeMessage('u', BuddyMessageRole.user, 'Hi', t0),
      fakeMessage('s1', BuddyMessageRole.buddy, 'One.', t0.add(gap)),
      fakeMessage('s2', BuddyMessageRole.buddy, 'Two.', t0.add(gap * 2)),
    ]);
    await t.pump();
    repo.sendGate!.complete();
    await t.pump();
    expect(bloc.state.local, isEmpty);
    expect(visible(bloc), ['Hi', 'One.']);
    await t.pump(gap);
    expect(visible(bloc), ['Hi', 'One.', 'Two.']);
  });

  run('history is never delayed', (t, bloc, repo) async {
    expect(visible(bloc), ['Old 1', 'Old 2']);
    expect(bloc.state.buddyTyping, isFalse);
  }, setup: (repo) {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('h1', BuddyMessageRole.buddy, 'Old 1', t0),
      fakeMessage('h2', BuddyMessageRole.buddy, 'Old 2', t0.add(gap)),
    ], hasMore: false);
  });

  run('keywords of the turn go to the bubble that names them', (t, bloc, repo) async {
    repo.sendAnswers.add(const BuddySendResult(
      reply: 'Rome is great.\nVisit Italy!',
      replies: ['Rome is great.', 'Visit Italy!'],
      keywords: [BuddyKeyword(type: 'city', name: 'Rome'), BuddyKeyword(type: 'country', name: 'Italy')],
      kind: 'chat',
      charged: 'free',
      freeRepliesLeft: 4,
    ));
    bloc.add(const BuddyChatSendPressed('Hi'));
    await t.pump();
    final buddy = bloc.state.messages.where((m) => m.isBuddy).toList();
    expect(buddy[0].keywords.map((k) => k.name), ['Rome']);
    expect(buddy[1].keywords.map((k) => k.name), ['Italy']);
    expect(buddy[0].charged, 'free');
    expect(buddy[1].charged, 'none', reason: 'a turn is charged once');
  });

  run('201 characters are never sent; 200 are', (t, bloc, repo) async {
    bloc.add(BuddyChatSendPressed('x' * (BuddyCatalog.maxMessageChars + 1)));
    await t.pump();
    expect(repo.sent, isEmpty);
    bloc.add(BuddyChatSendPressed('x' * BuddyCatalog.maxMessageChars));
    await t.pump();
    expect(repo.sent.single['text']!.length, 200);
  });

  test('BuddySendResult parses replies + keywords and never shows raw JSON', () {
    final r = BuddySendResult.fromMap(const {
      'reply': 'a\nb',
      'replies': ['a', '{"messages": ["x"]}', 'b', 3, ''],
      'keywords': [
        {'type': 'city', 'name': 'Lisbon'},
        {'type': 'planet', 'name': 'Mars'},
        'bad',
      ],
      'kind': 'chat',
      'charged': 'credit',
      'freeRepliesLeft': 0,
      'replyCredits': 2,
    });
    expect(r.bubbles, ['a', 'b']);
    expect(r.keywords, const [BuddyKeyword(type: 'city', name: 'Lisbon')]);
    expect(BuddySendResult.fromMap(const {'reply': 'only', 'kind': 'safety'}).bubbles, ['only']);
    expect(BuddyCatalog.maxMessageChars, 200);
  });
}
