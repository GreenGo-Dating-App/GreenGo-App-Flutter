import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_gift.dart';
import '../repositories/coin_repository.dart';

/// Send Coin Gift Use Case
/// Point 162: Send coins to matches
class SendCoinGift {

  SendCoinGift(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, CoinGift>> call({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
  }) async {
    return repository.sendGift(
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      message: message,
    );
  }
}

/// Accept Coin Gift Use Case
class AcceptCoinGift {

  AcceptCoinGift(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, void>> call({
    required String giftId,
    required String userId,
  }) async {
    return repository.acceptGift(
      giftId: giftId,
      userId: userId,
    );
  }
}

/// Decline Coin Gift Use Case
class DeclineCoinGift {

  DeclineCoinGift(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, void>> call({
    required String giftId,
    required String userId,
  }) async {
    return repository.declineGift(
      giftId: giftId,
      userId: userId,
    );
  }
}

/// Get Pending Gifts Use Case
class GetPendingGifts {

  GetPendingGifts(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, List<CoinGift>>> call(String userId) async {
    return repository.getPendingGifts(userId);
  }
}

/// Get Sent Gifts Use Case
class GetSentGifts {

  GetSentGifts(this.repository);
  final CoinRepository repository;

  Future<Either<Failure, List<CoinGift>>> call(String userId) async {
    return repository.getSentGifts(userId);
  }
}
