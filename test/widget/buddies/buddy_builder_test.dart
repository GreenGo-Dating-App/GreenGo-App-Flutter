import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/theme/app_theme.dart';
import 'package:greengo_chat/features/buddies/domain/buddy_catalog.dart';
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

  /// Opens the select [key] and picks its item [value].
  Future<void> pick(WidgetTester tester, String key, String value) async {
    await tester.ensureVisible(find.byKey(ValueKey(key)));
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('$key-$value')).last);
    await tester.pumpAndSettle();
  }

  DropdownButton<String> select(WidgetTester tester, String key) =>
      tester.widget<DropdownButton<String>>(find.byKey(ValueKey(key)));

  List<String?> items(WidgetTester tester, String key) =>
      [for (final i in select(tester, key).items!) i.value];

  Future<void> tapNext(WidgetTester tester) async {
    await tester.ensureVisible(next());
    await tester.tap(next());
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(320, 640), Size(360, 780), Size(412, 915)]) {
    testWidgets(
        'regression: step 2 (name + picture) continues with the app theme on a '
        '${size.width.toInt()}dp phone', (tester) async {
      await open(tester, size: size);
      await pick(tester, 'buddy-macro', 'arts');
      await pick(tester, 'buddy-micro', 'guitar');
      await tapNext(tester);
      expect(find.text('Step 2 of 2'), findsOneWidget);
      // Before the fix the footer button could not be laid out (infinite
      // ElevatedButton min width from the app theme next to a Spacer).
      expect(next().hitTestable(), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Max');
      await tester.pump();
      expect(nextEnabled(tester), isTrue);
      await tapNext(tester);
      expect(repo.created.single.topic, 'guitar');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('step 1 = the selects; the topic list depends on the main category',
      (tester) async {
    await open(tester);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    for (final k in [
      'buddy-macro',
      'buddy-micro',
      'buddy-language',
      'buddy-chat-language',
      'buddy-tone',
    ]) {
      expect(find.byKey(ValueKey(k)), findsOneWidget, reason: k);
    }
    // The chat translation language: default = the app language, with flags.
    expect(find.text('Translate this chat into'), findsOneWidget);
    expect(find.text("Messages are translated once into this language. It can't be changed later."),
        findsOneWidget);
    expect(select(tester, 'buddy-chat-language').value, 'en');
    expect(items(tester, 'buddy-chat-language'), BuddyCatalog.languages);
    // Both language selects show a flag next to every language (closed
    // field and list).
    expect(find.text('🇬🇧 English'), findsNWidgets(2));
    expect(find.text('Which language should your Buddy speak?'), findsOneWidget);
    for (final key in ['buddy-language', 'buddy-chat-language']) {
      final labels = [
        for (final i in select(tester, key).items!) ((i.child as Text).data ?? ''),
      ];
      expect(labels, [
        '🇬🇧 English',
        '🇩🇪 German',
        '🇪🇸 Spanish',
        '🇫🇷 French',
        '🇮🇹 Italian',
        '🇵🇹 Portuguese (Portugal)',
        '🇧🇷 Portuguese (Brazil)',
      ], reason: key);
    }
    expect(find.text('Main category'), findsOneWidget);
    expect(find.text('How should your Buddy sound?'), findsOneWidget);
    expect(find.text("Your Buddy always speaks only this language. It can't be changed later."),
        findsOneWidget);
    // No role, level, CEFR or ready-made suggestions.
    expect(find.text('Quick start'), findsNothing);
    expect(find.textContaining('Teacher'), findsNothing);

    // Topic select disabled until a main category is chosen.
    // Nothing preselected: placeholders; the sub-category select is
    // disabled until a category is chosen.
    expect(select(tester, 'buddy-macro').value, isNull);
    expect(select(tester, 'buddy-micro').value, isNull);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(select(tester, 'buddy-micro').onChanged, isNull);
    expect(find.text('Choose a sub-category'), findsWidgets);
    expect(nextEnabled(tester), isFalse, reason: 'a topic is required');

    // Only the topics of the chosen category are offered.
    await pick(tester, 'buddy-macro', 'languages');
    expect(items(tester, 'buddy-micro'), [for (final t in BuddyCatalog.topicsOf('languages')) t.id]);
    expect(items(tester, 'buddy-micro'), isNot(contains('guitar')));

    // Practise Italian presets the Buddy language to Italian.
    await pick(tester, 'buddy-micro', 'practice_italian');
    expect(select(tester, 'buddy-language').value, 'it');
    expect(select(tester, 'buddy-chat-language').value, 'en',
        reason: 'a practice topic never changes the translation language');
    expect(nextEnabled(tester), isTrue);

    // Another main category clears the topic (it belonged to the old one).
    await pick(tester, 'buddy-macro', 'arts');
    expect(select(tester, 'buddy-micro').value, isNull);
    expect(items(tester, 'buddy-micro'), [for (final t in BuddyCatalog.topicsOf('arts')) t.id]);
    expect(nextEnabled(tester), isFalse);
    expect(select(tester, 'buddy-language').value, 'it', reason: 'language is kept');

    await pick(tester, 'buddy-micro', 'guitar');
    await pick(tester, 'buddy-language', 'pt_BR');
    await pick(tester, 'buddy-chat-language', 'it');
    await pick(tester, 'buddy-tone', 'calm');
    await tapNext(tester);

    // Step 2: name + picture from buddy_avatars; the first is preselected.
    expect(find.text('Step 2 of 2'), findsOneWidget);
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

    expect(repo.created.single.toMap(), {
      'name': 'Giulia',
      'avatar': 'av_owl',
      'topic': 'guitar',
      'tone': 'calm',
      'language': 'pt_BR',
      'chatLanguage': 'it',
      'checkInsEnabled': true,
    });
    expect(repo.avatarReads, 1);
    expect(popped, 'new-buddy');
  });

  testWidgets('back from step 2 keeps the choices', (tester) async {
    await open(tester);
    await pick(tester, 'buddy-macro', 'food');
    await pick(tester, 'buddy-micro', 'coffee');
    await tapNext(tester);
    await tester.tap(find.byKey(const ValueKey('buddy-builder-back')));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(select(tester, 'buddy-macro').value, 'food');
    expect(select(tester, 'buddy-micro').value, 'coffee');
  });

  testWidgets('pictures fail to load: retry line, legacy fallback keeps Create possible',
      (tester) async {
    repo.avatarsError = StateError('offline');
    await open(tester);
    await pick(tester, 'buddy-macro', 'arts');
    await pick(tester, 'buddy-micro', 'guitar');
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
    await pick(tester, 'buddy-macro', 'sport');
    await pick(tester, 'buddy-micro', 'running');
    await tapNext(tester);
    await tester.enterText(find.byKey(const ValueKey('buddy-name-field')), 'Max');
    await tester.pump();
    await tapNext(tester);
    expect(prompts.calls, ['upgrade:1']);
    expect(popped, isNull);
    expect(nextEnabled(tester), isTrue, reason: 'can try again');
  });
}
