import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_gift.dart';
import '../repositories/coin_repository.dart';

/// Send Coin Gift Use Case
/// Point 162: Send coins to matches
class SendCoinGift {
  final CoinRepository repository;

  SendCoinGift(this.repository);

  Future<Either<Failure, CoinGift>> call({
    required String senderId,
    required String receiverId,
    required int amount,
    String? message,
  }) async {
    return await repository.sendGift(
      senderId: senderId,
      receiverId: receiverId,
      amount: amount,
      message: message,
    );
  }
}

/// Accept Coin Gift Use Case
class AcceptCoinGift {
  final CoinRepository repository;

  AcceptCoinGift(this.repository);

  Future<Either<Failure, void>> call({
    required String giftId,
    required String userId,
  }) async {
    return await repository.acceptGift(
      giftId: giftId,
      userId: userId,
    );
  }
}

/// Decline Coin Gift Use Case
class DeclineCoinGift {
  final CoinRepository repository;

  DeclineCoinGift(this.repository);

  Future<Either<Failure, void>> call({
    required String giftId,
    required String userId,
  }) async {
    return await repository.declineGift(
      giftId: giftId,
      userId: userId,
    );
  }
}

/// Get Pending Gifts Use Case
class GetPendingGifts {
  final CoinRepository repository;

  GetPendingGifts(this.repository);

  Future<Either<Failure, List<CoinGift>>> call(String userId) async {
    return await repository.getPendingGifts(userId);
  }
}

/// Get Sent Gifts Use Case
class GetSentGifts {
  final CoinRepository repository;

  GetSentGifts(this.repository);

  Future<Either<Failure, List<CoinGift>>> call(String userId) async {
    return await repository.getSentGifts(userId);
  }
}
