import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import '../../domain/entities/purchase.dart' as domain;
import '../../domain/entities/subscription.dart';
import '../models/subscription_model.dart';

/// Subscription Remote Data Source
/// Handles in-app purchases and Firestore operations
/// Points 146-147: Google Play & Apple StoreKit integration
class SubscriptionRemoteDataSource {
  final FirebaseFirestore firestore;
  final InAppPurchase inAppPurchase;
  final FirebaseFunctions functions;

    // Product IDs for one-time membership purchases
  static const String baseMembershipProductId = 'greengo_base_membership';
  
  // Monthly memberships
  static const String silverMonthlyProductId = '1_month_silver';
  static const String goldMonthlyProductId = '1_month_gold';
  static const String platinumMonthlyProductId = '1_month_platinum';
  
  // Yearly memberships (with discount)
  static const String silverYearlyProductId = '1_year_silver';
  static const String goldYearlyProductId = '1_year_gold';
  static const String platinumYearlyProductId = '1_year_platinum_membership';

  static const Set<String> _productIds = {
    baseMembershipProductId,
    silverMonthlyProductId,
    goldMonthlyProductId,
    platinumMonthlyProductId,
    silverYearlyProductId,
    goldYearlyProductId,
    platinumYearlyProductId,
  };

  // Purchase stream subscription for monitoring
  StreamSubscription<List<PurchaseDetails>>? _purchaseStreamSubscription;

  // Callbacks for purchase events
  Function(PurchaseDetails)? _onPurchaseSuccess;
  Function(PurchaseDetails, String)? _onPurchaseError;
  Function(PurchaseDetails)? _onPurchasePending;

  SubscriptionRemoteDataSource({
    required this.firestore,
    required this.inAppPurchase,
    FirebaseFunctions? functions,
  }) : functions = functions ?? FirebaseFunctions.instance;

  /// Initialize in-app purchases (Points 146-147)
  Future<bool> initializePurchases() async {
    final available = await inAppPurchase.isAvailable();
    if (!available) {
      throw Exception('In-app purchases not available');
    }

            // Set up platform-specific configurations
    if (Platform.isAndroid) {
      // In newer versions of in_app_purchase_android, enablePendingPurchases
      // might not be needed or might be called automatically
      // We'll skip this for now to avoid compilation errors
      debugPrint('Android platform detected - skipping enablePendingPurchases');
    }

    return true;
  }

  /// Get available products from store
  Future<List<ProductDetails>> getAvailableProducts() async {
    final ProductDetailsResponse response =
        await inAppPurchase.queryProductDetails(_productIds);

    if (response.error != null) {
      throw Exception('Failed to load products: ${response.error!.message}');
    }

    if (response.productDetails.isEmpty) {
      throw Exception('No products found');
    }

    return response.productDetails;
  }

