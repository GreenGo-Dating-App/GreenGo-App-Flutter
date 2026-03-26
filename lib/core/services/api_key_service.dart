import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Fetches API keys from Firebase Remote Config instead of hardcoding them.
class ApiKeyService {
  static String? _googleMapsApiKey;

  /// Get the Google Maps API key from Remote Config.
  /// Falls back to empty string if not configured.
  static String get googleMapsApiKey {
    if (_googleMapsApiKey != null) return _googleMapsApiKey!;
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      _googleMapsApiKey = remoteConfig.getString('google_maps_api_key');
      if (_googleMapsApiKey!.isEmpty) {
        debugPrint('WARNING: google_maps_api_key not set in Remote Config');
      }
    } catch (e) {
      debugPrint('Error fetching google_maps_api_key: $e');
      _googleMapsApiKey = '';
    }
    return _googleMapsApiKey!;
  }

  /// Clear cached key (e.g., after Remote Config refresh).
  static void invalidateCache() {
    _googleMapsApiKey = null;
  }
}
