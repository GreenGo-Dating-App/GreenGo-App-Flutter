import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_transaction.dart';
import '../repositories/coin_repository.dart';

/// Purchase Feature with Coins Use Case
/// Point 161: Purchase features using coins (Super Like, Boost, Undo, See Who Liked You)
class PurchaseFeature {

  PurchaseFeature(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, CoinTransaction>> call({
    required String userId,
    required String featureName,
    required int cost,
    String? relatedId,
  }) async {
    return repository.purchaseFeature(
      userId: userId,
      featureName: featureName,
      cost: cost,
      relatedId: relatedId,
    );
  }
}

/// Check if User Can Afford Feature Use Case
class CanAffordFeature {

  CanAffordFeature(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, bool>> call({
    required String userId,
    required int cost,
  }) async {
    return repository.canAffordFeature(
      userId: userId,
      cost: cost,
    );
  }
}
