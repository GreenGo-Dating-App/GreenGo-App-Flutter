import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/virtual_gift.dart';

/// Virtual Gift Repository Interface
abstract class VirtualGiftRepository {
  /// Get all available gifts (catalog)
  Future<Either<Failure, List<VirtualGift>>> getGiftCatalog();

  /// Get gifts by category
  Future<Either<Failure, List<VirtualGift>>> getGiftsByCategory(String category);

  /// Get a specific gift by ID
  Future<Either<Failure, VirtualGift>> getGiftById(String giftId);

  /// Send a gift to another user
  Future<Either<Failure, SentVirtualGift>> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String giftId,
    String? message,
  });

  /// Get received gifts for a user
  Future<Either<Failure, List<SentVirtualGift>>> getReceivedGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  });

  /// Stream received gifts for real-time updates
  Stream<Either<Failure, List<SentVirtualGift>>> streamReceivedGifts(
      String userId);

  /// Get sent gifts by a user
  Future<Either<Failure, List<SentVirtualGift>>> getSentGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  });

  /// Mark a gift as viewed
  Future<Either<Failure, void>> markGiftViewed(String giftId);

  /// Get gift statistics for a user
  Future<Either<Failure, GiftStats>> getGiftStats(String userId);

  /// Get unviewed gift count
  Future<Either<Failure, int>> getUnviewedGiftCount(String userId);
}
