import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/translation_service.dart';

/// The app and the translateTexts Cloud Function must derive the SAME id for
/// a (language, text) pair, or stored translations are never found. The
/// expected values were produced by Node's crypto (the server's code path).
void main() {
  test('shared translation id matches the server (sha256, NUL separator)', () {
    expect(
      TranslationService.sharedTranslationId('it', 'Colosseum — a famous arena'),
      '937155537fb0ec8d74f5d7428499458e77d494c9616e18263ba76d98d94a56a9',
    );
    expect(
      TranslationService.sharedTranslationId('pt-BR', 'Olá ✨ café'),
      'a98f96199274097ca3a85db05b48bd163138edc9f712ca0ebe6e3f493ae6d95b',
    );
  });
}
