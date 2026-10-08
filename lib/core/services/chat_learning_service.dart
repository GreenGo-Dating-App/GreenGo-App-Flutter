import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_l10n_lookup.dart';
import 'ai_consent_service.dart';

/// Signature of the server call (overridable in tests).
typedef AiAssistCall = Future<Map<String, dynamic>?> Function(
    Map<String, dynamic> payload);

/// Centralized service for AI-powered chat language learning features:
/// smart replies, grammar correction, cultural tooltips, word breakdown,
/// difficulty assessment and romanization.
///
/// Everything goes through the `aiAssist` callable: the Gemini key and the
/// prompt templates live on the server (audit C-08 / H-17). Nothing is sent
/// unless the user accepted the AI-processing notice ([AiConsentService]);
/// without it every method returns "no result" and the UI shows nothing.
/// Results are cached in memory only (message text is never written to a
/// shared store).
class ChatLearningService {
  factory ChatLearningService() => _instance;
  ChatLearningService._({AiAssistCall? call, AiConsentService? consent})
      : _call = call,
        _consentOverride = consent;
  static final ChatLearningService _instance = ChatLearningService._();

  @visibleForTesting
  factory ChatLearningService.test(
          {required AiAssistCall call, required AiConsentService consent}) =>
      ChatLearningService._(call: call, consent: consent);

  final AiAssistCall? _call;
  final AiConsentService? _consentOverride;
  AiConsentService get _consent => _consentOverride ?? AiConsentService.instance;

  /// Server input cap (functions/src/ai/aiGateway.ts CAPS.assistChars).
  static const int maxChars = 1000;

  // Caches to avoid repeated calls
  final Map<String, List<String>> _smartReplyCache = {};
  final Map<String, String> _correctionCache = {};
  final Map<String, String> _culturalTooltipCache = {};
  final Map<String, List<Map<String, String>>> _wordBreakdownCache = {};
  final Map<String, String> _romanizationCache = {};
  final Map<String, String> _difficultyCache = {};

  static Future<Map<String, dynamic>?> _callServer(Map<String, dynamic> payload) async {
    final res = await FirebaseFunctions.instance
        .httpsCallable('aiAssist',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)))
        .call<Map<String, dynamic>>(payload);
    final result = res.data['result'];
    return result is Map ? Map<String, dynamic>.from(result) : null;
  }

  /// Runs [task] on the server. Null when consent is missing, the text is
  /// too long, or the call failed.
  Future<Map<String, dynamic>?> _assist(String task, String text,
      {required String language, String? targetLanguage, String? userLanguage}) async {
    if (text.trim().isEmpty || text.length > maxChars) return null;
    await _consent.ensureLoaded();
    if (!_consent.isGranted) return null;
    final payload = <String, dynamic>{
      'task': task,
      'text': text,
      'language': language,
      if (targetLanguage != null) 'targetLanguage': targetLanguage,
      if (userLanguage != null) 'userLanguage': userLanguage,
    };
    final call = _call ?? _callServer;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await call(payload);
      } catch (e) {
        // Device says "granted" but the server has no record (first send
        // failed): send the consent again, then retry once.
        if (attempt == 0 && isAiConsentRequiredError(e) &&
            await _consent.resyncAfterServerRejection()) {
          continue;
        }
        debugPrint('ChatLearningService: aiAssist($task) failed: $e');
        return null;
      }
    }
    return null;
  }

  /// Get 3 smart reply suggestions in the learning language
  Future<List<String>> getSmartReplies(String receivedMessage, String targetLanguage, String userLanguage) async {
    final cacheKey = '${receivedMessage.hashCode}_$targetLanguage';
    if (_smartReplyCache.containsKey(cacheKey)) return _smartReplyCache[cacheKey]!;

    final result = await _assist('smartReplies', receivedMessage,
        language: targetLanguage,
        targetLanguage: targetLanguage,
        userLanguage: userLanguage);

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

  /// Check grammar and suggest corrections.
  Future<Map<String, dynamic>?> checkGrammar(String text, String language) async {
    final cacheKey = '${text.hashCode}_$language';
    if (_correctionCache.containsKey(cacheKey)) {
      return jsonDecode(_correctionCache[cacheKey]!) as Map<String, dynamic>;
    }
    final result = await _assist('grammar', text, language: language);
    if (result != null && result.containsKey('hasErrors')) {
      _correctionCache[cacheKey] = jsonEncode(result);
      return result;
    }
    return null;
  }

  /// Get cultural context for idioms/slang in a message.
  Future<String?> getCulturalTooltip(String text, String language) async {
    final cacheKey = '${text.hashCode}_$language';
    if (_culturalTooltipCache.containsKey(cacheKey)) return _culturalTooltipCache[cacheKey];

    final result = await _assist('cultural', text, language: language);
    if (result == null) return null; // not cached: may work later
    if (result['hasContext'] == true) {
      final l10n = await currentAppL10nAsync();
      final tooltip = '${result['expression']}\n'
          '${l10n.chatLearningLiteral('${result['literal']}')}\n'
          '${l10n.chatLearningMeaning('${result['meaning']}')}\n'
          '${result['cultural_note'] ?? ''}';
      _culturalTooltipCache[cacheKey] = tooltip;
      return tooltip;
    }
    return null;
  }

  /// Break down a message word by word with translations.
  Future<List<Map<String, String>>> getWordBreakdown(String text, String sourceLanguage, String targetLanguage) async {
    final cacheKey = '${text.hashCode}_${sourceLanguage}_$targetLanguage';
    if (_wordBreakdownCache.containsKey(cacheKey)) return _wordBreakdownCache[cacheKey]!;

    final result = await _assist('wordBreakdown', text,
        language: sourceLanguage, targetLanguage: targetLanguage);
    if (result != null && result['words'] is List) {
      final words = (result['words'] as List).map((w) => Map<String, String>.from({
        'word': w['word']?.toString() ?? '',
        'translation': w['translation']?.toString() ?? '',
        'pos': w['pos']?.toString() ?? '',
      })).toList();
      _wordBreakdownCache[cacheKey] = words;
      return words;
    }
    return [];
  }

  /// Get CEFR difficulty level for a message ('A1' when unknown).
  Future<String> getMessageDifficulty(String text, String language) async {
    final cacheKey = '${text.hashCode}_$language';
    if (_difficultyCache.containsKey(cacheKey)) return _difficultyCache[cacheKey]!;

    final result = await _assist('difficulty', text, language: language);
    final level = result?['level'] as String?;
    if (level == null) return 'A1'; // not cached: may work later
    _difficultyCache[cacheKey] = level;
    return level;
  }

  /// Get romanization for non-Latin script text
  Future<String?> getRomanization(String text, String language) async {
    // Only romanize non-Latin scripts
    if (!_needsRomanization(language)) return null;

    final cacheKey = '${text.hashCode}_$language';
    if (_romanizationCache.containsKey(cacheKey)) return _romanizationCache[cacheKey];

    final result = await _assist('romanize', text, language: language);
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

  void clearCaches() {
    _smartReplyCache.clear();
    _correctionCache.clear();
    _culturalTooltipCache.clear();
    _wordBreakdownCache.clear();
    _romanizationCache.clear();
    _difficultyCache.clear();
  }
}
