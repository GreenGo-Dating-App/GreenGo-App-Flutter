import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('automatic translation into the chat language, like the 1:1 chat', (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Good morning', t0),
      fakeMessage('m2', BuddyMessageRole.user, 'Morning!', t0.add(const Duration(minutes: 1))),
    ], hasMore: false);
    prompts.translation = 'IT';
    await open(tester);
    // App language = English = the Buddy's: nothing to show yet.
    expect(prompts.translated, containsAll(['en>en:Good morning', 'auto>en:Morning!']));

    // Chat language -> Italian: ALL messages are translated (same service).
    await tester.tap(find.byKey(const ValueKey('buddy-chat-languages')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-chat-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buddy-chat-language-it')));
    await tester.pumpAndSettle();
    expect(prompts.translated, containsAll(['en>it:Good morning', 'auto>it:Morning!']));
    expect(find.text('IT: Good morning'), findsOneWidget);
    expect(find.text('IT: Morning!'), findsOneWidget);
    // Original underneath (Show original text setting) + "Translated" mark.
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.byKey(const ValueKey('message-translated-label')), findsNWidgets(2));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('chat_buddy_b1_language'), 'it');

    // Report stays on the Buddy's messages.
    await tester.pump(const Duration(seconds: 2)); // "Language set to" snackbar
    expect(find.byKey(const ValueKey('buddy-report-m2')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('buddy-report-m1')));
    await tester.pump();
    expect(prompts.calls, ['report:m1']);
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

  testWidgets('translation failure: snackbar once, original shown', (tester) async {
    repo.latest = BuddyMessagePage(
        messages: [fakeMessage('m1', BuddyMessageRole.buddy, 'Hi', t0)], hasMore: false);
    prompts.translateFails = true;
    await open(tester);
    await tester.pump();
    expect(find.text('Hi'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
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
    repo.buddy.add(fakeBuddy('b1', avatar: 'av_fox'));
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
    expect(find.byKey(const ValueKey('buddy-clear-chat')), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-delete')), findsOneWidget);

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

  testWidgets('paid replies: "then 1 coin = 3 replies" from the status, prepaid replies',
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
    expect(find.text('No free replies left today · then 1 coin = 3 replies · 2 prepaid replies'),
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
