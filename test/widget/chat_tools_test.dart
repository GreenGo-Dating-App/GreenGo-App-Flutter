import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_datasets_download_card.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_ideas_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('download card: progress, then ready', (tester) async {
    final p = ValueNotifier<(int, int, bool?)>((2, 6, null));
    await tester.pumpWidget(_app(Stack(children: [ChatDatasetsDownloadCard(progress: p)])));
    expect(find.text('Downloading chat content for offline use… 2/6'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, closeTo(2 / 6, 1e-9));
    p.value = (6, 6, true);
    await tester.pump();
    expect(find.text('Chat content ready, also offline'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  for (final sentences in [false, true]) {
    testWidgets('ideas sheet shows one kind only (sentences: $sentences)', (tester) async {
      await tester.pumpWidget(_app(ChatIdeasSheet(
        partnerLanguage: 'en',
        myLanguage: 'en',
        onPick: (_) {},
        sentences: sentences,
      )));
      final title = tester.widget<Text>(find.byKey(const ValueKey('chat-ideas-title'))).data;
      expect(title, sentences ? 'Suggested sentences' : 'Ice-breakers');
      expect(find.byType(SegmentedButton<bool>), findsNothing);
    });
  }
}
