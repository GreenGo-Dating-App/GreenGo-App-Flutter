import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/stripe_billing_models.dart';
import '../../../core/services/stripe_web_checkout.dart';
import '../../../core/widgets/menu_row.dart';
import '../../../generated/app_localizations.dart';
import '../../coins/presentation/widgets/web_billing_panel.dart';

/// "Purchases & withdrawal" (Profile > Account Settings), Terms 9.4 / 9.5:
///  - web: a screen listing the account's web (Stripe) purchases, the
///    "Withdraw from contract" function and the billing portal;
///  - Android / iOS: store purchases were sold by Google Play / Apple, so a
///    sheet explains that refunds and withdrawal go through them (with links).
///    The iPhone app names only Apple (App Review 2.3.10: no other platforms).
class PurchasesWithdrawal {
  const PurchasesWithdrawal._();

  static const playOrderHistoryUrl = 'https://play.google.com/store/account/orderhistory';
  static const appleReportProblemUrl = 'https://reportaproblem.apple.com';
  static const billingEmail = 'billing@greengochat.com';

  /// Test seams.
  @visibleForTesting
  static Future<WebBillingSummary> Function() loadSummary = StripeWebCheckout.billingSummary;
  @visibleForTesting
  static Future<bool> Function() openPortal = StripeWebCheckout.openBillingPortal;
  @visibleForTesting
  static Future<bool> Function(Uri) openUrl = (u) => launchUrl(u, mode: LaunchMode.externalApplication);
  @visibleForTesting
  static bool? isWebOverride;
  @visibleForTesting
  static TargetPlatform? platformOverride;

  /// The iPhone app: show only Apple, never Google Play (2.3.10).
  static bool get _isIosApp =>
      !(isWebOverride ?? kIsWeb) &&
      (platformOverride ?? defaultTargetPlatform) == TargetPlatform.iOS;

  static Future<void> open(BuildContext context) async {
    final web = isWebOverride ?? kIsWeb;
    if (web) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PurchasesWithdrawalScreen()),
      );
    } else {
      await showStoreHelp(context);
    }
  }

  /// App purchases: refunds / withdrawal through the store that sold them.
  static Future<void> showStoreHelp(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundCard,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('purchases-withdrawal-help'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.purchasesWithdrawalTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_isIosApp ? l.purchasesWithdrawalStoreHelpIos : l.purchasesWithdrawalStoreHelp,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 14),
            ..._storeRows(l, appleOnly: _isIosApp),
            const SizedBox(height: MenuRow.gap),
            MenuRow(
              key: const ValueKey('purchases-withdrawal-email'),
              icon: Icons.mail_outline,
              title: billingEmail,
              subtitle: l.purchasesWithdrawalEmailWeb,
              subtitleMaxLines: null,
              onTap: () => openUrl(Uri(scheme: 'mailto', path: billingEmail)),
            ),
          ]),
        ),
      ),
    );
  }

  static List<Widget> _storeRows(AppLocalizations l, {bool appleOnly = false}) => [
        if (!appleOnly) ...[
          MenuRow(
            key: const ValueKey('purchases-withdrawal-play'),
            icon: Icons.shop_outlined,
            title: l.manageSubscriptionGooglePlay,
            subtitle: l.purchasesWithdrawalGooglePlayPath,
            onTap: () => openUrl(Uri.parse(playOrderHistoryUrl)),
          ),
          const SizedBox(height: MenuRow.gap),
        ],
        MenuRow(
          key: const ValueKey('purchases-withdrawal-apple'),
          icon: Icons.apple,
          title: l.manageSubscriptionAppStore,
          subtitle: l.purchasesWithdrawalApplePath,
          onTap: () => openUrl(Uri.parse(appleReportProblemUrl)),
        ),
      ];
}

/// Web: the account's web purchases, withdrawal and the billing portal.
class PurchasesWithdrawalScreen extends StatefulWidget {
  const PurchasesWithdrawalScreen({super.key});

  @override
  State<PurchasesWithdrawalScreen> createState() => _PurchasesWithdrawalScreenState();
}

