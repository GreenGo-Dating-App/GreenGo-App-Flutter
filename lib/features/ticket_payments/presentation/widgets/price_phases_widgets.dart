import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/ticket_payments_service.dart';
import '../../domain/price_phases.dart';
import '../../domain/ticket_fees.dart';
import '../../domain/ticket_payments.dart';
import '../ticket_l10n.dart';

/// Event editor: "Price phases (early bird…)". Owns the list while editing and
/// reports every change through [onChanged] (always in price order). Phases
/// that already sold ([sold], from the server) keep their price, cannot be
/// removed and cannot go below what they sold; new phases go after them.
/// Shows the seller payout estimate per phase (GreenGo fee per ticket on that
/// phase's price, minus the provider's estimate).
class PricePhasesEditor extends StatefulWidget {
  const PricePhasesEditor({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.currency,
    required this.capacity,
    this.sold = const {},
    this.provider,
    this.basePrice,
    this.listingId,
    this.service,
    this.feeRule,
  });

  /// The saved phases (edit) or [] (new event / no phases yet).
  final List<PricePhase> initial;
  final ValueChanged<List<PricePhase>> onChanged;

  /// ISO code or display symbol.
  final String currency;

  /// maxAttendees (<= 0 = unlimited).
  final int capacity;
  final Map<String, int> sold;
  final TicketProvider? provider;

  /// Price of the first phase added (the event's single price so far).
  final double? basePrice;
  final String? listingId;
  final TicketPaymentsService? service;

  /// Test seam (production asks the server once).
  final TicketFeeRule? feeRule;

  @override
  State<PricePhasesEditor> createState() => _PricePhasesEditorState();
}

class _PricePhasesEditorState extends State<PricePhasesEditor> {
  late List<PricePhase> _phases;
  // The list as it was when the editor opened (the saved event's phases):
  // what "already sold" phases are compared against.
  late final List<PricePhase> _original = widget.initial;
  final Map<String, TextEditingController> _price = {};
  final Map<String, TextEditingController> _qty = {};
  TicketFeeRule? _rule;

  String get _iso => isoCurrencyFor(widget.currency) ?? 'usd';

