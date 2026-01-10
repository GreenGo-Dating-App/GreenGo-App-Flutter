import 'package:flutter/foundation.dart';
import 'package:translator/translator.dart';

/// Translation Service
///
/// Handles online translation using Google Translate API
/// Works on all devices including emulators
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  // Cache translations to avoid repeated API calls
  final Map<String, String> _translationCache = {};

  /// Map language codes for display
  static final Map<String, String> _languageNames = {
    'en': 'English',
    'it': 'Italiano',
    'es': 'Español',
    'fr': 'Français',
    'pt': 'Português',
    'de': 'Deutsch',
  };

  /// Get language name for display
  static String getLanguageName(String code) {
    return _languageNames[code] ?? code.toUpperCase();
  }

  /// Initialize service (no-op for online translation)
  Future<void> initialize() async {
    debugPrint('TranslationService: Using online Google Translate');
  }

  /// Check if a language model is downloaded (always true for online)
  Future<bool> isModelDownloaded(String languageCode) async {
    // Online translation - no models needed
    return _languageNames.containsKey(languageCode);
  }

  /// Download a language model (no-op for online translation)
  Future<bool> downloadModel(String languageCode) async {
    // Online translation - no download needed
    return _languageNames.containsKey(languageCode);
  }

  /// Delete a downloaded language model (no-op for online)
  Future<bool> deleteModel(String languageCode) async {
    return true;
  }

  /// Translate text from source language to target language
  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.isEmpty) return text;
    if (sourceLanguage == targetLanguage) return text;

    // Check cache first
    final cacheKey = '${sourceLanguage}_${targetLanguage}_$text';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      // Use 'auto' for automatic language detection
      final from = sourceLanguage == 'auto' ? 'auto' : sourceLanguage;

      final translation = await _translator.translate(
        text,
        from: from,
        to: targetLanguage,
      );

      final result = translation.text;

      // Cache the result
      _translationCache[cacheKey] = result;

      // Limit cache size
      if (_translationCache.length > 500) {
        final keysToRemove = _translationCache.keys.take(100).toList();
        for (final key in keysToRemove) {
          _translationCache.remove(key);
        }
      }

      debugPrint('Translated: "$text" -> "$result"');
      return result;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  /// Get list of downloaded models (all supported for online)
  List<String> getDownloadedModels() {
    return _languageNames.keys.toList();
  }

  /// Get list of supported languages
  static List<String> getSupportedLanguages() {
    return _languageNames.keys.toList();
  }

  /// Check if translation is available between two languages
  Future<bool> canTranslate(String sourceLanguage, String targetLanguage) async {
    // Online translation always available
    return true;
  }

  /// Clear translation cache
  void clearCache() {
    _translationCache.clear();
  }

  /// Dispose (no-op for online)
  void dispose() {
    _translationCache.clear();
  }
}
