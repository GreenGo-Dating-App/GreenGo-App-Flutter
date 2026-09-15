import 'package:equatable/equatable.dart';

/// GreenGoCoin Balance Entity
/// Point 156: Virtual currency with $0.99 = 100 coins exchange rate
/// Point 158: Coin balance with animated display
///
/// Coins NEVER expire. App Store Review Guideline 3.1.1 states that purchased
/// credits or currencies "may never expire", and GreenGo sells coins as a
/// consumable in-app purchase. The previous 365-day expiry (former "Point 164")
/// was removed in v4.0.0 for every coin source — purchased, earned, gifted and
/// granted alike — so there is a single rule that is easy to state and to
/// defend at review: a coin, once credited, is the user's forever.
class CoinBalance extends Equatable {

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
  final String userId;
  final int totalCoins;
  final int earnedCoins;
  final int purchasedCoins;
  final int giftedCoins;
  final int spentCoins;
  final DateTime lastUpdated;
  final List<CoinBatch> coinBatches;

  /// Coins the user can spend.
  ///
  /// Coins NEVER expire (see the class note), so nothing is withheld for age.
  /// The remaining subtlety is that not every credit path writes a batch:
  /// several Cloud Functions in `functions/src/coins/index.ts` grant coins with
  /// a bare `totalCoins: increment(n)` and no `coinBatches` entry. Summing
  /// batches alone therefore reported 0 for anyone holding those coins, even
  /// with a non-zero balance on the document.
  ///
  /// So anything in [totalCoins] that no batch accounts for is still spendable:
  ///
  ///   available = max(totalCoins, sum of batch remainders)
  ///
  /// That keeps every case honest — fully batch-backed balances are unchanged,
  /// a balance with no batches at all falls back to [totalCoins], and a
  /// batch-backed balance whose document total lags behind is not under-counted.
  int get availableCoins {
    var tracked = 0;
    for (final batch in coinBatches) {
      tracked += batch.remainingCoins;
    }
    return totalCoins > tracked ? totalCoins : tracked;
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

/// Represents a batch of coins acquired together.
///
/// Batches exist to record WHERE coins came from (and when), which drives the
/// transaction history and the admin view. They carry no expiry — see the note
/// on [CoinBalance].
class CoinBatch extends Equatable {

  const CoinBatch({
    required this.batchId,
    required this.initialCoins,
    required this.remainingCoins,
    required this.source,
    required this.acquiredDate,
  });
  final String batchId;
  final int initialCoins;
  final int remainingCoins;
  final CoinSource source;
  final DateTime acquiredDate;

  @override
  List<Object?> get props => [
        batchId,
        initialCoins,
        remainingCoins,
        source,
        acquiredDate,
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
