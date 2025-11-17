import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_balance.dart';
import '../repositories/coin_repository.dart';

/// Process Expired Coins Use Case
/// Point 164: Handle coin expiration after 365 days
class ProcessExpiredCoins {
  final CoinRepository repository;

  ProcessExpiredCoins(this.repository);

  Future<Either<Failure, void>> call(String userId) async {
    return await repository.processExpiredCoins(userId);
  }
}

/// Get Expiring Coins Use Case
class GetExpiringCoins {
  final CoinRepository repository;

  GetExpiringCoins(this.repository);

  Future<Either<Failure, List<CoinBatch>>> call({
    required String userId,
    int days = 30,
  }) async {
    return await repository.getExpiringCoins(
      userId: userId,
      days: days,
    );
  }
}

/// Coin expiration configuration
class CoinExpirationConfig {
  /// Coins expire after 365 days
  static const int expirationDays = 365;

  /// Warning threshold (notify user when coins expire in X days)
  static const int warningThresholdDays = 30;

  /// Get expiration date for new coins
  static DateTime getExpirationDate({DateTime? acquiredDate}) {
    final date = acquiredDate ?? DateTime.now();
    return date.add(const Duration(days: expirationDays));
  }

  /// Check if coins are expiring soon
  static bool isExpiringSoon(DateTime expirationDate) {
    final now = DateTime.now();
    final threshold = now.add(const Duration(days: warningThresholdDays));
    return expirationDate.isBefore(threshold) && expirationDate.isAfter(now);
  }
}
