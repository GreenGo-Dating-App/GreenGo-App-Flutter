import 'dart:convert';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/utils/display_image.dart';
import 'package:greengo_chat/features/attractions/data/attractions_lite_codec.dart';
import 'package:greengo_chat/features/attractions/data/datasources/attractions_datasource.dart';
import 'package:greengo_chat/features/attractions/domain/entities/attraction.dart';

/// The LITE list layout (`attractions_lite`, scripts/build_attractions_lite.js).
///
/// test/fixtures/attractions_lite_fixture.json was produced by the script's
/// own `buildCountry()` over a sample of the production `attractions_index`
/// records (image tokens / hashes replaced, plus synthetic edge cases: a
/// non-UUID token, an off-table tier, a custom image base, a '|' in the
/// data). Both languages read the SAME file, so the Dart decoder is checked
/// against exactly what the Node encoder writes.
Map<String, dynamic> _fixture() => jsonDecode(
        File('test/fixtures/attractions_lite_fixture.json').readAsStringSync())
    as Map<String, dynamic>;

List<Map<String, dynamic>> _countries() => [
      for (final c in _fixture()['countries'] as List)
        Map<String, dynamic>.from(c as Map),
    ];

Map<String, dynamic> _country(String iso) =>
    _countries().firstWhere((c) => c['iso'] == iso);

List<Map<String, dynamic>> _liteDocs(Map<String, dynamic> c) => [
      for (final d in c['lite'] as List) Map<String, dynamic>.from(d as Map),
    ];

const _bucket = 'greengo-chat.firebasestorage.app';

