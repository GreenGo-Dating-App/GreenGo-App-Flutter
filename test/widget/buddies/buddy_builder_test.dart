import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/theme/app_theme.dart';
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

  /// Opens the builder on a phone-sized screen with the REAL app theme
  /// (its ElevatedButton has an infinite minimum width: the cause of the
  /// "stuck at step 2" bug).
  Future<void> open(WidgetTester tester, {Size size = const Size(360, 780)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<String>(MaterialPageRoute(
                  builder: (_) => BuddyBuilderScreen(
                      userId: 'u1',
                      repository: repo,
                      prompts: prompts,
                      buddyLimit: 1,
                      tier: 'FREE'),
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

  Finder next() => find.byKey(const ValueKey('buddy-builder-next'));

  bool nextEnabled(WidgetTester tester) => tester.widget<ElevatedButton>(next()).onPressed != null;

  Future<void> pickCategory(WidgetTester tester, String query, String label) async {
    final field = find.descendant(
        of: find.byKey(const ValueKey('buddy-category')), matching: find.byType(TextField));
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, query);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, label).hitTestable().first);
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.ensureVisible(next());
    await tester.tap(next());
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(320, 640), Size(360, 780), Size(412, 915)]) {
    testWidgets(
        'regression: step 2 continues with the app theme on a ${size.width.toInt()}dp phone',
        (tester) async {
      await open(tester, size: size);
      await pickCategory(tester, 'guit', 'Guitar');
      await tapNext(tester);
      expect(find.text('Step 2 of 3'), findsOneWidget);
      // Before the fix the Next button could not be laid out here.
      expect(next().hitTestable(), findsOneWidget);
      expect(nextEnabled(tester), isTrue);
      await tapNext(tester);
      expect(find.text('Step 3 of 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('category + language -> tone -> name + picture -> create', (tester) async {
    await open(tester);
    expect(find.text('Step 1 of 3'), findsOneWidget);
    // No role, level, CEFR or ready-made suggestions any more.
    expect(find.text('Quick start'), findsNothing);
    expect(find.textContaining('Teacher'), findsNothing);
    expect(nextEnabled(tester), isFalse, reason: 'a category is required');

    // Practise Italian presets the Buddy language to Italian.
    await pickCategory(tester, 'ital', 'Practise Italian');
    final itChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('buddy-lang-it')));
    expect(itChip.selected, isTrue);
    expect(find.text('Your Buddy always speaks only this language.'), findsOneWidget);
    await tapNext(tester);

    expect(find.text('How should your Buddy sound?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buddy-tone-calm')));
    await tester.pump();
    await tapNext(tester);

    // Pictures from buddy_avatars; the first is preselected.
    expect(find.byKey(const ValueKey('buddy-avatar-av_fox')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-avatar-av_cat')), findsOneWidget);
    expect(nextEnabled(tester), isFalse, reason: 'name required');
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Bad!');
    await tester.pump();
    expect(find.text('Use 1 to 24 letters, numbers, spaces, dots, apostrophes or hyphens.'),
        findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), ' Giulia ');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-avatar-av_owl')));
    await tester.pump();
    expect(find.text('Create Buddy'), findsOneWidget);
    await tapNext(tester);

    final s = repo.created.single;
    expect(s.toMap(), {
      'name': 'Giulia',
      'avatar': 'av_owl',
      'topic': 'practice_italian',
      'tone': 'calm',
      'language': 'it',
      'checkInsEnabled': true,
    });
    expect(repo.avatarReads, 1);
    expect(popped, 'new-buddy');
  });

  testWidgets('category combobox filters by topic and by group label', (tester) async {
    await open(tester);
    final field = find.descendant(
        of: find.byKey(const ValueKey('buddy-category')), matching: find.byType(TextField));
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, 'arts & mu');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(MenuItemButton, 'Guitar').hitTestable(), findsWidgets);
    expect(find.widgetWithText(MenuItemButton, 'Films').hitTestable(), findsNothing);
  });

  testWidgets('pictures fail to load: retry line, legacy fallback keeps Create possible',
      (tester) async {
    repo.avatarsError = StateError('offline');
    await open(tester);
    await pickCategory(tester, 'guit', 'Guitar');
    await tapNext(tester);
    await tapNext(tester);
    expect(find.byKey(const ValueKey('buddy-avatars-failed')), findsOneWidget);
    expect(find.text("Couldn't load the pictures."), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Max');
    await tester.pump();
    expect(nextEnabled(tester), isTrue);

    repo.avatarsError = null;
    await tester.tap(find.byKey(const ValueKey('buddy-avatars-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buddy-avatar-av_fox')), findsOneWidget);
    await tapNext(tester);
    expect(repo.created.single.avatar, 'av_fox', reason: 'picture replaces the fallback');
  });

  testWidgets('plan limit reached on create -> upgrade prompt', (tester) async {
    repo.createError = FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'tier-required: x',
        details: const {'reason': 'tier-required', 'limit': 1});
    await open(tester);
    await pickCategory(tester, 'run', 'Running');
    await tapNext(tester);
    await tapNext(tester);
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Max');
    await tester.pump();
    await tapNext(tester);
    expect(prompts.calls, ['upgrade:1']);
    expect(popped, isNull);
    expect(nextEnabled(tester), isTrue, reason: 'can try again');
  });
}
