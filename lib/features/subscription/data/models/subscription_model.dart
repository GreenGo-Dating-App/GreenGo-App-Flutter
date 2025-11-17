import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/subscription.dart';

/// Subscription Model
/// Data layer model with Firestore serialization
class SubscriptionModel extends Subscription {
  const SubscriptionModel({
    required super.subscriptionId,
    required super.userId,
    required super.tier,
    required super.status,
    required super.startDate,
    super.endDate,
    super.nextBillingDate,
    super.autoRenew,
    super.cancellationReason,
    super.cancelledAt,
    super.platform,
    super.purchaseToken,
    super.transactionId,
    super.orderId,
    super.inGracePeriod,
    super.gracePeriodEndDate,
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
      nextBillingDate: subscription.nextBillingDate,
      autoRenew: subscription.autoRenew,
      cancellationReason: subscription.cancellationReason,
      cancelledAt: subscription.cancelledAt,
      platform: subscription.platform,
      purchaseToken: subscription.purchaseToken,
      transactionId: subscription.transactionId,
      orderId: subscription.orderId,
      inGracePeriod: subscription.inGracePeriod,
      gracePeriodEndDate: subscription.gracePeriodEndDate,
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
      nextBillingDate: data['nextBillingDate'] != null
          ? (data['nextBillingDate'] as Timestamp).toDate()
          : null,
      autoRenew: data['autoRenew'] as bool? ?? true,
      cancellationReason: data['cancellationReason'] as String?,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      platform: data['platform'] as String?,
      purchaseToken: data['purchaseToken'] as String?,
      transactionId: data['transactionId'] as String?,
      orderId: data['orderId'] as String?,
      inGracePeriod: data['inGracePeriod'] as bool? ?? false,
      gracePeriodEndDate: data['gracePeriodEndDate'] != null
          ? (data['gracePeriodEndDate'] as Timestamp).toDate()
          : null,
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
      'nextBillingDate':
          nextBillingDate != null ? Timestamp.fromDate(nextBillingDate!) : null,
      'autoRenew': autoRenew,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'platform': platform,
      'purchaseToken': purchaseToken,
      'transactionId': transactionId,
      'orderId': orderId,
      'inGracePeriod': inGracePeriod,
      'gracePeriodEndDate':
          gracePeriodEndDate != null ? Timestamp.fromDate(gracePeriodEndDate!) : null,
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
      nextBillingDate: nextBillingDate,
      autoRenew: autoRenew,
      cancellationReason: cancellationReason,
      cancelledAt: cancelledAt,
      platform: platform,
      purchaseToken: purchaseToken,
      transactionId: transactionId,
      orderId: orderId,
      inGracePeriod: inGracePeriod,
      gracePeriodEndDate: gracePeriodEndDate,
      price: price,
      currency: currency,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
