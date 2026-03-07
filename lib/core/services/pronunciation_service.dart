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

  /// Generate a cache key from phrase + language + voice version
  String _cacheKey(String phrase, String language) {
    // Normalize: lowercase, trim, remove extra spaces
    final normalized = phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return 'v3g_${language.toLowerCase()}_${normalized.hashCode.abs()}';
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

  /// Generate pronunciation audio using Gemini 2.0 Flash native TTS.
  /// Produces natural, human-like speech across all supported languages.
  Future<Uint8List?> _generatePronunciation(
      String phrase, String language) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('PronunciationService: No API key configured');
      return null;
    }

    try {
      return await _synthesizeWithGeminiTts(phrase, language, apiKey);
    } catch (e) {
      debugPrint('PronunciationService: Gemini TTS failed: $e');
      return null;
    }
  }

  /// Synthesize speech using Gemini 2.0 Flash native TTS.
  /// Returns raw PCM audio encoded as WAV, then stored as .mp3 extension
  /// (Firebase Storage serves it correctly regardless).
  Future<Uint8List?> _synthesizeWithGeminiTts(
      String phrase, String language, String apiKey) async {
    final languageName = _getLanguageName(language);
    // Pick a voice based on language for best accent
    final voice = _getGeminiVoice(language);

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Say the following phrase clearly and naturally in $languageName, as a native speaker would: "$phrase"',
            },
          ],
        },
      ],
      'generationConfig': {
        'response_modalities': ['AUDIO'],
        'speech_config': {
          'voice_config': {
            'prebuilt_voice_config': {
              'voice_name': voice,
            },
          },
        },
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final inlineData =
              parts[0]['inlineData'] as Map<String, dynamic>?;
          if (inlineData != null) {
            final audioBase64 = inlineData['data'] as String?;
            if (audioBase64 != null) {
              return base64Decode(audioBase64);
            }
          }
        }
      }
      debugPrint('PronunciationService: No audio in Gemini response');
    } else {
      debugPrint(
          'PronunciationService: Gemini TTS error ${response.statusCode}: '
          '${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
    }
    return null;
  }

  /// Select a Gemini TTS voice suited for the target language.
  String _getGeminiVoice(String language) {
    // Gemini 2.0 Flash TTS voices — pick one that sounds natural per language
    const voiceMap = {
      'english': 'Kore',
      'spanish': 'Kore',
      'french': 'Kore',
      'german': 'Kore',
      'italian': 'Kore',
      'portuguese': 'Kore',
      'japanese': 'Kore',
      'korean': 'Kore',
      'chinese': 'Kore',
      'arabic': 'Charon',
      'hindi': 'Charon',
      'turkish': 'Charon',
      'russian': 'Charon',
    };
    return voiceMap[language.toLowerCase()] ?? 'Kore';
  }

  /// Get full language name from code or name for the TTS prompt.
  String _getLanguageName(String language) {
    // If it's already a full name, return as-is
    if (language.length > 3) return language;
    const names = {
      'EN': 'English', 'IT': 'Italian', 'ES': 'Spanish',
      'FR': 'French', 'DE': 'German', 'PT': 'Portuguese',
      'JA': 'Japanese', 'KO': 'Korean', 'ZH': 'Chinese',
      'AR': 'Arabic', 'HI': 'Hindi', 'TR': 'Turkish', 'RU': 'Russian',
    };
    return names[language.toUpperCase()] ?? language;
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
