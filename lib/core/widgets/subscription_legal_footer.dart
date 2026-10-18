import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../features/legal/presentation/screens/legal_document_screen.dart';
import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../utils/eula_link.dart';

/// Apple Guideline 3.1.2 compliance footer for auto-renewable subscription
/// purchase surfaces: the auto-renew disclosure, Terms, Privacy and EULA links,
/// and an optional "Restore Purchases" action.
///
/// No free-trial notice: GreenGo sells no free trials on any store (owner
/// decision 2026-10-17); the only introductory offer is the 2026 launch price,
/// described on each plan card by LaunchPromoPrice.
class SubscriptionLegalFooter extends StatelessWidget {
  const SubscriptionLegalFooter({
    super.key,
    this.onRestore,
    this.isRestoring = false,
  });

  /// When provided, a "Restore Purchases" button is shown above the disclosure.
  final VoidCallback? onRestore;
  final bool isRestoring;

  void _openLegal(BuildContext context, {required bool terms}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => terms
            ? const LegalDocumentScreen.termsAndConditions()
            : const LegalDocumentScreen.privacyPolicy(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const linkStyle = TextStyle(
      color: AppColors.richGold,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRestore != null) ...[
          TextButton(
            onPressed: isRestoring ? null : onRestore,
            child: isRestoring
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.restorePurchases,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          // Web subscriptions are Stripe's, not a store's: say where to
          // cancel (the billing portal, see WebBillingPanel). Audit L-11.
          kIsWeb ? l10n.subscriptionAutoRenewInfoWeb : l10n.subscriptionAutoRenewInfo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.8),
            fontSize: 11,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InkWell(
              onTap: () => _openLegal(context, terms: true),
              child: Text(l10n.termsAndConditions, style: linkStyle),
            ),
            Text(
              '   •   ',
              style: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            InkWell(
              onTap: () => _openLegal(context, terms: false),
              child: Text(l10n.privacyPolicy, style: linkStyle),
            ),
            Text(
              '   •   ',
              style: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
            InkWell(
              key: const ValueKey('subscription-footer-eula'),
              onTap: () => openEula(context),
              child: Text(l10n.eulaShort, style: linkStyle),
            ),
          ],
        ),
      ],
    );
  }
}
