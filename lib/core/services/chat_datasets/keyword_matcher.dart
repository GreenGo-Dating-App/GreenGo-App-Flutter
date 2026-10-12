import '../../utils/text_fold.dart';

/// What a highlighted word in a chat message points to.
enum KeywordKind {
  /// One attraction (`ref` = attraction id): opens its page.
  attraction('a'),

  /// A city (`ref` = "ISO2:citySlug"): opens the city's attractions.
  city('c'),

  /// A country (`ref` = ISO2): opens its cultural tips.
  country('k');

  const KeywordKind(this.code);
  final String code;

  static KeywordKind? fromCode(String? code) {
    for (final k in values) {
      if (k.code == code) return k;
    }
    return null;
  }
}

/// A keyword found in a message: [start]..[end] in the ORIGINAL text, and
/// every target the words can mean ("Valencia" -> the Spanish city; "Rome"
/// -> the city; "Colosseo" -> one attraction).
class KeywordMatch {
  const KeywordMatch({
    required this.start,
    required this.end,
    required this.kind,
    required this.refs,
  });

  final int start;
  final int end;
  final KeywordKind kind;
  final List<String> refs;

  /// Compact form stored in message `metadata['entities']`.
  Map<String, Object> toJson() =>
      {'s': start, 'e': end, 'k': kind.code, 'r': refs};

  /// Null when [m] is not a valid stored entity for a text of [textLength].
  static KeywordMatch? fromJson(Object? m, int textLength) {
    if (m is! Map) return null;
    final s = m['s'], e = m['e'];
    final kind = KeywordKind.fromCode(m['k']?.toString());
    final refs = m['r'];
    if (s is! int || e is! int || kind == null || refs is! List) return null;
    if (s < 0 || e <= s || e > textLength) return null;
    return KeywordMatch(
      start: s,
      end: e,
      kind: kind,
      refs: [for (final r in refs) r.toString()],
    );
  }

  @override
  String toString() => 'KeywordMatch($start-$end ${kind.code} $refs)';
}

class _Alias {
  _Alias(this.tokens, this.kind, this.capitalised);
  final List<String> tokens;
  final KeywordKind kind;
  final bool capitalised;
  final List<String> refs = [];
}

/// Offline keyword index (`keywords.json`, tools/chat_datasets/build_keywords.js):
/// attraction / city / country names in the 7 app languages.
///
/// Matching is case- and accent-insensitive, longest match first ("Roman
/// Forum" beats "Rome"), and an alias flagged as a common word ("Nice",
/// "Split") only matches when the user wrote it with a capital letter.
class KeywordIndex {
  KeywordIndex._(this._byFirst, this.attractions, this.cities, this.countries);

  /// first folded token -> aliases starting with it, longest first.
  final Map<String, List<_Alias>> _byFirst;

  /// attraction id -> [iso2, citySlug, name].
  final Map<String, List<String>> attractions;

  /// "ISO2:citySlug" -> city name.
  final Map<String, String> cities;

  /// ISO2 -> country name.
  final Map<String, String> countries;

  static final RegExp _word = RegExp(r"[\p{L}\p{N}']+", unicode: true);

  factory KeywordIndex.fromJson(Map<String, dynamic> j) {
    final grouped = <String, _Alias>{};
    for (final row in (j['n'] as List? ?? const [])) {
      if (row is! List || row.length < 3) continue;
      final alias = row[0].toString();
      final kind = KeywordKind.fromCode(row[1].toString());
      if (kind == null || alias.isEmpty) continue;
      final cap = row.length > 3 && row[3] == 1;
      final key = '$alias|${kind.code}|$cap';
      (grouped[key] ??= _Alias(alias.split(' '), kind, cap))
          .refs
          .add(row[2].toString());
    }
    final byFirst = <String, List<_Alias>>{};
    for (final a in grouped.values) {
      (byFirst[a.tokens.first] ??= []).add(a);
    }
    for (final list in byFirst.values) {
      list.sort((x, y) => y.tokens.length.compareTo(x.tokens.length));
    }
    final attractions = <String, List<String>>{};
    (j['a'] as Map? ?? const {}).forEach((k, v) {
      if (v is List) attractions[k.toString()] = [for (final x in v) '$x'];
    });
    final cities = <String, String>{};
    (j['c'] as Map? ?? const {}).forEach((k, v) {
      cities[k.toString()] = v is List && v.isNotEmpty ? '${v.first}' : '$v';
    });
    final countries = <String, String>{};
    (j['k'] as Map? ?? const {}).forEach((k, v) => countries[k.toString()] = '$v');
    return KeywordIndex._(byFirst, attractions, cities, countries);
  }

  /// Every keyword in [text], left to right, non-overlapping.
  List<KeywordMatch> match(String text) {
    if (text.isEmpty || _byFirst.isEmpty) return const [];
    final words = _word.allMatches(text).toList();
    if (words.isEmpty) return const [];
    final folded = [for (final w in words) foldForSearch(w.group(0)!)];
    final out = <KeywordMatch>[];
    var i = 0;
    while (i < words.length) {
      final candidates = _byFirst[folded[i]];
      _Alias? hit;
      if (candidates != null) {
        for (final a in candidates) {
          final n = a.tokens.length;
          if (i + n > words.length) continue;
          var ok = true;
          for (var t = 0; t < n && ok; t++) {
            ok = folded[i + t] == a.tokens[t];
          }
          if (!ok) continue;
          if (a.capitalised && !_startsUpper(words[i].group(0)!)) continue;
          hit = a;
          break;
        }
      }
      if (hit == null) {
        i++;
        continue;
      }
      final last = words[i + hit.tokens.length - 1];
      out.add(KeywordMatch(
        start: words[i].start,
        end: last.end,
        kind: hit.kind,
        refs: List.unmodifiable(hit.refs),
      ));
      i += hit.tokens.length;
    }
    return out;
  }

  static bool _startsUpper(String w) {
    if (w.isEmpty) return false;
    final first = String.fromCharCode(w.runes.first);
    return first != first.toLowerCase();
  }
}
