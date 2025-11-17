import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

/// Get Current Subscription Use Case
class GetCurrentSubscription {
  final SubscriptionRepository repository;

  GetCurrentSubscription(this.repository);

  Future<Either<Failure, Subscription?>> call(String userId) async {
    return await repository.getCurrentSubscription(userId);
  }
}
