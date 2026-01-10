import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/usecases/claim_reward.dart';
import '../../domain/usecases/get_coin_balance.dart';
import '../../domain/usecases/get_transaction_history.dart';
import '../../domain/usecases/manage_allowance.dart';
import '../../domain/usecases/manage_expiration.dart';
import '../../domain/usecases/manage_gifts.dart';
import '../../domain/usecases/manage_promotions.dart';
import '../../domain/usecases/purchase_coins.dart';
import '../../domain/usecases/purchase_feature.dart';
import 'coin_event.dart';
import 'coin_state.dart';

/// Coin BLoC
/// Manages all coin-related state and operations
class CoinBloc extends Bloc<CoinEvent, CoinState> {
  final GetCoinBalance getCoinBalance;
  final PurchaseCoins purchaseCoins;
  final GetAvailablePackages getAvailablePackages;
  final GetTransactionHistory getTransactionHistory;
  final ClaimReward claimReward;
  final CanClaimReward canClaimReward;
  final GetClaimedRewards getClaimedRewards;
  final PurchaseFeature purchaseFeature;
  final CanAffordFeature canAffordFeature;
  final SendCoinGift sendGift;
  final AcceptCoinGift acceptGift;
  final DeclineCoinGift declineGift;
  final GetPendingGifts getPendingGifts;
  final GetSentGifts getSentGifts;
  final ProcessExpiredCoins processExpiredCoins;
  final GetExpiringCoins getExpiringCoins;
  final GetActivePromotions getActivePromotions;
  final GetPromotionByCode getPromotionByCode;
  final IsPromotionApplicable isPromotionApplicable;

  CoinBloc({
    required this.getCoinBalance,
    required this.purchaseCoins,
    required this.getAvailablePackages,
    required this.getTransactionHistory,
    required this.claimReward,
    required this.canClaimReward,
    required this.getClaimedRewards,
    required this.purchaseFeature,
    required this.canAffordFeature,
    required this.sendGift,
    required this.acceptGift,
    required this.declineGift,
    required this.getPendingGifts,
    required this.getSentGifts,
    required this.processExpiredCoins,
    required this.getExpiringCoins,
    required this.getActivePromotions,
    required this.getPromotionByCode,
    required this.isPromotionApplicable,
  }) : super(CoinInitial()) {
    // Balance Events
    on<LoadCoinBalance>(_onLoadCoinBalance);
    on<SubscribeToCoinBalance>(_onSubscribeToCoinBalance);

    // Package Events
    on<LoadAvailablePackages>(_onLoadAvailablePackages);
    on<PurchaseCoinPackage>(_onPurchaseCoinPackage);

    // Transaction Events
    on<LoadTransactionHistory>(_onLoadTransactionHistory);
    on<SubscribeToTransactions>(_onSubscribeToTransactions);

    // Reward Events
    on<ClaimCoinReward>(_onClaimCoinReward);
    on<CheckRewardEligibility>(_onCheckRewardEligibility);
    on<LoadClaimedRewards>(_onLoadClaimedRewards);

    // Feature Purchase Events
    on<PurchaseFeatureWithCoins>(_onPurchaseFeatureWithCoins);
    on<CheckFeatureAffordability>(_onCheckFeatureAffordability);

    // Gift Events
    on<SendCoinGiftEvent>(_onSendCoinGift);
    on<AcceptCoinGiftEvent>(_onAcceptCoinGift);
    on<DeclineCoinGiftEvent>(_onDeclineCoinGift);
    on<LoadPendingGifts>(_onLoadPendingGifts);
    on<LoadSentGifts>(_onLoadSentGifts);

    // Expiration Events
    on<CheckExpiringCoins>(_onCheckExpiringCoins);
    on<ProcessExpiredCoinsEvent>(_onProcessExpiredCoins);

    // Promotion Events
    on<LoadActivePromotions>(_onLoadActivePromotions);
    on<ApplyPromoCode>(_onApplyPromoCode);
    on<CheckPromotionApplicability>(_onCheckPromotionApplicability);
  }

