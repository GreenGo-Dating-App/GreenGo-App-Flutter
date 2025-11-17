import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_balance.dart';
import '../entities/coin_gift.dart';
import '../entities/coin_package.dart';
import '../entities/coin_promotion.dart';
import '../entities/coin_reward.dart';
import '../entities/coin_transaction.dart';

/// Coin Repository Interface
/// Handles all coin-related operations
abstract class CoinRepository {
  // Balance Operations
  Future<Either<Failure, CoinBalance>> getBalance(String userId);
  Stream<Either<Failure, CoinBalance>> balanceStream(String userId);
  Future<Either<Failure, void>> updateBalance({
    required String userId,
    required int amount,
    required CoinTransactionType type,
    required CoinTransactionReason reason,
    String? relatedId,
    String? relatedUserId,
    Map<String, dynamic>? metadata,
  });

  // Purchase Operations (Point 157)
  Future<Either<Failure, List<CoinPackage>>> getAvailablePackages();
  Future<Either<Failure, CoinTransaction>> purchaseCoins({
    required String userId,
    required CoinPackage package,
    required String platform,
    String? purchaseToken,
    CoinPromotion? promotion,
  });
  Future<Either<Failure, bool>> verifyPurchase({
    required String userId,
    required String purchaseToken,
    required String platform,
  });

  // Transaction Operations (Point 159)
  Future<Either<Failure, List<CoinTransaction>>> getTransactionHistory({
    required String userId,
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  });
  Stream<Either<Failure, List<CoinTransaction>>> transactionStream({
    required String userId,
    int limit,
  });

  // Reward Operations (Point 160)
  Future<Either<Failure, CoinTransaction>> claimReward({
    required String userId,
    required CoinReward reward,
    Map<String, dynamic>? metadata,
  });
  Future<Either<Failure, bool>> canClaimReward({
    required String userId,
    required String rewardId,
  });
  Future<Either<Failure, List<ClaimedReward>>> getClaimedRewards(String userId);

  // Feature Purchase Operations (Point 161)
  Future<Either<Failure, CoinTransaction>> purchaseFeature({
    required String userId,
    required String featureName,
    required int cost,
    String? relatedId,
  });
  Future<Either<Failure, bool>> canAffordFeature({
    required String userId,
    required int cost,
  });

  // Gift Operations (Point 162)
  Future<Either<Failure, CoinGift>> sendGift({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
  });
  Future<Either<Failure, void>> acceptGift({
    required String giftId,
    required String userId,
  });
  Future<Either<Failure, void>> declineGift({
    required String giftId,
    required String userId,
  });
  Future<Either<Failure, List<CoinGift>>> getPendingGifts(String userId);
  Future<Either<Failure, List<CoinGift>>> getSentGifts(String userId);

  // Allowance Operations (Point 163)
  Future<Either<Failure, void>> grantMonthlyAllowance({
    required String userId,
    required int amount,
    required String tier,
  });
  Future<Either<Failure, bool>> hasReceivedMonthlyAllowance({
    required String userId,
    required int year,
    required int month,
  });

  // Expiration Operations (Point 164)
  Future<Either<Failure, void>> processExpiredCoins(String userId);
  Future<Either<Failure, List<CoinBatch>>> getExpiringCoins({
    required String userId,
    required int days,
  });

  // Promotion Operations (Point 165)
  Future<Either<Failure, List<CoinPromotion>>> getActivePromotions();
  Future<Either<Failure, CoinPromotion?>> getPromotionByCode(String code);
  Future<Either<Failure, bool>> isPromotionApplicable({
    required String promotionId,
    required String userId,
  });
}
