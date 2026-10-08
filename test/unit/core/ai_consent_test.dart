import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/ai_consent_service.dart';
import 'package:greengo_chat/core/services/chat_learning_service.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:greengo_chat/core/widgets/ai_consent_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemStore implements AiConsentStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

class FakeRecorder {
  final List<bool> sent = [];
  bool fail = false;
  Future<void> call({required bool accepted, required int version}) async {
    if (fail) throw Exception('offline');
    sent.add(accepted);
  }
}

AiConsentService svc(MemStore store, FakeRecorder rec, String? Function() uid) =>
    AiConsentService(store: store, recorder: rec.call, currentUid: uid);

FirebaseFunctionsException consentRequiredError() => FirebaseFunctionsException(
      message: 'Please review and accept the AI processing notice first.',
      code: 'permission-denied',
      details: {'code': 'AI_CONSENT_REQUIRED'},
    );

void main() {
  group('AiConsentService', () {
    test('unknown until decided; decision stored locally and on the server', () async {
      final store = MemStore(), rec = FakeRecorder();
      final s = svc(store, rec, () => 'u1');
      await s.ensureLoaded();
      expect(s.status, AiConsentStatus.unknown);
      expect(s.isGranted, isFalse);

      await s.setDecision(accepted: true);
      expect(s.status, AiConsentStatus.granted);
      expect(rec.sent, [true]);

      // A fresh instance (app restart) reads it back, without re-sending.
      final again = svc(store, rec, () => 'u1');
      await again.load();
      expect(again.status, AiConsentStatus.granted);
      expect(rec.sent, [true]);
    });

    test('decline is remembered and is not "granted"', () async {
      final s = svc(MemStore(), FakeRecorder(), () => 'u1');
      await s.setDecision(accepted: false);
      expect(s.status, AiConsentStatus.declined);
      expect(s.isGranted, isFalse);
    });

    test('per signed-in user: another account on the device starts unknown', () async {
      var uid = 'u1';
      final store = MemStore();
      final s = svc(store, FakeRecorder(), () => uid);
      await s.setDecision(accepted: true);
      uid = 'u2';
      expect(s.status, AiConsentStatus.unknown);
      await s.ensureLoaded();
      expect(s.status, AiConsentStatus.unknown);
      expect(s.promptedThisSession, isFalse);
    });

    test('signed out = unknown, and no decision can be recorded', () async {
      final rec = FakeRecorder();
      final s = svc(MemStore(), rec, () => null);
      expect(await s.setDecision(accepted: true), isFalse);
      expect(s.status, AiConsentStatus.unknown);
      expect(rec.sent, isEmpty);
    });

    test('failed server send is kept locally and retried on the next load', () async {
      final store = MemStore(), rec = FakeRecorder()..fail = true;
      final s = svc(store, rec, () => 'u1');
      expect(await s.setDecision(accepted: true), isFalse);
      expect(s.isGranted, isTrue); // the user's choice applies immediately
      expect(s.pendingSync, isTrue);

      rec.fail = false;
      final restarted = svc(store, rec, () => 'u1');
      await restarted.load();
      await Future<void>.delayed(Duration.zero);
      expect(rec.sent, [true]);
      expect(restarted.pendingSync, isFalse);
    });

    test('a decision for an older consent version asks again', () async {
      final store = MemStore()..data['ai_consent_u1'] = '{"v":0,"a":true,"s":true}';
      final s = svc(store, FakeRecorder(), () => 'u1');
      await s.load();
      expect(s.status, AiConsentStatus.unknown);
    });

    test('listeners hear the decision', () async {
      final s = svc(MemStore(), FakeRecorder(), () => 'u1');
      final seen = <AiConsentStatus>[];
      s.statusListenable.addListener(() => seen.add(s.statusListenable.value));
      await s.setDecision(accepted: true);
      expect(seen, [AiConsentStatus.granted]);
    });

    test('isAiConsentRequiredError', () {
      expect(isAiConsentRequiredError(consentRequiredError()), isTrue);
      expect(
          isAiConsentRequiredError(FirebaseFunctionsException(message: 'x', code: 'internal')),
          isFalse);
      expect(isAiConsentRequiredError(Exception('x')), isFalse);
    });
  });

  group('ChatLearningService consent gate', () {
    test('without consent nothing is sent to the server', () async {
      final calls = <Map<String, dynamic>>[];
      final s = svc(MemStore(), FakeRecorder(), () => 'u1');
      final learning = ChatLearningService.test(
        call: (p) async {
          calls.add(p);
          return {'replies': ['a']};
        },
        consent: s,
      );
      expect(await learning.getSmartReplies('Oi, tudo bem?', 'pt', 'en'), isEmpty);
      expect(await learning.checkGrammar('Hello there friend', 'en'), isNull);
      expect(await learning.getMessageDifficulty('Hello', 'en'), 'A1');
      await s.setDecision(accepted: false);
      expect(await learning.getWordBreakdown('Hello', 'en', 'pt'), isEmpty);
      expect(calls, isEmpty);
    });

    test('with consent: task + text + languages only', () async {
      final calls = <Map<String, dynamic>>[];
      final s = svc(MemStore(), FakeRecorder(), () => 'u1');
      await s.setDecision(accepted: true);
      final learning = ChatLearningService.test(
        call: (p) async {
          calls.add(p);
          return {'replies': ['Oi!', 'Tudo'], 'translations': ['Hi!', 'All']};
        },
        consent: s,
      );
      expect(await learning.getSmartReplies('Bom dia', 'pt', 'en'), ['Oi!', 'Tudo']);
      expect(learning.getSmartReplyTranslations('Bom dia', 'pt'), ['Hi!', 'All']);
      expect(calls.single, {
        'task': 'smartReplies',
        'text': 'Bom dia',
        'language': 'pt',
        'targetLanguage': 'pt',
        'userLanguage': 'en',
      });
      // Cached: no second call.
      await learning.getSmartReplies('Bom dia', 'pt', 'en');
      expect(calls, hasLength(1));
    });

    test('text over the server cap is not sent', () async {
      var n = 0;
      final s = svc(MemStore(), FakeRecorder(), () => 'u1');
      await s.setDecision(accepted: true);
      final learning = ChatLearningService.test(call: (p) async { n++; return null; }, consent: s);
      expect(await learning.checkGrammar('x' * 1001, 'en'), isNull);
      expect(n, 0);
    });

    test('server says AI_CONSENT_REQUIRED: consent re-sent, request retried once', () async {
      final rec = FakeRecorder();
      final s = svc(MemStore(), rec, () => 'u1');
      await s.setDecision(accepted: true);
      var n = 0;
      final learning = ChatLearningService.test(
        call: (p) async {
          n++;
          if (n == 1) throw consentRequiredError();
          return {'level': 'B2'};
        },
        consent: s,
      );
      expect(await learning.getMessageDifficulty('Hello', 'en'), 'B2');
      expect(n, 2);
      expect(rec.sent, [true, true]);
    });
  });

  group('TranslationService consent gate', () {
    MockClient endpoint(List<http.Request> log) => MockClient((req) async {
          log.add(req);
          return http.Response('[[["Ciao","Hello",null,null,10]],null,"en"]', 200);
        });

    test('private text without consent: nothing sent, consentRequired (not cached)', () async {
      final log = <http.Request>[];
      var granted = false;
      final t = TranslationService.test(client: endpoint(log), consentGranted: () => granted);
      final r = await t.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(r.consentRequired, isTrue);
      expect(r.failed, isTrue);
      expect(r.text, 'Hello');
      expect(log, isEmpty);

      granted = true; // user accepted: the same text now translates
      final r2 = await t.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(r2.text, 'Ciao');
      expect(r2.consentRequired, isFalse);
      expect(log, hasLength(1));
    });

    test('public content (requiresConsent: false) still translates', () async {
      final log = <http.Request>[];
      final t = TranslationService.test(client: endpoint(log), consentGranted: () => false);
      final r = await t.translateDetailed(
          text: 'Hello', targetLanguage: 'it', requiresConsent: false);
      expect(r.text, 'Ciao');
    });

    test('server flag on: private text goes to translatePrivateText, not the free endpoint', () async {
      final log = <http.Request>[];
      final payloads = <Map<String, dynamic>>[];
      final t = TranslationService.test(
        client: endpoint(log),
        useServer: () async => true,
        serverCall: (p) async {
          payloads.add(p);
          return {
            'translations': [
              {'text': 'Olá', 'detectedLanguage': 'en', 'sameLanguage': false}
            ]
          };
        },
      );
      final r = await t.translateDetailed(text: 'Hello', targetLanguage: 'pt_BR');
      expect(r.text, 'Olá');
      expect(r.detectedLanguage, 'en');
      expect(payloads.single, {'texts': ['Hello'], 'target': 'pt-BR'});
      expect(log, isEmpty);
    });
  });

  group('consent sheet', () {
    Future<void> pump(WidgetTester tester, AiConsentService s, ValueChanged<bool> onResult) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(await AiConsentGate.ensure(context, service: s)),
              child: const Text('go'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('names Google services; Allow grants', (tester) async {
      final rec = FakeRecorder();
      final s = svc(MemStore(), rec, () => 'u1');
      bool? result;
      await pump(tester, s, (r) => result = r);
      expect(find.textContaining('Google Gemini'), findsOneWidget);
      await tester.tap(find.byKey(const Key('aiConsentAccept')));
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(s.status, AiConsentStatus.granted);
      expect(rec.sent, [true]);
    });

    testWidgets('Decline disables; the next use explains instead of running', (tester) async {
      final s = svc(MemStore(), FakeRecorder(), () => 'u1');
      bool? result;
      await pump(tester, s, (r) => result = r);
      await tester.tap(find.byKey(const Key('aiConsentDecline')));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(s.status, AiConsentStatus.declined);

      await tester.tap(find.text('go'));
      await tester.pump();
      expect(result, isFalse);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byKey(const Key('aiConsentAccept')), findsNothing);
    });
  });
}
