import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/coin_repository.dart';

/// Grant Monthly Allowance Use Case
/// Point 163: Grant monthly coin allowance to Silver (100) and Gold (250) subscribers
class GrantMonthlyAllowance {
  final CoinRepository repository;

  GrantMonthlyAllowance(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required int amount,
    required String tier,
  }) async {
    return await repository.grantMonthlyAllowance(
      userId: userId,
      amount: amount,
      tier: tier,
    );
  }
}

/// Check if Monthly Allowance Received Use Case
class HasReceivedMonthlyAllowance {
  final CoinRepository repository;

  HasReceivedMonthlyAllowance(this.repository);

  Future<Either<Failure, bool>> call({
    required String userId,
    required int year,
    required int month,
  }) async {
    return await repository.hasReceivedMonthlyAllowance(
      userId: userId,
      year: year,
      month: month,
    );
  }
}

/// Monthly allowance amounts by tier
class MonthlyAllowanceAmounts {
  static const int basic = 0;
  static const int silver = 100;
  static const int gold = 250;

  /// Get allowance amount for tier
  static int getAmount(String tier) {
    switch (tier.toLowerCase()) {
      case 'silver':
        return silver;
      case 'gold':
        return gold;
      case 'basic':
      default:
        return basic;
    }
  }
}
