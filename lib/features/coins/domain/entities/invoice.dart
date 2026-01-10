import 'package:equatable/equatable.dart';
import 'order.dart';

/// Invoice Entity
/// Generated for each completed order for record keeping
class Invoice extends Equatable {
  final String invoiceId;
  final String invoiceNumber; // Human-readable INV-YYYYMMDD-XXXX
  final String orderId;
  final String userId;
  final String? userEmail;
  final String? userName;
  final InvoiceStatus status;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final List<InvoiceLineItem> lineItems;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final String currency;
  final PaymentMethod paymentMethod;
  final String? notes;
  final BillingAddress? billingAddress;

  const Invoice({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.orderId,
    required this.userId,
    this.userEmail,
    this.userName,
    required this.status,
    required this.issueDate,
    this.dueDate,
    this.paidDate,
    required this.lineItems,
    required this.subtotal,
    this.taxRate = 0.0,
    required this.taxAmount,
    required this.total,
    this.currency = 'USD',
    required this.paymentMethod,
    this.notes,
    this.billingAddress,
  });

  /// Get display total
  String get displayTotal {
    if (currency == 'USD') {
      return '\$${total.toStringAsFixed(2)}';
    }
    return '$currency ${total.toStringAsFixed(2)}';
  }

  /// Check if invoice is paid
  bool get isPaid => status == InvoiceStatus.paid;

  @override
  List<Object?> get props => [
        invoiceId,
        invoiceNumber,
        orderId,
        userId,
        userEmail,
        userName,
        status,
        issueDate,
        dueDate,
        paidDate,
        lineItems,
        subtotal,
        taxRate,
        taxAmount,
        total,
        currency,
        paymentMethod,
        notes,
        billingAddress,
      ];
}

/// Invoice Line Item
class InvoiceLineItem extends Equatable {
  final String itemId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const InvoiceLineItem({
    required this.itemId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  /// Get display price
  String displayTotalPrice(String currency) {
    if (currency == 'USD') {
      return '\$${totalPrice.toStringAsFixed(2)}';
    }
    return '$currency ${totalPrice.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        itemId,
        description,
        quantity,
        unitPrice,
        totalPrice,
      ];
}

/// Invoice Status
enum InvoiceStatus {
  draft,
  issued,
  paid,
  overdue,
  cancelled,
  refunded,
}

extension InvoiceStatusExtension on InvoiceStatus {
  String get displayName {
    switch (this) {
      case InvoiceStatus.draft:
        return 'Draft';
      case InvoiceStatus.issued:
        return 'Issued';
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.overdue:
        return 'Overdue';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
      case InvoiceStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Billing Address
class BillingAddress extends Equatable {
  final String? name;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const BillingAddress({
    this.name,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  /// Get formatted address
  String get formattedAddress {
    final parts = <String>[];
    if (name != null) parts.add(name!);
    if (addressLine1 != null) parts.add(addressLine1!);
    if (addressLine2 != null) parts.add(addressLine2!);
    if (city != null || state != null || postalCode != null) {
      final cityState = [city, state, postalCode]
          .where((e) => e != null)
          .join(', ');
      parts.add(cityState);
    }
    if (country != null) parts.add(country!);
    return parts.join('\n');
  }

  @override
  List<Object?> get props => [
        name,
        addressLine1,
        addressLine2,
        city,
        state,
        postalCode,
        country,
      ];
}
