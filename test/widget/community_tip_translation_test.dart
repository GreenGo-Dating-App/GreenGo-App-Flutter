import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/ai_consent_service.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:greengo_chat/features/communities/data/services/community_tip_translator.dart';
import 'package:greengo_chat/features/communities/domain/entities/community_message.dart';
import 'package:greengo_chat/features/communities/presentation/widgets/community_message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Owner request 2026-10-21: tips are shown in the viewer's language,
/// translated ONCE (shared server store) and cached in the app, with
/// "Show original".
class _MemConsentStore implements AiConsentStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

/// A signed-in user's AI consent with an in-memory store, a fake server
/// recorder and a server record of [server] (null = never decided).
AiConsentService consentService({bool? server}) => AiConsentService(
      store: _MemConsentStore(),
      recorder: ({required bool accepted, required int version}) async {},
      currentUid: () => 'viewer',
      serverReader: (_) async => server,
    );

void main() {
  late AiConsentService granted;

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

  setUp(() async {
    granted = consentService();
    await granted.setDecision(accepted: true);
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
      aiConsent: granted,
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
      aiConsent: granted,
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
      aiConsent: granted,
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
      aiConsent: granted,
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
      aiConsent: granted,
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
      aiConsent: granted,
    )));
    await tester.pumpAndSettle();
    expect(find.text('IT:Bring cash'), findsOneWidget);
    expect(serverCalls, hasLength(1), reason: 'served from the device cache');
    expect(sharedReads, hasLength(1), reason: 'no Firestore read either');
  });

  group('consent (Apple 5.1.2(i))', () {
    Widget twoTips(CommunityTipTranslator tr, AiConsentService c) => app(Column(
          children: [
            CommunityMessageBubble(
              message: tip('t1', 'Say thank you'),
              isCurrentUser: false,
              currentUserLanguage: 'it',
              tipTranslator: tr,
              aiConsent: c,
            ),
            CommunityMessageBubble(
              message: tip('t2', 'Bring cash', type: CommunityMessageType.cityTip),
              isCurrentUser: false,
              currentUserLanguage: 'it',
              tipTranslator: tr,
              aiConsent: c,
            ),
          ],
        ));

    Future<void> tapSheet(WidgetTester tester, String key) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    testWidgets('undecided: ONE consent sheet for the whole page; nothing is '
        'sent before Allow; Allow translates every tip', (tester) async {
      serverTexts['t1'] = 'Say thank you';
      serverTexts['t2'] = 'Bring cash';
      final c = consentService();
      await tester.pumpWidget(twoTips(translator(MemoryTipTranslationStore()), c));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('aiConsentAccept')), findsOneWidget);
      expect(serverCalls, isEmpty);
      expect(sharedReads, isEmpty);
      expect(find.text('Say thank you'), findsOneWidget);

      await tapSheet(tester, 'aiConsentAccept');
      expect(c.status, AiConsentStatus.granted);
      expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
      expect(find.text('IT:Say thank you'), findsOneWidget);
      expect(find.text('IT:Bring cash'), findsOneWidget);
    });

    testWidgets('declined: originals, nothing sent, Translate asks again',
        (tester) async {
      serverTexts['t1'] = 'Say thank you';
      serverTexts['t2'] = 'Bring cash';
      final c = consentService();
      await c.setDecision(accepted: false);
      await tester.pumpWidget(twoTips(translator(MemoryTipTranslationStore()), c));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('aiConsentAccept')), findsNothing,
          reason: 'a decided account is never prompted automatically');
      expect(find.text('Say thank you'), findsOneWidget);
      expect(find.text('Bring cash'), findsOneWidget);
      expect(find.text('Translate'), findsNWidgets(2));
      expect(serverCalls, isEmpty);
      expect(sharedReads, isEmpty);

      await tester.tap(find.text('Translate').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentAccept')), findsOneWidget,
          reason: 'the tap asks again');
      await tapSheet(tester, 'aiConsentAccept');
      expect(c.status, AiConsentStatus.granted);
      expect(find.text('IT:Say thank you'), findsOneWidget);
      // Granting is account-wide: the other tip translates too.
      expect(find.text('IT:Bring cash'), findsOneWidget);
    });

    testWidgets('dismissed without choosing: not asked again this session',
        (tester) async {
      serverTexts['t1'] = 'Say thank you';
      final c = consentService();
      final tr = translator(MemoryTipTranslationStore());
      await tester.pumpWidget(twoTips(tr, c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentAccept')), findsOneWidget);
      await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentAccept')), findsNothing);

      // The screen is opened again: no new sheet, originals + Translate.
      await tester.pumpWidget(app(const SizedBox()));
      await tester.pumpWidget(twoTips(tr, c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
      expect(find.text('Translate'), findsNWidgets(2));
      expect(serverCalls, isEmpty);
    });

    testWidgets('decided on another device: the server record is used, no sheet',
        (tester) async {
      serverTexts['t1'] = 'Say thank you';
      serverTexts['t2'] = 'Bring cash';
      final c = consentService(server: true);
      await tester.pumpWidget(twoTips(translator(MemoryTipTranslationStore()), c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
      expect(find.text('IT:Say thank you'), findsOneWidget);
    });
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

    test('server says AI_CONSENT_REQUIRED: consent re-sent, retried once',
        () async {
      var calls = 0;
      var resyncs = 0;
      final tr = CommunityTipTranslator(
        store: MemoryTipTranslationStore(),
        readShared: (_) async => null,
        callServer: (cid, ids, target) async {
          calls++;
          if (calls == 1) {
            throw FirebaseFunctionsException(
                message: 'consent',
                code: 'failed-precondition',
                details: {'code': 'AI_CONSENT_REQUIRED'});
          }
          return [
            {'messageId': 't1', 'hash': 'h', 'text': 'IT:Hi', 'sameLanguage': false}
          ];
        },
        onConsentRequired: () async {
          resyncs++;
          return true;
        },
      );
      final r = await tr.translate(tip('t1', 'Hi'), 'it');
      expect(r!.text, 'IT:Hi');
      expect(calls, 2);
      expect(resyncs, 1);
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
