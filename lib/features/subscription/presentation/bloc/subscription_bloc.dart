import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/constants/product_catalog.dart';
import '../../../../core/services/effective_tier.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/usecases/get_current_subscription.dart';
import '../../domain/usecases/purchase_subscription.dart' as domain;
import '../../domain/usecases/restore_purchases.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// Subscription BLoC
/// Manages subscription state and in-app purchases
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {

  SubscriptionBloc({
    required this.getCurrentSubscription,
    required this.purchaseSubscription,
    required this.restorePurchases,
    required this.inAppPurchase,
  }) : super(SubscriptionInitial()) {
    on<LoadCurrentSubscription>(_onLoadCurrentSubscription);
    on<LoadAvailableProducts>(_onLoadAvailableProducts);
    on<PurchaseSubscription>(_onPurchaseSubscription);
    on<RestorePurchasesEvent>(_onRestorePurchases);
    on<_PurchaseUpdated>(_onPurchaseUpdated);

    // Listen to purchase stream.
    //
    // in_app_purchase has no web implementation: reading purchaseStream there
    // throws LateInitializationError from the constructor, which took down
    // every screen that builds this bloc. Web buys through Stripe Checkout
    // instead, so there is no IAP stream to listen to. _consumeOldPurchases()
    // below already guarded for this; the stream did not.
    if (!kIsWeb) {
      _purchaseSubscription = inAppPurchase.purchaseStream.listen(
        (purchases) {
          add(_PurchaseUpdated(purchases));
        },
        onError: (error) {
          debugPrint('IAP stream error: $error');
        },
      );
    }

    // Restore old purchases on init to consume any unconsumed ones
    _consumeOldPurchases();
  }
  final GetCurrentSubscription getCurrentSubscription;
  final domain.PurchaseSubscription purchaseSubscription;
  final RestorePurchases restorePurchases;
  final InAppPurchase inAppPurchase;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String? _currentUserId;

  /// Restore and consume any old unconsumed purchases to clear "already owned" state
  Future<void> _consumeOldPurchases() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('[SubscriptionBloc] restorePurchases error (non-critical): $e');
    }
  }

  /// Acknowledge a subscription purchase. Subscriptions are never consumed —
  /// consuming a sub triggers a Google auto-refund; `completePurchase`
  /// acknowledges it.
  Future<void> _completeAndConsumePurchase(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await inAppPurchase.completePurchase(p);
    }
  }

  Future<void> _onLoadCurrentSubscription(
    LoadCurrentSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    _currentUserId = event.userId;

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

      // Per-platform store IDs (App Store and Google Play use different IDs);
      // ProductCatalog is the single source of truth for the mapping.
      final productIds = ProductCatalog.allStoreIds();

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

  int _tierRankFromProductId(String productId) {
    if (productId.contains('platinum')) return 3;
    if (productId.contains('gold')) return 2;
    if (productId.contains('silver')) return 1;
    return 0;
  }

  Future<void> _onPurchaseSubscription(
    PurchaseSubscription event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());

    try {
      // Block purchasing a lower tier than the user's current active membership
      if (_currentUserId != null && !event.product.id.endsWith('greengo_base_membership')) {
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(_currentUserId)
              .get();
          // EFFECTIVE tier: an expired paid tier (or 'BASIC' = Base/free)
          // never blocks a purchase — every tier is buyable again.
          final current = effectiveTierFromDoc(profileDoc.data());
          if (current != MembershipTier.free && current != MembershipTier.test) {
            final currentRank = current.priority;
            final purchaseRank = _tierRankFromProductId(event.product.id);
            if (purchaseRank < currentRank) {
              emit(SubscriptionError(
                'You already have a ${current.value} membership. You cannot buy a lower tier while it is active.',
              ));
              return;
            }
          }
        } catch (e) {
          debugPrint('Error checking current tier: $e');
        }
      }

      // Memberships are auto-renewable subscriptions (App Store) / subscriptions
      // (Google Play). The in_app_purchase plugin purchases both subscriptions
      // and non-consumables via buyNonConsumable — NOT buyConsumable (which is
      // only for consumable coin packs). Using buyConsumable on a subscription
      // causes the store to treat it incorrectly and breaks renewal/restore.
      final purchaseParam = PurchaseParam(
        productDetails: event.product,
        applicationUserName: _currentUserId,
      );
      final success = await inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        emit(const SubscriptionError('Purchase failed to initiate'));
      }
      // Wait for purchase stream to update
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('ALREADY_OWNED') ||
          errorStr.contains('ITEM_ALREADY_OWNED') ||
          errorStr.contains('itemAlreadyOwned')) {
        debugPrint('[SubscriptionBloc] Product already owned — consuming old purchases');
        await _consumeOldPurchases();
        await Future.delayed(const Duration(seconds: 2));
        emit(const SubscriptionError('Previous purchase found. Please try again.'));
      } else {
        emit(SubscriptionError(e.toString()));
      }
    }
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
        // Only membership products belong to this bloc; coin packs are
        // verified by their own flows (coin shop / PurchaseRecoveryService).
        final canonicalId = ProductCatalog.canonicalId(purchase.productID);
        if (!ProductCatalog.canonicalIds.contains(canonicalId)) continue;

        final userId = _currentUserId;
        if (userId == null) continue; // PurchaseRecoveryService picks it up.

        // The SERVER validates the receipt and writes the entitlement
        // (profiles/{uid} tier + end date, Base flag, welcome coins). Direct
        // client writes of those fields are refused by the rules.
        final Map<String, dynamic> res;
        try {
          res = await _verifyPurchaseOnServer(userId, purchase);
        } catch (e) {
          debugPrint('[SubscriptionBloc] verifyPurchase failed: $e');
          // Leave the purchase unfinished so PurchaseRecoveryService retries
          // it on the next launch instead of losing it.
          emit(SubscriptionError(e.toString()));
          continue;
        }

        if (res['expired'] == true) {
          // A lapsed subscription's receipt: nothing was granted, so this is
          // NOT an active membership — no success UI, no local tier change.
          debugPrint('[SubscriptionBloc] ${purchase.productID} is expired — no grant');
          await _completeAndConsumePurchase(purchase);
          emit(const NoSubscription());
          continue;
        }

        final isBase = canonicalId == ProductCatalog.baseMembership;
        final serverTier = res['tier'] as String?;
        final tier = isBase
            ? SubscriptionTier.basic
            : (serverTier != null
                ? SubscriptionTierExtension.fromString(serverTier)
                : _getTierFromProductId(purchase.productID));
        final endIso = (isBase ? res['baseMembershipEndDate'] : null) as String? ??
            res['endDate'] as String?;
        final endDate = endIso != null ? DateTime.tryParse(endIso) : null;
        final coinsGranted = (res['coinsGranted'] as num?)?.toInt() ?? 0;

        await _completeAndConsumePurchase(purchase);
        emit(SubscriptionPurchased(tier, endDate: endDate, coinsGranted: coinsGranted));
      } else if (purchase.status == PurchaseStatus.restored) {
        // Always consume restored purchases to clear "already owned" state
        await _completeAndConsumePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.error) {
        emit(SubscriptionError(purchase.error?.message ?? 'Purchase failed'));
        // Always consume to clear "already owned" state
        await _completeAndConsumePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.canceled) {
        emit(const SubscriptionError('Purchase cancelled'));
        // Always consume to clear "already owned" state
        await _completeAndConsumePurchase(purchase);
      }
    }
  }

    SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('platinum')) return SubscriptionTier.platinum;
    if (productId.contains('gold')) return SubscriptionTier.gold;
    if (productId.contains('silver')) return SubscriptionTier.silver;
    if (productId.contains('base')) return SubscriptionTier.basic;
    return SubscriptionTier.basic;
  }

  /// Calls the `verifyPurchase` callable — same payload as
  /// PurchaseRecoveryService / the coin shop.
  Future<Map<String, dynamic>> _verifyPurchaseOnServer(
      String userId, PurchaseDetails p) async {
    final receipt = p.verificationData.serverVerificationData;
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final result = await FirebaseFunctions.instance
        .httpsCallable('verifyPurchase')
        .call<Object?>(<String, dynamic>{
      'userId': userId,
      'platform': isIOS ? 'ios' : 'android',
      'productId': p.productID,
      'purchaseToken': isIOS ? (p.purchaseID ?? receipt) : receipt,
      'verificationData': receipt,
    });
    final data = result.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
