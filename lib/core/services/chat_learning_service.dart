import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Centralized service for AI-powered chat language learning features.
/// Uses Gemini API for: smart replies, grammar correction, cultural tooltips,
/// word breakdown, difficulty assessment, and romanization.
class ChatLearningService {
  static final ChatLearningService _instance = ChatLearningService._();
  factory ChatLearningService() => _instance;
  ChatLearningService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _geminiApiKey;

  // Caches to avoid repeated API calls
  final Map<String, List<String>> _smartReplyCache = {};
  final Map<String, String> _correctionCache = {};
  final Map<String, String> _culturalTooltipCache = {};
  final Map<String, List<Map<String, String>>> _wordBreakdownCache = {};
  final Map<String, String> _romanizationCache = {};
  final Map<String, String> _difficultyCache = {};

  Future<String?> _getApiKey() async {
    if (_geminiApiKey != null) return _geminiApiKey;
    try {
      final doc = await _firestore.collection('app_config').doc('api_keys').get();
      if (doc.exists) {
        _geminiApiKey = doc.data()?['gemini_api_key'] as String?;
      }
    } catch (e) {
      debugPrint('ChatLearningService: Failed to load API key: $e');
    }
    return _geminiApiKey;
  }

  Future<Map<String, dynamic>?> _callGemini(String prompt) async {
    final apiKey = await _getApiKey();
    if (apiKey == null) return null;

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1024},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          // Try to parse as JSON, otherwise return as raw text
          try {
            return jsonDecode(text) as Map<String, dynamic>;
          } catch (_) {
            return {'text': text};
          }
        }
      }
    } catch (e) {
      debugPrint('ChatLearningService: Gemini call failed: $e');
    }
    return null;
  }

  /// Get 3 smart reply suggestions in the learning language
  Future<List<String>> getSmartReplies(String receivedMessage, String targetLanguage, String userLanguage) async {
    final cacheKey = '${receivedMessage.hashCode}_$targetLanguage';
    if (_smartReplyCache.containsKey(cacheKey)) return _smartReplyCache[cacheKey]!;

    final langName = _langName(targetLanguage);
    final userLangName = _langName(userLanguage);
    final result = await _callGemini(
      'Given this chat message: "$receivedMessage"\n'
      'Suggest exactly 3 short, natural reply options in $langName. '
      'Each reply should be casual and conversational (1-8 words). '
      'Return ONLY a JSON object: {"replies": ["reply1", "reply2", "reply3"], "translations": ["translation1 in $userLangName", "translation2 in $userLangName", "translation3 in $userLangName"]}'
    );

    if (result != null && result['replies'] != null) {
      final replies = List<String>.from(result['replies']);
      _smartReplyCache[cacheKey] = replies;
      // Also cache translations
      if (result['translations'] != null) {
        _smartReplyCache['${cacheKey}_tr'] = List<String>.from(result['translations']);
      }
      return replies;
    }
    return [];
  }

  /// Get cached translations for smart replies
  List<String> getSmartReplyTranslations(String receivedMessage, String targetLanguage) {
    final cacheKey = '${receivedMessage.hashCode}_${targetLanguage}_tr';
    return _smartReplyCache[cacheKey] ?? [];
  }

  /// Check grammar and suggest corrections (Firestore cached)
  Future<Map<String, dynamic>?> checkGrammar(String text, String language) async {
    final cacheKey = '${text.hashCode}_$language';
    if (_correctionCache.containsKey(cacheKey)) {
      return jsonDecode(_correctionCache[cacheKey]!) as Map<String, dynamic>;
    }

    // Check Firestore cache
    try {
      final doc = await _firestore.collection('ai_cache').doc('gram_$cacheKey').get();
      if (doc.exists) {
        final data = doc.data()!;
        final result = <String, dynamic>{
          'hasErrors': data['hasErrors'],
          'corrected': data['corrected'],
          'explanation': data['explanation'],
        };
        _correctionCache[cacheKey] = jsonEncode(result);
        return result;
      }
    } catch (_) {}

    final langName = _langName(language);
    final result = await _callGemini(
      'Check this $langName text for grammar and spelling errors: "$text"\n'
      'Return ONLY a JSON object: {"hasErrors": true/false, "corrected": "corrected text", "explanation": "brief explanation of errors in English"}\n'
      'If no errors, set hasErrors to false and corrected to the original text.'
    );

    if (result != null && result.containsKey('hasErrors')) {
      _correctionCache[cacheKey] = jsonEncode(result);

      // Cache to Firestore (non-blocking)
      _firestore.collection('ai_cache').doc('gram_$cacheKey').set({
        ...result, 'text': text, 'language': language,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      return result;
    }
    return null;
  }

  /// Get cultural context for idioms/slang in a message (Firestore cached)
  Future<String?> getCulturalTooltip(String text, String language) async {
    final cacheKey = '${text.hashCode}_$language';
    if (_culturalTooltipCache.containsKey(cacheKey)) return _culturalTooltipCache[cacheKey];

    // Check Firestore cache
    try {
      final doc = await _firestore.collection('ai_cache').doc('cult_$cacheKey').get();
      if (doc.exists) {
        final tooltip = doc.data()?['tooltip'] as String?;
        if (tooltip != null) {
          _culturalTooltipCache[cacheKey] = tooltip;
          return tooltip;
        }
        return null; // Cached as no context
      }
    } catch (_) {}

    final langName = _langName(language);
    final result = await _callGemini(
      'Analyze this $langName text for idioms, slang, or cultural expressions: "$text"\n'
      'If it contains any, return a JSON object: {"hasContext": true, "expression": "the idiom/expression found", "literal": "literal word-by-word translation", "meaning": "actual meaning", "cultural_note": "brief cultural context"}\n'
      'If it is plain/literal language with no idioms or cultural nuance, return: {"hasContext": false}'
    );

    if (result != null && result['hasContext'] == true) {
      final tooltip = '${result['expression']}\n'
          'Literal: ${result['literal']}\n'
          'Meaning: ${result['meaning']}\n'
          '${result['cultural_note'] ?? ''}';
      _culturalTooltipCache[cacheKey] = tooltip;

      // Cache to Firestore (non-blocking)
      _firestore.collection('ai_cache').doc('cult_$cacheKey').set({
        'tooltip': tooltip, 'text': text, 'language': language,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      return tooltip;
    }

    // Cache negative result too
    _firestore.collection('ai_cache').doc('cult_$cacheKey').set({
      'tooltip': null, 'text': text, 'language': language,
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    return null;
  }

  /// Break down a message word by word with translations (Firestore cached)
  Future<List<Map<String, String>>> getWordBreakdown(String text, String sourceLanguage, String targetLanguage) async {
    final cacheKey = '${text.hashCode}_${sourceLanguage}_$targetLanguage';
    if (_wordBreakdownCache.containsKey(cacheKey)) return _wordBreakdownCache[cacheKey]!;

    // Check Firestore cache
    try {
      final doc = await _firestore.collection('ai_cache').doc('wb_$cacheKey').get();
      if (doc.exists && doc.data()?['words'] != null) {
        final words = (doc.data()!['words'] as List).map((w) => Map<String, String>.from({
          'word': w['word']?.toString() ?? '',
          'translation': w['translation']?.toString() ?? '',
          'pos': w['pos']?.toString() ?? '',
        })).toList();
        _wordBreakdownCache[cacheKey] = words;
        return words;
      }
    } catch (_) {}

    final srcName = _langName(sourceLanguage);
    final tgtName = _langName(targetLanguage);
    final result = await _callGemini(
      'Break down this $srcName sentence word by word: "$text"\n'
      'For each word, provide translation to $tgtName and part of speech.\n'
      'Return ONLY a JSON object: {"words": [{"word": "original", "translation": "translated", "pos": "noun/verb/adj/etc"}]}'
    );

    if (result != null && result['words'] != null) {
      final words = (result['words'] as List).map((w) => Map<String, String>.from({
        'word': w['word']?.toString() ?? '',
        'translation': w['translation']?.toString() ?? '',
        'pos': w['pos']?.toString() ?? '',
      })).toList();
      _wordBreakdownCache[cacheKey] = words;

      // Cache to Firestore (non-blocking)
      _firestore.collection('ai_cache').doc('wb_$cacheKey').set({
        'words': words, 'text': text,
        'sourceLanguage': sourceLanguage, 'targetLanguage': targetLanguage,
        'createdAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      return words;
    }
    return [];
  }

  /// Get CEFR difficulty level for a message (Firestore cached)
  Future<String> getMessageDifficulty(String text, String language) async {
    final cacheKey = '${text.hashCode}_$language';
    if (_difficultyCache.containsKey(cacheKey)) return _difficultyCache[cacheKey]!;

    // Check Firestore cache
    try {
      final doc = await _firestore.collection('ai_cache').doc('diff_$cacheKey').get();
      if (doc.exists) {
        final level = doc.data()?['level'] as String? ?? 'A1';
        _difficultyCache[cacheKey] = level;
        return level;
      }
    } catch (_) {}

    final langName = _langName(language);
    final result = await _callGemini(
      'Assess the CEFR difficulty level of this $langName text: "$text"\n'
      'Return ONLY a JSON object: {"level": "A1/A2/B1/B2/C1/C2"}'
    );

    final level = result?['level'] as String? ?? 'A1';
    _difficultyCache[cacheKey] = level;

    // Cache to Firestore (non-blocking)
    _firestore.collection('ai_cache').doc('diff_$cacheKey').set({
      'level': level, 'text': text, 'language': language,
      'createdAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});

    return level;
  }

  /// Get romanization for non-Latin script text
  Future<String?> getRomanization(String text, String language) async {
    // Only romanize non-Latin scripts
    if (!_needsRomanization(language)) return null;

    final cacheKey = '${text.hashCode}_$language';
    if (_romanizationCache.containsKey(cacheKey)) return _romanizationCache[cacheKey];

    final langName = _langName(language);
    final result = await _callGemini(
      'Romanize this $langName text (convert to Latin alphabet pronunciation): "$text"\n'
      'Return ONLY a JSON object: {"romanized": "romanized text"}'
    );

    final romanized = result?['romanized'] as String?;
    if (romanized != null) {
      _romanizationCache[cacheKey] = romanized;
    }
    return romanized;
  }

  bool _needsRomanization(String language) {
    const nonLatinLanguages = {'ja', 'ko', 'zh', 'ar', 'hi', 'ru', 'th', 'japanese', 'korean', 'chinese', 'arabic', 'hindi', 'russian', 'thai'};
    return nonLatinLanguages.contains(language.toLowerCase());
  }

  String _langName(String language) {
    if (language.length > 3) return language;
    final upper = language.toUpperCase().replaceAll('-', '_');
    const names = {
      'EN': 'English', 'IT': 'Italian', 'ES': 'Spanish',
      'FR': 'French', 'DE': 'German', 'PT': 'Portuguese',
      'PT_BR': 'Brazilian Portuguese',
      'JA': 'Japanese', 'KO': 'Korean', 'ZH': 'Chinese',
      'AR': 'Arabic', 'HI': 'Hindi', 'TR': 'Turkish', 'RU': 'Russian',
    };
    return names[upper] ?? language;
  }

  void clearCaches() {
    _smartReplyCache.clear();
    _correctionCache.clear();
    _culturalTooltipCache.clear();
    _wordBreakdownCache.clear();
    _romanizationCache.clear();
    _difficultyCache.clear();
  }
}
