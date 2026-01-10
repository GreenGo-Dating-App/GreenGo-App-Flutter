import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/invoice.dart';
import '../../domain/entities/order.dart';

/// Invoice Model for Firestore
class InvoiceModel extends Invoice {
  const InvoiceModel({
    required super.invoiceId,
    required super.invoiceNumber,
    required super.orderId,
    required super.userId,
    super.userEmail,
    super.userName,
    required super.status,
    required super.issueDate,
    super.dueDate,
    super.paidDate,
    required super.lineItems,
    required super.subtotal,
    super.taxRate = 0.0,
    required super.taxAmount,
    required super.total,
    super.currency = 'USD',
    required super.paymentMethod,
    super.notes,
    super.billingAddress,
  });

  /// Create from Firestore document
  factory InvoiceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    List<InvoiceLineItem> lineItems = [];
    if (data['lineItems'] != null) {
      lineItems = (data['lineItems'] as List).map((item) {
        return InvoiceLineItem(
          itemId: item['itemId'] as String,
          description: item['description'] as String,
          quantity: (item['quantity'] as num).toInt(),
          unitPrice: (item['unitPrice'] as num).toDouble(),
          totalPrice: (item['totalPrice'] as num).toDouble(),
        );
      }).toList();
    }

    BillingAddress? billingAddress;
    if (data['billingAddress'] != null) {
      final addr = data['billingAddress'] as Map<String, dynamic>;
      billingAddress = BillingAddress(
        name: addr['name'] as String?,
        addressLine1: addr['addressLine1'] as String?,
        addressLine2: addr['addressLine2'] as String?,
        city: addr['city'] as String?,
        state: addr['state'] as String?,
        postalCode: addr['postalCode'] as String?,
        country: addr['country'] as String?,
      );
    }

    return InvoiceModel(
      invoiceId: doc.id,
      invoiceNumber: data['invoiceNumber'] as String,
      orderId: data['orderId'] as String,
      userId: data['userId'] as String,
      userEmail: data['userEmail'] as String?,
      userName: data['userName'] as String?,
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      issueDate: (data['issueDate'] as Timestamp).toDate(),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      paidDate: data['paidDate'] != null
          ? (data['paidDate'] as Timestamp).toDate()
          : null,
      lineItems: lineItems,
      subtotal: (data['subtotal'] as num).toDouble(),
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (data['taxAmount'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == data['paymentMethod'],
        orElse: () => PaymentMethod.googlePlay,
      ),
      notes: data['notes'] as String?,
      billingAddress: billingAddress,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'invoiceNumber': invoiceNumber,
      'orderId': orderId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'status': status.name,
      'issueDate': Timestamp.fromDate(issueDate),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'paidDate': paidDate != null ? Timestamp.fromDate(paidDate!) : null,
      'lineItems': lineItems
          .map((item) => {
                'itemId': item.itemId,
                'description': item.description,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
                'totalPrice': item.totalPrice,
              })
          .toList(),
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'total': total,
      'currency': currency,
      'paymentMethod': paymentMethod.name,
      'notes': notes,
      'billingAddress': billingAddress != null
          ? {
              'name': billingAddress!.name,
              'addressLine1': billingAddress!.addressLine1,
              'addressLine2': billingAddress!.addressLine2,
              'city': billingAddress!.city,
              'state': billingAddress!.state,
              'postalCode': billingAddress!.postalCode,
              'country': billingAddress!.country,
            }
          : null,
    };
  }

  /// Generate invoice number
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomPart = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    return 'INV-$dateStr-$randomPart';
  }
}
