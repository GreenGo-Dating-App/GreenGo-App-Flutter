import 'package:equatable/equatable.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_promotion.dart';
import '../../domain/entities/coin_reward.dart';

/// Coin Events
abstract class CoinEvent extends Equatable {
  const CoinEvent();

  @override
  List<Object?> get props => [];
}

// Balance Events
class LoadCoinBalance extends CoinEvent {
  final String userId;

  const LoadCoinBalance(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SubscribeToCoinBalance extends CoinEvent {
  final String userId;

  const SubscribeToCoinBalance(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Package Events
class LoadAvailablePackages extends CoinEvent {
  const LoadAvailablePackages();
}

class PurchaseCoinPackage extends CoinEvent {
  final String userId;
  final CoinPackage package;
  final String platform;
  final CoinPromotion? promotion;

  const PurchaseCoinPackage({
    required this.userId,
    required this.package,
    required this.platform,
    this.promotion,
  });

  @override
  List<Object?> get props => [userId, package, platform, promotion];
}

// Transaction Events
class LoadTransactionHistory extends CoinEvent {
  final String userId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadTransactionHistory({
    required this.userId,
    this.limit,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, limit, startDate, endDate];
}

class SubscribeToTransactions extends CoinEvent {
  final String userId;
  final int limit;

  const SubscribeToTransactions({
    required this.userId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [userId, limit];
}

// Reward Events
class ClaimCoinReward extends CoinEvent {
  final String userId;
  final CoinReward reward;
  final Map<String, dynamic>? metadata;

  const ClaimCoinReward({
    required this.userId,
    required this.reward,
    this.metadata,
  });

  @override
  List<Object?> get props => [userId, reward, metadata];
}

class CheckRewardEligibility extends CoinEvent {
  final String userId;
  final String rewardId;

  const CheckRewardEligibility({
    required this.userId,
    required this.rewardId,
  });

  @override
  List<Object?> get props => [userId, rewardId];
}

class LoadClaimedRewards extends CoinEvent {
  final String userId;

  const LoadClaimedRewards(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Feature Purchase Events
class PurchaseFeatureWithCoins extends CoinEvent {
  final String userId;
  final String featureName;
  final int cost;
  final String? relatedId;

  const PurchaseFeatureWithCoins({
    required this.userId,
    required this.featureName,
    required this.cost,
    this.relatedId,
  });

  @override
  List<Object?> get props => [userId, featureName, cost, relatedId];
}

class CheckFeatureAffordability extends CoinEvent {
  final String userId;
  final int cost;

  const CheckFeatureAffordability({
    required this.userId,
    required this.cost,
  });

  @override
  List<Object?> get props => [userId, cost];
}

// Gift Events
class SendCoinGiftEvent extends CoinEvent {
  final String senderId;
  final String receiverId;
  final int amount;
  final String? message;

  const SendCoinGiftEvent({
    required this.senderId,
    required this.receiverId,
    required this.amount,
    this.message,
  });

  @override
  List<Object?> get props => [senderId, receiverId, amount, message];
}

class AcceptCoinGiftEvent extends CoinEvent {
  final String giftId;
  final String userId;

  const AcceptCoinGiftEvent({
    required this.giftId,
    required this.userId,
  });

  @override
  List<Object?> get props => [giftId, userId];
}

class DeclineCoinGiftEvent extends CoinEvent {
  final String giftId;
  final String userId;

  const DeclineCoinGiftEvent({
    required this.giftId,
    required this.userId,
  });

  @override
  List<Object?> get props => [giftId, userId];
}

class LoadPendingGifts extends CoinEvent {
  final String userId;

  const LoadPendingGifts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadSentGifts extends CoinEvent {
  final String userId;

  const LoadSentGifts(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Expiration Events
class CheckExpiringCoins extends CoinEvent {
  final String userId;
  final int days;

  const CheckExpiringCoins({
    required this.userId,
    this.days = 30,
  });

  @override
  List<Object?> get props => [userId, days];
}

class ProcessExpiredCoinsEvent extends CoinEvent {
  final String userId;

  const ProcessExpiredCoinsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Promotion Events
class LoadActivePromotions extends CoinEvent {
  const LoadActivePromotions();
}

class ApplyPromoCode extends CoinEvent {
  final String code;

  const ApplyPromoCode(this.code);

  @override
  List<Object?> get props => [code];
}

class CheckPromotionApplicability extends CoinEvent {
  final String promotionId;
  final String userId;

  const CheckPromotionApplicability({
    required this.promotionId,
    required this.userId,
  });

  @override
  List<Object?> get props => [promotionId, userId];
}
