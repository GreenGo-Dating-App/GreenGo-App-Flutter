import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_promotion.dart';
import '../repositories/coin_repository.dart';

/// Get Active Promotions Use Case
/// Point 165: Get promotional campaigns with bonus percentages
class GetActivePromotions {
  final CoinRepository repository;

  GetActivePromotions(this.repository);

  Future<Either<Failure, List<CoinPromotion>>> call() async {
    return await repository.getActivePromotions();
  }
}

/// Get Promotion by Code Use Case
class GetPromotionByCode {
  final CoinRepository repository;

  GetPromotionByCode(this.repository);

  Future<Either<Failure, CoinPromotion?>> call(String code) async {
    return await repository.getPromotionByCode(code);
  }
}

/// Check if Promotion is Applicable Use Case
class IsPromotionApplicable {
  final CoinRepository repository;

  IsPromotionApplicable(this.repository);

  Future<Either<Failure, bool>> call({
    required String promotionId,
    required String userId,
  }) async {
    return await repository.isPromotionApplicable(
      promotionId: promotionId,
      userId: userId,
    );
  }
}
