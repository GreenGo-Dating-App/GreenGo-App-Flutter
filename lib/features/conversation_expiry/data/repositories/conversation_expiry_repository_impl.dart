import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/conversation_expiry.dart';
import '../../domain/repositories/conversation_expiry_repository.dart';
import '../datasources/conversation_expiry_remote_datasource.dart';

/// Implementation of conversation expiry repository
class ConversationExpiryRepositoryImpl implements ConversationExpiryRepository {
  final ConversationExpiryRemoteDataSource remoteDataSource;

  ConversationExpiryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ConversationExpiry?>> getExpiry(
    String conversationId,
  ) async {
    try {
      final expiry = await remoteDataSource.getExpiry(conversationId);
      return Right(expiry);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConversationExpiry>>> getUserExpiries(
    String userId,
  ) async {
    try {
      final expiries = await remoteDataSource.getUserExpiries(userId);
      return Right(expiries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ConversationExpiry>>> getExpiringSoon(
    String userId, {
    int withinHours = 24,
  }) async {
    try {
      final expiries = await remoteDataSource.getExpiringSoon(
        userId,
        withinHours: withinHours,
      );
      return Right(expiries);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExtensionResult>> extendConversation({
    required String conversationId,
    required String userId,
  }) async {
    try {
      final result = await remoteDataSource.extendConversation(
        conversationId: conversationId,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, ConversationExpiry>> streamExpiry(
    String conversationId,
  ) {
    return remoteDataSource
        .streamExpiry(conversationId)
        .map((expiry) => Right<Failure, ConversationExpiry>(expiry));
  }

  @override
  Future<Either<Failure, ConversationExpiry>> recordActivity(
    String conversationId,
  ) async {
    try {
      final expiry = await remoteDataSource.recordActivity(conversationId);
      return Right(expiry);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isExpired(String conversationId) async {
    try {
      final expired = await remoteDataSource.isExpired(conversationId);
      return Right(expired);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
