import '../../generated/app_localizations.dart';

/// Placeholder names older app versions stored when a profile had no name.
/// New writes store an empty string / null instead and the reader renders
/// [AppLocalizations.commonUnknownUser] in their own language.
const Set<String> kLegacyUnknownNamePlaceholders = {'Unknown', 'Someone'};

/// True when [name] carries no real user name (null, blank or a legacy
/// English placeholder written by an older app version).
bool isMissingUserName(String? name) {
  final n = name?.trim() ?? '';
  return n.isEmpty || kLegacyUnknownNamePlaceholders.contains(n);
}

/// [name] for display, or the localized "Unknown user" when it is missing.
String displayUserName(AppLocalizations l10n, String? name) =>
    isMissingUserName(name) ? l10n.commonUnknownUser : name!.trim();