class _PurchasesWithdrawalScreenState extends State<PurchasesWithdrawalScreen> {
  WebBillingSummary? _summary;
  bool _failed = false;
  bool _openingPortal = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _summary = null;
    });
    try {
      final s = await PurchasesWithdrawal.loadSummary();
      if (mounted) setState(() => _summary = s);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _openPortal() async {
    setState(() => _openingPortal = true);
    var ok = false;
    try {
      ok = await PurchasesWithdrawal.openPortal();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _openingPortal = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.billingPortalOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final summary = _summary;
    const sectionStyle = TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700);
    const bodyStyle = TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(l.purchasesWithdrawalTitle),
      ),
      body: SafeArea(
        child: ListView(
          key: const ValueKey('purchases-withdrawal-screen'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(l.purchasesWithdrawalWebIntro, style: bodyStyle),
            const SizedBox(height: 16),
            if (summary == null && !_failed)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
              ),
            if (_failed) ...[
              Text(l.purchasesWithdrawalLoadFailed, style: bodyStyle),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _load, child: Text(l.retry)),
              ),
            ],
            if (summary != null) ...[
              if (summary.subscriptions.isEmpty && summary.orders.isEmpty)
                Text(l.purchasesWithdrawalEmpty, key: const ValueKey('purchases-withdrawal-empty'), style: bodyStyle),
              if (summary.subscriptions.isNotEmpty) ...[
                Text(l.purchasesWithdrawalMemberships, style: sectionStyle),
                const SizedBox(height: 8),
                for (final s in summary.subscriptions) ...[
                  Text(webSubscriptionLine(l, locale, s), style: bodyStyle),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 10),
              ],
              if (summary.orders.isNotEmpty) ...[
                Text(l.purchasesWithdrawalOrders, style: sectionStyle),
                const SizedBox(height: 8),
                for (final o in summary.orders) ...[
                  _OrderTile(order: o, locale: locale),
                  const SizedBox(height: MenuRow.gap),
                ],
                const SizedBox(height: 6),
              ],
              MenuRow(
                key: const ValueKey('purchases-withdrawal-withdraw'),
                icon: Icons.undo,
                title: l.withdrawFromContract,
                subtitle: l.purchasesWithdrawalWithdrawSubtitle,
                subtitleMaxLines: null,
                onTap: () => WithdrawalDialog.show(context, summary.orders),
              ),
              const SizedBox(height: MenuRow.gap),
              MenuRow(
                key: const ValueKey('purchases-withdrawal-portal'),
                icon: Icons.receipt_long_outlined,
                title: l.purchasesWithdrawalPortal,
                subtitle: l.purchasesWithdrawalPortalSubtitle,
                subtitleMaxLines: null,
                trailing: _openingPortal
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: _openingPortal ? () {} : _openPortal,
              ),
            ],
            const SizedBox(height: 20),
            Text(l.purchasesWithdrawalRules, key: const ValueKey('purchases-withdrawal-rules'), style: bodyStyle),
            const SizedBox(height: 20),
            Text(l.purchasesWithdrawalStoreHelp, style: bodyStyle),
            const SizedBox(height: 10),
            ...PurchasesWithdrawal._storeRows(l),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.locale});

  final WebOrderInfo order;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final price = formatMinorUnits(order.amountCents, order.currency, locale);
    final date = order.createdAt == null ? null : DateFormat.yMMMd(locale).format(order.createdAt!.toLocal());
    final deadline = order.withdrawable && order.withdrawalDeadline != null
        ? l.withdrawalDeadline(DateFormat.yMMMd(locale).format(order.withdrawalDeadline!.toLocal()))
        : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.backgroundCard, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${order.name} · $price',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        if (date != null) ...[
          const SizedBox(height: 2),
          Text(date, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
        if (deadline != null) ...[
          const SizedBox(height: 2),
          Text(deadline, style: const TextStyle(color: AppColors.richGold, fontSize: 12)),
        ],
      ]),
    );
  }
}
