import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_phrasebook.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:http/testing.dart';

/// The bundled phrasebook, read from the asset file itself.
final String phrasebookJson =
    File('assets/i18n/chat_phrasebook.json').readAsStringSync();

/// The free endpoint must never be hit by private chat text.
final MockClient noHttp = MockClient((req) async {
  fail('unexpected HTTP request: ${req.url}');
});

class FakeServer {
  final List<Map<String, dynamic>> calls = [];

  /// messageId -> answer item (`text`, `detectedLanguage`, `sameLanguage`,
  /// `layer`, or `error`).
  final Map<String, Map<String, dynamic>> byId = {};

  /// text -> translation for the old single-text payload.
  final Map<String, String> byText = {};
  bool batchThrows = false;

  Future<Map<String, dynamic>> call(Map<String, dynamic> payload) async {
    calls.add(payload);
    if (payload['messages'] != null) {
      if (batchThrows) throw Exception('INVALID_ARGUMENT texts is required');
      return {
        'translations': [
          for (final m in payload['messages'] as List)
            {'messageId': m['messageId'], ...?byId[m['messageId']]}
        ],
      };
    }
    final text = (payload['texts'] as List).single as String;
    return {
      'translations': [
        {'text': byText[text] ?? text, 'detectedLanguage': 'en'}
      ],
    };
  }

  List<Map<String, dynamic>> get batchCalls =>
      calls.where((c) => c['messages'] != null).toList();
  List<Map<String, dynamic>> get textCalls =>
      calls.where((c) => c['texts'] != null).toList();
}

TranslationService service(FakeServer server, {bool consent = true}) =>
    TranslationService.test(
      client: noHttp,
      consentGranted: () => consent,
      useServer: () async => true,
      serverCall: server.call,
      phrasebookJson: phrasebookJson,
    );

ChatMessageRef ref(
  String id, {
  String? lang,
  Map<String, String>? tr,
  String? trFor,
}) =>
    ChatMessageRef(
      kind: ChatMessageRef.conversation,
      parentId: 'c1',
      messageId: id,
      lang: lang,
      tr: tr,
      trHash: trFor == null ? null : TranslationService.messageTextHash(trFor),
    );