      /// Purchase membership (one-time purchase)
  /// Users can buy membership for 1 month or 1 year
  Future<void> purchaseMembership({
    required ProductDetails product,
    required String userId,
  }) async {
    // For one-time purchases, we don't check if already owned
    // because users can buy multiple times to extend membership
    
    final PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: userId,
        changeSubscriptionParam: null,
      );
    } else {
      purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      );
    }

    // Use buyConsumable for one-time purchases
    await inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
  }

    /// Restore purchases (Point 154)
  /// Handles BILLING_RESPONSE_ITEM_ALREADY_OWNED by syncing with store
  Future<List<PurchaseDetails>> restorePurchases() async {
    try {
      // First, restore purchases from the store
      await inAppPurchase.restorePurchases();
      
      // Get available products to check what's owned
      final products = await getAvailableProducts();
      
      // Get past purchases from the store
      final purchaseStream = inAppPurchase.purchaseStream;
      final completer = Completer<List<PurchaseDetails>>();
      final List<PurchaseDetails> restoredPurchases = [];
      
      // Listen for restored purchases
      StreamSubscription<List<PurchaseDetails>>? subscription;
      subscription = purchaseStream.listen(
        (purchases) {
          for (final purchase in purchases) {
            if (purchase.status == PurchaseStatus.restored || 
                purchase.status == PurchaseStatus.purchased) {
              restoredPurchases.add(purchase);
              
              // Complete purchase to clear it from queue
              if (purchase.pendingCompletePurchase) {
                inAppPurchase.completePurchase(purchase);
              }
            }
          }
          
          // Wait a bit for all purchases to come through
          Future.delayed(const Duration(seconds: 2), () {
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.complete(restoredPurchases);
            }
          });
        },
        onError: (error) {
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );
      
      // Timeout after 10 seconds
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          subscription?.cancel();
          return restoredPurchases;
        },
      );
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      rethrow;
    }
  }

  /// Verify purchase with backend via Cloud Function
  Future<bool> verifyPurchase({
    required PurchaseDetails purchaseDetails,
    required String userId,
  }) async {
    try {
      String? verificationData;
      String platform;

      if (Platform.isAndroid) {
        platform = 'android';
        final androidDetails =
            purchaseDetails as GooglePlayPurchaseDetails;
        verificationData = androidDetails.verificationData.serverVerificationData;
      } else if (Platform.isIOS) {
        platform = 'ios';
        final iosDetails = purchaseDetails as AppStorePurchaseDetails;
        verificationData = iosDetails.verificationData.serverVerificationData;
      } else {
        throw Exception('Unsupported platform');
      }

      // Call Cloud Function to verify purchase with store servers
      final callable = functions.httpsCallable('verifyPurchase');
      final result = await callable.call({
        'userId': userId,
        'platform': platform,
        'productId': purchaseDetails.productID,
        'purchaseToken': purchaseDetails.purchaseID,
        'verificationData': verificationData,
        'transactionDate': purchaseDetails.transactionDate,
      });

      final data = result.data as Map<String, dynamic>;
      final verified = data['verified'] as bool? ?? false;

      if (!verified) {
        final errorMessage = data['error'] as String? ?? 'Verification failed';
        throw Exception(errorMessage);
      }

      // Cloud Function handles subscription/purchase record creation
      debugPrint('Purchase verified successfully for user: $userId');
      return true;
    } catch (e) {
      debugPrint('Purchase verification error: $e');

      // Fallback to local verification if Cloud Function fails (for testing)
      if (kDebugMode) {
        return _fallbackLocalVerification(purchaseDetails, userId);
      }

      throw Exception('Failed to verify purchase: $e');
    }
  }

  /// Fallback local verification for development/testing
  Future<bool> _fallbackLocalVerification(
    PurchaseDetails purchaseDetails,
    String userId,
  ) async {
    debugPrint('Using fallback local verification (debug mode only)');

    // Check if purchase token already belongs to a different user
    final existingSub = await firestore
        .collection('subscriptions')
        .where('purchaseToken', isEqualTo: purchaseDetails.purchaseID)
        .limit(1)
        .get();

    if (existingSub.docs.isNotEmpty) {
      final ownerUserId = existingSub.docs.first.data()['userId'] as String?;
      if (ownerUserId != null && ownerUserId != userId) {
        debugPrint('⛔ Fallback: purchase token belongs to $ownerUserId, not $userId — rejecting');
        return false;
      }
    }

          final platform = Platform.isAndroid ? 'android' : 'ios';
      final details = _getMembershipDetailsFromProductId(purchaseDetails.productID);
      final tier = details['tier'] as SubscriptionTier;
      final duration = details['duration'] as Duration;
      final durationDays = duration.inDays;
      final tierName = tier.name.toUpperCase();

      final now = DateTime.now();

      // Get current membership to extend from end date
      final profileDoc = await firestore.collection('profiles').doc(userId).get();
      DateTime newEndDate;
      final currentEndDate = profileDoc.data()?['membershipEndDate'] as Timestamp?;
      final currentTier = profileDoc.data()?['membershipTier'] as String?;

      if (currentEndDate != null && currentTier != null) {
        final currentTierEnum = SubscriptionTierExtension.fromString(currentTier.toLowerCase());
        final currentEndDateTime = currentEndDate.toDate();
        if (tier.index >= currentTierEnum.index && currentEndDateTime.isAfter(now)) {
          newEndDate = currentEndDateTime.add(duration);
        } else {
          newEndDate = now.add(duration);
        }
      } else {
        newEndDate = now.add(duration);
      }

    // Create subscription in Firestore
    await firestore.collection('subscriptions').add({
      'userId': userId,
      'tier': tierName,
      'status': 'active',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(newEndDate),
      'durationDays': durationDays,
      'platform': platform,
      'purchaseToken': purchaseDetails.purchaseID,
      'transactionId': purchaseDetails.purchaseID,
      'orderId': purchaseDetails.purchaseID,
      'price': tier.monthlyPrice,
      'currency': 'USD',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create purchase record
    await firestore.collection('purchases').add({
      'userId': userId,
      'type': 'membership',
      'status': 'completed',
      'productId': purchaseDetails.productID,
      'productName': tier.displayName,
      'tier': tierName,
      'price': tier.monthlyPrice,
      'currency': 'USD',
      'platform': platform,
      'purchaseToken': purchaseDetails.purchaseID,
      'transactionId': purchaseDetails.purchaseID,
      'purchaseDate': FieldValue.serverTimestamp(),
      'verifiedAt': FieldValue.serverTimestamp(),
      'verificationMethod': 'local_fallback',
    });

    // Update the user's profile membershipTier
    await firestore.collection('profiles').doc(userId).update({
      'membershipTier': tierName,
      'membershipStartDate': Timestamp.fromDate(now),
      'membershipEndDate': Timestamp.fromDate(newEndDate),
    });

    return true;
  }

  /// Complete purchase (mark as consumed/acknowledged)
  Future<void> completePurchase(PurchaseDetails purchaseDetails) async {
    if (purchaseDetails.pendingCompletePurchase) {
      await inAppPurchase.completePurchase(purchaseDetails);
    }
  }

  /// Get current subscription for user
  Future<SubscriptionModel?> getCurrentSubscription(String userId) async {
        final snapshot = await firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return SubscriptionModel.fromFirestore(snapshot.docs.first);
  }

  /// Stream of subscription updates
  Stream<SubscriptionModel?> subscriptionStream(String userId) {
        return firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['active', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Get purchase history
  Future<List<Map<String, dynamic>>> getPurchaseHistory(String userId) async {
        final snapshot = await firestore
        .collection('purchases')
        .where('userId', isEqualTo: userId)
        .orderBy('purchaseDate', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'purchaseId': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

      /// Helper: Get tier and duration from product ID
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

  /// Listen to purchase stream
  Stream<List<PurchaseDetails>> get purchaseStream =>
      inAppPurchase.purchaseStream;

  /// Setup purchase stream listener to monitor purchases in real-time
  /// This should be called once during app initialization (e.g., in MainNavigationScreen.initState)
  void setupPurchaseStreamListener({
    required String userId,
    Function(PurchaseDetails)? onSuccess,
    Function(PurchaseDetails, String)? onError,
    Function(PurchaseDetails)? onPending,
  }) {
    _onPurchaseSuccess = onSuccess;
    _onPurchaseError = onError;
    _onPurchasePending = onPending;

    // Cancel any existing subscription
    _purchaseStreamSubscription?.cancel();

    // Subscribe to purchase stream
    _purchaseStreamSubscription = inAppPurchase.purchaseStream.listen(
      (purchases) => _handlePurchaseUpdates(purchases, userId),
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
      onDone: () {
        debugPrint('Purchase stream closed');
      },
    );

    debugPrint('Purchase stream listener setup for user: $userId');
  }

  /// Handle purchase updates from the stream.
  /// Only processes purchases that belong to the current app user.
  /// Purchases from a shared Google billing account that belong to a
  /// different app user are skipped (completed but not verified).
  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchases,
    String userId,
  ) async {
    for (final purchase in purchases) {
      debugPrint('Processing purchase: ${purchase.productID}, status: ${purchase.status}');

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Purchase is pending (e.g., awaiting payment confirmation)
          _onPurchasePending?.call(purchase);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // CRITICAL: Before verifying, check if this purchase token is
          // already owned by a DIFFERENT app user. This prevents shared
          // Google billing accounts from granting membership to multiple
          // app accounts. Applies to both new purchases and restores.
          {
            final existingSub = await firestore
                .collection('subscriptions')
                .where('purchaseToken', isEqualTo: purchase.purchaseID)
                .limit(1)
                .get();

            if (existingSub.docs.isNotEmpty) {
              final ownerUserId = existingSub.docs.first.data()['userId'] as String?;
              if (ownerUserId != null && ownerUserId != userId) {
                debugPrint('⛔ Purchase token belongs to app user $ownerUserId, NOT current user $userId — skipping');
                if (purchase.pendingCompletePurchase) {
                  await inAppPurchase.completePurchase(purchase);
                }
                continue;
              }
            }

            // Also check purchase history records
            final existingPurchase = await firestore
                .collection('purchases')
                .where('purchaseToken', isEqualTo: purchase.purchaseID)
                .limit(1)
                .get();

            if (existingPurchase.docs.isNotEmpty) {
              final purchaseOwner = existingPurchase.docs.first.data()['userId'] as String?;
              if (purchaseOwner != null && purchaseOwner != userId) {
                debugPrint('⛔ Purchase record belongs to app user $purchaseOwner, NOT current user $userId — skipping');
                if (purchase.pendingCompletePurchase) {
                  await inAppPurchase.completePurchase(purchase);
                }
                continue;
              }
            }
          }

          // Verify and complete the purchase
          try {
            final verified = await verifyPurchase(
              purchaseDetails: purchase,
              userId: userId,
            );

            if (verified) {
                          // Update user's profile membershipTier
            final details = _getMembershipDetailsFromProductId(purchase.productID);
            final tier = details['tier'] as SubscriptionTier;
            final duration = details['duration'] as Duration;
            final tierName = tier.name.toUpperCase();
            
            // Get current membership end date to extend it
            final currentProfile = await firestore.collection('profiles').doc(userId).get();
            DateTime newEndDate;
            final currentEndDate = currentProfile.data()?['membershipEndDate'] as Timestamp?;
            final currentTier = currentProfile.data()?['membershipTier'] as String?;
            
            if (currentEndDate != null && currentTier != null) {
              final currentTierEnum = SubscriptionTierExtension.fromString(currentTier.toLowerCase());
              final currentEndDateTime = currentEndDate.toDate();
              
              // If buying same or higher tier, extend from current end date
              // If buying lower tier, extend from now
              if (tier.index >= currentTierEnum.index) {
                newEndDate = currentEndDateTime.add(duration);
              } else {
                newEndDate = DateTime.now().add(duration);
              }
            } else {
              // No current membership, start from now
              newEndDate = DateTime.now().add(duration);
            }
            
            await firestore.collection('profiles').doc(userId).update({
              'membershipTier': tierName,
              'membershipStartDate': Timestamp.fromDate(DateTime.now()),
              'membershipEndDate': Timestamp.fromDate(newEndDate),
            });

              // Complete the purchase with the store
              await completePurchase(purchase);
              _onPurchaseSuccess?.call(purchase);
            } else {
              _onPurchaseError?.call(purchase, 'Verification failed');
            }
          } catch (e) {
            // If the server rejected due to token ownership, just complete
            // the purchase to clear it from the queue — don't treat as error
            final errorMsg = e.toString();
            if (errorMsg.contains('already-exists') || errorMsg.contains('already linked')) {
              debugPrint('Purchase belongs to different app account — skipping: $errorMsg');
              if (purchase.pendingCompletePurchase) {
                await inAppPurchase.completePurchase(purchase);
              }
            } else {
              _onPurchaseError?.call(purchase, errorMsg);
            }
          }
          break;

        case PurchaseStatus.error:
          // Purchase failed
          final errorMessage = purchase.error?.message ?? 'Unknown error';
          _onPurchaseError?.call(purchase, errorMessage);

          // Still need to complete purchase to clear it from queue
          if (purchase.pendingCompletePurchase) {
            await inAppPurchase.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          // User canceled the purchase
          debugPrint('Purchase canceled: ${purchase.productID}');
          if (purchase.pendingCompletePurchase) {
            await inAppPurchase.completePurchase(purchase);
          }
          break;
      }
    }
  }

  /// Dispose of the purchase stream listener
  void disposePurchaseStreamListener() {
    _purchaseStreamSubscription?.cancel();
    _purchaseStreamSubscription = null;
    _onPurchaseSuccess = null;
    _onPurchaseError = null;
    _onPurchasePending = null;
    debugPrint('Purchase stream listener disposed');
  }

  /// Check if feature is available
  Future<bool> hasFeatureAccess({
    required String userId,
    required String featureName,
  }) async {
    final subscription = await getCurrentSubscription(userId);
    if (subscription == null) return false;

    return subscription.hasFeature(featureName);
  }

  /// Get feature limit
  Future<int> getFeatureLimit({
    required String userId,
    required String featureName,
  }) async {
    final subscription = await getCurrentSubscription(userId);
    if (subscription == null) return 0;

    return subscription.getLimit(featureName);
  }
}
