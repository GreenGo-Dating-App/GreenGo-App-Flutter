import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

/// Get Current Subscription Use Case
class GetCurrentSubscription {

  GetCurrentSubscription(this.repository);
  final SubscriptionRepository repository;

  Future<Either<Failure, Subscription?>> call(String userId) async {
    return repository.getCurrentSubscription(userId);
  }
}
