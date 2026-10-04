import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/display_image.dart';
import '../../domain/country_resolver.dart';
import '../../domain/entities/attraction.dart';

/// Reads curated attractions.
///
/// The feature is country-scoped. A country's compact records live in
/// `attractions_index/{ISO2}_{n}` shards of up to 500, sorted by GreenGo Score
/// (best first), plus `{ISO2}_meta` { shardCount, total }. Since the
/// 2026-10 catalogue (77k attractions, 85 countries) a big country is up to
/// 7 shards / ~1.7 MB, so:
///
///  * the Attractions tab reads ONE country (one query, every shard), then
///    sorts / filters / searches it in memory;
///  * Explore's "Featured attractions" (score > 80) reads only the top
///    shard(s) through [aboveScore] — normally `{ISO2}_0` alone;
///  * "which country am I in" is resolved from the profile's country name or
///    the published countries' bounding boxes first ([resolveCountry]); the
///    ~0.5 MB geo index (`attraction_config/geo`, every city) is read only
///    when those are ambiguous;
///  * search never downloads the catalogue (~45 MB): see [searchCatalogue].
///
/// Everything is memoised for the session and concurrent callers (the
/// background prefetch, the tab, Explore) share one in-flight read.
class AttractionsDataSource {
  AttractionsDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static final Map<String, List<Attraction>> _cache = {};

  /// Country loads in flight, so the background prefetch and the tab (or two
  /// screens) asking for the same country share ONE read.
  static final Map<String, Future<List<Attraction>>> _inflight = {};

  /// [aboveScore] results / loads, keyed `ISO2>minScore`.
  static final Map<String, Future<List<Attraction>>> _top = {};
  static List<AttractionCountry>? _countries;
  static Future<List<AttractionCountry>>? _countriesInflight;
  static String? _bucket;
  static Future<String>? _bucketInflight;

  /// The geo index, already converted to `cities: [[lat, lng], ...]`.
  static List<Map<String, dynamic>>? _geo;
  static Future<List<Map<String, dynamic>>>? _geoInflight;

  /// Full detail records read this session.
  static final Map<int, Attraction> _byId = {};

  /// [searchCatalogue] results, keyed by the normalised query.
  static final Map<String, Future<List<Attraction>>> _search = {};

  /// Cross-catalogue search bounds (see [searchCatalogue]).
  static const int searchNameLimit = 20;
  static const int searchCityLimit = 40;
  static const int searchMaxCities = 3;

