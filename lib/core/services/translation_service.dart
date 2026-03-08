import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Translation Service
///
/// Handles online translation using Google Translate free API directly.
/// Supports all Google Translate language codes including pt-BR.
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  // Cache translations to avoid repeated API calls
  final Map<String, String> _translationCache = {};

  /// Map language codes for display
  static final Map<String, String> _languageNames = {
    'en': 'English',
    'it': 'Italiano',
    'es': 'Español',
    'fr': 'Français',
    'pt': 'Português',
    'pt-BR': 'Português (BR)',
    'de': 'Deutsch',
  };

  /// Get language name for display
  static String getLanguageName(String code) {
    return _languageNames[code] ?? code.toUpperCase();
  }

  /// Initialize service (no-op for online translation)
  Future<void> initialize() async {
    debugPrint('TranslationService: Using Google Translate API');
  }

  /// Check if a language model is downloaded (always true for online)
  Future<bool> isModelDownloaded(String languageCode) async {
    return true;
  }

  /// Download a language model (no-op for online translation)
  Future<bool> downloadModel(String languageCode) async {
    return true;
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
      final from = sourceLanguage == 'auto' ? 'auto' : sourceLanguage;

      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx'
        '&sl=${Uri.encodeComponent(from)}'
        '&tl=${Uri.encodeComponent(targetLanguage)}'
        '&dt=t'
        '&q=${Uri.encodeComponent(text)}',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Response format: [[["translated text","original text",null,null,x],...],null,"detected_lang",...]
        final translations = decoded[0] as List;
        final buffer = StringBuffer();
        for (final part in translations) {
          if (part is List && part.isNotEmpty && part[0] is String) {
            buffer.write(part[0]);
          }
        }
        final result = buffer.toString();

        if (result.isNotEmpty) {
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
        }
      }

      debugPrint('Translation failed: HTTP ${response.statusCode}');
      return text;
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
    return true;
  }

  /// Batch translate multiple texts
  Future<Map<String, String>> batchTranslate({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final results = <String, String>{};
    for (final text in texts) {
      results[text] = await translate(
        text: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }
    return results;
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
