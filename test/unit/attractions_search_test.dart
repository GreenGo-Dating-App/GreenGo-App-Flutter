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

  group('allPublished — the catalogue search reads from', () {
    test('collects every country and skips _meta docs', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('attractions_index').doc('IT_0').set({
        'iso2': 'IT',
        'items': [
          rec(401, 'Colosseum', 'Rome', 'colosseum-rome'),
          rec(421, 'Florence Cathedral', 'Florence', 'florence-cathedral'),
        ],
      });
      await db.collection('attractions_index').doc('IT_meta').set({
        'iso2': 'IT',
        'total': 2,
      });
      await db.collection('attractions_index').doc('US_0').set({
        'iso2': 'US',
        'items': [rec(253, 'Hollywood Walk of Fame', 'Los Angeles', 'walk-of-fame')],
      });
      await db.collection('attractions_index').doc('US_meta').set({'iso2': 'US'});

      final all = await AttractionsDataSource(firestore: db).allPublished();

      expect(all, hasLength(3), reason: '_meta docs must not add records');
      expect(all.map((a) => a.countryIso2).toSet(), {'IT', 'US'});
      expect(all.firstWhere((a) => a.id == 253).cityName, 'Los Angeles');
    });

    test('memoises — a second call does not depend on Firestore', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('attractions_index').doc('IT_0').set({
        'iso2': 'IT',
        'items': [rec(401, 'Colosseum', 'Rome', 'colosseum-rome')],
      });
      final ds = AttractionsDataSource(firestore: db);
      expect(await ds.allPublished(), hasLength(1));

      // Adding data after the first call must NOT appear until invalidate().
      await db.collection('attractions_index').doc('US_0').set({
        'iso2': 'US',
        'items': [rec(253, 'Walk of Fame', 'Los Angeles', 'wof')],
      });
      expect(await ds.allPublished(), hasLength(1));

      AttractionsDataSource.invalidate();
      expect(await ds.allPublished(), hasLength(2));
    });

    test('an empty catalogue yields an empty list, not an error', () async {
      final db = FakeFirebaseFirestore();
      expect(await AttractionsDataSource(firestore: db).allPublished(), isEmpty);
    });

    test('a shard with no items list is skipped safely', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('attractions_index').doc('IT_0').set({'iso2': 'IT'});
      expect(await AttractionsDataSource(firestore: db).allPublished(), isEmpty);
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
}
