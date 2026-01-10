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
    // European Languages
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
    SupportedLanguage(
      code: 'nl',
      name: 'Dutch',
      nativeName: 'Nederlands',
      flag: '🇳🇱',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'pl',
      name: 'Polish',
      nativeName: 'Polski',
      flag: '🇵🇱',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'uk',
      name: 'Ukrainian',
      nativeName: 'Українська',
      flag: '🇺🇦',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'sv',
      name: 'Swedish',
      nativeName: 'Svenska',
      flag: '🇸🇪',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'no',
      name: 'Norwegian',
      nativeName: 'Norsk',
      flag: '🇳🇴',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'da',
      name: 'Danish',
      nativeName: 'Dansk',
      flag: '🇩🇰',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'fi',
      name: 'Finnish',
      nativeName: 'Suomi',
      flag: '🇫🇮',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'el',
      name: 'Greek',
      nativeName: 'Ελληνικά',
      flag: '🇬🇷',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'cs',
      name: 'Czech',
      nativeName: 'Čeština',
      flag: '🇨🇿',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'ro',
      name: 'Romanian',
      nativeName: 'Română',
      flag: '🇷🇴',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'hu',
      name: 'Hungarian',
      nativeName: 'Magyar',
      flag: '🇭🇺',
      region: 'Europe',
    ),
    SupportedLanguage(
      code: 'tr',
      name: 'Turkish',
      nativeName: 'Türkçe',
      flag: '🇹🇷',
      region: 'Europe/Asia',
    ),

    // Asian Languages
    SupportedLanguage(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'zh',
      name: 'Chinese (Simplified)',
      nativeName: '简体中文',
      flag: '🇨🇳',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'zh-TW',
      name: 'Chinese (Traditional)',
      nativeName: '繁體中文',
      flag: '🇹🇼',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'th',
      name: 'Thai',
      nativeName: 'ไทย',
      flag: '🇹🇭',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'vi',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flag: '🇻🇳',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'id',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flag: '🇮🇩',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'ms',
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
      flag: '🇲🇾',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'tl',
      name: 'Filipino',
      nativeName: 'Tagalog',
      flag: '🇵🇭',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'bn',
      name: 'Bengali',
      nativeName: 'বাংলা',
      flag: '🇧🇩',
      region: 'Asia',
    ),
    SupportedLanguage(
      code: 'ta',
      name: 'Tamil',
      nativeName: 'தமிழ்',
      flag: '🇮🇳',
      region: 'Asia',
    ),

    // Middle Eastern Languages
    SupportedLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      region: 'Middle East',
    ),
    SupportedLanguage(
      code: 'he',
      name: 'Hebrew',
      nativeName: 'עברית',
      flag: '🇮🇱',
      region: 'Middle East',
    ),
    SupportedLanguage(
      code: 'fa',
      name: 'Persian',
      nativeName: 'فارسی',
      flag: '🇮🇷',
      region: 'Middle East',
    ),

    // African Languages
    SupportedLanguage(
      code: 'sw',
      name: 'Swahili',
      nativeName: 'Kiswahili',
      flag: '🇰🇪',
      region: 'Africa',
    ),
    SupportedLanguage(
      code: 'af',
      name: 'Afrikaans',
      nativeName: 'Afrikaans',
      flag: '🇿🇦',
      region: 'Africa',
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
}
