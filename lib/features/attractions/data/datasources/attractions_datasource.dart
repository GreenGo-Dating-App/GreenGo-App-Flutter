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

  /// Storage bucket used to compose image URLs. Read once from
  /// `attraction_config/app` so it can change without an app release.
  Future<String> bucket() async {
    if (_bucket != null) return _bucket!;
    try {
      final d = await _db.collection('attraction_config').doc('app').get();
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
      final snap = await _db
          .collection('attraction_countries')
          .where('published', isEqualTo: true)
          .get();
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
      final snap = await _db
          .collection('attractions_index')
          .where('iso2', isEqualTo: key)
          .get();
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
      final snap = await _db.collection('attractions_index').get();
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