void main() {
  group('AttractionsLiteShard.parse (fixture written by the Node builder)', () {
    for (final c in _countries()) {
      final iso = c['iso'] as String;
      test('$iso: every list field equals the index record', () {
        final src = [
          for (final it in c['items'] as List)
            Attraction.fromIndex({...Map<String, dynamic>.from(it as Map), 'iso': iso}),
        ];
        final lite = [
          for (final d in _liteDocs(c))
            ...AttractionsLiteShard.parse(d, iso2: iso)!.items,
        ];
        expect(lite.map((a) => a.id), src.map((a) => a.id),
            reason: 'same records, same (score) order');
        for (var k = 0; k < src.length; k++) {
          final w = src[k], g = lite[k];
          final why = '$iso id ${w.id}';
          expect(g.slug, w.slug, reason: why);
          expect(g.name, w.name, reason: why);
          expect(g.cityName, w.cityName, reason: why);
          expect(g.citySlug, w.citySlug, reason: why);
          expect(g.countryIso2, iso, reason: why);
          expect(g.category, w.category, reason: why);
          expect(g.categoryIcon, w.categoryIcon, reason: why);
          expect(g.importanceKey, w.importanceKey, reason: why);
          expect(g.importanceIcon, w.importanceIcon, reason: why);
          expect(g.greengoScore, w.greengoScore, reason: why);
          expect(g.scoreTier, w.scoreTier, reason: why);
          expect(g.googleRating, w.googleRating, reason: why);
          final paid = (w.ticketPrice ?? 0) > 0;
          expect(g.ticketPrice, paid ? w.ticketPrice : null, reason: why);
          expect(g.currency, paid ? w.currency : null, reason: why);
          expect(g.freeEntry, w.freeEntry, reason: why);
          expect(g.unesco, w.unesco, reason: why);
          expect(g.mustVisit, w.mustVisit, reason: why);
          expect(g.top10Country, w.top10Country, reason: why);
          expect(g.visitDuration, w.visitDuration, reason: why);
          expect(g.attributionAuthor, w.attributionAuthor, reason: why);
          expect(g.attributionLicense, w.attributionLicense, reason: why);
          expect(g.needsAttribution, w.needsAttribution, reason: why);
          if (w.lat == null) {
            expect(g.lat, isNull, reason: why);
          } else {
            expect(g.lat, closeTo(w.lat!, 6e-6), reason: why);
            expect(g.lng, closeTo(w.lng!, 6e-6), reason: why);
          }
          // Images: the SAME URL => the same CachedNetworkImage / ImageCache
          // entry (FirstScreenGate precache, warm-up and the tiles agree).
          expect(g.imgBase, w.imgBase, reason: why);
          expect(g.imgHash, w.imgHash, reason: why);
          expect(g.imgToken, w.imgToken, reason: why);
          for (final v in ['micro', 'thumb', 'card', 'hero']) {
            expect(g.imageUrl(v, bucket: _bucket), w.imageUrl(v, bucket: _bucket),
                reason: why);
          }
          expect(attractionHasPicture(g), attractionHasPicture(w), reason: why);
          // Description: exact (templated ones are rebuilt in full, whatever
          // their length), or a verbatim one capped at 120 chars + ellipsis.
          final d = w.descriptionShort;
          if (d == null || d.length <= 120 || g.descriptionShort == d) {
            expect(g.descriptionShort, d, reason: why);
          } else {
            expect(g.descriptionShort!.length, lessThanOrEqualTo(120), reason: why);
            expect(g.descriptionShort, endsWith('…'), reason: why);
            expect(d.startsWith(g.descriptionShort!.replaceAll('…', '')),
                isTrue,
                reason: why);
          }
          // Detail-only: loaded from attractions/{id} on the detail page.
          expect(g.descriptionMedium, isNull);
          expect(g.categoryGroup, isNull);
        }
      });
    }

    test('the fixture covers the edge cases it claims', () {
      final all = [
        for (final c in _countries())
          for (final d in _liteDocs(c)) d,
      ];
      expect(all.map((d) => d['sep']).toSet(), containsAll(['|', '~']));
      final it = _country('IT');
      final lite = AttractionsLiteShard.parse(_liteDocs(it).first)!;
      final odd = lite.items.firstWhere((a) => a.id == 999001);
      expect(odd.imgToken, 'legacy-token-not-a-uuid');
      expect(odd.scoreTier, 'great', reason: 'off-table tier kept verbatim');
      expect(odd.imgBase, 'custom/base/path');
      expect(odd.lat, isNull);
      expect(odd.descriptionShort, isNull);
    });

    test('a doc of another format is ignored (caller falls back)', () {
      final d = _liteDocs(_country('IT')).first;
      expect(AttractionsLiteShard.parse({...d, 'format': 2}), isNull);
      expect(AttractionsLiteShard.header({...d, 'format': 2}), isNull);
      expect(AttractionsLiteShard.parse(null), isNull);
      expect(AttractionsLiteShard.parse({...d, 'shard': 3}), isNull,
          reason: 'shard outside 0..shards-1');
    });

    test('columns are read by name: an unknown extra column is harmless', () {
      final d = _liteDocs(_country('IT')).first;
      final sep = d['sep'] as String;
      final widened = {
        ...d,
        'cols': [...(d['cols'] as List), 'zz'],
        'rows': [
          for (final r in d['rows'] as List)
            // Pad the trimmed row to every column, then add the new one.
            [
              ...(r as String).split(sep),
              ...List.filled(
                  (d['cols'] as List).length - r.split(sep).length, ''),
              'future',
            ].join(sep),
        ],
      };
      final a = AttractionsLiteShard.parse(d)!.items;
      final b = AttractionsLiteShard.parse(widened)!.items;
      expect(b.map((x) => x.imageUrl('thumb', bucket: _bucket)),
          a.map((x) => x.imageUrl('thumb', bucket: _bucket)));
      expect(b.map((x) => x.descriptionShort), a.map((x) => x.descriptionShort));
    });
  });

  group('lite helpers (must match scripts/build_attractions_lite.js)', () {
    test('liteSlug', () {
      expect(AttractionsLiteShard.liteSlug("Port d'Envalira"), 'port-denvalira');
      expect(AttractionsLiteShard.liteSlug('Château d’If'), 'chateau-dif');
      expect(AttractionsLiteShard.liteSlug('Zürich'), 'zurich');
      expect(AttractionsLiteShard.liteSlug('  Notre-Dame de Paris! '),
          'notre-dame-de-paris');
    });

    test('unpackUuid', () {
      expect(AttractionsLiteShard.unpackUuid('EjRWeJq8Te-BI0VniavN7w'),
          '12345678-9abc-4def-8123-456789abcdef');
      expect(AttractionsLiteShard.unpackUuid('short'), isNull);
      expect(AttractionsLiteShard.unpackUuid('legacy-token-not-a-uu'), isNull);
    });

    test('tierForScore follows attraction_config/app scoreTiers', () {
      expect(AttractionsLiteShard.tierForScore(97), 'iconic');
      expect(AttractionsLiteShard.tierForScore(90), 'iconic');
      expect(AttractionsLiteShard.tierForScore(80), 'exceptional');
      expect(AttractionsLiteShard.tierForScore(70), 'excellent');
      expect(AttractionsLiteShard.tierForScore(60), 'great');
      expect(AttractionsLiteShard.tierForScore(59), 'worth_visit');
    });
  });

  group('AttractionCountry.lite (manifest)', () {
    AttractionCountry country(Map<String, dynamic>? lite, {int? indexVersion}) =>
        AttractionCountry(
          iso2: 'IT',
          name: 'Italy',
          total: 1,
          indexVersion: indexVersion,
          liteManifest: AttractionLiteManifest.fromMap(lite),
        );

    test('current manifest is used', () {
      final m = country({'format': 1, 'shards': 1, 'version': 'v1', 'src': 7},
          indexVersion: 7);
      expect(m.lite?.version, 'v1');
    });

    test('missing / stale / unknown-format manifest => full shards', () {
      expect(country(null).lite, isNull);
      expect(
          country({'format': 1, 'shards': 1, 'version': 'v1', 'src': 6},
                  indexVersion: 7)
              .lite,
          isNull,
          reason: 'built from an older index (a reseed since)');
      expect(
          country({'format': 9, 'shards': 1, 'version': 'v1', 'src': 7},
                  indexVersion: 7)
              .lite,
          isNull);
      expect(country({'format': 1, 'shards': 0, 'version': 'v1'}).lite, isNull);
      expect(country({'format': '1'}).lite, isNull);
    });
  });

  group('AttractionsDataSource with the lite layout', () {
    setUp(AttractionsDataSource.invalidate);

    const iso = 'IT';
    const src = 1791095739508;

    /// The index shard holds ONE marker record, so a test can tell which
    /// layout a list came from.
    Future<FakeFirebaseFirestore> seed({
      bool manifest = true,
      bool liteDocs = true,
      Map<String, dynamic> manifestOverride = const {},
      int indexVersion = src,
    }) async {
      final db = FakeFirebaseFirestore();
      final c = _country(iso);
      final docs = _liteDocs(c);
      await db.collection('attraction_countries').doc(iso).set({
        'iso2': iso,
        'name': 'Italy',
        'published': true,
        'indexVersion': indexVersion,
        if (manifest)
          'lite': {
            'format': 1,
            'shards': docs.length,
            'version': docs.first['version'],
            'src': src,
            ...manifestOverride,
          },
      });
      if (liteDocs) {
        for (final d in docs) {
          await db
              .collection('attractions_lite')
              .doc('${iso}_${d['shard']}')
              .set(d);
        }
      }
      final marker = Map<String, dynamic>.from((c['items'] as List).first as Map)
        ..['i'] = 1
        ..['n'] = 'FROM INDEX';
      await db.collection('attractions_index').doc('${iso}_0').set({
        'iso2': iso,
        'shard': 0,
        'items': [marker],
      });
      await db
          .collection('attractions_index')
          .doc('${iso}_meta')
          .set({'iso2': iso, 'shardCount': 1, 'total': 1, 'version': src});
      return db;
    }

    List<int> liteIds() => [
          for (final it in _country(iso)['items'] as List)
            ((it as Map)['i'] as num).toInt(),
        ];

    test('forCountry reads the lite build when the manifest is current',
        () async {
      final db = await seed();
      final list = await AttractionsDataSource(firestore: db).forCountry(iso);
      expect(list.map((a) => a.id), liteIds());
      expect(list.first.countryIso2, iso);
    });

    test('no manifest => the full index shards', () async {
      final db = await seed(manifest: false);
      final list = await AttractionsDataSource(firestore: db).forCountry(iso);
      expect(list.map((a) => a.name), ['FROM INDEX']);
    });

    test('manifest but no lite docs (e.g. rules / not built) => index',
        () async {
      final db = await seed(liteDocs: false);
      final list = await AttractionsDataSource(firestore: db).forCountry(iso);
      expect(list.map((a) => a.name), ['FROM INDEX']);
    });

    test('stale manifest (reseeded since the lite build) => index', () async {
      final db = await seed(indexVersion: src + 1);
      final list = await AttractionsDataSource(firestore: db).forCountry(iso);
      expect(list.map((a) => a.name), ['FROM INDEX']);
    });

    test('incomplete lite build is never shown as the list => index',
        () async {
      final db = await seed();
      // The stored shard claims a 2-shard build whose shard 1 is missing.
      await db
          .collection('attractions_lite')
          .doc('${iso}_0')
          .update({'shards': 2});
      final list = await AttractionsDataSource(firestore: db).forCountry(iso);
      expect(list.map((a) => a.name), ['FROM INDEX']);
    });

    test('aboveScore uses the lite build and memoises the whole country',
        () async {
      final db = await seed();
      final ds = AttractionsDataSource(firestore: db);
      final top = await ds.aboveScore(iso, 80);
      final all = AttractionsDataSource.cachedCountry(iso);
      expect(all, isNotNull, reason: 'one lite doc = the whole country');
      expect(all!.map((a) => a.id), liteIds());
      expect(top.map((a) => a.id),
          all.where((a) => a.greengoScore > 80).map((a) => a.id));
      expect(top, isNotEmpty);
    });

    test('aboveScore without a manifest still reads the index', () async {
      final db = await seed(manifest: false);
      final top = await AttractionsDataSource(firestore: db).aboveScore(iso, 0);
      expect(top.map((a) => a.name), ['FROM INDEX']);
    });
  });
}
