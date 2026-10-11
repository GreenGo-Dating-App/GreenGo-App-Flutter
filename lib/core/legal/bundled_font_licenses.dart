import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asset paths of the font licenses shown on the open-source licenses page.
const String poppinsLicenseAsset = 'assets/fonts/OFL-Poppins.txt';
const String webFallbackFontsLicenseAsset = 'assets/fonts/OFL-Roboto-Noto.txt';

bool _registered = false;

/// Adds the SIL Open Font License texts of the fonts GreenGo ships to
/// [LicenseRegistry], so they appear on Flutter's licenses page
/// (`showLicensePage`), next to the package licenses Flutter collects itself.
///
/// - Poppins: declared in pubspec.yaml (assets/fonts). OFL 1.1.
/// - Roboto + Noto (web only): the web build serves them from our own origin
///   (/gfonts/ -> fontFallbackProxy) instead of fonts.gstatic.com, i.e. we
///   distribute them, so their OFL notice must ship with the app. OFL 1.1.
///
/// Loading is lazy: the license texts are only read when the licenses page is
/// opened. Safe to call more than once.
void registerBundledFontLicenses({bool? isWeb}) {
  if (_registered) return;
  _registered = true;
  final web = isWeb ?? kIsWeb;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const <String>['Poppins (font)'],
      await rootBundle.loadString(poppinsLicenseAsset),
    );
    if (web) {
      yield LicenseEntryWithLineBreaks(
        const <String>['Roboto (font)', 'Noto fonts'],
        await rootBundle.loadString(webFallbackFontsLicenseAsset),
      );
    }
  });
}

@visibleForTesting
void resetBundledFontLicensesForTest() => _registered = false;
