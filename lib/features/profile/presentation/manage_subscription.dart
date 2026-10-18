import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/stripe_web_checkout.dart';
import '../../../core/widgets/menu_row.dart';
import '../../../generated/app_localizations.dart';

/// "Manage subscription" (Profile > Account Settings), the place Terms 7.3
/// names for cancelling (owner, 2026-10-16). One tap does the right thing:
///  - web: Stripe's billing portal for web purchases; with no web
///    subscription on the account, a sheet says where else to cancel;
///  - Android: Google Play's subscriptions page for GreenGo;
///  - iOS: the App Store's subscriptions page.
class ManageSubscription {
  const ManageSubscription._();

  static const playSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions?package=com.greengochat.greengochatapp';
  static const appStoreSubscriptionsUrl = 'https://apps.apple.com/account/subscriptions';

  /// Test seams.
  @visibleForTesting
  static Future<bool> Function() openPortal = StripeWebCheckout.openBillingPortal;
  @visibleForTesting
  static Future<bool> Function(Uri) openUrl = (u) => launchUrl(u, mode: LaunchMode.externalApplication);
  @visibleForTesting
  static bool? isWebOverride;
  @visibleForTesting
  static TargetPlatform? platformOverride;

  static Future<void> open(BuildContext context) async {
    final web = isWebOverride ?? kIsWeb;
    final platform = platformOverride ?? defaultTargetPlatform;
    var ok = false;
    try {
      if (web) {
        ok = await openPortal();
      } else if (platform == TargetPlatform.android) {
        ok = await openUrl(Uri.parse(playSubscriptionsUrl));
      } else if (platform == TargetPlatform.iOS) {
        ok = await openUrl(Uri.parse(appStoreSubscriptionsUrl));
      }
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) await showHelp(context, web: web);
  }

  /// Where to cancel each kind of purchase (also the web fallback when the
  /// account has no web subscription).
  static Future<void> showHelp(BuildContext context, {required bool web}) {
    final l = AppLocalizations.of(context)!;
    // The iPhone app names only Apple, never Google Play (App Review 2.3.10).
    final iosApp = !web && (platformOverride ?? defaultTargetPlatform) == TargetPlatform.iOS;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => SafeArea(
        child: Padding(
          key: const ValueKey('manage-subscription-help'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.manageSubscriptionTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(web
                    ? l.manageSubscriptionNoWeb
                    : (iosApp ? l.manageSubscriptionStoreHelpIos : l.manageSubscriptionStoreHelp),
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            if (!iosApp) ...[
              MenuRow(
                key: const ValueKey('manage-subscription-play'),
                icon: Icons.shop_outlined,
                title: l.manageSubscriptionGooglePlay,
                subtitle: l.manageSubscriptionGooglePlayPath,
                onTap: () => openUrl(Uri.parse(playSubscriptionsUrl)),
              ),
              const SizedBox(height: MenuRow.gap),
            ],
            MenuRow(
              key: const ValueKey('manage-subscription-apple'),
              icon: Icons.apple,
              title: l.manageSubscriptionAppStore,
              subtitle: l.manageSubscriptionAppStorePath,
              onTap: () => openUrl(Uri.parse(appStoreSubscriptionsUrl)),
            ),
          ]),
        ),
      ),
    );
  }
}
