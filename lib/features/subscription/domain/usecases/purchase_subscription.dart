import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

/// Purchase Subscription Use Case
/// Point 146-147: Handle subscription purchase
class PurchaseSubscription {
  final SubscriptionRepository repository;

  PurchaseSubscription(this.repository);

  Future<Either<Failure, Purchase>> call({
    required String userId,
    required SubscriptionTier tier,
    required String platform,
  }) async {
    return await repository.purchaseSubscription(
      userId: userId,
      tier: tier,
      platform: platform,
    );
  }
}
