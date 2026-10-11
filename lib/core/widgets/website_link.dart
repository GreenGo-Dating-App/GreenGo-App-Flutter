import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';

/// The marketing site, linked from the web login page.
const String kWebsiteDomain = 'greengochat.com';
final Uri kWebsiteUri = Uri.parse('https://$kWebsiteDomain');

/// Whether to show the website link: the web build only (the native apps
/// don't send users out to the site). Overridable in tests.
bool Function() websiteLinkEligible = () => kIsWeb;

/// Opens [uri] in a new browser tab. Overridable in tests.
Future<bool> Function(Uri uri) openWebsite = (uri) => launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

/// "Visit greengochat.com for more info": muted text, the domain in gold
/// (the Sign Up link style), centred, wraps gracefully in long locales,
/// >= 44 px tap target, announced as a link. Renders nothing off the web.
class WebsiteLink extends StatelessWidget {
  const WebsiteLink({super.key, this.shadows});

  /// Optional text halo (the login draws it straight on the background).
  final List<Shadow>? shadows;

  @override
  Widget build(BuildContext context) {
    if (!websiteLinkEligible()) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final full = l10n.loginVisitWebsite(kWebsiteDomain);
    // Split around the (untranslated) domain so only it is gold.
    final at = full.indexOf(kWebsiteDomain);
    final before = at < 0 ? full : full.substring(0, at);
    final after = at < 0 ? '' : full.substring(at + kWebsiteDomain.length);

    final muted = TextStyle(
      color: AppColors.liquidMuted,
      fontSize: 13,
      height: 1.4,
      shadows: shadows,
    );
    void open() => openWebsite(kWebsiteUri);
    // One node: "link, Visit greengochat.com for more info", activatable.
    return Semantics(
      link: true,
      label: full,
      onTap: open,
      excludeSemantics: true,
      child: Center(
        child: InkWell(
          key: const ValueKey('website-link'),
          onTap: open,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text.rich(
                  TextSpan(
                    style: muted,
                    children: [
                      TextSpan(text: before),
                      if (at >= 0)
                        const TextSpan(
                          text: kWebsiteDomain,
                          style: TextStyle(
                            color: AppColors.liquidGoldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      TextSpan(text: after),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
