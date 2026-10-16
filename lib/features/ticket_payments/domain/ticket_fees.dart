import 'ticket_payments.dart';

/// GreenGo service fee on paid tickets — DISPLAY-ONLY mirror of
/// functions/src/ticket_payments/fees.ts (the server prices every order and
/// is authoritative; keep both in sync).
///
/// The fee is PAID BY THE SELLER (owner rule 2026-10-14): the buyer pays the
/// listed ticket price only and GreenGo keeps its fee out of it, so the
/// organizer receives price - fee (minus the provider's processing fee).
/// Per ticket, by the HOST's effective tier (caps raised 2026-10-16 from 10/9/8):
///   Silver   US$ 3 + 10 % (max US$ 30)
///   Gold     US$ 2 + 10 % (max US$ 28)
///   Platinum US$ 1 + 10 % (max US$ 25)   (TEST = Platinum; no paid tier = Silver)
///   trial    flat US$ 1 on the host's first paid listing (event or experience)
/// Free tickets: no fee. The fee never exceeds the ticket price. The US$ parts are converted with [kUsdRates] and
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
  TicketFeeRule.silver: TicketFeeSchedule(fixedUsdCents: 300, percent: 10, capUsdCents: 3000),
  TicketFeeRule.gold: TicketFeeSchedule(fixedUsdCents: 200, percent: 10, capUsdCents: 2800),
  TicketFeeRule.platinum: TicketFeeSchedule(fixedUsdCents: 100, percent: 10, capUsdCents: 2500),
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
  final cap = s.capUsdCents == null ? raw : usdCentsToMinor(s.capUsdCents!, currency)!;
  final capped = raw < cap ? raw : cap;
  return capped < unitMinor ? capped : unitMinor;
}

/// An order's fee split (minor units).
class TicketFeeBreakdown {
  const TicketFeeBreakdown({required this.rule, required this.subtotal, required this.fee});

  final TicketFeeRule rule;

  /// Ticket prices = what the buyer pays.
  final int subtotal;

  /// GreenGo service fee for the whole order, paid by the seller.
  final int fee;

  /// What the buyer pays (the fee is not added on top).
  int get total => subtotal;

  /// What the organizer receives before the provider's processing fee.
  int get hostNet => subtotal - fee;
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

/// A payment provider's processing fee, for the host's payout ESTIMATE only
/// (GreenGo never charges it: Stripe / Mercado Pago debit it from the host's
/// own account, and the real amount depends on the card, country and payment
/// method). Public standard rates, 2026-10, rounded up where they vary.
class ProviderFeeEstimate {
  const ProviderFeeEstimate({required this.percent, this.fixedMinor = 0});

  /// Percent of the charge.
  final double percent;

  /// Fixed part per charge, minor units of the ticket currency.
  final int fixedMinor;
}

const Map<String, ProviderFeeEstimate> _kStripeFees = {
  'usd': ProviderFeeEstimate(percent: 2.9, fixedMinor: 30),
  'eur': ProviderFeeEstimate(percent: 1.5, fixedMinor: 25),
  'gbp': ProviderFeeEstimate(percent: 1.5, fixedMinor: 20),
  'brl': ProviderFeeEstimate(percent: 3.99, fixedMinor: 39),
  'cad': ProviderFeeEstimate(percent: 2.9, fixedMinor: 30),
  'aud': ProviderFeeEstimate(percent: 1.7, fixedMinor: 30),
  'mxn': ProviderFeeEstimate(percent: 3.6, fixedMinor: 300),
};

/// Mercado Pago Checkout Pro, card paid and released at once (Pix is cheaper).
const Map<String, ProviderFeeEstimate> _kMercadoPagoFees = {
  'brl': ProviderFeeEstimate(percent: 4.98),
};

/// Processing-fee estimate of [provider] for ONE charge of [amountMinor].
int estimateProviderFee(TicketProvider provider, int amountMinor, String currency) {
  if (amountMinor <= 0) return 0;
  final c = currency.toLowerCase();
  final ProviderFeeEstimate e;
  if (provider == TicketProvider.stripe) {
    e = _kStripeFees[c] ??
        ProviderFeeEstimate(percent: 2.9, fixedMinor: usdCentsToMinor(30, c) ?? 0);
  } else {
    e = _kMercadoPagoFees[c] ?? const ProviderFeeEstimate(percent: 4.99);
  }
  // toStringAsFixed: 10000 x 4.98 / 100 is 498.00000000000006 in binary floating point.
  return double.parse((amountMinor * e.percent / 100).toStringAsFixed(6)).ceil() + e.fixedMinor;
}

/// What the host gets for one ticket of [unitMinor]: the buyer pays the
/// price, GreenGo keeps [greenGoFee], the provider keeps [providerFee]
/// (estimate; null when no provider is chosen yet).
class HostPayoutEstimate {
  const HostPayoutEstimate({required this.price, required this.greenGoFee, this.providerFee});

  final int price;
  final int greenGoFee;
  final int? providerFee;

  int get net {
    final n = price - greenGoFee - (providerFee ?? 0);
    return n < 0 ? 0 : n;
  }
}

/// Per-ticket payout estimate; null when the currency has no rate.
HostPayoutEstimate? estimateHostPayout(
    TicketFeeRule rule, int unitMinor, String currency, TicketProvider? provider) {
  final fee = ticketFeePerTicket(rule, unitMinor, currency);
  if (fee == null) return null;
  return HostPayoutEstimate(
    price: unitMinor,
    greenGoFee: fee,
    providerFee: provider == null || provider == TicketProvider.link
        ? null
        : estimateProviderFee(provider, unitMinor, currency),
  );
}
