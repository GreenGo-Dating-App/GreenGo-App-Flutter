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

  // Local file path cache (messageKey -> local file path)
  final Map<String, String> _filePathCache = {};

  /// Get pronunciation audio as a local file path for playback.
  ///
  /// Strategy: memory cache → local file → Firestore/Storage cache → Gemini generate.
  /// Audio is saved to Firebase Storage for cross-device/cross-session reuse.
  Future<String?> getPronunciationFilePath(String phrase, String language) async {
    final key = _cacheKey(phrase, language);

    // 1. Check local file cache
    if (_filePathCache.containsKey(key)) {
      final path = _filePathCache[key]!;
      if (File(path).existsSync()) return path;
      _filePathCache.remove(key); // File was cleaned up
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
          // Download to local file
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

    // 3. Generate via Gemini AI
    final audioBytes = await _generatePronunciation(phrase, language);
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
      final file = File('${tempDir.path}/tts_$key.wav');
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
      final storagePath = 'pronunciation_audio/$language/$key.wav';
      final ref = _storage.ref(storagePath);
      await ref.putData(audioBytes, SettableMetadata(contentType: 'audio/wav'));
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
  Future<String?> getPronunciationUrl(String phrase, String language) async {
    final filePath = await getPronunciationFilePath(phrase, language);
    return filePath != null ? 'file://$filePath' : null;
  }

  /// Try multiple Gemini model names for TTS until one works.
  static const _ttsModels = [
    'gemini-2.5-flash-preview-tts',
    'gemini-2.0-flash-live-001',
    'gemini-2.0-flash',
  ];
  String? _workingModel; // Cache the model that works

  /// Generate pronunciation audio using Gemini native TTS.
  Future<Uint8List?> _generatePronunciation(
      String phrase, String language) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('PronunciationService: No API key configured');
      return null;
    }

    // If we already found a working model, use it directly
    if (_workingModel != null) {
      try {
        final result = await _synthesizeWithGeminiTts(phrase, language, apiKey, _workingModel!);
        if (result != null) return result;
      } catch (_) {}
    }

    // Try each model until one works
    for (final model in _ttsModels) {
      try {
        debugPrint('PronunciationService: Trying model $model');
        final result = await _synthesizeWithGeminiTts(phrase, language, apiKey, model);
        if (result != null) {
          _workingModel = model;
          debugPrint('PronunciationService: Model $model works!');
          return result;
        }
      } catch (e) {
        debugPrint('PronunciationService: Model $model failed: $e');
      }
    }

    debugPrint('PronunciationService: All TTS models failed');
    return null;
  }

  /// Synthesize speech using Gemini native TTS.
  /// Returns audio wrapped in a proper WAV header so AudioPlayer can decode it.
  Future<Uint8List?> _synthesizeWithGeminiTts(
      String phrase, String language, String apiKey, String model) async {
    final languageName = _getLanguageName(language);
    // Pick a voice based on language for best accent
    final voice = _getGeminiVoice(language);

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

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
    ).timeout(const Duration(seconds: 30));

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
            final mimeType = inlineData['mimeType'] as String? ?? 'audio/L16;rate=24000';
            if (audioBase64 != null) {
              final rawPcm = base64Decode(audioBase64);
              // Gemini returns raw PCM (linear16). Wrap in WAV header for playback.
              if (mimeType.contains('L16') || mimeType.contains('pcm') || mimeType.contains('raw')) {
                // Parse sample rate from mime type (e.g., "audio/L16;rate=24000")
                int sampleRate = 24000;
                final rateMatch = RegExp(r'rate=(\d+)').firstMatch(mimeType);
                if (rateMatch != null) {
                  sampleRate = int.parse(rateMatch.group(1)!);
                }
                return _addWavHeader(rawPcm, sampleRate: sampleRate);
              }
              // Already in a playable format (WAV/MP3)
              return rawPcm;
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

  /// Add a 44-byte WAV header to raw PCM data (mono, 16-bit, given sample rate).
  Uint8List _addWavHeader(Uint8List pcmData, {int sampleRate = 24000, int channels = 1, int bitsPerSample = 16}) {
    final byteRate = sampleRate * channels * (bitsPerSample ~/ 8);
    final blockAlign = channels * (bitsPerSample ~/ 8);
    final dataSize = pcmData.length;
    final fileSize = 36 + dataSize;

    final header = ByteData(44);
    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize, Endian.little);
    header.setUint8(8, 0x57);  // W
    header.setUint8(9, 0x41);  // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    // fmt chunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // (space)
    header.setUint32(16, 16, Endian.little); // chunk size
    header.setUint16(20, 1, Endian.little);  // PCM format
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    // data chunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    // Combine header + PCM data
    final wav = Uint8List(44 + dataSize);
    wav.setRange(0, 44, header.buffer.asUint8List());
    wav.setRange(44, 44 + dataSize, pcmData);
    return wav;
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
      'brazilian portuguese': 'Kore',
      'japanese': 'Kore',
      'korean': 'Kore',
      'chinese': 'Kore',
      'arabic': 'Charon',
      'hindi': 'Charon',
      'turkish': 'Charon',
      'russian': 'Charon',
    };
    // Resolve language code to name first, then look up voice
    final langName = _getLanguageName(language).toLowerCase();
    return voiceMap[langName] ?? voiceMap[language.toLowerCase()] ?? 'Kore';
  }

  /// Get full language name from code or name for the TTS prompt.
  String _getLanguageName(String language) {
    final upper = language.toUpperCase().replaceAll('-', '_');
    const names = {
      'EN': 'English', 'IT': 'Italian', 'ES': 'Spanish',
      'FR': 'French', 'DE': 'German', 'PT': 'Portuguese',
      'PT_BR': 'Brazilian Portuguese',
      'JA': 'Japanese', 'KO': 'Korean', 'ZH': 'Chinese',
      'AR': 'Arabic', 'HI': 'Hindi', 'TR': 'Turkish', 'RU': 'Russian',
    };
    // Check map first, then return as-is if it looks like a full name
    return names[upper] ?? (language.length > 5 ? language : language);
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
