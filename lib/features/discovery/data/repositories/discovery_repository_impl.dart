import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../domain/entities/match_preferences.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

/// Discovery Repository Implementation
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;

  DiscoveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MatchCandidate>>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    try {
      final candidates = await remoteDataSource.getDiscoveryStack(
        userId: userId,
        preferences: preferences,
        limit: limit,
      );
      return Right(candidates);
    } on ServerException catch (e) {
      print('ServerException in getDiscoveryStack: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      print('Error in getDiscoveryStack: $e');
      // Return empty list instead of error if it's just "no profiles found"
      if (e.toString().contains('User profile not found')) {
        return const Right([]);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SwipeAction>> recordSwipe({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
  }) async {
    try {
      final action = await remoteDataSource.recordSwipe(
        userId: userId,
        targetUserId: targetUserId,
        actionType: actionType,
      );
      return Right(action);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Match?>> checkForMatch({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final match = await remoteDataSource.checkForMatch(
        userId: userId,
        targetUserId: targetUserId,
      );
      return Right(match);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Match>>> getMatches({
    required String userId,
    bool activeOnly = true,
  }) async {
    try {
      final matches = await remoteDataSource.getMatches(
        userId: userId,
        activeOnly: activeOnly,
      );
      return Right(matches);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, (Match, Profile)>> getMatchWithProfile({
    required String matchId,
    required String currentUserId,
  }) async {
    try {
      final result = await remoteDataSource.getMatchWithProfile(
        matchId: matchId,
        currentUserId: currentUserId,
      );
      return Right(result);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markMatchAsSeen({
    required String matchId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.markMatchAsSeen(
        matchId: matchId,
        userId: userId,
      );
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> unmatch({
    required String matchId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.unmatch(matchId: matchId, userId: userId);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> getUserLikes({
    required String userId,
  }) async {
    try {
      final likes = await remoteDataSource.getUserLikes(userId);
      return Right(likes);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<Profile>>> getWhoLikedMe({
    required String userId,
  }) async {
    try {
      final profiles = await remoteDataSource.getWhoLikedMe(userId);
      return Right(profiles);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> hasSwipedOn({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final hasSwiped = await remoteDataSource.hasSwipedOn(
        userId: userId,
        targetUserId: targetUserId,
      );
      return Right(hasSwiped);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
