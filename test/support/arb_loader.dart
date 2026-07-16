import 'dart:convert';
import 'dart:io';

/// Shared helpers for the ARB (Application Resource Bundle) localization tests.
///
/// The tests read the real `lib/l10n/*.arb` files off disk with dart:io (tests
/// run with the package root as the current directory) and parse them with
/// dart:convert so we assert against exactly what ships.

/// Directory holding the ARB files, relative to the package root.
const String kL10nDir = 'lib/l10n';

/// The reference locale every other locale is compared against.
const String kBaseLocale = 'en';

/// The non-base locales GreenGo ships.
const List<String> kOtherLocales = ['de', 'es', 'fr', 'it', 'pt', 'pt_BR'];

/// Loads and decodes an ARB file for [locale] (e.g. `en`, `pt_BR`).
Map<String, dynamic> loadArb(String locale) {
  final file = File('$kL10nDir/app_$locale.arb');
  if (!file.existsSync()) {
    throw StateError('Missing ARB file: ${file.path} (cwd: ${Directory.current.path})');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// The translatable keys of an ARB map: everything that is NOT ARB metadata
/// (keys beginning with `@`, which includes `@@locale` and per-key `@key`
/// descriptor objects).
Set<String> translationKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// The translatable string values of an ARB map (skips metadata + non-strings).
Iterable<MapEntry<String, String>> translationEntries(Map<String, dynamic> arb) sync* {
  for (final entry in arb.entries) {
    if (entry.key.startsWith('@')) continue;
    final v = entry.value;
    if (v is String) yield MapEntry(entry.key, v);
  }
}
