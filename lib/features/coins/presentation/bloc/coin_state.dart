import 'package:equatable/equatable.dart';
import '../../domain/entities/coin_balance.dart';
import '../../domain/entities/coin_gift.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_promotion.dart';
import '../../domain/entities/coin_reward.dart';
import '../../domain/entities/coin_transaction.dart';

/// Coin States
abstract class CoinState extends Equatable {
  const CoinState();

  @override
  List<Object?> get props => [];
}

class CoinInitial extends CoinState {}

class CoinLoading extends CoinState {}

// Balance States
class CoinBalanceLoaded extends CoinState {

  const CoinBalanceLoaded(this.balance);
  final CoinBalance balance;

  @override
  List<Object?> get props => [balance];
}

class CoinBalanceUpdated extends CoinState {

  const CoinBalanceUpdated({
    required this.balance,
    required this.message,
  });
  final CoinBalance balance;
  final String message;

  @override
  List<Object?> get props => [balance, message];
}

// Package States
class CoinPackagesLoaded extends CoinState {

  const CoinPackagesLoaded({
    required this.packages,
    this.activePromotions = const [],
  });
  final List<CoinPackage> packages;
  final List<CoinPromotion> activePromotions;

  @override
  List<Object?> get props => [packages, activePromotions];
}

class CoinPackagePurchased extends CoinState {

  const CoinPackagePurchased({
    required this.transaction,
    required this.coinsAdded,
    this.bonusCoins,
  });
  final CoinTransaction transaction;
  final int coinsAdded;
  final int? bonusCoins;

  @override
  List<Object?> get props => [transaction, coinsAdded, bonusCoins];
}

// Transaction States
class TransactionHistoryLoaded extends CoinState {

  const TransactionHistoryLoaded(this.transactions);
  final List<CoinTransaction> transactions;

  @override
  List<Object?> get props => [transactions];
}

// Reward States
class RewardEligibilityChecked extends CoinState {

  const RewardEligibilityChecked({
    required this.rewardId,
    required this.isEligible,
  });
  final String rewardId;
  final bool isEligible;

  @override
  List<Object?> get props => [rewardId, isEligible];
}

class RewardClaimed extends CoinState {

  const RewardClaimed({
    required this.reward,
    required this.transaction,
  });
  final CoinReward reward;
  final CoinTransaction transaction;

  @override
  List<Object?> get props => [reward, transaction];
}

class ClaimedRewardsLoaded extends CoinState {

  const ClaimedRewardsLoaded(this.rewards);
  final List<ClaimedReward> rewards;

  @override
  List<Object?> get props => [rewards];
}

// Feature Purchase States
class FeatureAffordabilityChecked extends CoinState {

  const FeatureAffordabilityChecked({
    required this.canAfford,
    required this.cost,
    required this.currentBalance,
  });
  final bool canAfford;
  final int cost;
  final int currentBalance;

  @override
  List<Object?> get props => [canAfford, cost, currentBalance];
}

class FeaturePurchased extends CoinState {

  const FeaturePurchased({
    required this.featureName,
    required this.transaction,
  });
  final String featureName;
  final CoinTransaction transaction;

  @override
  List<Object?> get props => [featureName, transaction];
}

// Gift States
class GiftSent extends CoinState {

  const GiftSent(this.gift);
  final CoinGift gift;

  @override
  List<Object?> get props => [gift];
}

class GiftAccepted extends CoinState {

  const GiftAccepted({
    required this.giftId,
    required this.amount,
  });
  final String giftId;
  final int amount;

  @override
  List<Object?> get props => [giftId, amount];
}

class GiftDeclined extends CoinState {

  const GiftDeclined(this.giftId);
  final String giftId;

  @override
  List<Object?> get props => [giftId];
}

class PendingGiftsLoaded extends CoinState {

  const PendingGiftsLoaded(this.gifts);
  final List<CoinGift> gifts;

  @override
  List<Object?> get props => [gifts];
}

class SentGiftsLoaded extends CoinState {

  const SentGiftsLoaded(this.gifts);
  final List<CoinGift> gifts;

  @override
  List<Object?> get props => [gifts];
}

// Expiration States
class ExpiringCoinsLoaded extends CoinState {

  const ExpiringCoinsLoaded({
    required this.expiringBatches,
    required this.totalExpiringCoins,
    required this.daysUntilExpiration,
  });
  final List<CoinBatch> expiringBatches;
  final int totalExpiringCoins;
  final int daysUntilExpiration;

  @override
  List<Object?> get props => [
        expiringBatches,
        totalExpiringCoins,
        daysUntilExpiration,
      ];
}

class ExpiredCoinsProcessed extends CoinState {

  const ExpiredCoinsProcessed(this.expiredAmount);
  final int expiredAmount;

  @override
  List<Object?> get props => [expiredAmount];
}

// Promotion States
class PromotionsLoaded extends CoinState {

  const PromotionsLoaded(this.promotions);
  final List<CoinPromotion> promotions;

  @override
  List<Object?> get props => [promotions];
}

class PromoCodeApplied extends CoinState {

  const PromoCodeApplied(this.promotion);
  final CoinPromotion promotion;

  @override
  List<Object?> get props => [promotion];
}

class PromotionApplicabilityChecked extends CoinState {

  const PromotionApplicabilityChecked({
    required this.promotionId,
    required this.isApplicable,
  });
  final String promotionId;
  final bool isApplicable;

  @override
  List<Object?> get props => [promotionId, isApplicable];
}

// Error State
class CoinError extends CoinState {

  const CoinError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
