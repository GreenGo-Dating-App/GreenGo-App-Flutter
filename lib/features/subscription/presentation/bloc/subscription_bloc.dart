import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/usecases/get_current_subscription.dart';
import '../../domain/usecases/purchase_subscription.dart' as domain;
import '../../domain/usecases/restore_purchases.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

/// Subscription BLoC
/// Manages subscription state and in-app purchases
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetCurrentSubscription getCurrentSubscription;
  final domain.PurchaseSubscription purchaseSubscription;
  final RestorePurchases restorePurchases;
  final InAppPurchase inAppPurchase;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  String? _currentUserId;

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

    // Listen to purchase stream
    _purchaseSubscription = inAppPurchase.purchaseStream.listen(
      (purchases) {
        add(_PurchaseUpdated(purchases));
      },
      onError: (error) {
        debugPrint('IAP stream error: $error');
      },
    );

    // Restore old purchases on init to consume any unconsumed ones
    _consumeOldPurchases();
  }

  /// Restore and consume any old unconsumed purchases to clear "already owned" state
  Future<void> _consumeOldPurchases() async {
    if (!Platform.isAndroid) return;
    try {
      await inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('[SubscriptionBloc] restorePurchases error (non-critical): $e');
    }
  }

  /// Complete and consume a purchase
  Future<void> _completeAndConsumePurchase(PurchaseDetails p) async {
    if (p.pendingCompletePurchase) {
      await inAppPurchase.completePurchase(p);
    }
    if (Platform.isAndroid) {
      try {
        final androidAddition = inAppPurchase
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
        await androidAddition.consumePurchase(p);
        debugPrint('[SubscriptionBloc] Consumed purchase ${p.productID}');
      } catch (e) {
        debugPrint('[SubscriptionBloc] Consume failed (non-critical): $e');
      }
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

            const productIds = {
        'greengo_base_membership',
        '1_month_silver',
        '1_month_gold',
        '1_month_platinum',
        '1_year_silver',
        '1_year_gold',
        '1_year_platinum_membership',
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

  static const _tierRanks = {
    'BASIC': 0,
    'SILVER': 1,
    'GOLD': 2,
    'PLATINUM': 3,
  };

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
      if (_currentUserId != null && event.product.id != 'greengo_base_membership') {
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(_currentUserId)
              .get();
          final currentTier = profileDoc.data()?['membershipTier'] as String?;
          final endDate = profileDoc.data()?['membershipEndDate'] as Timestamp?;
          final isActive = endDate != null && endDate.toDate().isAfter(DateTime.now());

          if (isActive && currentTier != null) {
            final currentRank = _tierRanks[currentTier.toUpperCase()] ?? 0;
            final purchaseRank = _tierRankFromProductId(event.product.id);
            if (purchaseRank < currentRank) {
              emit(SubscriptionError(
                'You already have a $currentTier membership. You cannot buy a lower tier while it is active.',
              ));
              return;
            }
          }
        } catch (e) {
          debugPrint('Error checking current tier: $e');
        }
      }

      // All products are managed (in-app) products — use buyConsumable
      final purchaseParam = PurchaseParam(
        productDetails: event.product,
        applicationUserName: _currentUserId,
      );
      final bool success = await inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: false,
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
        // Purchase successful - verify it
        final tier = _getTierFromProductId(purchase.productID);
        final tierName = tier.name.toUpperCase();
        final userId = _currentUserId;
        DateTime newEndDate = DateTime.now().add(const Duration(days: 30));
        int coinsGranted = 0;

        // Update the user's profile membershipTier in Firestore
        try {
          if (userId != null) {
            // Get membership details to calculate end date
            final details = _getMembershipDetailsFromProductId(purchase.productID);
            final duration = details['duration'] as Duration;

            // Get current membership to extend it
            final profileDoc = await FirebaseFirestore.instance
                .collection('profiles')
                .doc(userId)
                .get();

            final currentEndDate = profileDoc.data()?['membershipEndDate'] as Timestamp?;
            final currentTier = profileDoc.data()?['membershipTier'] as String?;

            if (currentEndDate != null && currentTier != null) {
              final currentEndDateTime = currentEndDate.toDate();
              final now = DateTime.now();

              // If membership is still active, extend from current end date
              // If expired, start from now
              if (currentEndDateTime.isAfter(now)) {
                newEndDate = currentEndDateTime.add(duration);
              } else {
                newEndDate = now.add(duration);
              }
            } else {
              // No current membership, start from now
              newEndDate = DateTime.now().add(duration);
            }

            await FirebaseFirestore.instance
                .collection('profiles')
                .doc(userId)
                .update({
                  'membershipTier': tierName,
                  'membershipEndDate': Timestamp.fromDate(newEndDate),
                });
            await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .update({
                  'membershipTier': tierName,
                  'membershipEndDate': Timestamp.fromDate(newEndDate),
                });
          }
          debugPrint('Membership purchased: $tierName, ends: $newEndDate');
        } catch (e) {
          debugPrint('Error updating profile tier: $e');
        }

        // Grant 500 coins for base membership (write to coinBatches array field, not subcollection)
        if (purchase.productID == 'greengo_base_membership' && userId != null) {
          try {
            final now = DateTime.now();
            final balanceRef = FirebaseFirestore.instance
                .collection('coinBalances')
                .doc(userId!);
            final batchEntry = {
              'batchId': 'membership_${now.millisecondsSinceEpoch}',
              'initialCoins': 500,
              'remainingCoins': 500,
              'source': 'reward',
              'acquiredDate': Timestamp.fromDate(now),
              'expirationDate': Timestamp.fromDate(newEndDate),
            };
            final balanceDoc = await balanceRef.get();
            if (balanceDoc.exists) {
              await balanceRef.update({
                'totalCoins': FieldValue.increment(500),
                'earnedCoins': FieldValue.increment(500),
                'lastUpdated': Timestamp.fromDate(now),
                'coinBatches': FieldValue.arrayUnion([batchEntry]),
              });
            } else {
              await balanceRef.set({
                'userId': userId,
                'totalCoins': 500,
                'earnedCoins': 500,
                'purchasedCoins': 0,
                'giftedCoins': 0,
                'spentCoins': 0,
                'lastUpdated': Timestamp.fromDate(now),
                'coinBatches': [batchEntry],
              });
            }
            coinsGranted = 500;
          } catch (e) {
            debugPrint('Error granting base membership coins: $e');
          }
        }

        // Track purchase ownership by app userId
        try {
          final token = purchase.purchaseID ?? '';
          if (token.isNotEmpty && userId != null) {
            await FirebaseFirestore.instance
                .collection('membership_purchases')
                .doc(token)
                .set({
              'userId': userId,
              'productId': purchase.productID,
              'purchaseId': token,
              'tier': tierName,
              'purchasedAt': Timestamp.fromDate(DateTime.now()),
              'endDate': Timestamp.fromDate(newEndDate),
            });
          }
        } catch (e) {
          debugPrint('[SubscriptionBloc] Failed to track purchase: $e');
        }

        emit(SubscriptionPurchased(tier, endDate: newEndDate, coinsGranted: coinsGranted));

        // Complete and consume the purchase so it can be bought again
        await _completeAndConsumePurchase(purchase);
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

  Map<String, dynamic> _getMembershipDetailsFromProductId(String productId) {
    SubscriptionTier tier;
    Duration duration;
    
    // Determine tier
    if (productId.contains('platinum')) {
      tier = SubscriptionTier.platinum;
    } else if (productId.contains('gold')) {
      tier = SubscriptionTier.gold;
    } else if (productId.contains('silver')) {
      tier = SubscriptionTier.silver;
    } else if (productId.contains('base')) {
      tier = SubscriptionTier.basic;
    } else {
      tier = SubscriptionTier.basic;
    }
    
    // Determine duration
    if (productId.contains('1_year') || productId.contains('year')) {
      duration = const Duration(days: 365); // 1 year
    } else if (productId.contains('1_month') || productId.contains('month')) {
      duration = const Duration(days: 30); // 1 month
    } else {
      // Default to 1 month for base membership
      duration = const Duration(days: 30);
    }
    
    return {
      'tier': tier,
      'duration': duration,
      'isYearly': duration.inDays >= 365,
    };
  }

  @override
  Future<void> close() {
    _purchaseSubscription?.cancel();
    return super.close();
  }
}
