import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_fees.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';
import 'ticket_fee_widgets.dart';

/// "How do guests pay?" for a PAID event / experience (editor, mobile + web):
/// Mercado Pago or Stripe, the organizer's connected account. Buyers pay in
/// the app and their tickets are confirmed automatically; the organizer
/// receives the full ticket price and buyers pay a GreenGo service fee on top
/// (shown here as a preview for the price being set).
///
/// Payment links are no longer accepted (owner rule 2026-10-14): a listing
/// still set to a link shows a banner until a provider is picked.
class TicketPaymentSelector extends StatefulWidget {
  const TicketPaymentSelector({
    super.key,
    required this.uid,
    required this.value,
    required this.onChanged,
    required this.price,
    required this.currency,
    this.kind,
    this.listingId,
    this.service,
    this.accounts,
    this.config,
    this.feeRule,
  });

  final String uid;
  final TicketPaymentChoice value;
  final ValueChanged<TicketPaymentChoice> onChanged;

  /// Price in major units, currency as ISO code or symbol.
  final double? price;
  final String? currency;

  /// The listing being edited ('event' | 'experience'; null id = new), for
  /// the service-fee preview.
  final String? kind;
  final String? listingId;

  /// Test seams (production reads Firestore / callables).
  final TicketPaymentsService? service;
  final PaymentAccounts? accounts;
  final TicketPaymentsConfig? config;
  final TicketFeeRule? feeRule;

  @override
  State<TicketPaymentSelector> createState() => _TicketPaymentSelectorState();
}

class _TicketPaymentSelectorState extends State<TicketPaymentSelector> {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  StreamSubscription<PaymentAccounts>? _sub;
  PaymentAccounts _accounts = const PaymentAccounts();
  TicketPaymentsConfig _config = const TicketPaymentsConfig();
  TicketProvider? _connecting;

  @override
  void initState() {
    super.initState();
    if (widget.accounts != null) {
      _accounts = widget.accounts!;
    } else {
      _sub = _svc.watchAccounts(widget.uid).listen((a) {
        if (mounted) setState(() => _accounts = a);
      });
    }
    if (widget.config != null) {
      _config = widget.config!;
    } else {
      _svc.config().then((c) {
        if (mounted) setState(() => _config = c);
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String? get _iso => isoCurrencyFor(widget.currency);

  Future<void> _connect(TicketProvider p) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _connecting = p);
    try {
      final url = await _svc.onboardingUrl(p);
      await TicketPaymentsService.openInApp(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TicketL10n.error(l, e))));
      }
    } finally {
      if (mounted) setState(() => _connecting = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final price = widget.price;
    if (price == null || price <= 0) return const SizedBox.shrink();
    return Column(
      key: const ValueKey('ticket-payment-selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.tpSelectorTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l.tpInstantSubtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 10),
        if (needsReconnect(widget.value))
          _banner(l.tpLinkDiscontinuedBanner, AppColors.warningAmber,
              key: const ValueKey('ticket-link-discontinued')),
        _providerTile(l, TicketProvider.mercadoPago, brazil: true),
        const SizedBox(height: 8),
        _providerTile(l, TicketProvider.stripe),
        const SizedBox(height: 10),
        Text(l.tpFeeHostNote,
            key: const ValueKey('ticket-fee-host-note'),
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
        TicketFeeHostPreview(
          price: price,
          currency: widget.currency,
          kind: widget.kind,
          id: widget.listingId,
          service: _svc,
          rule: widget.feeRule,
        ),
      ],
    );
  }

  Widget _banner(String text, Color color, {Key? key}) => Container(
        key: key,
        margin: const EdgeInsets.only(top: 8, bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5))),
        ]),
      );

  Widget _badge(String t, Color c) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(6)),
        child: Text(t, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700)),
      );

  Widget _providerTile(AppLocalizations l, TicketProvider p, {bool brazil = false}) {
    final status = _accounts.of(p);
    final block = providerBlock(
        p: p, config: _config, accounts: _accounts, currency: _iso, price: widget.price);
    final selected = widget.value.provider == p;
    final canPick = block == null;
    final showConnect = _config.enabled(p) &&
        (status == PayoutStatus.notConnected || status == PayoutStatus.needsReconnect || status == PayoutStatus.pending);
    return Material(
      key: ValueKey('ticket-provider-${p.wire}'),
      color: AppColors.backgroundInput,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: selected ? AppColors.richGold : AppColors.divider, width: selected ? 1.6 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RadioListTile<TicketProvider>(
          value: p,
          groupValue: widget.value.provider,
          activeColor: AppColors.richGold,
          onChanged: canPick ? (_) => widget.onChanged(TicketPaymentChoice(provider: p)) : null,
          title: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(TicketL10n.provider(l, p), style: const TextStyle(color: AppColors.textPrimary)),
            if (brazil) _badge(l.tpBadgeBrazil, AppColors.infoBlue),
          ]),
          subtitle: Text(
            block == null ? l.tpInstantSubtitle : TicketL10n.block(l, block, p,
                accountCurrency: _accounts.mercadoPagoCurrency, currency: _iso),
            style: TextStyle(
                color: block == null ? AppColors.textSecondary : AppColors.warningAmber, fontSize: 12),
          ),
          secondary: _statusChip(l, status),
        ),
        if (showConnect)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: OutlinedButton.icon(
              key: ValueKey('ticket-connect-${p.wire}'),
              onPressed: _connecting != null ? null : () => _connect(p),
              icon: _connecting == p
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link, size: 18),
              label: Text(status == PayoutStatus.pending
                  ? l.tpContinueSetup
                  : l.tpConnectProvider(TicketL10n.provider(l, p))),
            ),
          ),
      ]),
    );
  }

  Widget _statusChip(AppLocalizations l, PayoutStatus s) {
    final c = switch (s) {
      PayoutStatus.ready => AppColors.successGreen,
      PayoutStatus.pending => AppColors.warningAmber,
      PayoutStatus.needsReconnect => AppColors.errorRed,
      PayoutStatus.notConnected => AppColors.textTertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(TicketL10n.payoutStatus(l, s), style: TextStyle(color: c, fontSize: 11)),
    );
  }
}
