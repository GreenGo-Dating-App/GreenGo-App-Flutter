import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/follow_card.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import 'follow_test_support.dart';

void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  Finder inTile(String tileKey, Finder f) =>
      find.descendant(of: find.byKey(Key(tileKey)), matching: f);

  group('followNamesLine', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    String line(List<String> names, int total) =>
        followNamesLine(l10n, names, total, locale: 'en');

    test('one name', () => expect(line(['Maria Silva'], 1), 'Maria'));
    test('two names', () => expect(line(['Maria', 'João'], 2), 'Maria and João'));
    test('two names + others', () {
      expect(line(['Maria Silva', 'João', 'Ana'], 12), 'Maria, João and 10 others');
      expect(line(['Maria', 'João'], 3), 'Maria, João and 1 other');
    });
    test('missing names are skipped, never shown as ids', () {
      expect(line(['', 'João'], 5), 'João and 4 others');
      expect(line(['', ''], 2), '2 people');
      expect(line([], 1500), '1.5k people');
      expect(line(['@zed'], 1), '@zed');
    });
    test('a lagging counter never undercounts the names shown', () {
      expect(line(['Maria', 'João'], 0), 'Maria and João');
    });
  });

  testWidgets('numbers, at most 4 newest avatars and the names line',
      (tester) async {
    await w.counts('t', followers: 12, following: 0);
    for (var i = 1; i <= 6; i++) {
      await w.follow('u$i', 't');
    }
    w.briefs({
      for (var i = 1; i <= 6; i++) 'u$i': UserBrief(name: 'User$i Last'),
    });

    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();

    expect(inTile('follow_card_followers', find.byKey(const Key('follow_card_count'))),
        findsOneWidget);
    expect(inTile('follow_card_followers', find.text('12')), findsOneWidget);
    expect(inTile('follow_card_followers', find.text('Followers')), findsOneWidget);
    expect(
      find.descendant(
          of: find.byKey(const Key('follow_card_avatars')),
          matching: find.byType(CircleAvatar)),
      findsNWidgets(4),
    );
    // Newest first: u6, u5.
    expect(inTile('follow_card_followers', find.text('User6, User5 and 10 others')),
        findsOneWidget);
    // Following tile is empty: friendly text, no share button (not own).
    expect(inTile('follow_card_following', find.text('Not following anyone yet')),
        findsOneWidget);
    expect(find.byKey(const Key('follow_card_share')), findsNothing);
    expect(tester.takeException(), isNull); // no overflow at 320 dp
  });

  testWidgets('big counts are compact', (tester) async {
    await w.counts('t', followers: 1250000, following: 3400);
    await w.follow('u1', 't');
    await w.follow('t', 'x1');
    w.briefs({'u1': const UserBrief(name: 'Ana'), 'x1': const UserBrief(name: 'Bia')});
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();
    expect(find.text('1.2M'), findsOneWidget);
    expect(find.text('3.4k'), findsOneWidget);
    expect(find.text('Ana and 1.2M others'), findsOneWidget);
    expect(find.text('Bia and 3.3k others'), findsOneWidget);
  });

  testWidgets('blocked-out / inactive people are not shown', (tester) async {
    await w.counts('t', followers: 2);
    await w.follow('gone', 't');
    await w.follow('u1', 't');
    w.briefs({'u1': const UserBrief(name: 'Ana'), 'gone': UserBrief.missing});
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
          of: find.byKey(const Key('follow_card_avatars')),
          matching: find.byType(CircleAvatar)),
      findsOneWidget,
    );
    expect(find.text('Ana and 1 other'), findsOneWidget);
  });

  testWidgets('own profile, no followers: empty text + Share profile button',
      (tester) async {
    await w.counts('me');
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(inTile('follow_card_followers', find.text('No followers yet')),
        findsOneWidget);
    expect(inTile('follow_card_followers', find.byKey(const Key('follow_card_share'))),
        findsOneWidget);
    // Only on the Followers tile.
    expect(find.byKey(const Key('follow_card_share')), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('someone else with no followers: no share button', (tester) async {
    await w.counts('t');
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(find.text('No followers yet'), findsOneWidget);
    expect(find.byKey(const Key('follow_card_share')), findsNothing);
  });

  testWidgets('skeleton while loading keeps the same footprint', (tester) async {
    await w.counts('t', followers: 3);
    await w.follow('u1', 't');
    w.briefs({'u1': const UserBrief(name: 'Ana')});
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'me')));
    expect(find.byKey(const Key('follow_card_skeleton')), findsNWidgets(2));
    final before = tester.getSize(find.byKey(const Key('follow_card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('follow_card_skeleton')), findsNothing);
    expect(tester.getSize(find.byKey(const Key('follow_card'))), before);
  });

  for (final tab in [0, 1]) {
    testWidgets('tapping a tile opens the list on tab $tab', (tester) async {
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
