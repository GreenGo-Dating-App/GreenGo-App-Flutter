import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/data/datasources/buddies_remote_datasource.dart';
import 'package:greengo_chat/features/buddies/data/repositories/buddies_repository_impl.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_exception.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_avatar_option.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';

/// Real Firestore reads (fake backend) + recorded callables.
class _Remote extends BuddiesRemoteDataSource {
  _Remote(FirebaseFirestore db) : super(firestore: db);

  final List<(String, Map<String, Object?>)> calls = [];
  Map<String, dynamic> answer = {};
  Object? error;
  int avatarReads = 0;
  Object? avatarError;

  @override
  Future<List<BuddyAvatarOption>> fetchAvatarOptions() {
    avatarReads++;
    if (avatarError != null) throw avatarError!;
    return super.fetchAvatarOptions();
  }

  @override
  Future<Map<String, dynamic>> call(String name, Map<String, Object?> data,
      {Duration timeout = const Duration(seconds: 30)}) async {
    calls.add((name, data));
    if (error != null) throw error!;
    return answer;
  }
}

void expectCall((String, Map<String, Object?>) call, String name, Map<String, Object?> data) {
  expect(call.$1, name);
  expect(call.$2, equals(data));
}

void main() {
  late FakeFirebaseFirestore db;
  late _Remote remote;
  late BuddiesRepositoryImpl repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    remote = _Remote(db);
    repo = BuddiesRepositoryImpl(remote: remote);
  });

  CollectionReference<Map<String, dynamic>> msgs() =>
      db.collection('ai_buddies').doc('u1').collection('buddies').doc('b1').collection('messages');

  Future<void> seedMessages(int n) async {
    for (var i = 0; i < n; i++) {
      await msgs().doc('m$i').set({
        'role': i.isEven ? 'user' : 'buddy',
        'text': 'msg $i',
        'kind': i == 3 ? 'checkin' : 'chat',
        'charged': 'none',
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1).add(Duration(minutes: i))),
      });
    }
  }

  test('watchBuddies parses settings, memory and state', () async {
    await db.collection('ai_buddies').doc('u1').collection('buddies').doc('b1').set({
      'name': 'Luca',
      'avatar': 'buddy_05',
      'topic': 'practice_italian',
      'role': 'teacher',
      'tone': 'warm',
      'language': 'it',
      'level': 'beginner',
      'cefr': 'A2',
      'checkInsEnabled': false,
      'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      'lastMessage': 'Ciao!',
      'lastMessageAt': null,
      'messageCount': 4,
      'unansweredCheckIns': 1,
      'memory': [
        {'id': 'f1', 'text': 'Likes pasta', 'at': 1760000000000},
        {'bad': true},
      ],
    });
    final list = await repo.watchBuddies('u1').first;
    final b = list.single;
    expect(b.settings.cefr, 'A2');
    expect(b.settings.checkInsEnabled, isFalse);
    expect(b.lastMessage, 'Ciao!');
    expect(b.lastMessageAt, isNull);
    expect(b.unansweredCheckIns, 1);
    expect(b.memory.single.text, 'Likes pasta');
  });

  test('messages: newest page first, then older pages, oldest first in each', () async {
    await seedMessages(5);
    final latest = await repo.latestMessages('u1', 'b1', limit: 2);
    expect(latest.messages.map((m) => m.id), ['m3', 'm4']);
    expect(latest.hasMore, isTrue);
    expect(latest.messages.first.kind, BuddyMessageKind.checkin);

    final older =
        await repo.olderMessages('u1', 'b1', before: latest.messages.first.createdAt, limit: 2);
    expect(older.messages.map((m) => m.id), ['m1', 'm2']);
    final oldest =
        await repo.olderMessages('u1', 'b1', before: older.messages.first.createdAt, limit: 2);
    expect(oldest.messages.map((m) => m.id), ['m0']);
    expect(oldest.hasMore, isFalse);
  });

  test('watchNewMessages only returns messages after the anchor', () async {
    await seedMessages(3);
    final list = await repo
        .watchNewMessages('u1', 'b1', after: DateTime(2026, 10, 1).add(const Duration(minutes: 1)))
        .first;
    expect(list.map((m) => m.id), ['m2']);
  });

  test('callables: payloads match functions/src/buddies', () async {
    remote.answer = {'buddyId': 'new1'};
    final id = await repo.createBuddy(const BuddySettings(
      name: 'Sunny',
      avatar: 'av_fox',
      topic: 'movies',
      tone: 'funny',
      language: 'en',
    ));
    expect(id, 'new1');
    // Only category, language, tone, name, picture (+ check-ins): role, level
    // and CEFR are left to the server defaults, never sent as null.
    expectCall(remote.calls.last, 'createBuddy', {
      'settings': {
        'name': 'Sunny',
        'avatar': 'av_fox',
        'topic': 'movies',
        'tone': 'funny',
        'language': 'en',
        'checkInsEnabled': true,
      }
    });

    await repo.updateBuddy('b1', {'tone': 'calm'});
    expectCall(remote.calls.last, 'updateBuddy', {
      'buddyId': 'b1',
      'settings': {'tone': 'calm'}
    });

    await repo.forgetMemory('b1');
    expect(remote.calls.last.$2.containsKey('factId'), isFalse, reason: 'no factId = forget all');
    await repo.forgetMemory('b1', factId: 'f1');
    expect(remote.calls.last.$2['factId'], 'f1');

    await repo.clearChat('b1', forgetMemory: true);
    expectCall(remote.calls.last, 'clearBuddyChat', {'buddyId': 'b1', 'forgetMemory': true});

    await repo.deleteBuddy('b1');
    expectCall(remote.calls.last, 'deleteBuddy', {'buddyId': 'b1'});

    remote.answer = {
      'reply': 'Hi!',
      'kind': 'chat',
      'charged': 'coin',
      'freeRepliesLeft': 0,
      'coinBalance': 9
    };
    final r = await repo.sendMessage(buddyId: 'b1', text: 'hello', requestId: 'abcdefgh');
    expect(r.charged, 'coin');
    expect(r.coinBalance, 9);
    expectCall(remote.calls.last, 'sendBuddyMessage',
        {'buddyId': 'b1', 'text': 'hello', 'requestId': 'abcdefgh'});

    remote.answer = {
      'tier': 'SILVER',
      'buddyLimit': 3,
      'buddyCount': 2,
      'freeRepliesPerDay': 30,
      'freeRepliesLeft': 30,
      'coinsPerReply': 1,
    };
    final s = await repo.getStatus();
    expect(s.buddyLimit, 3);
    expect(s.canCreateMore, isTrue);
  });

  test('requestId satisfies the server validRequestId and is unique', () {
    final re = RegExp(r'^[A-Za-z0-9_-]{8,80}$');
    final a = repo.newRequestId(), b = repo.newRequestId();
    expect(re.hasMatch(a), isTrue);
    expect(a, isNot(b));
  });

  test('callable failures become BuddyException', () async {
    remote.error = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'tier-required: x',
        details: const {'reason': 'tier-required', 'limit': 1});
    await expectLater(
      repo.createBuddy(const BuddySettings(
          name: 'A', avatar: 'buddy_01', topic: 'movies', tone: 'warm', language: 'en')),
      throwsA(isA<BuddyException>().having((e) => e.kind, 'kind', BuddyErrorKind.tierRequired)),
    );
  });

  group('avatar pictures (buddy_avatars)', () {
    Future<void> seedAvatars() async {
      final c = db.collection('buddy_avatars');
      await c
          .doc('av_owl')
          .set({'url': 'https://s.test/owl.png', 'label': 'Owl', 'order': 2, 'active': true});
      await c
          .doc('av_fox')
          .set({'url': 'https://s.test/fox.png', 'label': 'Fox', 'order': 1, 'active': true});
      await c
          .doc('av_old')
          .set({'url': 'https://s.test/old.png', 'label': 'Old', 'order': 0, 'active': false});
      await c.doc('av_http').set({'url': 'http://s.test/x.png', 'order': 3, 'active': true});
      await c.doc('av_nourl').set({'label': 'No url', 'order': 4, 'active': true});
    }

    test('active only, ordered by order, invalid docs skipped', () async {
      await seedAvatars();
      final list = await repo.avatarOptions();
      expect(list.map((o) => o.id), ['av_fox', 'av_owl']);
      expect(
          list.first,
          const BuddyAvatarOption(
              id: 'av_fox', url: 'https://s.test/fox.png', label: 'Fox', order: 1));
    });

    test('one read, then cached; concurrent callers share it; refresh reads again', () async {
      await seedAvatars();
      expect(repo.cachedAvatarOptions, isNull);
      final both = await Future.wait([repo.avatarOptions(), repo.avatarOptions()]);
      expect(remote.avatarReads, 1);
      expect(identical(both[0], both[1]), isTrue);
      await repo.avatarOptions();
      expect(remote.avatarReads, 1);
      expect(repo.cachedAvatarOptions!.length, 2);
      await repo.avatarOptions(refresh: true);
      expect(remote.avatarReads, 2);
    });

    test('a failed read is not cached: the next call reads again', () async {
      await seedAvatars();
      remote.avatarError = StateError('offline');
      await expectLater(repo.avatarOptions(), throwsStateError);
      expect(repo.cachedAvatarOptions, isNull);
      remote.avatarError = null;
      expect((await repo.avatarOptions()).length, 2);
      expect(remote.avatarReads, 2);
    });

    test('settings without role/level parse as null (server defaults)', () async {
      await db.collection('ai_buddies').doc('u1').collection('buddies').doc('b2').set({
        'name': 'Mia',
        'avatar': 'av_fox',
        'topic': 'movies',
        'tone': 'calm',
        'language': 'de',
        'createdAt': Timestamp.fromDate(DateTime(2026, 10, 24)),
      });
      final b = (await repo.watchBuddies('u1').first).single;
      expect(b.settings.avatar, 'av_fox');
      expect(b.settings.role, isNull);
      expect(b.settings.level, isNull);
    });
  });

  test('getBuddyStatus / sendBuddyMessage: 0.2 coins per reply and prepaid replies', () async {
    remote.answer = {
      'tier': 'FREE',
      'buddyLimit': 1,
      'buddyCount': 1,
      'freeRepliesPerDay': 10,
      'freeRepliesLeft': 0,
      'coinsPerReply': 0.2,
      'repliesPerCoin': 5,
      'replyCredits': 4,
    };
    final s = await repo.getStatus();
    expect(s.coinsPerReply, 0.2);
    expect(s.repliesPerCoin, 5);
    expect(s.replyCredits, 4);
    expect(s.coinsNeeded, 1);

    // Older server without repliesPerCoin: derived from the price.
    remote.answer = {'coinsPerReply': 0.25};
    expect((await repo.getStatus()).repliesPerCoin, 4);
    remote.answer = {'coinsPerReply': 1};
    final one = await repo.getStatus();
    expect(one.repliesPerCoin, 1);
    expect(one.replyCredits, 0);

    remote.answer = {
      'reply': 'Hi',
      'kind': 'chat',
      'charged': 'credit',
      'freeRepliesLeft': 0,
      'replyCredits': 3
    };
    final r = await repo.sendMessage(buddyId: 'b1', text: 'x', requestId: 'abcdefgh');
    expect(r.charged, 'credit');
    expect(r.replyCredits, 3);
  });
}
