import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Attraction texts come only from the stored i18n fields in Firestore
/// (fallback: the original text). No attraction surface may call a
/// translation service (TranslationService, translateTexts, gtx, Cloud
/// Translation) or show a Translate / Show original toggle.
final _forbidden = RegExp(
  r'TranslationService|TranslatableText|translateShared|translateTexts|'
  r'translatePrivateText|translate\.googleapis|client=gtx',
);

/// Every file that renders attraction content.
List<File> _attractionSurfaces() => [
      ...Directory('lib/features/attractions')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
      File('lib/features/chat/presentation/widgets/attraction_message.dart'),
      File('lib/features/chat/presentation/widgets/chat_places_bar.dart'),
    ];

List<String> _hits(File f) => f
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .where(_forbidden.hasMatch)
    .toList();

void main() {
  test('the scan finds a translation call where there is one', () {
    expect(_hits(File('lib/core/widgets/translatable_text.dart')), isNotEmpty);
  });

  test('no attraction surface calls a translation service', () {
    final files = _attractionSurfaces();
    expect(files.length, greaterThan(5));
    final bad = <String>[
      for (final f in files)
        for (final l in _hits(f)) '${f.path}: ${l.trim()}',
    ];
    expect(bad, isEmpty);
  });

  test('chat does not translate shared attraction cards', () {
    final src =
        File('lib/features/chat/presentation/screens/chat_screen.dart').readAsStringSync();
    final start = src.indexOf('Future<Message> _translateMessage(');
    expect(start, greaterThan(0));
    final body = src.substring(start, src.indexOf('translateDetailed(', start));
    expect(body, contains('ChatAttractionShare.of(message.metadata) != null) return message'));
  });
}
