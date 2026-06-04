part of 'subscription_bloc.dart';

/// Subscription States
abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SubscriptionInitial extends SubscriptionState {}

/// Loading state
class SubscriptionLoading extends SubscriptionState {}

/// Subscription loaded
class SubscriptionLoaded extends SubscriptionState {

  const SubscriptionLoaded(this.subscription);
  final Subscription subscription;

  @override
  List<Object?> get props => [subscription];
}

/// No active subscription
class NoSubscription extends SubscriptionState {
  const NoSubscription();
}

/// Products loaded from store
class ProductsLoaded extends SubscriptionState {

  const ProductsLoaded(this.products);
  final List<ProductDetails> products;

  @override
  List<Object?> get props => [products];
}

/// Subscription purchased successfully
class SubscriptionPurchased extends SubscriptionState {

  const SubscriptionPurchased(this.tier, {this.endDate, this.coinsGranted = 0});
  final SubscriptionTier tier;
  final DateTime? endDate;
  final int coinsGranted;

  @override
  List<Object?> get props => [tier, endDate, coinsGranted];
}

/// Purchases restored
class PurchasesRestored extends SubscriptionState {

  const PurchasesRestored(this.count);
  final int count;

  @override
  List<Object?> get props => [count];
}

/// Error state
class SubscriptionError extends SubscriptionState {

  const SubscriptionError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
