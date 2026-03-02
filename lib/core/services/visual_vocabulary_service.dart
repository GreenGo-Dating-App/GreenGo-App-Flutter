import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for fetching contextual images for vocabulary words.
///
/// Uses free image APIs (Unsplash primary, Pexels fallback) to find
/// real-world photos that illustrate vocabulary words. Results are cached
/// in Firestore so the same word is never fetched twice.
///
/// Example: "red" → images of red flowers, red car, red sunset
/// Example: "table" → images of different kinds of tables
/// Example: "run" → images of people running
class VisualVocabularyService {
  static final VisualVocabularyService _instance = VisualVocabularyService._();
  factory VisualVocabularyService() => _instance;
  VisualVocabularyService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // In-memory cache for current session
  final Map<String, List<VocabularyImage>> _memoryCache = {};

  String? _unsplashApiKey;
  String? _pexelsApiKey;

  /// Load API keys from Firestore config
  Future<void> _loadApiKeys() async {
    if (_unsplashApiKey != null) return;
    try {
      final doc = await _firestore
          .collection('app_config')
          .doc('api_keys')
          .get();
      if (doc.exists) {
        _unsplashApiKey = doc.data()?['unsplash_api_key'] as String?;
        _pexelsApiKey = doc.data()?['pexels_api_key'] as String?;
      }
    } catch (e) {
      debugPrint('VisualVocabularyService: Failed to load API keys: $e');
    }
  }

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

    // 3. Fetch from image API
    await _loadApiKeys();
    List<VocabularyImage> images = [];

    // Try Unsplash first (better quality)
    if (_unsplashApiKey != null && _unsplashApiKey!.isNotEmpty) {
      images = await _fetchFromUnsplash(normalizedWord, count);
    }

    // Fallback to Pexels
    if (images.isEmpty && _pexelsApiKey != null && _pexelsApiKey!.isNotEmpty) {
      images = await _fetchFromPexels(normalizedWord, count);
    }

    if (images.isEmpty) {
      debugPrint('VisualVocabularyService: No images found for "$word"');
      return [];
    }

    // 4. Cache in Firestore
    try {
      await _firestore.collection('vocabulary_images').doc(cacheKey).set({
        'word': normalizedWord,
        'language': language ?? 'en',
        'images': images.map((img) => img.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastAccessed': FieldValue.serverTimestamp(),
        'accessCount': 1,
        'source': images.first.source,
      });
    } catch (e) {
      debugPrint('VisualVocabularyService: Firestore write failed: $e');
    }

    // 5. Cache in memory
    _memoryCache[cacheKey] = images;

    return images;
  }

  /// Fetch images from Unsplash API (free tier: 50 req/hour demo, unlimited production)
  Future<List<VocabularyImage>> _fetchFromUnsplash(
      String query, int count) async {
    try {
      final url = Uri.parse(
          'https://api.unsplash.com/search/photos'
          '?query=${Uri.encodeComponent(query)}'
          '&per_page=$count'
          '&orientation=squarish'
          '&content_filter=high'); // Safe images only

      final response = await http.get(url, headers: {
        'Authorization': 'Client-ID $_unsplashApiKey',
        'Accept-Version': 'v1',
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final results = json['results'] as List<dynamic>;

        return results.map((result) {
          final urls = result['urls'] as Map<String, dynamic>;
          final user = result['user'] as Map<String, dynamic>;
          return VocabularyImage(
            imageUrl: urls['small'] as String, // 400px width — good for mobile
            thumbnailUrl: urls['thumb'] as String, // 200px — for previews
            fullUrl: urls['regular'] as String, // 1080px — for detail view
            description: result['alt_description'] as String? ??
                result['description'] as String? ??
                query,
            photographer: user['name'] as String? ?? 'Unknown',
            photographerUrl: user['links']?['html'] as String?,
            source: 'unsplash',
            // Unsplash requires attribution
            attribution:
                'Photo by ${user['name'] ?? 'Unknown'} on Unsplash',
          );
        }).toList();
      } else if (response.statusCode == 403) {
        debugPrint('VisualVocabularyService: Unsplash rate limit hit');
      } else {
        debugPrint(
            'VisualVocabularyService: Unsplash error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('VisualVocabularyService: Unsplash fetch failed: $e');
    }
    return [];
  }

  /// Fetch images from Pexels API (free tier: 200 req/hour)
  Future<List<VocabularyImage>> _fetchFromPexels(
      String query, int count) async {
    try {
      final url = Uri.parse(
          'https://api.pexels.com/v1/search'
          '?query=${Uri.encodeComponent(query)}'
          '&per_page=$count'
          '&size=small');

      final response = await http.get(url, headers: {
        'Authorization': _pexelsApiKey!,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final photos = json['photos'] as List<dynamic>;

        return photos.map((photo) {
          final src = photo['src'] as Map<String, dynamic>;
          return VocabularyImage(
            imageUrl: src['medium'] as String, // 350px height
            thumbnailUrl: src['tiny'] as String, // 130px height
            fullUrl: src['large'] as String, // 940px height
            description: photo['alt'] as String? ?? query,
            photographer: photo['photographer'] as String? ?? 'Unknown',
            photographerUrl: photo['photographer_url'] as String?,
            source: 'pexels',
            attribution:
                'Photo by ${photo['photographer'] ?? 'Unknown'} on Pexels',
          );
        }).toList();
      } else if (response.statusCode == 429) {
        debugPrint('VisualVocabularyService: Pexels rate limit hit');
      } else {
        debugPrint(
            'VisualVocabularyService: Pexels error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('VisualVocabularyService: Pexels fetch failed: $e');
    }
    return [];
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
class VocabularyImage {
  final String imageUrl; // Display-ready URL (~400px)
  final String thumbnailUrl; // Small preview URL (~200px)
  final String fullUrl; // Full resolution URL
  final String description; // Alt text describing the image
  final String photographer; // Photographer name (required for attribution)
  final String? photographerUrl; // Link to photographer profile
  final String source; // 'unsplash' or 'pexels'
  final String attribution; // Full attribution text

  const VocabularyImage({
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.fullUrl,
    required this.description,
    required this.photographer,
    this.photographerUrl,
    required this.source,
    required this.attribution,
  });

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
}
