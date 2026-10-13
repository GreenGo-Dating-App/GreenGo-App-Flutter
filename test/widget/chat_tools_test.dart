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
  testWidgets('download window: percentage, then ready; failure offers OK', (tester) async {
    final p = ValueNotifier<(double, bool?)>((0.457, null));
    await tester.pumpWidget(_app(ChatDatasetsDownloadDialog(progress: p)));
    expect(find.text('Getting GreenGo ready'), findsOneWidget);
    expect(find.textContaining('only once'), findsOneWidget);
    expect(find.text('Downloading… 45%'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value, closeTo(0.457, 1e-9));
    expect(find.text('OK'), findsNothing); // the user waits
    p.value = (1, true);
    await tester.pump();
    expect(find.text('Chat content ready, also offline'), findsOneWidget);
    p.value = (0.6, false);
    await tester.pump();
    expect(find.textContaining('try again next time'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
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
