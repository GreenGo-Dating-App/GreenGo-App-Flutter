import 'package:cloud_firestore/cloud_firestore.dart';

/// A curated attraction from the GreenGo dataset.
///
/// Two shapes exist for the SAME entity:
///  • the compact record inside `attractions_index/{ISO2}_{n}.items` — carries
///    everything the list/cards need, so a whole country lists in ONE doc read;
///  • the full `attractions/{id}` doc — read only when a detail screen opens.
///
/// Image URLs are COMPOSED from {base, hash, token} rather than stored, which
/// keeps each compact record ~260 bytes.
class Attraction {
  const Attraction({
    required this.id,
    required this.slug,
    required this.name,
    required this.cityName,
    required this.citySlug,
    required this.countryIso2,
    required this.imgBase,
    required this.imgHash,
    required this.imgToken,
    this.officialName,
    this.category,
    this.categoryIcon,
    this.categoryGroup,
    this.importanceLevel,
    this.importanceKey,
    this.importanceIcon,
    this.greengoScore = 0,
    this.scoreTier,
    this.googleRating,
    this.lat,
    this.lng,
    this.ticketPrice,
    this.currency,
    this.freeEntry = false,
    this.unesco = false,
    this.mustVisit = false,
    this.top10Country = false,
    this.descriptionShort,
    this.visitDuration,
    this.indoorOutdoor,
    this.wheelchairAccessible,
    this.attributionAuthor,
    this.attributionLicense,
    // detail-only
    this.descriptionMedium,
    this.descriptionLong,
    this.historySummary,
    this.topHighlights = const [],
    this.photographyTips,
    this.interestingFacts = const [],
    this.altText,
    this.openingHours,
    this.bestSeason,
    this.bestTimeOfDay,
    this.streetAddress,
    this.annualVisitors,
    this.safetyLevel,
    this.petFriendly,
    this.timezone,
    this.photographyScore,
    this.historicalScore,
    this.architecturalScore,
    this.naturalScore,
    this.countryName,
  });

  final int id;
  final String slug;
  final String name;
  final String? officialName;
  final String cityName;
  final String citySlug;
  final String countryIso2;
  final String? countryName;

  final String? category;
  final String? categoryIcon;
  final String? categoryGroup;
  final String? importanceLevel;
  final String? importanceKey;
  final String? importanceIcon;

  final int greengoScore;
  final String? scoreTier;
  final double? googleRating;

  final double? lat;
  final double? lng;

  final double? ticketPrice;
  final String? currency;
  final bool freeEntry;
  final bool unesco;
  final bool mustVisit;
  final bool top10Country;

  final String? descriptionShort;
  final String? visitDuration;
  final String? indoorOutdoor;
  final String? wheelchairAccessible;

  /// Only set when the image licence requires a visible credit.
  final String? attributionAuthor;
  final String? attributionLicense;

  final String imgBase;
  final String imgHash;
  final String imgToken;

  // Detail-only fields (null when built from a compact index record).
  final String? descriptionMedium;
  final String? descriptionLong;
  final String? historySummary;
  final List<String> topHighlights;
  final String? photographyTips;
  final List<String> interestingFacts;
  final String? altText;
  final String? openingHours;
  final String? bestSeason;
  final String? bestTimeOfDay;
  final String? streetAddress;
  final String? annualVisitors;
  final String? safetyLevel;
  final String? petFriendly;
  final String? timezone;
  final int? photographyScore;
  final int? historicalScore;
  final int? architecturalScore;
  final int? naturalScore;

  bool get needsAttribution =>
      attributionAuthor != null && attributionAuthor!.isNotEmpty;

  /// Firebase Storage download URL for a variant: micro | thumb | card | hero.
  String imageUrl(String variant, {required String bucket}) {
    final p = Uri.encodeComponent('$imgBase/$variant-$imgHash.webp');
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$p'
        '?alt=media&token=$imgToken';
  }

