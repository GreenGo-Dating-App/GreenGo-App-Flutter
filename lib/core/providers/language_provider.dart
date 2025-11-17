import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _languageKey = 'selected_language';

  Locale get currentLocale => _currentLocale;

  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('it'), // Italian
    Locale('es'), // Spanish
    Locale('pt'), // Portuguese
    Locale('pt', 'BR'), // Portuguese (Brazil)
    Locale('fr'), // French
    Locale('de'), // German
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'it': 'Italiano',
    'es': 'Español',
    'pt': 'Português',
    'pt_BR': 'Português (Brasil)',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      final parts = languageCode.split('_');
      _currentLocale = parts.length > 1
          ? Locale(parts[0], parts[1])
          : Locale(parts[0]);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final languageCode = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_languageKey, languageCode);
  }

  String getLanguageName(Locale locale) {
    final key = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    return languageNames[key] ?? locale.languageCode.toUpperCase();
  }

  String get currentLanguageName => getLanguageName(_currentLocale);
}
