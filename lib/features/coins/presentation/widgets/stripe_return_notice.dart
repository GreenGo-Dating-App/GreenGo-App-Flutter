import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/purchase_consent.dart';
import '../../../../core/services/stripe_billing_models.dart';
import '../../../../core/services/stripe_web_checkout.dart';
import '../../../../core/widgets/purchase_success_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/presentation/tier_l10n.dart';
import '../../domain/entities/coin_package.dart';

/// Web: the message after coming back from Stripe Checkout
/// (`/?payment=success|cancel`). Cancelled -> "you have not been charged";
/// paid -> waits (up to [confirmFor]) for the webhook to complete the order,
/// then the same [PurchaseSuccessDialog] / celebration the mobile shop shows,
/// or "it is added automatically" when it takes longer (e.g. PIX). No-op on
/// mobile and on a normal load.
class StripeReturnNotice {
  StripeReturnNotice._();

  static Future<void> check(BuildContext context, {Duration confirmFor = const Duration(seconds: 90)}) async {
    final r = await StripeWebCheckout.consumeReturn();
    if (r == null || !context.mounted) return;
    await show(context, r, confirmFor: confirmFor);
  }

  /// Shows the outcome of [r]. [waitForOrder] is injectable for tests.
  static Future<void> show(
    BuildContext context,
    StripeReturn r, {
    Duration confirmFor = const Duration(seconds: 90),
    Future<bool> Function(Set<String> known, Duration timeout)? waitForOrder,
  }) async {
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.webPaymentCancelled)),
      );
      return;
    }
    // The confirming dialog closes itself with `true` once the order lands.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StripeReturnDialog(result: r, confirmFor: confirmFor, waitForOrder: waitForOrder),
    );
    if (confirmed == true && context.mounted) {
      await showSuccess(context, r.productId!);
    }
  }

  /// The mobile shop's success feedback for [productId]: coins -> the coins
  /// dialog, a tier -> the membership celebration, Base -> the success dialog.
  static Future<void> showSuccess(BuildContext context, String productId) {
    final l10n = AppLocalizations.of(context)!;
    final package = CoinPackages.getByProductId(productId);
    if (package != null) {
      return PurchaseSuccessDialog.showCoinsPurchased(
        context,
        coinsAdded: package.coinAmount,
        bonusCoins: package.bonusCoins,
      );
    }
    // Paid tiers only: Base shares `basic`'s product id but is not a tier.
    for (final tier in const [SubscriptionTier.silver, SubscriptionTier.gold, SubscriptionTier.platinum]) {
      if (tier.monthlyProductId == productId || tier.yearlyProductId == productId) {
        return PurchaseSuccessDialog.showSubscriptionActivated(
          context,
          tierName: localizedSubscriptionTierName(l10n, tier),
          tier: tier,
        );
      }
    }
    return showDialog<void>(
      context: context,
      builder: (_) => PurchaseSuccessDialog(
        title: l10n.purchaseSuccessfulTitle,
        message: isCoinProduct(productId) ? l10n.webPaymentDoneCoins : l10n.webPaymentDoneMembership,
        icon: Icons.workspace_premium,
        iconColor: AppColors.richGold,
      ),
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
      if (!mounted) return;
      if (ok) {
        // Confirmed: hand over to the success dialog (see StripeReturnNotice.show).
        Navigator.of(context).pop(true);
      } else {
        setState(() => _confirmed = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final confirming = _confirmed == null;
    final message = confirming ? l10n.webPaymentConfirming : l10n.webPaymentPending;
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
                : const Icon(Icons.hourglass_bottom, color: AppColors.richGold, size: 56),
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
