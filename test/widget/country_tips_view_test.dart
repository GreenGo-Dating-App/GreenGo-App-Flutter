import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/chat_datasets/chat_datasets.dart';
import 'package:greengo_chat/features/chat/presentation/widgets/keyword_actions.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

CulturalTip _tip(String id, String cat, String en, String it) =>
    CulturalTip(id: id, category: cat, text: LocalizedText({'en': en, 'it': it}));

Future<void> _pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: CountryTipsView(iso2: 'IT', ready: Future<void>.value())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    ChatDatasets.instance.debugSet(tips: {
      'IT': [
        _tip('1', 'dining', 'Cappuccino is a morning drink.', 'Il cappuccino si beve al mattino.'),
        _tip('2', 'greetings', 'Two kisses on the cheeks among friends.', 'Due baci sulle guance tra amici.'),
        _tip('3', 'dining', 'Bread is not dipped in olive oil.', 'Il pane non si intinge nell\'olio.'),
      ],
    });
  });

  testWidgets('All: chips with counts, tips grouped under category headings in order', (tester) async {
    await _pump(tester);
    expect(find.text('All  3'), findsOneWidget);
    expect(find.text('Greetings  1'), findsOneWidget);
    expect(find.text('Food & dining  2'), findsOneWidget);
    // Greetings comes before dining in the fixed category order.
    final greet = tester.getTopLeft(find.text('GREETINGS')).dy;
    final dining = tester.getTopLeft(find.text('FOOD & DINING')).dy;
    expect(greet, lessThan(dining));
    expect(find.text('Cappuccino is a morning drink.'), findsOneWidget);
  });

  testWidgets('a category chip shows only that category', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Greetings  1'));
    await tester.pumpAndSettle();
    expect(find.text('Two kisses on the cheeks among friends.'), findsOneWidget);
    expect(find.text('Cappuccino is a morning drink.'), findsNothing);
    expect(find.text('GREETINGS'), findsNothing); // no headings in a single category
  });

  testWidgets('tips and category names follow the app language', (tester) async {
    await _pump(tester, locale: const Locale('it'));
    expect(find.text('Cibo e tavola  2'), findsOneWidget);
    expect(find.text('Il cappuccino si beve al mattino.'), findsOneWidget);
  });
}
