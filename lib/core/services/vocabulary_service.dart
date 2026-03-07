import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for querying vocabulary data from Firestore with local caching
///
/// Words are stored in Firestore by an external import script.
/// This service downloads them once per language and caches locally
/// using SharedPreferences so subsequent lookups are instant and offline-capable.
class VocabularyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// In-memory cache: language -> { word -> frequencyScore }
  static final Map<String, Map<String, int>> _memoryCache = {};

  /// Whether a language has been fully loaded into memory
  static final Set<String> _loadedLanguages = {};

  /// Load all vocabulary words for a language from Firestore into local cache.
  /// Fetches from local SharedPreferences first; falls back to Firestore.
  static Future<void> loadLanguage(String language) async {
    if (_loadedLanguages.contains(language)) return;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'vocab_cache_$language';
    final cacheVersionKey = 'vocab_version_$language';
    final cachedData = prefs.getString(cacheKey);
    final cachedVersion = prefs.getInt(cacheVersionKey) ?? 0;

    // Current cache version — increment when re-importing data
    const currentVersion = 1;

    if (cachedData != null && cachedVersion >= currentVersion) {
      // Load from local cache
      final Map<String, dynamic> decoded = json.decode(cachedData);
      _memoryCache[language] = decoded.map(
        (key, value) => MapEntry(key, value as int),
      );
      _loadedLanguages.add(language);
      debugPrint('VocabularyService: Loaded ${_memoryCache[language]!.length} '
          'words for $language from local cache');
      return;
    }

    // Download from Firestore in paginated batches
    debugPrint('VocabularyService: Downloading vocabulary for $language from Firestore...');
    final wordMap = <String, int>{};
    DocumentSnapshot? lastDoc;
    const pageSize = 5000;

    while (true) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('vocabulary_words')
          .where('language', isEqualTo: language)
          .orderBy('rank')
          .limit(pageSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final text = (data['text'] as String?)?.toLowerCase().trim();
        final score = data['frequencyScore'] as int?;
        if (text != null && text.isNotEmpty && score != null) {
          wordMap[text] = score;
        }
      }

      lastDoc = snapshot.docs.last;
      debugPrint('VocabularyService: Fetched ${wordMap.length} words so far for $language');

      if (snapshot.docs.length < pageSize) break;
    }

    _memoryCache[language] = wordMap;
    _loadedLanguages.add(language);

    // Persist to local cache
    await prefs.setString(cacheKey, json.encode(wordMap));
    await prefs.setInt(cacheVersionKey, currentVersion);

    debugPrint('VocabularyService: Cached ${wordMap.length} words for $language locally');
  }

  /// Look up the frequency score for a word in a given language
  ///
  /// Returns the frequencyScore (1-100) or null if word is not in corpus.
  /// Automatically loads the language if not yet cached.
  static Future<int?> getWordFrequencyScore(String word, String language) async {
    await loadLanguage(language);

    final normalizedWord = word.toLowerCase().trim();
    return _memoryCache[language]?[normalizedWord];
  }

  /// Look up frequency scores for multiple words at once
  ///
  /// Returns a map of word -> frequencyScore. Words not in corpus are omitted.
  static Future<Map<String, int>> getWordFrequencyScores(
    List<String> words,
    String language,
  ) async {
    await loadLanguage(language);

    final langCache = _memoryCache[language];
    if (langCache == null) return {};

    final results = <String, int>{};
    for (final word in words) {
      final normalized = word.toLowerCase().trim();
      if (normalized.isEmpty) continue;
      final score = langCache[normalized];
      if (score != null) {
        results[normalized] = score;
      }
    }
    return results;
  }

  /// Get top words for a language by frequency score (from local cache)
  static Future<List<MapEntry<String, int>>> getTopWords(
    String language, {
    int limit = 100,
  }) async {
    await loadLanguage(language);

    final langCache = _memoryCache[language];
    if (langCache == null) return [];

    final sorted = langCache.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).toList();
  }

  /// Check if vocabulary data exists for a language (in Firestore)
  static Future<bool> hasDataForLanguage(String language) async {
    final snapshot = await _firestore
        .collection('vocabulary_words')
        .where('language', isEqualTo: language)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Get the count of cached words for a language
  static int getCachedWordCount(String language) {
    return _memoryCache[language]?.length ?? 0;
  }

  /// Check if a language is loaded
  static bool isLanguageLoaded(String language) {
    return _loadedLanguages.contains(language);
  }

  /// Clear all caches (memory and local storage)
  static Future<void> clearCache() async {
    _memoryCache.clear();
    _loadedLanguages.clear();

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('vocab_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Clear cache for a specific language
  static Future<void> clearLanguageCache(String language) async {
    _memoryCache.remove(language);
    _loadedLanguages.remove(language);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vocab_cache_$language');
    await prefs.remove('vocab_version_$language');
  }
}