  /// Reads that may come from the on-device cache first.
  ///
  /// Index shards and config are immutable-by-version: a stale copy is still a
  /// correct list, so the tab paints instantly on a warm start and the server
  /// copy refreshes in the background. Firestore serves the server value when
  /// the cache is empty.
  static Future<DocumentSnapshot<Map<String, dynamic>>> _docCacheFirst(
      DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final c = await ref.get(const GetOptions(source: Source.cache));
      if (c.exists) {
        ref.get().ignore(); // refresh for next time
        return c;
      }
    } catch (_) {/* empty cache */}
    return ref.get();
  }

  /// Like [_docCacheFirst] for a query. [complete] decides whether the cached
  /// result is the WHOLE answer: the local cache holds whatever documents any
  /// earlier read fetched (e.g. only `{ISO2}_0` from [aboveScore]), and a
  /// partial result must never be shown as the full list.
  static Future<QuerySnapshot<Map<String, dynamic>>> _queryCacheFirst(
      Query<Map<String, dynamic>> q,
      {bool Function(QuerySnapshot<Map<String, dynamic>>)? complete}) async {
    try {
      final c = await q.get(const GetOptions(source: Source.cache));
      if (c.docs.isNotEmpty && (complete == null || complete(c))) {
        q.get().ignore();
        return c;
      }
    } catch (_) {/* empty cache */}
    return q.get();
  }

  /// True when a cached country query holds its `_meta` doc and every shard
  /// that meta announces.
  static bool _shardsComplete(QuerySnapshot<Map<String, dynamic>> s) {
    int? expected;
    var shards = 0;
    for (final d in s.docs) {
      if (d.id.endsWith('_meta')) {
        expected = (d.data()['shardCount'] as num?)?.toInt();
      } else {
        shards++;
      }
    }
    return expected != null && shards >= expected;
  }

  /// Every published country with its bounding box and city coordinates, in a
  /// SINGLE document (`attraction_config/geo`, ~0.5 MB for 37k cities), with
  /// `cities` as [[lat, lng], ...]. Memoised once loaded.
  ///
  /// Prefer [resolveCountry], which needs this only when the cheap signals are
  /// ambiguous. When the doc is missing or unreadable this returns the
  /// published countries' boxes WITHOUT cities (and is retried next call) —
  /// it never falls back to reading the ~37k attraction_cities docs.
  /// (scripts/build_attraction_geo_index.js rebuilds the doc.)
  Future<List<Map<String, dynamic>>> geoIndex() {
    final hit = _geo;
    if (hit != null) return Future.value(hit);
    return _geoInflight ??= _readGeo().whenComplete(() => _geoInflight = null);
  }

  Future<List<Map<String, dynamic>>> _readGeo() async {
    try {
      final d = await _docCacheFirst(
          _db.collection('attraction_config').doc('geo'));
      final list = d.data()?['countries'];
      if (list is List && list.isNotEmpty) {
        // Stored flat ([lat, lng, lat, lng, ...]) because Firestore forbids an
        // array inside an array; callers get [[lat, lng], ...].
        final countries = list.whereType<Map>().map<Map<String, dynamic>>((c) {
          final m = Map<String, dynamic>.from(c);
          final flat = m['cities'];
          if (flat is List && (flat.isEmpty || flat.first is num)) {
            m['cities'] = <List<double>>[
              for (var i = 0; i + 1 < flat.length; i += 2)
                [(flat[i] as num).toDouble(), (flat[i + 1] as num).toDouble()],
            ];
          }
          return m;
        }).toList();
        return _geo = countries;
      }
    } catch (_) {/* fall through to the boxes */}
    final countries = await publishedCountries();
    return [
      for (final c in countries)
        <String, dynamic>{
          'iso2': c.iso2,
          'name': c.name,
          'bbox': c.bbox,
          'cities': const <List<double>>[],
        },
    ];
  }

  /// The published country the user is in, or null.
  ///
  /// Same answer as [CountryResolver.resolve] over the full geo index, but
  /// cheapest signal first:
  ///  1. the profile's country NAME against the published countries (85 tiny
  ///     docs the tab reads anyway) — no geometry at all;
  ///  2. exactly ONE published bounding box contains the point (the full
  ///     resolver would pick that box too);
  ///  3. only otherwise (overlapping boxes near borders, or outside every box)
  ///     the geo index with every city is read.
  Future<String?> resolveCountry(
      {String? countryName, double? lat, double? lng}) async {
    final countries = await publishedCountries();
    if (countries.isEmpty) return null;
    final light = [
      for (final c in countries)
        CountryCandidate(iso2: c.iso2, name: c.name, bbox: c.bbox),
    ];
    final byName =
        CountryResolver.resolve(candidates: light, countryName: countryName);
    if (byName != null) return byName;
    if (lat == null || lng == null) return null;
    final boxed = light.where((c) => c.containsPoint(lat, lng)).toList();
    if (boxed.length == 1) return boxed.first.iso2;
    final geo = await geoIndex();
    return CountryResolver.resolve(
      candidates: [for (final m in geo) CountryCandidate.fromGeo(m)],
      countryName: countryName,
      lat: lat,
      lng: lng,
    );
  }

  /// Storage bucket used to compose image URLs. Read once from
  /// `attraction_config/app` so it can change without an app release.
  Future<String> bucket() {
    final hit = _bucket;
    if (hit != null) return Future.value(hit);
    return _bucketInflight ??= () async {
      try {
        final d = await _docCacheFirst(
            _db.collection('attraction_config').doc('app'));
        _bucket = (d.data()?['storageBucket'] as String?) ??
            'greengo-chat.firebasestorage.app';
      } catch (_) {
        _bucket = 'greengo-chat.firebasestorage.app';
      }
      return _bucket!;
    }()
        .whenComplete(() => _bucketInflight = null);
  }

  /// Countries that currently have published attractions (<= ~100 tiny docs).
  Future<List<AttractionCountry>> publishedCountries() {
    final hit = _countries;
    if (hit != null) return Future.value(hit);
    return _countriesInflight ??= () async {
      try {
        final snap = await _queryCacheFirst(_db
            .collection('attraction_countries')
            .where('published', isEqualTo: true));
        final list = snap.docs.map(AttractionCountry.fromDoc).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        // An empty read is a failure, not "nothing published": retry later.
        if (list.isNotEmpty) _countries = list;
        return list;
      } catch (_) {
        return const <AttractionCountry>[];
      }
    }()
        .whenComplete(() => _countriesInflight = null);
  }

  /// Every published attraction for [iso2] (one query over its shards).
  Future<List<Attraction>> forCountry(String iso2) {
    final key = iso2.toUpperCase();
    final hit = _cache[key];
    if (hit != null) return Future.value(hit);
    // (Block body: returning the removed future from whenComplete would make
    // the load wait on itself.)
    return _inflight[key] ??= _readCountry(key).whenComplete(() {
      _inflight.remove(key);
    });
  }

  /// The memoised list for [iso2] when already loaded (synchronous), else null.
  static List<Attraction>? cachedCountry(String iso2) =>
      _cache[iso2.toUpperCase()];

  /// The storage bucket once [bucket] has resolved it (synchronous), else null.
  static String? get cachedBucket => _bucket;

  static Iterable<Attraction> _parseShard(String iso, Object? items) sync* {
    if (items is! List) return;
    for (final it in items) {
      if (it is Map) {
        yield Attraction.fromIndex({...Map<String, dynamic>.from(it), 'iso': iso});
      }
    }
  }

  Future<List<Attraction>> _readCountry(String key) async {
    try {
      final snap = await _queryCacheFirst(
          _db.collection('attractions_index').where('iso2', isEqualTo: key),
          complete: _shardsComplete);
      final docs = snap.docs.where((d) => !d.id.endsWith('_meta')).toList()
        // Shard order = score order, whatever order the docs arrive in.
        ..sort((a, b) => ((a.data()['shard'] as num?) ?? 0)
            .compareTo((b.data()['shard'] as num?) ?? 0));
      final out = <Attraction>[
        for (final doc in docs)
          // Pictures only (lists, counts, filters and Explore all read here).
          ..._parseShard(key, doc.data()['items']).where(attractionHasPicture),
      ];
      _cache[key] = out;
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// The published attractions of [iso2] with a GreenGo Score above
  /// [minScore] (pictures only), for Explore's "Featured attractions".
  ///
  /// Shards are sorted by score (best first), so this reads `{ISO2}_0` and
  /// stops at the first shard whose lowest score is <= [minScore] — one
  /// ~290 KB document instead of the whole country (up to ~1.7 MB). Exactly
  /// the records [forCountry] would return above that score. Uses the full
  /// country instead when it is already memoised or loading.
  Future<List<Attraction>> aboveScore(String iso2, int minScore) {
    final key = iso2.toUpperCase();
    List<Attraction> filter(List<Attraction> all) =>
        all.where((a) => a.greengoScore > minScore).toList();
    final full = _cache[key];
    if (full != null) return Future.value(filter(full));
    final loading = _inflight[key];
    if (loading != null) return loading.then(filter);
    final memoKey = '$key>$minScore';
    return _top[memoKey] ??= _readAbove(key, minScore).then((list) {
      if (list.isEmpty) _top.remove(memoKey); // retry a failed / empty read
      return list;
    });
  }

  Future<List<Attraction>> _readAbove(String key, int minScore) async {
    final out = <Attraction>[];
    try {
      for (var shard = 0; shard < 64; shard++) {
        final snap = await _docCacheFirst(
            _db.collection('attractions_index').doc('${key}_$shard'));
        final items = snap.data()?['items'];
        if (items is! List || items.isEmpty) break;
        int? lowest;
        for (final a in _parseShard(key, items)) {
          if (lowest == null || a.greengoScore < lowest) lowest = a.greengoScore;
          if (a.greengoScore > minScore && attractionHasPicture(a)) out.add(a);
        }
        if (lowest == null || lowest <= minScore) break;
      }
    } catch (_) {/* what was read so far */}
    return out;
  }

  /// Cross-catalogue search, bounded (the whole catalogue is ~45 MB / 291
  /// shard docs, so it is never downloaded).
  ///
  /// For the normalised [query] it returns, merged by id (pictures only):
  ///  * every attraction of up to 2 published countries NAMED like the query
  ///    ("italy", "it", "ital...") — the memoised [forCountry] list;
  ///  * up to [searchNameLimit] attractions whose slug starts with the query
  ///    ("colosseum" → Colosseum, Rome) — `orderBy(slug)` range, single-field
  ///    index;
  ///  * the best [searchCityLimit] attractions of up to [searchMaxCities]
  ///    cities named exactly like the query ("rome") — `attraction_cities`
  ///    `citySlug ==`, then `attractions` (countryIso2 ==, citySlug ==,
  ///    orderBy greengoScore desc: composite index in firestore.indexes.json).
  ///
  /// The caller still ranks and filters in memory (with the country on
  /// screen). Memoised per query for the session; never throws.
  Future<List<Attraction>> searchCatalogue(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return Future.value(const <Attraction>[]);
    return _search[q] ??= _runSearch(q);
  }

  /// Lower-case ASCII slug exactly as the seeder writes `slug` / `citySlug`
  /// (tools/attractions/seed_firestore.cjs: NFKD, drop the accents, every
  /// other run of non [a-z0-9] -> '-'): "Zürich" -> "zurich",
  /// "Notre-Dame de Paris" -> "notre-dame-de-paris".
  static String slugify(String s) {
    final buf = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final ch = String.fromCharCode(r);
      final c = _accentFold[ch] ?? ch;
      buf.write(_slugChar.hasMatch(c) ? c : '-');
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static final RegExp _slugChar = RegExp(r'^[a-z0-9]$');

  /// Latin letters whose NFKD form is base letter + combining mark (the ones
  /// the seeder's `normalize('NFKD').replace(/[̀-ͯ]/g, '')` turns
  /// into ASCII). Letters that do not decompose (ø, ł, đ, ß, æ) become '-'
  /// there too, so they are deliberately absent.
  static final Map<String, String> _accentFold = () {
    const groups = {
      'a': 'àáâãäåāăą',
      'c': 'çćĉċč',
      'd': 'ď',
      'e': 'èéêëēĕėęě',
      'g': 'ĝğġģ',
      'h': 'ĥ',
      'i': 'ìíîïĩīĭį',
      'j': 'ĵ',
      'k': 'ķ',
      'l': 'ĺļľ',
      'n': 'ñńņňǹ',
      'o': 'òóôõöōŏő',
      'r': 'ŕŗř',
      's': 'śŝşšș',
      't': 'ţťț',
      'u': 'ùúûüũūŭůűų',
      'w': 'ŵ',
      'y': 'ýÿŷ',
      'z': 'źżž',
    };
    return {
      for (final e in groups.entries)
        for (final ch in e.value.split('')) ch: e.key,
    };
  }();

  Future<List<Attraction>> _runSearch(String q) async {
    final found = <int, Attraction>{};
    void addAll(Iterable<Attraction> list) {
      for (final a in list) {
        if (attractionHasPicture(a)) found.putIfAbsent(a.id, () => a);
      }
    }

    final jobs = <Future<void>>[];
    final countries = await publishedCountries();
    final named = countries.where((c) {
      final n = c.name.toLowerCase();
      return n == q ||
          c.iso2.toLowerCase() == q ||
          (q.length >= 3 && n.startsWith(q));
    }).take(2);
    for (final c in named) {
      jobs.add(forCountry(c.iso2).then(addAll));
    }

    final slug = slugify(q);
    if (slug.length >= 3) {
      final attractions = _db.collection('attractions');
      jobs.add(attractions
          .orderBy('slug')
          .startAt([slug])
          .endAt(['$slug'])
          .limit(searchNameLimit)
          .get()
          .then((s) => addAll(s.docs.map(Attraction.fromDoc))));
      jobs.add(() async {
        final cities = await _db
            .collection('attraction_cities')
            .where('citySlug', isEqualTo: slug)
            .limit(10)
            .get();
        final top = cities.docs
            .map((d) => d.data())
            .where((m) => m['published'] != false && m['iso2'] != null)
            .toList()
          ..sort((a, b) => ((b['attractionCount'] as num?) ?? 0)
              .compareTo((a['attractionCount'] as num?) ?? 0));
        await Future.wait([
          for (final c in top.take(searchMaxCities))
            attractions
                .where('countryIso2',
                    isEqualTo: c['iso2'].toString().toUpperCase())
                .where('citySlug', isEqualTo: slug)
                .orderBy('greengoScore', descending: true)
                .limit(searchCityLimit)
                .get()
                .then((s) => addAll(s.docs.map(Attraction.fromDoc))),
        ]);
      }());
    }
    // Each source is best-effort: one failing never blanks the others.
    await Future.wait(jobs.map((j) => j.catchError((Object _) {})));
    final out = found.values.toList();
    if (out.isEmpty) _search.remove(q); // allow a retry (offline, etc.)
    return out;
  }

  /// Full record for the detail screen (1 read, cache-first, memoised).
  Future<Attraction?> byId(int id) async {
    final hit = _byId[id];
    if (hit != null) return hit;
    try {
      final d = await _docCacheFirst(_db.collection('attractions').doc('$id'));
      if (!d.exists) return null;
      return _byId[id] = Attraction.fromDoc(d);
    } catch (_) {
      return null;
    }
  }

  /// Drop memoised data (pull-to-refresh).
  static void invalidate() {
    _cache.clear();
    _inflight.clear();
    _top.clear();
    _countries = null;
    _search.clear();
  }
}
