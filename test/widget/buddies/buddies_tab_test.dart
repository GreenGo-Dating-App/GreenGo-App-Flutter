import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/widgets/buddies_tab.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/buddies_fakes.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

/// The plan-usage line is horizontally centered (owner 2026-10-24).
void expectCentered(WidgetTester tester) {
  final screenMid = tester.getSize(find.byType(Scaffold)).width / 2;
  for (final k in ['buddies-plan-usage', 'buddies-free-replies']) {
    final f = find.byKey(ValueKey(k));
    expect(tester.getCenter(f).dx, moreOrLessEquals(screenMid, epsilon: 1), reason: k);
    expect(tester.widget<Text>(f).textAlign, TextAlign.center, reason: k);
  }
}

void main() {
  late FakeBuddiesRepository repo;
  late FakeBuddyPrompts prompts;

  setUp(() {
    repo = FakeBuddiesRepository();
    prompts = FakeBuddyPrompts();
  });

  tearDown(() => repo.dispose());

  Future<void> pumpTab(WidgetTester tester) async {
    await tester.pumpWidget(_app(BuddiesTab(userId: 'u1', repository: repo, prompts: prompts)));
    await tester.pump();
  }

  testWidgets('empty state: create button, plan usage and free replies', (tester) async {
    await pumpTab(tester);
    repo.buddies.add(const []);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('buddies-empty')), findsOneWidget);
    expect(find.text('Create your Buddy'), findsOneWidget);
    expect(find.text('0 of 1 Buddies'), findsOneWidget);
    expect(find.text('7 free replies left today · then 1 coin per reply'), findsOneWidget);
    expectCentered(tester);

    await tester.tap(find.byKey(const ValueKey('buddies-create')));
    await tester.pumpAndSettle();
    // The builder opened on step 1.
    expect(find.text('What do you want to talk about?'), findsOneWidget);
  });

  testWidgets('list: name, topic, last message, AI badge; locked Buddy greyed', (tester) async {
    repo.status = const BuddyStatus(
        tier: 'FREE',
        buddyLimit: 1,
        buddyCount: 2,
        freeRepliesPerDay: 10,
        freeRepliesLeft: 3,
        coinsPerReply: 1);
    await pumpTab(tester);
    repo.buddies.add([
      fakeBuddy('old',
          name: 'Sunny',
          topic: 'movies',
          createdAt: DateTime(2026, 1, 1),
          lastMessage: 'Seen any good films?',
          lastMessageAt: DateTime(2026, 10, 2)),
      fakeBuddy('new', name: 'Luca', topic: 'practice_italian', createdAt: DateTime(2026, 6, 1)),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Sunny'), findsOneWidget);
    expect(find.text('Films · Seen any good films?'), findsOneWidget);
    expect(find.text('2 of 1 Buddies'), findsOneWidget);
    expectCentered(tester);
    expect(find.byKey(const ValueKey('buddy-ai-badge')), findsWidgets);
    // Newest Buddy beyond the Free limit is locked.
    expect(find.byKey(const ValueKey('buddy-locked-new')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-locked-old')), findsNothing);
    expect(find.text('Locked on your plan. Upgrade to chat again.'), findsOneWidget);

    // At the limit, "New Buddy" shows the upgrade prompt instead of the builder.
    await tester.tap(find.byKey(const ValueKey('buddies-new')));
    await tester.pump();
    expect(prompts.calls, ['upgrade:1']);
  });

  testWidgets('price comes from getBuddyStatus: 0.2 coins per reply + prepaid replies',
      (tester) async {
    repo.status = const BuddyStatus(
        tier: 'SILVER',
        buddyLimit: 10,
        buddyCount: 0,
        freeRepliesPerDay: 30,
        freeRepliesLeft: 12,
        coinsPerReply: 0.2,
        repliesPerCoin: 5,
        replyCredits: 2);
    await pumpTab(tester);
    repo.buddies.add(const []);
    await tester.pump();
    await tester.pump();
    expect(find.text('0 of 10 Buddies'), findsOneWidget);
    expect(
        find.text('12 free replies left today · then 0.2 coins per reply (1 coin = 5 replies)'
            ' · 2 prepaid replies'),
        findsOneWidget);
    expectCentered(tester);
  });
}
