import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/core/widgets/glass_container.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/follow_card.dart';

import 'follow_test_support.dart';

void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  Finder inPill(String key, Finder f) =>
      find.descendant(of: find.byKey(Key(key)), matching: f);

  testWidgets('two glass pills "12 Followers" / "64 Following", no avatars',
      (tester) async {
    await w.counts('t', followers: 12, following: 64);
    await w.follow('u1', 't');

    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();

    expect(inPill('follow_card_followers', find.text('12 Followers')),
        findsOneWidget);
    expect(inPill('follow_card_following', find.text('64 Following')),
        findsOneWidget);
    expect(find.byType(GlassContainer), findsNWidgets(2));
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byKey(const Key('follow_card_avatars')), findsNothing);
    expect(find.textContaining('others'), findsNothing);
    // Number is gold + bold, label is a separate span.
    final rich = tester.widget<Text>(inPill(
        'follow_card_followers', find.byKey(const Key('follow_card_pill_text'))));
    final first = (rich.textSpan! as TextSpan).children!.first as TextSpan;
    expect(first.text, '12');
    expect(first.style!.fontWeight, FontWeight.w700);
    // Pills sit side by side with a 10 px gap, fixed 36 height.
    final a = tester.getRect(find.byKey(const Key('follow_card_followers')));
    final b = tester.getRect(find.byKey(const Key('follow_card_following')));
    expect(b.left - a.right, closeTo(FollowCard.gap, 0.01));
    expect(a.height, FollowCard.height);
    expect(find.bySemanticsLabel('12 followers'), findsOneWidget);
    expect(find.bySemanticsLabel('64 following'), findsOneWidget);
    expect(tester.takeException(), isNull); // no overflow at 320 dp
  });

  testWidgets('singular label and compact counts', (tester) async {
    await w.counts('t', followers: 1, following: 3400);
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'viewer')));
    await tester.pumpAndSettle();
    expect(find.text('1 Follower'), findsOneWidget);
    expect(find.text('3.4k Following'), findsOneWidget);

    await w.counts('t', followers: 1250000);
    await tester.pumpAndSettle();
    expect(find.text('1.2M Followers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('own profile, no followers: "0 Followers" / "0 Following"',
      (tester) async {
    await w.counts('me');
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 'me', currentUserId: 'me')));
    await tester.pumpAndSettle();
    expect(find.text('0 Followers'), findsOneWidget);
    expect(find.text('0 Following'), findsOneWidget);
  });

  testWidgets('loading shows dashes in the same fixed footprint',
      (tester) async {
    await w.counts('t', followers: 3);
    await tester.pumpWidget(
        wrapForTest(const FollowCard(userId: 't', currentUserId: 'me')));
    expect(find.text('– Followers'), findsOneWidget);
    expect(find.text('– Following'), findsOneWidget);
    final before = tester.getSize(find.byKey(const Key('follow_card')));
    await tester.pumpAndSettle();
    expect(find.textContaining('–'), findsNothing);
    expect(find.text('3 Followers'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('follow_card'))), before);
  });

  for (final tab in [0, 1]) {
    testWidgets('tapping a pill opens the list on tab $tab', (tester) async {
      await w.counts('t', followers: 1, following: 1);
      await w.follow('u1', 't');
      await w.follow('t', 'x1');
      w.briefs({
        'u1': const UserBrief(name: 'Ana'),
        'x1': const UserBrief(name: 'Bia'),
      });
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
