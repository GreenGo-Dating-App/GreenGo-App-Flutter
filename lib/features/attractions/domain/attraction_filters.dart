import 'entities/attraction.dart';

/// Pure filtering + facet logic for the Attractions tab.
///
/// Kept free of Flutter so the rules the filter sheet, the result list and the
/// "filters active" badge all depend on can be unit-tested directly.

/// Stable key for an attraction's city: the slug when present (unique within a
/// country), otherwise the lower-cased display name.
String attractionCityKey(Attraction a) =>
    a.citySlug.isNotEmpty ? a.citySlug : a.cityName.trim().toLowerCase();

/// Lowest / highest possible GreenGo Score. The full range means "no filter".
const int kAttrScoreMin = 0;
const int kAttrScoreMax = 100;

/// Narrows [list] to attractions whose GreenGo Score lies in
/// [minScore]..[maxScore] (inclusive), that belong to [category] (raw
/// spreadsheet value; null = every category) and to [city] (an
/// [attractionCityKey]; null = every city). Order is preserved.
List<Attraction> filterAttractions(
  List<Attraction> list, {
  int minScore = kAttrScoreMin,
  int maxScore = kAttrScoreMax,
  String? category,
  String? city,
}) {
  final scoreFiltered = minScore > kAttrScoreMin || maxScore < kAttrScoreMax;
  if (!scoreFiltered && category == null && city == null) return list;
  return list.where((a) {
    if (scoreFiltered &&
        (a.greengoScore < minScore || a.greengoScore > maxScore)) {
      return false;
    }
    if (category != null && a.category != category) return false;
    if (city != null && attractionCityKey(a) != city) return false;
    return true;
  }).toList();
}

/// One selectable value in the filter sheet (a category or a city) with the
/// number of attractions carrying it.
class AttractionFacet {
  const AttractionFacet({
    required this.key,
    required this.label,
    required this.count,
    this.icon,
  });

  /// Filter value: raw category, or [attractionCityKey].
  final String key;

  /// Display name (raw category / city name). Categories are localised by the
  /// caller.
  final String label;
  final int count;

  /// Category icon key (see `AttractionIcons.category`); null for cities.
  final String? icon;
}

/// Categories present in [list], most-populated first. Ties are broken by
/// [labelOf] (e.g. the localised name) when given, otherwise by the raw value.
List<AttractionFacet> categoryFacets(
  Iterable<Attraction> list, {
  String Function(String raw)? labelOf,
}) {
  final counts = <String, int>{};
  final icons = <String, String?>{};
  for (final a in list) {
    final c = a.category;
    if (c == null || c.isEmpty) continue;
    counts[c] = (counts[c] ?? 0) + 1;
    icons[c] ??= a.categoryIcon;
  }
  String label(String c) => labelOf == null ? c : labelOf(c);
  final out = counts.keys
      .map((c) => AttractionFacet(
          key: c, label: label(c), count: counts[c]!, icon: icons[c]))
      .toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0 ? byCount : a.label.compareTo(b.label);
    });
  return out;
}

/// Cities present in [list], most-populated first, then alphabetical.
List<AttractionFacet> cityFacets(Iterable<Attraction> list) {
  final counts = <String, int>{};
  final names = <String, String>{};
  for (final a in list) {
    if (a.cityName.trim().isEmpty && a.citySlug.isEmpty) continue;
    final k = attractionCityKey(a);
    counts[k] = (counts[k] ?? 0) + 1;
    names[k] ??= a.cityName.trim().isEmpty ? k : a.cityName.trim();
  }
  final out = counts.keys
      .map((k) => AttractionFacet(key: k, label: names[k]!, count: counts[k]!))
      .toList()
    ..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      return byCount != 0
          ? byCount
          : a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
  return out;
}

/// Everything the filter sheet edits. [countryIso] is the country whose
/// attractions are loaded; the other fields narrow that list.
class AttractionFilterSelection {
  const AttractionFilterSelection({
    required this.countryIso,
    this.minScore = kAttrScoreMin,
    this.maxScore = kAttrScoreMax,
    this.category,
    this.city,
  });

  final String? countryIso;
  final int minScore;
  final int maxScore;
  final String? category;
  final String? city;

  bool get scoreFiltered => minScore > kAttrScoreMin || maxScore < kAttrScoreMax;

  /// True when anything differs from the defaults, where [defaultIso] is the
  /// country the tab would pick on its own.
  bool isActive(String? defaultIso) =>
      scoreFiltered ||
      category != null ||
      city != null ||
      (countryIso != null && countryIso != defaultIso);
}
