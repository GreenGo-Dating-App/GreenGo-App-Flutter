import 'dart:ui' show Locale;

import 'package:cloud_firestore/cloud_firestore.dart';

/// A curated attraction from the GreenGo dataset.
///
/// Three shapes exist for the SAME entity:
///  • the packed LITE row inside `attractions_lite/{ISO2}_{n}.rows` (decoded by
///    `AttractionsLiteShard`) — only what the list / grid / filters / sort /
///    search render, so a whole big country is ONE ~0.4 MB doc;
///  • the compact record inside `attractions_index/{ISO2}_{n}.items` — the
///    fallback list source when a country has no (current) lite build;
///  • the full `attractions/{id}` doc — read only when a detail screen opens.
///
/// A list record (lite or index) leaves the detail-only fields null; the lite
/// one also leaves [categoryGroup], [indoorOutdoor] and [wheelchairAccessible]
/// null and may carry a description capped at 120 chars. The detail page
/// always reloads the full doc.
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
    this.curiosities = const [],
    this.names = const {},
    this.about = const {},
    this.aboutSources = const {},
    this.aboutTranslated = const {},
    this.i18n = const {},
    this.cityNames = const {},
    this.shortTemplates = const {},
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

  /// The attraction's top 5 curiosities (English; the detail page translates
  /// them). Filled by scripts/generate_attraction_curiosities.js.
  final List<String> curiosities;

  /// The title in the app languages (en, it, es, pt, pt_BR, fr, de), from
  /// Wikidata (scripts/build_attraction_names_i18n.js). Missing languages fall
  /// back to [name]; use [nameFor].
  final Map<String, String> names;

  /// The title to show for [locale]: "Colosseo" in Italian, "Kolosseum" in
  /// German, else [name]. Wikidata labels are lower case in some languages
  /// ("torre Eiffel"); as a title the first letter is upper case.
  String nameFor(Locale? locale) {
    if (locale == null || names.isEmpty) return name;
    final lang = locale.languageCode;
    final key = lang == 'pt' && locale.countryCode == 'BR' ? 'pt_BR' : lang;
    final n = names[key] ?? names[lang];
    if (n == null || n.isEmpty) return name;
    return n[0].toUpperCase() + n.substring(1);
  }

  /// "What is it?": 3-4 sentences per app language (en, it, es, pt, pt_BR,
  /// fr, de) from the lead of the attraction's Wikipedia article
  /// (tools/attractions_about/build_about.js). CC BY-SA 4.0: show
  /// [aboutSources] with it.
  final Map<String, String> about;

  /// Wikipedia article URL per language of [about].
  final Map<String, String> aboutSources;

  static String _langKey(Locale locale) =>
      locale.languageCode == 'pt' && locale.countryCode == 'BR' ? 'pt_BR' : locale.languageCode;

  /// [about] in [locale]'s language, or null when that language has no article
  /// (then show the English one, translated).
  String? aboutIn(Locale locale) {
    final k = _langKey(locale);
    return about[k] ?? about[locale.languageCode];
  }

  /// The text to translate when [aboutIn] has none: English, else whichever
  /// language has an article (some places only have one in Spanish, say).
  String? get aboutAny => about['en'] ?? (about.isEmpty ? null : about.values.first);

  /// Languages of [about] that were TRANSLATED (by tools/attractions_i18n)
  /// because Wikipedia has no article in them: language -> source language.
  /// Their [aboutSources] entry is the source article.
  final Map<String, String> aboutTranslated;

  /// Whether [aboutIn] for [locale] is a translation of another language's
  /// article (the credit line then says so).
  bool aboutIsTranslated(Locale locale) {
    final k = _langKey(locale);
    if (about[k] != null) return aboutTranslated.containsKey(k);
    return aboutTranslated.containsKey(locale.languageCode);
  }

  /// The catalogue texts in it, es, pt, pt_BR, fr, de (`attractions/{id}.i18n`,
  /// tools/attractions_i18n). English lives in the plain fields. Empty on list
  /// records; use [textsFor].
  final Map<String, AttractionTexts> i18n;

  /// City name per language, only where it differs from [cityName] (lite
  /// columns c_* or i18n.{lang}.cityName). Use [cityFor].
  final Map<String, String> cityNames;

  /// List records: [descriptionShort] per language with `{N}` / `{C}` left for
  /// the localised title and city (lite columns d_*). Use [descriptionShortFor].
  final Map<String, String> shortTemplates;

  /// Every catalogue text in [locale]'s language, each field falling back to
  /// English when that language has no copy. Pure lookup: a language switch
  /// just rebuilds.
  AttractionTexts textsFor(Locale? locale) {
    final en = AttractionTexts.english(this);
    if (locale == null) return en;
    final k = _langKey(locale);
    final t = i18n[k] ?? i18n[locale.languageCode];
    return t == null ? en : t.orElse(en);
  }

  /// [cityName] in [locale]'s language.
  String cityFor(Locale? locale) {
    if (locale == null) return cityName;
    return i18n[_langKey(locale)]?.cityName ??
        cityNames[_langKey(locale)] ??
        cityNames[locale.languageCode] ??
        cityName;
  }

  /// The one-line description in [locale]'s language: the full doc's copy,
  /// else the list record's template, else English.
  String? descriptionShortFor(Locale? locale) {
    if (locale == null) return descriptionShort;
    final full = i18n[_langKey(locale)]?.descriptionShort;
    if (full != null) return full;
    final t = shortTemplates[_langKey(locale)] ?? shortTemplates[locale.languageCode];
    if (t == null) return descriptionShort;
    return t.replaceAll('{N}', nameFor(locale)).replaceAll('{C}', cityFor(locale));
  }

  /// Source URL for the text [aboutIn] returned, else for [aboutAny].
  String? aboutSourceIn(Locale locale) {
    final k = _langKey(locale);
    if (aboutIn(locale) != null) return aboutSources[k] ?? aboutSources[locale.languageCode];
    final any = aboutAny;
    for (final e in about.entries) {
      if (e.value == any) return aboutSources[e.key];
    }
    return null;
  }

  /// Every known title (catalogue, official and localised), for search.
  Iterable<String> get allNames => {
        name,
        if (officialName != null) officialName!,
        ...names.values,
      };
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

  /// A `names` map from Firestore / the lite columns (string values only).
  static Map<String, String> namesMap(dynamic v) {
    if (v is! Map) return const {};
    final out = <String, String>{};
    v.forEach((k, val) {
      final s = val?.toString().trim() ?? '';
      if (s.isNotEmpty) out[k.toString()] = s;
    });
    return out;
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
      curiosities: _list(m['curiosities']),
      names: namesMap(m['names']),
      about: namesMap(m['about']),
      aboutSources: namesMap(m['aboutSources']),
      aboutTranslated: namesMap(m['aboutTranslated']),
      i18n: AttractionTexts.i18nMap(m['i18n']),
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

/// The catalogue texts of one attraction in one language: one entry of
/// `attractions/{id}.i18n` (field names = the English top-level fields), or
/// the English fields themselves ([AttractionTexts.english]).
class AttractionTexts {
  const AttractionTexts({
    this.cityName,
    this.descriptionShort,
    this.descriptionMedium,
    this.descriptionLong,
    this.historySummary,
    this.topHighlights = const [],
    this.interestingFacts = const [],
    this.curiosities = const [],
    this.photographyTips,
    this.altText,
    this.openingHours,
    this.visitDuration,
    this.bestSeason,
    this.bestTimeOfDay,
    this.wheelchairAccessible,
    this.indoorOutdoor,
    this.petFriendly,
    this.safetyLevel,
    this.annualVisitors,
  });

  final String? cityName;
  final String? descriptionShort;
  final String? descriptionMedium;
  final String? descriptionLong;
  final String? historySummary;
  final List<String> topHighlights;
  final List<String> interestingFacts;
  final List<String> curiosities;
  final String? photographyTips;
  final String? altText;
  final String? openingHours;
  final String? visitDuration;
  final String? bestSeason;
  final String? bestTimeOfDay;
  final String? wheelchairAccessible;
  final String? indoorOutdoor;
  final String? petFriendly;
  final String? safetyLevel;
  final String? annualVisitors;

  factory AttractionTexts.english(Attraction a) => AttractionTexts(
        cityName: a.cityName,
        descriptionShort: a.descriptionShort,
        descriptionMedium: a.descriptionMedium,
        descriptionLong: a.descriptionLong,
        historySummary: a.historySummary,
        topHighlights: a.topHighlights,
        interestingFacts: a.interestingFacts,
        curiosities: a.curiosities,
        photographyTips: a.photographyTips,
        altText: a.altText,
        openingHours: a.openingHours,
        visitDuration: a.visitDuration,
        bestSeason: a.bestSeason,
        bestTimeOfDay: a.bestTimeOfDay,
        wheelchairAccessible: a.wheelchairAccessible,
        indoorOutdoor: a.indoorOutdoor,
        petFriendly: a.petFriendly,
        safetyLevel: a.safetyLevel,
        annualVisitors: a.annualVisitors,
      );

  factory AttractionTexts.fromMap(Map m) => AttractionTexts(
        cityName: Attraction._s(m['cityName']),
        descriptionShort: Attraction._s(m['descriptionShort']),
        descriptionMedium: Attraction._s(m['descriptionMedium']),
        descriptionLong: Attraction._s(m['descriptionLong']),
        historySummary: Attraction._s(m['historySummary']),
        topHighlights: Attraction._list(m['topHighlights']),
        interestingFacts: Attraction._list(m['interestingFacts']),
        curiosities: Attraction._list(m['curiosities']),
        photographyTips: Attraction._s(m['photographyTips']),
        altText: Attraction._s(m['altText']),
        openingHours: Attraction._s(m['openingHours']),
        visitDuration: Attraction._s(m['visitDuration']),
        bestSeason: Attraction._s(m['bestSeason']),
        bestTimeOfDay: Attraction._s(m['bestTimeOfDay']),
        wheelchairAccessible: Attraction._s(m['wheelchairAccessible']),
        indoorOutdoor: Attraction._s(m['indoorOutdoor']),
        petFriendly: Attraction._s(m['petFriendly']),
        safetyLevel: Attraction._s(m['safetyLevel']),
        annualVisitors: Attraction._s(m['annualVisitors']),
      );

  /// `attractions/{id}.i18n` -> language -> texts (malformed entries skipped).
  static Map<String, AttractionTexts> i18nMap(dynamic v) {
    if (v is! Map) return const {};
    return {
      for (final e in v.entries)
        if (e.value is Map) e.key.toString(): AttractionTexts.fromMap(e.value as Map),
    };
  }

  /// This language's texts with every missing field taken from [fallback]
  /// (lists: a list is used only when it has the same length, so a partial
  /// copy never mixes languages inside one section).
  AttractionTexts orElse(AttractionTexts fallback) {
    List<String> list(List<String> mine, List<String> other) =>
        mine.isNotEmpty && mine.length == other.length ? mine : other;
    return AttractionTexts(
      cityName: cityName ?? fallback.cityName,
      descriptionShort: descriptionShort ?? fallback.descriptionShort,
      descriptionMedium: descriptionMedium ?? fallback.descriptionMedium,
      descriptionLong: descriptionLong ?? fallback.descriptionLong,
      historySummary: historySummary ?? fallback.historySummary,
      topHighlights: list(topHighlights, fallback.topHighlights),
      interestingFacts: list(interestingFacts, fallback.interestingFacts),
      curiosities: list(curiosities, fallback.curiosities),
      photographyTips: photographyTips ?? fallback.photographyTips,
      altText: altText ?? fallback.altText,
      openingHours: openingHours ?? fallback.openingHours,
      visitDuration: visitDuration ?? fallback.visitDuration,
      bestSeason: bestSeason ?? fallback.bestSeason,
      bestTimeOfDay: bestTimeOfDay ?? fallback.bestTimeOfDay,
      wheelchairAccessible: wheelchairAccessible ?? fallback.wheelchairAccessible,
      indoorOutdoor: indoorOutdoor ?? fallback.indoorOutdoor,
      petFriendly: petFriendly ?? fallback.petFriendly,
      safetyLevel: safetyLevel ?? fallback.safetyLevel,
      annualVisitors: annualVisitors ?? fallback.annualVisitors,
    );
  }
}

/// A country that has published attractions (`attraction_countries/{ISO2}`).
class AttractionCountry {
  const AttractionCountry({
    required this.iso2,
    required this.name,
    required this.total,
    this.bbox,
    this.indexVersion,
    this.liteManifest,
  });

  final String iso2;
  final String name;
  final int total;

  /// [south, west, north, east] of the country's published attractions (plus
  /// padding), written by tools/attractions/seed_bbox.cjs. Lets the country a
  /// user stands in be resolved WITHOUT the ~0.5 MB geo index whenever only
  /// one box contains the point.
  final List<double>? bbox;

  /// Version of the country's `attractions_index` shards (bumped by every
  /// catalogue seed).
  final int? indexVersion;

  /// `lite` manifest written by scripts/build_attractions_lite.js, as stored.
  final AttractionLiteManifest? liteManifest;

  /// The lite build to list this country from, or null to use the full index
  /// shards: absent, an unknown format, or built from an older index than the
  /// current [indexVersion] (a reseed happened after the last lite build).
  AttractionLiteManifest? get lite {
    final m = liteManifest;
    if (m == null || m.format != AttractionLiteManifest.supportedFormat) {
      return null;
    }
    if (m.shards < 1 || m.version.isEmpty) return null;
    if (indexVersion != null && m.src != indexVersion) return null;
    return m;
  }

  factory AttractionCountry.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final box = m['bbox'];
    return AttractionCountry(
      iso2: (m['iso2'] ?? d.id).toString(),
      name: (m['name'] ?? d.id).toString(),
      total: (m['publishedCount'] as num?)?.toInt() ??
          (m['total'] as num?)?.toInt() ??
          0,
      bbox: box is List && box.length == 4 && box.every((e) => e is num)
          ? [for (final e in box) (e as num).toDouble()]
          : null,
      indexVersion: (m['indexVersion'] as num?)?.toInt(),
      liteManifest: AttractionLiteManifest.fromMap(m['lite']),
    );
  }
}

/// `attraction_countries/{ISO2}.lite`: which `attractions_lite` build holds
/// the country's list rows (scripts/build_attractions_lite.js).
class AttractionLiteManifest {
  const AttractionLiteManifest({
    required this.format,
    required this.shards,
    required this.version,
    this.src,
    this.count,
  });

  /// The lite layout this app decodes (see `AttractionsLiteShard.format`).
  static const int supportedFormat = 1;

  final int format;

  /// Number of `attractions_lite/{ISO2}_{n}` docs in the build.
  final int shards;

  /// Content hash every shard of the build carries.
  final String version;

  /// The `attractions_index` version the build was made from.
  final int? src;
  final int? count;

  static AttractionLiteManifest? fromMap(Object? v) {
    if (v is! Map) return null;
    final format = v['format'], shards = v['shards'], version = v['version'];
    if (format is! num || shards is! num || version is! String) return null;
    return AttractionLiteManifest(
      format: format.toInt(),
      shards: shards.toInt(),
      version: version,
      src: (v['src'] as num?)?.toInt(),
      count: (v['count'] as num?)?.toInt(),
    );
  }
}
