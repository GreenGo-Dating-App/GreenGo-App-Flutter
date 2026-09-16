import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/attraction.dart';

/// Reads curated attractions.
///
/// The whole feature is country-scoped, so a country is at most ~100 records —
/// they arrive in ONE document read from `attractions_index/{ISO2}_{n}` and are
/// then sorted/filtered/searched entirely in memory. No pagination, no geohash
/// rings, no composite queries on the list path.
///
/// Results are memoised per country for the session, so switching between the
/// home and travel country is instant after the first load.
class AttractionsDataSource {
  AttractionsDataSource({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static final Map<String, List<Attraction>> _cache = {};
  static List<AttractionCountry>? _countries;
  static List<Attraction>? _all;
  static String? _bucket;
  static Map<String, dynamic>? _geo;

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

  static Future<QuerySnapshot<Map<String, dynamic>>> _queryCacheFirst(
      Query<Map<String, dynamic>> q) async {
    try {
      final c = await q.get(const GetOptions(source: Source.cache));
      if (c.docs.isNotEmpty) {
        q.get().ignore();
        return c;
      }
    } catch (_) {/* empty cache */}
    return q.get();
  }

  /// Every published country with its bounding box and city coordinates, in a
  /// SINGLE document (`attraction_config/geo`). Replaces reading ~700 city docs
  /// plus ~60 country docs on every open. Falls back to those collections when
  /// the doc is missing (e.g. before the next seed run).
  Future<List<Map<String, dynamic>>> geoIndex() async {
    if (_geo != null) {
      return (_geo!['countries'] as List).cast<Map<String, dynamic>>();
    }
    try {
      final d = await _docCacheFirst(_db.collection('attraction_config').doc('geo'));
      final data = d.data();
      final list = data?['countries'];
      if (list is List && list.isNotEmpty) {
        _geo = data;
        // Stored flat ([lat, lng, lat, lng, ...]) because Firestore forbids an
        // array inside an array; callers get [[lat, lng], ...] either way.
        return list.map<Map<String, dynamic>>((c) {
          final m = Map<String, dynamic>.from(c as Map);
          final flat = m['cities'];
          if (flat is List && (flat.isEmpty || flat.first is num)) {
            final pairs = <List<double>>[];
            for (var i = 0; i + 1 < flat.length; i += 2) {
              pairs.add([(flat[i] as num).toDouble(), (flat[i + 1] as num).toDouble()]);
            }
            m['cities'] = pairs;
          }
          return m;
        }).toList();
      }
    } catch (_) {/* fall through to the per-collection reads */}
    return _geoIndexFallback();
  }

  Future<List<Map<String, dynamic>>> _geoIndexFallback() async {
    try {
      final cities = await _queryCacheFirst(
          _db.collection('attraction_cities').where('published', isEqualTo: true));
      final byIso = <String, List<List<double>>>{};
      for (final d in cities.docs) {
        final m = d.data();
        final iso = (m['iso2'] as String?)?.toUpperCase();
        final la = (m['lat'] as num?)?.toDouble();
        final ln = (m['lng'] as num?)?.toDouble();
        if (iso == null || la == null || ln == null) continue;
        (byIso[iso] ??= []).add([la, ln]);
      }
      final countries = await _queryCacheFirst(
          _db.collection('attraction_countries').where('published', isEqualTo: true));
      return countries.docs.map((d) {
        final m = d.data();
        final iso = (m['iso2'] ?? d.id).toString().toUpperCase();
        return <String, dynamic>{
          'iso2': iso,
          'name': (m['name'] ?? iso).toString(),
          'bbox': m['bbox'],
          'cities': byIso[iso] ?? const <List<double>>[],
        };
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Storage bucket used to compose image URLs. Read once from
  /// `attraction_config/app` so it can change without an app release.
  Future<String> bucket() async {
    if (_bucket != null) return _bucket!;
    try {
      final d = await _docCacheFirst(_db.collection('attraction_config').doc('app'));
      _bucket = (d.data()?['storageBucket'] as String?) ??
          'greengo-chat.firebasestorage.app';
    } catch (_) {
      _bucket = 'greengo-chat.firebasestorage.app';
    }
    return _bucket!;
  }

  /// Countries that currently have published attractions (<= a few dozen docs).
  Future<List<AttractionCountry>> publishedCountries() async {
    if (_countries != null) return _countries!;
    try {
      final snap = await _queryCacheFirst(_db
          .collection('attraction_countries')
          .where('published', isEqualTo: true));
      final list = snap.docs.map(AttractionCountry.fromDoc).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      _countries = list;
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Every published attraction for [iso2]. One doc read per shard; a country
  /// holds at most 100 records so this is normally a single read.
  Future<List<Attraction>> forCountry(String iso2) async {
    final key = iso2.toUpperCase();
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final snap = await _queryCacheFirst(
          _db.collection('attractions_index').where('iso2', isEqualTo: key));
      final out = <Attraction>[];
      for (final doc in snap.docs) {
        if (doc.id.endsWith('_meta')) continue;
        final items = doc.data()['items'];
        if (items is! List) continue;
        for (final it in items) {
          if (it is Map) {
            out.add(Attraction.fromIndex(
                {...Map<String, dynamic>.from(it), 'iso': key}));
          }
        }
      }
      _cache[key] = out;
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Every published attraction, across all countries.
  ///
  /// Used only when the user searches: search must be able to answer "Rome",
  /// "Italy" or "Colosseum" regardless of which country the tab is scoped to.
  /// The whole catalogue is ~3,500 compact records across 50 shard documents
  /// (<1 MB), read once and memoised for the session, so this costs one burst
  /// of reads on the first search and nothing afterwards.
  Future<List<Attraction>> allPublished() async {
    if (_all != null) return _all!;
    try {
      final snap = await _queryCacheFirst(_db.collection('attractions_index'));
      final out = <Attraction>[];
      for (final doc in snap.docs) {
        if (doc.id.endsWith('_meta')) continue;
        final data = doc.data();
        final iso = (data['iso2'] as String?)?.toUpperCase() ?? '';
        final items = data['items'];
        if (items is! List) continue;
        for (final it in items) {
          if (it is Map) {
            out.add(Attraction.fromIndex(
                {...Map<String, dynamic>.from(it), 'iso': iso}));
          }
        }
      }
      _all = out;
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Full record for the detail screen (1 read).
  Future<Attraction?> byId(int id) async {
    try {
      final d = await _db.collection('attractions').doc('$id').get();
      if (!d.exists) return null;
      return Attraction.fromDoc(d);
    } catch (_) {
      return null;
    }
  }

  /// Drop memoised data (pull-to-refresh).
  static void invalidate() {
    _cache.clear();
    _countries = null;
    _all = null;
  }
}
