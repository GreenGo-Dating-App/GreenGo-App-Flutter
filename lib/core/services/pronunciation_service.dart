import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service for generating and caching pronunciation audio.
///
/// Uses Google Cloud TTS (Chirp 3 HD) for high-quality neural voices.
/// Each TTS listen costs 1 coin — coin deduction is handled by the caller.
///
/// Strategy: Check Firestore cache first. If the phrase+language combination
/// already has a cached audio URL, return it. Otherwise, call Cloud TTS to
/// generate the audio, upload to Firebase Storage, cache the URL in Firestore,
/// and return it.
class PronunciationService {
  static final PronunciationService _instance = PronunciationService._();
  factory PronunciationService() => _instance;
  PronunciationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // In-memory cache to avoid repeated Firestore reads within same session
  final Map<String, String> _memoryCache = {};

  String? _cloudTtsApiKey;

  /// Load API key from Firestore config (never hardcoded)
  Future<String?> _getApiKey() async {
    if (_cloudTtsApiKey != null) return _cloudTtsApiKey;
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('api_keys')
          .get();
      if (doc.exists) {
        // Use dedicated cloud_tts_api_key, or fall back to gemini_api_key
        // (same Google Cloud project key works for both)
        _cloudTtsApiKey = doc.data()?['cloud_tts_api_key'] as String?
            ?? doc.data()?['gemini_api_key'] as String?;
      }
    } catch (e) {
      debugPrint('PronunciationService: Failed to load API key: $e');
    }
    return _cloudTtsApiKey;
  }

  /// Generate a cache key from phrase + language + voice version
  String _cacheKey(String phrase, String language) {
    final normalized = phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return 'v5c_${language.toLowerCase()}_${normalized.hashCode.abs()}';
  }

  // Local file path cache (messageKey -> local file path)
  final Map<String, String> _filePathCache = {};

  /// Get pronunciation audio as a local file path for playback.
  ///
  /// Strategy: local file cache → Firestore/Storage cache → Cloud TTS generate.
  /// Audio is saved to Firebase Storage for cross-device/cross-session reuse.
  Future<String?> getPronunciationFilePath(String phrase, String language, {bool isMale = true}) async {
    final genderSuffix = isMale ? '_m' : '_f';
    final key = '${_cacheKey(phrase, language)}$genderSuffix';

    // 1. Check local file cache
    if (_filePathCache.containsKey(key)) {
      final path = _filePathCache[key]!;
      if (File(path).existsSync()) return path;
      _filePathCache.remove(key);
    }

    // 2. Check Firestore cache → download from Storage
    try {
      final doc = await _firestore
          .collection('pronunciation_cache')
          .doc(key)
          .get();

      if (doc.exists) {
        final url = doc.data()?['audioUrl'] as String?;
        if (url != null) {
          final localPath = await _downloadToLocal(key, url);
          if (localPath != null) {
            doc.reference.update({
              'accessCount': FieldValue.increment(1),
              'lastAccessed': FieldValue.serverTimestamp(),
            }).catchError((_) {});
            return localPath;
          }
        }
      }
    } catch (e) {
      debugPrint('PronunciationService: Firestore cache check failed: $e');
    }

    // 3. Generate via Google Cloud TTS (Chirp 3 HD)
    final audioBytes = await _generatePronunciation(phrase, language, isMale: isMale);
    if (audioBytes == null) return null;

    // 4. Save locally for immediate playback
    final localPath = await _saveLocally(key, audioBytes);
    if (localPath == null) return null;

    // 5. Upload to Firebase Storage + cache in Firestore (background)
    _uploadToFirebase(key, phrase, language, audioBytes).catchError((_) {});

    return localPath;
  }

  /// Download audio from URL to a local temp file
  Future<String?> _downloadToLocal(String key, String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return await _saveLocally(key, response.bodyBytes);
      }
    } catch (e) {
      debugPrint('PronunciationService: Download failed: $e');
    }
    return null;
  }

  /// Save audio bytes to local temp file
  Future<String?> _saveLocally(String key, Uint8List audioBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tts_$key.mp3');
      await file.writeAsBytes(audioBytes);
      _filePathCache[key] = file.path;
      debugPrint('PronunciationService: Saved to ${file.path} (${audioBytes.length} bytes)');
      return file.path;
    } catch (e) {
      debugPrint('PronunciationService: Local save failed: $e');
      return null;
    }
  }

  /// Upload to Firebase Storage and cache URL in Firestore (background, non-blocking)
  Future<void> _uploadToFirebase(String key, String phrase, String language, Uint8List audioBytes) async {
    try {
      final storagePath = 'pronunciation_audio/$language/$key.mp3';
      final ref = _storage.ref(storagePath);
      await ref.putData(audioBytes, SettableMetadata(contentType: 'audio/mpeg'));
      final downloadUrl = await ref.getDownloadURL();
      await _firestore.collection('pronunciation_cache').doc(key).set({
        'phrase': phrase,
        'language': language,
        'audioUrl': downloadUrl,
        'storagePath': storagePath,
        'createdAt': FieldValue.serverTimestamp(),
        'lastAccessed': FieldValue.serverTimestamp(),
        'accessCount': 1,
      });
      debugPrint('PronunciationService: Uploaded to Firebase Storage');
    } catch (e) {
      debugPrint('PronunciationService: Firebase upload failed (non-blocking): $e');
    }
  }

  /// Legacy URL-based method (kept for compatibility)
  Future<String?> getPronunciationUrl(String phrase, String language, {bool isMale = true}) async {
    final filePath = await getPronunciationFilePath(phrase, language, isMale: isMale);
    return filePath != null ? 'file://$filePath' : null;
  }

  // ===== Google Cloud TTS (Chirp 3 HD) =====

  /// Map language code to Google Cloud TTS language code
  String _getCloudTtsLanguageCode(String language) {
    final lower = language.toLowerCase().replaceAll('_', '-');
    const mapping = {
      'en': 'en-US',
      'it': 'it-IT',
      'es': 'es-ES',
      'fr': 'fr-FR',
      'de': 'de-DE',
      'pt': 'pt-PT',
      'pt-br': 'pt-BR',
      'ja': 'ja-JP',
      'ko': 'ko-KR',
      'zh': 'cmn-CN',
      'ar': 'ar-XA',
      'hi': 'hi-IN',
      'tr': 'tr-TR',
      'ru': 'ru-RU',
    };
    // If already a full code like en-US, use as-is or map it
    if (lower.contains('-') && lower.length >= 4) {
      return mapping[lower] ?? lower;
    }
    return mapping[lower] ?? 'en-US';
  }

  /// Get Chirp 3 HD voice name. Male: Orus, Female: Kore.
  String _getChirp3VoiceName(String languageCode, {bool isMale = true}) {
    final voiceName = isMale ? 'Orus' : 'Kore';
    return '$languageCode-Chirp3-HD-$voiceName';
  }

  /// Synthesize speech using Google Cloud TTS Chirp 3 HD. Returns MP3 bytes.
  Future<Uint8List?> _synthesizeWithCloudTts(
      String phrase, String apiKey, String languageCode, String voiceName) async {
    final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey');

    final body = jsonEncode({
      'input': {'text': phrase},
      'voice': {
        'languageCode': languageCode,
        'name': voiceName,
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
      },
    });

    debugPrint('PronunciationService: Cloud TTS - voice=$voiceName, lang=$languageCode');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final audioContent = json['audioContent'] as String?;
      if (audioContent != null && audioContent.isNotEmpty) {
        debugPrint('PronunciationService: Cloud TTS success (Chirp 3 HD)');
        return base64Decode(audioContent);
      }
      debugPrint('PronunciationService: Cloud TTS - no audioContent in response');
    } else {
      debugPrint(
          'PronunciationService: Cloud TTS error ${response.statusCode}: '
          '${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
    }
    return null;
  }

  /// Generate pronunciation audio using Google Cloud TTS (Chirp 3 HD).
  /// Retries up to 3 times.
  Future<Uint8List?> _generatePronunciation(
      String phrase, String language, {bool isMale = true}) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('PronunciationService: No API key configured');
      return null;
    }

    final languageCode = _getCloudTtsLanguageCode(language);
    final voiceName = _getChirp3VoiceName(languageCode, isMale: isMale);

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint('PronunciationService: Attempt $attempt - Cloud TTS (Chirp 3 HD)');
        final result = await _synthesizeWithCloudTts(phrase, apiKey, languageCode, voiceName);
        if (result != null) return result;
      } catch (e) {
        debugPrint('PronunciationService: Attempt $attempt failed: $e');
      }

      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    debugPrint('PronunciationService: All TTS attempts failed after 3 retries');
    return null;
  }

  /// Pre-warm cache for common phrases in a language.
  Future<void> prewarmCommonPhrases(String language) async {
    const commonPhrases = [
      'Hello', 'Goodbye', 'Thank you', 'Please', 'Yes', 'No',
      'How are you?', 'Nice to meet you', 'My name is...',
      'I don\'t understand', 'Can you help me?', 'Where is...?',
      'How much does it cost?', 'Good morning', 'Good night',
    ];

    for (final phrase in commonPhrases) {
      final key = _cacheKey(phrase, language);
      final doc = await _firestore
          .collection('pronunciation_cache')
          .doc(key)
          .get();
      if (!doc.exists) {
        await getPronunciationUrl(phrase, language);
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
