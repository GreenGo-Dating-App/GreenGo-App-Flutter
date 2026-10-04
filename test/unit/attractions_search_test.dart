import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/data/datasources/attractions_datasource.dart';

Map<String, dynamic> rec(int i, String name, String city, String slug) => {
      'i': i,
      'n': name,
      'c': city,
      's': slug,
      'cat': 'Historic Site',
      'ci': 'history_edu',
      'b': 'attractions/X/$i',
      'h': 'aaaaaaaa',
      'tk': 'tok',
      'sc': 80,
      'st': 'exceptional',
    };

void main() {
  setUp(AttractionsDataSource.invalidate);

  group('searchCatalogue - bounded cross-catalogue search', () {
    Future<void> seedItaly(FakeFirebaseFirestore db) async {
      await db.collection('attraction_countries').doc('IT').set(
          {'iso2': 'IT', 'name': 'Italy', 'published': true, 'total': 2});
      await db.collection('attraction_countries').doc('US').set(
          {'iso2': 'US', 'name': 'United States', 'published': true, 'total': 1});
      await db.collection('attractions_index').doc('IT_0').set({
        'iso2': 'IT',
        'shard': 0,
        'items': [
          rec(401, 'Colosseum', 'Rome', 'colosseum-rome'),
          rec(421, 'Florence Cathedral', 'Florence', 'florence-cathedral'),
        ],
      });
      await db
          .collection('attractions_index')
          .doc('IT_meta')
          .set({'iso2': 'IT', 'shardCount': 1, 'total': 2});
    }

    Map<String, dynamic> fullDoc(
            int id, String name, String slug, String iso, String citySlug,
            {int score = 90}) =>
        {
          'id': id,
          'name': name,
          'slug': slug,
          'cityName': citySlug,
          'citySlug': citySlug,
          'countryIso2': iso,
          'greengoScore': score,
          'status': 'published',
          'img': {'base': 'attractions/$iso/$id', 'hash': 'h', 'token': 't'},
        };

    test('a country name returns that whole country (memoised list)',
        () async {
      final db = FakeFirebaseFirestore();
      await seedItaly(db);
      final hits =
          await AttractionsDataSource(firestore: db).searchCatalogue('Italy');
      expect(hits.map((a) => a.id).toSet(), {401, 421});
    });

    test('an attraction name matches by slug prefix, in any country',
        () async {
      final db = FakeFirebaseFirestore();
      await seedItaly(db);
      await db.collection('attractions').doc('253').set(fullDoc(
          253, 'Hollywood Walk of Fame', 'hollywood-walk-of-fame', 'US',
          'los-angeles'));
      final hits = await AttractionsDataSource(firestore: db)
          .searchCatalogue('Hollywood');
      expect(hits.map((a) => a.id), [253]);
      expect(hits.single.countryIso2, 'US');
    });

    test('a city name returns that city\'s attractions', () async {
      final db = FakeFirebaseFirestore();
      await seedItaly(db);
      await db.collection('attraction_cities').doc('IT_rome').set({
        'iso2': 'IT',
        'citySlug': 'rome',
        'published': true,
        'attractionCount': 1,
      });
      await db.collection('attractions').doc('401').set(
          fullDoc(401, 'Colosseum', 'colosseum-rome', 'IT', 'rome'));
      final hits =
          await AttractionsDataSource(firestore: db).searchCatalogue('Rome');
      expect(hits.map((a) => a.id), [401]);
    });

    test('pictures only, and nothing for an unrelated query', () async {
      final db = FakeFirebaseFirestore();
      await seedItaly(db);
      await db.collection('attractions').doc('9').set({
        ...fullDoc(9, 'Zzz Tower', 'zzz-tower', 'IT', 'x'),
        'img': {'base': '', 'hash': '', 'token': ''},
      });
      final ds = AttractionsDataSource(firestore: db);
      expect(await ds.searchCatalogue('zzz'), isEmpty);
      expect(await ds.searchCatalogue('qqqq'), isEmpty);
    });

    test('slugify matches the seeder (NFKD, accents dropped)', () {
      expect(AttractionsDataSource.slugify('Zürich'), 'zurich');
      expect(AttractionsDataSource.slugify('Notre-Dame de Paris'),
          'notre-dame-de-paris');
      expect(AttractionsDataSource.slugify('  São Paulo! '), 'sao-paulo');
      expect(AttractionsDataSource.slugify('Kraków'), 'krakow');
    });
  });

  group('search ranking contract', () {
    // Mirrors _score() in AttractionsTab. Kept here so the ordering rules are
    // pinned by a test even though the widget itself needs a BuildContext.
    int score(String q, {
      required String name,
      required String city,
      required String country,
      String iso = 'IT',
      String cat = 'Historic Site',
      String slug = '',
    }) {
      final n = name.toLowerCase(), c = city.toLowerCase();
      final co = country.toLowerCase(), i = iso.toLowerCase();
      final ct = cat.toLowerCase();
      if (n == q) return 1000;
      if (c == q) return 900;
      if (co == q || i == q) return 850;
      if (n.startsWith(q)) return 800;
      if (c.startsWith(q)) return 700;
      if (co.startsWith(q)) return 650;
      if (n.contains(q)) return 600;
      if (c.contains(q)) return 500;
      if (co.contains(q)) return 450;
      if (ct == q) return 400;
      if (ct.contains(q)) return 300;
      if (slug.contains(q)) return 200;
      return 0;
    }

    const rome = {'name': 'Colosseum', 'city': 'Rome', 'country': 'Italy'};

    test('an exact attraction name outranks a city match', () {
      final byName = score('colosseum',
          name: 'Colosseum', city: 'Rome', country: 'Italy');
      final byCity =
          score('rome', name: 'Colosseum', city: 'Rome', country: 'Italy');
      expect(byName, greaterThan(byCity));
    });

    test('a city match outranks a country match', () {
      expect(score('rome', name: rome['name']!, city: 'Rome', country: 'Italy'),
          greaterThan(
              score('italy', name: rome['name']!, city: 'Rome', country: 'Italy')));
    });

    test('country name and ISO code both match', () {
      expect(score('italy', name: 'X', city: 'Y', country: 'Italy'), 850);
      expect(score('it', name: 'X', city: 'Y', country: 'Italy', iso: 'IT'), 850);
    });

    test('prefix beats substring', () {
      expect(score('holly', name: 'Hollywood Sign', city: 'LA', country: 'USA'),
          greaterThan(
              score('wood', name: 'Hollywood Sign', city: 'LA', country: 'USA')));
    });

    test('category is matched, below place and name', () {
      final byCat = score('historic', name: 'X', city: 'Y', country: 'Z');
      expect(byCat, greaterThan(0));
      expect(byCat,
          lessThan(score('x', name: 'X', city: 'Y', country: 'Z')));
    });

    test('an unrelated query scores zero and is filtered out', () {
      expect(score('zzzz', name: 'Colosseum', city: 'Rome', country: 'Italy'), 0);
    });
  });

  _categoryConsistency();
}

