import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/coin_balance.dart';
import '../../domain/entities/coin_gift.dart';
import '../../domain/entities/coin_package.dart';
import '../../domain/entities/coin_promotion.dart';
import '../../domain/entities/coin_reward.dart';
import '../../domain/entities/coin_transaction.dart';
import '../../domain/repositories/coin_repository.dart';
import '../datasources/coin_remote_datasource.dart';

/// Coin Repository Implementation
class CoinRepositoryImpl implements CoinRepository {
  final CoinRemoteDataSource remoteDataSource;

  CoinRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, CoinBalance>> getBalance(String userId) async {
    try {
      final balance = await remoteDataSource.getBalance(userId);
      return Right(balance);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, CoinBalance>> balanceStream(String userId) {
    try {
      return remoteDataSource.balanceStream(userId).map(
            (balance) => Right<Failure, CoinBalance>(balance),
          );
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> updateBalance({
    required String userId,
    required int amount,
    required CoinTransactionType type,
    required CoinTransactionReason reason,
    String? relatedId,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await remoteDataSource.updateBalance(
        userId: userId,
        amount: amount,
        type: type,
        reason: reason,
        relatedId: relatedId,
        relatedUserId: relatedUserId,
        metadata: metadata,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CoinPackage>>> getAvailablePackages() async {
    try {
      final packages = await remoteDataSource.getAvailablePackages();
      return Right(packages);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CoinTransaction>> purchaseCoins({
    required String userId,
    required CoinPackage package,
    required String platform,
    String? purchaseToken,
    CoinPromotion? promotion,
  }) async {
    try {
      // Calculate total coins including promotion bonus
      int totalCoins = package.coinAmount;
      if (promotion != null && promotion.isCurrentlyActive) {
        totalCoins += promotion.calculateBonus(package.coinAmount, package.price);
      }

      // Update balance
      await remoteDataSource.updateBalance(
        userId: userId,
        amount: totalCoins,
        type: CoinTransactionType.credit,
        reason: CoinTransactionReason.coinPurchase,
        metadata: {
          'package': package.packageId,
          'price': package.price,
          'baseCoins': package.coinAmount,
          'bonusCoins': totalCoins - package.coinAmount,
          'platform': platform,
          'promotionId': promotion?.promotionId,
        },
      );

      // Get the transaction
      final transactions = await remoteDataSource.getTransactionHistory(
        userId: userId,
        limit: 1,
      );

      return Right(transactions.first);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPurchase({
    required String userId,
    required String purchaseToken,
    required String platform,
  }) async {
    try {
      final verified = await remoteDataSource.verifyPurchase(
        userId: userId,
        purchaseToken: purchaseToken,
        platform: platform,
      );
      return Right(verified);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CoinTransaction>>> getTransactionHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final transactions = await remoteDataSource.getTransactionHistory(
        userId: userId,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(transactions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<CoinTransaction>>> transactionStream({
    required String userId,
    int limit = 50,
  }) {
    try {
      return remoteDataSource
          .transactionStream(userId: userId, limit: limit)
          .map(
            (transactions) => Right<Failure, List<CoinTransaction>>(transactions),
          );
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, CoinTransaction>> claimReward({
    required String userId,
    required CoinReward reward,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if can claim
      final canClaim = await remoteDataSource.canClaimReward(
        userId: userId,
        rewardId: reward.rewardId,
      );

      if (!canClaim) {
        return Left(ServerFailure('Reward cannot be claimed'));
      }

      final transaction = await remoteDataSource.claimReward(
        userId: userId,
        reward: reward,
        metadata: metadata,
      );

      return Right(transaction);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canClaimReward({
    required String userId,
    required String rewardId,
  }) async {
    try {
      final canClaim = await remoteDataSource.canClaimReward(
        userId: userId,
        rewardId: rewardId,
      );
      return Right(canClaim);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ClaimedReward>>> getClaimedRewards(
      String userId) async {
    try {
      final rewards = await remoteDataSource.getClaimedRewards(userId);
      return Right(rewards);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CoinTransaction>> purchaseFeature({
    required String userId,
    required String featureName,
    required int cost,
    String? relatedId,
  }) async {
    try {
      // Get reason from feature name
      final reason = _getReasonFromFeature(featureName);

      await remoteDataSource.updateBalance(
        userId: userId,
        amount: cost,
        type: CoinTransactionType.debit,
        reason: reason,
        relatedId: relatedId,
        metadata: {'feature': featureName},
      );

      // Get the transaction
      final transactions = await remoteDataSource.getTransactionHistory(
        userId: userId,
        limit: 1,
      );

      return Right(transactions.first);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canAffordFeature({
    required String userId,
    required int cost,
  }) async {
    try {
      final balance = await remoteDataSource.getBalance(userId);
      return Right(balance.availableCoins >= cost);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  CoinTransactionReason _getReasonFromFeature(String featureName) {
    switch (featureName.toLowerCase()) {
      case 'superlike':
      case 'super_like':
        return CoinTransactionReason.superLikePurchase;
      case 'boost':
        return CoinTransactionReason.boostPurchase;
      case 'undo':
        return CoinTransactionReason.undoPurchase;
      case 'see_who_liked_you':
      case 'seewholikedyou':
        return CoinTransactionReason.seeWhoLikedYouPurchase;
      default:
        return CoinTransactionReason.featurePurchase;
    }
  }

  @override
  Future<Either<Failure, CoinGift>> sendGift({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
  }) async {
    try {
      // Validate amount
      if (!CoinGiftConstraints.isValidAmount(amount)) {
        return Left(ServerFailure(
          'Gift amount must be between ${CoinGiftConstraints.minAmount} and ${CoinGiftConstraints.maxAmount}',
        ));
      }

      // Check if sender has enough coins
      final balance = await remoteDataSource.getBalance(senderId);
      if (balance.availableCoins < amount) {
        return Left(ServerFailure('Insufficient coins'));
      }

      final gift = await remoteDataSource.sendGift(
        senderId: senderId,
        receiverId: receiverId,
        amount: amount,
        message: message,
      );

      return Right(gift);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptGift({
    required String giftId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.acceptGift(giftId: giftId, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> declineGift({
    required String giftId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.declineGift(giftId: giftId, userId: userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CoinGift>>> getPendingGifts(String userId) async {
    try {
      final gifts = await remoteDataSource.getPendingGifts(userId);
      return Right(gifts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CoinGift>>> getSentGifts(String userId) async {
    try {
      final gifts = await remoteDataSource.getSentGifts(userId);
      return Right(gifts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> grantMonthlyAllowance({
    required String userId,
    required int amount,
    required String tier,
  }) async {
    try {
      await remoteDataSource.grantMonthlyAllowance(
        userId: userId,
        amount: amount,
        tier: tier,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> hasReceivedMonthlyAllowance({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final hasReceived = await remoteDataSource.hasReceivedMonthlyAllowance(
        userId: userId,
        year: year,
        month: month,
      );
      return Right(hasReceived);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> processExpiredCoins(String userId) async {
    try {
      await remoteDataSource.processExpiredCoins(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CoinBatch>>> getExpiringCoins({
    required String userId,
    required int days,
  }) async {
    try {
      final batches = await remoteDataSource.getExpiringCoins(
        userId: userId,
        days: days,
      );
      return Right(batches);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CoinPromotion>>> getActivePromotions() async {
    try {
      final promotions = await remoteDataSource.getActivePromotions();
      return Right(promotions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CoinPromotion?>> getPromotionByCode(String code) async {
    try {
      final promotion = await remoteDataSource.getPromotionByCode(code);
      return Right(promotion);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isPromotionApplicable({
    required String promotionId,
    required String userId,
  }) async {
    try {
      // Check if promotion is active
      final promotions = await remoteDataSource.getActivePromotions();
      final promotion = promotions.where((p) => p.promotionId == promotionId).firstOrNull;

      if (promotion == null) {
        return const Right(false);
      }

      // Check first purchase promotion
      if (promotion.type == PromotionType.firstPurchase) {
        final transactions = await remoteDataSource.getTransactionHistory(
          userId: userId,
          limit: 1,
        );
        // Applicable if no previous purchases
        return Right(transactions.isEmpty);
      }

      return Right(promotion.isCurrentlyActive);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
