import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/domain/attraction_rating.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';
import 'package:greengo_chat/features/attractions/presentation/widgets/attraction_grid_tile.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// A worst-case record: long names everywhere, every overlay on.
Attraction _attraction({double? google = 4.4}) => Attraction(
      id: 42,
      slug: 'x',
      name: 'Basilica di Santa Maria Gloriosa dei Frari e Chiostro Monumentale',
      cityName: 'Castelnuovo di Garfagnana sul Serchio',
      citySlug: 'x',
      countryIso2: 'IT',
      imgBase: 'b',
      imgHash: 'h',
      imgToken: 't',
      greengoScore: 93,
      scoreTier: 'iconic',
      googleRating: google,
      unesco: true,
      importanceKey: 'world_icon',
      attributionAuthor: 'A Very Long Photographer Name',
      attributionLicense: 'CC BY-SA 4.0',
    );

const _locales = [
  Locale('en'),
  Locale('it'),
  Locale('es'),
  Locale('fr'),
  Locale('de'),
  Locale('pt'),
  Locale('pt', 'BR'),
];

Future<void> _pumpGrid(
  WidgetTester tester,
  Locale locale, {
  required bool withDistance,
  required AttractionRatingDisplay? rating,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(320, 640);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final a = _attraction();
      return Scaffold(
        body: GridView.builder(
          // Same geometry as AttractionsTab._grid on a phone.
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.62,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => AttractionGridTile(
            attraction: a,
            image: Container(color: Colors.grey),
            cityCountry: '${a.cityName} - Italia del Nord e Centro',
            distance: withDistance ? l10n.attrKmAway('1234.5') : null,
            rating: rating,
            attribution:
                l10n.attrPhotoBy(a.attributionAuthor!, a.attributionLicense!),
            onTap: () {},
          ),
        ),
      );
    }),
  ));
  await tester.pump();
}

void main() {
  final greengo = AttractionRatingDisplay.of(
      const AttractionRatingSummary(sum: 46000, count: 10000), 4.2);
  final google = AttractionRatingDisplay.of(null, 4.2);

  for (final locale in _locales) {
    for (final withDistance in [true, false]) {
      for (final rating in [greengo, google, null]) {
        testWidgets(
            'grid tile fits at 320px / 3 columns '
            '[$locale dist=$withDistance rating=${rating?.valueLabel}]',
            (tester) async {
          await _pumpGrid(tester, locale,
              withDistance: withDistance, rating: rating);
          expect(tester.takeException(), isNull); // no RenderFlex overflow
          expect(find.byType(AttractionGridTile), findsWidgets);
          expect(find.byKey(const ValueKey('attrTileDistance')),
              withDistance ? findsWidgets : findsNothing);
          expect(find.byKey(const ValueKey('attrRatingLine')),
              rating == null ? findsNothing : findsWidgets);
        });
      }
    }
  }

  testWidgets('text lines are title, City - Country, distance, rating',
      (tester) async {
    await _pumpGrid(tester, const Locale('en'),
        withDistance: true, rating: greengo);
    double top(Key k) => tester.getTopLeft(find.byKey(k).first).dy;
    final title = top(const ValueKey('attrTileTitle'));
    final place = top(const ValueKey('attrTilePlace'));
    final dist = top(const ValueKey('attrTileDistance'));
    final rate = top(const ValueKey('attrRatingLine'));
    expect(title < place && place < dist && dist < rate, isTrue);
    expect(find.text('4.6 (10000)'), findsWidgets);
    expect(find.text('1234.5 km away'), findsWidgets);
  });

  testWidgets('Google fallback shows no count', (tester) async {
    await _pumpGrid(tester, const Locale('en'),
        withDistance: false, rating: google);
    expect(find.text('4.2'), findsWidgets);
  });
}
