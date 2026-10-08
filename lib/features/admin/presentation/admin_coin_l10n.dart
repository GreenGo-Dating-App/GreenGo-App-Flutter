import '../../../generated/app_localizations.dart';
import '../../coins/domain/entities/invoice.dart';
import '../../coins/domain/entities/order.dart';

/// Localized labels for coin order/invoice enums shown in admin screens
/// (the domain `displayName` getters stay English for logs).
String adminOrderStatusLabel(AppLocalizations l10n, OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return l10n.adminPending;
    case OrderStatus.processing:
      return l10n.adminStatusProcessing;
    case OrderStatus.completed:
      return l10n.adminStatusCompleted;
    case OrderStatus.failed:
      return l10n.adminStatusFailed;
    case OrderStatus.cancelled:
      return l10n.adminStatusCancelled;
    case OrderStatus.refunded:
      return l10n.adminStatusRefunded;
  }
}

String adminInvoiceStatusLabel(AppLocalizations l10n, InvoiceStatus status) {
  switch (status) {
    case InvoiceStatus.draft:
      return l10n.adminStatusDraft;
    case InvoiceStatus.issued:
      return l10n.adminStatusIssued;
    case InvoiceStatus.paid:
      return l10n.adminStatusPaid;
    case InvoiceStatus.overdue:
      return l10n.adminStatusOverdue;
    case InvoiceStatus.cancelled:
      return l10n.adminStatusCancelled;
    case InvoiceStatus.refunded:
      return l10n.adminStatusRefunded;
  }
}

String adminOrderTypeLabel(AppLocalizations l10n, OrderType type) {
  switch (type) {
    case OrderType.coins:
      return l10n.adminOrderTypeCoins;
    case OrderType.subscription:
      return l10n.adminOrderTypeSubscription;
    case OrderType.gift:
      return l10n.adminOrderTypeGift;
  }
}
