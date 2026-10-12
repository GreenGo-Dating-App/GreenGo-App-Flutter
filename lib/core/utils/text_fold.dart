/// Accent- and case-insensitive form of [s] for matching user text against
/// names in any language: "Colisée" -> "colisee", "São Paulo" -> "sao paulo",
/// "Straße" -> "strasse". Punctuation becomes a single space.
///
/// Must stay in sync with `norm()` in tools/chat_datasets/build_keywords.js and
/// scripts/build_attraction_names_i18n.js (the offline indexes are folded the
/// same way).
String foldForSearch(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  var lastSpace = true;
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final folded = _fold[ch] ?? ch;
    final isWord = _isWordChar(rune) || folded != ch;
    if (isWord || ch == "'") {
      out.write(folded);
      lastSpace = false;
    } else if (ch == '’' || ch == '`' || ch == '´') {
      out.write("'");
      lastSpace = false;
    } else if (!lastSpace) {
      out.write(' ');
      lastSpace = true;
    }
  }
  return out.toString().trim();
}

bool _isWordChar(int r) =>
    (r >= 0x30 && r <= 0x39) || // 0-9
    (r >= 0x61 && r <= 0x7a) || // a-z
    (r >= 0xc0 && r != 0xd7 && r != 0xf7); // letters of other scripts

const Map<String, String> _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a', 'ă': 'a', 'ą': 'a',
  'ç': 'c', 'ć': 'c', 'ĉ': 'c', 'ċ': 'c', 'č': 'c',
  'ď': 'd', 'đ': 'd',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e', 'ě': 'e',
  'ĝ': 'g', 'ğ': 'g', 'ġ': 'g', 'ģ': 'g',
  'ĥ': 'h',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ĩ': 'i', 'ī': 'i', 'ĭ': 'i', 'į': 'i', 'ı': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺ': 'l', 'ļ': 'l', 'ľ': 'l', 'ł': 'l',
  'ñ': 'n', 'ń': 'n', 'ņ': 'n', 'ň': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', 'ŏ': 'o', 'ő': 'o',
  'ŕ': 'r', 'ř': 'r',
  'ś': 's', 'ŝ': 's', 'ş': 's', 'š': 's', 'ș': 's',
  'ß': 'ss',
  'ţ': 't', 'ť': 't', 'ț': 't',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ũ': 'u', 'ū': 'u', 'ŭ': 'u', 'ů': 'u', 'ű': 'u', 'ų': 'u',
  'ŵ': 'w',
  'ý': 'y', 'ÿ': 'y', 'ŷ': 'y',
  'ź': 'z', 'ż': 'z', 'ž': 'z',
  'æ': 'ae', 'œ': 'oe',
};
