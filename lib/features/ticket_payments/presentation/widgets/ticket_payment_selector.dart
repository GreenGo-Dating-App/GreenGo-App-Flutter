import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';

/// "How do guests pay?" for a PAID event / experience (editor, mobile + web).
///
///  * Instant (Stripe / Mercado Pago, connected account): tickets confirmed
///    automatically. Recommended for many people.
///  * Manual (one of the organizer's own payment methods, or cash / bank
///    transfer): the organizer confirms each payment. No setup.
/// The order and badges follow [adviseTicketPayment]; nothing is ever blocked
/// by the recommendation (only an unusable provider cannot be picked).
class TicketPaymentSelector extends StatefulWidget {
  const TicketPaymentSelector({
    super.key,
    required this.uid,
    required this.value,
    required this.onChanged,
    required this.capacity,
    required this.price,
    required this.currency,
    this.service,
    this.profileMethodKeys,
    this.accounts,
    this.config,
  });

  final String uid;
  final TicketPaymentChoice value;
  final ValueChanged<TicketPaymentChoice> onChanged;

  /// Max attendees / places (null or <= 0 = unlimited).
  final int? capacity;

  /// Price in major units, currency as ISO code or symbol.
  final double? price;
  final String? currency;

  /// Test seams (production reads Firestore / callables).
  final TicketPaymentsService? service;
  final List<String>? profileMethodKeys;
  final PaymentAccounts? accounts;
  final TicketPaymentsConfig? config;

  @override
  State<TicketPaymentSelector> createState() => _TicketPaymentSelectorState();
}

class _TicketPaymentSelectorState extends State<TicketPaymentSelector> {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  StreamSubscription<PaymentAccounts>? _sub;
  PaymentAccounts _accounts = const PaymentAccounts();
  TicketPaymentsConfig _config = const TicketPaymentsConfig();
  List<String> _profileKeys = const [];
  late final TextEditingController _instructions =
      TextEditingController(text: widget.value.instructions ?? '');
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
    if (widget.profileMethodKeys != null) {
      _profileKeys = widget.profileMethodKeys!;
    } else {
      FirebaseFirestore.instance.collection('profiles').doc(widget.uid).get().then((d) {
        final raw = d.data()?['paymentLinks'];
        if (raw is Map && mounted) {
          setState(() => _profileKeys = [
                for (final e in raw.entries)
                  if (e.value is String && (e.value as String).isNotEmpty) '${e.key}',
              ]);
        }
      }).catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _instructions.dispose();
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
    final advice = adviseTicketPayment(
        capacity: widget.capacity, price: widget.price, threshold: _config.largeAudienceThreshold);
    if (advice == TicketPaymentAdvice.none) return const SizedBox.shrink();
    final instantFirst = advice == TicketPaymentAdvice.instantRecommended;
    final v = widget.value;

    final instant = <Widget>[
      _providerTile(l, TicketProvider.mercadoPago, recommended: instantFirst, brazil: true),
      const SizedBox(height: 8),
      _providerTile(l, TicketProvider.stripe, recommended: instantFirst),
    ];
    final manual = _manualTile(l, simplest: !instantFirst);

    return Column(
      key: const ValueKey('ticket-payment-selector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.tpSelectorTitle,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(instantFirst ? l.tpAdviceLarge : l.tpAdviceSmall,
            key: ValueKey('ticket-advice-${advice.name}'),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        const SizedBox(height: 10),
        if (needsReconnect(v)) _banner(l.tpReconnectBanner, AppColors.warningAmber),
        if (instantFirst) ...[
          _groupLabel(l.tpInstantTitle),
          ...instant,
          const SizedBox(height: 14),
          _groupLabel(l.tpManualTitle),
          manual,
        ] else ...[
          _groupLabel(l.tpManualTitle),
          manual,
          const SizedBox(height: 14),
          _groupLabel(l.tpInstantOptional),
          ...instant,
        ],
        if (warnManualForLarge(advice, v.provider))
          _banner(
              l.tpManualLargeWarning(
                  widget.capacity == null || widget.capacity! <= 0 ? '∞' : '${widget.capacity}'),
              AppColors.warningAmber,
              key: const ValueKey('ticket-manual-warning')),
        const SizedBox(height: 8),
        Text(l.tpNoFeeNote, style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
      ],
    );
  }

  Widget _groupLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.richGold, fontSize: 12.5, fontWeight: FontWeight.w700)),
      );

  Widget _banner(String text, Color color, {Key? key}) => Container(
        key: key,
        margin: const EdgeInsets.only(top: 8, bottom: 4),
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

  Widget _providerTile(AppLocalizations l, TicketProvider p,
      {required bool recommended, bool brazil = false}) {
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
            if (recommended) _badge(l.tpBadgeRecommended, AppColors.successGreen),
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

  Widget _manualTile(AppLocalizations l, {required bool simplest}) {
    final methods = manualTicketMethods(_profileKeys);
    final v = widget.value;
    final selected = v.provider == TicketProvider.link;
    final current = methods.contains(v.linkMethod) ? v.linkMethod : null;
    return Material(
      key: const ValueKey('ticket-provider-link'),
      color: AppColors.backgroundInput,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: selected ? AppColors.richGold : AppColors.divider, width: selected ? 1.6 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        RadioListTile<TicketProvider>(
          value: TicketProvider.link,
          groupValue: v.provider,
          activeColor: AppColors.richGold,
          onChanged: (_) => widget.onChanged(TicketPaymentChoice(
              provider: TicketProvider.link, linkMethod: current ?? methods.first, instructions: _instructions.text)),
          title: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(l.tpManualTitle, style: const TextStyle(color: AppColors.textPrimary)),
            if (simplest) _badge(l.tpBadgeNoSetup, AppColors.successGreen),
          ]),
          subtitle: Text(l.tpManualSubtitle,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        if (selected) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              key: const ValueKey('ticket-link-method'),
              value: current,
              dropdownColor: AppColors.backgroundCard,
              decoration: InputDecoration(labelText: l.tpManualMethodLabel),
              items: [
                for (final m in methods)
                  DropdownMenuItem(value: m, child: Text(TicketL10n.method(l, m))),
              ],
              onChanged: (m) => widget.onChanged(v.copyWith(linkMethod: m)),
            ),
          ),
          if (_profileKeys.where((k) => k != 'stripe' && k != 'mercadoPago').isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(l.tpManualAddMethodsHint,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
            ),
          if (current == kTicketMethodBankTransfer || current == kTicketMethodCash)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: TextField(
                controller: _instructions,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: current == kTicketMethodBankTransfer
                      ? l.tpBankInstructionsLabel
                      : l.tpCashInstructionsLabel,
                ),
                onChanged: (t) => widget.onChanged(v.copyWith(instructions: t)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(l.tpManualDisclaimer,
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 11.5)),
          ),
        ],
      ]),
      ),
    );
  }
}
