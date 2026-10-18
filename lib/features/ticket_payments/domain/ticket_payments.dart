import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Paid tickets for events and experiences (server: functions/src/ticket_payments).
///
/// Buyers pay inside the app through the organizer's connected
/// [TicketProvider.stripe] / [TicketProvider.mercadoPago] account; the provider
/// confirms automatically and the QR is released only then. The organizer
/// receives the full listed price; buyers pay a GreenGo service fee on top
/// (ticket_fees.dart).
///
/// [TicketProvider.link] (the organizer's own payment method, confirmed by
/// hand) is LEGACY: payment links are no longer accepted (owner rule
/// 2026-10-14). It is kept only to read orders / listings created before.
enum TicketProvider {
  link('link'),
  stripe('stripe'),
  mercadoPago('mercadopago');

  const TicketProvider(this.wire);
  final String wire;

  bool get isInstant => this != TicketProvider.link;

  static TicketProvider? fromWire(Object? v) {
    for (final p in values) {
      if (p.wire == v) return p;
    }
    return null;
  }
}

/// Legacy link-order methods that were not profile payment links (shown on
/// orders created before payment links were discontinued).
const String kTicketMethodCash = 'cash';
const String kTicketMethodBankTransfer = 'bankTransfer';

/// Kept for `app_config/ticket_payments.largeAudienceThreshold` (config).
const int kLargeAudienceThreshold = 30;

/// "Payments to confirm" (legacy orders) suggests connecting a provider from this many.
const int kPendingConfirmationsHint = 10;

bool suggestInstantForPending(int pendingCount) =>
    pendingCount >= kPendingConfirmationsHint;

/// The selection stored on a listing.
class TicketPaymentChoice extends Equatable {
  const TicketPaymentChoice({this.provider, this.linkMethod, this.instructions});

  final TicketProvider? provider;
  final String? linkMethod;
  final String? instructions;

  /// Complete enough to sell (the server re-checks everything): a connected
  /// provider. A legacy link choice is never complete.
  bool get isComplete => provider != null && provider != TicketProvider.link;

  TicketPaymentChoice copyWith({
    TicketProvider? provider,
    String? linkMethod,
    String? instructions,
  }) =>
      TicketPaymentChoice(
        provider: provider ?? this.provider,
        linkMethod: linkMethod ?? this.linkMethod,
        instructions: instructions ?? this.instructions,
      );

  @override
  List<Object?> get props => [provider, linkMethod, instructions];
}

/// Status of one provider in "Get paid".
enum PayoutStatus { notConnected, pending, ready, needsReconnect }

class PaymentAccounts extends Equatable {
  const PaymentAccounts({
    this.stripe = PayoutStatus.notConnected,
    this.mercadoPago = PayoutStatus.notConnected,
    this.mercadoPagoCurrency,
    this.stripeCountry,
  });

  final PayoutStatus stripe;
  final PayoutStatus mercadoPago;

  /// The only currency the organizer's MP account charges in (site currency).
  final String? mercadoPagoCurrency;
  final String? stripeCountry;

  static PayoutStatus _status(Object? raw) {
    if (raw is! Map) return PayoutStatus.notConnected;
    switch (raw['status']) {
      case 'ready':
        return PayoutStatus.ready;
      case 'needs_reconnect':
        return PayoutStatus.needsReconnect;
      default:
        return PayoutStatus.pending;
    }
  }

  factory PaymentAccounts.fromMap(Map<String, dynamic>? d) => PaymentAccounts(
        stripe: _status(d?['stripe']),
        mercadoPago: _status(d?['mercadoPago']),
        mercadoPagoCurrency: d?['mercadoPago'] is Map
            ? (d!['mercadoPago'] as Map)['currency'] as String?
            : null,
        stripeCountry:
            d?['stripe'] is Map ? (d!['stripe'] as Map)['country'] as String? : null,
      );

  PayoutStatus of(TicketProvider p) => switch (p) {
        TicketProvider.stripe => stripe,
        TicketProvider.mercadoPago => mercadoPago,
        TicketProvider.link => PayoutStatus.ready,
      };

  bool get anyReady =>
      stripe == PayoutStatus.ready || mercadoPago == PayoutStatus.ready;

  @override
  List<Object?> get props => [stripe, mercadoPago, mercadoPagoCurrency, stripeCountry];
}

// ─────────────────────────────────────────── currency + method rules (mirror the server)

const Set<String> _zeroDecimal = {
  'bif', 'clp', 'djf', 'gnf', 'jpy', 'kmf', 'krw', 'mga', 'pyg', 'rwf', 'ugx', 'vnd', 'vuv', 'xaf', 'xof', 'xpf',
};

int currencyExponent(String currency) => _zeroDecimal.contains(currency.toLowerCase()) ? 0 : 2;