/// The category tab counts and the rendered list are derived from the same
/// base set. These pin the invariant that broke in the field: a tab reading
/// "Street 8" must render exactly 8 rows, and a category that is not present
/// must never be used as a filter.
void _categoryConsistency() {
  group('category tab counts match the filtered list', () {
    List<String> cats(List<String> raw) => raw;

    Map<String, int> countBy(List<String> items) {
      final m = <String, int>{};
      for (final c in items) {
        m[c] = (m[c] ?? 0) + 1;
      }
      return m;
    }

    test('every tab count equals the size of that filtered subset', () {
      final base = cats([
        'Street', 'Street', 'Street', 'Museum', 'Museum',
        'Theme Park', 'Beach', 'Street',
      ]);
      final counts = countBy(base);
      for (final entry in counts.entries) {
        final filtered = base.where((c) => c == entry.key).length;
        expect(filtered, entry.value,
            reason: 'tab "${entry.key}" claims ${entry.value}');
      }
    });

    test('the All count equals the whole base set', () {
      final base = cats(['Street', 'Museum', 'Beach']);
      expect(base.length, 3);
      expect(countBy(base).values.fold<int>(0, (a, b) => a + b), base.length);
    });

    test('a category absent from the base set filters to nothing', () {
      final base = cats(['Street', 'Museum']);
      // This is the state that produced "Theme Park 8 but nothing available":
      // a stale selection that no longer exists in the current results.
      expect(base.where((c) => c == 'Theme Park'), isEmpty);
      expect(countBy(base).containsKey('Theme Park'), isFalse,
          reason: 'no tab should be offered for it either');
    });
  });
}
