import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/data/datasources/attractions_datasource.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';

/// One compact record shaped EXACTLY as the seeder writes it into
/// `attractions_index/{ISO2}_0.items` (verified against production data for
/// attraction 401, the Colosseum).
Map<String, dynamic> colosseumRecord() => {
      'i': 401,
      's': 'colosseum-rome',
      'n': 'Colosseum',
      'c': 'Rome',
      'cs': 'rome',
      'cat': 'Historic Site',
      'ci': 'history_edu',
      'cg': 'landmarks',
      'imp': 'world_icon',
      'ii': 'public',
      'la': 41.890277777778,
      'ln': 12.492222222222,
      'b': 'attractions/IT/401',
      'h': '3f9a2b7c',
      'tk': 'tok-123',
      'sc': 99,
      'st': 'iconic',
      'r': 4.7,
      'tp': 21,
      'cu': 'EUR',
      'f': false,
      'u': true,
      'mv': true,
      't10': true,
      'd': 'Colosseum in Rome: historic site.',
      'vd': '1.5-2.5 hours',
      'io': 'Outdoor',
      'wa': 'Partial',
      'at': null,
    };

void main() {
  group('Attraction.fromIndex', () {
    test('parses every field the card and tile render', () {
      final a = Attraction.fromIndex({...colosseumRecord(), 'iso': 'IT'});

      expect(a.id, 401);
      expect(a.name, 'Colosseum');
      expect(a.cityName, 'Rome');
      expect(a.countryIso2, 'IT');
      expect(a.category, 'Historic Site');
      expect(a.categoryIcon, 'history_edu');
      expect(a.categoryGroup, 'landmarks');
      expect(a.importanceKey, 'world_icon');
      expect(a.importanceIcon, 'public');
      expect(a.greengoScore, 99);
      expect(a.scoreTier, 'iconic');
      expect(a.googleRating, 4.7);
      expect(a.ticketPrice, 21);
      expect(a.currency, 'EUR');
      expect(a.freeEntry, isFalse);
      expect(a.unesco, isTrue);
      expect(a.mustVisit, isTrue);
      expect(a.top10Country, isTrue);
      expect(a.visitDuration, '1.5-2.5 hours');
      expect(a.wheelchairAccessible, 'Partial');
      expect(a.lat, closeTo(41.8903, 0.001));
      expect(a.lng, closeTo(12.4922, 0.001));
      expect(a.needsAttribution, isFalse);
    });

    test('composes a Storage download URL per variant', () {
      final a = Attraction.fromIndex({...colosseumRecord(), 'iso': 'IT'});
      final url = a.imageUrl('hero', bucket: 'greengo-chat.firebasestorage.app');

      // Path must be percent-encoded or Storage returns 404.
      expect(url, contains('attractions%2FIT%2F401%2Fhero-3f9a2b7c.webp'));
      expect(url, contains('alt=media'));
      expect(url, contains('token=tok-123'));
      expect(a.imageUrl('thumb', bucket: 'b'), contains('thumb-3f9a2b7c.webp'));
    });

    test('surfaces attribution only when the licence demands it', () {
      final free = Attraction.fromIndex({...colosseumRecord(), 'iso': 'IT'});
      expect(free.needsAttribution, isFalse);

      final credited = Attraction.fromIndex({
        ...colosseumRecord(),
        'iso': 'IT',
        'at': {'a': 'Jane Doe', 'l': 'CC BY-SA 4.0'},
      });
      expect(credited.needsAttribution, isTrue);
      expect(credited.attributionAuthor, 'Jane Doe');
      expect(credited.attributionLicense, 'CC BY-SA 4.0');
    });

    test('tolerates a record missing optional fields', () {
      final a = Attraction.fromIndex({'i': 1, 'n': 'X', 'iso': 'IT'});
      expect(a.id, 1);
      expect(a.greengoScore, 0);
      expect(a.freeEntry, isFalse);
      expect(a.lat, isNull);
      expect(a.needsAttribution, isFalse);
    });
  });

  group('AttractionsDataSource', () {
    setUp(AttractionsDataSource.invalidate);

    test('reads a country from its index shard and skips the _meta doc',
        () async {
      final db = FakeFirebaseFirestore();
      await db.collection('attractions_index').doc('IT_0').set({
        'iso2': 'IT',
        'shard': 0,
        'items': [colosseumRecord()],
      });
      await db.collection('attractions_index').doc('IT_meta').set({
        'iso2': 'IT',
        'shardCount': 1,
        'total': 1,
      });

      final list = await AttractionsDataSource(firestore: db).forCountry('IT');

      // _meta carries no `items`; it must not produce a phantom attraction.
      expect(list, hasLength(1));
      expect(list.first.name, 'Colosseum');
      expect(list.first.countryIso2, 'IT');
    });

    test('returns only published countries, sorted by name', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('attraction_countries').doc('IT').set(
          {'iso2': 'IT', 'name': 'Italy', 'published': true, 'publishedCount': 100});
      await db.collection('attraction_countries').doc('BR').set(
          {'iso2': 'BR', 'name': 'Brazil', 'published': true, 'publishedCount': 87});
      await db.collection('attraction_countries').doc('FR').set(
          {'iso2': 'FR', 'name': 'France', 'published': false, 'publishedCount': 0});

      final c = await AttractionsDataSource(firestore: db).publishedCountries();

      expect(c.map((e) => e.iso2), ['BR', 'IT']);
      expect(c.first.total, 87);
    });

    test('an unknown country yields an empty list, not an error', () async {
      final db = FakeFirebaseFirestore();
      expect(await AttractionsDataSource(firestore: db).forCountry('ZZ'), isEmpty);
    });
  });
}
