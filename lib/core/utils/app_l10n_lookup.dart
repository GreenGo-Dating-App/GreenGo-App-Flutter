import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../generated/app_localizations.dart';
import '../providers/language_provider.dart';

/// Localized strings for code that has no BuildContext (services, validators,
/// Android notification channels…).
///
/// Mirrors the app's own locale choice: the app renders in
/// [LanguageProvider.currentLocale], which defaults to English when the user
/// never picked a language (the device locale is NOT used by MaterialApp).

/// [AppLocalizations] for [locale], falling back to the language-only locale
/// and finally to English when the language is not supported.
AppLocalizations appL10nFor(Locale? locale) {
  if (locale != null) {
    final supported = AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
    if (supported) {
      try {
        return lookupAppLocalizations(locale);
      } catch (_) {
        // fall through to English
      }
    }
  }
  return lookupAppLocalizations(const Locale('en'));
}

/// Parses a stored language code such as `en`, `pt_BR` or `pt-BR`.
Locale? _parseLanguageCode(String? code) {
  if (code == null || code.isEmpty) return null;
  final parts = code.split(RegExp('[_-]'));
  return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
}

/// Synchronous lookup using the locale the UI is currently rendered in
/// (English until a [LanguageProvider] exists).
AppLocalizations currentAppL10n() => appL10nFor(LanguageProvider.activeLocale);

/// Like [currentAppL10n], but when no [LanguageProvider] exists yet (early
/// start-up, background work) reads the user's saved language instead.
Future<AppLocalizations> currentAppL10nAsync() async {
  final active = LanguageProvider.activeLocale;
  if (active != null) return appL10nFor(active);
  try {
    final prefs = await SharedPreferences.getInstance();
    return appL10nFor(_parseLanguageCode(prefs.getString('selected_language')));
  } catch (_) {
    return appL10nFor(null);
  }
}
