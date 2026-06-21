import 'package:cloud_firestore/cloud_firestore.dart';

/// City → coordinates lookup, sourced from the `city_coordinates` table the
/// ingester builds from provider destination centers (~3,400+ cities).
///
/// Optimised to be read **at most once per session**: the whole table is loaded
/// lazily on first use and memoised in memory; with Firestore offline
/// persistence enabled, even that first load is served from local cache on
/// subsequent app launches (so it's "one read or less"). Callers should use
/// [ensureLoaded] once, then the synchronous [coordsFor]/[citiesIn] lookups.
class CityCoordinatesService {
  CityCoordinatesService._();
  static final CityCoordinatesService instance = CityCoordinatesService._();

  bool _loaded = false;
  Future<void>? _loading;
  // key: "city|country" (lowercased) → (lat,lng)
  final Map<String, ({double lat, double lng})> _coords = {};
  // country (lowercased) → sorted unique city names
  final Map<String, List<String>> _citiesByCountry = {};

  bool get isLoaded => _loaded;

  /// Loads the table once. Safe to call repeatedly — only the first call hits
  /// Firestore (cache-first); concurrent callers await the same future.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('city_coordinates').get();
      for (final d in snap.docs) {
        final data = d.data();
        final city = (data['city'] as String?)?.trim() ?? '';
        final country = (data['country'] as String?)?.trim() ?? '';
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        if (city.isEmpty || lat == null || lng == null) continue;
        _coords['${city.toLowerCase()}|${country.toLowerCase()}'] =
            (lat: lat, lng: lng);
        final ck = country.toLowerCase();
        (_citiesByCountry[ck] ??= <String>[]).add(city);
      }
      for (final list in _citiesByCountry.values) {
        final uniq = list.toSet().toList()..sort();
        list
          ..clear()
          ..addAll(uniq);
      }
      _loaded = true;
    } catch (_) {
      // best-effort; leave unloaded so a later call can retry
      _loading = null;
    }
  }

  /// Coordinates for a city (optionally disambiguated by country). Null if
  /// unknown or not yet loaded.
  ({double lat, double lng})? coordsFor(String city, {String? country}) {
    final c = city.toLowerCase();
    if (country != null && country.isNotEmpty) {
      final hit = _coords['$c|${country.toLowerCase()}'];
      if (hit != null) return hit;
    }
    for (final entry in _coords.entries) {
      if (entry.key.startsWith('$c|')) return entry.value;
    }
    return null;
  }

  /// Sorted city names available for a country.
  List<String> citiesIn(String country) =>
      _citiesByCountry[country.toLowerCase()] ?? const [];

  /// All countries that have cities in the table.
  List<String> get countries =>
      _citiesByCountry.keys.toList(); // lowercased keys
}
