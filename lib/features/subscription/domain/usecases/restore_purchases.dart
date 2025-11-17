import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/purchase.dart';
import '../repositories/subscription_repository.dart';

/// Restore Purchases Use Case
/// Point 154: Restore purchases for reinstalling users
class RestorePurchases {
  final SubscriptionRepository repository;

  RestorePurchases(this.repository);

  Future<Either<Failure, List<Purchase>>> call(String userId) async {
    return await repository.restorePurchases(userId);
  }
}
