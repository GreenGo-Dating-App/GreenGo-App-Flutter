import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Translation Service
///
/// Handles online translation using Google Translate free API directly.
/// Supports all Google Translate language codes including pt-BR.
class TranslationService {
  factory TranslationService() => _instance;
  TranslationService._internal();
  static final TranslationService _instance = TranslationService._internal();

  // Cache translations to avoid repeated API calls
  final Map<String, String> _translationCache = {};

  // Last detected source language from translation
  String? _lastDetectedLanguage;

  /// Get the last detected source language from the most recent translation
  String? get lastDetectedLanguage => _lastDetectedLanguage;

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

  /// Normalizes a language to something the translate endpoint accepts.
  ///
  /// Call sites pass a mixture: BCP-47 codes from the app locale ("en",
  /// "pt_BR") and display names from profile fields ("Portuguese (Brazil)"),
  /// because profiles store languages as names. That matters because the
  /// endpoint ACCEPTS an unrecognised `tl` and returns the text untranslated
  /// instead of failing:
  ///
  ///   tl=Portuguese  "Hello friend" -> "Hello friend"
  ///   tl=pt          "Hello friend" -> "Ola amigo"
  ///
  /// which is indistinguishable from a broken feature. Normalizing here means
  /// no caller can get it wrong.
  static String normalizeLanguage(String language) {
    final raw = language.trim();
    if (raw.isEmpty) return 'en';

    final key = raw.toLowerCase();

    // Brazilian Portuguese first: it must survive as pt-BR, not collapse to pt.
    if (key.contains('brazil') || key.contains('brasil') ||
        key.startsWith('pt_br') || key.startsWith('pt-br')) {
      return 'pt-BR';
    }

    // Already a code such as en, pt, en-GB, zh_CN.
    final code = RegExp(r'^([a-z]{2})([-_]([a-z]{2}))?$', caseSensitive: false)
        .firstMatch(raw);
    if (code != null) {
      final base = code.group(1)!.toLowerCase();
      final region = code.group(3);
      return region == null ? base : '$base-${region.toUpperCase()}';
    }

    const byName = <String, String>{
      'english': 'en', 'german': 'de', 'deutsch': 'de', 'spanish': 'es',
      'espanol': 'es', 'español': 'es', 'french': 'fr', 'francais': 'fr',
      'français': 'fr', 'italian': 'it', 'italiano': 'it',
      'portuguese': 'pt', 'português': 'pt', 'russian': 'ru',
      'chinese': 'zh', 'japanese': 'ja', 'korean': 'ko', 'arabic': 'ar',
      'hindi': 'hi', 'turkish': 'tr', 'dutch': 'nl', 'swedish': 'sv',
      'norwegian': 'no', 'danish': 'da', 'finnish': 'fi', 'polish': 'pl',
      'greek': 'el', 'hebrew': 'he', 'thai': 'th', 'vietnamese': 'vi',
    };
    return byName[key] ?? 'en';
  }

  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (text.isEmpty) return text;

    // Normalize before anything else, including the equality check and the
    // cache key, so "Portuguese" and "pt" are one entry rather than two.
    final target = normalizeLanguage(targetLanguage);
    if (sourceLanguage != 'auto' &&
        normalizeLanguage(sourceLanguage) == target) {
      return text;
    }

    // Check cache first
    final cacheKey = '${sourceLanguage}_${target}_$text';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      final from = sourceLanguage == 'auto' ? 'auto' : sourceLanguage;

      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx'
        '&sl=${Uri.encodeComponent(from)}'
        '&tl=${Uri.encodeComponent(target)}'
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

        // Extract detected source language (index 2 in response array)
        if (decoded is List && decoded.length > 2 && decoded[2] is String) {
          _lastDetectedLanguage = decoded[2] as String;
        }

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

          debugPrint('Translated: "$text" -> "$result" (detected: $_lastDetectedLanguage)');
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
