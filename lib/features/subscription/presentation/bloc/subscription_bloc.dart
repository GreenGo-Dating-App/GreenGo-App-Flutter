import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/usecases/get_current_subscription.dart';
import '../../domain/usecases/purchase_subscription.dart' as domain;
import '../../domain/usecases/cancel_subscription.dart';
import '../../domain/usecases/restore_purchases.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// Subscription BLoC
/// Manages subscription state and in-app purchases
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetCurrentSubscription getCurrentSubscription;
  final domain.PurchaseSubscription purchaseSubscription;
  final CancelSubscription cancelSubscription;
  final RestorePurchases restorePurchases;
  final InAppPurchase inAppPurchase;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  SubscriptionBloc({
    required this.getCurrentSubscription,
    required this.purchaseSubscription,
    required this.cancelSubscription,
    required this.restorePurchases,
    required this.inAppPurchase,
  }) : super(SubscriptionInitial()) {
    on<LoadCurrentSubscription>(_onLoadCurrentSubscription);
    on<LoadAvailableProducts>(_onLoadAvailableProducts);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<RestorePurchasesEvent>(_onRestorePurchases);
    on<_PurchaseUpdated>(_onPurchaseUpdated);

    // Listen to purchase stream
    _purchaseSubscription = inAppPurchase.purchaseStream.listen(
      (purchases) {
        add(_PurchaseUpdated(purchases));
      },
    );
  }

  Future<void> _onLoadCurrentSubscription(
    LoadCurrentSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    final result = await getCurrentSubscription(event.userId);

    result.fold(
      (failure) => emit(SubscriptionError(failure.toString())),
      (subscription) {
        if (subscription == null) {
          emit(const NoSubscription());
        } else {
          emit(SubscriptionLoaded(subscription));
        }
      },
    );
  }

  Future<void> _onLoadAvailableProducts(
    LoadAvailableProducts event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    try {
      final available = await inAppPurchase.isAvailable();
      if (!available) {
        emit(const SubscriptionError('Store not available'));
        return;
      }

      const productIds = {
        'silver_premium_monthly',
        'gold_premium_monthly',
      };

      final response = await inAppPurchase.queryProductDetails(productIds);

      if (response.error != null) {
        emit(SubscriptionError(response.error!.message));
        return;
      }

      if (response.productDetails.isEmpty) {
        emit(const SubscriptionError('No products available'));
        return;
      }

      emit(ProductsLoaded(response.productDetails));
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    try {
      final purchaseParam = PurchaseParam(
        productDetails: event.product,
      );

      final success = await inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        emit(const SubscriptionError('Purchase failed to initiate'));
      }
      // Wait for purchase stream to update
    } catch (e) {
      emit(SubscriptionError(e.toString()));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    final result = await cancelSubscription(
      subscriptionId: event.subscriptionId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(SubscriptionError(failure.toString())),
      (_) => emit(const SubscriptionCancelled()),
    );
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    final result = await restorePurchases(event.userId);

    result.fold(
      (failure) => emit(SubscriptionError(failure.toString())),
      (purchases) => emit(PurchasesRestored(purchases.length)),
    );
  }

  Future<void> _onPurchaseUpdated(
    _PurchaseUpdated event,
    Emitter<SubscriptionState> emit,
  ) async {
    for (final purchase in event.purchases) {
      if (purchase.status == PurchaseStatus.purchased) {
        // Purchase successful - verify it
        // In production, call your verification use case
        final tier = _getTierFromProductId(purchase.productID);
        emit(SubscriptionPurchased(tier));

        // Complete the purchase
        if (purchase.pendingCompletePurchase) {
          await inAppPurchase.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        emit(SubscriptionError(purchase.error?.message ?? 'Purchase failed'));
      } else if (purchase.status == PurchaseStatus.canceled) {
        emit(const SubscriptionError('Purchase cancelled'));
      }
    }
  }

  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('silver')) return SubscriptionTier.silver;
    if (productId.contains('gold')) return SubscriptionTier.gold;
    return SubscriptionTier.basic;
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
