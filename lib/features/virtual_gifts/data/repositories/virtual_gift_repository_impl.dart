import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/virtual_gift.dart';
import '../../domain/repositories/virtual_gift_repository.dart';
import '../datasources/virtual_gift_remote_datasource.dart';

/// Virtual Gift Repository Implementation
class VirtualGiftRepositoryImpl implements VirtualGiftRepository {
  final VirtualGiftRemoteDataSource remoteDataSource;

  VirtualGiftRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VirtualGift>>> getGiftCatalog() async {
    try {
      final gifts = await remoteDataSource.getGiftCatalog();
      return Right(gifts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VirtualGift>>> getGiftsByCategory(
      String category) async {
    try {
      final gifts = await remoteDataSource.getGiftsByCategory(category);
      return Right(gifts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VirtualGift>> getGiftById(String giftId) async {
    try {
      final gift = await remoteDataSource.getGiftById(giftId);
      return Right(gift);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SentVirtualGift>> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String giftId,
    String? message,
  }) async {
    try {
      final sentGift = await remoteDataSource.sendGift(
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        receiverName: receiverName,
        giftId: giftId,
        message: message,
      );
      return Right(sentGift);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SentVirtualGift>>> getReceivedGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  }) async {
    try {
      final gifts = await remoteDataSource.getReceivedGifts(
        userId: userId,
        limit: limit,
        lastGiftId: lastGiftId,
      );
      return Right(gifts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<SentVirtualGift>>> streamReceivedGifts(
      String userId) {
    return remoteDataSource.streamReceivedGifts(userId).map((gifts) {
      return Right<Failure, List<SentVirtualGift>>(gifts);
    }).handleError((e) {
      return Left<Failure, List<SentVirtualGift>>(ServerFailure(e.toString()));
    });
  }

  @override
  Future<Either<Failure, List<SentVirtualGift>>> getSentGifts({
    required String userId,
    int limit = 20,
    String? lastGiftId,
  }) async {
    try {
      final gifts = await remoteDataSource.getSentGifts(
        userId: userId,
        limit: limit,
        lastGiftId: lastGiftId,
      );
      return Right(gifts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markGiftViewed(String giftId) async {
    try {
      await remoteDataSource.markGiftViewed(giftId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GiftStats>> getGiftStats(String userId) async {
    try {
      final stats = await remoteDataSource.getGiftStats(userId);
      return Right(stats);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnviewedGiftCount(String userId) async {
    try {
      final count = await remoteDataSource.getUnviewedGiftCount(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
