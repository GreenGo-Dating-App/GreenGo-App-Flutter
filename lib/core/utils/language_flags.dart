/// Maps a user's primary language (a code like `en`/`pt_BR` or a display name
/// like `English`/`Português (Brazil)`) to a flag emoji, so we can show where a
/// person is coming from next to their name in group chats. Returns '' when the
/// language is unknown (caller hides the flag).
String languageFlagEmoji(String? language) {
  if (language == null) return '';
  final key = language.trim().toLowerCase();
  if (key.isEmpty) return '';

  // Normalize a few common variants to a base key.
  if (key.startsWith('pt_br') || key.contains('brazil') || key.contains('brasil')) {
    return '🇧🇷';
  }
  if (key.startsWith('pt')) return '🇵🇹';

  const byCode = <String, String>{
    'en': '🇬🇧', 'de': '🇩🇪', 'es': '🇪🇸', 'fr': '🇫🇷', 'it': '🇮🇹',
    'pt': '🇵🇹', 'ru': '🇷🇺', 'zh': '🇨🇳', 'ja': '🇯🇵', 'ko': '🇰🇷',
    'ar': '🇸🇦', 'hi': '🇮🇳', 'tr': '🇹🇷', 'nl': '🇳🇱', 'sv': '🇸🇪',
    'pl': '🇵🇱', 'el': '🇬🇷', 'he': '🇮🇱', 'th': '🇹🇭', 'vi': '🇻🇳',
  };
  const byName = <String, String>{
    'english': '🇬🇧', 'german': '🇩🇪', 'deutsch': '🇩🇪', 'spanish': '🇪🇸',
    'español': '🇪🇸', 'espanol': '🇪🇸', 'french': '🇫🇷', 'français': '🇫🇷',
    'francais': '🇫🇷', 'italian': '🇮🇹', 'italiano': '🇮🇹',
    'portuguese': '🇵🇹', 'português': '🇵🇹', 'russian': '🇷🇺',
    'chinese': '🇨🇳', 'japanese': '🇯🇵', 'korean': '🇰🇷', 'arabic': '🇸🇦',
    'hindi': '🇮🇳', 'turkish': '🇹🇷', 'dutch': '🇳🇱', 'swedish': '🇸🇪',
    'polish': '🇵🇱', 'greek': '🇬🇷', 'hebrew': '🇮🇱', 'thai': '🇹🇭',
    'vietnamese': '🇻🇳',
  };

  // Try a 2-letter code prefix first (handles 'en', 'en-US', 'en_GB').
  final code = key.split(RegExp('[-_ ]')).first;
  return byCode[code] ?? byName[key] ?? '';
}

/// Normalizes a language (code or display name) to a 2-letter TTS code, or null
/// when unknown (caller falls back to a default).
String? languageCode(String? language) {
  if (language == null) return null;
  final key = language.trim().toLowerCase();
  if (key.isEmpty) return null;
  if (key.startsWith('pt')) return 'pt';
  const byName = <String, String>{
    'english': 'en', 'german': 'de', 'deutsch': 'de', 'spanish': 'es',
    'español': 'es', 'espanol': 'es', 'french': 'fr', 'français': 'fr',
    'francais': 'fr', 'italian': 'it', 'italiano': 'it', 'portuguese': 'pt',
    'português': 'pt', 'russian': 'ru', 'chinese': 'zh', 'japanese': 'ja',
    'korean': 'ko', 'arabic': 'ar', 'hindi': 'hi', 'turkish': 'tr',
    'dutch': 'nl', 'swedish': 'sv', 'polish': 'pl', 'greek': 'el',
    'hebrew': 'he', 'thai': 'th', 'vietnamese': 'vi',
  };
  const known = {
    'en', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'zh', 'ja', 'ko', 'ar', 'hi',
    'tr', 'nl', 'sv', 'pl', 'el', 'he', 'th', 'vi',
  };
  final code = key.split(RegExp('[-_ ]')).first;
  if (known.contains(code)) return code;
  return byName[key];
}
