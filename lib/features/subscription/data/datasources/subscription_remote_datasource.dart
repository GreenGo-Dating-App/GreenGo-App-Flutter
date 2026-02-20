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

  // Product IDs (must match backend and store configurations)
  static const String silverProductId = 'silver_premium_monthly';
  static const String goldProductId = 'gold_premium_monthly';
  static const String platinumProductId = 'platinum_vip_monthly';

  static const Set<String> _productIds = {
    silverProductId,
    goldProductId,
    platinumProductId,
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
      // Enable pending purchases for Google Play
      InAppPurchaseAndroidPlatformAddition androidAddition =
          inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      await androidAddition.enablePendingPurchases();
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

  /// Purchase subscription (Points 146-147)
  /// Uses obfuscatedExternalAccountId on Android to tie the purchase
  /// to the app's Firebase Auth user, not the Google Play billing account.
  Future<void> purchaseSubscription({
    required ProductDetails product,
    required String userId,
  }) async {
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

    await inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore purchases (Point 154)
  Future<List<PurchaseDetails>> restorePurchases() async {
    await inAppPurchase.restorePurchases();

    // Get past purchases
    final Stream<List<PurchaseDetails>> purchaseStream =
        inAppPurchase.purchaseStream;

    // Note: In real implementation, you'd listen to the stream
    // For now, return empty list (purchases come through stream)
    return [];
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

    final platform = Platform.isAndroid ? 'android' : 'ios';
    final tierName = _getTierFromProductId(purchaseDetails.productID);
    final tier = SubscriptionTierExtension.fromString(tierName);

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + 1, now.day);

    // Create subscription in Firestore
    await firestore.collection('subscriptions').add({
      'userId': userId,
      'tier': tierName,
      'status': 'active',
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(endDate),
      'nextBillingDate': Timestamp.fromDate(endDate),
      'autoRenew': true,
      'platform': platform,
      'purchaseToken': purchaseDetails.purchaseID,
      'transactionId': purchaseDetails.purchaseID,
      'orderId': purchaseDetails.purchaseID,
      'price': tier.monthlyPrice,
      'currency': 'USD',
      'inGracePeriod': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create purchase record
    await firestore.collection('purchases').add({
      'userId': userId,
      'type': 'subscription',
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
      'membershipTier': tierName.toUpperCase(),
      'membershipStartDate': Timestamp.fromDate(now),
      'membershipEndDate': Timestamp.fromDate(endDate),
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
        .where('userId', '==', userId)
        .where('status', 'in', ['active', 'cancelled'])
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
        .where('userId', '==', userId)
        .where('status', 'in', ['active', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return SubscriptionModel.fromFirestore(snapshot.docs.first);
    });
  }

  /// Cancel subscription (Point 151)
  Future<void> cancelSubscription({
    required String subscriptionId,
    required String reason,
  }) async {
    await firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': 'cancelled',
      'autoRenew': false,
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Upgrade subscription (Point 150)
  Future<void> upgradeSubscription({
    required String currentSubscriptionId,
    required SubscriptionTier newTier,
    required ProductDetails product,
  }) async {
    // Cancel current subscription
    await firestore
        .collection('subscriptions')
        .doc(currentSubscriptionId)
        .update({
      'status': 'cancelled',
      'autoRenew': false,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Purchase new tier through store
    // The verification will create the new subscription
    // Note: In production, implement pro-rated billing
  }

  /// Get purchase history
  Future<List<Map<String, dynamic>>> getPurchaseHistory(String userId) async {
    final snapshot = await firestore
        .collection('purchases')
        .where('userId', '==', userId)
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

  /// Helper: Get tier from product ID
  String _getTierFromProductId(String productId) {
    if (productId.contains('platinum')) return 'platinum';
    if (productId.contains('gold')) return 'gold';
    if (productId.contains('silver')) return 'silver';
    return 'basic';
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

  /// Handle purchase updates from the stream
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
          // Verify and complete the purchase
          try {
            final verified = await verifyPurchase(
              purchaseDetails: purchase,
              userId: userId,
            );

            if (verified) {
              // Update user's profile membershipTier
              final tierName = _getTierFromProductId(purchase.productID);
              final now = DateTime.now();
              final endDate = DateTime(now.year, now.month + 1, now.day);
              await firestore.collection('profiles').doc(userId).update({
                'membershipTier': tierName.toUpperCase(),
                'membershipStartDate': Timestamp.fromDate(now),
                'membershipEndDate': Timestamp.fromDate(endDate),
              });

              // Complete the purchase with the store
              await completePurchase(purchase);
              _onPurchaseSuccess?.call(purchase);
            } else {
              _onPurchaseError?.call(purchase, 'Verification failed');
            }
          } catch (e) {
            _onPurchaseError?.call(purchase, e.toString());
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
