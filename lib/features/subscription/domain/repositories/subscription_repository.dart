import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase.dart';
import '../entities/subscription.dart';

/// Subscription Repository
///
/// Contract for subscription and purchase operations
abstract class SubscriptionRepository {
  /// Get current subscription for user
  Future<Either<Failure, Subscription?>> getCurrentSubscription(String userId);

  /// Stream of subscription updates
  Stream<Either<Failure, Subscription?>> subscriptionStream(String userId);

  /// Purchase subscription (Points 146-147)
  Future<Either<Failure, Purchase>> purchaseSubscription({
    required String userId,
    required SubscriptionTier tier,
    required String platform,
  });

  /// Upgrade subscription (Point 150)
  Future<Either<Failure, Subscription>> upgradeSubscription({
    required String userId,
    required SubscriptionTier newTier,
  });

  /// Downgrade subscription (Point 150)
  Future<Either<Failure, Subscription>> downgradeSubscription({
    required String userId,
    required SubscriptionTier newTier,
  });

  /// Cancel subscription (Point 151)
  Future<Either<Failure, void>> cancelSubscription({
    required String userId,
    required String reason,
  });

  /// Restore purchases (Point 154)
  Future<Either<Failure, List<Purchase>>> restorePurchases(String userId);

  /// Verify purchase with platform
  Future<Either<Failure, bool>> verifyPurchase({
    required String purchaseToken,
    required String productId,
    required String platform,
  });

  /// Get purchase history
  Future<Either<Failure, List<Purchase>>> getPurchaseHistory(String userId);

  /// Handle failed payment (Point 153)
  Future<Either<Failure, void>> handleFailedPayment({
    required String subscriptionId,
  });

  /// End grace period
  Future<Either<Failure, void>> endGracePeriod({
    required String subscriptionId,
  });

  /// Check if feature is available for user
  Future<Either<Failure, bool>> hasFeatureAccess({
    required String userId,
    required String featureName,
  });

  /// Get feature limit for user
  Future<Either<Failure, int>> getFeatureLimit({
    required String userId,
    required String featureName,
  });

  /// Admin: Manual subscription management (Point 155)
  Future<Either<Failure, void>> adminUpdateSubscription({
    required String subscriptionId,
    required SubscriptionStatus status,
    String? note,
  });

  /// Admin: Issue refund
  Future<Either<Failure, void>> adminRefund({
    required String purchaseId,
    required String reason,
  });
}
