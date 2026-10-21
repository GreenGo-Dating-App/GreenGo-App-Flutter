import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:greengo_chat/features/communities/data/services/community_tip_translator.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_message.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Owner request 2026-10-21: tips are shown in the viewer's language,
/// translated ONCE (shared server store) and cached in the app, with
/// "Show original".
void main() {
  CommunityMessage tip(String id, String content,
          {CommunityMessageType type = CommunityMessageType.languageTip,
          String sender = 'other'}) =>
      CommunityMessage(
        id: id,
        communityId: 'c1',
        senderId: sender,
        senderName: 'Other',
        content: content,
        sentAt: DateTime(2026, 10, 21, 12),
        type: type,
      );

  /// Fake server: translates by prefixing "IT:"; records every call.
  late List<List<String>> serverCalls;
  late List<String> sharedReads;
  late Map<String, String> sharedStore; // translations/{id}
  late Map<String, String> serverTexts; // messageId -> content on server

  CommunityTipTranslator translator(TipTranslationStore store) =>
      CommunityTipTranslator(
        store: store,
        readShared: (id) async {
          sharedReads.add(id);
          return sharedStore[id];
        },
        callServer: (communityId, ids, target) async {
          serverCalls.add(ids);
          return [
            for (final id in ids)
              if (serverTexts.containsKey(id))
                {
                  'messageId': id,
                  'hash': CommunityTipTranslator.contentHash(serverTexts[id]!),
                  'text': serverTexts[id]!.startsWith('Ciao')
                      ? serverTexts[id]!
                      : 'IT:${serverTexts[id]}',
                  'sameLanguage': serverTexts[id]!.startsWith('Ciao'),
                }
              else
                null,
          ];
        },
      );

  setUp(() {
    serverCalls = [];
    sharedReads = [];
    sharedStore = {};
    serverTexts = {};
  });

  Widget app(Widget child) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('a tip by someone else shows the translation + Show original',
      (tester) async {
    serverTexts['t1'] = 'Say thank you';
    final tr = translator(MemoryTipTranslationStore());
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: tip('t1', 'Say thank you'),
      isCurrentUser: false,
      currentUserLanguage: 'it',
      tipTranslator: tr,
    )));
    await tester.pumpAndSettle();

    expect(find.text('IT:Say thank you'), findsOneWidget);
    expect(find.text('Show original'), findsOneWidget);
    expect(serverCalls, [
      ['t1']
    ]);

    await tester.tap(find.text('Show original'));
    await tester.pump();
    expect(find.text('Say thank you'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);

    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(find.text('IT:Say thank you'), findsOneWidget);
    expect(serverCalls, hasLength(1), reason: 'toggling never refetches');
  });

  testWidgets('a tip already in the viewer language shows no toggle',
      (tester) async {
    serverTexts['t1'] = 'Ciao a tutti';
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: tip('t1', 'Ciao a tutti', type: CommunityMessageType.otherTip),
      isCurrentUser: false,
      currentUserLanguage: 'it',
      tipTranslator: translator(MemoryTipTranslationStore()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ciao a tutti'), findsOneWidget);
    expect(find.text('Show original'), findsNothing);
    expect(find.text('Translate'), findsNothing);
  });

  testWidgets('own tips are not auto-translated', (tester) async {
    serverTexts['t1'] = 'My tip';
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: tip('t1', 'My tip', sender: 'me'),
      isCurrentUser: true,
      currentUserLanguage: 'it',
      tipTranslator: translator(MemoryTipTranslationStore()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('My tip'), findsOneWidget);
    expect(serverCalls, isEmpty);
    expect(sharedReads, isEmpty);
  });

  testWidgets('server unavailable: original + on-demand Translate fallback',
      (tester) async {
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: tip('t1', 'Untranslatable now'),
      isCurrentUser: false,
      currentUserLanguage: 'it',
      tipTranslator: translator(MemoryTipTranslationStore()),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Untranslatable now'), findsOneWidget);
    expect(find.text('Translate'), findsOneWidget);
  });

  testWidgets('the device cache prevents a second request (app restart)',
      (tester) async {
    serverTexts['t1'] = 'Bring cash';
    final store = MemoryTipTranslationStore(); // persists like the Hive box
    await tester.pumpWidget(app(CommunityMessageBubble(
      message: tip('t1', 'Bring cash', type: CommunityMessageType.cityTip),
      isCurrentUser: false,
      currentUserLanguage: 'it',
      tipTranslator: translator(store),
    )));
    await tester.pumpAndSettle();
    expect(serverCalls, hasLength(1));

    // A NEW translator (fresh memory, same device store) = app restart.
    await tester.pumpWidget(app(CommunityMessageBubble(
      key: const ValueKey('again'),
      message: tip('t1', 'Bring cash', type: CommunityMessageType.cityTip),
      isCurrentUser: false,
      currentUserLanguage: 'it',
      tipTranslator: translator(store),
    )));
    await tester.pumpAndSettle();
    expect(find.text('IT:Bring cash'), findsOneWidget);
    expect(serverCalls, hasLength(1), reason: 'served from the device cache');
    expect(sharedReads, hasLength(1), reason: 'no Firestore read either');
  });

  group('CommunityTipTranslator', () {
    test('a stored shared translation is used without the callable', () async {
      sharedStore[TranslationService.sharedTranslationId('it', 'Hello')] =
          'Ciao!';
      final tr = translator(MemoryTipTranslationStore());
      final r = await tr.translate(tip('t1', 'Hello'), 'it');
      expect(r!.text, 'Ciao!');
      expect(r.sameLanguage, isFalse);
      expect(serverCalls, isEmpty);
    });

    test('one visible page is batched: <= 30 ids per call, in-flight deduped',
        () async {
      for (var i = 0; i < 35; i++) {
        serverTexts['t$i'] = 'tip $i';
      }
      final tr = translator(MemoryTipTranslationStore());
      final futures = [
        for (var i = 0; i < 35; i++) tr.translate(tip('t$i', 'tip $i'), 'it'),
        tr.translate(tip('t0', 'tip 0'), 'it'), // same tip again
      ];
      final out = await Future.wait(futures);
      expect(out.every((r) => r != null), isTrue);
      expect(serverCalls.map((c) => c.length).toList(), [30, 5]);
      expect(serverCalls.expand((c) => c).toSet().length, 35);
      expect(identical(futures.first, futures.last), isTrue);
    });

    test('an edited tip (new content hash) is translated again', () async {
      serverTexts['t1'] = 'Old text';
      final tr = translator(MemoryTipTranslationStore());
      expect((await tr.translate(tip('t1', 'Old text'), 'it'))!.text,
          'IT:Old text');
      expect((await tr.translate(tip('t1', 'Old text'), 'it'))!.text,
          'IT:Old text');
      expect(serverCalls, hasLength(1));
      serverTexts['t1'] = 'New text';
      expect((await tr.translate(tip('t1', 'New text'), 'it'))!.text,
          'IT:New text');
      expect(serverCalls, hasLength(2));
    });

    test('a different viewer language is a separate entry', () async {
      serverTexts['t1'] = 'Hello';
      final tr = translator(MemoryTipTranslationStore());
      await tr.translate(tip('t1', 'Hello'), 'it');
      await tr.translate(tip('t1', 'Hello'), 'Italian'); // normalised to it
      expect(serverCalls, hasLength(1));
      await tr.translate(tip('t1', 'Hello'), 'de');
      expect(serverCalls, hasLength(2));
    });

    test('chat messages are never sent', () async {
      final tr = translator(MemoryTipTranslationStore());
      final chat = CommunityMessage(
        id: 'c',
        communityId: 'c1',
        senderId: 'o',
        senderName: 'O',
        content: 'private-ish chat',
        sentAt: DateTime(2026),
      );
      expect(await tr.translate(chat, 'it'), isNull);
      expect(serverCalls, isEmpty);
      expect(sharedReads, isEmpty);
    });
  });
}
