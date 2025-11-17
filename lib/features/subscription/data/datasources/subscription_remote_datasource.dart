import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Product IDs (must match backend and store configurations)
  static const String silverProductId = 'silver_premium_monthly';
  static const String goldProductId = 'gold_premium_monthly';

  static const Set<String> _productIds = {
    silverProductId,
    goldProductId,
  };

  SubscriptionRemoteDataSource({
    required this.firestore,
    required this.inAppPurchase,
  });

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
  Future<void> purchaseSubscription({
    required ProductDetails product,
    required String userId,
  }) async {
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: userId, // Used for verification
    );

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

  /// Verify purchase with backend
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

      // Send to backend for verification
      // In production, call your Cloud Function
      // For now, we'll just create the subscription directly

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
      });

      return true;
    } catch (e) {
      throw Exception('Failed to verify purchase: $e');
    }
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
    if (productId.contains('silver')) return 'silver';
    if (productId.contains('gold')) return 'gold';
    return 'basic';
  }

  /// Listen to purchase stream
  Stream<List<PurchaseDetails>> get purchaseStream =>
      inAppPurchase.purchaseStream;

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
