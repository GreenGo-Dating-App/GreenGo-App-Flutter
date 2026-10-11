import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../data/private_profile.dart';
import '../../domain/entities/payment_links.dart';
import '../../domain/entities/profile.dart';
import '../../domain/payment_links_access.dart';
import 'edit_section_card.dart';

/// Account settings > Payment methods (owner rule 2026-10-12: "Silver, Gold
/// and Platinum have payment links in Account settings. That is visible only
/// when the tier is Silver, Gold or Platinum.").
///
///  * effective tier Silver / Gold / Platinum (or TEST): the normal entry;
///  * any other tier WITH links saved during a paid tier (server-moved to
///    `profiles_private/{uid}.paymentLinksHidden`): an entry subtitled
///    "Available with Silver, Gold or Platinum" opening the locked view;
///  * otherwise nothing.
class PaymentLinksSettingsEntry extends StatelessWidget {
  const PaymentLinksSettingsEntry({
    required this.profile,
    required this.onOpen,
    this.hiddenLinks,
    super.key,
  });

  final Profile profile;
  final VoidCallback onOpen;

  /// Hidden links override (tests); defaults to the live private-profile cache.
  final PaymentLinks? Function()? hiddenLinks;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (paymentLinksAllowed(profile)) {
      return _entry(l, l.paymentMethodsSettingsSubtitle);
    }
    final cache = PrivateProfileCache.instance;
    return ValueListenableBuilder<int>(
      valueListenable: cache.version,
      builder: (context, _, __) {
        final hidden = hiddenLinks != null
            ? hiddenLinks!()
            : hiddenPaymentLinksFromPrivate(cache.dataFor(profile.userId));
        if (hidden == null || !hidden.hasAnyLink) return const SizedBox.shrink();
        return _entry(l, l.paymentLinksTierLocked);
      },
    );
  }

  Widget _entry(AppLocalizations l, String subtitle) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: EditSectionCard(
          key: const ValueKey('account-settings-payment-methods'),
          title: l.paymentLinksTitle,
          subtitle: subtitle,
          icon: Icons.account_balance_wallet_outlined,
          onTap: onOpen,
        ),
      );
}
