import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/organizer_share_notice.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/domain/entities/event.dart';
import '../../../trader/presentation/widgets/seller_trader_info.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/price_phases.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';
import '../ticket_purchase.dart';
import 'ticket_fee_widgets.dart';

/// "Buy tickets" for a paid event: ticket types (with price, perks and
/// availability) or a single quantity stepper, limited by the remaining
/// capacity and the per-person limit ("You can buy N more"). The exact total
/// (the ticket prices: the GreenGo service fee is paid by the seller) is shown
/// BEFORE the checkout opens. The server re-checks (and re-prices) every number.
/// Events with price phases: the tickets are priced from the current phase on
/// (an order may span phases, one line per phase) and the shown total is sent
/// as `expectedTotal` (the server answers `price_changed` if a phase sold out
/// meanwhile).
class BuyTicketSheet extends StatefulWidget {
  const BuyTicketSheet({
    super.key,
    required this.event,
    required this.uid,
    this.service,
    this.types,
    this.alreadyHeld,
    this.phaseSold,
  });

  final Event event;
  final String uid;
  final TicketPaymentsService? service;

  /// Test seams.
  final List<TicketType>? types;
  final int? alreadyHeld;
  final Map<String, int>? phaseSold;

  static Future<void> show(BuildContext context, {required Event event, required String uid}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.backgroundCard,
        builder: (_) => BuyTicketSheet(event: event, uid: uid),
      );

  @override
  State<BuyTicketSheet> createState() => _BuyTicketSheetState();
}

class _BuyTicketSheetState extends State<BuyTicketSheet> {
  late final TicketPaymentsService _svc = widget.service ?? TicketPaymentsService();
  List<TicketType>? _types;
  int _held = 0;
  Map<String, int> _heldPerType = const {};
  final Map<String, int> _qty = {};
  int _single = 1;
  // Reserved per price phase (null while loading; events with phases only).
  Map<String, int>? _phaseSold;

  String get _currency => widget.event.currencyCode ?? isoCurrencyFor(widget.event.currency) ?? 'usd';

  @override
  void initState() {
    super.initState();
    if (widget.types != null) {
      _types = widget.types;
    } else {
      _svc.watchTicketTypes(widget.event.id).first.then((t) {
        if (mounted) setState(() => _types = t);
      }).catchError((Object _) {
        if (mounted) setState(() => _types = const []);
      });
    }
    if (widget.event.hasPricePhases) {
      if (widget.phaseSold != null) {
        _phaseSold = widget.phaseSold;
      } else {
        _svc.phaseSold(widget.event.id).then((s) {
          if (mounted) setState(() => _phaseSold = s);
        });
      }
    }
    if (widget.alreadyHeld != null) {
      _held = widget.alreadyHeld!;
    } else {
      _svc.holdings('event', widget.event.id, widget.uid).then((h) {
        if (mounted) {
          setState(() {
            _held = h.held + h.owned;
            _heldPerType = h.perType;
          });
        }
      });
    }
  }

  int? get _capacityLeft {
    final max = widget.event.maxAttendees;
    if (max <= 0) return null;
    return (max - widget.event.attendeeCount).clamp(0, max);
  }

  int? get _canBuy => remainingForBuyer(
      limit: widget.event.maxTicketsPerUser, alreadyHeld: _held, remainingCapacity: _capacityLeft);

  int get _selectedCount => (_types?.isNotEmpty ?? false)
      ? _qty.values.fold(0, (a, b) => a + b)
      : _single;

  /// Price phases apply to the general ticket (events without ticket types).
  bool get _phased => widget.event.hasPricePhases && (_types?.isEmpty ?? false);

  List<PricePhaseLine>? get _phaseLines =>
      allocatePricePhases(widget.event.pricePhases, _phaseSold ?? const {}, _single, _currency);

  int get _phaseLeft =>
      pricePhasesLeft(widget.event.pricePhases, _phaseSold ?? const {}).fold(0, (a, b) => a + b);

  int get _total {
    final types = _types ?? const <TicketType>[];
    if (_phased) {
      final lines = _phaseLines;
      return lines == null ? 0 : pricePhaseTotal(lines);
    }
    if (types.isEmpty) {
      return toMinorUnits(widget.event.price ?? 0, _currency) * _single;
    }
    return types.fold(0, (s, t) => s + t.price * (_qty[t.id] ?? 0));
  }

