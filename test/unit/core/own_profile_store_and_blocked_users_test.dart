import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:greengo_chat/core/services/blocked_users_service.dart';
import 'package:greengo_chat/core/services/own_profile_store.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';

import '../../support/profile_fixtures.dart';

void main() {
  // BlockedUsersService persists its last set through LastResultCache (Hive);
  // the app initialises Hive at startup, the test does it here.
  setUpAll(() => Hive.init(
      Directory.systemTemp.createTempSync('blocked_users_test').path));
  group('OwnProfileStore', () {
    final store = OwnProfileStore.instance;
    Map<String, dynamic> json(String uid) =>
        ProfileModel.fromEntity(buildProfile(userId: uid)).toJson();

    setUp(store.reset);

    test('peek is per user and empty until fed', () {
      expect(store.peek('u1'), isNull);
      store.seed('u1', json('u1'));
      expect(store.peek('u1')?.userId, 'u1');
      expect(store.peek('u2'), isNull);
    });

    test('only a live server snapshot counts as live', () {
      store.seed('u1', json('u1'));
      expect(store.peekLive('u1'), isNull);
      store.publish('u1', json('u1'), fromServer: false);
      expect(store.peekLive('u1'), isNull);
      store.publish('u1', json('u1'));
      expect(store.peekLive('u1'), isNotNull);
      store.detach('u1');
      expect(store.peekLive('u1'), isNull);
      expect(store.peek('u1'), isNotNull); // kept as last known
    });

    test('a one-shot read never overwrites the live listener value', () {
      store.publish('u1', {...json('u1'), 'displayName': 'Live'});
      store.seed('u1', {...json('u1'), 'displayName': 'Old'});
      expect(store.peek('u1')?.displayName, 'Live');
    });

    test('current answers from memory without a read', () async {
      store.publish('u1', json('u1'));
      expect((await store.current('u1'))?.userId, 'u1');
    });

    test('reset forgets the user', () {
      store.publish('u1', json('u1'));
      store.reset();
      expect(store.peek('u1'), isNull);
      expect(store.profile.value, isNull);
    });
  });

  group('BlockedUsersService', () {
    late FakeFirebaseFirestore fs;
    late BlockedUsersService svc;

    setUp(() async {
      fs = FakeFirebaseFirestore();
      svc = BlockedUsersService(firestore: fs);
      await fs
          .collection('blockedUsers')
          .add({'blockerId': 'me', 'blockedUserId': 'a'});
      await fs
          .collection('blockedUsers')
          .add({'blockerId': 'b', 'blockedUserId': 'me'});
      await fs
          .collection('blockedUsers')
          .add({'blockerId': 'x', 'blockedUserId': 'y'});
    });

    test('returns both directions', () async {
      expect(await svc.getBlockedUserIds('me'), {'a', 'b'});
      expect(svc.lastKnownBlockedIds('me'), {'a', 'b'});
    });

    test('last known is empty before the first lookup', () {
      expect(svc.lastKnownBlockedIds('me'), isEmpty);
    });

    test('invalidate makes the next lookup wait for the server', () async {
      expect(await svc.getBlockedUserIds('me'), {'a', 'b'});
      await fs
          .collection('blockedUsers')
          .add({'blockerId': 'me', 'blockedUserId': 'c'});
      // Still the cached set within the TTL.
      expect(await svc.getBlockedUserIds('me'), {'a', 'b'});
      svc.invalidate('me');
      expect(await svc.getBlockedUserIds('me'), {'a', 'b', 'c'});
    });

    test('concurrent lookups share one result', () async {
      final r = await Future.wait(
          [svc.getBlockedUserIds('me'), svc.getBlockedUserIds('me')]);
      expect(r[0], {'a', 'b'});
      expect(r[1], {'a', 'b'});
    });
  });
}
