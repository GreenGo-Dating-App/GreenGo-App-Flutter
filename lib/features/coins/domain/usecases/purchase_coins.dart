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
    required String purchaseToken,
    required String verificationData,
    CoinPromotion? promotion,
  }) async {
    return repository.purchaseCoins(
      userId: userId,
      package: package,
      platform: platform,
      purchaseToken: purchaseToken,
      verificationData: verificationData,
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

// NOTE: the old `VerifyCoinPurchase` use case was removed. Receipt verification
// is no longer a separate client step that returns a bool — it is inseparable
// from crediting the coins and happens entirely inside the
// verifyGooglePlayCoinPurchase / verifyAppStoreCoinPurchase Cloud Functions,
// reached via `PurchaseCoins`.
