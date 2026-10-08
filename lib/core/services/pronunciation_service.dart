import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'ai_consent_service.dart';

/// Service for generating and caching pronunciation audio.
///
/// Audio comes from Google Cloud TTS (Chirp 3 HD) through the
/// `synthesizeSpeech` callable: the key stays on the server (audit C-08), and
/// the server fills the shared `pronunciation_cache` / `pronunciation_audio`
/// cache. Each TTS listen costs coins; the deduction is handled by the caller.
///
/// Nothing is sent to Google unless the user accepted the AI-processing
/// notice ([AiConsentService]); callers gate the tap with
/// `AiConsentGate.ensure` so the user sees why.
///
/// Strategy: session cache -> shared cache doc (server key, then the legacy
/// device-written key) -> `synthesizeSpeech`.
class PronunciationService {
  factory PronunciationService() => _instance;
  PronunciationService._();
  static final PronunciationService _instance = PronunciationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Web has no writable filesystem, so freshly synthesised audio is kept in
  // memory for the session instead of on disk.
  final Map<String, Uint8List> _webBytesCache = {};

  /// Server input cap (functions/src/ai/aiGateway.ts CAPS.ttsChars).
  static const int maxChars = 500;

  /// Legacy cache key written by older app versions (Dart String.hashCode).
  String _legacyCacheKey(String phrase, String language) {
    final normalized = phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return 'v5c_${language.toLowerCase()}_${normalized.hashCode.abs()}';
  }

  /// Same key the server computes (aiGateway.ts ttsCacheKey).
  @visibleForTesting
  static String serverCacheKey(String phrase, String language, {required bool isMale}) {
    final normalized = phrase.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    var lang = language
        .toLowerCase()
        .replaceAll('_', '-')
        .replaceAll(RegExp('[^a-z0-9-]'), '');
    if (lang.length > 10) lang = lang.substring(0, 10);
    if (lang.isEmpty) lang = 'en';
    final h = sha256.convert(utf8.encode(normalized)).toString().substring(0, 40);
    return 'v6_${lang}_${h}_${isMale ? 'm' : 'f'}';
  }

  // Local file path cache (messageKey -> local file path)
  final Map<String, String> _filePathCache = {};

  /// Cached audio URL from the shared cache, or null.
  Future<String?> _cachedUrl(String phrase, String language, bool isMale) async {
    final keys = [
      serverCacheKey(phrase, language, isMale: isMale),
      '${_legacyCacheKey(phrase, language)}${isMale ? '_m' : '_f'}',
    ];
    for (final key in keys) {
      try {
        final doc = await _firestore.collection('pronunciation_cache').doc(key).get();
        final url = doc.data()?['audioUrl'] as String?;
        if (url != null && url.isNotEmpty) return url;
      } catch (e) {
        debugPrint('PronunciationService: cache check failed: $e');
      }
    }
    return null;
  }

  /// Get pronunciation audio as a local file path for playback.
  Future<String?> getPronunciationFilePath(String phrase, String language, {bool isMale = true}) async {
    // Web cannot produce a file path at all — callers must use
    // [getPronunciationSource], which handles both platforms.
    if (kIsWeb) return null;
    final key = serverCacheKey(phrase, language, isMale: isMale);

    // 1. Local file cache
    final local = _filePathCache[key];
    if (local != null) {
      if (File(local).existsSync()) return local;
      _filePathCache.remove(key);
    }

    // 2. Shared cache -> download
    final url = await _cachedUrl(phrase, language, isMale);
    if (url != null) {
      final path = await _downloadToLocal(key, url);
      if (path != null) return path;
    }

    // 3. Server synthesis
    final generated = await _synthesize(phrase, language, isMale: isMale);
    if (generated == null) return null;
    if (generated.bytes != null) return _saveLocally(key, generated.bytes!);
    if (generated.url != null) return _downloadToLocal(key, generated.url!);
    return null;
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

  /// Save audio bytes to local temp file. Native only — web has no temp dir.
  Future<String?> _saveLocally(String key, Uint8List audioBytes) async {
    if (kIsWeb) return null;
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tts_$key.mp3');
      await file.writeAsBytes(audioBytes);
      _filePathCache[key] = file.path;
      return file.path;
    } catch (e) {
      debugPrint('PronunciationService: Local save failed: $e');
      return null;
    }
  }

  /// Legacy URL-based method (kept for compatibility)
  Future<String?> getPronunciationUrl(String phrase, String language, {bool isMale = true}) async {
    final filePath = await getPronunciationFilePath(phrase, language, isMale: isMale);
    return filePath != null ? 'file://$filePath' : null;
  }

  /// Playable audio for [phrase], resolved for the current platform.
  ///
  /// Native keeps the temp-file cache. Web has neither `dart:io` nor
  /// `path_provider`, so cached audio plays straight from its Storage URL and
  /// freshly synthesised audio plays from bytes. Both platforms share the same
  /// `pronunciation_cache` documents.
  Future<ap.Source?> getPronunciationSource(
    String phrase,
    String language, {
    bool isMale = true,
  }) async {
    if (!kIsWeb) {
      final path =
          await getPronunciationFilePath(phrase, language, isMale: isMale);
      return path == null ? null : ap.DeviceFileSource(path);
    }

    final key = serverCacheKey(phrase, language, isMale: isMale);
    final cachedBytes = _webBytesCache[key];
    if (cachedBytes != null) return ap.BytesSource(cachedBytes);

    final url = await _cachedUrl(phrase, language, isMale);
    if (url != null) return ap.UrlSource(url);

    final generated = await _synthesize(phrase, language, isMale: isMale);
    if (generated == null) return null;
    if (generated.bytes != null) {
      _webBytesCache[key] = generated.bytes!;
      return ap.BytesSource(generated.bytes!);
    }
    return generated.url != null ? ap.UrlSource(generated.url!) : null;
  }

  /// Server synthesis (`synthesizeSpeech`). Null without consent, for text
  /// over the cap, or when the call failed.
  Future<({Uint8List? bytes, String? url})?> _synthesize(
      String phrase, String language, {required bool isMale}) async {
    if (phrase.trim().isEmpty || phrase.length > maxChars) return null;
    final consent = AiConsentService.instance;
    await consent.ensureLoaded();
    if (!consent.isGranted) {
      debugPrint('PronunciationService: AI consent not granted');
      return null;
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await FirebaseFunctions.instance
            .httpsCallable('synthesizeSpeech',
                options: HttpsCallableOptions(timeout: const Duration(seconds: 45)))
            .call<Map<String, dynamic>>({
          'text': phrase,
          'language': language,
          'isMale': isMale,
        });
        final b64 = res.data['audioContent'] as String?;
        final url = res.data['audioUrl'] as String?;
        return (
          bytes: (b64 != null && b64.isNotEmpty) ? base64Decode(b64) : null,
          url: (url != null && url.isNotEmpty) ? url : null,
        );
      } catch (e) {
        if (attempt == 0 && isAiConsentRequiredError(e) &&
            await consent.resyncAfterServerRejection()) {
          continue;
        }
        debugPrint('PronunciationService: synthesizeSpeech failed: $e');
        return null;
      }
    }
    return null;
  }

  /// Clear in-memory caches (the shared cache persists)
  void clearMemoryCache() {
    _webBytesCache.clear();
    _filePathCache.clear();
  }
}
