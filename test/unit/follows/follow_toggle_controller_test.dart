import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';
import 'package:greengo_chat/features/follows/presentation/follow_toggle_controller.dart';

void main() {
  group('FollowToggleController', () {
    test('follow is optimistic and keeps state on success', () async {
      var follows = 0;
      final c = FollowToggleController(
        follow: () async => follows++,
        unfollow: () async {},
        initialFollowers: 10,
      );
      final pending = c.toggle();
      expect(c.following, isTrue);
      expect(c.followers, 11);
      expect(c.busy, isTrue);
      expect(await pending, isTrue);
      expect(c.busy, isFalse);
      expect(c.following, isTrue);
      expect(c.followers, 11);
      expect(follows, 1);
    });

    test('unfollow decrements and never goes below zero', () async {
      final c = FollowToggleController(
        follow: () async {},
        unfollow: () async {},
        initiallyFollowing: true,
      );
      expect(await c.toggle(), isTrue);
      expect(c.following, isFalse);
      expect(c.followers, 0);
    });

    test('failure rolls back state and exposes the error', () async {
      final c = FollowToggleController(
        follow: () async => throw const FollowBlockedException(),
        unfollow: () async {},
        initialFollowers: 3,
      );
      expect(await c.toggle(), isFalse);
      expect(c.following, isFalse);
      expect(c.followers, 3);
      expect(c.busy, isFalse);
      expect(c.lastError, isA<FollowBlockedException>());
    });

    test('taps while a write is pending are ignored', () async {
      final gate = Completer<void>();
      var calls = 0;
      final c = FollowToggleController(
        follow: () {
          calls++;
          return gate.future;
        },
        unfollow: () async => calls++,
      );
      final first = c.toggle();
      expect(await c.toggle(), isFalse);
      gate.complete();
      expect(await first, isTrue);
      expect(calls, 1);
      expect(c.following, isTrue);
    });

    test('server sync applies when idle, is ignored while pending', () async {
      final gate = Completer<void>();
      final c = FollowToggleController(
        follow: () => gate.future,
        unfollow: () async {},
      );
      c.syncFromServer(following: false, followers: 41);
      expect(c.followers, 41);

      final pending = c.toggle(); // optimistic: following, 42
      c.syncFromServer(following: false, followers: 41); // stale echo
      expect(c.following, isTrue);
      expect(c.followers, 42);
      gate.complete();
      await pending;

      c.syncFromServer(following: true, followers: 42);
      expect(c.following, isTrue);
      expect(c.followers, 42);
      c.syncFromServer(followers: -3);
      expect(c.followers, 0);
    });

    test('notifies listeners on changes', () async {
      final c = FollowToggleController(
        follow: () async {},
        unfollow: () async {},
      );
      var n = 0;
      c.addListener(() => n++);
      await c.toggle();
      expect(n, greaterThanOrEqualTo(2)); // optimistic flip + settle
      c.dispose();
    });
  });

  group('FollowCounts', () {
    test('reads only the server-maintained counters', () {
      final c = FollowCounts.fromProfileData({
        'followerCount': 999, // legacy, client-writable → ignored
        'followersCount': 12,
        'followingCount': 4,
      });
      expect(c.followers, 12);
      expect(c.following, 4);
    });

    test('missing / negative values read as zero', () {
      expect(FollowCounts.fromProfileData(null).followers, 0);
      expect(FollowCounts.fromProfileData({'followersCount': -2}).followers, 0);
    });
  });
}