void main() {
  group('needsTranslation (skip filter)', () {
    test('nothing to translate', () {
      for (final t in [
        '😀😂👍',
        '12345',
        '!!! ???',
        'https://greengochat.com/app',
        'www.example.com/page',
        'a',
        'a 😀 1',
        '+55 11 99999-0000',
      ]) {
        expect(TranslationService.needsTranslation(t), isFalse, reason: t);
      }
    });

    test('text with at least two letters', () {
      for (final t in [
        'hi',
        'Ok 👍',
        'see https://x.y/z tomorrow',
        'Olá',
        '你好',
      ]) {
        expect(TranslationService.needsTranslation(t), isTrue, reason: t);
      }
    });
  });

  group('ChatPhrasebook', () {
    final book = ChatPhrasebook.fromJson(phrasebookJson);

    test('the asset is well formed: every entry has all 7 languages', () {
      final decoded = jsonDecode(phrasebookJson) as Map<String, dynamic>;
      final entries = decoded['entries'] as List;
      expect(entries.length, greaterThanOrEqualTo(60));
      const langs = {'en', 'de', 'es', 'fr', 'it', 'pt', 'pt_BR'};
      for (final e in entries.cast<Map<String, dynamic>>()) {
        expect(e.keys.toSet(), langs, reason: '$e');
        for (final l in langs) {
          final v = (e[l] as List).cast<String>();
          expect(v, isNotEmpty);
          expect(v.first.trim(), isNotEmpty);
        }
      }
    });

    test('translates exact phrases, keeping trailing punctuation / emoji', () {
      expect(book.lookup('Thanks!', 'de')!.text, 'Danke!');
      expect(book.lookup('thank you 😊', 'it')!.text, 'Grazie 😊');
      expect(book.lookup('  HOW   are you? ', 'fr')!.text, 'Comment ça va?');
      expect(
          book.lookup('Where are you from?', 'pt-BR')!.text, 'De onde você é?');
      expect(book.lookup('good morning', 'pt')!.text, 'Bom dia');
      expect(book.lookup('Gracias', 'en')!.source, 'es');
    });

    test('Spanish opening marks follow the closing ones', () {
      expect(book.lookup('How are you?', 'es')!.text, '¿Cómo estás?');
      expect(book.lookup('how are you', 'es')!.text, 'Cómo estás');
      expect(book.lookup('and you?', 'es')!.text, '¿Y tú?');
      expect(book.lookup('and you', 'es')!.text, 'Y tú');
    });

    test('already in the target (base) language: same, untouched', () {
      final r = book.lookup('obrigado!', 'pt-BR')!;
      expect(r.same, isTrue);
      expect(r.text, 'obrigado!');
      expect(book.lookup('ok', 'es')!.same, isTrue);
    });

    test('ambiguous or unknown: no answer (left to the API)', () {
      expect(book.lookup('ciao', 'en'), isNull); // hi or bye
      expect(book.lookup('buenas noches', 'en'), isNull); // evening / night
      expect(book.lookup('thanks for the dinner', 'it'), isNull);
      expect(book.lookup('hello', 'ja'), isNull); // language not covered
      expect(book.lookup('já', 'en'), isNull); // accents are kept: not "ja"
    });
  });

  group('lookup order (chat message)', () {
    test('translation stored on the message: no call, sync and async',
        () async {
      final server = FakeServer();
      final svc = service(server);
      final r = ref('m1',
          lang: 'en', tr: {'it': 'Ciao amico'}, trFor: 'Hello friend');
      final sync = svc.translateSync(
          text: 'Hello friend', targetLanguage: 'it', message: r)!;
      expect(sync.text, 'Ciao amico');
      expect(sync.layer, 'message');
      final res = await svc.translateDetailed(
          text: 'Hello friend', targetLanguage: 'it', message: r);
      expect(res.text, 'Ciao amico');
      expect(res.layer, 'message');
      expect(server.calls, isEmpty);
    });

    test('stored translation of edited content is ignored', () async {
      final server = FakeServer()
        ..byId['m1'] = {
          'text': 'Ciao di nuovo',
          'detectedLanguage': 'en',
          'layer': 'api'
        };
      final svc = service(server);
      final r = ref('m1', tr: {'it': 'Ciao amico'}, trFor: 'Hello friend');
      expect(
          svc.translateSync(
              text: 'Hello again', targetLanguage: 'it', message: r),
          isNull);
      final res = await svc.translateDetailed(
          text: 'Hello again', targetLanguage: 'it', message: r);
      expect(res.text, 'Ciao di nuovo');
      expect(server.batchCalls, hasLength(1));
    });

    test('message lang == target base language: original, no call', () async {
      final server = FakeServer();
      final svc = service(server);
      final res = await svc.translateDetailed(
          text: 'Olá, tudo certo por aí?',
          targetLanguage: 'pt_BR',
          message: ref('m1', lang: 'pt'));
      expect(res.isTranslated, isFalse);
      expect(res.failed, isFalse);
      expect(res.layer, 'lang');
      expect(server.calls, isEmpty);
    });

    test('phrasebook: no call', () async {
      final server = FakeServer();
      final svc = service(server);
      final res = await svc.translateDetailed(
          text: 'Good night!', targetLanguage: 'de', message: ref('m1'));
      expect(res.text, 'Gute Nacht!');
      expect(res.layer, 'phrasebook');
      expect(server.calls, isEmpty);
    });

    test('nothing to translate: no call, not even a consent prompt', () async {
      final server = FakeServer();
      final svc = service(server, consent: false);
      final res = await svc.translateDetailed(
          text: '😂😂', targetLanguage: 'it', message: ref('m1'));
      expect(res.consentRequired, isFalse);
      expect(res.layer, 'skip');
      expect(server.calls, isEmpty);
    });

    test('misses of one frame go to the server in ONE call', () async {
      final server = FakeServer()
        ..byId['m1'] = {
          'text': 'Ci vediamo alle otto',
          'detectedLanguage': 'en',
          'layer': 'api'
        }
        ..byId['m2'] = {
          'text': 'Dove ci incontriamo?',
          'detectedLanguage': 'en',
          'layer': 'cache'
        }
        ..byId['m3'] = {
          'text': 'Va bene per me',
          'detectedLanguage': 'it',
          'sameLanguage': true,
          'layer': 'api'
        };
      final svc = service(server);
      final results = await Future.wait([
        svc.translateDetailed(
            text: 'See you at eight', targetLanguage: 'it', message: ref('m1')),
        svc.translateDetailed(
            text: 'Where do we meet?',
            targetLanguage: 'it',
            message: ref('m2')),
        svc.translateDetailed(
            text: 'Va bene per me', targetLanguage: 'it', message: ref('m3')),
      ]);
      expect(server.calls, hasLength(1));
      final call = server.batchCalls.single;
      expect(call['target'], 'it');
      expect([for (final m in call['messages'] as List) m['messageId']],
          ['m1', 'm2', 'm3']);
      expect((call['messages'] as List).first,
          {'kind': 'conversation', 'parentId': 'c1', 'messageId': 'm1'});
      expect(results.map((r) => r.text).toList(),
          ['Ci vediamo alle otto', 'Dove ci incontriamo?', 'Va bene per me']);
      expect(results[1].layer, 'server-cache');
      expect(results[2].isTranslated, isFalse);

      // Second time: memory, no call.
      final again = await svc.translateDetailed(
          text: 'See you at eight', targetLanguage: 'it', message: ref('m1'));
      expect(again.layer, 'memory');
      expect(server.calls, hasLength(1));
    });

    test('an item the server could not resolve falls back to the text path',
        () async {
      final server = FakeServer()
        ..byId['m1'] = {'error': 'not-found'}
        ..byText['See you at eight'] = 'Ci vediamo alle otto';
      final svc = service(server);
      final res = await svc.translateDetailed(
          text: 'See you at eight', targetLanguage: 'it', message: ref('m1'));
      expect(res.text, 'Ci vediamo alle otto');
      expect(server.batchCalls, hasLength(1));
      expect(server.textCalls.single['texts'], ['See you at eight']);
    });

    test('an old server (batch refused) still translates every message',
        () async {
      final server = FakeServer()
        ..batchThrows = true
        ..byText['See you at eight'] = 'Ci vediamo alle otto'
        ..byText['Where do we meet?'] = 'Dove ci incontriamo?';
      final svc = service(server);
      final results = await Future.wait([
        svc.translateDetailed(
            text: 'See you at eight', targetLanguage: 'it', message: ref('m1')),
        svc.translateDetailed(
            text: 'Where do we meet?',
            targetLanguage: 'it',
            message: ref('m2')),
      ]);
      expect(results.map((r) => r.text).toList(),
          ['Ci vediamo alle otto', 'Dove ci incontriamo?']);
      expect(server.batchCalls, hasLength(1));
      expect(server.textCalls, hasLength(2));
    });

    test('without a message ref the old single-text call is used', () async {
      final server = FakeServer()
        ..byText['See you at eight'] = 'Ci vediamo alle otto';
      final svc = service(server);
      final res = await svc.translateDetailed(
          text: 'See you at eight', targetLanguage: 'it');
      expect(res.text, 'Ci vediamo alle otto');
      expect(server.batchCalls, isEmpty);
    });

    test('translateSync returns null for a real miss', () {
      final svc = service(FakeServer());
      expect(
          svc.translateSync(
              text: 'See you at eight',
              targetLanguage: 'it',
              message: ref('m1')),
          isNull);
    });
  });
}
