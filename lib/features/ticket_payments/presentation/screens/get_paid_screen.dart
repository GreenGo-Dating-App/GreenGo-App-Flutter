import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';
import '../widgets/ticket_fee_widgets.dart';
import 'payments_to_confirm_screen.dart';

/// Business > "Get paid": connect Mercado Pago / Stripe. Buyers pay inside
/// the app and their tickets are confirmed automatically; the money goes
/// straight to the organizer's own account (the full listed ticket price).
/// Buyers pay a GreenGo service fee on top ([TicketFeeScheduleCard]).
///
/// Payment links are no longer accepted (owner rule 2026-10-14): the former
/// "Manual Payment and Approval" section and the personal payment methods
/// editor are gone. "Payments to confirm" (app-bar icon with a badge) stays
/// reachable only while LEGACY link orders are still waiting for this
/// organizer.
class GetPaidScreen extends StatefulWidget {
  const GetPaidScreen({super.key, required this.uid, this.service});

  final String uid;
  final TicketPaymentsService? service;

  static Route<void> route(String uid) =>
      MaterialPageRoute(builder: (_) => GetPaidScreen(uid: uid));

  @override
  State<GetPaidScreen> createState() => _GetPaidScreenState();
}

class _GetPaidScreenState extends State<GetPaidScreen> with WidgetsBindingObserver {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  TicketPaymentsConfig _config = const TicketPaymentsConfig();
  TicketProvider? _busy;
  int? _toConfirm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _svc.config().then((c) {
      if (mounted) setState(() => _config = c);
    });
    unawaited(_refresh());
    _loadPendingCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the provider's onboarding page: re-read the account status.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      await _svc.refreshAccounts();
    } catch (_) {/* status stream still shows the last state */}
  }

  /// Legacy link orders still waiting for this organizer (see class doc).
  Future<void> _loadPendingCount() async {
    try {
      final c = await FirebaseFirestore.instance
          .collection('ticket_orders')
          .where('organizerId', isEqualTo: widget.uid)
          .where('status', isEqualTo: 'awaiting_confirmation')
          .count()
          .get();
      if (mounted) setState(() => _toConfirm = c.count);
    } catch (_) {}
  }

  Future<void> _connect(TicketProvider p) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _busy = p);
    try {
      await TicketPaymentsService.openInApp(await _svc.onboardingUrl(p));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _openToConfirm() {
    Navigator.of(context)
        .push(PaymentsToConfirmScreen.route(widget.uid))
        .then((_) => _loadPendingCount());
  }

  /// App-bar "Payments to confirm" action with the pending-count badge.
  Widget _toConfirmAction(AppLocalizations l) {
    final n = _toConfirm ?? 0;
    return IconButton(
      key: const ValueKey('get-paid-to-confirm'),
      tooltip: '${l.tpToConfirmTitle} ($n)',
      onPressed: _openToConfirm,
      icon: Badge(
        label: Text(n > 99 ? '99+' : '$n'),
        backgroundColor: AppColors.richGold,
        textColor: AppColors.deepBlack,
        child: const Icon(Icons.fact_check_outlined),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: Text(l.tpGetPaidTitle),
        actions: [
          if ((_toConfirm ?? 0) > 0) _toConfirmAction(l),
          IconButton(
            tooltip: l.tpRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: StreamBuilder<PaymentAccounts>(
        stream: _svc.watchAccounts(widget.uid),
        builder: (context, snap) {
          final a = snap.data ?? const PaymentAccounts();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                key: const ValueKey('get-paid-intro'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.richGold.withValues(alpha: 0.35)),
                ),
                child: Row(children: [
                  const Icon(Icons.savings_outlined, color: AppColors.richGold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l.tpGetPaidIntro,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.35)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Row(key: const ValueKey('get-paid-section-auto'), children: [
                const Icon(Icons.bolt_outlined, color: AppColors.richGold, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l.tpAutoSectionTitle,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(l.tpAutoSectionHint,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35)),
              const SizedBox(height: 12),
              _providerCard(l, TicketProvider.mercadoPago, a.mercadoPago,
                  recommendedBr: true, currency: a.mercadoPagoCurrency),
              const SizedBox(height: 12),
              _providerCard(l, TicketProvider.stripe, a.stripe),
              const SizedBox(height: 20),
              const TicketFeeScheduleCard(key: ValueKey('get-paid-fees')),
            ],
          );
        },
      ),
    );
  }

  Widget _providerCard(AppLocalizations l, TicketProvider p, PayoutStatus s,
      {bool recommendedBr = false, String? currency}) {
    final enabled = _config.enabled(p);
    final color = switch (s) {
      PayoutStatus.ready => AppColors.successGreen,
      PayoutStatus.pending => AppColors.warningAmber,
      PayoutStatus.needsReconnect => AppColors.errorRed,
      PayoutStatus.notConnected => AppColors.textTertiary,
    };
    return Container(
      key: ValueKey('get-paid-${p.wire}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(TicketL10n.provider(l, p),
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          if (recommendedBr) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.infoBlue.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(l.tpBadgeBrazil,
                  style: const TextStyle(color: AppColors.infoBlue, fontSize: 10.5)),
            ),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(TicketL10n.payoutStatus(l, s), style: TextStyle(color: color, fontSize: 11.5)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(p == TicketProvider.mercadoPago ? l.tpMpDescription : l.tpStripeDescription,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        if (currency != null && s == PayoutStatus.ready) ...[
          const SizedBox(height: 4),
          Text(l.tpMpCurrencyInfo(currency.toUpperCase()),
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        if (!enabled)
          Text(l.tpBlockNotConfigured,
              style: const TextStyle(color: AppColors.warningAmber, fontSize: 12))
        else if (s != PayoutStatus.ready)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: ValueKey('get-paid-connect-${p.wire}'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack),
              onPressed: _busy != null ? null : () => _connect(p),
              icon: _busy == p
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(s == PayoutStatus.pending
                  ? l.tpContinueSetup
                  : l.tpConnectProvider(TicketL10n.provider(l, p))),
            ),
          )
        else
          TextButton(
            onPressed: _busy != null ? null : () => _connect(p),
            child: Text(l.tpOpenProviderSettings),
          ),
      ]),
    );
  }
}
