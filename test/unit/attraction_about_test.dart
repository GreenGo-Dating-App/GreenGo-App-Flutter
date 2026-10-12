import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';

Attraction _a(Map<String, String> about, Map<String, String> src) => Attraction(
      id: 401,
      slug: 'colosseum-rome',
      name: 'Colosseum',
      cityName: 'Rome',
      citySlug: 'rome',
      countryIso2: 'IT',
      imgBase: 'b',
      imgHash: 'h',
      imgToken: 't',
      greengoScore: 99,
      scoreTier: 'iconic',
      about: about,
      aboutSources: src,
    );

void main() {
  final a = _a(
    {'en': 'The Colosseum is an ancient amphitheatre.', 'it': 'Il Colosseo è un anfiteatro.', 'pt_BR': 'O Coliseu é um anfiteatro.'},
    {'en': 'https://en.wikipedia.org/wiki/Colosseum', 'it': 'https://it.wikipedia.org/wiki/Colosseo', 'pt_BR': 'https://pt.wikipedia.org/wiki/Coliseu'},
  );

  test('the text and source of the app language', () {
    expect(a.aboutIn(const Locale('it')), 'Il Colosseo è un anfiteatro.');
    expect(a.aboutSourceIn(const Locale('it')), 'https://it.wikipedia.org/wiki/Colosseo');
    expect(a.aboutIn(const Locale('pt', 'BR')), 'O Coliseu é um anfiteatro.');
  });

  test('no article in that language: null text (translate English), English source', () {
    expect(a.aboutIn(const Locale('de')), isNull);
    expect(a.aboutSourceIn(const Locale('de')), 'https://en.wikipedia.org/wiki/Colosseum');
  });

  test('only a Spanish article: that one is the fallback, with its source', () {
    final es = _a({'es': 'El jardín botánico de Hamilton.'}, {'es': 'https://es.wikipedia.org/wiki/X'});
    expect(es.aboutIn(const Locale('en')), isNull);
    expect(es.aboutAny, 'El jardín botánico de Hamilton.');
    expect(es.aboutSourceIn(const Locale('en')), 'https://es.wikipedia.org/wiki/X');
    expect(es.aboutIn(const Locale('es')), 'El jardín botánico de Hamilton.');
  });
}