  static double? _d(dynamic v) => v is num ? v.toDouble() : null;
  static int _i(dynamic v) => v is num ? v.toInt() : 0;
  static String? _s(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<String> _list(dynamic v) =>
      v is List ? v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
                : const [];

  /// Build from one compact record inside an index shard.
  factory Attraction.fromIndex(Map<String, dynamic> m) {
    final at = m['at'];
    return Attraction(
      id: _i(m['i']),
      slug: _s(m['s']) ?? '',
      name: _s(m['n']) ?? '',
      cityName: _s(m['c']) ?? '',
      citySlug: _s(m['cs']) ?? '',
      countryIso2: _s(m['iso']) ?? _s(m['k']) ?? '',
      category: _s(m['cat']),
      categoryIcon: _s(m['ci']),
      categoryGroup: _s(m['cg']),
      importanceKey: _s(m['imp']),
      importanceIcon: _s(m['ii']),
      lat: _d(m['la']),
      lng: _d(m['ln']),
      imgBase: _s(m['b']) ?? '',
      imgHash: _s(m['h']) ?? '',
      imgToken: _s(m['tk']) ?? '',
      greengoScore: _i(m['sc']),
      scoreTier: _s(m['st']),
      googleRating: _d(m['r']),
      ticketPrice: _d(m['tp']),
      currency: _s(m['cu']),
      freeEntry: m['f'] == true,
      unesco: m['u'] == true,
      mustVisit: m['mv'] == true,
      top10Country: m['t10'] == true,
      descriptionShort: _s(m['d']),
      visitDuration: _s(m['vd']),
      indoorOutdoor: _s(m['io']),
      wheelchairAccessible: _s(m['wa']),
      attributionAuthor: at is Map ? _s(at['a']) : null,
      attributionLicense: at is Map ? _s(at['l']) : null,
    );
  }

  /// Build from the full `attractions/{id}` document.
  factory Attraction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? const {};
    final img = (m['img'] as Map?) ?? const {};
    final at = (m['attribution'] as Map?);
    return Attraction(
      id: _i(m['id']),
      slug: _s(m['slug']) ?? '',
      name: _s(m['name']) ?? '',
      officialName: _s(m['officialName']),
      cityName: _s(m['cityName']) ?? '',
      citySlug: _s(m['citySlug']) ?? '',
      countryIso2: _s(m['countryIso2']) ?? '',
      countryName: _s(m['countryName']),
      category: _s(m['category']),
      categoryIcon: _s(m['categoryIcon']),
      categoryGroup: _s(m['categoryGroup']),
      importanceLevel: _s(m['importanceLevel']),
      importanceKey: _s(m['importanceKey']),
      importanceIcon: _s(m['importanceIcon']),
      greengoScore: _i(m['greengoScore']),
      scoreTier: _s(m['scoreTier']),
      googleRating: _d(m['googleRating']),
      lat: _d(m['lat']),
      lng: _d(m['lng']),
      ticketPrice: _d(m['ticketPrice']),
      currency: _s(m['currency']),
      freeEntry: m['freeEntry'] == true,
      unesco: m['unesco'] == true,
      mustVisit: m['mustVisit'] == true,
      top10Country: m['top10Country'] == true,
      descriptionShort: _s(m['descriptionShort']),
      descriptionMedium: _s(m['descriptionMedium']),
      descriptionLong: _s(m['descriptionLong']),
      historySummary: _s(m['historySummary']),
      topHighlights: _list(m['topHighlights']),
      photographyTips: _s(m['photographyTips']),
      interestingFacts: _list(m['interestingFacts']),
      altText: _s(m['altText']),
      openingHours: _s(m['openingHours']),
      visitDuration: _s(m['visitDuration']),
      bestSeason: _s(m['bestSeason']),
      bestTimeOfDay: _s(m['bestTimeOfDay']),
      indoorOutdoor: _s(m['indoorOutdoor']),
      wheelchairAccessible: _s(m['wheelchairAccessible']),
      petFriendly: _s(m['petFriendly']),
      safetyLevel: _s(m['safetyLevel']),
      streetAddress: _s(m['streetAddress']),
      annualVisitors: _s(m['annualVisitors']),
      timezone: _s(m['timezone']),
      photographyScore: (m['photographyScore'] as num?)?.toInt(),
      historicalScore: (m['historicalScore'] as num?)?.toInt(),
      architecturalScore: (m['architecturalScore'] as num?)?.toInt(),
      naturalScore: (m['naturalScore'] as num?)?.toInt(),
      imgBase: _s(img['base']) ?? '',
      imgHash: _s(img['hash']) ?? '',
      imgToken: _s(img['token']) ?? '',
      attributionAuthor: at == null ? null : _s(at['author']),
      attributionLicense: at == null ? null : _s(at['license']),
    );
  }
}

/// A country that has published attractions (`attraction_countries/{ISO2}`).
class AttractionCountry {
  const AttractionCountry({
    required this.iso2,
    required this.name,
    required this.total,
  });

  final String iso2;
  final String name;
  final int total;

  factory AttractionCountry.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    return AttractionCountry(
      iso2: (m['iso2'] ?? d.id).toString(),
      name: (m['name'] ?? d.id).toString(),
      total: (m['publishedCount'] as num?)?.toInt() ??
          (m['total'] as num?)?.toInt() ??
          0,
    );
  }
}
