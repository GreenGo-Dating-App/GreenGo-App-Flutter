import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
///
/// Delegates in-memory caching to the singleton datasource (5-min TTL).
/// forceRefresh=true bypasses cache — used on pull-to-refresh and traveler activation.
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;

  // Queue size for discovery profiles
  static const int queueSize = 20;
  static const int prefetchThreshold = 5;

  DiscoveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MatchCandidate>>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final candidates = await remoteDataSource.getDiscoveryStack(
        userId: userId,
        preferences: preferences,
        limit: queueSize,
        forceRefresh: forceRefresh,
      );

      debugPrint('✅ Discovery stack: ${candidates.length} profiles (forceRefresh=$forceRefresh)');
      return Right(candidates);
    } on ServerException catch (e) {
      debugPrint('ServerException in getDiscoveryStack: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getDiscoveryStack: $e');
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
    } on ServerException catch (e) {
      debugPrint('❌ recordSwipe ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('❌ recordSwipe error: $e');
      return Left(ServerFailure(e.toString()));
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

  @override
  Future<Either<Failure, void>> undoSwipe({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      await remoteDataSource.undoSwipe(
        userId: userId,
        targetUserId: targetUserId,
      );
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
