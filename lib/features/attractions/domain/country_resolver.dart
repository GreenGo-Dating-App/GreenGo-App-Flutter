import '../../../core/utils/geo_query.dart';

/// One published country, with whatever hints we have for deciding whether a
/// given position sits inside it.
class CountryCandidate {
  const CountryCandidate({
    required this.iso2,
    required this.name,
    this.bbox, // [south, west, north, east]
    this.cities = const [],
  });

  final String iso2;
  final String name;
  final List<double>? bbox;

  /// (lat, lng) of that country's published cities.
  final List<(double, double)> cities;

  bool containsPoint(double lat, double lng) {
    final b = bbox;
    if (b == null || b.length != 4) return false;
    return lat >= b[0] && lat <= b[2] && lng >= b[1] && lng <= b[3];
  }

  /// Metres to the closest published city, or null when we have none.
  double? distanceToNearestCity(double lat, double lng) {
    double? best;
    for (final c in cities) {
      final d = GeoQuery.distanceMeters(lat, lng, c.$1, c.$2);
      if (best == null || d < best) best = d;
    }
    return best;
  }
}

/// Decides which published country a user is in.
///
/// Deliberately layered so that a weak signal can never produce a WRONG answer,
/// only "no answer", which then falls through to the next tier:
///
///  1. the country NAME on the user's profile location — definitive when present
///  2. among countries whose bounding box contains the point, the one with the
///     nearest city (boxes overlap near borders, so the box alone is not enough)
///  3. nearest published city overall, with NO distance cap
///
/// Tier 3 matters: bounding boxes are derived from our own attraction
/// coordinates, so they under-cover large countries (a user in Seattle sits
/// outside the US box because our northernmost US city is Boston). Falling
/// through to "nearest city wins" resolves those correctly.
class CountryResolver {
  const CountryResolver._();

  /// Common ways a country name is written, mapped to how our registry spells
  /// it. Compared case-insensitively after stripping punctuation.
  static const Map<String, String> _aliases = {
    'usa': 'united states',
    'us': 'united states',
    'u s a': 'united states',
    'united states of america': 'united states',
    'america': 'united states',
    'uk': 'united kingdom',
    'great britain': 'united kingdom',
    'britain': 'united kingdom',
    'england': 'united kingdom',
    'scotland': 'united kingdom',
    'wales': 'united kingdom',
    'uae': 'united arab emirates',
    'emirates': 'united arab emirates',
    'czech republic': 'czechia',
    'holland': 'netherlands',
    'south korea': 'south korea',
    'korea': 'south korea',
    'republic of korea': 'south korea',
    'brasil': 'brazil',
    'italia': 'italy',
    'espana': 'spain',
    'españa': 'spain',
    'deutschland': 'germany',
    'suisse': 'switzerland',
    'schweiz': 'switzerland',
    'osterreich': 'austria',
    'österreich': 'austria',
  };

  static String _norm(String s) {
    final lower = s.toLowerCase().trim();
    final buf = StringBuffer();
    for (final r in lower.runes) {
      final c = String.fromCharCode(r);
      buf.write(RegExp(r'[a-z0-9À-ɏ ]').hasMatch(c) ? c : ' ');
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// [countryName] is the free-text country from the profile location; it may be
  /// null, a display name, or an ISO code.
  static String? resolve({
    required List<CountryCandidate> candidates,
    String? countryName,
    double? lat,
    double? lng,
  }) {
    if (candidates.isEmpty) return null;

    // --- tier 1: the name we were given -------------------------------------
    if (countryName != null && countryName.trim().isNotEmpty) {
      final raw = _norm(countryName);
      final key = _aliases[raw] ?? raw;
      for (final c in candidates) {
        if (_norm(c.name) == key) return c.iso2;
      }
      // An ISO2 code may arrive in the country field instead of a name.
      if (raw.length == 2) {
        for (final c in candidates) {
          if (c.iso2.toLowerCase() == raw) return c.iso2;
        }
      }
    }

    if (lat == null || lng == null) return null;

    // --- tier 2: bounding box, disambiguated by nearest city ----------------
    CountryCandidate? boxed;
    double boxedDist = double.infinity;
    for (final c in candidates) {
      if (!c.containsPoint(lat, lng)) continue;
      final d = c.distanceToNearestCity(lat, lng) ?? double.infinity;
      if (d < boxedDist) {
        boxedDist = d;
        boxed = c;
      }
    }
    if (boxed != null) return boxed.iso2;

    // --- tier 3: nearest published city, no cap -----------------------------
    CountryCandidate? nearest;
    double nearestDist = double.infinity;
    for (final c in candidates) {
      final d = c.distanceToNearestCity(lat, lng);
      if (d != null && d < nearestDist) {
        nearestDist = d;
        nearest = c;
      }
    }
    return nearest?.iso2;
  }
}
