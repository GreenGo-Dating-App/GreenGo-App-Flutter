part of 'subscription_bloc.dart';

/// Subscription Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load current subscription
class LoadCurrentSubscription extends SubscriptionEvent {
  final String userId;

  const LoadCurrentSubscription(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load available products from store
class LoadAvailableProducts extends SubscriptionEvent {
  const LoadAvailableProducts();
}

/// Purchase subscription
class PurchaseSubscription extends SubscriptionEvent {
  final ProductDetails product;
  final SubscriptionTier tier;

  const PurchaseSubscription({
    required this.product,
    required this.tier,
  });

  @override
  List<Object?> get props => [product, tier];
}

/// Restore purchases
class RestorePurchasesEvent extends SubscriptionEvent {
  final String userId;

  const RestorePurchasesEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Internal event for purchase stream updates
class _PurchaseUpdated extends SubscriptionEvent {
  final List<PurchaseDetails> purchases;

  const _PurchaseUpdated(this.purchases);

  @override
  List<Object?> get props => [purchases];
}
