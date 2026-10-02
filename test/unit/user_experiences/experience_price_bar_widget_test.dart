import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/theme/app_theme.dart';
import 'package:greengo_chat/features/user_experiences/presentation/widgets/experience_widgets.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Regression: the experience price rendered one character per line. The app
/// theme gives ElevatedButton an infinite minimum width; as an inflexible Row
/// child next to the price's Expanded it left the price ~0 px wide.
/// The bar is pumped with the REAL app theme so that trap is reproduced.
Widget _host(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: AppTheme.darkTheme,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );

Future<void> _setWidth(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(tester.view.reset);
}

void _expectPriceOnOneLine(WidgetTester tester) {
  final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
      of: find.byKey(const ValueKey('experience-price')),
      matching: find.byType(RichText)));
  final fontSize = ExperiencePriceBar.priceStyle.fontSize!;
  expect(paragraph.size.height, lessThanOrEqualTo(fontSize * 1.5),
      reason: 'price must be laid out on ONE line');
  // Wide enough for more than a couple of glyphs (the bug gave ~1 glyph).
  expect(paragraph.size.width, greaterThan(fontSize * 3));
}

void main() {
  for (final width in [320.0, 375.0, 1024.0]) {
    testWidgets('price + Pay/Book stays on one line at $width px',
        (tester) async {
      await _setWidth(tester, width);
      await tester.pumpWidget(_host(ExperiencePriceBar(
        priceText: 'R\$ 120',
        payLabel: 'Bezahlen / Buchen', // longest locale label
        payIcon: Icons.open_in_new,
        onPay: () {},
      )));
      expect(tester.takeException(), isNull);
      _expectPriceOnOneLine(tester);
      expect(find.byKey(const ValueKey('experience-pay')), findsOneWidget);
    });
  }

  testWidgets('a price too long for 320 px ellipsizes on one line',
      (tester) async {
    await _setWidth(tester, 320);
    await tester.pumpWidget(_host(ExperiencePriceBar(
      priceText: 'BRL 1234567.89 / person / group',
      payLabel: 'Pay / Book',
      onPay: () {},
    )));
    expect(tester.takeException(), isNull);
    _expectPriceOnOneLine(tester);
  });

  testWidgets('free experience without link: price only, one line',
      (tester) async {
    await _setWidth(tester, 320);
    await tester.pumpWidget(_host(const ExperiencePriceBar(priceText: 'Free')));
    expect(tester.takeException(), isNull);
    _expectPriceOnOneLine(tester);
    expect(find.byKey(const ValueKey('experience-pay')), findsNothing);
  });

  group('HostRatingBadge.label', () {
    late AppLocalizations en;
    late AppLocalizations pt;
    setUpAll(() async {
      en = await AppLocalizations.delegate.load(const Locale('en'));
      pt = await AppLocalizations.delegate.load(const Locale('pt', 'BR'));
    });

    test('no ratings -> New host', () {
      expect(HostRatingBadge.label(en, 'en', count: 0, avg: 0), 'New host');
      expect(HostRatingBadge.label(pt, 'pt_BR', count: 0, avg: 0),
          'Novo anfitrião');
    });

    test('average + localized compact count', () {
      expect(HostRatingBadge.label(en, 'en', count: 23, avg: 4.7),
          '4.7 · 23 ratings');
      expect(HostRatingBadge.label(en, 'en', count: 1, avg: 5),
          '5.0 · 1 rating');
      expect(HostRatingBadge.label(en, 'en', count: 1200, avg: 4.66),
          '4.7 · 1.2K ratings');
      expect(HostRatingBadge.label(pt, 'pt_BR', count: 23, avg: 4.7),
          '4,7 · 23 avaliações');
      expect(
          HostRatingBadge.label(en, 'en', count: 23, avg: 4.7, compact: true),
          '4.7 (23)');
    });
  });
}
