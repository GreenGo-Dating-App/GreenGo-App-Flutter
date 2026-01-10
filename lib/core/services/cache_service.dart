import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Service for reducing Firestore reads
/// Implements in-memory caching with persistent storage fallback
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();

  CacheService._();

  // Hive boxes for different data types
  late Box<String> _profilesBox;
  late Box<String> _settingsBox;
  late Box<String> _generalBox;

  // In-memory cache for frequently accessed data
  final Map<String, _CacheEntry> _memoryCache = {};

  // Cache configuration
  static const Duration defaultTTL = Duration(minutes: 5);
  static const Duration profileTTL = Duration(minutes: 10);
  static const Duration settingsTTL = Duration(hours: 1);
  static const int maxMemoryCacheSize = 100;

  /// Initialize the cache service
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      _profilesBox = await Hive.openBox<String>('profiles_cache');
      _settingsBox = await Hive.openBox<String>('settings_cache');
      _generalBox = await Hive.openBox<String>('general_cache');

      debugPrint('✓ Cache Service initialized');
    } catch (e) {
      debugPrint('⚠️ Cache initialization error: $e');
    }
  }

  // ============================================================================
  // PROFILE CACHING
  // ============================================================================

  /// Get cached profile
  Map<String, dynamic>? getProfile(String userId) {
    // Check memory cache first
    final memKey = 'profile_$userId';
    final memEntry = _memoryCache[memKey];
    if (memEntry != null && !memEntry.isExpired) {
      return memEntry.data as Map<String, dynamic>?;
    }

    // Check persistent cache
    try {
      final cached = _profilesBox.get(userId);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = data['_cachedAt'] as int?;
        if (timestamp != null) {
          final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (DateTime.now().difference(cachedAt) < profileTTL) {
            // Update memory cache
            _setMemoryCache(memKey, data, profileTTL);
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }

    return null;
  }

  /// Cache profile data
  Future<void> cacheProfile(String userId, Map<String, dynamic> profile) async {
    try {
      final data = Map<String, dynamic>.from(profile);
      data['_cachedAt'] = DateTime.now().millisecondsSinceEpoch;

      // Memory cache
      _setMemoryCache('profile_$userId', data, profileTTL);

      // Persistent cache
      await _profilesBox.put(userId, jsonEncode(data));
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Invalidate profile cache
  Future<void> invalidateProfile(String userId) async {
    _memoryCache.remove('profile_$userId');
    await _profilesBox.delete(userId);
  }

  // ============================================================================
  // GENERAL DATA CACHING
  // ============================================================================

  /// Get cached data with custom key
  T? get<T>(String key, {Duration? ttl}) {
    final effectiveTTL = ttl ?? defaultTTL;

    // Check memory cache
    final memEntry = _memoryCache[key];
    if (memEntry != null && !memEntry.isExpired) {
      return memEntry.data as T?;
    }

    // Check persistent cache
    try {
      final cached = _generalBox.get(key);
      if (cached != null) {
        final wrapper = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = wrapper['_cachedAt'] as int?;
        if (timestamp != null) {
          final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (DateTime.now().difference(cachedAt) < effectiveTTL) {
            final data = wrapper['data'];
            _setMemoryCache(key, data, effectiveTTL);
            return data as T?;
          }
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }

    return null;
  }

  /// Set cached data with custom key
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    final effectiveTTL = ttl ?? defaultTTL;

    try {
      // Memory cache
      _setMemoryCache(key, data, effectiveTTL);

      // Persistent cache
      final wrapper = {
        'data': data,
        '_cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await _generalBox.put(key, jsonEncode(wrapper));
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  /// Remove cached data
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    await _generalBox.delete(key);
  }

  // ============================================================================
  // LIST CACHING (for paginated data)
  // ============================================================================

  /// Get cached list
  List<Map<String, dynamic>>? getList(String key) {
    final cached = get<List<dynamic>>(key);
    if (cached != null) {
      return cached.cast<Map<String, dynamic>>();
    }
    return null;
  }

  /// Cache list data
  Future<void> cacheList(String key, List<Map<String, dynamic>> data,
      {Duration? ttl}) async {
    await set(key, data, ttl: ttl ?? defaultTTL);
  }

  // ============================================================================
  // SETTINGS CACHING (longer TTL)
  // ============================================================================

  /// Get cached settings
  Map<String, dynamic>? getSettings(String key) {
    // Check memory cache
    final memKey = 'settings_$key';
    final memEntry = _memoryCache[memKey];
    if (memEntry != null && !memEntry.isExpired) {
      return memEntry.data as Map<String, dynamic>?;
    }

    // Check persistent cache
    try {
      final cached = _settingsBox.get(key);
      if (cached != null) {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = data['_cachedAt'] as int?;
        if (timestamp != null) {
          final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
          if (DateTime.now().difference(cachedAt) < settingsTTL) {
            _setMemoryCache(memKey, data, settingsTTL);
            return data;
          }
        }
      }
    } catch (e) {
      debugPrint('Settings cache read error: $e');
    }

    return null;
  }

  /// Cache settings data
  Future<void> cacheSettings(String key, Map<String, dynamic> settings) async {
    try {
      final data = Map<String, dynamic>.from(settings);
      data['_cachedAt'] = DateTime.now().millisecondsSinceEpoch;

      _setMemoryCache('settings_$key', data, settingsTTL);
      await _settingsBox.put(key, jsonEncode(data));
    } catch (e) {
      debugPrint('Settings cache write error: $e');
    }
  }

  // ============================================================================
  // CACHE MANAGEMENT
  // ============================================================================

  /// Clear all caches
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _profilesBox.clear();
    await _settingsBox.clear();
    await _generalBox.clear();
    debugPrint('All caches cleared');
  }

  /// Clear expired entries
  Future<void> cleanupExpired() async {
    // Clean memory cache
    _memoryCache.removeWhere((key, entry) => entry.isExpired);

    // Clean persistent caches - profiles
    final profileKeys = _profilesBox.keys.toList();
    for (final key in profileKeys) {
      try {
        final cached = _profilesBox.get(key);
        if (cached != null) {
          final data = jsonDecode(cached) as Map<String, dynamic>;
          final timestamp = data['_cachedAt'] as int?;
          if (timestamp != null) {
            final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (DateTime.now().difference(cachedAt) > profileTTL) {
              await _profilesBox.delete(key);
            }
          }
        }
      } catch (e) {
        await _profilesBox.delete(key);
      }
    }

    debugPrint('Cache cleanup completed');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memoryEntries': _memoryCache.length,
      'profilesEntries': _profilesBox.length,
      'settingsEntries': _settingsBox.length,
      'generalEntries': _generalBox.length,
    };
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  void _setMemoryCache(String key, dynamic data, Duration ttl) {
    // Enforce max size
    if (_memoryCache.length >= maxMemoryCacheSize) {
      // Remove oldest entries
      final sortedKeys = _memoryCache.keys.toList()
        ..sort((a, b) {
          final aEntry = _memoryCache[a]!;
          final bEntry = _memoryCache[b]!;
          return aEntry.createdAt.compareTo(bEntry.createdAt);
        });

      for (int i = 0; i < 10 && sortedKeys.isNotEmpty; i++) {
        _memoryCache.remove(sortedKeys[i]);
      }
    }

    _memoryCache[key] = _CacheEntry(data, ttl);
  }
}

/// Internal cache entry with TTL tracking
class _CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final Duration ttl;

  _CacheEntry(this.data, this.ttl) : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Global cache instance
final cacheService = CacheService.instance;
