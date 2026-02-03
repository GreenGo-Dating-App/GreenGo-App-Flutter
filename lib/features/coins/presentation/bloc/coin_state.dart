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
  final CoinBalance balance;

  const CoinBalanceLoaded(this.balance);

  @override
  List<Object?> get props => [balance];
}

class CoinBalanceUpdated extends CoinState {
  final CoinBalance balance;
  final String message;

  const CoinBalanceUpdated({
    required this.balance,
    required this.message,
  });

  @override
  List<Object?> get props => [balance, message];
}

// Package States
class CoinPackagesLoaded extends CoinState {
  final List<CoinPackage> packages;
  final List<CoinPromotion> activePromotions;

  const CoinPackagesLoaded({
    required this.packages,
    this.activePromotions = const [],
  });

  @override
  List<Object?> get props => [packages, activePromotions];
}

class CoinPackagePurchased extends CoinState {
  final CoinTransaction transaction;
  final int coinsAdded;
  final int? bonusCoins;

  const CoinPackagePurchased({
    required this.transaction,
    required this.coinsAdded,
    this.bonusCoins,
  });

  @override
  List<Object?> get props => [transaction, coinsAdded, bonusCoins];
}

// Transaction States
class TransactionHistoryLoaded extends CoinState {
  final List<CoinTransaction> transactions;

  const TransactionHistoryLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

// Reward States
class RewardEligibilityChecked extends CoinState {
  final String rewardId;
  final bool isEligible;

  const RewardEligibilityChecked({
    required this.rewardId,
    required this.isEligible,
  });

  @override
  List<Object?> get props => [rewardId, isEligible];
}

class RewardClaimed extends CoinState {
  final CoinReward reward;
  final CoinTransaction transaction;

  const RewardClaimed({
    required this.reward,
    required this.transaction,
  });

  @override
  List<Object?> get props => [reward, transaction];
}

class ClaimedRewardsLoaded extends CoinState {
  final List<ClaimedReward> rewards;

  const ClaimedRewardsLoaded(this.rewards);

  @override
  List<Object?> get props => [rewards];
}

// Feature Purchase States
class FeatureAffordabilityChecked extends CoinState {
  final bool canAfford;
  final int cost;
  final int currentBalance;

  const FeatureAffordabilityChecked({
    required this.canAfford,
    required this.cost,
    required this.currentBalance,
  });

  @override
  List<Object?> get props => [canAfford, cost, currentBalance];
}

class FeaturePurchased extends CoinState {
  final String featureName;
  final CoinTransaction transaction;

  const FeaturePurchased({
    required this.featureName,
    required this.transaction,
  });

  @override
  List<Object?> get props => [featureName, transaction];
}

// Gift States
class GiftSent extends CoinState {
  final CoinGift gift;

  const GiftSent(this.gift);

  @override
  List<Object?> get props => [gift];
}

class GiftAccepted extends CoinState {
  final String giftId;
  final int amount;

  const GiftAccepted({
    required this.giftId,
    required this.amount,
  });

  @override
  List<Object?> get props => [giftId, amount];
}

class GiftDeclined extends CoinState {
  final String giftId;

  const GiftDeclined(this.giftId);

  @override
  List<Object?> get props => [giftId];
}

class PendingGiftsLoaded extends CoinState {
  final List<CoinGift> gifts;

  const PendingGiftsLoaded(this.gifts);

  @override
  List<Object?> get props => [gifts];
}

class SentGiftsLoaded extends CoinState {
  final List<CoinGift> gifts;

  const SentGiftsLoaded(this.gifts);

  @override
  List<Object?> get props => [gifts];
}

// Expiration States
class ExpiringCoinsLoaded extends CoinState {
  final List<CoinBatch> expiringBatches;
  final int totalExpiringCoins;
  final int daysUntilExpiration;

  const ExpiringCoinsLoaded({
    required this.expiringBatches,
    required this.totalExpiringCoins,
    required this.daysUntilExpiration,
  });

  @override
  List<Object?> get props => [
        expiringBatches,
        totalExpiringCoins,
        daysUntilExpiration,
      ];
}

class ExpiredCoinsProcessed extends CoinState {
  final int expiredAmount;

  const ExpiredCoinsProcessed(this.expiredAmount);

  @override
  List<Object?> get props => [expiredAmount];
}

// Promotion States
class PromotionsLoaded extends CoinState {
  final List<CoinPromotion> promotions;

  const PromotionsLoaded(this.promotions);

  @override
  List<Object?> get props => [promotions];
}

class PromoCodeApplied extends CoinState {
  final CoinPromotion promotion;

  const PromoCodeApplied(this.promotion);

  @override
  List<Object?> get props => [promotion];
}

class PromotionApplicabilityChecked extends CoinState {
  final String promotionId;
  final bool isApplicable;

  const PromotionApplicabilityChecked({
    required this.promotionId,
    required this.isApplicable,
  });

  @override
  List<Object?> get props => [promotionId, isApplicable];
}

// Error State
class CoinError extends CoinState {
  final String message;

  const CoinError(this.message);

  @override
  List<Object?> get props => [message];
}
