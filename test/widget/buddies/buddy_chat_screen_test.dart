import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/buddies/presentation/buddy_segments.dart';
import 'package:greengo_chat/core/services/app_sound_service.dart';
import 'package:greengo_chat/core/services/chat_datasets/chat_datasets.dart';
import 'package:greengo_chat/core/services/chat_datasets/keyword_matcher.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/screens/buddy_chat_screen.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_ideas_sheet.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/buddies_fakes.dart';

void main() {
  late FakeBuddiesRepository repo;
  late FakeBuddyPrompts prompts;
  final t0 = DateTime(2026, 10, 20, 9);

  setUpAll(() {
    // Offline datasets as the 1:1 chat uses them (no download in tests).
    LocalizedText t(String en) => LocalizedText({'en': en, 'it': '$en (it)'});
    ChatDatasets.instance.debugSet(
      keywords: KeywordIndex.fromJson({
        'a': <String, dynamic>{},
        'c': {'PT:lisbon': ['Lisbon']},
        'k': {'PT': 'Portugal'},
        'n': [
          ['lisbon', 'c', 'PT:lisbon', 0],
          ['portugal', 'k', 'PT', 0],
        ],
      }),
      icebreakers: [
        DatasetItem(id: 'ib-travel-001', topic: 'travel', text: t('Where would you go tomorrow?')),
      ],
      sentences: [
        DatasetItem(id: 's-001', topic: 'travel', text: t('I love travelling.')),
      ],
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = FakeBuddiesRepository();
    prompts = FakeBuddyPrompts();
  });

  tearDown(() => repo.dispose());

  Future<void> open(WidgetTester tester,
      {bool locked = false, FakeBuddyPrompts? p, Buddy? buddy, NavigatorObserver? observer}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [if (observer != null) observer],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BuddyChatScreen(
        userId: 'u1',
        buddyId: 'b1',
        initialBuddy: buddy ?? fakeBuddy('b1'),
        locked: locked,
        repository: repo,
        prompts: p ?? prompts,
      ),
    ));
    await tester.pump();
    await tester.pump();
  }

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('buddy-input')), text);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the 1:1 chat bubbles: header, AI notice, AI badge, check-in mark, quota, counter',
      (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'How was your day?', t0,
          kind: BuddyMessageKind.checkin),
      fakeMessage('m2', BuddyMessageRole.user, 'Great!', t0.add(const Duration(minutes: 1))),
    ], hasMore: false);
    await open(tester);

    expect(find.text('Sunny'), findsOneWidget);
    expect(find.text('Films'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-ai-disclosure')), findsOneWidget);
    // Messages are the normal chat's MessageBubble.
    expect(find.byType(MessageBubble), findsNWidgets(2));
    expect(find.text('How was your day?'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('buddy-msg-m1')),
            matching: find.byKey(const ValueKey('buddy-ai-badge'))),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('buddy-msg-m2')),
            matching: find.byKey(const ValueKey('buddy-ai-badge'))),
        findsNothing,
        reason: 'the AI badge is only on Buddy messages');
    expect(find.byKey(const ValueKey('buddy-msg-mark-checkin')), findsOneWidget);
    expect(find.text('7 free replies left today · then 1 coin per reply'), findsOneWidget);
    expect(find.text('0/200'), findsOneWidget);
    // The 1:1 chat's languages menu + the extra Buddy settings icon.
    expect(find.byKey(const ValueKey('buddy-chat-languages')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-settings-button')), findsOneWidget);
  });

  testWidgets('no language-level (CEFR) badge on Buddy messages', (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy,
          'Notwithstanding the circumstances, I would wholeheartedly recommend it.', t0),
    ], hasMore: false);
    await open(tester);
    final bubble = tester.widget<MessageBubble>(find.byType(MessageBubble));
    expect(bubble.message.metadata?.containsKey('level'), isFalse);
    final cefr = RegExp(r'^[ABC][12]$');
    expect(
        find.byWidgetPredicate((w) => w is Text && w.data != null && cefr.hasMatch(w.data!)),
        findsNothing);
  });

  testWidgets('no attachments: no photo, video, voice-note or + button; ideas tools are there',
      (tester) async {
    await open(tester);
    for (final icon in [
      Icons.add_circle_outline,
      Icons.attach_file,
      Icons.mic,
      Icons.mic_none,
      Icons.photo,
      Icons.photo_camera,
      Icons.image,
      Icons.videocam,
      Icons.location_on,
    ]) {
      expect(find.byIcon(icon), findsNothing, reason: '$icon');
    }
    expect(find.byKey(const ValueKey('chat-tool-attach')), findsNothing);
    expect(find.byKey(const ValueKey('buddy-tool-icebreakers')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-tool-sentences')), findsOneWidget);
    expect(find.byKey(const ValueKey('chat-places-trip')), findsOneWidget);

    // Ice-breakers: the 1:1 chat's sheet, in the Buddy's language.
    await tester.tap(find.byKey(const ValueKey('buddy-tool-icebreakers')));
    await tester.pumpAndSettle();
    expect(find.byType(ChatIdeasSheet), findsOneWidget);
    expect(tester.widget<ChatIdeasSheet>(find.byType(ChatIdeasSheet)).partnerLanguage, 'en');
  });

  testWidgets('empty chat: conversation starters fill the input', (tester) async {
    await open(tester);
    expect(find.byKey(const ValueKey('buddy-empty-icebreakers')), findsOneWidget);
    await tester.tap(find.text('Where would you go tomorrow?').first);
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(const ValueKey('buddy-input')));
    expect(field.controller!.text, 'Where would you go tomorrow?');
  });

  testWidgets('input: hard limit of 200 characters with a counter', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'x' * 250);
    await tester.pump();
    final field = tester.widget<TextField>(find.byKey(const ValueKey('buddy-input')));
    expect(field.controller!.text.length, 200);
    expect(field.maxLength, 200);
    expect(find.text('200/200'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
    expect(repo.sent.single['text']!.length, 200);
  });

  testWidgets('send: typing indicator, reply, sounds only after success', (tester) async {
    await open(tester);
    repo.sendGate = Completer<void>();
    await send(tester, 'Hello there');
    expect(find.byKey(const ValueKey('buddy-typing')), findsOneWidget);
    expect(find.text('Sunny is typing…'), findsOneWidget);
    expect(prompts.sounds, isEmpty);

    repo.sendGate!.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('buddy-typing')), findsNothing);
    expect(find.text('Reply to Hello there'), findsOneWidget);
    expect(find.text('5 free replies left today · then 1 coin per reply'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(prompts.sounds, [AppSound.messageSent, AppSound.newMessage]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('two bubbles arriving together: the 2nd shows 1 s after the 1st, typing between',
      (tester) async {
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'Lisbon is lovely.\nHave you been?',
        replies: ['Lisbon is lovely.', 'Have you been?'],
        kind: 'chat',
        charged: 'free',
        freeRepliesLeft: 4));
    await open(tester);
    await send(tester, 'Hi');
    expect(find.textContaining('lovely', findRichText: true), findsOneWidget);
    expect(find.text('Have you been?'), findsNothing);
    expect(find.byKey(const ValueKey('buddy-typing')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Have you been?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Have you been?'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-typing')), findsNothing);
  });

  testWidgets('one bubble per turn: shown at once', (tester) async {
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'Sure!', replies: ['Sure!'], kind: 'chat', charged: 'free', freeRepliesLeft: 4));
    await open(tester);
    await send(tester, 'Hi');
    expect(find.text('Sure!'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-typing')), findsNothing);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('keyword chips: places in Buddy messages are highlighted and offered',
      (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Have you seen Lisbon?', t0),
    ], hasMore: false);
    await open(tester);
    final rich = tester
        .widgetList<RichText>(find.descendant(
            of: find.byKey(const ValueKey('buddy-msg-m1')), matching: find.byType(RichText)))
        .map((r) => r.text)
        .whereType<TextSpan>()
        .toList();
    final spans = <TextSpan>[];
    for (final r in rich) {
      r.visitChildren((s) {
        if (s is TextSpan) spans.add(s);
        return true;
      });
    }
    final hit = spans.firstWhere((s) => s.text == 'Lisbon');
    expect(hit.recognizer, isNotNull, reason: 'tappable like in the 1:1 chat');
    // The places bar suggests questions about the place the Buddy named.
    expect(find.textContaining('Lisbon', findRichText: true), findsWidgets);
  });

  testWidgets('stored translations: shown like the 1:1 chat, no translation call',
      (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Good morning', t0, translation: 'Buongiorno'),
      fakeMessage('m2', BuddyMessageRole.user, 'Morning!', t0.add(const Duration(minutes: 1)),
          translation: 'Buondì!'),
      fakeMessage('m3', BuddyMessageRole.buddy, 'Ciao', t0.add(const Duration(minutes: 2))),
    ], hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', chatLanguage: 'it'));
    // The Buddy's: translation as the main text, original underneath,
    // "Translated" mark (the MessageBubble translated display).
    expect(find.text('Buongiorno'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('buddy-msg-m1')),
            matching: find.byKey(const ValueKey('message-translated-label'))),
        findsOneWidget);
    // The user's: the original stays the main text, the translation is a
    // line under it.
    expect(find.text('Morning!'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('buddy-user-translation-m2')),
            matching: find.text('Buondì!')),
        findsOneWidget);
    // No stored translation: only the original, once, no mark.
    expect(find.text('Ciao'), findsOneWidget);
    expect(find.byKey(const ValueKey('message-translated-label')), findsOneWidget);

    // Report stays on the Buddy's messages.
    expect(find.byKey(const ValueKey('buddy-report-m2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buddy-report-m1')));
    await tester.pump();
    expect(prompts.calls, ['report:m1']);
  });

  test('the Buddy chat makes no client-side translation call', () {
    // BuddyPrompts.autoTranslate is gone; the screen must not reach any
    // translation service on its own either.
    for (final f in [
      'lib/features/buddies/presentation/screens/buddy_chat_screen.dart',
      'lib/features/buddies/presentation/widgets/buddy_prompts.dart',
      'lib/features/buddies/presentation/bloc/buddy_chat_bloc.dart',
    ]) {
      final src = File(f).readAsStringSync();
      for (final banned in [
        'TranslationService',
        'translation_service.dart',
        'translatePrivateText',
        'autoTranslate',
        'translateDetailed',
        'chatTranslationFailed',
      ]) {
        expect(src.contains(banned), isFalse, reason: '$f uses $banned');
      }
    }
  });

  testWidgets('an untranslated message renders its text exactly once', (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      // Same text but for case / punctuation: not a real translation.
      fakeMessage('m1', BuddyMessageRole.buddy, 'Hello friend', t0, translation: 'hello, friend!'),
      fakeMessage('m2', BuddyMessageRole.user, 'Grazie mille', t0.add(const Duration(minutes: 1)),
          translation: 'Grazie mille.'),
      fakeMessage('m3', BuddyMessageRole.buddy, 'No translation', t0.add(const Duration(minutes: 2))),
    ], hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', chatLanguage: 'it'));
    expect(find.text('Hello friend'), findsOneWidget);
    expect(find.text('hello, friend!'), findsNothing);
    expect(find.text('Grazie mille'), findsOneWidget);
    expect(find.text('Grazie mille.'), findsNothing);
    expect(find.byKey(const ValueKey('buddy-user-translation-m2')), findsNothing);
    expect(find.text('No translation'), findsOneWidget);
    expect(find.byKey(const ValueKey('message-translated-label')), findsNothing);
  });

  testWidgets('chat language = Buddy language (pt / pt_BR): never a translation shown',
      (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Olá, tudo bem?', t0, translation: 'Oi, tudo bom?'),
      fakeMessage('m2', BuddyMessageRole.user, 'Tudo ótimo', t0.add(const Duration(minutes: 1)),
          translation: 'Tudo excelente'),
    ], hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', language: 'pt', chatLanguage: 'pt_BR'));
    expect(find.text('Olá, tudo bem?'), findsOneWidget);
    expect(find.text('Oi, tudo bom?'), findsNothing);
    expect(find.text('Tudo ótimo'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-user-translation-m2')), findsNothing);
    expect(find.byKey(const ValueKey('message-translated-label')), findsNothing);
  });

  testWidgets(
      'a Buddy bubble shows its translation from its first frame; '
      "the user's main text never changes", (tester) async {
    repo.sendAnswers.add(const BuddySendResult(
      reply: 'It is lovely.\nHave you been?',
      replies: ['It is lovely.', 'Have you been?'],
      translations: ['È bellissimo.', 'Ci sei stato?'],
      userTranslation: 'Ciao a tutti',
      kind: 'chat',
      charged: 'free',
      freeRepliesLeft: 4,
    ));
    repo.sendGate = Completer<void>();
    await open(tester, buddy: fakeBuddy('b1', chatLanguage: 'it'));

    void userMainTextUnchanged() {
      expect(find.text('Hello all'), findsOneWidget, reason: 'the original stays the main text');
    }

    await send(tester, 'Hello all');
    userMainTextUnchanged();
    expect(find.text('Ciao a tutti'), findsNothing);

    repo.sendGate!.complete();
    await tester.pump();
    // The first frame the 1st bubble exists in already has its translation.
    expect(find.byKey(const ValueKey('buddy-msg-local_reply_req-1-abcdef_0')), findsOneWidget);
    expect(find.text('È bellissimo.'), findsOneWidget);
    expect(find.text('It is lovely.'), findsOneWidget); // original underneath
    expect(find.text('Have you been?'), findsNothing);
    // The user's translation is a line added under the unchanged text.
    userMainTextUnchanged();
    expect(find.text('Ciao a tutti'), findsOneWidget);

    // 2nd bubble: hidden until revealed, then translated in that same frame.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('buddy-msg-local_reply_req-1-abcdef_1')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('buddy-msg-local_reply_req-1-abcdef_1')), findsOneWidget);
    expect(find.text('Ci sei stato?'), findsOneWidget);

    // The stored docs replace the local copies: same layout, no swap.
    final now = DateTime.now();
    repo.newMessages.add([
      fakeMessage('s0', BuddyMessageRole.user, 'Hello all', now, translation: 'Ciao a tutti'),
      fakeMessage('s1', BuddyMessageRole.buddy, 'It is lovely.', now.add(const Duration(seconds: 1)),
          translation: 'È bellissimo.'),
      fakeMessage('s2', BuddyMessageRole.buddy, 'Have you been?',
          now.add(const Duration(seconds: 2)), translation: 'Ci sei stato?'),
    ]);
    await tester.pump();
    userMainTextUnchanged();
    expect(find.text('Ciao a tutti'), findsOneWidget);
    expect(find.text('È bellissimo.'), findsOneWidget);
    expect(find.text('Ci sei stato?'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  /// The coloured chunks rendered under [of]: text -> background colour.
  Map<String, Color> colouredSpans(WidgetTester tester, Finder of) {
    final out = <String, Color>{};
    for (final r in tester.widgetList<RichText>(find.descendant(of: of, matching: find.byType(RichText)))) {
      r.text.visitChildren((span) {
        final dc = span is TextSpan ? span.style?.decorationColor : null;
        if (span is TextSpan && span.text != null && dc != null &&
            (BuddySegmentPalette.colors.contains(dc) || BuddySegmentPalette.deepColors.contains(dc))) {
          out[span.text!] = span.style!.decorationColor!;
        }
        return true;
      });
    }
    return out;
  }

  List<BuddyMessage> segmentMessages() => [
        fakeMessage('m1', BuddyMessageRole.buddy, 'I love the sea', t0,
            translation: 'Amo il mare',
            segments: const [
              BuddySegment(s: 'I love', t: 'Amo'),
              BuddySegment(s: 'not there', t: 'il'), // invalid: ignored
              BuddySegment(s: 'the sea', t: 'il mare'),
            ]),
        fakeMessage('m2', BuddyMessageRole.user, 'Good morning', t0.add(const Duration(minutes: 1)),
            translation: 'Buongiorno',
            segments: const [BuddySegment(s: 'Good morning', t: 'Buongiorno')]),
      ];

  testWidgets('matching chunks: the same colour for a pair in both texts', (tester) async {
    repo.latest = BuddyMessagePage(messages: segmentMessages(), hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', chatLanguage: 'it'));
    await tester.pump();
    // The Buddy's: translation (main) and original underneath.
    final main = colouredSpans(tester, find.byKey(const ValueKey('buddy-seg-main-m1')));
    final orig = colouredSpans(tester, find.byKey(const ValueKey('buddy-seg-original-m1')));
    expect(main.keys, unorderedEquals(['Amo', 'il mare']));
    expect(orig.keys, unorderedEquals(['I love', 'the sea']));
    expect(main['Amo'], orig['I love']);
    expect(main['il mare'], orig['the sea']);
    expect(main['Amo'], isNot(main['il mare']), reason: 'each pair has its own colour');
    // The invalid segment is ignored: no coloured lone "il".
    expect(main.containsKey('il'), isFalse);
    // Not colour alone: matched chunks are underlined.
    final underlined = <String>[];
    for (final r in tester.widgetList<RichText>(find.descendant(
        of: find.byKey(const ValueKey('buddy-seg-main-m1')), matching: find.byType(RichText)))) {
      r.text.visitChildren((span) {
        if (span is TextSpan && span.style?.decoration == TextDecoration.underline) {
          underlined.add(span.text!);
        }
        return true;
      });
    }
    expect(underlined, unorderedEquals(['Amo', 'il mare']));

    // The user's: original (main) and the translation line, same colour.
    final userMain = colouredSpans(tester, find.byKey(const ValueKey('buddy-seg-main-m2')));
    final userLine =
        colouredSpans(tester, find.byKey(const ValueKey('buddy-user-translation-m2')));
    expect(userMain['Good morning'], isNotNull);
    expect(userLine['Buongiorno'], userMain['Good morning']);

    // Setting on (default): the server is asked for the colour pairs.
    await send(tester, 'Colours please');
    expect(repo.aligns, [true]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('matching chunks: setting off = no colours, texts as before', (tester) async {
    SharedPreferences.setMockInitialValues({'chat_highlightMatches': false});
    repo.latest = BuddyMessagePage(messages: segmentMessages(), hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', chatLanguage: 'it'));
    await tester.pump();
    expect(find.byKey(const ValueKey('buddy-seg-main-m1')), findsNothing);
    expect(find.byKey(const ValueKey('buddy-seg-original-m1')), findsNothing);
    expect(find.byKey(const ValueKey('buddy-seg-main-m2')), findsNothing);
    expect(colouredSpans(tester, find.byKey(const ValueKey('buddy-messages'))), isEmpty);
    expect(find.text('Amo il mare'), findsOneWidget);
    expect(find.text('I love the sea'), findsOneWidget);
    expect(find.text('Good morning'), findsOneWidget);
    // The server is told to skip the colour pairs (align: false).
    await send(tester, 'No colours please');
    expect(repo.aligns, [false]);
    await tester.pump(const Duration(seconds: 1));

    // The toggle is in the chat settings sheet, on by default elsewhere.
    await tester.tap(find.byKey(const ValueKey('buddy-chat-languages')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-chat-settings')));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('buddy-chat-setting-highlightMatches'));
    await tester.ensureVisible(toggle);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.text('Highlight matching words'), findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buddy-seg-main-m1'), skipOffstage: false), findsOneWidget);
  });

  testWidgets('Enter sends the message; Shift+Enter does not', (tester) async {
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Typed on a keyboard');
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(repo.sent, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Typed on a keyboard');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(repo.sent.map((m) => m['text']), ['Typed on a keyboard']);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('buddy-input'))).controller!.text,
        isEmpty);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('languages menu: the chat language is read-only info', (tester) async {
    await open(tester, buddy: fakeBuddy('b1', chatLanguage: 'it'));
    await tester.tap(find.byKey(const ValueKey('buddy-chat-languages')));
    await tester.pumpAndSettle();
    final info = find.byKey(const ValueKey('buddy-chat-language-info'));
    expect(info, findsOneWidget);
    expect(tester.widget<ListTile>(info).onTap, isNull);
    expect(find.text('Translated into: 🇮🇹 Italian (fixed)'), findsOneWidget);
    // No picker any more; the chat settings entry stays.
    await tester.tap(info);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buddy-chat-language-it')), findsNothing);
    expect(find.byKey(const ValueKey('buddy-chat-settings')), findsOneWidget);
  });

  testWidgets('chat settings: the 1:1 chat settings apply (cultural tips off hides places)',
      (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('buddy-chat-languages')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-chat-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('buddy-chat-settings-sheet')), findsOneWidget);
    for (final n in ['showOriginalText', 'showCulturalTips', 'showIcebreakers', 'showPronunciation']) {
      expect(find.byKey(ValueKey('buddy-chat-setting-$n')), findsOneWidget, reason: n);
    }
    expect(find.byKey(const ValueKey('buddy-chat-setting-showGrammarCheck')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buddy-chat-setting-showCulturalTips')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-chat-settings-save-chat')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('chat-places-trip')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('chat_buddy_b1_showCulturalTips'), isFalse);
    expect(prefs.getBool('chat_buddy_b1_hasCustomSettings'), isTrue);
  });

  testWidgets('no coins left -> coin shop prompt; failed message can be retried', (tester) async {
    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'insufficient-coins: x',
        details: const {'reason': 'insufficient-coins'}));
    await open(tester);
    await send(tester, 'Hi');
    expect(prompts.calls, ['coins:1']);
    expect(find.text('Not sent. Tap to try again.'), findsOneWidget);
    expect(prompts.sounds, isEmpty);

    await tester.tap(find.text('Not sent. Tap to try again.'));
    await tester.pump();
    await tester.pump();
    expect(repo.sent.map((s) => s['requestId']).toSet().length, 1);
    expect(find.text('Reply to Hi'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('AI notice required -> consent sheet, then automatic retry', (tester) async {
    repo.sendAnswers
        .add(FirebaseFunctionsException(code: 'permission-denied', message: 'x', details: const {
      'code': 'AI_CONSENT_UPDATE_REQUIRED',
      'details': {'reason': 'AI_CONSENT_UPDATE_REQUIRED'}
    }));
    await open(tester);
    await send(tester, 'Ciao');
    await tester.pump();
    expect(prompts.calls, ['consent:true']);
    expect(repo.sent.length, 2);
    expect(repo.sent[0]['requestId'], repo.sent[1]['requestId']);
    expect(find.text('Reply to Ciao'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('locked Buddy: upgrade banner instead of the input', (tester) async {
    await open(tester, locked: true);
    expect(find.byKey(const ValueKey('buddy-locked-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-input')), findsNothing);
    await tester.tap(find.text('Upgrade'));
    await tester.pump();
    expect(prompts.calls, ['upgrade:1']);
  });

  testWidgets('quick settings: memory list, forget all, tone change', (tester) async {
    await open(tester);
    repo.buddy.add(fakeBuddy('b1',
        memory: const [BuddyMemoryFact(id: 'f1', text: 'Training for a 10k race')]));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('What Sunny remembers'), findsOneWidget);
    expect(find.text('Training for a 10k race'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buddy-setting-tone')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-option-calm')));
    await tester.pumpAndSettle();
    expect(repo.updates.single, {'tone': 'calm'});

    await tester.ensureVisible(find.byKey(const ValueKey('buddy-memory-forget-all')));
    await tester.tap(find.byKey(const ValueKey('buddy-memory-forget-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-confirm')));
    await tester.pumpAndSettle();
    expect(repo.forgotten, [null]);
  });

  testWidgets('quick settings: category, language (fixed), tone, picture, name, check-ins',
      (tester) async {
    await open(tester);
    repo.buddy.add(fakeBuddy('b1', avatar: 'av_fox', chatLanguage: 'it'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-settings-button')));
    await tester.pumpAndSettle();

    for (final k in ['topic', 'language', 'tone', 'avatar', 'name', 'checkins']) {
      expect(find.byKey(ValueKey('buddy-setting-$k')), findsOneWidget, reason: k);
    }
    for (final k in ['role', 'level', 'cefr']) {
      expect(find.byKey(ValueKey('buddy-setting-$k')), findsNothing, reason: k);
    }
    expect(find.text('Category'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-clear-chat'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-delete'), skipOffstage: false), findsOneWidget);
    // The chat language (translation target) is fixed too: read-only info.
    expect(find.byKey(const ValueKey('buddy-setting-chat-language')), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(const ValueKey('buddy-setting-chat-language'))).onTap,
        isNull);
    expect(find.text('Translated into: 🇮🇹 Italian (fixed)'), findsOneWidget);

    // Language: chosen at creation only, never changed (read-only).
    expect(find.text('English (fixed)'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(const ValueKey('buddy-setting-language'))).onTap,
        isNull);

    // Category: searchable combobox in a dialog.
    await tester.tap(find.byKey(const ValueKey('buddy-setting-topic')));
    await tester.pumpAndSettle();
    final field = find.descendant(
        of: find.byKey(const ValueKey('buddy-category')), matching: find.byType(TextField));
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, 'guit');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'Guitar').hitTestable().first);
    await tester.pumpAndSettle();
    expect(repo.updates.last, {'topic': 'guitar'});

    // Picture: grid of buddy_avatars pictures.
    await tester.tap(find.byKey(const ValueKey('buddy-setting-avatar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-avatar-av_cat')));
    await tester.pumpAndSettle();
    expect(repo.updates.last, {'avatar': 'av_cat'});

    // Name: validated like the server.
    await tester.tap(find.byKey(const ValueKey('buddy-setting-name')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('buddy-rename-field')), 'Bad!');
    await tester.pump();
    expect(tester.widget<TextButton>(find.byKey(const ValueKey('buddy-rename-save'))).onPressed,
        isNull);
    await tester.enterText(find.byKey(const ValueKey('buddy-rename-field')), ' Nova  Star ');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-rename-save')));
    await tester.pumpAndSettle();
    expect(repo.updates.last, {'name': 'Nova Star'});
    expect(repo.updates.any((u) => u.containsKey('language')), isFalse);
    expect(repo.avatarReads, 1, reason: 'pictures read once, then cached');
  });

  testWidgets('picture avatar in the header; tapping it opens no profile', (tester) async {
    final observer = _PushCounter();
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Hi there', t0),
    ], hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', avatar: 'av_owl'), observer: observer);
    await tester.pump();
    final images = find.byKey(const ValueKey('buddy-avatar-image-https://img.test/owl.png'));
    expect(images, findsOneWidget, reason: 'header (bubbles look like the 1:1 chat)');
    final pushes = observer.pushes;
    await tester.tap(images.first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(observer.pushes, pushes, reason: 'Buddies have no profile page');
  });

  testWidgets('paid replies: "1 coin = 3 replies" from the status (no free replies), prepaid replies',
      (tester) async {
    repo.status = const BuddyStatus(
        tier: 'FREE',
        buddyLimit: 1,
        buddyCount: 1,
        freeRepliesPerDay: 10,
        freeRepliesLeft: 0,
        coinsPerReply: 0.33,
        repliesPerCoin: 3,
        replyCredits: 2);
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'Sure!', kind: 'chat', charged: 'credit', freeRepliesLeft: 0, replyCredits: 1));
    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'insufficient-coins: x',
        details: const {'reason': 'insufficient-coins'}));
    await open(tester);
    expect(find.text('1 coin = 3 replies · 2 prepaid replies'),
        findsOneWidget);

    await send(tester, 'Hello');
    expect(find.textContaining('1 prepaid reply'), findsOneWidget);

    await send(tester, 'Again');
    expect(prompts.calls, ['coins:1/3']);
    await tester.pump(const Duration(seconds: 1));
  });
}

class _PushCounter extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}
