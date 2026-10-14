import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/data/attractions_lite_codec.dart';
import 'package:greengo_chat/features/attractions/domain/attraction_filters.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';

Attraction _a({
  Map<String, AttractionTexts> i18n = const {},
  Map<String, String> cityNames = const {},
  Map<String, String> shortTemplates = const {},
  Map<String, String> about = const {},
  Map<String, String> aboutTranslated = const {},
}) =>
    Attraction(
      id: 7,
      slug: 'english-garden-munich',
      name: 'English Garden',
      cityName: 'Munich',
      citySlug: 'munich',
      countryIso2: 'DE',
      imgBase: 'b',
      imgHash: 'h',
      imgToken: 't',
      names: const {'it': 'Giardino Inglese'},
      descriptionShort: 'English Garden in Munich: park and one of Germany\'s standout stops.',
      historySummary: 'Laid out in 1789.',
      openingHours: 'Open 24 hours',
      topHighlights: const ['Chinese Tower', 'Eisbach wave'],
      i18n: i18n,
      cityNames: cityNames,
      shortTemplates: shortTemplates,
      about: about,
      aboutTranslated: aboutTranslated,
    );

void main() {
  group('textsFor', () {
    final a = _a(i18n: AttractionTexts.i18nMap({
      'it': {
        'cityName': 'Monaco di Baviera',
        'historySummary': 'Realizzato nel 1789.',
        'topHighlights': ['Torre Cinese', 'Onda dell\'Eisbach'],
      },
      'de': {'topHighlights': ['Chinesischer Turm']}, // partial list
      'fr': 'not a map',
    }));

    test('stored language is read as is, missing fields fall back to English', () {
      final t = a.textsFor(const Locale('it'));
      expect(t.historySummary, 'Realizzato nel 1789.');
      expect(t.topHighlights, ['Torre Cinese', 'Onda dell\'Eisbach']);
      expect(t.openingHours, 'Open 24 hours');
      expect(a.cityFor(const Locale('it')), 'Monaco di Baviera');
    });

    test('a list of another length never mixes languages', () {
      expect(a.textsFor(const Locale('de')).topHighlights, ['Chinese Tower', 'Eisbach wave']);
    });

    test('English, unknown and malformed languages give the English texts', () {
      for (final l in const [Locale('en'), Locale('fr'), Locale('ja')]) {
        expect(a.textsFor(l).historySummary, 'Laid out in 1789.');
        expect(a.cityFor(l), 'Munich');
      }
      expect(a.textsFor(null).historySummary, 'Laid out in 1789.');
    });
  });

  group('list records', () {
    final a = _a(
      cityNames: const {'it': 'Monaco di Baviera', 'pt_BR': 'Munique'},
      shortTemplates: const {
        'it': '{N} a {C}: parco e una delle tappe imperdibili della Germania.',
        'pt_BR': '{N} em {C}: parque e uma das paradas imperdíveis da Alemanha.',
      },
    );

    test('short description is filled with the localised title and city', () {
      expect(a.descriptionShortFor(const Locale('it')),
          'Giardino Inglese a Monaco di Baviera: parco e una delle tappe imperdibili della Germania.');
      expect(a.descriptionShortFor(const Locale('pt', 'BR')),
          'English Garden em Munique: parque e uma das paradas imperdíveis da Alemanha.');
      expect(a.descriptionShortFor(const Locale('de')), a.descriptionShort);
    });

    test('city facets are labelled in the app language', () {
      expect(cityFacets([a], locale: const Locale('it')).single.label, 'Monaco di Baviera');
      expect(cityFacets([a]).single.label, 'Munich');
    });
  });

  test('a lower-case Wikidata title is shown with a capital letter', () {
    final a = Attraction(
      id: 1,
      slug: 'eiffel-tower-paris',
      name: 'Eiffel Tower',
      cityName: 'Paris',
      citySlug: 'paris',
      countryIso2: 'FR',
      imgBase: 'b',
      imgHash: 'h',
      imgToken: 't',
      names: const {'it': 'torre Eiffel', 'fr': ''},
    );
    expect(a.nameFor(const Locale('it')), 'Torre Eiffel');
    expect(a.nameFor(const Locale('fr')), 'Eiffel Tower');
  });

  test('about: a translated language is flagged for the credit line', () {
    final a = _a(
      about: const {'en': 'A large public park.', 'it': 'Un grande parco pubblico.', 'de': 'Ein Park.'},
      aboutTranslated: const {'it': 'en'},
    );
    expect(a.aboutIsTranslated(const Locale('it')), isTrue);
    expect(a.aboutIsTranslated(const Locale('de')), isFalse);
    expect(a.aboutIsTranslated(const Locale('en')), isFalse);
  });

  test('lite rows decode the per-language city and short description columns', () {
    final shard = AttractionsLiteShard.parse({
      'format': 1,
      'iso2': 'DE',
      'shard': 0,
      'shards': 1,
      'version': 'v1',
      'sep': '|',
      'cols': ['i', 'n', 'c', 'sc', 'c_it', 'c_ptbr', 'd_it'],
      'dict': {
        'd_it': ['{N} a {C}: parco.'],
      },
      'rows': ['7|English Garden|Munich|90|Monaco di Baviera|Munique|0', '8|Hofgarten|Munich|80'],
    })!;
    final g = shard.items.first;
    expect(g.cityNames, {'it': 'Monaco di Baviera', 'pt_BR': 'Munique'});
    expect(g.shortTemplates, {'it': '{N} a {C}: parco.'});
    expect(g.descriptionShortFor(const Locale('it')), 'English Garden a Monaco di Baviera: parco.');
    expect(shard.items.last.cityNames, isEmpty);
  });
}
