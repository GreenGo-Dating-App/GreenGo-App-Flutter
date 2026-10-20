import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/info_button.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_fees.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';

/// What the buyer pays (minor units). The GreenGo service fee is paid by the
/// seller (owner rule 2026-10-14), so a buyer sees the ticket price as the
/// total. [feeOnTop] is only for orders priced BEFORE that change, when the
/// buyer paid the fee on top: Tickets / GreenGo service fee / Total.
class TicketFeeBreakdownView extends StatelessWidget {
  const TicketFeeBreakdownView({
    super.key,
    required this.subtotal,
    required this.currency,
    this.fee,
    this.feeOnTop = false,
    this.trial = false,
  });

  final int subtotal;

  /// Fee of a legacy buyer-paid order (shown only with [feeOnTop]).
  final int? fee;
  final String currency;
  final bool feeOnTop;
  final bool trial;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final f = feeOnTop ? (fee ?? 0) : 0;
    return Column(
      key: const ValueKey('ticket-fee-breakdown'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (f > 0) ...[
          _row(l.tpTicketsSubtotal, formatTicketAmount(subtotal, currency), key: 'ticket-fee-subtotal'),
          _row(l.tpServiceFee, formatTicketAmount(f, currency), key: 'ticket-fee-fee'),
          if (trial)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l.tpServiceFeeTrial,
                  key: const ValueKey('ticket-fee-trial'),
                  style: const TextStyle(color: AppColors.successGreen, fontSize: 12)),
            ),
          const SizedBox(height: 4),
        ],
        Row(children: [
          Text(l.tpTotal, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(formatTicketAmount(subtotal + f, currency),
              key: const ValueKey('buy-total'),
              style: const TextStyle(color: AppColors.richGold, fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
      ],
    );
  }

  Widget _row(String label, String value, {required String key}) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value, key: ValueKey(key), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ]),
      );
}

/// Host side: the GreenGo service fee schedule the SELLER pays per ticket
/// (Get paid, editors).
class TicketFeeScheduleCard extends StatelessWidget {
  const TicketFeeScheduleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const line = TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.receipt_long_outlined, color: AppColors.richGold, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.tpServiceFee,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
          ),
          InfoButton(
            title: l.xplInfoFeeTitle,
            message: l.xplInfoFeeBody,
            bullets: [
              l.xplInfoFeeTiers,
              l.xplInfoFeeTrial,
              l.xplInfoFeeFree,
              l.xplInfoFeeProvider,
            ],
          ),
        ]),
        const SizedBox(height: 6),
        Text(l.tpFeeHostNote, style: line),
        const SizedBox(height: 6),
        Text('• ${l.tpFeeRuleSilver}', style: line),
        Text('• ${l.tpFeeRuleGold}', style: line),
        Text('• ${l.tpFeeRulePlatinum}', style: line),
        Text('• ${l.tpFeeRuleTrial}', style: line.copyWith(color: AppColors.successGreen)),
      ]),
    );
  }
}

/// Host editor: per-ticket payout ESTIMATE at [price] (major units): the
/// buyer pays the price, minus the GreenGo service fee (the host's own rule;
/// null [id] = a listing not created yet), minus the chosen [provider]'s
/// processing fee (estimate; asks to pick one while null).
class TicketFeeHostPreview extends StatefulWidget {
  const TicketFeeHostPreview({
    super.key,
    required this.price,
    required this.currency,
    this.provider,
    this.kind,
    this.id,
    this.service,
    this.rule,
  });

  final double? price;

  /// ISO code or display symbol.
  final String? currency;
  final TicketProvider? provider;
  final String? kind;
  final String? id;
  final TicketPaymentsService? service;

  /// Test seam (production asks the server).
  final TicketFeeRule? rule;

  @override
  State<TicketFeeHostPreview> createState() => _TicketFeeHostPreviewState();
}

class _TicketFeeHostPreviewState extends State<TicketFeeHostPreview> {
  TicketFeeRule? _rule;

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
    if (_rule == null) {
      (widget.service ?? TicketPaymentsService())
          .feeRule(kind: widget.kind, id: widget.id)
          .then((r) {
        if (mounted && r != null) setState(() => _rule = r);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final iso = isoCurrencyFor(widget.currency);
    final price = widget.price;
    final rule = _rule;
    if (iso == null || price == null || price <= 0 || rule == null) return const SizedBox.shrink();
    final est = estimateHostPayout(rule, toMinorUnits(price, iso), iso, widget.provider);
    if (est == null) return const SizedBox.shrink();
    const small = TextStyle(color: AppColors.textSecondary, fontSize: 12.5);
    Widget row(String label, String value, String key, {TextStyle style = small}) => Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: style)),
            Text(value, key: ValueKey(key), style: style),
          ]),
        );
    final p = widget.provider;
    final providerFee = est.providerFee;
    return Container(
      key: const ValueKey('ticket-fee-host-preview'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(l.tpPayoutTitle,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          InfoButton(
            title: l.xplInfoReceiveTitle,
            message: l.xplInfoReceiveBody,
            bullets: [l.xplInfoFeeTiers, l.xplInfoFeeProvider],
          ),
        ]),
        const SizedBox(height: 6),
        row(l.tpPayoutBuyerPays, formatTicketAmount(est.price, iso), 'payout-price'),
        row(rule == TicketFeeRule.trial ? l.tpPayoutGreenGoFeeTrial : l.tpServiceFee,
            '- ${formatTicketAmount(est.greenGoFee, iso)}', 'payout-greengo-fee'),
        if (p != null && providerFee != null)
          row(l.tpPayoutProviderFee(TicketL10n.provider(l, p)),
              '≈ - ${formatTicketAmount(providerFee, iso)}', 'payout-provider-fee')
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(l.tpPayoutPickProvider,
                key: const ValueKey('payout-pick-provider'),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ),
        const Divider(height: 12, color: AppColors.divider),
        row(l.tpPayoutYouReceive, '≈ ${formatTicketAmount(est.net, iso)}', 'payout-net',
            style: const TextStyle(color: AppColors.richGold, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(l.tpPayoutEstimateNote,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
      ]),
    );
  }
}

/// Buyer side, before paying (experience booking summary / payment): the
/// total for [lines] (minor units). The GreenGo service fee is paid by the
/// seller, so nothing is added for the buyer.
class TicketFeeQuoteView extends StatelessWidget {
  const TicketFeeQuoteView({
    super.key,
    required this.currency,
    required this.lines,
  });

  /// ISO code (lower case).
  final String currency;
  final List<({int unitAmount, int quantity})> lines;

  @override
  Widget build(BuildContext context) {
    final subtotal = lines.fold<int>(0, (s, l) => s + l.unitAmount * l.quantity);
    return TicketFeeBreakdownView(subtotal: subtotal, currency: currency);
  }
}
