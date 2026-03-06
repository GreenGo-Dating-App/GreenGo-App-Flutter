import 'package:equatable/equatable.dart';

/// Represents a supported language in the app
class SupportedLanguage extends Equatable {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isPremium;
  final int totalPhrases;
  final String? region;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    this.isPremium = false,
    this.totalPhrases = 0,
    this.region,
  });

  @override
  List<Object?> get props => [
        code,
        name,
        nativeName,
        flag,
        isPremium,
        totalPhrases,
        region,
      ];

  /// All supported languages in the app
  static const List<SupportedLanguage> allLanguages = [
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'pt-BR',
      name: 'Brazilian Portuguese',
      nativeName: 'Português Brasileiro',
      flag: '🇧🇷',
      region: 'South America',
    ),
  ];

  /// Get language by code
  static SupportedLanguage? getByCode(String code) {
    try {
      return allLanguages.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Get languages by region
  static List<SupportedLanguage> getByRegion(String region) {
    return allLanguages.where((lang) => lang.region == region).toList();
  }

  /// Get all regions
  static List<String> get allRegions {
    return allLanguages
        .map((lang) => lang.region)
        .whereType<String>()
        .toSet()
        .toList();
  }

  /// Get available target languages (excluding the user's native language).
  /// A user cannot learn a language they already speak natively.
  static List<SupportedLanguage> availableTargets(String nativeLangCode) {
    return allLanguages
        .where((lang) => lang.code != nativeLangCode)
        .toList();
  }
}
