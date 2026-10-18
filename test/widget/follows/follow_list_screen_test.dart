import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/user_follow_button.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import 'follow_test_support.dart';

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: home,
    );

void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  Finder rows() => find.byType(FollowRow);

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('follow_list_search')), text);
    await tester.pump(FollowListTab.debounce);
    await tester.pumpAndSettle();
  }

  testWidgets('tab labels carry the counts; own Followers tab shows "Follows you"',
      (tester) async {
    await w.counts('me', followers: 3, following: 1200);
    await w.follow('u1', 'me', followerName: 'maria silva');
    await w.follow('u2', 'me', followerName: 'joao');
    await w.follow('u3', 'me', followerName: 'mario');
    await w.follow('me', 'x1', followeeName: 'bia');
    w.briefs({
      'u1': const UserBrief(name: 'Maria Silva', city: 'Lisbon', country: 'Portugal'),
      'u2': const UserBrief(name: 'João'),
      'u3': const UserBrief(name: 'Mário'),
      'x1': const UserBrief(name: 'Bia'),
    });

    await tester.pumpWidget(
        _app(const FollowListScreen(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();

    expect(find.text('Followers 3'), findsOneWidget);
    expect(find.text('Following 1.2k'), findsOneWidget);
    expect(rows(), findsNWidgets(3));
    // Everyone on MY followers list follows me.
    // "Follows you" is the subtitle prefix, joined with the city + flag.
    expect(find.text('Follows you · 🇵🇹 Lisbon, Portugal'), findsOneWidget);
    expect(find.text('Follows you'), findsNWidgets(2)); // no city known
    expect(find.text('Follow back'), findsNWidgets(3));
    // Compact pill: text only, filled while not following.
    expect(
        find.descendant(
            of: find.byType(UserFollowButton), matching: find.byType(Icon)),
        findsNothing);

    // The Following tab: no "Follows you" chip (it would cost a read per row).
    await tester.tap(find.text('Following 1.2k'));
    await tester.pumpAndSettle();
    expect(find.text('Bia'), findsOneWidget);
    expect(find.textContaining('Follows you'), findsNothing);
  });

  testWidgets('search queries the server by name prefix; clearing restores',
      (tester) async {
    await w.counts('me', followers: 4);
    await w.follow('u1', 'me', followerName: 'maria silva');
    await w.follow('u2', 'me', followerName: 'joao');
    await w.follow('u3', 'me', followerName: 'mario');
    await w.follow('u4', 'me'); // legacy edge: no name yet (pre-backfill)
    w.briefs({
      'u1': const UserBrief(name: 'Maria Silva'),
      'u2': const UserBrief(name: 'João'),
      'u3': const UserBrief(name: 'Mário'),
      'u4': const UserBrief(name: 'Legacy Marcos'),
    });
    await tester.pumpWidget(
        _app(const FollowListScreen(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(rows(), findsNWidgets(4)); // the legacy row still lists normally

    // Case- and accent-insensitive, matched on the server-written name.
    await search(tester, 'MÁR');
    expect(rows(), findsNWidgets(2));
    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Mário'), findsOneWidget);
    expect(find.text('João'), findsNothing);

    await search(tester, 'zzz');
    expect(rows(), findsNothing);
    expect(find.text('No one matches “zzz”'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(rows(), findsNWidgets(4));
  });

  testWidgets('endless loading in a search (20 per page)', (tester) async {
    await w.counts('me', followers: 35);
    final briefs = <String, UserBrief>{};
    for (var i = 0; i < 35; i++) {
      final n = i.toString().padLeft(2, '0');
      await w.follow('u$n', 'me', followerName: 'ana $n');
      briefs['u$n'] = UserBrief(name: 'Ana $n');
    }
    w.briefs(briefs);
    await tester.pumpWidget(
        _app(const FollowListScreen(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();

    // (The normal list's own paging is unchanged; fake_cloud_firestore
    // mis-handles startAfterDocument on a DESCENDING order, so it is not
    // re-asserted here.) First page: the 30 newest.
    expect(find.text('Ana 34'), findsOneWidget);
    final list = find
        .descendant(
            of: find.byKey(const Key('follow_list_followers')),
            matching: find.byType(Scrollable))
        .first;

    // Search pages are 20: "Ana 24" (alphabetically 25th) needs page 2.
    await search(tester, 'ana');
    await tester.scrollUntilVisible(find.text('Ana 24'), 400, scrollable: list);
    expect(find.text('Ana 24'), findsOneWidget);
  });

  testWidgets("someone else's lists are private: nothing is shown or read",
      (tester) async {
    await w.counts('t', followers: 2, following: 1);
    await w.follow('u1', 't', followerName: 'ana');
    w.briefs({'u1': const UserBrief(name: 'Ana')});
    await tester.pumpWidget(
        _app(const FollowListScreen(userId: 't', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('follow_list_private')), findsOneWidget);
    expect(rows(), findsNothing);
    expect(find.byType(TabBar), findsNothing);
    expect(find.textContaining('Followers'), findsNothing);
    expect(find.text('Ana'), findsNothing);
    expect(FollowListScreen.canOpen('t', 'me'), isFalse);
    expect(FollowListScreen.canOpen('me', 'me'), isTrue);
    expect(FollowListScreen.canOpen('', ''), isFalse);
  });

  testWidgets('pill flips Follow -> Following (filled -> outlined)',
      (tester) async {
    // Own Following list: unfollow then follow again from the row.
    await w.counts('me', following: 1);
    await w.follow('me', 'u1', followeeName: 'ana');
    w.briefs({'u1': const UserBrief(name: 'Ana', city: 'Rome')});
    await tester.pumpWidget(_app(const FollowListScreen(
        userId: 'me', currentUserId: 'me', initialTab: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Rome'), findsOneWidget);
    await w.fs
        .collection('business_followers')
        .doc('u1')
        .collection('followers')
        .doc('me')
        .delete();
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsOneWidget);
    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(find.text('Following'), findsWidgets);
    expect(
        find.descendant(
            of: find.byType(FollowRow), matching: find.text('Following')),
        findsOneWidget);
    // Let the follow write's deferred work (count overlay expiry) finish.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 10));
  });

  testWidgets('empty list: one short line with a muted icon', (tester) async {
    await w.counts('me');
    await tester.pumpWidget(
        _app(const FollowListScreen(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('follow_list_message')), findsOneWidget);
    expect(find.text('No followers yet'), findsOneWidget);
    expect(find.byIcon(Icons.people_outline), findsOneWidget);
  });

  test('subtitleLine', () {
    expect(FollowRow.subtitleLine('Follows you', 'Rome', followsYou: true),
        'Follows you · Rome');
    expect(FollowRow.subtitleLine('Follows you', '', followsYou: true),
        'Follows you');
    expect(FollowRow.subtitleLine('Follows you', 'Rome', followsYou: false),
        'Rome');
    expect(FollowRow.subtitleLine('Follows you', '', followsYou: false), '');
  });
}
