import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';

const alice = 'alice'; // follower
const bob = 'bob'; // followee

/// Latest value of a counts stream, kept up to date.
class _Latest {
  _Latest(Stream<FollowCounts> s) {
    sub = s.listen((c) => value = c);
  }
  late final StreamSubscription<FollowCounts> sub;
  FollowCounts? value;
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('FollowCountOverlay', () {
    test('adds pending deltas and clamps at zero', () {
      final o = FollowCountOverlay();
      o.record(bob, FollowCounter.followers, -1, serverBefore: 0);
      expect(o.apply(bob, FollowCounter.followers, 0), 0);
      o.record(alice, FollowCounter.following, 1, serverBefore: 3);
      expect(o.apply(alice, FollowCounter.following, 3), 4);
      o.clear();
    });

    test('reconciles once the server moves off the base', () {
      final o = FollowCountOverlay();
      o.record(bob, FollowCounter.followers, 1, serverBefore: 5);
      o.observeServer(bob, FollowCounter.followers, 5); // not counted yet
      expect(o.apply(bob, FollowCounter.followers, 5), 6);
      o.observeServer(bob, FollowCounter.followers, 6); // trigger ran
      expect(o.pendingDelta(bob, FollowCounter.followers), 0);
      expect(o.apply(bob, FollowCounter.followers, 6), 6); // not 7
    });

    test('follow + unfollow before the trigger ran cancel out', () {
      final o = FollowCountOverlay();
      o.record(bob, FollowCounter.followers, 1, serverBefore: 2);
      o.record(bob, FollowCounter.followers, -1, serverBefore: 2);
      expect(o.pendingDelta(bob, FollowCounter.followers), 0);
      expect(o.apply(bob, FollowCounter.followers, 2), 2);
    });

    test('a landed change is dropped before the next one is recorded', () {
      final o = FollowCountOverlay();
      o.record(bob, FollowCounter.followers, 1, serverBefore: 2);
      // Server already counted the follow (3) when the unfollow starts.
      o.record(bob, FollowCounter.followers, -1, serverBefore: 3);
      expect(o.apply(bob, FollowCounter.followers, 3), 2);
    });

    test('expires after the ttl', () async {
      final o = FollowCountOverlay(ttl: const Duration(milliseconds: 30));
      final changed = <String>[];
      final sub = o.changes.listen(changed.add);
      o.record(bob, FollowCounter.followers, 1, serverBefore: 0);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(o.pendingDelta(bob, FollowCounter.followers), 0);
      expect(changed.where((u) => u == bob).length, 2); // record + expiry
      await sub.cancel();
    });
  });

  group('FollowService counts (both sides, immediate)', () {
    late FakeFirebaseFirestore db;
    late FollowService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = FollowService(firestore: db, overlay: FollowCountOverlay());
      await db.collection('profiles').doc(alice).set({'followingCount': 3});
      await db.collection('profiles').doc(bob).set({'followersCount': 10});
    });

    test('unfollow lowers the follower\'s FOLLOWING and the followee\'s FOLLOWERS '
        'immediately, and stays right when the trigger lands', () async {
      // Already following, already counted by the server.
      await service.followUser(followeeId: bob, followerId: alice);
      await db.collection('profiles').doc(alice).update({'followingCount': 4});
      await db.collection('profiles').doc(bob).update({'followersCount': 11});

      final me = _Latest(service.counts(alice));
      final them = _Latest(service.counts(bob));
      await _settle();
      expect(me.value!.following, 4);
      expect(them.value!.followers, 11);

      await service.unfollowUser(followeeId: bob, followerId: alice);
      await _settle();
      expect(me.value!.following, 3, reason: 'my following drops at once');
      expect(them.value!.followers, 10, reason: 'their followers drop at once');

      // An unrelated profile update (presence) must not bring the old value back.
      await db.collection('profiles').doc(bob).update({'isOnline': true});
      await _settle();
      expect(them.value!.followers, 10);

      // onUserFollowDeleted lands: no double decrement.
      await db.collection('profiles').doc(alice).update({'followingCount': 3});
      await db.collection('profiles').doc(bob).update({'followersCount': 10});
      await _settle();
      expect(me.value!.following, 3);
      expect(them.value!.followers, 10);

      await me.sub.cancel();
      await them.sub.cancel();
    });

    test('follow raises both sides at once; rapid follow/unfollow/follow nets +1',
        () async {
      final me = _Latest(service.counts(alice));
      final them = _Latest(service.counts(bob));
      await _settle();

      await service.followUser(followeeId: bob, followerId: alice);
      await service.unfollowUser(followeeId: bob, followerId: alice);
      await service.followUser(followeeId: bob, followerId: alice);
      await _settle();
      expect(me.value!.following, 4);
      expect(them.value!.followers, 11);

      // Idempotent: a second follow writes nothing and changes nothing.
      await service.followUser(followeeId: bob, followerId: alice);
      await _settle();
      expect(me.value!.following, 4);
      expect(them.value!.followers, 11);

      final edge = await db
          .collection('business_followers')
          .doc(bob)
          .collection('followers')
          .doc(alice)
          .get();
      expect(edge.exists, isTrue);

      await me.sub.cancel();
      await them.sub.cancel();
    });

    test('unfollowing when not following changes nothing and never goes negative',
        () async {
      await db.collection('profiles').doc(alice).set({'followingCount': 0});
      final me = _Latest(service.counts(alice));
      await _settle();
      await service.unfollowUser(followeeId: bob, followerId: alice);
      await _settle();
      expect(me.value!.following, 0);
      await me.sub.cancel();
    });

    test('unfollow deletes the canonical edge and the mirror', () async {
      await service.followUser(followeeId: bob, followerId: alice);
      await service.unfollowUser(followeeId: bob, followerId: alice);
      final edge = await db
          .collection('business_followers')
          .doc(bob)
          .collection('followers')
          .doc(alice)
          .get();
      final mirror = await db
          .collection('user_business_following')
          .doc(alice)
          .collection('businesses')
          .doc(bob)
          .get();
      expect(edge.exists, isFalse);
      expect(mirror.exists, isFalse);
    });
  });
}
