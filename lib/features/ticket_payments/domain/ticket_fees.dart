import 'ticket_payments.dart';

/// GreenGo service fee on paid tickets — DISPLAY-ONLY mirror of
/// functions/src/ticket_payments/fees.ts (the server prices every order and
/// is authoritative; keep both in sync).
///
/// The fee is ADDED ON TOP for the buyer; the organizer receives the full
/// listed ticket price. Per ticket, by the HOST's effective tier:
///   Silver   US$ 3 + 10 % (max US$ 10)
///   Gold     US$ 2 + 10 % (max US$ 9)
///   Platinum US$ 1 + 10 % (max US$ 8)   (TEST = Platinum; no paid tier = Silver)
///   trial    flat US$ 1 on the host's first paid listing (event or experience)
/// Free tickets: no fee. The US$ parts are converted with [kUsdRates] and
/// rounded to the currency's minor unit; the 10 % is taken in the ticket
/// currency.
enum TicketFeeRule {
  trial('trial'),
  silver('silver'),
  gold('gold'),
  platinum('platinum');

  const TicketFeeRule(this.wire);
  final String wire;

  static TicketFeeRule? fromWire(Object? v) {
    for (final r in values) {
      if (r.wire == v) return r;
    }
    return null;
  }
}

class TicketFeeSchedule {
  const TicketFeeSchedule({required this.fixedUsdCents, required this.percent, this.capUsdCents});

  /// Fixed part per ticket, US$ cents.
  final int fixedUsdCents;

  /// Percent of the ticket price (in the ticket currency).
  final int percent;

  /// Max fee per ticket, US$ cents (null = no cap: the flat trial).
  final int? capUsdCents;
}

const Map<TicketFeeRule, TicketFeeSchedule> kTicketFeeSchedules = {
  TicketFeeRule.silver: TicketFeeSchedule(fixedUsdCents: 300, percent: 10, capUsdCents: 1000),
  TicketFeeRule.gold: TicketFeeSchedule(fixedUsdCents: 200, percent: 10, capUsdCents: 900),
  TicketFeeRule.platinum: TicketFeeSchedule(fixedUsdCents: 100, percent: 10, capUsdCents: 800),
  TicketFeeRule.trial: TicketFeeSchedule(fixedUsdCents: 100, percent: 0),
};

/// Units of each currency per 1 US$ — must match USD_RATES in
/// functions/src/ticket_payments/fees.ts (owner-maintained).
const Map<String, double> kUsdRates = {
  'usd': 1, 'eur': 0.92, 'gbp': 0.79, 'brl': 5.5, 'jpy': 150, 'aud': 1.52, 'cad': 1.37, 'chf': 0.88,
  'czk': 23, 'dkk': 6.9, 'hkd': 7.8, 'huf': 360, 'inr': 84, 'mxn': 18.5, 'myr': 4.5, 'nok': 10.8,
  'nzd': 1.66, 'pln': 4, 'ron': 4.6, 'sek': 10.5, 'sgd': 1.34, 'thb': 35, 'aed': 3.67, 'bgn': 1.8,
  'ars': 1000, 'clp': 940, 'cop': 4100, 'pen': 3.75, 'uyu': 40, 'krw': 1380,
};

/// Effective tier name ('SILVER' | 'GOLD' | 'PLATINUM' | 'TEST' | other) -> rule.
TicketFeeRule ticketFeeRuleForTier(String? tier, {bool trial = false}) {
  if (trial) return TicketFeeRule.trial;
  switch ((tier ?? '').toUpperCase()) {
    case 'PLATINUM':
    case 'TEST':
      return TicketFeeRule.platinum;
    case 'GOLD':
      return TicketFeeRule.gold;
    default:
      return TicketFeeRule.silver;
  }
}

/// US$ cents -> minor units of [currency] (rounded half up); null without a rate.
int? usdCentsToMinor(int usdCents, String currency) {
  final rate = kUsdRates[currency.toLowerCase()];
  if (rate == null) return null;
  final f = currencyExponent(currency) == 0 ? 1 : 100;
  return double.parse((usdCents / 100 * rate * f).toStringAsFixed(6)).round();
}

/// Fee for ONE ticket of [unitMinor] minor units; 0 when free, null without a rate.
int? ticketFeePerTicket(TicketFeeRule rule, int unitMinor, String currency) {
  if (unitMinor <= 0) return 0;
  final s = kTicketFeeSchedules[rule]!;
  final fixed = usdCentsToMinor(s.fixedUsdCents, currency);
  if (fixed == null) return null;
  final raw = fixed + (unitMinor * s.percent / 100).round();
  if (s.capUsdCents == null) return raw;
  final cap = usdCentsToMinor(s.capUsdCents!, currency)!;
  return raw < cap ? raw : cap;
}

/// What the buyer sees before paying (minor units).
class TicketFeeBreakdown {
  const TicketFeeBreakdown({required this.rule, required this.subtotal, required this.fee});

  final TicketFeeRule rule;

  /// Ticket prices (what the organizer receives).
  final int subtotal;

  /// GreenGo service fee for the whole order.
  final int fee;

  int get total => subtotal + fee;
}

/// Whole-order fee for [lines] (unit price, quantity); null without a rate.
TicketFeeBreakdown? computeTicketFee(
    TicketFeeRule rule, String currency, List<({int unitAmount, int quantity})> lines) {
  var subtotal = 0;
  var fee = 0;
  for (final l in lines) {
    final unitFee = ticketFeePerTicket(rule, l.unitAmount, currency);
    if (unitFee == null) return null;
    subtotal += l.unitAmount * l.quantity;
    fee += unitFee * l.quantity;
  }
  return TicketFeeBreakdown(rule: rule, subtotal: subtotal, fee: fee);
}
