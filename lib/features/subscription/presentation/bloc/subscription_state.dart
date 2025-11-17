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
  final Subscription subscription;

  const SubscriptionLoaded(this.subscription);

  @override
  List<Object?> get props => [subscription];
}

/// No active subscription
class NoSubscription extends SubscriptionState {
  const NoSubscription();
}

/// Products loaded from store
class ProductsLoaded extends SubscriptionState {
  final List<ProductDetails> products;

  const ProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

/// Subscription purchased successfully
class SubscriptionPurchased extends SubscriptionState {
  final SubscriptionTier tier;

  const SubscriptionPurchased(this.tier);

  @override
  List<Object?> get props => [tier];
}

/// Subscription cancelled
class SubscriptionCancelled extends SubscriptionState {
  const SubscriptionCancelled();
}

/// Purchases restored
class PurchasesRestored extends SubscriptionState {
  final int count;

  const PurchasesRestored(this.count);

  @override
  List<Object?> get props => [count];
}

/// Error state
class SubscriptionError extends SubscriptionState {
  final String message;

  const SubscriptionError(this.message);

  @override
  List<Object?> get props => [message];
}
