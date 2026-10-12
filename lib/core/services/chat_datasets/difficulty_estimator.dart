import '../../utils/text_fold.dart';

/// Offline CEFR estimate (A1..C2) of a chat message, from word frequency.
///
/// Each language has its most frequent words in rank order (`freq.json`,
/// tools/chat_datasets/build_chat_datasets.js, from the CC-BY-SA-4.0
/// FrequencyWords lists). A message made only of very common words is A1;
/// the more of its words sit outside the top 1k / 2k / 4k / 8k / 15k, the
/// higher the level. Long sentences add one level. Names the keyword engine
/// recognised (cities, attractions) are skipped: "Colosseo" is not a hard
/// word.
class DifficultyEstimator {
  DifficultyEstimator(Map<String, List<String>> frequencyLists)
      : _ranks = {
          for (final e in frequencyLists.entries)
            e.key: {
              for (var i = 0; i < e.value.length; i++)
                foldForSearch(e.value[i]): i + 1,
            },
        };

  /// language -> folded word -> rank (1 = most frequent).
  final Map<String, Map<String, int>> _ranks;

  static const List<String> levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static final RegExp _word = RegExp(r"[\p{L}']+", unicode: true);

  bool supports(String language) => _ranks.containsKey(_key(language));

  /// The level of [text] in [language] ('en', 'it', 'pt_BR', 'pt-BR' ...),
  /// or null when the language is unknown or the text has no real words.
  /// [skip] are character ranges (keyword matches) to ignore.
  String? estimate(String text, String language,
      {List<(int, int)> skip = const []}) {
    final ranks = _ranks[_key(language)];
    if (ranks == null) return null;
    final words = <int>[];
    for (final m in _word.allMatches(text)) {
      if (skip.any((r) => m.start < r.$2 && m.end > r.$1)) continue;
      final w = foldForSearch(m.group(0)!);
      if (w.length < 2 && w != 'a' && w != 'e' && w != 'o' && w != 'y') continue;
      words.add(ranks[w] ?? 100000);
    }
    if (words.isEmpty) return null;
    double share(int top) => words.where((r) => r <= top).length / words.length;

    var level = share(1000) >= 0.95
        ? 0
        : share(2000) >= 0.92
            ? 1
            : share(4000) >= 0.90
                ? 2
                : share(8000) >= 0.88
                    ? 3
                    : share(15000) >= 0.85
                        ? 4
                        : 5;
    // A single rare word in a two-word message should not make it C2.
    if (words.length <= 3 && level > 2) level = 2;
    if (words.length > 25 && level < 5) level++;
    return levels[level];
  }

  static String _key(String language) {
    final l = language.replaceAll('-', '_');
    if (l.toLowerCase() == 'pt_br') return 'pt_BR';
    final base = l.split('_').first.toLowerCase();
    return base;
  }
}
