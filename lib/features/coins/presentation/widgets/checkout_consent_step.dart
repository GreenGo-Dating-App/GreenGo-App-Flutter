import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/purchase_consent.dart';
import '../../../../generated/app_localizations.dart';

/// The mandatory step shown before the web (Stripe) checkout opens. Plan P2-9.
///
/// - Coins (immediate digital content): the EU CRD art. 16(m) waiver checkbox.
///   "Continue to payment" stays disabled until it is ticked; the box is never
///   pre-ticked.
/// - Memberships (a service): the 14-day (EU) / 7-day (Brazil) withdrawal
///   information and the auto-renew notice. No waiver checkbox.
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
  bool _waiverTicked = false;

  bool get _isCoins => isCoinProduct(widget.productId);
  bool get _canContinue => !_isCoins || _waiverTicked;

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
        if (_isCoins)
          CheckboxListTile(
            key: const Key('checkoutWaiverCheckbox'),
            value: _waiverTicked,
            onChanged: (v) => setState(() => _waiverTicked = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.richGold,
            title: Text(l10n.checkoutCoinWaiverCheckbox, style: textStyle),
          )
        else
          Text(
            l10n.checkoutMembershipWithdrawalInfo,
            key: const Key('checkoutWithdrawalInfo'),
            style: textStyle,
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: widget.onCancel,
              child: Text(l10n.cancel),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              key: const Key('checkoutContinueButton'),
              onPressed: _canContinue ? _continue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
              ),
              child: Text(l10n.checkoutContinueToPayment),
            ),
          ],
        ),
      ],
    );
  }
}
