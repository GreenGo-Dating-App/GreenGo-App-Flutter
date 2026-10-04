import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/shared_translation_contributor.dart';
import 'package:greengo_chat/core/services/translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// On-device translations of PUBLIC content are contributed to the shared
/// store in debounced, fire-and-forget batches of at most 20 per call.
void main() {
  const debounce = Duration(milliseconds: 20);
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 80));

  late List<(String, List<Map<String, String>>)> calls;
  late SharedTranslationContributor c;

  setUp(() {
    calls = [];
    c = SharedTranslationContributor(
      debounce: debounce,
      submit: (target, items) async => calls.add((target, items)),
    );
  });
  tearDown(() => c.dispose());

  test('debounces: nothing is sent before the quiet period, then one batch', () async {
    c.add('it', 'Hello', 'Ciao');
    c.add('it', 'Good morning', 'Buongiorno');
    expect(calls, isEmpty);
    await settle();
    expect(calls, hasLength(1));
    expect(calls.single.$1, 'it');
    expect(calls.single.$2, [
      {'text': 'Hello', 'translation': 'Ciao'},
      {'text': 'Good morning', 'translation': 'Buongiorno'},
    ]);
  });

  test('splits into calls of at most 20 items, grouped by target', () async {
    for (var i = 0; i < 45; i++) {
      c.add('it', 'text $i', 'testo $i');
    }
    c.add('pt-BR', 'Hello', 'Olá');
    await settle();
    final it = calls.where((x) => x.$1 == 'it').map((x) => x.$2.length).toList();
    expect(it, [20, 20, 5]);
    expect(calls.where((x) => x.$1 == 'pt-BR').single.$2.single['translation'], 'Olá');
    expect(calls.every((x) => x.$2.length <= SharedTranslationContributor.maxPerCall), isTrue);
  });

  test('skips untranslated, empty, oversize and duplicate items', () async {
    c.add('it', 'Same', 'Same');
    c.add('it', '', 'x');
    c.add('it', 'x', '  ');
    c.add('it', 'a' * 5001, 'b');
    c.add('it', 'Hello', 'Ciao');
    c.add('it', 'Hello', 'Salve');
    expect(c.pendingCount, 1);
    await settle();
    expect(calls.single.$2, [
      {'text': 'Hello', 'translation': 'Ciao'},
    ]);
    // Already sent this session: not sent again.
    c.add('it', 'Hello', 'Ciao');
    await settle();
    expect(calls, hasLength(1));
  });

  test('bounds the queue', () {
    for (var i = 0; i < SharedTranslationContributor.maxQueued + 50; i++) {
      c.add('it', 't$i', 'x$i');
    }
    expect(c.pendingCount, SharedTranslationContributor.maxQueued);
  });

  test('a failing call never throws and later batches still go out', () async {
    var n = 0;
    final failing = SharedTranslationContributor(
      debounce: debounce,
      submit: (target, items) async {
        n++;
        if (n == 1) throw Exception('offline');
      },
    );
    for (var i = 0; i < 25; i++) {
      failing.add('it', 't$i', 'x$i');
    }
    await failing.flush();
    expect(n, 2);
    failing.dispose();
  });

  test('TranslationService routes contributions to its contributor', () async {
    final svc = TranslationService.test(
      client: MockClient((_) async => http.Response('[]', 200)),
      contributor: c,
    );
    svc.contributeShared('it', 'Hello', 'Ciao');
    await settle();
    expect(calls.single.$2.single, {'text': 'Hello', 'translation': 'Ciao'});
  });
}