/// Major units (49.9) -> integer minor units (4990); zero-decimal aware.
int toMinorUnits(double major, String currency) {
  final f = currencyExponent(currency) == 0 ? 1 : 100;
  return (double.parse((major * f).toStringAsFixed(6))).round();
}

/// Stripe minimum charge per currency (major units); MP 1.00 local.
const Map<String, double> kStripeMinimumMajor = {
  'usd': 0.5, 'aed': 2, 'aud': 0.5, 'bgn': 1, 'brl': 0.5, 'cad': 0.5, 'chf': 0.5, 'czk': 15,
  'dkk': 2.5, 'eur': 0.5, 'gbp': 0.3, 'hkd': 4, 'huf': 175, 'inr': 0.5, 'jpy': 50, 'mxn': 10,
  'myr': 2, 'nok': 3, 'nzd': 0.5, 'pln': 2, 'ron': 2, 'sek': 3, 'sgd': 0.5, 'thb': 10,
};

/// Minimum price (major units) for [p] in [currency]; null when none applies.
double? providerMinimum(TicketProvider p, String currency) => switch (p) {
      TicketProvider.stripe => kStripeMinimumMajor[currency.toLowerCase()],
      TicketProvider.mercadoPago => 1.0,
      TicketProvider.link => null,
    };

/// Why [p] cannot sell at [price] [currency] for this organizer (null = it can).
enum ProviderBlock { notConfigured, notConnected, currencyMismatch, belowMinimum }

ProviderBlock? providerBlock({
  required TicketProvider p,
  required TicketPaymentsConfig config,
  required PaymentAccounts accounts,
  required String? currency,
  required double? price,
}) {
  if (p == TicketProvider.link) return null;
  if (!config.enabled(p)) return ProviderBlock.notConfigured;
  if (accounts.of(p) != PayoutStatus.ready) return ProviderBlock.notConnected;
  final c = currency?.toLowerCase();
  if (p == TicketProvider.mercadoPago &&
      (c == null || accounts.mercadoPagoCurrency == null || accounts.mercadoPagoCurrency != c)) {
    return ProviderBlock.currencyMismatch;
  }
  final min = c == null ? null : providerMinimum(p, c);
  if (min != null && price != null && price > 0 && price < min) return ProviderBlock.belowMinimum;
  return null;
}

/// A listing still set to a (legacy) payment link needs a connected
/// Stripe / Mercado Pago account before it can sell again.
bool needsReconnect(TicketPaymentChoice c) => c.provider == TicketProvider.link;

/// Per-user limit stored on a listing: missing -> default 4, null/0 -> none.
const int kDefaultMaxTicketsPerUser = 4;

/// How many more tickets a buyer may take now (null = no limit).
int? remainingForBuyer({required int? limit, required int alreadyHeld, required int? remainingCapacity}) {
  final byLimit = limit == null ? null : (limit - alreadyHeld).clamp(0, 100);
  if (byLimit == null) return remainingCapacity?.clamp(0, 100);
  if (remainingCapacity == null) return byLimit;
  return byLimit < remainingCapacity ? byLimit : remainingCapacity.clamp(0, 100);
}

/// Server-provided switches (getTicketPaymentsConfig).
class TicketPaymentsConfig extends Equatable {
  const TicketPaymentsConfig({
    this.stripe = false,
    this.mercadoPago = false,
    this.holdMinutes = 30,
    this.linkHoldHours = 24,
    this.largeAudienceThreshold = kLargeAudienceThreshold,
  });

  final bool stripe;
  final bool mercadoPago;
  final int holdMinutes;
  final int linkHoldHours;
  final int largeAudienceThreshold;

  bool enabled(TicketProvider p) => switch (p) {
        TicketProvider.link => true,
        TicketProvider.stripe => stripe,
        TicketProvider.mercadoPago => mercadoPago,
      };

  @override
  List<Object?> get props =>
      [stripe, mercadoPago, holdMinutes, linkHoldHours, largeAudienceThreshold];
}

enum TicketOrderStatus {
  creating,
  pending,
  pendingPayment,
  awaitingConfirmation,
  paid,
  expired,
  cancelled,
  failed,
  rejected,
  refunded,
  disputed,
  unknown;

  static TicketOrderStatus fromWire(Object? v) => switch (v) {
        'creating' => creating,
        'pending' => pending,
        'pending_payment' => pendingPayment,
        'awaiting_confirmation' => awaitingConfirmation,
        'paid' => paid,
        'expired' => expired,
        'cancelled' => cancelled,
        'failed' => failed,
        'rejected' => rejected,
        'refunded' => refunded,
        'disputed' => disputed,
        _ => unknown,
      };

  bool get isOpen =>
      this == creating ||
      this == pending ||
      this == pendingPayment ||
      this == awaitingConfirmation;
}

