import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_fees.dart';
import '../../domain/ticket_payments.dart';

/// Tickets / GreenGo service fee / Total, as the buyer pays it (minor units).
/// Amounts come from [computeTicketFee] (display mirror) before checkout, or
/// from the server-priced order afterwards.
class TicketFeeBreakdownView extends StatelessWidget {
  const TicketFeeBreakdownView({
    super.key,
    required this.subtotal,
    required this.fee,
    required this.currency,
    this.trial = false,
  });

  final int subtotal;

  /// Null = the fee could not be quoted (shown as "+ service fee").
  final int? fee;
  final String currency;
  final bool trial;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final f = fee;
    return Column(
      key: const ValueKey('ticket-fee-breakdown'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row(l.tpTicketsSubtotal, formatTicketAmount(subtotal, currency), key: 'ticket-fee-subtotal'),
        if (f == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l.tpPlusServiceFee,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          )
        else ...[
          _row(l.tpServiceFee, formatTicketAmount(f, currency), key: 'ticket-fee-fee'),
          if (trial)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(l.tpServiceFeeTrial,
                  key: const ValueKey('ticket-fee-trial'),
                  style: const TextStyle(color: AppColors.successGreen, fontSize: 12)),
            ),
        ],
        const SizedBox(height: 4),
        Row(children: [
          Text(l.tpTotal, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(formatTicketAmount(subtotal + (f ?? 0), currency),
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

/// Host side: "You receive 100% of the ticket price" + the fee schedule
/// buyers pay on top (Get paid, editors).
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

/// Host editor: what a buyer pays for one ticket at [price] (major units).
/// The rule is the host's own (null [id] = a listing not created yet).
class TicketFeeHostPreview extends StatefulWidget {
  const TicketFeeHostPreview({
    super.key,
    required this.price,
    required this.currency,
    this.kind,
    this.id,
    this.service,
    this.rule,
  });

  final double? price;

  /// ISO code or display symbol.
  final String? currency;
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
    final unit = toMinorUnits(price, iso);
    final fee = ticketFeePerTicket(rule, unit, iso);
    if (fee == null) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('ticket-fee-host-preview'),
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        l.tpFeeBuyerPreview(formatTicketAmount(unit, iso), formatTicketAmount(fee, iso),
            formatTicketAmount(unit + fee, iso)),
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}

/// Buyer side, before paying (experience booking summary / payment): asks
/// the server which fee rule applies to [organizerId]'s listing and shows
/// Tickets / GreenGo service fee / Total for [lines] (minor units).
class TicketFeeQuoteView extends StatefulWidget {
  const TicketFeeQuoteView({
    super.key,
    required this.organizerId,
    required this.kind,
    required this.listingId,
    required this.currency,
    required this.lines,
    this.service,
    this.rule,
  });

  final String organizerId;
  final String kind;
  final String listingId;

  /// ISO code (lower case).
  final String currency;
  final List<({int unitAmount, int quantity})> lines;
  final TicketPaymentsService? service;

  /// Test seam (production asks the server).
  final TicketFeeRule? rule;

  @override
  State<TicketFeeQuoteView> createState() => _TicketFeeQuoteViewState();
}

class _TicketFeeQuoteViewState extends State<TicketFeeQuoteView> {
  TicketFeeRule? _rule;

  @override
  void initState() {
    super.initState();
    _rule = widget.rule;
    if (_rule == null) {
      (widget.service ?? TicketPaymentsService())
          .feeRule(organizerId: widget.organizerId, kind: widget.kind, id: widget.listingId)
          .then((r) {
        if (mounted && r != null) setState(() => _rule = r);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rule = _rule;
    final subtotal = widget.lines.fold<int>(0, (s, l) => s + l.unitAmount * l.quantity);
    final fee = rule == null ? null : computeTicketFee(rule, widget.currency, widget.lines);
    return TicketFeeBreakdownView(
      subtotal: subtotal,
      fee: fee?.fee,
      currency: widget.currency,
      trial: rule == TicketFeeRule.trial && (fee?.fee ?? 0) > 0,
    );
  }
}
