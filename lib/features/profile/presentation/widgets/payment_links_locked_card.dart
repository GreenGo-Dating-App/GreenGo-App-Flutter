import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../subscription/presentation/screens/membership_screen.dart';
import '../../domain/entities/payment_links.dart';

/// Payment methods for an owner whose effective tier is NOT Silver, Gold or
/// Platinum (owner rule 2026-10-12). Nothing can be added or edited; links
/// saved during a paid tier ([hidden], moved by the server to the owner-only
/// `profiles_private/{uid}.paymentLinksHidden`) are shown greyed out, with
/// "Available with Silver, Gold or Platinum" and an upgrade button. They come
/// back on the profile automatically after an upgrade.
class PaymentLinksLockedCard extends StatelessWidget {
  const PaymentLinksLockedCard({
    required this.uid,
    this.hidden,
    this.onUpgrade,
    super.key,
  });

  final String uid;

  /// The owner's hidden links (null / empty = none saved).
  final PaymentLinks? hidden;

  /// Upgrade action; defaults to the membership marketplace.
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final links = hidden;
    final hasHidden = links != null && links.hasAnyLink;
    return Container(
      key: const ValueKey('payment-links-locked'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_outline, color: AppColors.richGold, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.paymentLinksTierLocked,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            hasHidden ? l.paymentLinksTierLockedBody : l.paymentLinksTierUpsellBody,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          if (hasHidden) ...[
            const SizedBox(height: 12),
            // Greyed, read-only: the owner sees what is waiting for them.
            Opacity(
              key: const ValueKey('payment-links-locked-list'),
              opacity: 0.45,
              child: Column(children: [
                for (final m in links.methods)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 18, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(m.label,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(links.valueOf(m) ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textTertiary)),
                      ),
                    ]),
                  ),
              ]),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const ValueKey('payment-links-upgrade'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack),
              onPressed: onUpgrade ??
                  () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => MembershipScreen(currentUserId: uid))),
              icon: const Icon(Icons.workspace_premium),
              label: Text(l.upgrade),
            ),
          ),
        ],
      ),
    );
  }
}
