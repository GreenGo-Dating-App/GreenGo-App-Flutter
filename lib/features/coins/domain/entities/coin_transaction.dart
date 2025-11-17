import 'package:equatable/equatable.dart';

/// Coin Transaction Entity
/// Point 159: Transaction history with earnings and spending
class CoinTransaction extends Equatable {
  final String transactionId;
  final String userId;
  final CoinTransactionType type;
  final int amount;
  final int balanceAfter;
  final CoinTransactionReason reason;
  final String? relatedId; // Related entity ID (e.g., match ID, purchase ID)
  final String? relatedUserId; // For gifts
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const CoinTransaction({
    required this.transactionId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.reason,
    this.relatedId,
    this.relatedUserId,
    this.metadata,
    required this.createdAt,
  });

  /// Get display amount with sign
  String get displayAmount {
    final sign = type == CoinTransactionType.credit ? '+' : '-';
    return '$sign$amount';
  }

  /// Get description
  String get description {
    return reason.getDescription(
      amount: amount,
      metadata: metadata,
    );
  }

  @override
  List<Object?> get props => [
        transactionId,
        userId,
        type,
        amount,
        balanceAfter,
        reason,
        relatedId,
        relatedUserId,
        metadata,
        createdAt,
      ];
}

/// Transaction type (credit or debit)
enum CoinTransactionType {
  credit,  // Coins added
  debit,   // Coins spent
}

/// Reason for transaction
enum CoinTransactionReason {
  // Credits (Point 160: Rewards)
  firstMatchReward,
  completeProfileReward,
  dailyLoginStreakReward,
  achievementReward,

  // Credits (Point 163: Monthly allowance)
  monthlyAllowance,

  // Credits (Point 162: Gifts)
  giftReceived,

  // Credits (Point 165: Promotions)
  promotionalBonus,

  // Credits (Purchases & Refunds)
  coinPurchase,
  refund,

  // Debits (Point 161: Coin-based features)
  superLikePurchase,
  boostPurchase,
  undoPurchase,
  seeWhoLikedYouPurchase,

  // Debits (Point 162: Gifts)
  giftSent,

  // Debits (Other)
  featurePurchase,
  expired,
}

extension CoinTransactionReasonExtension on CoinTransactionReason {
  String get displayName {
    switch (this) {
      // Rewards
      case CoinTransactionReason.firstMatchReward:
        return 'First Match Reward';
      case CoinTransactionReason.completeProfileReward:
        return 'Complete Profile Reward';
      case CoinTransactionReason.dailyLoginStreakReward:
        return 'Daily Login Streak';
      case CoinTransactionReason.achievementReward:
        return 'Achievement Unlocked';

      // Allowance
      case CoinTransactionReason.monthlyAllowance:
        return 'Monthly Allowance';

      // Gifts
      case CoinTransactionReason.giftReceived:
        return 'Gift Received';
      case CoinTransactionReason.giftSent:
        return 'Gift Sent';

      // Promotions
      case CoinTransactionReason.promotionalBonus:
        return 'Promotional Bonus';

      // Purchases
      case CoinTransactionReason.coinPurchase:
        return 'Coin Purchase';
      case CoinTransactionReason.refund:
        return 'Refund';

      // Features
      case CoinTransactionReason.superLikePurchase:
        return 'Super Like';
      case CoinTransactionReason.boostPurchase:
        return 'Profile Boost';
      case CoinTransactionReason.undoPurchase:
        return 'Undo Last Swipe';
      case CoinTransactionReason.seeWhoLikedYouPurchase:
        return 'See Who Liked You';
      case CoinTransactionReason.featurePurchase:
        return 'Feature Purchase';

      // Other
      case CoinTransactionReason.expired:
        return 'Coins Expired';
    }
  }

  String getDescription({
    required int amount,
    Map<String, dynamic>? metadata,
  }) {
    switch (this) {
      case CoinTransactionReason.firstMatchReward:
        return 'Congratulations on your first match! Earned $amount coins.';
      case CoinTransactionReason.completeProfileReward:
        return 'Profile completed! Earned $amount coins.';
      case CoinTransactionReason.dailyLoginStreakReward:
        final streak = metadata?['streak'] ?? 1;
        return 'Day $streak login streak! Earned $amount coins.';
      case CoinTransactionReason.achievementReward:
        final achievement = metadata?['achievement'] ?? 'achievement';
        return 'Achievement unlocked: $achievement! Earned $amount coins.';

      case CoinTransactionReason.monthlyAllowance:
        final tier = metadata?['tier'] ?? 'Premium';
        return '$tier monthly allowance: $amount coins.';

      case CoinTransactionReason.giftReceived:
        final fromUser = metadata?['fromUsername'] ?? 'Someone';
        return 'Received $amount coins from $fromUser.';
      case CoinTransactionReason.giftSent:
        final toUser = metadata?['toUsername'] ?? 'someone';
        return 'Sent $amount coins to $toUser.';

      case CoinTransactionReason.promotionalBonus:
        final campaign = metadata?['campaign'] ?? 'special offer';
        return 'Promotional bonus from $campaign: $amount coins.';

      case CoinTransactionReason.coinPurchase:
        final packageName = metadata?['package'] ?? '';
        return 'Purchased $amount coins${packageName.isNotEmpty ? ' ($packageName)' : ''}.';
      case CoinTransactionReason.refund:
        return 'Refund: $amount coins.';

      case CoinTransactionReason.superLikePurchase:
        return 'Used $amount coins for Super Like.';
      case CoinTransactionReason.boostPurchase:
        return 'Used $amount coins for Profile Boost.';
      case CoinTransactionReason.undoPurchase:
        return 'Used $amount coins to Undo last swipe.';
      case CoinTransactionReason.seeWhoLikedYouPurchase:
        return 'Used $amount coins to see who liked you.';
      case CoinTransactionReason.featurePurchase:
        final feature = metadata?['feature'] ?? 'feature';
        return 'Used $amount coins for $feature.';

      case CoinTransactionReason.expired:
        return '$amount coins expired.';
    }
  }

  static CoinTransactionReason fromString(String value) {
    return CoinTransactionReason.values.firstWhere(
      (reason) => reason.toString().split('.').last == value,
      orElse: () => CoinTransactionReason.featurePurchase,
    );
  }
}

/// Coin feature prices (Point 161)
class CoinFeaturePrices {
  static const int superLike = 5;
  static const int boost = 50;
  static const int undo = 3;
  static const int seeWhoLikedYou = 20;

  /// Get price for a feature
  static int getPrice(String feature) {
    switch (feature.toLowerCase()) {
      case 'superlike':
      case 'super_like':
        return superLike;
      case 'boost':
        return boost;
      case 'undo':
        return undo;
      case 'see_who_liked_you':
      case 'seewholikedyou':
        return seeWhoLikedYou;
      default:
        return 0;
    }
  }
}