  int _maxFor(TicketType t) {
    final others = _selectedCount - (_qty[t.id] ?? 0);
    var max = 100;
    final can = _canBuy;
    if (can != null) max = can - others;
    if (t.left != null && t.left! < max) max = t.left!;
    if (t.maxPerUser != null) {
      final perType = t.maxPerUser! - (_heldPerType[t.id] ?? 0);
      if (perType < max) max = perType;
    }
    return max.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final types = _types;
    final can = _canBuy;
    final now = DateTime.now();
    final total = _total;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: types == null || (widget.event.hasPricePhases && types.isEmpty && _phaseSold == null)
            ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.richGold)))
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.tpBuyTickets,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(can == null ? l.tpCanBuyUnlimited : l.tpCanBuyMore(can),
                    key: const ValueKey('buy-can-buy'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 12),
                if (types.isEmpty && _phased)
                  ..._phasedRows(l, can)
                else if (types.isEmpty)
                  _row(
                    key: 'buy-qty-single',
                    title: widget.event.title,
                    subtitle: formatTicketAmount(toMinorUnits(widget.event.price ?? 0, _currency), _currency),
                    value: _single,
                    min: 1,
                    max: (can ?? 100).clamp(0, 100),
                    onChanged: (v) => setState(() => _single = v),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
                    child: ListView(shrinkWrap: true, children: [
                      for (final t in types.where((t) => !t.hidden))
                        _typeRow(l, t, ticketTypeState(t, now)),
                    ]),
                  ),
                const Divider(color: AppColors.divider, height: 24),
                TicketFeeBreakdownView(subtotal: total, currency: _currency),
                const SizedBox(height: 12),
                const OrganizerShareNotice(),
                // Terms 12.4 / DSA art. 30: the seller's trader details.
                SellerTraderInfo(sellerId: widget.event.organizerId, topSpacing: 8),
                const SizedBox(height: 8),
                ElevatedButton(
                  key: const ValueKey('buy-continue'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _selectedCount < 1 || (can != null && _selectedCount > can) ||
                          (_phased && _phaseLines == null)
                      ? null
                      : () {
                          final nav = Navigator.of(context);
                          final parent = nav.context;
                          nav.pop();
                          startTicketPurchase(parent,
                              kind: 'event',
                              id: widget.event.id,
                              quantity: _single,
                              items: types.isEmpty ? null : Map.of(_qty),
                              expectedTotal: _phased ? total : null);
                        },
                  child: Text(l.tpContinueToPay(formatTicketAmount(total, _currency))),
                ),
              ]),
      ),
    );
  }

  /// Quantity stepper priced by phase + one line per phase of the order.
  List<Widget> _phasedRows(AppLocalizations l, int? can) {
    final phases = widget.event.pricePhases;
    final sold = _phaseSold ?? const <String, int>{};
    final cur = currentPricePhaseIndex(phases, sold);
    final left = _phaseLeft;
    var max = (can ?? 100).clamp(0, 100);
    if (left < max) max = left;
    final lines = _phaseLines;
    return [
      _row(
        key: 'buy-qty-single',
        title: widget.event.title,
        subtitle: cur < 0
            ? l.tpTypeSoldOut
            : '${TicketL10n.phaseName(l, phases[cur].name)} · '
                '${formatTicketAmount(toMinorUnits(phases[cur].price, _currency), _currency)} · '
                '${l.ppLeftAtPrice(pricePhasesLeft(phases, sold)[cur])}',
        value: _single,
        min: max < 1 ? 0 : 1,
        max: max,
        onChanged: (v) => setState(() => _single = v),
      ),
      if (lines != null)
        for (final x in lines)
          Padding(
            key: ValueKey('buy-phase-line-${x.phase.id}'),
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Row(children: [
              Expanded(
                child: Text(l.ppLineQty(TicketL10n.phaseName(l, x.phase.name), x.quantity),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
              Text(formatTicketAmount(x.unitAmount * x.quantity, _currency),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ]),
          ),
    ];
  }

  Widget _typeRow(AppLocalizations l, TicketType t, TicketTypeState s) {
    final status = switch (s) {
      TicketTypeState.soldOut => l.tpTypeSoldOut,
      TicketTypeState.notStarted => l.tpTypeNotStarted,
      TicketTypeState.ended => l.tpTypeEnded,
      TicketTypeState.unavailable => l.tpTypeUnavailable,
      TicketTypeState.onSale => t.left != null && t.left! <= 10 ? l.tpTypeOnlyLeft(t.left!) : null,
    };
    final sub = [
      t.price == 0 ? l.tpFree : formatTicketAmount(t.price, _currency),
      if (t.description != null && t.description!.isNotEmpty) t.description!,
      if (status != null) status,
    ].join(' · ');
    return _row(
      key: 'buy-type-${t.id}',
      title: t.name,
      subtitle: sub,
      value: _qty[t.id] ?? 0,
      min: 0,
      max: s == TicketTypeState.onSale ? _maxFor(t) : 0,
      onChanged: (v) => setState(() => _qty[t.id] = v),
    );
  }

  Widget _row({
    required String key,
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) =>
      Padding(
        key: ValueKey(key),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            ]),
          ),
          IconButton(
            key: ValueKey('$key-minus'),
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.richGold),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Text('$value', key: ValueKey('$key-value'), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          IconButton(
            key: ValueKey('$key-plus'),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.richGold),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ]),
      );
}
