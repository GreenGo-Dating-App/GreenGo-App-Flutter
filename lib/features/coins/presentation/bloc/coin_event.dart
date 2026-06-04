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

  const LoadCoinBalance(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class SubscribeToCoinBalance extends CoinEvent {

  const SubscribeToCoinBalance(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

// Package Events
class LoadAvailablePackages extends CoinEvent {
  const LoadAvailablePackages();
}

class PurchaseCoinPackage extends CoinEvent {

  const PurchaseCoinPackage({
    required this.userId,
    required this.package,
    required this.platform,
    this.promotion,
  });
  final String userId;
  final CoinPackage package;
  final String platform;
  final CoinPromotion? promotion;

  @override
  List<Object?> get props => [userId, package, platform, promotion];
}

// Transaction Events
class LoadTransactionHistory extends CoinEvent {

  const LoadTransactionHistory({
    required this.userId,
    this.limit,
    this.startDate,
    this.endDate,
  });
  final String userId;
  final int? limit;
  final DateTime? startDate;
  final DateTime? endDate;

  @override
  List<Object?> get props => [userId, limit, startDate, endDate];
}

class SubscribeToTransactions extends CoinEvent {

  const SubscribeToTransactions({
    required this.userId,
    this.limit = 50,
  });
  final String userId;
  final int limit;

  @override
  List<Object?> get props => [userId, limit];
}

// Reward Events
class ClaimCoinReward extends CoinEvent {

  const ClaimCoinReward({
    required this.userId,
    required this.reward,
    this.metadata,
  });
  final String userId;
  final CoinReward reward;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [userId, reward, metadata];
}

class CheckRewardEligibility extends CoinEvent {

  const CheckRewardEligibility({
    required this.userId,
    required this.rewardId,
  });
  final String userId;
  final String rewardId;

  @override
  List<Object?> get props => [userId, rewardId];
}

class LoadClaimedRewards extends CoinEvent {

  const LoadClaimedRewards(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

// Feature Purchase Events
class PurchaseFeatureWithCoins extends CoinEvent {

  const PurchaseFeatureWithCoins({
    required this.userId,
    required this.featureName,
    required this.cost,
    this.relatedId,
  });
  final String userId;
  final String featureName;
  final int cost;
  final String? relatedId;

  @override
  List<Object?> get props => [userId, featureName, cost, relatedId];
}

class CheckFeatureAffordability extends CoinEvent {

  const CheckFeatureAffordability({
    required this.userId,
    required this.cost,
  });
  final String userId;
  final int cost;

  @override
  List<Object?> get props => [userId, cost];
}

// Gift Events
class SendCoinGiftEvent extends CoinEvent {

  const SendCoinGiftEvent({
    required this.senderId,
    required this.receiverId,
    required this.amount,
    this.message,
  });
  final String senderId;
  final String receiverId;
  final int amount;
  final String? message;

  @override
  List<Object?> get props => [senderId, receiverId, amount, message];
}

class AcceptCoinGiftEvent extends CoinEvent {

  const AcceptCoinGiftEvent({
    required this.giftId,
    required this.userId,
  });
  final String giftId;
  final String userId;

  @override
  List<Object?> get props => [giftId, userId];
}

class DeclineCoinGiftEvent extends CoinEvent {

  const DeclineCoinGiftEvent({
    required this.giftId,
    required this.userId,
  });
  final String giftId;
  final String userId;

  @override
  List<Object?> get props => [giftId, userId];
}

class LoadPendingGifts extends CoinEvent {

  const LoadPendingGifts(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class LoadSentGifts extends CoinEvent {

  const LoadSentGifts(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

// Expiration Events
class CheckExpiringCoins extends CoinEvent {

  const CheckExpiringCoins({
    required this.userId,
    this.days = 30,
  });
  final String userId;
  final int days;

  @override
  List<Object?> get props => [userId, days];
}

class ProcessExpiredCoinsEvent extends CoinEvent {

  const ProcessExpiredCoinsEvent(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

// Promotion Events
class LoadActivePromotions extends CoinEvent {
  const LoadActivePromotions();
}

class ApplyPromoCode extends CoinEvent {

  const ApplyPromoCode(this.code);
  final String code;

  @override
  List<Object?> get props => [code];
}

class CheckPromotionApplicability extends CoinEvent {

  const CheckPromotionApplicability({
    required this.promotionId,
    required this.userId,
  });
  final String promotionId;
  final String userId;

  @override
  List<Object?> get props => [promotionId, userId];
}
