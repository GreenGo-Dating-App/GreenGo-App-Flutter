/// Server-side community search: `communities/{id}.searchKeywords` holds the
/// normalised PREFIXES of every word of the name, then the city, then the
/// tags (e.g. "Café Lisboa" → c, ca, caf, cafe, l, li, … lisboa), so a single
/// `searchKeywords arrayContains <prefix>` query finds a community by any
/// word the user starts typing.
///
/// MUST stay byte-for-byte identical to
/// functions/src/communities/searchKeywords.ts (Cloud Function trigger and
/// scripts/backfill_community_search_keywords.js use it). Both sides are
/// checked against test/fixtures/community_search_keywords_vectors.json.
library;

/// Firestore field name.
const String kCommunitySearchKeywordsField = 'searchKeywords';

/// Max entries in the array (keeps the doc + index entries small).
const int kMaxCommunitySearchKeywords = 100;

/// Longest prefix stored per word; longer query words are truncated to it.
const int kMaxCommunitySearchPrefixLength = 15;

/// Lowercase accented letter → plain replacement. Explicit (no Unicode NFD)
/// so Dart and Node produce identical output.
const Map<String, String> _foldGroups = {
  'àáâãäåāăą': 'a',
  'çćĉċč': 'c',
  'ďđð': 'd',
  'èéêëēĕėęě': 'e',
  'ĝğġģ': 'g',
  'ĥħ': 'h',
  'ìíîïĩīĭįı': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺļľŀł': 'l',
  'ñńņňŉ': 'n',
  'òóôõöøōŏő': 'o',
  'ŕŗř': 'r',
  'śŝşšș': 's',
  'ţťŧț': 't',
  'ùúûüũūŭůűų': 'u',
  'ŵ': 'w',
  'ýÿŷ': 'y',
  'źżž': 'z',
  'ß': 'ss',
  'æ': 'ae',
  'œ': 'oe',
  'þ': 'th',
};

final Map<int, String> _fold = {
  for (final e in _foldGroups.entries)
    for (final r in e.key.runes) r: e.value,
};

final RegExp _combiningMarks = RegExp('[̀-ͯ]');
final RegExp _nonWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lowercase + strip accents.
String normalizeCommunitySearchText(String? input) {
  if (input == null || input.isEmpty) return '';
  final lower = input.toLowerCase().replaceAll(_combiningMarks, '');
  final sb = StringBuffer();
  for (final r in lower.runes) {
    final f = _fold[r];
    if (f != null) {
      sb.write(f);
    } else {
      sb.writeCharCode(r);
    }
  }
  return sb.toString();
}

/// Normalised words (letters/digits of any script; everything else splits).
List<String> communitySearchTokens(String? input) => normalizeCommunitySearchText(
      input,
    ).split(_nonWord).where((t) => t.isNotEmpty).toList();

String _truncate(String token) {
  final runes = token.runes;
  if (runes.length <= kMaxCommunitySearchPrefixLength) return token;
  return String.fromCharCodes(runes.take(kMaxCommunitySearchPrefixLength));
}

/// The `searchKeywords` array for a community: name word prefixes first, then
/// city, then tags; de-duplicated in that order and capped at
/// [kMaxCommunitySearchKeywords].
List<String> buildCommunitySearchKeywords({
  required String? name,
  String? city,
  Iterable<String> tags = const [],
}) {
  final out = <String>[];
  final seen = <String>{};
  final sources = <String?>[name, city, ...tags];
  for (final source in sources) {
    for (final token in communitySearchTokens(source)) {
      final runes = token.runes.toList();
      final max = runes.length < kMaxCommunitySearchPrefixLength
          ? runes.length
          : kMaxCommunitySearchPrefixLength;
      for (var i = 1; i <= max; i++) {
        final prefix = String.fromCharCodes(runes.sublist(0, i));
        if (seen.add(prefix)) {
          out.add(prefix);
          if (out.length >= kMaxCommunitySearchKeywords) return out;
        }
      }
    }
  }
  return out;
}

/// The single value to query `searchKeywords` with: the LONGEST word of the
/// query (most selective), truncated to [kMaxCommunitySearchPrefixLength].
/// Null when the query has no searchable word.
String? communitySearchQueryToken(String? query) {
  String? best;
  var bestLen = 0;
  for (final t in communitySearchTokens(query)) {
    final len = t.runes.length;
    if (len > bestLen) {
      best = t;
      bestLen = len;
    }
  }
  return best == null ? null : _truncate(best);
}

/// Client-side check of the FULL query: every query word must be the prefix
/// of some word of the name, city or tags (the keyword query only matched the
/// longest one).
bool communityMatchesSearchQuery({
  required String query,
  required String name,
  String? city,
  Iterable<String> tags = const [],
}) {
  final queryTokens = communitySearchTokens(query).map(_truncate).toList();
  if (queryTokens.isEmpty) return false;
  final docTokens = <String>[
    ...communitySearchTokens(name),
    ...communitySearchTokens(city),
    for (final t in tags) ...communitySearchTokens(t),
  ];
  return queryTokens.every((q) => docTokens.any((d) => d.startsWith(q)));
}
