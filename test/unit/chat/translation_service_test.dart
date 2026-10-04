import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Free-endpoint body for [sentences] (pairs of translated/original) and the
/// detected source language.
String body(List<List<String>> sentences, String detected) => jsonEncode([
      [
        for (final s in sentences) [s[0], s[1], null, null, 10],
      ],
      null,
      detected,
    ]);

/// Fake endpoint: translates by lookup on the `q` parameter (GET or POST).
MockClient fakeEndpoint(
  Map<String, List<String>> table, {
  List<http.Request>? log,
}) =>
    MockClient((req) async {
      log?.add(req);
      final q = req.method == 'POST'
          ? Uri.splitQueryString(req.body)['q']!
          : req.url.queryParameters['q']!;
      final hit = table[q];
      if (hit == null) return http.Response('[[["$q","$q"]],null,"en"]', 200);
      return http.Response(body([[hit[0], q]], hit[1]), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });

void main() {
  group('parseFreeResponse', () {
    test('joins every sentence in order and reports the detected language',
        () {
      final r = TranslationService.parseFreeResponse(
        'Hello my friend. How are you?',
        'it',
        body([
          ['Ciao amico mio. ', 'Hello my friend. '],
          ['Come stai?', 'How are you?'],
        ], 'en'),
      )!;
      expect(r.text, 'Ciao amico mio. Come stai?');
      expect(r.detectedLanguage, 'en');
      expect(r.isTranslated, isTrue);
      expect(r.failed, isFalse);
    });

    test('same language (incl. regional variant) is not a translation', () {
      final r = TranslationService.parseFreeResponse(
        'Bom dia',
        'pt-BR',
        body([
          ['Bom dia', 'Bom dia'],
        ], 'pt'),
      )!;
      expect(r.text, 'Bom dia');
      expect(r.isTranslated, isFalse);
      expect(r.detectedLanguage, 'pt');
    });

    test('a malformed body is rejected', () {
      expect(TranslationService.parseFreeResponse('x', 'it', '<html>'), isNull);
      expect(TranslationService.parseFreeResponse('x', 'it', '{"a":1}'),
          isNull);
    });
  });

  group('translateDetailed', () {
    test('retries a 429 and then succeeds', () async {
      var calls = 0;
      final svc = TranslationService.test(
        client: MockClient((req) async {
          calls++;
          if (calls == 1) return http.Response('Too Many Requests', 429);
          return http.Response(body([['Ciao', 'Hello']], 'en'), 200);
        }),
      );
      final r =
          await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(r.text, 'Ciao');
      expect(r.failed, isFalse);
      expect(calls, 2);
    });

    test('gives up after 4 attempts, reports failure and does not cache it',
        () async {
      var calls = 0;
      final svc = TranslationService.test(
        client: MockClient((req) async {
          calls++;
          return http.Response('unavailable', 503);
        }),
      );
      final r =
          await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(r.failed, isTrue);
      expect(r.text, 'Hello');
      expect(r.isTranslated, isFalse);
      expect(calls, 4);

      // Asking again goes back to the network (failures are not cached).
      await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(calls, 8);
    });

    test('network errors are retried', () async {
      var calls = 0;
      final svc = TranslationService.test(
        client: MockClient((req) async {
          calls++;
          if (calls < 3) throw http.ClientException('offline');
          return http.Response(body([['Ciao', 'Hello']], 'en'), 200);
        }),
      );
      final r =
          await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(r.text, 'Ciao');
      expect(calls, 3);
    });

    test('a 400 is not retried', () async {
      var calls = 0;
      final svc = TranslationService.test(
        client: MockClient((req) async {
          calls++;
          return http.Response('bad', 400);
        }),
      );
      final r =
          await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(r.failed, isTrue);
      expect(calls, 1);
    });

    test('each result carries its own detected language, also on cache hits',
        () async {
      // Regression: chat read the service-wide lastDetectedLanguage, which a
      // cache hit never updated, so reopening a chat attributed the last
      // network result's language ("it") to an English message and dropped
      // its translation as "same language".
      final svc = TranslationService.test(
        client: fakeEndpoint({
          'Hello': ['Ciao', 'en'],
          'Ciao come va': ['Ciao come va', 'it'],
        }),
      );
      await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      await svc.translateDetailed(text: 'Ciao come va', targetLanguage: 'it');

      final again =
          await svc.translateDetailed(text: 'Hello', targetLanguage: 'it');
      expect(again.text, 'Ciao');
      expect(again.detectedLanguage, 'en');
      expect(again.isTranslated, isTrue);

      // The legacy String API keeps lastDetectedLanguage in step too.
      await svc.translate(
          text: 'Hello', sourceLanguage: 'auto', targetLanguage: 'it');
      expect(svc.lastDetectedLanguage, 'en');
    });

    test('identical concurrent requests share one call', () async {
      final log = <http.Request>[];
      final svc = TranslationService.test(
          client: fakeEndpoint({
        'Hello': ['Ciao', 'en'],
      }, log: log));
      final results = await Future.wait([
        for (var i = 0; i < 5; i++)
          svc.translateDetailed(text: 'Hello', targetLanguage: 'it'),
      ]);
      expect(results.map((r) => r.text).toSet(), {'Ciao'});
      expect(log.length, 1);
    });

    test('never more than maxConcurrent requests in flight', () async {
      var active = 0, peak = 0, calls = 0;
      final svc = TranslationService.test(
        client: MockClient((req) async {
          calls++;
          active++;
          if (active > peak) peak = active;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          active--;
          final q = req.url.queryParameters['q']!;
          return http.Response(body([['T:$q', q]], 'en'), 200);
        }),
      );
      final results = await Future.wait([
        for (var i = 0; i < 20; i++)
          svc.translateDetailed(text: 'message $i', targetLanguage: 'it'),
      ]);
      expect(calls, 20);
      expect(peak, lessThanOrEqualTo(TranslationService.maxConcurrent));
      expect(results[7].text, 'T:message 7');
    });

    test('long text is sent in a POST body', () async {
      final log = <http.Request>[];
      final long = 'word ' * 400;
      final svc = TranslationService.test(
          client: fakeEndpoint({
        long: ['parola', 'en'],
      }, log: log));
      final r = await svc.translateDetailed(text: long, targetLanguage: 'it');
      expect(r.text, 'parola');
      expect(log.single.method, 'POST');
      expect(log.single.url.queryParameters.containsKey('q'), isFalse);
    });

    test('display names are normalized and same source/target short-circuits',
        () async {
      final log = <http.Request>[];
      final svc = TranslationService.test(
          client: fakeEndpoint({
        'Hello': ['Olá', 'en'],
      }, log: log));
      final r = await svc.translateDetailed(
          text: 'Hello', targetLanguage: 'Portuguese (Brazil)');
      expect(r.text, 'Olá');
      expect(log.single.url.queryParameters['tl'], 'pt-BR');

      final same = await svc.translateDetailed(
          text: 'Hi', sourceLanguage: 'en', targetLanguage: 'English');
      expect(same.isTranslated, isFalse);
      expect(log.length, 1);
    });
  });
}
