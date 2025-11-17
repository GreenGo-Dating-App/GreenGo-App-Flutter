import 'package:equatable/equatable.dart';
import 'subscription.dart';

/// Purchase Type
enum PurchaseType {
  subscription,  // Recurring subscription
  oneTime,       // One-time purchase (boosts, super likes, etc.)
}

/// Purchase Status
enum PurchaseStatus {
  pending,    // Purchase initiated
  completed,  // Purchase successful
  failed,     // Purchase failed
  refunded,   // Purchase was refunded
  cancelled,  // User cancelled purchase
}

/// Purchase Entity
/// Represents a single purchase transaction
class Purchase extends Equatable {
  final String purchaseId;
  final String userId;
  final PurchaseType type;
  final PurchaseStatus status;

  // Product information
  final String productId;
  final String productName;
  final SubscriptionTier? tier; // Only for subscription purchases

  // Pricing
  final double price;
  final String currency;

  // Platform information
  final String platform; // 'android', 'ios', 'web'
  final String? purchaseToken;
  final String? transactionId;
  final String? orderId;
  final String? receipt;

  // Dates
  final DateTime purchaseDate;
  final DateTime? verifiedAt;
  final DateTime? refundedAt;

  // Metadata
  final Map<String, dynamic>? metadata;

  const Purchase({
    required this.purchaseId,
    required this.userId,
    required this.type,
    required this.status,
    required this.productId,
    required this.productName,
    this.tier,
    required this.price,
    this.currency = 'USD',
    required this.platform,
    this.purchaseToken,
    this.transactionId,
    this.orderId,
    this.receipt,
    required this.purchaseDate,
    this.verifiedAt,
    this.refundedAt,
    this.metadata,
  });

  bool get isVerified => verifiedAt != null;
  bool get isRefunded => status == PurchaseStatus.refunded;
  bool get isCompleted => status == PurchaseStatus.completed;

  Purchase copyWith({
    String? purchaseId,
    String? userId,
    PurchaseType? type,
    PurchaseStatus? status,
    String? productId,
    String? productName,
    SubscriptionTier? tier,
    double? price,
    String? currency,
    String? platform,
    String? purchaseToken,
    String? transactionId,
    String? orderId,
    String? receipt,
    DateTime? purchaseDate,
    DateTime? verifiedAt,
    DateTime? refundedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Purchase(
      purchaseId: purchaseId ?? this.purchaseId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      tier: tier ?? this.tier,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      platform: platform ?? this.platform,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      transactionId: transactionId ?? this.transactionId,
      orderId: orderId ?? this.orderId,
      receipt: receipt ?? this.receipt,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      refundedAt: refundedAt ?? this.refundedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        purchaseId,
        userId,
        type,
        status,
        productId,
        productName,
        tier,
        price,
        currency,
        platform,
        purchaseToken,
        transactionId,
        orderId,
        receipt,
        purchaseDate,
        verifiedAt,
        refundedAt,
        metadata,
      ];
}
