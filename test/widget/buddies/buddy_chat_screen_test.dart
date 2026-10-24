import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/app_sound_service.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_message.dart';
import 'package:greengo_chat/features/buddies/domain/entities/buddy_status.dart';
import 'package:greengo_chat/features/buddies/presentation/screens/buddy_chat_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/buddies_fakes.dart';

void main() {
  late FakeBuddiesRepository repo;
  late FakeBuddyPrompts prompts;
  final t0 = DateTime(2026, 10, 20, 9);

  setUp(() {
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

  testWidgets('header, AI notice, check-in mark, quota line, 500-char counter', (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'How was your day?', t0,
          kind: BuddyMessageKind.checkin),
    ], hasMore: false);
    await open(tester);

    expect(find.text('Sunny'), findsOneWidget);
    expect(find.text('Films'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-ai-badge')), findsWidgets);
    expect(find.byKey(const ValueKey('buddy-ai-disclosure')), findsOneWidget);
    expect(find.text('How was your day?'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-msg-mark-checkin')), findsOneWidget);
    expect(find.text('7 free replies left today · then 1 coin per reply'), findsOneWidget);
    expect(find.text('0/500'), findsOneWidget);
    expect(find.byKey(const ValueKey('buddy-tone-warm')), findsNothing);
  });

  testWidgets('send: typing indicator, reply, sounds only after success', (tester) async {
    await open(tester);
    repo.sendGate = Completer<void>();
    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Hello there');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
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
  });

  testWidgets('no coins left -> coin shop prompt; failed message can be retried', (tester) async {
    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'insufficient-coins: x',
        details: const {'reason': 'insufficient-coins'}));
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Hi');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
    expect(prompts.calls, ['coins:1']);
    expect(find.text('Not sent. Tap to try again.'), findsOneWidget);
    expect(prompts.sounds, isEmpty);

    await tester.tap(find.text('Not sent. Tap to try again.'));
    await tester.pump();
    await tester.pump();
    expect(repo.sent.map((s) => s['requestId']).toSet().length, 1);
    expect(find.text('Reply to Hi'), findsOneWidget);
  });

  testWidgets('AI notice required -> consent sheet, then automatic retry', (tester) async {
    repo.sendAnswers
        .add(FirebaseFunctionsException(code: 'permission-denied', message: 'x', details: const {
      'code': 'AI_CONSENT_UPDATE_REQUIRED',
      'details': {'reason': 'AI_CONSENT_UPDATE_REQUIRED'}
    }));
    await open(tester);
    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Ciao');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(prompts.calls, ['consent:true']);
    expect(repo.sent.length, 2);
    expect(repo.sent[0]['requestId'], repo.sent[1]['requestId']);
    expect(find.text('Reply to Ciao'), findsOneWidget);
  });

  testWidgets('translate and report on Buddy messages', (tester) async {
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Good morning', t0),
      fakeMessage('m2', BuddyMessageRole.user, 'Morning!', t0.add(const Duration(minutes: 1))),
    ], hasMore: false);
    await open(tester);
    expect(find.byKey(const ValueKey('buddy-translate-m2')), findsNothing,
        reason: 'not on my messages');

    await tester.tap(find.byKey(const ValueKey('buddy-translate-m1')));
    await tester.pump();
    await tester.pump();
    expect(find.text('Traduzione'), findsOneWidget);
    expect(find.text('Show original'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('buddy-translate-m1')));
    await tester.pump();
    expect(find.text('Good morning'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('buddy-report-m1')));
    await tester.pump();
    expect(prompts.calls, ['translate:en', 'report:m1']);
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

  testWidgets('quick settings: only category, language, tone, picture, name, check-ins',
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
    expect(repo.avatarReads, 1, reason: 'pictures read once, then cached');
  });

  testWidgets('picture avatar in header and bubbles; tapping it opens no profile', (tester) async {
    final observer = _PushCounter();
    repo.latest = BuddyMessagePage(messages: [
      fakeMessage('m1', BuddyMessageRole.buddy, 'Hi there', t0),
    ], hasMore: false);
    await open(tester, buddy: fakeBuddy('b1', avatar: 'av_owl'), observer: observer);
    await tester.pump();
    final images = find.byKey(const ValueKey('buddy-avatar-image-https://img.test/owl.png'));
    expect(images, findsNWidgets(2), reason: 'header + bubble');
    final pushes = observer.pushes;
    await tester.tap(images.first, warnIfMissed: false);
    await tester.tap(images.last, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(observer.pushes, pushes, reason: 'Buddies have no profile page');
  });

  testWidgets('paid replies: 0.2 coins per reply, prepaid replies, bundle coin prompt',
      (tester) async {
    repo.status = const BuddyStatus(
        tier: 'FREE',
        buddyLimit: 1,
        buddyCount: 1,
        freeRepliesPerDay: 10,
        freeRepliesLeft: 0,
        coinsPerReply: 0.2,
        repliesPerCoin: 5,
        replyCredits: 4);
    repo.sendAnswers.add(const BuddySendResult(
        reply: 'Sure!', kind: 'chat', charged: 'credit', freeRepliesLeft: 0, replyCredits: 3));
    repo.sendAnswers.add(FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'insufficient-coins: x',
        details: const {'reason': 'insufficient-coins'}));
    await open(tester);
    expect(
        find.text('No free replies left today · then 0.2 coins per reply (1 coin = 5 replies)'
            ' · 4 prepaid replies'),
        findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Hello');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('3 prepaid replies'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('buddy-input')), 'Again');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('buddy-send')));
    await tester.pump();
    await tester.pump();
    expect(prompts.calls, ['coins:1/5']);
  });
}

class _PushCounter extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}
