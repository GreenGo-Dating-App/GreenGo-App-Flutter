import 'dart:math';

import 'package:equatable/equatable.dart';

import 'ticket_fees.dart';
import 'ticket_payments.dart';

/// Ticket price phases ("early bird", "presale", "regular", ...) of a paid
/// event. Mirror of functions/src/ticket_payments/pricePhases.ts for the
/// editor and the buyer screens; the SERVER prices every order again
/// (createTicketCheckout) and never sells from an invalid setup.
///
/// `events/{id}.pricePhases` = ordered list (price order) of
/// `{id, nameKey, price (major units), quantity}`; the reserved counts per
/// phase live server-side in `ticket_inventory/event_{id}.phaseSold`.

/// Preset names (the stored key is stable; the label is localized).
enum PricePhaseName {
  superEarlyBird,
  earlyBird,
  presale,
  regular,
  late,
  lastMinute,
  door;

  String get wire => name;

  static PricePhaseName? fromWire(Object? v) {
    for (final n in values) {
      if (n.name == v) return n;
    }
    return null;
  }
}

/// At most 10 phases (one per preset name, so 7 in practice).
const int kMaxPricePhases = 10;

/// Same limits as the event price (major units).
const int kPhasePriceMin = 1;
const int kPhasePriceMax = 1000;

class PricePhase extends Equatable {
  const PricePhase({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  /// Stable id (generated once, kept across edits).
  final String id;
  final PricePhaseName name;

  /// Major units of the event currency (like `events.price`).
  final double price;

  /// Tickets sold at this price.
  final int quantity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nameKey': name.wire,
        // Whole amounts stay ints in Firestore (the rules accept any number).
        'price': price == price.roundToDouble() ? price.toInt() : price,
        'quantity': quantity,
      };

  /// Null for an entry this app version does not understand.
  static PricePhase? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final name = PricePhaseName.fromWire(raw['nameKey']);
    final price = raw['price'];
    final qty = raw['quantity'];
    if (id is! String || id.isEmpty || name == null || price is! num || qty is! num) return null;
    return PricePhase(id: id, name: name, price: price.toDouble(), quantity: qty.toInt());
  }

  static List<PricePhase> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <PricePhase>[];
    for (final r in raw) {
      final p = fromMap(r);
      if (p != null) out.add(p);
    }
    return out;
  }

  PricePhase copyWith({PricePhaseName? name, double? price, int? quantity}) => PricePhase(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity ?? this.quantity,
      );

  @override
  List<Object?> get props => [id, name, price, quantity];
}

/// A new stable phase id (20 url-safe chars).
String newPricePhaseId([Random? random]) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final r = random ?? Random.secure();
  return List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
}

/// What is wrong with a phase setup (the editor shows it inline).
enum PricePhaseError {
  tooMany,
  duplicateName,
  priceRange,
  quantity,
  notIncreasing,
  overCapacity,
  soldPhaseRemoved,
  soldPriceChanged,
  belowSold,
  insertedBeforeSold,
}

/// Validates [phases] for an event of [capacity] (<= 0 = unlimited) in
/// [currency]. With [sold] (reserved per phase, from the server) and the
/// [original] phases of the saved event, also the "after sales start" rules:
/// a phase with sales is kept, with the same price and at least as many
/// tickets as it sold; new phases go after the last phase that sold.
PricePhaseError? validatePricePhases(
  List<PricePhase> phases, {
  required int capacity,
  required String currency,
  Map<String, int> sold = const {},
  List<PricePhase> original = const [],
}) {
  if (phases.length > kMaxPricePhases) return PricePhaseError.tooMany;
  final names = <PricePhaseName>{};
  var prev = -1;
  var total = 0;
  for (final p in phases) {
    if (!names.add(p.name)) return PricePhaseError.duplicateName;
    if (p.price < kPhasePriceMin || p.price > kPhasePriceMax) return PricePhaseError.priceRange;
    if (p.quantity < 1) return PricePhaseError.quantity;
    final minor = toMinorUnits(p.price, currency);
    if (minor <= prev) return PricePhaseError.notIncreasing;
    prev = minor;
    total += p.quantity;
  }
  if (capacity > 0 && total > capacity) return PricePhaseError.overCapacity;
  final byId = {for (final p in phases) p.id: p};
  final origById = {for (final p in original) p.id: p};
  for (final e in sold.entries) {
    if (e.value <= 0) continue;
    final p = byId[e.key];
    if (p == null) return PricePhaseError.soldPhaseRemoved;
    final o = origById[e.key];
    if (o != null && toMinorUnits(o.price, currency) != toMinorUnits(p.price, currency)) {
      return PricePhaseError.soldPriceChanged;
    }
    if (p.quantity < e.value) return PricePhaseError.belowSold;
  }
  var lastSold = -1;
  for (var i = 0; i < phases.length; i++) {
    if ((sold[phases[i].id] ?? 0) > 0) lastSold = i;
  }
  for (var i = 0; i < lastSold; i++) {
    // A phase that is not in the saved event is new.
    if (!origById.containsKey(phases[i].id)) return PricePhaseError.insertedBeforeSold;
  }
  return null;
}

/// Tickets left per phase.
List<int> pricePhasesLeft(List<PricePhase> phases, Map<String, int> sold) =>
    [for (final p in phases) max(0, p.quantity - max(0, sold[p.id] ?? 0))];

/// Index of the current phase (first with tickets left); -1 = all sold out.
int currentPricePhaseIndex(List<PricePhase> phases, Map<String, int> sold) =>
    pricePhasesLeft(phases, sold).indexWhere((n) => n > 0);

/// One line of an order: [quantity] tickets of [phase] at [unitAmount] (minor).
class PricePhaseLine extends Equatable {
  const PricePhaseLine({required this.phase, required this.unitAmount, required this.quantity});
  final PricePhase phase;
  final int unitAmount;
  final int quantity;

  @override
  List<Object?> get props => [phase, unitAmount, quantity];
}

/// [qty] tickets from the current phase on (an order may span phases); null
/// when the phases do not have [qty] tickets left.
List<PricePhaseLine>? allocatePricePhases(
    List<PricePhase> phases, Map<String, int> sold, int qty, String currency) {
  final left = pricePhasesLeft(phases, sold);
  var need = qty;
  final out = <PricePhaseLine>[];
  for (var i = 0; i < phases.length && need > 0; i++) {
    final take = min(left[i], need);
    if (take <= 0) continue;
    out.add(PricePhaseLine(phase: phases[i], unitAmount: toMinorUnits(phases[i].price, currency), quantity: take));
    need -= take;
  }
  return need > 0 ? null : out;
}

/// Total of [lines] (minor units).
int pricePhaseTotal(List<PricePhaseLine> lines) =>
    lines.fold(0, (s, l) => s + l.unitAmount * l.quantity);

/// GreenGo service fee of an order spanning phases: per ticket, on each
/// ticket's own price (the seller pays it). Display only.
TicketFeeBreakdown? pricePhaseFee(TicketFeeRule rule, String currency, List<PricePhaseLine> lines) =>
    computeTicketFee(rule, currency, [for (final l in lines) (unitAmount: l.unitAmount, quantity: l.quantity)]);

/// Keeps the list in price order (the order = phase order).
List<PricePhase> sortPricePhases(List<PricePhase> phases) =>
    [...phases]..sort((a, b) => a.price.compareTo(b.price));

/// `ticket_inventory/event_{id}.phaseSold` -> counts.
Map<String, int> phaseSoldFrom(Object? raw) {
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (e.key is String && e.value is num) e.key as String: (e.value as num).toInt(),
  };
}
