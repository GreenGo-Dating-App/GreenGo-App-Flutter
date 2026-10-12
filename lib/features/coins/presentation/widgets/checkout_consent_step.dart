import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/purchase_consent.dart';
import '../../../../generated/app_localizations.dart';

/// The mandatory step shown before the web (Stripe) checkout opens. Plan P2-9.
///
/// - Coins (immediate digital content): the EU CRD art. 16(m) waiver text;
///   tapping "Accept" is the express agreement (nothing is pre-selected).
/// - Memberships (a service): the 14-day (EU) / 7-day (Brazil) withdrawal
///   information and the auto-renew notice.
/// Full-width Accept with Cancel under it, so both always fit on a phone.
class CheckoutConsentStep extends StatefulWidget {
  const CheckoutConsentStep({
    required this.productId,
    required this.onContinue,
    required this.onCancel,
    super.key,
  });

  final String productId;
  final ValueChanged<CheckoutConsent> onContinue;
  final VoidCallback onCancel;

  @override
  State<CheckoutConsentStep> createState() => _CheckoutConsentStepState();
}

class _CheckoutConsentStepState extends State<CheckoutConsentStep> {
  bool get _isCoins => isCoinProduct(widget.productId);

  void _continue() {
    widget.onContinue(_isCoins
        ? const CheckoutConsent(
            waiverAccepted: true,
            waiverVersion: kCoinWaiverVersion,
          )
        : const CheckoutConsent(
            withdrawalNoticeVersion: kMembershipWithdrawalNoticeVersion,
          ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 14,
      height: 1.4,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.checkoutConsentTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isCoins ? l10n.checkoutCoinWaiverCheckbox : l10n.checkoutMembershipWithdrawalInfo,
          key: Key(_isCoins ? 'checkoutWaiverText' : 'checkoutWithdrawalInfo'),
          style: textStyle,
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          key: const Key('checkoutContinueButton'),
          onPressed: _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.richGold,
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 48),
          ),
          child: Text(l10n.checkoutAccept,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: widget.onCancel,
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
