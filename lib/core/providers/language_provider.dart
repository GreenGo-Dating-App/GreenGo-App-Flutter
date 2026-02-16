import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  LanguageProvider({String? initialLanguage}) {
    if (initialLanguage != null) {
      final parts = initialLanguage.split('_');
      _currentLocale = parts.length > 1
          ? Locale(parts[0], parts[1])
          : Locale(parts[0]);
    }
  }

  /// Load language from Firestore for the current user (call after auth)
  Future<void> loadFromDatabase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('userSettings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final lang = doc.data()?['language'] as String?;
        if (lang != null) {
          final parts = lang.split('_');
          final newLocale = parts.length > 1
              ? Locale(parts[0], parts[1])
              : Locale(parts[0]);

          if (_currentLocale != newLocale) {
            _currentLocale = newLocale;
            notifyListeners();

            // Also update local SharedPreferences cache
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_languageKey, lang);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load language from database: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    notifyListeners();

    final languageCode = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;

    // Save to SharedPreferences (local cache for instant load)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);

    // Save to Firestore (persists across devices)
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('userSettings')
            .doc(user.uid)
            .set({'language': languageCode}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Failed to save language to database: $e');
    }
  }

  String getLanguageName(Locale locale) {
    final key = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    return languageNames[key] ?? locale.languageCode.toUpperCase();
  }

  String get currentLanguageName => getLanguageName(_currentLocale);
}
