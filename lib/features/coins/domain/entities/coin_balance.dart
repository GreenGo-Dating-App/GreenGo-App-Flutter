import 'package:equatable/equatable.dart';

/// GreenGoCoin Balance Entity
/// Point 156: Virtual currency with $0.99 = 100 coins exchange rate
/// Point 158: Coin balance with animated display
/// Point 164: Coin expiration after 365 days
class CoinBalance extends Equatable {
  final String userId;
  final int totalCoins;
  final int earnedCoins;
  final int purchasedCoins;
  final int giftedCoins;
  final int spentCoins;
  final DateTime lastUpdated;
  final List<CoinBatch> coinBatches; // For tracking expiration

  const CoinBalance({
    required this.userId,
    required this.totalCoins,
    required this.earnedCoins,
    required this.purchasedCoins,
    required this.giftedCoins,
    required this.spentCoins,
    required this.lastUpdated,
    this.coinBatches = const [],
  });

  /// Get available (non-expired) coins
  int get availableCoins {
    final now = DateTime.now();
    int available = 0;
    for (final batch in coinBatches) {
      if (!batch.isExpired(now)) {
        available += batch.remainingCoins;
      }
    }
    return available;
  }

  /// Get expired coins
  int get expiredCoins {
    final now = DateTime.now();
    int expired = 0;
    for (final batch in coinBatches) {
      if (batch.isExpired(now)) {
        expired += batch.remainingCoins;
      }
    }
    return expired;
  }

  /// Get coins expiring soon (within 30 days)
  int getCoinsExpiringSoon({int days = 30}) {
    final threshold = DateTime.now().add(Duration(days: days));
    int expiringSoon = 0;
    for (final batch in coinBatches) {
      if (!batch.isExpired(DateTime.now()) &&
          batch.expirationDate.isBefore(threshold)) {
        expiringSoon += batch.remainingCoins;
      }
    }
    return expiringSoon;
  }

  /// Check if user has enough coins
  bool hasEnoughCoins(int amount) {
    return availableCoins >= amount;
  }

  @override
  List<Object?> get props => [
        userId,
        totalCoins,
        earnedCoins,
        purchasedCoins,
        giftedCoins,
        spentCoins,
        lastUpdated,
        coinBatches,
      ];
}

/// Represents a batch of coins with expiration date
/// Point 164: Coins expire after 365 days
class CoinBatch extends Equatable {
  final String batchId;
  final int initialCoins;
  final int remainingCoins;
  final CoinSource source;
  final DateTime acquiredDate;
  final DateTime expirationDate;

  const CoinBatch({
    required this.batchId,
    required this.initialCoins,
    required this.remainingCoins,
    required this.source,
    required this.acquiredDate,
    required this.expirationDate,
  });

  /// Check if batch has expired
  bool isExpired(DateTime now) {
    return now.isAfter(expirationDate);
  }

  /// Get days until expiration
  int daysUntilExpiration() {
    final now = DateTime.now();
    if (isExpired(now)) return 0;
    return expirationDate.difference(now).inDays;
  }

  @override
  List<Object?> get props => [
        batchId,
        initialCoins,
        remainingCoins,
        source,
        acquiredDate,
        expirationDate,
      ];
}

/// Source of coins
enum CoinSource {
  purchase,      // Purchased with real money
  reward,        // Achievement rewards
  gift,          // Gifted by other users
  allowance,     // Monthly subscription allowance
  promotion,     // Promotional campaigns
  refund,        // Refunded from cancelled purchase
}

extension CoinSourceExtension on CoinSource {
  String get displayName {
    switch (this) {
      case CoinSource.purchase:
        return 'Purchase';
      case CoinSource.reward:
        return 'Reward';
      case CoinSource.gift:
        return 'Gift';
      case CoinSource.allowance:
        return 'Monthly Allowance';
      case CoinSource.promotion:
        return 'Promotion';
      case CoinSource.refund:
        return 'Refund';
    }
  }

  static CoinSource fromString(String value) {
    switch (value.toLowerCase()) {
      case 'purchase':
        return CoinSource.purchase;
      case 'reward':
        return CoinSource.reward;
      case 'gift':
        return CoinSource.gift;
      case 'allowance':
        return CoinSource.allowance;
      case 'promotion':
        return CoinSource.promotion;
      case 'refund':
        return CoinSource.refund;
      default:
        return CoinSource.purchase;
    }
  }
}
