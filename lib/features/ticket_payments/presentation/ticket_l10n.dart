import '../../../generated/app_localizations.dart';
import '../../profile/domain/entities/payment_links.dart' as pl;
import '../data/ticket_payments_service.dart';
import '../domain/ticket_payments.dart';

/// Localized texts for ticket payments (reason codes, statuses, methods).
class TicketL10n {
  const TicketL10n._();

  static String provider(AppLocalizations l, TicketProvider p) => switch (p) {
        TicketProvider.link => l.tpManualTitle,
        TicketProvider.stripe => 'Stripe',
        TicketProvider.mercadoPago => 'Mercado Pago',
      };

  static String method(AppLocalizations l, String key) {
    if (key == kTicketMethodCash) return l.tpMethodCash;
    if (key == kTicketMethodBankTransfer) return l.tpMethodBankTransfer;
    return pl.PaymentMethod.fromKey(key)?.label ?? key;
  }

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
    return switch (reason) {
      'payments_not_configured' => l.tpBlockNotConfigured,
      'organizer_payments_not_ready' => l.tpErrNotOnSale,
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
