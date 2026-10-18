import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// The End-User License Agreement on the website (greengochat.com `/eula`,
/// rendered from the greengo-eula repo). Apple 3.1.2 asks subscription apps
/// to link it next to the Terms and the Privacy Policy.
const String kEulaUrl = 'https://greengochat.com/eula';

/// The EULA in the app language: `?lang=en|pt|es|fr|de|it` (the site's
/// i18n query parameter; pt and pt_BR both read the Brazilian text).
Uri eulaUri(Locale locale) {
  const supported = {'en', 'pt', 'es', 'fr', 'de', 'it'};
  final lang =
      supported.contains(locale.languageCode) ? locale.languageCode : 'en';
  return Uri.parse('$kEulaUrl?lang=$lang');
}

/// Test seam for opening the EULA.
@visibleForTesting
Future<bool> Function(Uri) eulaLauncher =
    (u) => launchUrl(u, mode: LaunchMode.externalApplication);

Future<bool> openEula(BuildContext context) async {
  try {
    return await eulaLauncher(eulaUri(Localizations.localeOf(context)));
  } catch (_) {
    return false;
  }
}
