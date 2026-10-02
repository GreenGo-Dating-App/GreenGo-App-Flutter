import '../entities/entities.dart';

/// Repository interface for cultural exchange features
abstract class CulturalExchangeRepository {
  // ==================== Country Spotlights ====================

  /// Get the currently active country spotlight
  Future<CountrySpotlight?> getActiveSpotlight();

  /// The spotlight shown last time (local, no network) — for an instant
  /// first paint before [getActiveSpotlight] refreshes it. Null if none.
  Future<CountrySpotlight?> getCachedActiveSpotlight();

  /// Get history of past country spotlights
  Future<List<CountrySpotlight>> getSpotlightHistory();

  // ==================== Cultural Tips ====================

  /// Get cultural tips with optional filtering
  Future<List<CulturalTip>> getCulturalTips({
    String? country,
    String? category,
    int limit = 50,
  });

  /// Submit a new cultural tip
  Future<void> submitCulturalTip(CulturalTip tip);

  /// Like a cultural tip
  Future<void> likeCulturalTip(String tipId, String userId);

  // ==================== Dating Etiquette ====================

  /// Get dating etiquette for a specific country
  Future<DatingEtiquette?> getDatingEtiquette(String country);

  /// Get list of all available countries with dating etiquette
  Future<List<String>> getAvailableCountries();

  /// The country list saved last time (local, no network); empty if none.
  /// With [maxAge] only a list saved within that window is returned.
  Future<List<String>> getCachedAvailableCountries({Duration? maxAge});
}
