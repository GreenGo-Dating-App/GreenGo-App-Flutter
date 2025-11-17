import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_balance.dart';
import '../repositories/coin_repository.dart';

/// Get Coin Balance Use Case
/// Point 156: Get user's current coin balance
class GetCoinBalance {
  final CoinRepository repository;

  GetCoinBalance(this.repository);

  Future<Either<Failure, CoinBalance>> call(String userId) async {
    return await repository.getBalance(userId);
  }

  /// Stream variant for real-time updates
  Stream<Either<Failure, CoinBalance>> stream(String userId) {
    return repository.balanceStream(userId);
  }
}
