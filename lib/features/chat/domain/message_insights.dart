import '../../../core/services/chat_datasets/chat_datasets.dart';
import '../../../core/services/chat_datasets/keyword_matcher.dart';

/// Offline "insights" stored with a text message when it is sent:
///   metadata['entities'] = [{s, e, k, r}]  keywords in the text (cities,
///                                         attractions, countries)
///   metadata['level']    = 'B1'           CEFR estimate of the text
/// Receivers render highlights / the difficulty badge from these without
/// needing the datasets; older app versions ignore the fields.
class MessageInsights {
  MessageInsights._();

  /// Metadata for [text] written in [language], merged over [base]. Returns
  /// [base] unchanged when the datasets are not loaded yet (the receiver then
  /// computes the same thing locally).
  static Map<String, dynamic>? metadataFor(String text,
      {String? language, Map<String, dynamic>? base}) {
    final datasets = ChatDatasets.instance;
    final out = <String, dynamic>{...?base};
    final matches = datasets.keywords?.match(text) ?? const <KeywordMatch>[];
    if (matches.isNotEmpty) {
      out['entities'] = [for (final m in matches.take(20)) m.toJson()];
    }
    if (language != null) {
      final level = datasets.difficulty?.estimate(text, language,
          skip: [for (final m in matches) (m.start, m.end)]);
      if (level != null) out['level'] = level;
      out['language'] ??= language;
    }
    return out.isEmpty ? base : out;
  }

  /// The stored keywords of a message (validated against [text]).
  static List<KeywordMatch>? storedEntities(
      Map<String, dynamic>? metadata, String text) {
    final raw = metadata?['entities'];
    if (raw is! List) return null;
    final out = <KeywordMatch>[];
    for (final e in raw) {
      final m = KeywordMatch.fromJson(e, text.length);
      if (m != null) out.add(m);
    }
    return out;
  }

  /// The stored CEFR level, or null.
  static String? storedLevel(Map<String, dynamic>? metadata) {
    final l = metadata?['level'];
    return l is String && RegExp(r'^[ABC][12]$').hasMatch(l) ? l : null;
  }
}
