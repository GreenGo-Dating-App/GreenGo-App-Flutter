import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/virtual_gift.dart';
import '../repositories/virtual_gift_repository.dart';

/// Get gift catalog
class GetGiftCatalog {

  GetGiftCatalog(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, List<VirtualGift>>> call() {
    return repository.getGiftCatalog();
  }
}

/// Get gifts by category
class GetGiftsByCategory {

  GetGiftsByCategory(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, List<VirtualGift>>> call(String category) {
    return repository.getGiftsByCategory(category);
  }
}

/// Get gift by ID
class GetGiftById {

  GetGiftById(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, VirtualGift>> call(String giftId) {
    return repository.getGiftById(giftId);
  }
}

/// Send a virtual gift
class SendVirtualGift {

  SendVirtualGift(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, SentVirtualGift>> call({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String giftId,
    String? message,
  }) {
    return repository.sendGift(
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      receiverName: receiverName,
      giftId: giftId,
      message: message,
    );
  }
}

/// Get received gifts
class GetReceivedGifts {

  GetReceivedGifts(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, List<SentVirtualGift>>> call({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  }) {
    return repository.getReceivedGifts(
      userId: userId,
      limit: limit,
      lastGiftId: lastGiftId,
    );
  }

  Stream<Either<Failure, List<SentVirtualGift>>> stream(String userId) {
    return repository.streamReceivedGifts(userId);
  }
}

/// Get sent gifts
class GetSentGifts {

  GetSentGifts(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, List<SentVirtualGift>>> call({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  }) {
    return repository.getSentGifts(
      userId: userId,
      limit: limit,
      lastGiftId: lastGiftId,
    );
  }
}

/// Mark gift as viewed
class MarkGiftViewed {

  MarkGiftViewed(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, void>> call(String giftId) {
    return repository.markGiftViewed(giftId);
  }
}

/// Get gift statistics
class GetGiftStats {

  GetGiftStats(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, GiftStats>> call(String userId) {
    return repository.getGiftStats(userId);
  }
}

/// Get unviewed gift count
class GetUnviewedGiftCount {

  GetUnviewedGiftCount(this.repository);
  final VirtualGiftRepository repository;

  Future<Either<Failure, int>> call(String userId) {
    return repository.getUnviewedGiftCount(userId);
  }
}
