import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/presentation/screens/buddy_builder_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/buddies_fakes.dart';

void main() {
  late FakeBuddiesRepository repo;
  late FakeBuddyPrompts prompts;
  String? popped;

  setUp(() {
    repo = FakeBuddiesRepository();
    prompts = FakeBuddyPrompts();
    popped = null;
  });

  tearDown(() => repo.dispose());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<String>(MaterialPageRoute(
                  builder: (_) => BuddyBuilderScreen(
                      userId: 'u1', repository: repo, prompts: prompts, buddyLimit: 1, tier: 'FREE'),
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('suggestion -> role -> language + CEFR -> name, look, tone -> create', (tester) async {
    await open(tester);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.text('Quick start'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buddy-suggestion-italian_teacher')));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 4'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buddy-role-coach')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-builder-next')));
    await tester.pumpAndSettle();

    // Language practice: Italian preselected and CEFR offered.
    expect(find.text('Language level (optional)'), findsOneWidget);
    final itChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('buddy-lang-it')));
    expect(itChip.selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('buddy-cefr-B1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-builder-next')));
    await tester.pumpAndSettle();

    // Name required (server rule), then avatar + tone.
    final next = find.byKey(const ValueKey('buddy-builder-next'));
    expect(tester.widget<ElevatedButton>(next).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Bad!');
    await tester.pump();
    expect(find.text("Use 1 to 24 letters, numbers, spaces, dots, apostrophes or hyphens."), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), ' Giulia ');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-avatar-buddy_12')));
    await tester.tap(find.byKey(const ValueKey('buddy-tone-calm')));
    await tester.pump();
    await tester.tap(next);
    await tester.pumpAndSettle();

    final s = repo.created.single;
    expect(s.name, 'Giulia');
    expect(s.topic, 'practice_italian');
    expect(s.role, 'coach');
    expect(s.language, 'it');
    expect(s.cefr, 'B1');
    expect(s.avatar, 'buddy_12');
    expect(s.tone, 'calm');
    expect(popped, 'new-buddy');
  });

  testWidgets('topic search is grouped and filters; non-language topic has no CEFR', (tester) async {
    await open(tester);
    expect(find.text('Languages & culture'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('buddy-topic-search')), 'guit');
    await tester.pump();
    expect(find.byKey(const ValueKey('buddy-topic-guitar')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-topic-movies')), findsNothing);
    expect(find.text('Arts & music'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('buddy-topic-search')), 'zzzz');
    await tester.pump();
    expect(find.text('No topics found'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('buddy-topic-search')), 'guit');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-topic-guitar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-builder-next')));
    await tester.pumpAndSettle();
    expect(find.text('Language level (optional)'), findsNothing);
  });

  testWidgets('plan limit reached on create -> upgrade prompt', (tester) async {
    repo.createError = FirebaseFunctionsException(
        code: 'failed-precondition', message: 'tier-required: x', details: const {'reason': 'tier-required', 'limit': 1});
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('buddy-suggestion-running_coach')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-builder-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-builder-next')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Max');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-builder-next')));
    await tester.pumpAndSettle();
    expect(prompts.calls, ['upgrade:1']);
    expect(popped, isNull);
  });
}
