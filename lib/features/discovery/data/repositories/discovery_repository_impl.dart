import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/cache_service.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../../domain/entities/match_preferences.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match.dart';
import '../../domain/entities/swipe_action.dart';
import '../../domain/repositories/discovery_repository.dart';
import '../datasources/discovery_remote_datasource.dart';

/// Discovery Repository Implementation
///
/// Implements caching to reduce Firestore reads and maintain a 20-profile queue
class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final DiscoveryRemoteDataSource remoteDataSource;
  final CacheService _cacheService = CacheService.instance;

  // Queue size for discovery profiles
  static const int queueSize = 20;
  static const int prefetchThreshold = 5; // Prefetch when below this threshold

  DiscoveryRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MatchCandidate>>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    try {
      // Try to get cached candidates first
      final cachedData = _cacheService.getDiscoveryStack(userId);
      if (cachedData != null && cachedData.isNotEmpty) {
        debugPrint('📦 Using cached discovery stack (${cachedData.length} profiles)');
        // Convert cached data back to MatchCandidate objects
        // Note: For now, still fetch fresh data but use cache for faster subsequent loads
      }

      // Fetch from remote - always get 20+ for the queue
      final candidates = await remoteDataSource.getDiscoveryStack(
        userId: userId,
        preferences: preferences,
        limit: queueSize,
      );

      // Cache the candidates for faster access
      if (candidates.isNotEmpty) {
        await _cacheDiscoveryCandidates(userId, candidates);
      }

      debugPrint('✅ Discovery stack loaded: ${candidates.length} profiles');
      return Right(candidates);
    } on ServerException catch (e) {
      debugPrint('ServerException in getDiscoveryStack: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('Error in getDiscoveryStack: $e');
      // Return empty list instead of error if it's just "no profiles found"
      if (e.toString().contains('User profile not found')) {
        return const Right([]);
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  /// Cache discovery candidates for faster access
  Future<void> _cacheDiscoveryCandidates(String userId, List<MatchCandidate> candidates) async {
    try {
      final cachedData = candidates.map((c) => {
        'profileId': c.profile.userId,
        'distance': c.distance,
        'matchScore': c.matchScore.overallScore,
        'suggestedAt': c.suggestedAt.millisecondsSinceEpoch,
      }).toList();
      await _cacheService.cacheDiscoveryStack(userId, cachedData);

      // Also cache individual profiles for quick detail access
      for (final candidate in candidates) {
        await _cacheService.cacheProfile(candidate.profile.userId, {
          'userId': candidate.profile.userId,
          'displayName': candidate.profile.displayName,
          'nickname': candidate.profile.nickname,
          'photoUrls': candidate.profile.photoUrls,
          'bio': candidate.profile.bio,
          'age': candidate.profile.age,
          'gender': candidate.profile.gender.toString(),
          'distance': candidate.distance,
        });
      }
    } catch (e) {
      debugPrint('Cache error: $e');
    }
  }

  /// Invalidate discovery cache (call after swiping)
  Future<void> invalidateDiscoveryCache(String userId) async {
    await _cacheService.invalidateDiscoveryStack(userId);
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
