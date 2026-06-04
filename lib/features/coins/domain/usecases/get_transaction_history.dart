import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_transaction.dart';
import '../repositories/coin_repository.dart';

/// Get Transaction History Use Case
/// Point 159: Get coin transaction history
class GetTransactionHistory {

  GetTransactionHistory(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, List<CoinTransaction>>> call({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return repository.getTransactionHistory(
      userId: userId,
      limit: limit,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Stream variant for real-time updates
  Stream<Either<Failure, List<CoinTransaction>>> stream({
    required String userId,
    int limit = 50,
  }) {
    return repository.transactionStream(
      userId: userId,
      limit: limit,
    );
  }
}
