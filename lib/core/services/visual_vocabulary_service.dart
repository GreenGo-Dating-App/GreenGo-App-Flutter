import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching contextual images for vocabulary words.
///
/// Images come from Unsplash (Pexels fallback) through the
/// `getVocabularyImages` callable: the API keys stay on the server (audit
/// C-08), which also caches results in `vocabulary_images` so the same word is
/// never fetched twice. Only the word itself is sent (no personal data).
///
/// Example: "red" -> images of red flowers, red car, red sunset
class VisualVocabularyService {
  factory VisualVocabularyService() => _instance;
  VisualVocabularyService._();
  static final VisualVocabularyService _instance = VisualVocabularyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache for current session
  final Map<String, List<VocabularyImage>> _memoryCache = {};

  /// Get contextual images for a vocabulary word.
  ///
  /// Returns 3-5 images showing different contexts of the word.
  /// Results are cached — first call fetches from API, subsequent calls
  /// read from Firestore cache (zero API cost).
  Future<List<VocabularyImage>> getImagesForWord(String word,
      {String? language, int count = 4}) async {
    final normalizedWord = word.trim().toLowerCase();
    final cacheKey = '${language ?? 'en'}_$normalizedWord';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // 2. Check Firestore cache
    try {
      final doc = await _firestore
          .collection('vocabulary_images')
          .doc(cacheKey)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final images = (data['images'] as List<dynamic>)
            .map((img) => VocabularyImage.fromMap(img as Map<String, dynamic>))
            .toList();
        _memoryCache[cacheKey] = images;

        // Update access count (fire and forget)
        doc.reference.update({
          'accessCount': FieldValue.increment(1),
          'lastAccessed': FieldValue.serverTimestamp(),
        }).catchError((_) {});

        return images;
      }
    } catch (e) {
      debugPrint('VisualVocabularyService: Firestore read failed: $e');
    }

    // 3. Server lookup (fills the shared cache).
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable('getVocabularyImages',
              options: HttpsCallableOptions(timeout: const Duration(seconds: 25)))
          .call<Map<String, dynamic>>({
        'word': normalizedWord,
        'language': language ?? 'en',
        'count': count,
      });
      final images = ((res.data['images'] as List?) ?? const [])
          .map((img) => VocabularyImage.fromMap(Map<String, dynamic>.from(img as Map)))
          .toList();
      if (images.isNotEmpty) _memoryCache[cacheKey] = images;
      return images;
    } catch (e) {
      debugPrint('VisualVocabularyService: getVocabularyImages failed: $e');
      return [];
    }
  }

  /// Get a single representative image for a word (the best one)
  Future<VocabularyImage?> getBestImageForWord(String word,
      {String? language}) async {
    final images = await getImagesForWord(word, language: language, count: 1);
    return images.isNotEmpty ? images.first : null;
  }

  /// Pre-warm cache for a list of vocabulary words.
  /// Call this when user starts a new lesson to preload all word images.
  Future<void> prewarmLessonImages(List<String> words,
      {String? language}) async {
    for (final word in words) {
      final cacheKey = '${language ?? 'en'}_${word.trim().toLowerCase()}';

      // Skip if already cached
      if (_memoryCache.containsKey(cacheKey)) continue;

      try {
        final doc = await _firestore
            .collection('vocabulary_images')
            .doc(cacheKey)
            .get();
        if (doc.exists) continue; // Already in Firestore cache
      } catch (_) {}

      await getImagesForWord(word, language: language);
      // Rate limit protection
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  /// Clear in-memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
  }
}

/// Represents a contextual image for a vocabulary word
class VocabularyImage { // Full attribution text

  const VocabularyImage({
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.fullUrl,
    required this.description,
    required this.photographer,
    required this.source, required this.attribution, this.photographerUrl,
  });

  factory VocabularyImage.fromMap(Map<String, dynamic> map) {
    return VocabularyImage(
      imageUrl: map['imageUrl'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      fullUrl: map['fullUrl'] as String? ?? '',
      description: map['description'] as String? ?? '',
      photographer: map['photographer'] as String? ?? 'Unknown',
      photographerUrl: map['photographerUrl'] as String?,
      source: map['source'] as String? ?? 'unknown',
      attribution: map['attribution'] as String? ?? '',
    );
  }
  final String imageUrl; // Display-ready URL (~400px)
  final String thumbnailUrl; // Small preview URL (~200px)
  final String fullUrl; // Full resolution URL
  final String description; // Alt text describing the image
  final String photographer; // Photographer name (required for attribution)
  final String? photographerUrl; // Link to photographer profile
  final String source; // 'unsplash' or 'pexels'
  final String attribution;

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'fullUrl': fullUrl,
      'description': description,
      'photographer': photographer,
      'photographerUrl': photographerUrl,
      'source': source,
      'attribution': attribution,
    };
  }
}
