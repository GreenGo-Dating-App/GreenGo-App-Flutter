import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/follow_card.dart';

import 'follow_test_support.dart';

void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  Finder inBlock(String key, Finder f) =>
      find.descendant(of: find.byKey(Key(key)), matching: f);
  Finder avatars() => find.descendant(
      of: find.byKey(const Key('follow_card_avatars')),
      matching: find.byType(CircleAvatar));

  testWidgets('numbers + at most 3 newest photos on Followers only',
      (tester) async {
    await w.counts('t', followers: 12, following: 64);
    for (var i = 1; i <= 6; i++) {
      await w.follow('u$i', 't');
    }
    await w.follow('t', 'x1');
    w.briefs({
      for (var i = 1; i <= 6; i++) 'u$i': UserBrief(name: 'User$i Last'),
      'x1': const UserBrief(name: 'Bia'),
    });

    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();

    expect(inBlock('follow_card_followers', find.text('12')), findsOneWidget);
    expect(inBlock('follow_card_followers', find.text('Followers')),
        findsOneWidget);
    expect(inBlock('follow_card_following', find.text('64')), findsOneWidget);
    expect(inBlock('follow_card_following', find.text('Following')),
        findsOneWidget);
    expect(avatars(), findsNWidgets(3));
    expect(
        inBlock('follow_card_followers', find.byKey(const Key('follow_card_avatars'))),
        findsOneWidget);
    expect(
        inBlock('follow_card_following', find.byKey(const Key('follow_card_avatars'))),
        findsNothing);
    // No names line, no share button, no card chrome text.
    expect(find.textContaining('others'), findsNothing);
    expect(find.textContaining('User'), findsNothing);
    expect(find.byIcon(Icons.ios_share), findsNothing);
    // Semantics label carries the count.
    expect(find.bySemanticsLabel('12 followers'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow at 320 dp
  });

  testWidgets('singular label and compact counts', (tester) async {
    await w.counts('t', followers: 1, following: 3400);
    await w.follow('u1', 't');
    w.briefs({'u1': const UserBrief(name: 'Ana')});
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();
    expect(find.text('Follower'), findsOneWidget);
    expect(find.text('3.4k'), findsOneWidget);
    expect(avatars(), findsOneWidget);

    await w.counts('t', followers: 1250000);
    await tester.pumpAndSettle();
    expect(find.text('1.2M'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
  });

  testWidgets('inactive people are not shown', (tester) async {
    await w.counts('t', followers: 2);
    await w.follow('gone', 't');
    await w.follow('u1', 't');
    w.briefs({'u1': const UserBrief(name: 'Ana'), 'gone': UserBrief.missing});
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();
    expect(avatars(), findsOneWidget);
  });

  testWidgets('own profile, no followers: just "0", no photos, no share',
      (tester) async {
    await w.counts('me');
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(find.text('0'), findsNWidgets(2));
    expect(find.byKey(const Key('follow_card_avatars')), findsNothing);
    expect(find.text('No followers yet'), findsNothing);
    expect(find.text('Not following anyone yet'), findsNothing);
    expect(find.byIcon(Icons.ios_share), findsNothing);
  });

  testWidgets('loading shows dashes in the same fixed footprint',
      (tester) async {
    await w.counts('t', followers: 3);
    await w.follow('u1', 't');
    w.briefs({'u1': const UserBrief(name: 'Ana')});
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'me')));
    expect(find.text('–'), findsNWidgets(2));
    final before = tester.getSize(find.byKey(const Key('follow_card')));
    await tester.pumpAndSettle();
    expect(find.text('–'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('follow_card'))), before);
  });

  for (final tab in [0, 1]) {
    testWidgets('tapping a block opens the list on tab $tab', (tester) async {
      await w.counts('t', followers: 1, following: 1);
      await w.follow('u1', 't');
      await w.follow('t', 'x1');
      w.briefs({'u1': const UserBrief(name: 'Ana'), 'x1': const UserBrief(name: 'Bia')});
      await tester.pumpWidget(
          wrapForTest(const FollowCard(userId: 't', currentUserId: 'me')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(
          Key(tab == 0 ? 'follow_card_followers' : 'follow_card_following')));
      await tester.pumpAndSettle();
      final screen =
          tester.widget<FollowListScreen>(find.byType(FollowListScreen));
      expect(screen.initialTab, tab);
      expect(screen.userId, 't');
      final ctrl = DefaultTabController.of(
          tester.element(find.byType(TabBarView)));
      expect(ctrl.index, tab);
    });
  }
}
