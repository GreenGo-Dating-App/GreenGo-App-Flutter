/// Normalizes city names to a stable key so a user's subscription
/// (`notification_preferences.eventCities`) matches an event's `city` field
/// regardless of case, accents, or spacing.
///
/// MUST stay in sync with the backend `normalizeCity` in
/// `functions/src/notifications/cityAlerts.ts`.
class CityNormalizer {
  CityNormalizer._();

  static const String _from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
  static const String _to = 'aaaaaaceeeeiiiinooooouuuuyy';

  /// Lowercase, trim, strip diacritics, drop punctuation, collapse whitespace.
  static String normalize(String raw) {
    var s = raw.trim().toLowerCase();
    final b = StringBuffer();
    for (final ch in s.split('')) {
      final i = _from.indexOf(ch);
      b.write(i >= 0 ? _to[i] : ch);
    }
    s = b.toString();
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Title-case a normalized key for display (e.g. "rio de janeiro" → "Rio De Janeiro").
  static String display(String key) {
    if (key.isEmpty) return key;
    return key
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