  // ===== Balance Event Handlers =====

  Future<void> _onLoadCoinBalance(
    LoadCoinBalance event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getCoinBalance(event.userId);

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (balance) => emit(CoinBalanceLoaded(balance)),
    );
  }

  Future<void> _onSubscribeToCoinBalance(
    SubscribeToCoinBalance event,
    Emitter<CoinState> emit,
  ) async {
    // Use emit.forEach to properly handle stream emissions
    await emit.forEach(
      getCoinBalance.stream(event.userId),
      onData: (result) {
        return result.fold(
          (failure) => CoinError(failure.toString()),
          (balance) => CoinBalanceLoaded(balance),
        );
      },
    );
  }

  // ===== Package Event Handlers =====

  Future<void> _onLoadAvailablePackages(
    LoadAvailablePackages event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final packagesResult = await getAvailablePackages();
    final promotionsResult = await getActivePromotions();

    packagesResult.fold(
      (failure) => emit(CoinError(failure.toString())),
      (packages) {
        promotionsResult.fold(
          (failure) => emit(CoinPackagesLoaded(packages: packages)),
          (promotions) => emit(CoinPackagesLoaded(
            packages: packages,
            activePromotions: promotions,
          )),
        );
      },
    );
  }

  Future<void> _onPurchaseCoinPackage(
    PurchaseCoinPackage event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await purchaseCoins(
      userId: event.userId,
      package: event.package,
      platform: event.platform,
      promotion: event.promotion,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (transaction) {
        emit(CoinPackagePurchased(
          transaction: transaction,
          coinsAdded: transaction.amount,
        ));
        // Also load updated balance
        add(LoadCoinBalance(event.userId));
      },
    );
  }

  // ===== Transaction Event Handlers =====

  Future<void> _onLoadTransactionHistory(
    LoadTransactionHistory event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getTransactionHistory(
      userId: event.userId,
      limit: event.limit,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (transactions) => emit(TransactionHistoryLoaded(transactions)),
    );
  }

  Future<void> _onSubscribeToTransactions(
    SubscribeToTransactions event,
    Emitter<CoinState> emit,
  ) async {
    // Use emit.forEach to properly handle stream emissions
    await emit.forEach(
      getTransactionHistory.stream(userId: event.userId, limit: event.limit),
      onData: (result) {
        return result.fold(
          (failure) => CoinError(failure.toString()),
          (transactions) => TransactionHistoryLoaded(transactions),
        );
      },
    );
  }

  // ===== Reward Event Handlers =====

  Future<void> _onClaimCoinReward(
    ClaimCoinReward event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await claimReward(
      userId: event.userId,
      reward: event.reward,
      metadata: event.metadata,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (transaction) {
        emit(RewardClaimed(
          reward: event.reward,
          transaction: transaction,
        ));
        // Reload balance
        add(LoadCoinBalance(event.userId));
      },
    );
  }

  Future<void> _onCheckRewardEligibility(
    CheckRewardEligibility event,
    Emitter<CoinState> emit,
  ) async {
    final result = await canClaimReward(
      userId: event.userId,
      rewardId: event.rewardId,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (isEligible) => emit(RewardEligibilityChecked(
        rewardId: event.rewardId,
        isEligible: isEligible,
      )),
    );
  }

  Future<void> _onLoadClaimedRewards(
    LoadClaimedRewards event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getClaimedRewards(event.userId);

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (rewards) => emit(ClaimedRewardsLoaded(rewards)),
    );
  }

  // ===== Feature Purchase Event Handlers =====

  Future<void> _onPurchaseFeatureWithCoins(
    PurchaseFeatureWithCoins event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await purchaseFeature(
      userId: event.userId,
      featureName: event.featureName,
      cost: event.cost,
      relatedId: event.relatedId,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (transaction) {
        emit(FeaturePurchased(
          featureName: event.featureName,
          transaction: transaction,
        ));
        // Reload balance
        add(LoadCoinBalance(event.userId));
      },
    );
  }

  Future<void> _onCheckFeatureAffordability(
    CheckFeatureAffordability event,
    Emitter<CoinState> emit,
  ) async {
    final balanceResult = await getCoinBalance(event.userId);
    final affordResult = await canAffordFeature(
      userId: event.userId,
      cost: event.cost,
    );

    balanceResult.fold(
      (failure) => emit(CoinError(failure.toString())),
      (balance) {
        affordResult.fold(
          (failure) => emit(CoinError(failure.toString())),
          (canAfford) => emit(FeatureAffordabilityChecked(
            canAfford: canAfford,
            cost: event.cost,
            currentBalance: balance.availableCoins,
          )),
        );
      },
    );
  }

  // ===== Gift Event Handlers =====

  Future<void> _onSendCoinGift(
    SendCoinGiftEvent event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await sendGift(
      senderId: event.senderId,
      receiverId: event.receiverId,
      amount: event.amount,
      message: event.message,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (gift) {
        emit(GiftSent(gift));
        // Reload balance
        add(LoadCoinBalance(event.senderId));
      },
    );
  }

  Future<void> _onAcceptCoinGift(
    AcceptCoinGiftEvent event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await acceptGift(
      giftId: event.giftId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (_) {
        emit(GiftAccepted(
          giftId: event.giftId,
          amount: 0, // Will be in transaction
        ));
        // Reload balance and pending gifts
        add(LoadCoinBalance(event.userId));
        add(LoadPendingGifts(event.userId));
      },
    );
  }

  Future<void> _onDeclineCoinGift(
    DeclineCoinGiftEvent event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await declineGift(
      giftId: event.giftId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (_) {
        emit(GiftDeclined(event.giftId));
        // Reload pending gifts
        add(LoadPendingGifts(event.userId));
      },
    );
  }

  Future<void> _onLoadPendingGifts(
    LoadPendingGifts event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getPendingGifts(event.userId);

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (gifts) => emit(PendingGiftsLoaded(gifts)),
    );
  }

  Future<void> _onLoadSentGifts(
    LoadSentGifts event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getSentGifts(event.userId);

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (gifts) => emit(SentGiftsLoaded(gifts)),
    );
  }

  // ===== Expiration Event Handlers =====

  Future<void> _onCheckExpiringCoins(
    CheckExpiringCoins event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getExpiringCoins(
      userId: event.userId,
      days: event.days,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (batches) {
        final totalExpiring =
            batches.fold<int>(0, (sum, batch) => sum + batch.remainingCoins);
        emit(ExpiringCoinsLoaded(
          expiringBatches: batches,
          totalExpiringCoins: totalExpiring,
          daysUntilExpiration: event.days,
        ));
      },
    );
  }

  Future<void> _onProcessExpiredCoins(
    ProcessExpiredCoinsEvent event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await processExpiredCoins(event.userId);

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (_) {
        emit(const ExpiredCoinsProcessed(0));
        // Reload balance
        add(LoadCoinBalance(event.userId));
      },
    );
  }

  // ===== Promotion Event Handlers =====

  Future<void> _onLoadActivePromotions(
    LoadActivePromotions event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getActivePromotions();

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (promotions) => emit(PromotionsLoaded(promotions)),
    );
  }

  Future<void> _onApplyPromoCode(
    ApplyPromoCode event,
    Emitter<CoinState> emit,
  ) async {
    emit(CoinLoading());

    final result = await getPromotionByCode(event.code);

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (promotion) {
        if (promotion == null) {
          emit(const CoinError('Invalid promo code'));
        } else {
          emit(PromoCodeApplied(promotion));
        }
      },
    );
  }

  Future<void> _onCheckPromotionApplicability(
    CheckPromotionApplicability event,
    Emitter<CoinState> emit,
  ) async {
    final result = await isPromotionApplicable(
      promotionId: event.promotionId,
      userId: event.userId,
    );

    result.fold(
      (failure) => emit(CoinError(failure.toString())),
      (isApplicable) => emit(PromotionApplicabilityChecked(
        promotionId: event.promotionId,
        isApplicable: isApplicable,
      )),
    );
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
