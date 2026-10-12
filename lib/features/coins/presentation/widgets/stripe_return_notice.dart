import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/purchase_consent.dart';
import '../../../../core/services/stripe_billing_models.dart';
import '../../../../core/services/stripe_web_checkout.dart';
import '../../../../generated/app_localizations.dart';

/// Web: the message after coming back from Stripe Checkout
/// (`/?payment=success|cancel`). Cancelled -> "you have not been charged";
/// paid -> waits (up to [confirmFor]) for the webhook to complete the order,
/// then "coins added" / "membership active", or "it is added automatically"
/// when it takes longer (e.g. PIX). No-op on mobile and on a normal load.
class StripeReturnNotice {
  StripeReturnNotice._();

  static Future<void> check(BuildContext context, {Duration confirmFor = const Duration(seconds: 90)}) async {
    final r = await StripeWebCheckout.consumeReturn();
    if (r == null || !context.mounted) return;
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.webPaymentCancelled)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => StripeReturnDialog(result: r, confirmFor: confirmFor),
    );
  }
}

class StripeReturnDialog extends StatefulWidget {
  const StripeReturnDialog({super.key, required this.result, required this.confirmFor, this.waitForOrder});

  final StripeReturn result;
  final Duration confirmFor;

  /// Injectable for tests; defaults to [StripeWebCheckout.waitForCompletion].
  final Future<bool> Function(Set<String> known, Duration timeout)? waitForOrder;

  @override
  State<StripeReturnDialog> createState() => _StripeReturnDialogState();
}

class _StripeReturnDialogState extends State<StripeReturnDialog> {
  bool? _confirmed; // null = still confirming

  @override
  void initState() {
    super.initState();
    if (widget.result.productId == null) {
      _confirmed = false; // nothing to match the order against
      return;
    }
    final wait = widget.waitForOrder ??
        (Set<String> known, Duration t) => StripeWebCheckout.waitForCompletion(known, timeout: t);
    wait(widget.result.knownOrderIds, widget.confirmFor).then((ok) {
      if (mounted) setState(() => _confirmed = ok);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coins = isCoinProduct(widget.result.productId ?? '');
    final confirming = _confirmed == null;
    final message = confirming
        ? l10n.webPaymentConfirming
        : _confirmed!
            ? (coins ? l10n.webPaymentDoneCoins : l10n.webPaymentDoneMembership)
            : l10n.webPaymentPending;
    return AlertDialog(
      key: const ValueKey('stripe-return-dialog'),
      backgroundColor: AppColors.backgroundDark,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: confirming
                ? const CircularProgressIndicator(color: AppColors.richGold)
                : Icon(_confirmed! ? Icons.check_circle : Icons.hourglass_bottom,
                    color: AppColors.richGold, size: 56),
          ),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
