import '../../../core/utils/language_flags.dart';

/// Community `languages` are stored as lowercase 2-letter ISO 639-1 codes
/// (`en`, `pt`, `ca` — see create_community_screen `_availableLanguages` and
/// the seed data), while profile language fields are mostly ENGLISH DISPLAY
/// NAMES (`profiles.languages` comes from the onboarding chips: `English`,
/// `Portuguese (Brazil)`, …) and may also hold codes or locales (`pt_BR`,
/// `en-US`) from older clients / seed data.
///
/// Firestore `arrayContainsAny` accepts at most 10 values.
const int kMaxCommunityLanguageFilters = 10;

/// Names the shared [languageCode] helper does not know (it only covers the
/// ~20 TTS languages). Keys are lowercase.
const Map<String, String> _extraLanguageNames = {
  'mandarin': 'zh', 'cantonese': 'zh', '中文': 'zh', 'chinese (simplified)': 'zh',
  'chinese (traditional)': 'zh',
  'catalan': 'ca', 'català': 'ca', 'catala': 'ca',
  'norwegian': 'no', 'norsk': 'no', 'nb': 'no', 'nn': 'no',
  'danish': 'da', 'dansk': 'da',
  'finnish': 'fi', 'suomi': 'fi',
  'castellano': 'es',
  'nederlands': 'nl', 'svenska': 'sv', 'polski': 'pl', 'türkçe': 'tr',
  'русский': 'ru', '日本語': 'ja', '한국어': 'ko', 'العربية': 'ar', 'हिन्दी': 'hi',
  'indonesian': 'id', 'ukrainian': 'uk', 'czech': 'cs', 'hungarian': 'hu',
  'romanian': 'ro', 'persian': 'fa', 'farsi': 'fa', 'malay': 'ms',
  'filipino': 'tl', 'tagalog': 'tl', 'bengali': 'bn', 'urdu': 'ur',
  'swahili': 'sw',
  'iw': 'he', // legacy Java/Android code for Hebrew
};

final RegExp _parenthetical = RegExp(r'\s*\(.*\)\s*$');
final RegExp _localeSeparator = RegExp('[-_ ]');
final RegExp _twoLetters = RegExp(r'^[a-z]{2}$');

/// Normalises one profile language value (display name, code or locale) to the
/// community `languages` format (lowercase 2-letter code), or null when it is
/// unknown. Reuses the app-wide [languageCode] map first.
String? normalizeCommunityLanguage(String? raw) {
  if (raw == null) return null;
  final key = raw.trim().toLowerCase();
  if (key.isEmpty) return null;

  final known = languageCode(key);
  if (known != null) return known;

  final extra = _extraLanguageNames[key];
  if (extra != null) return extra;

  // "Chinese (Simplified)"-style labels: retry without the qualifier.
  final stripped = key.replaceAll(_parenthetical, '').trim();
  if (stripped.isNotEmpty && stripped != key) {
    return normalizeCommunityLanguage(stripped);
  }

  // Any other code / locale ("uk", "cs_CZ"): keep its 2-letter base.
  final base = key.split(_localeSeparator).first;
  final mapped = _extraLanguageNames[base];
  if (mapped != null) return mapped;
  if (_twoLetters.hasMatch(base)) return base;
  return null;
}

/// Normalises, de-duplicates (first occurrence wins, so pass the most
/// relevant field first) and caps at [kMaxCommunityLanguageFilters] — ready
/// for a `languages arrayContainsAny` query.
List<String> normalizeCommunityLanguages(Iterable<String?> raw) {
  final out = <String>[];
  for (final value in raw) {
    final code = normalizeCommunityLanguage(value);
    if (code == null || out.contains(code)) continue;
    out.add(code);
    if (out.length >= kMaxCommunityLanguageFilters) break;
  }
  return out;
}
