import '../../../generated/app_localizations.dart';
import '../data/ticket_payments_service.dart';
import '../domain/price_phases.dart';
import '../domain/ticket_payments.dart';

/// Localized texts for ticket payments (reason codes, statuses, methods).
class TicketL10n {
  const TicketL10n._();

  static String provider(AppLocalizations l, TicketProvider p) => switch (p) {
        TicketProvider.link => l.tpManualTitle,
        TicketProvider.stripe => 'Stripe',
        TicketProvider.mercadoPago => 'Mercado Pago',
      };

  /// Brand names of the (legacy) link-order methods; not translated.
  static const Map<String, String> _methodBrands = {
    'pix': 'Pix', 'picPay': 'PicPay', 'paypal': 'PayPal', 'venmo': 'Venmo', 'cashApp': 'Cash App',
    'revolut': 'Revolut', 'wise': 'Wise', 'monzo': 'Monzo', 'kofi': 'Ko-fi',
  };

  /// Payment method of a LEGACY link order (orders opened before payment
  /// links were discontinued).
  static String method(AppLocalizations l, String key) {
    if (key == kTicketMethodCash) return l.tpMethodCash;
    if (key == kTicketMethodBankTransfer) return l.tpMethodBankTransfer;
    return _methodBrands[key] ?? key;
  }

  /// Preset price-phase name.
  static String phaseName(AppLocalizations l, PricePhaseName n) => switch (n) {
        PricePhaseName.superEarlyBird => l.ppNameSuperEarlyBird,
        PricePhaseName.earlyBird => l.ppNameEarlyBird,
        PricePhaseName.presale => l.ppNamePresale,
        PricePhaseName.regular => l.ppNameRegular,
        PricePhaseName.late => l.ppNameLate,
        PricePhaseName.lastMinute => l.ppNameLastMinute,
        PricePhaseName.door => l.ppNameDoor,
      };

  /// Stored phase key (orders, tickets) -> localized name (the key if unknown).
  static String phaseNameKey(AppLocalizations l, String key) {
    final n = PricePhaseName.fromWire(key);
    return n == null ? key : phaseName(l, n);
  }

  /// Editor validation message of a price-phase setup.
  static String phaseError(AppLocalizations l, PricePhaseError e) => switch (e) {
        PricePhaseError.notIncreasing => l.ppErrNotIncreasing,
        PricePhaseError.overCapacity => l.ppErrOverCapacity,
        PricePhaseError.priceRange => l.eventsPriceRange,
        PricePhaseError.quantity => l.ppErrQuantity,
        PricePhaseError.belowSold => l.ppErrBelowSold,
        PricePhaseError.soldPhaseRemoved || PricePhaseError.soldPriceChanged => l.ppErrSoldLocked,
        PricePhaseError.insertedBeforeSold => l.ppErrInsertedBeforeSold,
        PricePhaseError.duplicateName || PricePhaseError.tooMany => l.ppErrDuplicateName,
      };

  static String payoutStatus(AppLocalizations l, PayoutStatus s) => switch (s) {
        PayoutStatus.notConnected => l.tpStatusNotConnected,
        PayoutStatus.pending => l.tpStatusPending,
        PayoutStatus.ready => l.tpStatusReady,
        PayoutStatus.needsReconnect => l.tpStatusReconnect,
      };

  static String orderStatus(AppLocalizations l, TicketOrderStatus s) => switch (s) {
        TicketOrderStatus.creating || TicketOrderStatus.pending => l.tpOrderWaitingProvider,
        TicketOrderStatus.pendingPayment => l.tpOrderPendingPayment,
        TicketOrderStatus.awaitingConfirmation => l.tpOrderAwaitingConfirmation,
        TicketOrderStatus.paid => l.tpOrderPaid,
        TicketOrderStatus.expired => l.tpOrderExpired,
        TicketOrderStatus.cancelled => l.tpOrderCancelled,
        TicketOrderStatus.failed => l.tpOrderFailed,
        TicketOrderStatus.rejected => l.tpOrderRejected,
        TicketOrderStatus.refunded => l.tpOrderRefunded,
        TicketOrderStatus.disputed => l.tpOrderDisputed,
        TicketOrderStatus.unknown => l.tpOrderWaitingProvider,
      };

  static String block(AppLocalizations l, ProviderBlock b, TicketProvider p,
      {String? accountCurrency, String? currency}) {
    switch (b) {
      case ProviderBlock.notConfigured:
        return l.tpBlockNotConfigured;
      case ProviderBlock.notConnected:
        return l.tpBlockNotConnected(provider(l, p));
      case ProviderBlock.currencyMismatch:
        return accountCurrency == null
            ? l.tpBlockMpCurrencyUnknown
            : l.tpBlockMpCurrency(accountCurrency.toUpperCase());
      case ProviderBlock.belowMinimum:
        final min = providerMinimum(p, currency ?? 'usd') ?? 0;
        return l.tpBlockMinimum(provider(l, p),
            formatTicketAmount(toMinorUnits(min, currency ?? 'usd'), currency ?? 'usd'));
    }
  }

  /// A server refusal (`details.code`) as a sentence.
  static String error(AppLocalizations l, Object e) {
    final reason = e is TicketPaymentException ? e.reason : 'internal';
    if (reason == 'price_changed' && e is TicketPaymentException) {
      final total = e.details['total'];
      final currency = e.details['currency'];
      if (total is num && currency is String) {
        return l.tpErrPriceChanged(formatTicketAmount(total.toInt(), currency));
      }
    }
    return switch (reason) {
      'price_phases_invalid' => l.tpErrPricePhasesInvalid,
      'payments_not_configured' => l.tpBlockNotConfigured,
      'organizer_payments_not_ready' => l.tpErrNotOnSale,
      'seller_billing_missing' => l.tpErrNotOnSale,
      'seller_not_business' => l.tpErrSellerNotBusiness,
      'link_payments_discontinued' => l.tpErrLinkDiscontinued,
      'fee_currency_unsupported' => l.tpErrFeeCurrency,
      'sold_out' || 'ticket_type_sold_out' => l.tpErrSoldOut,
      'ticket_limit_reached' || 'ticket_type_limit_reached' => l.tpErrLimit,
      'ticket_type_sales_not_started' => l.tpTypeNotStarted,
      'ticket_type_sales_ended' || 'listing_ended' => l.tpErrEnded,
      'currency_not_supported' => l.tpBlockMpCurrencyUnknown,
      'amount_below_minimum' => l.tpErrMinimum,
      'own_listing' => l.tpErrOwnListing,
      'already_has_ticket' => l.tpErrAlreadyHasTicket,
      'not_organizer' || 'permission-denied' => l.tpErrNotAllowed,
      'provider_unavailable' || 'unavailable' => l.tpErrProvider,
      _ => l.tpErrGeneric,
    };
  }
}
