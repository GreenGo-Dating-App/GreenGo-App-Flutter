import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for generating and caching pronunciation audio.
///
/// Strategy: Check Firestore cache first. If the phrase+language combination
/// already has a cached audio URL, return it. Otherwise, call Gemini AI to
/// generate the audio, upload to Firebase Storage, cache the URL in Firestore,
/// and return it. This means millions of users asking for the same phrase in
/// the same language will only trigger ONE API call.
class PronunciationService {
  static final PronunciationService _instance = PronunciationService._();
  factory PronunciationService() => _instance;
  PronunciationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // In-memory cache to avoid repeated Firestore reads within same session
  final Map<String, String> _memoryCache = {};

  String? _geminiApiKey;

  /// Load API key from Firestore config (never hardcoded)
  Future<String?> _getApiKey() async {
    if (_geminiApiKey != null) return _geminiApiKey;
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('api_keys')
          .get();
      if (doc.exists) {
        _geminiApiKey = doc.data()?['gemini_api_key'] as String?;
      }
    } catch (e) {
      debugPrint('PronunciationService: Failed to load API key: $e');
    }
    return _geminiApiKey;
  }

  /// Generate a cache key from phrase + language
  String _cacheKey(String phrase, String language) {
    // Normalize: lowercase, trim, remove extra spaces
    final normalized = phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return '${language.toLowerCase()}_${normalized.hashCode.abs()}';
  }

  /// Get pronunciation audio URL for a phrase in a specific language.
  ///
  /// Returns a Firebase Storage download URL, or null if generation fails.
  /// The audio is cached — subsequent calls for the same phrase+language
  /// return instantly from cache.
  Future<String?> getPronunciationUrl(String phrase, String language) async {
    final key = _cacheKey(phrase, language);

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // 2. Check Firestore cache
    try {
      final doc = await _firestore
          .collection('pronunciation_cache')
          .doc(key)
          .get();

      if (doc.exists) {
        final url = doc.data()?['audioUrl'] as String?;
        if (url != null) {
          _memoryCache[key] = url;
          // Update access count for analytics
          doc.reference.update({
            'accessCount': FieldValue.increment(1),
            'lastAccessed': FieldValue.serverTimestamp(),
          }).catchError((_) {}); // Fire and forget
          return url;
        }
      }
    } catch (e) {
      debugPrint('PronunciationService: Firestore cache read failed: $e');
    }

    // 3. Generate via Gemini AI
    final audioBytes = await _generatePronunciation(phrase, language);
    if (audioBytes == null) return null;

    // 4. Upload to Firebase Storage
    final storagePath = 'pronunciation_audio/$language/$key.mp3';
    try {
      final ref = _storage.ref(storagePath);
      await ref.putData(
        audioBytes,
        SettableMetadata(
          contentType: 'audio/mpeg',
          customMetadata: {
            'phrase': phrase,
            'language': language,
          },
        ),
      );
      final downloadUrl = await ref.getDownloadURL();

      // 5. Cache in Firestore
      await _firestore.collection('pronunciation_cache').doc(key).set({
        'phrase': phrase,
        'language': language,
        'audioUrl': downloadUrl,
        'storagePath': storagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'lastAccessed': FieldValue.serverTimestamp(),
        'accessCount': 1,
      });

      // 6. Cache in memory
      _memoryCache[key] = downloadUrl;

      return downloadUrl;
    } catch (e) {
      debugPrint('PronunciationService: Upload/cache failed: $e');
      return null;
    }
  }

  /// Generate pronunciation audio using Gemini API TTS capabilities.
  /// Falls back to Google Cloud TTS-style synthesis if Gemini TTS unavailable.
  Future<Uint8List?> _generatePronunciation(
      String phrase, String language) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('PronunciationService: No API key configured');
      return null;
    }

    try {
      // Use Gemini's generateContent with TTS instruction to get phonetic guide,
      // then use Google Cloud TTS for actual audio synthesis.
      // For now, use Google Cloud TTS directly if available, or Gemini multimodal.
      final audioBytes = await _synthesizeWithGoogleTts(phrase, language, apiKey);
      return audioBytes;
    } catch (e) {
      debugPrint('PronunciationService: Generation failed: $e');
      return null;
    }
  }

  /// Synthesize speech using Google Cloud Text-to-Speech API
  /// (shares the same GCP project as Gemini, uses same API key for simplicity)
  Future<Uint8List?> _synthesizeWithGoogleTts(
      String phrase, String language, String apiKey) async {
    // Map language names to BCP-47 codes for TTS
    final languageCode = _getLanguageCode(language);

    final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey');

    // Use Neural2 voice for extremely human-like speech
    final voiceName = _getNeuralVoice(languageCode);
    final body = jsonEncode({
      'input': {'text': phrase},
      'voice': {
        'languageCode': languageCode,
        'name': voiceName,
        'ssmlGender': 'FEMALE',
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
        'speakingRate': 0.9, // Natural pace for learning
        'pitch': 0.0,
        'effectsProfileId': ['headphone-class-device'],
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final audioContent = json['audioContent'] as String?;
      if (audioContent != null) {
        return base64Decode(audioContent);
      }
    } else {
      debugPrint(
          'PronunciationService: TTS API error ${response.statusCode}: ${response.body}');
    }
    return null;
  }

  /// Get the best Neural2/WaveNet voice for a language code.
  /// Neural2 voices are the most human-like available on Google Cloud TTS.
  String _getNeuralVoice(String languageCode) {
    const neuralVoices = {
      'en-US': 'en-US-Neural2-F',    // Female, very natural
      'en-GB': 'en-GB-Neural2-F',
      'es-ES': 'es-ES-Neural2-A',    // Female
      'fr-FR': 'fr-FR-Neural2-A',    // Female
      'de-DE': 'de-DE-Neural2-F',    // Female
      'it-IT': 'it-IT-Neural2-A',    // Female
      'pt-BR': 'pt-BR-Neural2-C',    // Female
      'ru-RU': 'ru-RU-Wavenet-A',    // Female (Neural2 not yet available)
      'ja-JP': 'ja-JP-Neural2-B',    // Female
      'ko-KR': 'ko-KR-Neural2-A',   // Female
      'ar-XA': 'ar-XA-Wavenet-A',   // Female
      'nl-NL': 'nl-NL-Wavenet-A',   // Female
      'pl-PL': 'pl-PL-Wavenet-A',   // Female
      'tr-TR': 'tr-TR-Wavenet-A',   // Female
      'hi-IN': 'hi-IN-Neural2-A',   // Female
      'sv-SE': 'sv-SE-Wavenet-A',   // Female
      'nb-NO': 'nb-NO-Wavenet-A',   // Female
      'da-DK': 'da-DK-Wavenet-A',   // Female
      'fi-FI': 'fi-FI-Wavenet-A',   // Female
      'cs-CZ': 'cs-CZ-Wavenet-A',   // Female
      'ro-RO': 'ro-RO-Wavenet-A',   // Female
      'el-GR': 'el-GR-Wavenet-A',   // Female
      'uk-UA': 'uk-UA-Wavenet-A',   // Female
      'hu-HU': 'hu-HU-Wavenet-A',   // Female
      'sk-SK': 'sk-SK-Wavenet-A',   // Female
      'bg-BG': 'bg-BG-Standard-A',  // Standard (no neural yet)
      'vi-VN': 'vi-VN-Neural2-A',   // Female
      'th-TH': 'th-TH-Neural2-C',   // Female
      'id-ID': 'id-ID-Wavenet-A',   // Female
    };
    // Try exact match, then base language
    final base = languageCode.split('-').first;
    return neuralVoices[languageCode] ??
        neuralVoices.entries
            .where((e) => e.key.startsWith(base))
            .map((e) => e.value)
            .firstOrNull ??
        'en-US-Neural2-F';
  }

  /// Map language display names to BCP-47 language codes
  String _getLanguageCode(String language) {
    const languageCodes = {
      'english': 'en-US',
      'spanish': 'es-ES',
      'french': 'fr-FR',
      'german': 'de-DE',
      'italian': 'it-IT',
      'portuguese': 'pt-BR',
      'russian': 'ru-RU',
      'japanese': 'ja-JP',
      'korean': 'ko-KR',
      'chinese': 'zh-CN',
      'arabic': 'ar-XA',
      'hindi': 'hi-IN',
      'turkish': 'tr-TR',
      'dutch': 'nl-NL',
      'swedish': 'sv-SE',
      'norwegian': 'nb-NO',
      'danish': 'da-DK',
      'finnish': 'fi-FI',
      'polish': 'pl-PL',
      'czech': 'cs-CZ',
      'romanian': 'ro-RO',
      'hungarian': 'hu-HU',
      'greek': 'el-GR',
      'thai': 'th-TH',
      'vietnamese': 'vi-VN',
      'indonesian': 'id-ID',
      'malay': 'ms-MY',
      'filipino': 'fil-PH',
      'swahili': 'sw-KE',
      'hebrew': 'he-IL',
      'persian': 'fa-IR',
      'ukrainian': 'uk-UA',
      'serbian': 'sr-RS',
      'croatian': 'hr-HR',
      'bulgarian': 'bg-BG',
      'slovak': 'sk-SK',
      'slovenian': 'sl-SI',
      'lithuanian': 'lt-LT',
      'latvian': 'lv-LV',
      'estonian': 'et-EE',
      'georgian': 'ka-GE',
    };
    return languageCodes[language.toLowerCase()] ?? 'en-US';
  }

  /// Pre-warm cache for common phrases in a language.
  /// Call this during app initialization or when user selects a learning language.
  Future<void> prewarmCommonPhrases(String language) async {
    const commonPhrases = [
      'Hello',
      'Goodbye',
      'Thank you',
      'Please',
      'Yes',
      'No',
      'How are you?',
      'Nice to meet you',
      'My name is...',
      'I don\'t understand',
      'Can you help me?',
      'Where is...?',
      'How much does it cost?',
      'I love you',
      'Good morning',
      'Good night',
    ];

    for (final phrase in commonPhrases) {
      // Check if already cached before generating
      final key = _cacheKey(phrase, language);
      final doc = await _firestore
          .collection('pronunciation_cache')
          .doc(key)
          .get();
      if (!doc.exists) {
        await getPronunciationUrl(phrase, language);
        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }

  /// Get cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final snapshot = await _firestore
          .collection('pronunciation_cache')
          .count()
          .get();
      return {
        'totalCachedPhrases': snapshot.count,
        'memoryCacheSize': _memoryCache.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear in-memory cache (Firestore cache persists)
  void clearMemoryCache() {
    _memoryCache.clear();
  }
}
