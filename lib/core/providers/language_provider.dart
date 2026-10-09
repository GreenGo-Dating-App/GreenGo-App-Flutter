import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {

  LanguageProvider({String? initialLanguage}) {
    if (initialLanguage != null) {
      final parts = initialLanguage.split('_');
      _currentLocale = parts.length > 1
          ? Locale(parts[0], parts[1])
          : Locale(parts[0]);
    }
    activeLocale = _currentLocale;
  }
  Locale _currentLocale = const Locale('en');

  /// The locale the app UI currently renders in, for code without a
  /// BuildContext (services, validators, notification channels). Null until a
  /// [LanguageProvider] has been created. See `lib/core/utils/app_l10n_lookup.dart`.
  static Locale? activeLocale;
  static const String _languageKey = 'selected_language';

  Locale get currentLocale => _currentLocale;

  /// [activeLocale] as a stored language code (`en`, `pt_BR`), English when
  /// no provider exists yet.
  static String get activeLanguageCode => codeOf(activeLocale ?? const Locale('en'));

  /// `pt_BR` / `de` form of [locale].
  static String codeOf(Locale locale) =>
      (locale.countryCode != null && locale.countryCode!.isNotEmpty)
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;

  /// Field on users/{uid} the Cloud Functions read to localize pushes and
  /// email subjects for this user (private doc, owner-writable).
  static const String serverLanguageField = 'appLanguage';

  /// The language the user has picked, read straight from the local cache.
  ///
  /// For code with no BuildContext (data sources, background work) that still
  /// needs to tell the backend which language to answer in — e.g. the welcome
  /// email sent during registration, before any profile exists. Returns codes
  /// like `en` or `pt_BR`; falls back to `en`.
  static Future<String> currentLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_languageKey);
      if (stored != null && stored.isNotEmpty) return stored;
    } catch (e) {
      debugPrint('Failed to read cached language: $e');
    }
    return 'en';
  }

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
            activeLocale = newLocale;
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
    activeLocale = locale;
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
        // Server-rendered texts (pushes, email subjects) follow the app language.
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({serverLanguageField: languageCode}, SetOptions(merge: true));
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
