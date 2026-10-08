import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/domain/entities/event.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_purchase.dart';

/// "Buy tickets" for a paid event: ticket types (with price, perks and
/// availability) or a single quantity stepper, limited by the remaining
/// capacity and the per-person limit ("You can buy N more"). The exact total
/// and currency are shown BEFORE the checkout opens. The server re-checks
/// every number.
class BuyTicketSheet extends StatefulWidget {
  const BuyTicketSheet({
    super.key,
    required this.event,
    required this.uid,
    this.service,
    this.types,
    this.alreadyHeld,
  });

  final Event event;
  final String uid;
  final TicketPaymentsService? service;

  /// Test seams.
  final List<TicketType>? types;
  final int? alreadyHeld;

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

  int get _total {
    final types = _types ?? const <TicketType>[];
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: types == null
            ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.richGold)))
            : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.tpBuyTickets,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(can == null ? l.tpCanBuyUnlimited : l.tpCanBuyMore(can),
                    key: const ValueKey('buy-can-buy'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 12),
                if (types.isEmpty)
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
                Row(children: [
                  Text(l.tpTotal, style: const TextStyle(color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(formatTicketAmount(_total, _currency),
                      key: const ValueKey('buy-total'),
                      style: const TextStyle(color: AppColors.richGold, fontSize: 18, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 12),
                ElevatedButton(
                  key: const ValueKey('buy-continue'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _selectedCount < 1 || (can != null && _selectedCount > can)
                      ? null
                      : () {
                          final nav = Navigator.of(context);
                          final parent = nav.context;
                          nav.pop();
                          startTicketPurchase(parent,
                              kind: 'event',
                              id: widget.event.id,
                              quantity: _single,
                              items: types.isEmpty ? null : Map.of(_qty));
                        },
                  child: Text(l.tpContinueToPay(formatTicketAmount(_total, _currency))),
                ),
              ]),
      ),
    );
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
