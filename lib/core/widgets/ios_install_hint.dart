import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../web/ios_install_detector.dart';

/// Public guide on the website explaining how to add GreenGo to the iPhone /
/// iPad home screen.
const String kIosInstallGuideUrl = 'https://greengochat.com/how-to';

/// Whether to offer the iPhone / iPad install guide (web on iOS, not yet
/// installed). Overridable in tests.
bool Function() iosInstallHintEligible = isIosBrowserNotInstalled;

/// The guide in the user's language, opened at the iPhone / iPad section:
/// `?lang=en|pt|es|fr|de|it` (pt = Brazilian Portuguese) + `#ios`.
Uri iosInstallGuideUri(Locale locale) {
  const supported = {'en', 'pt', 'es', 'fr', 'de', 'it'};
  final lang = supported.contains(locale.languageCode) ? locale.languageCode : 'en';
  return Uri.parse('$kIosInstallGuideUrl?lang=$lang#ios');
}

Future<void> openIosInstallGuide(BuildContext context) => launchUrl(
      iosInstallGuideUri(Localizations.localeOf(context)),
      mode: LaunchMode.externalApplication,
    );

/// Small link for the login page: "How to install on your iPhone or iPad".
/// Renders nothing when [iosInstallHintEligible] is false.
class IosInstallLink extends StatelessWidget {
  const IosInstallLink({super.key});

  @override
  Widget build(BuildContext context) {
    if (!iosInstallHintEligible()) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return TextButton.icon(
      key: const ValueKey('ios-install-link'),
      onPressed: () => openIosInstallGuide(context),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(44, 44),
      ),
      icon: const Icon(Icons.ios_share, size: 18),
      label: Text(
        l10n.iosInstallHowTo,
        style: const TextStyle(fontSize: 14, decoration: TextDecoration.underline),
      ),
    );
  }
}

/// After sign-in on an iPhone / iPad browser: a dismissible banner pointing to
/// the install guide. Dismissing hides it for [_snooze].
class IosInstallBanner {
  static const String _prefsKey = 'ios_install_hint_dismissed_at';
  static const Duration _snooze = Duration(days: 30);

  /// Shows the banner on [messenger] when eligible and not recently dismissed.
  static Future<void> maybeShow(BuildContext context) async {
    if (!iosInstallHintEligible()) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    if (messenger == null || l10n == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getInt(_prefsKey);
      if (last != null &&
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) < _snooze) {
        return;
      }
      Future<void> dismiss() async {
        messenger.hideCurrentMaterialBanner();
        await prefs.setInt(_prefsKey, DateTime.now().millisecondsSinceEpoch);
      }

      messenger.showMaterialBanner(MaterialBanner(
        key: const ValueKey('ios-install-banner'),
        backgroundColor: AppColors.backgroundCard,
        leading: const Icon(Icons.install_mobile, color: AppColors.richGold),
        content: Text(l10n.iosInstallBannerText,
            style: const TextStyle(color: AppColors.textPrimary)),
        actions: [
          TextButton(onPressed: dismiss, child: Text(l10n.iosInstallNotNow)),
          TextButton(
            onPressed: () async {
              await dismiss();
              if (context.mounted) await openIosInstallGuide(context);
            },
            child: Text(l10n.iosInstallShowMe,
                style: const TextStyle(color: AppColors.richGold)),
          ),
        ],
      ));
    } catch (_) {
      // Preferences unavailable (private mode): skip the banner silently.
    }
  }
}