DateTime? _date(Object? v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// `ticket_orders/{id}` as the buyer / organizer sees it.
class TicketOrder extends Equatable {
  const TicketOrder({
    required this.id,
    required this.kind,
    required this.listingId,
    required this.buyerId,
    required this.organizerId,
    required this.provider,
    required this.status,
    required this.totalAmount,
    required this.currency,
    this.ticketSubtotal,
    this.feeTotal = 0,
    this.feeRule,
    this.bookingId,
    this.quantity = 1,
    this.code,
    this.paymentMethod,
    this.paymentValue,
    this.paymentInstructions,
    this.checkoutUrl,
    this.expiresAt,
    this.sentAt,
    this.receiptPath,
    this.rejectReason,
    this.title,
    this.startsAt,
    this.createdAt,
    this.phaseLines = const [],
  });

  final String id;
  final String kind;
  final String listingId;
  final String? bookingId;
  final String buyerId;
  final String organizerId;
  final TicketProvider provider;
  final TicketOrderStatus status;
  /// What the buyer pays (tickets + GreenGo service fee).
  final int totalAmount;
  final String currency;

  /// Ticket prices only (what the organizer receives); null on older orders
  /// (= [totalAmount], no fee).
  final int? ticketSubtotal;

  /// GreenGo service fee of the whole order (0 on older / link orders).
  final int feeTotal;
  final String? feeRule;
  final int quantity;
  final String? code;
  final String? paymentMethod;
  final String? paymentValue;
  final String? paymentInstructions;
  final String? checkoutUrl;
  final DateTime? expiresAt;
  final DateTime? sentAt;
  final String? receiptPath;
  final String? rejectReason;
  final String? title;
  final DateTime? startsAt;
  final DateTime? createdAt;

  /// Price phases of the order (each ticket at its phase): one line per phase.
  final List<({String nameKey, int unitAmount, int quantity})> phaseLines;

  bool get isLink => provider == TicketProvider.link;

  factory TicketOrder.fromMap(String id, Map<String, dynamic> d) {
    final pay = d['payment'] is Map ? Map<String, dynamic>.from(d['payment'] as Map) : const <String, dynamic>{};
    return TicketOrder(
      id: id,
      kind: d['kind'] as String? ?? 'event',
      listingId: d['listingId'] as String? ?? '',
      bookingId: d['bookingId'] as String?,
      buyerId: d['buyerId'] as String? ?? '',
      organizerId: d['organizerId'] as String? ?? '',
      provider: TicketProvider.fromWire(d['provider']) ?? TicketProvider.link,
      status: TicketOrderStatus.fromWire(d['status']),
      totalAmount: (d['totalAmount'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String? ?? 'usd').toLowerCase(),
      ticketSubtotal: (d['ticketSubtotal'] as num?)?.toInt(),
      feeTotal: (d['feeTotal'] as num?)?.toInt() ?? 0,
      feeRule: d['feeRuleApplied'] as String?,
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
      code: d['code'] as String?,
      paymentMethod: pay['method'] as String?,
      paymentValue: pay['value'] as String?,
      paymentInstructions: pay['instructions'] as String?,
      checkoutUrl: d['checkoutUrl'] as String?,
      expiresAt: _date(d['expiresAt']),
      sentAt: _date(d['sentAt']),
      receiptPath: d['receiptPath'] as String?,
      rejectReason: d['rejectReason'] as String?,
      title: d['title'] as String?,
      startsAt: _date(d['startsAt']),
      createdAt: _date(d['createdAt']),
      phaseLines: [
        if (d['phaseLines'] is List)
          for (final x in d['phaseLines'] as List)
            if (x is Map && x['nameKey'] is String && x['unitAmount'] is num && x['quantity'] is num)
              (
                nameKey: x['nameKey'] as String,
                unitAmount: (x['unitAmount'] as num).toInt(),
                quantity: (x['quantity'] as num).toInt(),
              ),
      ],
    );
  }

  @override
  List<Object?> get props => [id, status, checkoutUrl, expiresAt, sentAt, receiptPath, rejectReason];
}

/// Formats minor units ("2500", "brl") for display.
String formatTicketAmount(int minor, String currency, {String? locale}) {
  const zeroDecimal = {'jpy', 'krw', 'clp', 'vnd', 'pyg', 'ugx', 'xaf', 'xof'};
  final digits = zeroDecimal.contains(currency.toLowerCase()) ? 0 : 2;
  final major = digits == 0 ? minor.toDouble() : minor / 100;
  try {
    return NumberFormat.simpleCurrency(
            locale: locale, name: currency.toUpperCase(), decimalDigits: digits)
        .format(major);
  } catch (_) {
    return '${currency.toUpperCase()} ${major.toStringAsFixed(digits)}';
  }
}

/// Display symbol -> ISO code for listings (events store a symbol).
String? isoCurrencyFor(String? symbolOrCode) {
  if (symbolOrCode == null) return null;
  final v = symbolOrCode.trim().toLowerCase();
  if (RegExp(r'^[a-z]{3}$').hasMatch(v)) return v;
  const map = {'\$': 'usd', 'us\$': 'usd', '€': 'eur', '£': 'gbp', 'r\$': 'brl', '¥': 'jpy'};
  return map[v];
}

/// `events/{id}/ticket_types/{typeId}` (sold / held are server-owned).
class TicketType extends Equatable {
  const TicketType({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.quantity,
    this.sold = 0,
    this.held = 0,
    this.salesStart,
    this.salesEnd,
    this.maxPerUser,
    this.hidden = false,
    this.active = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? description;

  /// Minor units (0 = free type).
  final int price;
  final int? quantity;
  final int sold;
  final int held;
  final DateTime? salesStart;
  final DateTime? salesEnd;
  final int? maxPerUser;
  final bool hidden;
  final bool active;
  final int sortOrder;

  int? get left => quantity == null ? null : (quantity! - sold - held).clamp(0, quantity!);

  factory TicketType.fromMap(String id, Map<String, dynamic> d) => TicketType(
        id: id,
        name: d['name'] as String? ?? '',
        description: d['description'] as String?,
        price: (d['price'] as num?)?.toInt() ?? 0,
        quantity: (d['quantity'] as num?)?.toInt(),
        sold: (d['sold'] as num?)?.toInt() ?? 0,
        held: (d['held'] as num?)?.toInt() ?? 0,
        salesStart: _date(d['salesStart']),
        salesEnd: _date(d['salesEnd']),
        maxPerUser: (d['maxPerUser'] as num?)?.toInt(),
        hidden: d['hidden'] == true,
        active: d['active'] != false,
        sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'quantity': quantity,
        'salesStart': salesStart == null ? null : Timestamp.fromDate(salesStart!),
        'salesEnd': salesEnd == null ? null : Timestamp.fromDate(salesEnd!),
        'maxPerUser': maxPerUser,
        'hidden': hidden,
        'active': active,
        'sortOrder': sortOrder,
      };

  @override
  List<Object?> get props => [id, name, description, price, quantity, sold, held, salesStart, salesEnd, maxPerUser, hidden, active, sortOrder];
}

enum TicketTypeState { onSale, soldOut, notStarted, ended, unavailable }

TicketTypeState ticketTypeState(TicketType t, DateTime now) {
  if (!t.active || t.hidden) return TicketTypeState.unavailable;
  if (t.salesStart != null && now.isBefore(t.salesStart!)) return TicketTypeState.notStarted;
  if (t.salesEnd != null && now.isAfter(t.salesEnd!)) return TicketTypeState.ended;
  if (t.left == 0) return TicketTypeState.soldOut;
  return TicketTypeState.onSale;
}

/// An issued ticket (`tickets/{id}`, buyer-only).
class IssuedTicket extends Equatable {
  const IssuedTicket({
    required this.id,
    required this.orderId,
    required this.kind,
    required this.listingId,
    required this.status,
    required this.qrPayload,
    this.title,
    this.typeName,
    this.partySize = 1,
    this.index = 1,
    this.of = 1,
    this.startsAt,
    this.checkedIn = false,
    this.attendeeName,
  });

  final String id;
  final String orderId;
  final String kind;
  final String listingId;
  final String status;
  final String qrPayload;
  final String? title;
  final String? typeName;
  final int partySize;
  final int index;
  final int of;
  final DateTime? startsAt;
  final bool checkedIn;

  /// "Ask for attendee names": the holder of this ticket ("First Last").
  final String? attendeeName;

  bool get isValid => status == 'valid';

  factory IssuedTicket.fromMap(String id, Map<String, dynamic> d) => IssuedTicket(
        id: id,
        orderId: d['orderId'] as String? ?? '',
        kind: d['kind'] as String? ?? 'event',
        listingId: d['listingId'] as String? ?? '',
        status: d['status'] as String? ?? 'valid',
        qrPayload: d['qrPayload'] as String? ?? '',
        title: d['title'] as String?,
        typeName: d['ticketTypeName'] as String?,
        partySize: (d['partySize'] as num?)?.toInt() ?? 1,
        index: (d['index'] as num?)?.toInt() ?? 1,
        of: (d['of'] as num?)?.toInt() ?? 1,
        startsAt: _date(d['startsAt']),
        checkedIn: d['checkedInAt'] != null,
        attendeeName: (d['attendeeName'] as String?)?.trim().isEmpty ?? true
            ? null
            : (d['attendeeName'] as String).trim(),
      );

  @override
  List<Object?> get props => [id, status, qrPayload, checkedIn];
}
