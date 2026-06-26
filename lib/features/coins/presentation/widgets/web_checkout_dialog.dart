import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/stripe_web_checkout.dart';
import '../../../../generated/app_localizations.dart';

/// Drives the web Stripe checkout flow with a single modal:
/// opens the hosted checkout in a new tab, then polls `stripe_orders` and
/// resolves true once the purchase is credited (or false on cancel/timeout).
///
/// Usage:
///   final ok = await WebCheckoutDialog.show(context, productId);
///   if (ok == true) { /* refresh balance / profile */ }
class WebCheckoutDialog extends StatefulWidget {
  const WebCheckoutDialog({required this.productId, super.key});

  final String productId;

  static Future<bool?> show(BuildContext context, String productId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => WebCheckoutDialog(productId: productId),
    );
  }

  @override
  State<WebCheckoutDialog> createState() => _WebCheckoutDialogState();
}

enum _Phase { opening, waiting, timeout, failed }

class _WebCheckoutDialogState extends State<WebCheckoutDialog> {
  _Phase _phase = _Phase.opening;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final known = await StripeWebCheckout.existingCompletedOrderIds();
      final sessionId = await StripeWebCheckout.startCheckout(widget.productId);
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
    final busy = _phase == _Phase.opening || _phase == _Phase.waiting;

    String message;
    switch (_phase) {
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
