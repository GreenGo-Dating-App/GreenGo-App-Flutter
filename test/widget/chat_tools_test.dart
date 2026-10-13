import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/chat_datasets.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_datasets_download_card.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_ideas_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('download window: only the number, moving with the bytes; ready; failure offers OK', (tester) async {
    final p = ValueNotifier<(double, bool?)>((0.457, null));
    await tester.pumpWidget(_app(ChatDatasetsDownloadDialog(progress: p)));
    expect(find.text('Getting GreenGo ready'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('OK'), findsNothing); // the user waits (or minimises)
    p.value = (0.857, null);
    await tester.pump();
    expect(find.text('85%'), findsOneWidget); // exactly the downloaded share
    p.value = (1, true);
    await tester.pump();
    expect(find.text('Chat content ready, also offline'), findsOneWidget);
    p.value = (0.6, false);
    await tester.pump();
    expect(find.textContaining('try again next time'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('window can be minimised while downloading; pill shows the %', (tester) async {
    final p = ValueNotifier<(double, bool?)>((0.2, null));
    var minimised = false;
    await tester.pumpWidget(_app(ChatDatasetsDownloadDialog(progress: p, onMinimise: () => minimised = true)));
    await tester.tap(find.byKey(const ValueKey('chat-datasets-minimise')));
    expect(minimised, isTrue);

    await tester.pumpWidget(_app(Stack(children: [ChatDatasetsDownloadPill(progress: p)])));
    expect(find.text('20%'), findsOneWidget);
    // It can be dragged anywhere.
    final before = tester.getCenter(find.byKey(const ValueKey('chat-datasets-download-pill')));
    await tester.drag(find.byKey(const ValueKey('chat-datasets-download-pill-drag')), const Offset(-60, -200));
    await tester.pump();
    final after = tester.getCenter(find.byKey(const ValueKey('chat-datasets-download-pill')));
    expect(after.dy, lessThan(before.dy - 100));
    p.value = (0.73, null);
    await tester.pump();
    expect(find.text('73%'), findsOneWidget);
    p.value = (1, true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Chat content ready, also offline'), findsOneWidget);
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

  testWidgets('ice-breakers: category grid, tap one for its messages, back to the grid', (tester) async {
    LocalizedText t(String en) => LocalizedText({'en': en});
    ChatDatasets.instance.debugSet(icebreakers: [
      DatasetItem(id: 'ib-travel-001', topic: 'travel', text: t('Where would you go tomorrow?')),
      DatasetItem(id: 'ib-travel-002', topic: 'travel', text: t('Best trip ever?')),
      DatasetItem(id: 'ib-food-001', topic: 'food', text: t('Favourite dish?')),
    ]);
    await tester.pumpWidget(_app(ChatIdeasSheet(partnerLanguage: 'en', myLanguage: 'en', onPick: (_) {})));
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-ideas-categories')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-ideas-category-travel')));
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-ideas-categories')), findsNothing);
    expect(find.text('Best trip ever?'), findsOneWidget);
    expect(find.text('Favourite dish?'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('chat-ideas-back')));
    await tester.pump();
    expect(find.byKey(const ValueKey('chat-ideas-categories')), findsOneWidget);
  });
}
