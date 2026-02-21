import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription.dart';

/// Subscription Model
/// Data layer model with Firestore serialization for one-time membership purchases
class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.subscriptionId,
    required super.userId,
    required super.tier,
    required super.status,
    required super.startDate,
    super.endDate,
    super.durationDays,
    super.platform,
    super.purchaseToken,
    super.transactionId,
    super.orderId,
    required super.price,
    super.currency,
    required super.createdAt,
    super.updatedAt,
  });

  /// Create from Subscription entity
  factory SubscriptionModel.fromEntity(Subscription subscription) {
    return SubscriptionModel(
      subscriptionId: subscription.subscriptionId,
      userId: subscription.userId,
      tier: subscription.tier,
      status: subscription.status,
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      durationDays: subscription.durationDays,
      platform: subscription.platform,
      purchaseToken: subscription.purchaseToken,
      transactionId: subscription.transactionId,
      orderId: subscription.orderId,
      price: subscription.price,
      currency: subscription.currency,
      createdAt: subscription.createdAt,
      updatedAt: subscription.updatedAt,
    );
  }

  /// Create from Firestore document
  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SubscriptionModel(
      subscriptionId: doc.id,
      userId: data['userId'] as String,
      tier: SubscriptionTierExtension.fromString(data['tier'] as String? ?? 'basic'),
      status: SubscriptionStatusExtension.fromString(data['status'] as String? ?? 'expired'),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
      durationDays: data['durationDays'] as int? ?? 30,
      platform: data['platform'] as String?,
      purchaseToken: data['purchaseToken'] as String?,
      transactionId: data['transactionId'] as String?,
      orderId: data['orderId'] as String?,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'tier': tier.name,
      'status': status.value,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'durationDays': durationDays,
      'platform': platform,
      'purchaseToken': purchaseToken,
      'transactionId': transactionId,
      'orderId': orderId,
      'price': price,
      'currency': currency,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Convert to Subscription entity
  Subscription toEntity() {
    return Subscription(
      subscriptionId: subscriptionId,
      userId: userId,
      tier: tier,
      status: status,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      platform: platform,
      purchaseToken: purchaseToken,
      transactionId: transactionId,
      orderId: orderId,
      price: price,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
