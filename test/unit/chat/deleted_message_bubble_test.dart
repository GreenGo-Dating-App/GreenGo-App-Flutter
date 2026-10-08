import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/pronunciation_service.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/deleted_message_bubble.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

void main() {
  test('deleted-author detection: new and old message formats', () {
    expect(isDeletedAuthorMessage('deleted_user'), isTrue); // old + new
    expect(isDeletedAuthorMessage('abc', deletedAuthor: true), isTrue);
    expect(isDeletedAuthorMessage('abc'), isFalse);
    expect(isDeletedAuthorMessage(null), isFalse);
  });

  for (final locale in const [Locale('en'), Locale('it'), Locale('pt', 'BR')]) {
    testWidgets('placeholder is localized ($locale)', (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: DeletedMessageBubble()),
      ));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(DeletedMessageBubble)))!;
      expect(l10n.chatMessageDeleted, isNotEmpty);
      expect(find.text(l10n.chatMessageDeleted), findsOneWidget);
    });
  }

  test('TTS cache key matches the server (aiGateway.ts ttsCacheKey)', () {
    // sha256("bom dia")[:40], language "pt_BR" -> "pt-br", female.
    final k = PronunciationService.serverCacheKey('  Bom   DIA ', 'pt_BR', isMale: false);
    // Value computed with Node's crypto, i.e. what the server writes.
    expect(k, 'v6_pt-br_b8e3bc65c7438ad83af40847a23a087e935cb0a1_f');
    expect(k, PronunciationService.serverCacheKey('bom dia', 'PT_br', isMale: false));
  });
}
