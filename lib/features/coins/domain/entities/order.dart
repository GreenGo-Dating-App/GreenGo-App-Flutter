import 'package:equatable/equatable.dart';

/// Order Entity
/// Represents a purchase order for coins or video coins
class CoinOrder extends Equatable {
  final String orderId;
  final String userId;
  final OrderType type;
  final OrderStatus status;
  final String packageId;
  final int itemQuantity;
  final double subtotal;
  final double tax;
  final double total;
  final String currency;
  final PaymentMethod paymentMethod;
  final String? paymentIntentId;
  final String? transactionId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? refundedAt;
  final String? refundReason;
  final Map<String, dynamic>? metadata;

  const CoinOrder({
    required this.orderId,
    required this.userId,
    required this.type,
    required this.status,
    required this.packageId,
    required this.itemQuantity,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.currency = 'USD',
    required this.paymentMethod,
    this.paymentIntentId,
    this.transactionId,
    required this.createdAt,
    this.completedAt,
    this.refundedAt,
    this.refundReason,
    this.metadata,
  });

  /// Get display total
  String get displayTotal {
    if (currency == 'USD') {
      return '\$${total.toStringAsFixed(2)}';
    }
    return '$currency ${total.toStringAsFixed(2)}';
  }

  /// Check if order is completed
  bool get isCompleted => status == OrderStatus.completed;

  /// Check if order is refundable
  bool get isRefundable {
    if (status != OrderStatus.completed) return false;
    if (refundedAt != null) return false;
    // Orders are refundable within 24 hours
    final refundDeadline = completedAt?.add(const Duration(hours: 24));
    return refundDeadline != null && DateTime.now().isBefore(refundDeadline);
  }

  @override
  List<Object?> get props => [
        orderId,
        userId,
        type,
        status,
        packageId,
        itemQuantity,
        subtotal,
        tax,
        total,
        currency,
        paymentMethod,
        paymentIntentId,
        transactionId,
        createdAt,
        completedAt,
        refundedAt,
        refundReason,
        metadata,
      ];
}

/// Order Type
enum OrderType {
  coins,       // Regular GreenGoCoins
  videoCoins,  // Video call minutes
  subscription, // Subscription purchase
  gift,        // Gift purchase
}

extension OrderTypeExtension on OrderType {
  String get displayName {
    switch (this) {
      case OrderType.coins:
        return 'Coins Purchase';
      case OrderType.videoCoins:
        return 'Video Minutes';
      case OrderType.subscription:
        return 'Subscription';
      case OrderType.gift:
        return 'Gift Purchase';
    }
  }
}

/// Order Status
enum OrderStatus {
  pending,    // Order created, awaiting payment
  processing, // Payment processing
  completed,  // Payment successful, items delivered
  failed,     // Payment failed
  cancelled,  // Order cancelled
  refunded,   // Order refunded
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.failed:
        return 'Failed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  bool get isTerminal {
    return this == OrderStatus.completed ||
        this == OrderStatus.failed ||
        this == OrderStatus.cancelled ||
        this == OrderStatus.refunded;
  }
}

/// Payment Method
enum PaymentMethod {
  googlePlay,
  appStore,
  stripe,
  paypal,
  creditCard,
  promotional, // Free from promotion
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.googlePlay:
        return 'Google Play';
      case PaymentMethod.appStore:
        return 'App Store';
      case PaymentMethod.stripe:
        return 'Stripe';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.promotional:
        return 'Promotional';
    }
  }
}
