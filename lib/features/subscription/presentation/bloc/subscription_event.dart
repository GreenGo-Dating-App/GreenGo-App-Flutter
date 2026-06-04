part of 'subscription_bloc.dart';

/// Subscription Events
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Load current subscription
class LoadCurrentSubscription extends SubscriptionEvent {

  const LoadCurrentSubscription(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load available products from store
class LoadAvailableProducts extends SubscriptionEvent {
  const LoadAvailableProducts();
}

/// Purchase subscription
class PurchaseSubscription extends SubscriptionEvent {

  const PurchaseSubscription({
    required this.product,
    required this.tier,
  });
  final ProductDetails product;
  final SubscriptionTier tier;

  @override
  List<Object?> get props => [product, tier];
}

/// Restore purchases
class RestorePurchasesEvent extends SubscriptionEvent {

  const RestorePurchasesEvent(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Internal event for purchase stream updates
class _PurchaseUpdated extends SubscriptionEvent {

  const _PurchaseUpdated(this.purchases);
  final List<PurchaseDetails> purchases;

  @override
  List<Object?> get props => [purchases];
}
