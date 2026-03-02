import '../entities/entities.dart';

/// Repository interface for cultural exchange features
abstract class CulturalExchangeRepository {
  // ==================== Country Spotlights ====================

  /// Get the currently active country spotlight
  Future<CountrySpotlight?> getActiveSpotlight();

  /// Get history of past country spotlights
  Future<List<CountrySpotlight>> getSpotlightHistory();

  // ==================== Cultural Tips ====================

  /// Get cultural tips with optional filtering
  Future<List<CulturalTip>> getCulturalTips({
    String? country,
    String? category,
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
}
