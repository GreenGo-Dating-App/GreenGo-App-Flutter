import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firestore_helpers.dart';

/// Vocabulary Data Import Utility
///
/// Downloads word and sentence frequency data from OpenSubtitles corpus
/// and imports into Firestore with frequency scores.
class VocabularyImport {
  static const String _baseUrl =
      'https://raw.githubusercontent.com/orgtre/top-open-subtitles-sentences/main/bld';

  static const List<String> _languages = [
    'en', 'es', 'de', 'fr', 'it', 'pt', 'pt_br'
  ];

  /// Target number of words to import per language
  static const int _targetWordsPerLanguage = 100000;

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Random _random = Random();

  /// Import all vocabulary data for all languages
  static Future<void> importAll({
    void Function(String message)? onProgress,
  }) async {
    for (final lang in _languages) {
      onProgress?.call('Importing words for $lang...');
      await importWords(lang, onProgress: onProgress);
      onProgress?.call('Importing sentences for $lang...');
      await importSentences(lang, onProgress: onProgress);
    }
    onProgress?.call('Import complete!');
  }

  /// Import word frequency data for a single language
  /// Takes a random sample of [_targetWordsPerLanguage] words (3+ letters)
  static Future<void> importWords(
    String language, {
    void Function(String message)? onProgress,
  }) async {
    final url = '$_baseUrl/top_words/${language}_top_words.csv';
    final allEntries = await _downloadAndParseCsv(url);
    if (allEntries.isEmpty) {
      onProgress?.call('No word data found for $language');
      return;
    }

    onProgress?.call('Parsed ${allEntries.length} eligible words for $language');

    // Randomly sample if more than target
    final entries = _randomSample(allEntries, _targetWordsPerLanguage);

    // Re-sort sampled entries by count descending to assign proper ranks
    entries.sort((a, b) => b.count.compareTo(a.count));

    final totalItems = entries.length;
    onProgress?.call('Selected $totalItems words for $language (random sample)');

    final operations = <BatchOperation>[];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final rank = i + 1;
      final frequencyScore = _computeFrequencyScore(rank, totalItems);

      final docRef = _firestore.collection('vocabulary_words').doc();
      operations.add(BatchOperation.set(docRef, {
        'text': entry.text,
        'language': language,
        'count': entry.count,
        'rank': rank,
        'frequencyScore': frequencyScore,
      }));
    }

    onProgress?.call('Writing ${operations.length} words for $language...');
    await FirestoreHelpers.batchWrite(operations);
    onProgress?.call('Words for $language imported successfully');
  }

  /// Import sentence frequency data for a single language
  static Future<void> importSentences(
    String language, {
    void Function(String message)? onProgress,
  }) async {
    final url = '$_baseUrl/top_sentences/${language}_top_sentences.csv';
    final entries = await _downloadAndParseCsv(url);
    if (entries.isEmpty) {
      onProgress?.call('No sentence data found for $language');
      return;
    }

    final totalItems = entries.length;
    onProgress?.call('Parsed $totalItems sentences for $language');

    final operations = <BatchOperation>[];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final rank = i + 1;
      final frequencyScore = _computeFrequencyScore(rank, totalItems);

      final docRef = _firestore.collection('vocabulary_sentences').doc();
      operations.add(BatchOperation.set(docRef, {
        'text': entry.text,
        'language': language,
        'count': entry.count,
        'rank': rank,
        'frequencyScore': frequencyScore,
      }));
    }

    onProgress?.call('Writing ${operations.length} sentences for $language...');
    await FirestoreHelpers.batchWrite(operations);
    onProgress?.call('Sentences for $language imported successfully');
  }

  /// Compute frequency score from rank (100 = most common, 1 = least common)
  static int _computeFrequencyScore(int rank, int totalItems) {
    if (totalItems <= 1) return 100;
    return max(1, 100 - ((rank - 1) * 100 ~/ totalItems));
  }

  /// Randomly sample up to [count] items from a list using Fisher-Yates shuffle
  static List<_CsvEntry> _randomSample(List<_CsvEntry> source, int count) {
    if (source.length <= count) return List.from(source);

    // Fisher-Yates partial shuffle for efficient random sampling
    final list = List<_CsvEntry>.from(source);
    for (int i = 0; i < count; i++) {
      final j = i + _random.nextInt(list.length - i);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list.sublist(0, count);
  }

  /// Download CSV from URL and parse into entries (words with 3+ letters only)
  static Future<List<_CsvEntry>> _downloadAndParseCsv(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('Failed to download $url: ${response.statusCode}');
        return [];
      }

      final lines = response.body.split('\n');
      if (lines.isEmpty) return [];

      // Skip header line
      final entries = <_CsvEntry>[];
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // CSV format: text,count
        final lastComma = line.lastIndexOf(',');
        if (lastComma <= 0) continue;

        final text = line.substring(0, lastComma).trim();
        final countStr = line.substring(lastComma + 1).trim();
        final count = int.tryParse(countStr);
        if (count == null || text.isEmpty) continue;

        // Only import words with 3 or more letters
        if (text.length < 3) continue;

        entries.add(_CsvEntry(text: text, count: count));
      }

      // Sort by count descending (most frequent first)
      entries.sort((a, b) => b.count.compareTo(a.count));
      return entries;
    } catch (e) {
      debugPrint('Error downloading/parsing $url: $e');
      return [];
    }
  }

  /// Check if vocabulary data already exists for a language
  static Future<bool> hasDataForLanguage(String language) async {
    final snapshot = await _firestore
        .collection('vocabulary_words')
        .where('language', isEqualTo: language)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}

class _CsvEntry {
  final String text;
  final int count;

  const _CsvEntry({required this.text, required this.count});
}
