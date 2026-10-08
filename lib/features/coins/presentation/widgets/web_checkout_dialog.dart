import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/purchase_consent.dart';
import '../../../../core/services/stripe_web_checkout.dart';
import '../../../../generated/app_localizations.dart';
import 'checkout_consent_step.dart';

/// Drives the web Stripe checkout flow with a single modal:
/// first the mandatory consent step ([CheckoutConsentStep]: the EU waiver
/// checkbox for coins, the withdrawal information for memberships), then
/// opens the hosted checkout in a new tab, polls `stripe_orders` and
/// resolves true once the purchase is credited (or false on cancel/timeout).
///
/// Usage:
///   final ok = await WebCheckoutDialog.show(context, productId);
///   if (ok == true) { /* refresh balance / profile */ }
class WebCheckoutDialog extends StatefulWidget {
  const WebCheckoutDialog({required this.productId, super.key});

  final String productId;

  static Future<bool?> show(BuildContext context, String productId) {
    // Fail closed on mobile. `StripeWebCheckout` is already compiled out of iOS
    // and Android builds (see stripe_web_checkout.dart), so the dialog could
    // only ever spin forever there — but returning false immediately makes the
    // intent explicit: store binaries must never show an external payment flow.
    if (!kIsWeb) {
      assert(
        false,
        'WebCheckoutDialog.show called on a mobile build — use in_app_purchase.',
      );
      return Future<bool?>.value(false);
    }
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WebCheckoutDialog(productId: productId),
    );
  }

  @override
  State<WebCheckoutDialog> createState() => _WebCheckoutDialogState();
}

enum _Phase { consent, opening, waiting, timeout, failed }

class _WebCheckoutDialogState extends State<WebCheckoutDialog> {
  _Phase _phase = _Phase.consent;

  void _onConsent(CheckoutConsent consent) {
    setState(() => _phase = _Phase.opening);
    _run(consent);
  }

  Future<void> _run(CheckoutConsent consent) async {
    try {
      final known = await StripeWebCheckout.existingCompletedOrderIds();
      final sessionId = await StripeWebCheckout.startCheckout(
        widget.productId,
        consent: consent,
      );
      if (sessionId == null) {
        if (mounted) setState(() => _phase = _Phase.failed);
        return;
      }
      if (mounted) setState(() => _phase = _Phase.waiting);

      final ok = await StripeWebCheckout.waitForCompletion(known);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _phase = _Phase.timeout);
      }
    } catch (_) {
      if (mounted) setState(() => _phase = _Phase.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_phase == _Phase.consent) {
      return AlertDialog(
        backgroundColor: AppColors.backgroundDark,
        content: SingleChildScrollView(
          child: CheckoutConsentStep(
            productId: widget.productId,
            onContinue: _onConsent,
            onCancel: () => Navigator.of(context).pop(false),
          ),
        ),
      );
    }
    final busy = _phase == _Phase.opening || _phase == _Phase.waiting;

    String message;
    switch (_phase) {
      case _Phase.consent:
      case _Phase.opening:
        message = l10n.webCheckoutOpening;
        break;
      case _Phase.waiting:
        message = l10n.webCheckoutWaiting;
        break;
      case _Phase.timeout:
        message = l10n.webCheckoutTimeout;
        break;
      case _Phase.failed:
        message = l10n.webCheckoutFailed;
        break;
    }

    return AlertDialog(
      backgroundColor: AppColors.backgroundDark,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Icon(
                _phase == _Phase.timeout
                    ? Icons.hourglass_bottom
                    : Icons.error_outline,
                color: AppColors.richGold,
                size: 56,
              ),
            ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: busy
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.continueToApp),
              ),
            ],
    );
  }
}