  @override
  void initState() {
    super.initState();
    _phases = sortPricePhases(widget.initial);
    for (final p in _phases) {
      _controllersFor(p);
    }
    _rule = widget.feeRule;
    if (_rule == null) {
      (widget.service ?? TicketPaymentsService())
          .feeRule(kind: 'event', id: widget.listingId)
          .then((r) {
        if (mounted && r != null) setState(() => _rule = r);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [..._price.values, ..._qty.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void _controllersFor(PricePhase p) {
    _price[p.id] = TextEditingController(text: _fmt(p.price));
    _qty[p.id] = TextEditingController(text: '${p.quantity}');
  }

  static String _fmt(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _emit() => widget.onChanged(List.unmodifiable(_phases));

  bool _hasSales(PricePhase p) => (widget.sold[p.id] ?? 0) > 0;

  void _add() {
    final used = _phases.map((p) => p.name).toSet();
    final free = PricePhaseName.values.where((n) => !used.contains(n)).toList();
    if (free.isEmpty || _phases.length >= kMaxPricePhases) return;
    // The next preset after the last one used (Early bird -> Presale ...).
    final lastIdx = _phases.isEmpty ? -1 : _phases.map((p) => p.name.index).reduce((a, b) => a > b ? a : b);
    final name = _phases.isEmpty && free.contains(PricePhaseName.earlyBird)
        ? PricePhaseName.earlyBird
        : free.firstWhere((n) => n.index > lastIdx, orElse: () => free.first);
    final top = _phases.isEmpty ? null : _phases.map((p) => p.price).reduce((a, b) => a > b ? a : b);
    final price = top == null
        ? ((widget.basePrice ?? 10).clamp(kPhasePriceMin, kPhasePriceMax)).toDouble()
        : (top + 5).clamp(kPhasePriceMin, kPhasePriceMax).toDouble();
    final p = PricePhase(id: newPricePhaseId(), name: name, price: price, quantity: 10);
    _controllersFor(p);
    setState(() => _phases = [..._phases, p]);
    _emit();
  }

  void _remove(PricePhase p) {
    setState(() => _phases = _phases.where((x) => x.id != p.id).toList());
    _price.remove(p.id)?.dispose();
    _qty.remove(p.id)?.dispose();
    _emit();
  }

  void _update(PricePhase p) {
    setState(() => _phases = [for (final x in _phases) x.id == p.id ? p : x]);
    _emit();
  }

  /// Keeps the list in price order once the organizer leaves a price field.
  void _resort() {
    final sorted = sortPricePhases(_phases);
    if (!_sameOrder(sorted, _phases)) {
      setState(() => _phases = sorted);
      _emit();
    }
  }

  static bool _sameOrder(List<PricePhase> a, List<PricePhase> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final err = _phases.isEmpty
        ? null
        : validatePricePhases(_phases,
            capacity: widget.capacity, currency: _iso, sold: widget.sold, original: _original);
    final anySold = _phases.any(_hasSales);
    final canAdd = _phases.length < kMaxPricePhases && _phases.length < PricePhaseName.values.length;
    return Column(
      key: const ValueKey('price-phases-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.ppSectionTitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l.ppSectionHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.3)),
        if (anySold) ...[
          const SizedBox(height: 4),
          Text(l.ppLockedHint, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.3)),
        ],
        const SizedBox(height: 8),
        for (final p in _phases) ...[
          _phaseCard(l, p),
          const SizedBox(height: 8),
        ],
        if (err != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(TicketL10n.phaseError(l, err),
                key: const ValueKey('price-phases-error'),
                style: const TextStyle(color: AppColors.errorRed, fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        if (canAdd)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('price-phases-add'),
              onPressed: _add,
              icon: const Icon(Icons.add_circle, color: AppColors.richGold),
              label: Text(l.ppAddPhase, style: const TextStyle(color: AppColors.richGold)),
            ),
          ),
      ],
    );
  }

  Widget _phaseCard(AppLocalizations l, PricePhase p) {
    final sold = widget.sold[p.id] ?? 0;
    final locked = sold > 0;
    final used = _phases.where((x) => x.id != p.id).map((x) => x.name).toSet();
    final rule = _rule;
    final est = rule == null ? null : estimateHostPayout(rule, toMinorUnits(p.price, _iso), _iso, widget.provider);
    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.backgroundInput,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        );
    return Container(
      key: ValueKey('price-phase-${p.id}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<PricePhaseName>(
              key: ValueKey('price-phase-name-${p.id}'),
              initialValue: p.name,
              isExpanded: true,
              dropdownColor: AppColors.backgroundCard,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: deco(l.ppPhaseName),
              items: [
                for (final n in PricePhaseName.values)
                  if (n == p.name || !used.contains(n))
                    DropdownMenuItem(value: n, child: Text(TicketL10n.phaseName(l, n))),
              ],
              onChanged: (n) {
                if (n != null) _update(p.copyWith(name: n));
              },
            ),
          ),
          IconButton(
            key: ValueKey('price-phase-remove-${p.id}'),
            tooltip: l.ppRemovePhase,
            onPressed: locked ? null : () => _remove(p),
            icon: Icon(Icons.delete_outline, color: locked ? AppColors.textTertiary : AppColors.errorRed),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Focus(
              onFocusChange: (has) {
                if (!has) _resort();
              },
              child: TextFormField(
                key: ValueKey('price-phase-price-${p.id}'),
                controller: _price[p.id],
                enabled: !locked,
                style: const TextStyle(color: AppColors.textPrimary),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                decoration: deco('${l.ppPhasePrice} (${widget.currency})'),
                onChanged: (v) {
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n != null) _update(p.copyWith(price: n));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              key: ValueKey('price-phase-qty-${p.id}'),
              controller: _qty[p.id],
              style: const TextStyle(color: AppColors.textPrimary),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: deco(l.ppPhaseQuantity),
              onChanged: (v) => _update(p.copyWith(quantity: int.tryParse(v) ?? 0)),
            ),
          ),
        ]),
        if (locked || est != null) const SizedBox(height: 6),
        if (locked)
          Text(l.ppPhaseSold(sold),
              key: ValueKey('price-phase-sold-${p.id}'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        if (est != null)
          Text(l.ppYouReceive(formatTicketAmount(est.net, _iso)),
              key: ValueKey('price-phase-payout-${p.id}'),
              style: const TextStyle(color: AppColors.richGold, fontSize: 12)),
      ]),
    );
  }
}

/// Buyer side (event detail): every phase with its price, the current one
/// ("Now", "N left at this price", "then X (Late)"), sold-out ones struck
/// through. [sold] null = loading (shows the phases without counts).
class PricePhasesBuyerView extends StatelessWidget {
  const PricePhasesBuyerView({
    super.key,
    required this.phases,
    required this.currency,
    required this.sold,
  });

  final List<PricePhase> phases;

  /// ISO code or display symbol.
  final String? currency;
  final Map<String, int>? sold;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final iso = isoCurrencyFor(currency) ?? 'usd';
    final counts = sold ?? const <String, int>{};
    final left = pricePhasesLeft(phases, counts);
    final cur = sold == null ? -1 : currentPricePhaseIndex(phases, counts);
    String price(PricePhase p) => formatTicketAmount(toMinorUnits(p.price, iso), iso);
    return Container(
      key: const ValueKey('price-phases-buyer'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.local_offer_outlined, color: AppColors.richGold, size: 20),
          const SizedBox(width: 8),
          Text(l.ppBuyerTitle, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        for (var i = 0; i < phases.length; i++)
          _row(l, phases[i], price(phases[i]),
              soldOut: sold != null && left[i] == 0,
              current: i == cur,
              left: left[i],
              next: i == cur && i + 1 < phases.length ? phases[i + 1] : null,
              nextPrice: i == cur && i + 1 < phases.length ? price(phases[i + 1]) : null),
      ]),
    );
  }

  Widget _row(AppLocalizations l, PricePhase p, String price,
      {required bool soldOut, required bool current, required int left, PricePhase? next, String? nextPrice}) {
    final strike = soldOut ? TextDecoration.lineThrough : null;
    final color = soldOut ? AppColors.textTertiary : (current ? AppColors.textPrimary : AppColors.textSecondary);
    return Padding(
      key: ValueKey('price-phase-row-${p.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(TicketL10n.phaseName(l, p.name),
                style: TextStyle(color: color, decoration: strike, fontWeight: current ? FontWeight.w700 : FontWeight.w400)),
          ),
          if (current)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.richGold, borderRadius: BorderRadius.circular(10)),
              child: Text(l.ppNow,
                  style: const TextStyle(color: AppColors.deepBlack, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          Text(soldOut ? '${l.tpTypeSoldOut} · $price' : price,
              key: ValueKey('price-phase-price-${p.id}'),
              style: TextStyle(color: current ? AppColors.richGold : color, decoration: strike, fontWeight: FontWeight.w600)),
        ]),
        if (current)
          Text(l.ppLeftAtPrice(left),
              key: const ValueKey('price-phase-left'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        if (current && next != null && nextPrice != null)
          Text(l.ppThenNext(nextPrice, TicketL10n.phaseName(l, next.name)),
              key: const ValueKey('price-phase-next'),
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12.5)),
      ]),
    );
  }
}

/// Loads the phase counters of [eventId] once and shows [PricePhasesBuyerView].
class EventPricePhasesSection extends StatefulWidget {
  const EventPricePhasesSection({
    super.key,
    required this.eventId,
    required this.phases,
    required this.currency,
    this.service,
  });

  final String eventId;
  final List<PricePhase> phases;
  final String? currency;
  final TicketPaymentsService? service;

  @override
  State<EventPricePhasesSection> createState() => _EventPricePhasesSectionState();
}

class _EventPricePhasesSectionState extends State<EventPricePhasesSection> {
  Map<String, int>? _sold;

  @override
  void initState() {
    super.initState();
    (widget.service ?? TicketPaymentsService()).phaseSold(widget.eventId).then((s) {
      if (mounted) setState(() => _sold = s);
    });
  }

  @override
  Widget build(BuildContext context) =>
      PricePhasesBuyerView(phases: widget.phases, currency: widget.currency, sold: _sold);
}
