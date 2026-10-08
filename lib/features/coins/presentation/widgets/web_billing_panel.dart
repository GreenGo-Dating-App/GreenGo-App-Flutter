import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/stripe_billing_models.dart';
import '../../../../core/services/stripe_web_checkout.dart';
import '../../../../generated/app_localizations.dart';

/// Web-only billing panel for Stripe purchases (plan P2-9; audit L-11, H-23):
///   - each active web subscription with its Stripe price, interval and next
///     renewal date, plus "Cancel anytime in the billing portal";
///   - the "Withdraw from contract" entry (CRD art. 11a), which lists the
///     purchases still within their withdrawal period and asks the server to
///     email a confirmation link.
/// Renders nothing on iOS / Android (store purchases are managed by the store).
class WebBillingPanel extends StatefulWidget {
  const WebBillingPanel({super.key, this.showSubscriptions = true});

  final bool showSubscriptions;

  @override
  State<WebBillingPanel> createState() => _WebBillingPanelState();
}

class _WebBillingPanelState extends State<WebBillingPanel> {
  WebBillingSummary _summary = WebBillingSummary.empty;
  bool _openingPortal = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _load();
  }

  Future<void> _load() async {
    try {
      final s = await StripeWebCheckout.billingSummary();
      if (mounted) setState(() => _summary = s);
    } catch (_) {
      // Informational panel: the withdrawal entry still works without it.
    }
  }

  Future<void> _openPortal() async {
    setState(() => _openingPortal = true);
    var ok = false;
    try {
      ok = await StripeWebCheckout.openBillingPortal();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _openingPortal = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.billingPortalOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final subs = widget.showSubscriptions ? _summary.subscriptions : const <WebSubscriptionInfo>[];
    const linkStyle = TextStyle(
      color: AppColors.richGold,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.webBillingTitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          for (final s in subs) ...[
            const SizedBox(height: 8),
            Text(
              _subscriptionLine(l10n, locale, s),
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
            ),
          ],
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: _openingPortal ? null : _openPortal,
              child: Text(l10n.cancelAnytimeBillingPortal, style: linkStyle),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            key: const Key('withdrawFromContractLink'),
            onTap: () => WithdrawalDialog.show(context, _summary.orders),
            child: Text(l10n.withdrawFromContract, style: linkStyle),
          ),
        ],
      ),
    );
  }

  static String _subscriptionLine(
      AppLocalizations l10n, String locale, WebSubscriptionInfo s) {
    final price = formatMinorUnits(s.amountCents, s.currency, locale);
    final interval =
        s.interval == 'year' ? l10n.billingIntervalYear : l10n.billingIntervalMonth;
    final date = s.currentPeriodEnd == null
        ? '-'
        : DateFormat.yMMMd(locale).format(s.currentPeriodEnd!.toLocal());
    return s.cancelAtPeriodEnd
        ? l10n.webSubscriptionEndsOn(s.name, price, interval, date)
        : l10n.webSubscriptionRenewsOn(s.name, price, interval, date);
  }
}

/// Formats Stripe minor units (cents) as a localized currency amount.
String formatMinorUnits(int? cents, String? currency, String locale) {
  if (cents == null) return '-';
  final code = (currency ?? 'usd').toUpperCase();
  try {
    return NumberFormat.simpleCurrency(locale: locale, name: code).format(cents / 100);
  } catch (_) {
    return '${(cents / 100).toStringAsFixed(2)} $code';
  }
}

/// Lists the purchases still within their withdrawal period; picking one asks
/// the server to email a confirmation link (nothing is refunded until the
/// buyer confirms from that email).
class WithdrawalDialog extends StatefulWidget {
  const WithdrawalDialog({required this.orders, super.key});

  final List<WebOrderInfo> orders;

  static Future<void> show(BuildContext context, List<WebOrderInfo> orders) {
    return showDialog<void>(
      context: context,
      builder: (_) => WithdrawalDialog(orders: orders),
    );
  }

  @override
  State<WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends State<WithdrawalDialog> {
  String? _busyOrderId;

  Future<void> _request(WebOrderInfo o) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busyOrderId = o.orderId);
    String status;
    try {
      status = await StripeWebCheckout.requestWithdrawal(o.orderId);
    } catch (_) {
      status = 'error';
    }
    if (!mounted) return;
    setState(() => _busyOrderId = null);
    final ok = status == 'sent';
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? l10n.withdrawalRequestSent : l10n.withdrawalRequestFailed),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final eligible = widget.orders.where((o) => o.withdrawable).toList();
    return AlertDialog(
      backgroundColor: AppColors.backgroundDark,
      title: Text(l10n.withdrawFromContract,
          style: const TextStyle(color: AppColors.textSecondary)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eligible.isEmpty ? l10n.withdrawalNothingEligible : l10n.withdrawalDialogIntro,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13, height: 1.4),
              ),
              for (final o in eligible)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${o.name} · ${formatMinorUnits(o.amountCents, o.currency, locale)}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  subtitle: o.withdrawalDeadline == null
                      ? null
                      : Text(
                          l10n.withdrawalDeadline(DateFormat.yMMMd(locale)
                              .format(o.withdrawalDeadline!.toLocal())),
                          style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                        ),
                  trailing: _busyOrderId == o.orderId
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _busyOrderId == null ? () => _request(o) : null,
                          child: Text(l10n.withdrawFromContract),
                        ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
