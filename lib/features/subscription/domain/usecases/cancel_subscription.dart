import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/subscription_repository.dart';

/// Cancel Subscription Use Case
/// Point 151: Handle subscription cancellation
class CancelSubscription {
  final SubscriptionRepository repository;

  CancelSubscription(this.repository);

  Future<Either<Failure, void>> call({
    required String subscriptionId,
    required String reason,
  }) async {
    return await repository.cancelSubscription(
      userId: '', // Will be extracted from subscription
      reason: reason,
    );
  }
}
