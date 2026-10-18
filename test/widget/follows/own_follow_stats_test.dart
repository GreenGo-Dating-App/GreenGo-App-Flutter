import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/screens/followed_stores_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/own_follow_stats.dart';

import 'follow_test_support.dart';

/// Private follows (owner rule 2026-10-17): follower / following / stores
/// counts are shown ONLY to the account itself.
void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  group('OwnFollowStatsBar (own profile, 3 columns)', () {
    testWidgets('owner: Followers | Following | Stores with compact numbers, fits 320 dp',
        (tester) async {
      await w.counts('me', followers: 128, following: 1200, stores: 12);
      await tester.pumpWidget(wrapForTest(
          const OwnFollowStatsBar(userId: 'me', currentUserId: 'me'),
          width: 320));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('own_follow_stats_bar')), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('1.2k'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Stores'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Three equal columns.
      final a = tester.getSize(find.byKey(const Key('own_stat_followers')));
      final c = tester.getSize(find.byKey(const Key('own_stat_stores')));
      expect(a.width, closeTo(c.width, 0.5));
    });

    testWidgets('another viewer: renders nothing', (tester) async {
      await w.counts('t', followers: 5);
      await tester.pumpWidget(wrapForTest(
          const OwnFollowStatsBar(userId: 't', currentUserId: 'me')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('own_follow_stats_bar')), findsNothing);
      expect(find.text('5'), findsNothing);
    });

    for (final (key, tab) in [('own_stat_followers', 0), ('own_stat_following', 1)]) {
      testWidgets('tapping $key opens the own list on tab $tab', (tester) async {
        await w.counts('me', followers: 1, following: 1);
        await tester.pumpWidget(wrapForTest(
            const OwnFollowStatsBar(userId: 'me', currentUserId: 'me')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key(key)));
        await tester.pumpAndSettle();
        final screen = tester.widget<FollowListScreen>(find.byType(FollowListScreen));
        expect(screen.userId, 'me');
        expect(screen.currentUserId, 'me');
        expect(screen.initialTab, tab);
      });
    }

    testWidgets('Stores opens the followed-stores list', (tester) async {
      await w.counts('me', stores: 0);
      await tester.pumpWidget(wrapForTest(
          const OwnFollowStatsBar(userId: 'me', currentUserId: 'me')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('own_stat_stores')));
      await tester.pumpAndSettle();
      expect(find.byType(FollowedStoresScreen), findsOneWidget);
      expect(find.byKey(const Key('followed_stores_empty')), findsOneWidget);
      expect(find.text("You don't follow any stores yet"), findsOneWidget);
    });
  });

  group('OwnFollowStatsLine ("View my profile", under the city)', () {
    testWidgets('owner: "128 followers · 64 following" with icons; taps open the lists',
        (tester) async {
      await w.counts('me', followers: 128, following: 64);
      await tester.pumpWidget(wrapForTest(
          const OwnFollowStatsLine(userId: 'me', currentUserId: 'me'),
          width: 320));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('own_follow_stats_line')), findsOneWidget);
      expect(find.text('128 followers'), findsOneWidget);
      expect(find.text('64 following'), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      final t = tester.widget<Text>(find.text('128 followers'));
      expect(t.style?.fontSize, 13);

      await tester.tap(find.byKey(const Key('own_line_following')));
      await tester.pumpAndSettle();
      expect(tester.widget<FollowListScreen>(find.byType(FollowListScreen)).initialTab, 1);
    });

    testWidgets('another viewer: absent', (tester) async {
      await w.counts('t', followers: 128, following: 64);
      await tester.pumpWidget(wrapForTest(
          const OwnFollowStatsLine(userId: 't', currentUserId: 'me')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('own_follow_stats_line')), findsNothing);
      expect(find.textContaining('followers'), findsNothing);
    });
  });

  testWidgets('OwnFollowersCount (Explore stat) streams the own private count',
      (tester) async {
    await w.counts('me', followers: 7);
    await tester.pumpWidget(wrapForTest(OwnFollowersCount(
      uid: 'me',
      builder: (_, n) => Text(n == null ? 'loading' : 'n=$n'),
    )));
    await tester.pumpAndSettle();
    expect(find.text('n=7'), findsOneWidget);
    await w.counts('me', followers: 8);
    await tester.pumpAndSettle();
    expect(find.text('n=8'), findsOneWidget);
  });

  test('profile detail shows no follow stats to other viewers (source guard)', () {
    final src = File('lib/features/discovery/presentation/screens/profile_detail_screen.dart')
        .readAsStringSync();
    expect(src.contains('FollowCard'), isFalse);
    expect(src.contains('FollowListScreen'), isFalse);
    // The only follow stats there are the own line, behind the self-view check.
    final i = src.indexOf('OwnFollowStatsLine(');
    expect(i, greaterThan(0));
    expect(src.lastIndexOf('if (_isSelfView) ...[', i), greaterThan(i - 400));
    // The Follow button stays for everyone else.
    expect(src.contains('UserFollowButton('), isTrue);
  });
}
