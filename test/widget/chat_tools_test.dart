import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/chat_datasets.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/chat_ideas_sheet.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
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

  testWidgets('3-column category grid fits a 320 px phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    LocalizedText t(String en) => LocalizedText({'en': en});
    ChatDatasets.instance.debugSet(icebreakers: [
      for (final topic in ['would_you_rather', 'hobbies_creativity', 'movies_series', 'dreams_goals'])
        DatasetItem(id: 'x-$topic', topic: topic, text: t('?')),
    ]);
    await tester.pumpWidget(_app(ChatIdeasSheet(partnerLanguage: 'en', myLanguage: 'en', onPick: (_) {})));
    await tester.pump();
    expect(tester.takeException(), isNull);
    final grid = tester.widget<GridView>(find.byKey(const ValueKey('chat-ideas-categories')));
    expect((grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount).crossAxisCount, 3);
  });
}
