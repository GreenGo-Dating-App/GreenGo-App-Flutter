import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/order.dart';

/// Coin Order Model for Firestore
class CoinOrderModel extends CoinOrder {
  const CoinOrderModel({
    required super.orderId,
    required super.userId,
    required super.type,
    required super.status,
    required super.packageId,
    required super.itemQuantity,
    required super.subtotal,
    required super.tax,
    required super.total,
    super.currency = 'USD',
    required super.paymentMethod,
    super.paymentIntentId,
    super.transactionId,
    required super.createdAt,
    super.completedAt,
    super.refundedAt,
    super.refundReason,
    super.metadata,
  });

  /// Create from Firestore document
  factory CoinOrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoinOrderModel(
      orderId: doc.id,
      userId: data['userId'] as String,
      type: OrderType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => OrderType.coins,
      ),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      packageId: data['packageId'] as String,
      itemQuantity: (data['itemQuantity'] as num).toInt(),
      subtotal: (data['subtotal'] as num).toDouble(),
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num).toDouble(),
      currency: data['currency'] as String? ?? 'USD',
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == data['paymentMethod'],
        orElse: () => PaymentMethod.googlePlay,
      ),
      paymentIntentId: data['paymentIntentId'] as String?,
      transactionId: data['transactionId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      refundedAt: data['refundedAt'] != null
          ? (data['refundedAt'] as Timestamp).toDate()
          : null,
      refundReason: data['refundReason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'packageId': packageId,
      'itemQuantity': itemQuantity,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'currency': currency,
      'paymentMethod': paymentMethod.name,
      'paymentIntentId': paymentIntentId,
      'transactionId': transactionId,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'refundReason': refundReason,
      'metadata': metadata,
    };
  }

  /// Copy with new values
  CoinOrderModel copyWith({
    String? orderId,
    String? userId,
    OrderType? type,
    OrderStatus? status,
    String? packageId,
    int? itemQuantity,
    double? subtotal,
    double? tax,
    double? total,
    String? currency,
    PaymentMethod? paymentMethod,
    String? paymentIntentId,
    String? transactionId,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? refundedAt,
    String? refundReason,
    Map<String, dynamic>? metadata,
  }) {
    return CoinOrderModel(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      packageId: packageId ?? this.packageId,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      transactionId: transactionId ?? this.transactionId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      refundReason: refundReason ?? this.refundReason,
      metadata: metadata ?? this.metadata,
    );
  }
}
