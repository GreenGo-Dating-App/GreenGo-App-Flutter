import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_package.dart';
import '../entities/coin_promotion.dart';
import '../entities/coin_transaction.dart';
import '../repositories/coin_repository.dart';

/// Purchase Coins Use Case
/// Point 157: Handle coin package purchases
class PurchaseCoins {

  PurchaseCoins(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, CoinTransaction>> call({
    required String userId,
    required CoinPackage package,
    required String platform,
    String? purchaseToken,
    CoinPromotion? promotion,
  }) async {
    return repository.purchaseCoins(
      userId: userId,
      package: package,
      platform: platform,
      purchaseToken: purchaseToken,
      promotion: promotion,
    );
  }
}

/// Get Available Coin Packages Use Case
class GetAvailablePackages {

  GetAvailablePackages(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, List<CoinPackage>>> call() async {
    return repository.getAvailablePackages();
  }
}

/// Verify Coin Purchase Use Case
class VerifyCoinPurchase {

  VerifyCoinPurchase(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, bool>> call({
    required String userId,
    required String purchaseToken,
    required String platform,
  }) async {
    return repository.verifyPurchase(
      userId: userId,
      purchaseToken: purchaseToken,
      platform: platform,
    );
  }
}
