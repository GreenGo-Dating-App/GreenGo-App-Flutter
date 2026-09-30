import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/domain/attraction_filters.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';

Attraction att(
  int id, {
  int score = 50,
  String? category = 'Museum',
  String city = 'Rome',
  String? citySlug,
}) =>
    Attraction(
      id: id,
      slug: 'a$id',
      name: 'A$id',
      cityName: city,
      citySlug: citySlug ?? city.toLowerCase(),
      countryIso2: 'IT',
      imgBase: 'b',
      imgHash: 'h',
      imgToken: 't',
      category: category,
      categoryIcon: category == null ? null : 'icon_$category',
      greengoScore: score,
    );

void main() {
  final list = [
    att(1, score: 95, category: 'Museum', city: 'Rome'),
    att(2, score: 80, category: 'Historic Site', city: 'Rome'),
    att(3, score: 60, category: 'Museum', city: 'Florence'),
    att(4, score: 40, category: 'Beach', city: 'Naples'),
    att(5, score: 100, category: null, city: 'Rome'),
    att(6, score: 0, category: 'Museum', city: 'Florence'),
  ];

  group('filterAttractions', () {
    test('defaults return the list unchanged (same instance)', () {
      expect(identical(filterAttractions(list), list), isTrue);
    });

    test('score range is inclusive at both ends', () {
      final ids = filterAttractions(list, minScore: 60, maxScore: 95)
          .map((a) => a.id)
          .toList();
      expect(ids, [1, 2, 3]);
      expect(filterAttractions(list, minScore: 100).map((a) => a.id), [5]);
      expect(filterAttractions(list, maxScore: 0).map((a) => a.id), [6]);
    });

    test('category narrows by raw value', () {
      expect(filterAttractions(list, category: 'Museum').map((a) => a.id),
          [1, 3, 6]);
    });

    test('city narrows by city key', () {
      expect(filterAttractions(list, city: 'rome').map((a) => a.id),
          [1, 2, 5]);
    });

    test('filters combine and preserve order', () {
      final out = filterAttractions(list,
          minScore: 50, category: 'Museum', city: 'florence');
      expect(out.map((a) => a.id), [3]);
      expect(
          filterAttractions(list, city: 'naples', category: 'Museum'), isEmpty);
    });
  });

  group('facets', () {
    test('categoryFacets counts, skips null, most-populated first', () {
      final f = categoryFacets(list);
      expect(f.map((c) => c.key), ['Museum', 'Beach', 'Historic Site']);
      expect(f.first.count, 3);
      expect(f.first.icon, 'icon_Museum');
    });

    test('categoryFacets breaks ties by the provided label', () {
      final f = categoryFacets(list, labelOf: (c) => c == 'Beach' ? 'Z' : 'A');
      expect(f.map((c) => c.key), ['Museum', 'Historic Site', 'Beach']);
    });

    test('cityFacets counts by slug and keeps the display name', () {
      final f = cityFacets(list);
      expect(f.map((c) => c.key), ['rome', 'florence', 'naples']);
      expect(f.map((c) => c.count), [3, 2, 1]);
      expect(f.first.label, 'Rome');
    });

    test('attractionCityKey falls back to the name without a slug', () {
      expect(attractionCityKey(att(9, city: 'San José', citySlug: '')),
          'san josé');
    });
  });

  group('AttractionFilterSelection.isActive', () {
    test('defaults are inactive', () {
      expect(const AttractionFilterSelection(countryIso: 'IT').isActive('IT'),
          isFalse);
      expect(const AttractionFilterSelection(countryIso: null).isActive('IT'),
          isFalse);
    });

    test('any non-default field activates it', () {
      expect(
          const AttractionFilterSelection(countryIso: 'IT', minScore: 1)
              .isActive('IT'),
          isTrue);
      expect(
          const AttractionFilterSelection(countryIso: 'IT', category: 'Museum')
              .isActive('IT'),
          isTrue);
      expect(
          const AttractionFilterSelection(countryIso: 'IT', city: 'rome')
              .isActive('IT'),
          isTrue);
      expect(const AttractionFilterSelection(countryIso: 'US').isActive('IT'),
          isTrue);
    });
  });
}
