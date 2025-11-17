import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/match_preferences.dart';
import '../../domain/entities/match_score.dart';
import '../../domain/entities/user_vector.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../domain/usecases/compatibility_scorer.dart';
import '../../domain/usecases/feature_engineer.dart';
import '../datasources/matching_remote_datasource.dart';

/// Matching Repository Implementation
///
/// Implements the matching repository interface with error handling
class MatchingRepositoryImpl implements MatchingRepository {
  final MatchingRemoteDataSource remoteDataSource;
  final FeatureEngineer featureEngineer;
  final CompatibilityScorer compatibilityScorer;

  MatchingRepositoryImpl({
    required this.remoteDataSource,
    FeatureEngineer? featureEngineer,
    CompatibilityScorer? compatibilityScorer,
  })  : featureEngineer = featureEngineer ?? FeatureEngineer(),
        compatibilityScorer = compatibilityScorer ?? CompatibilityScorer();

  @override
  Future<Either<Failure, List<MatchCandidate>>> getMatchCandidates({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    try {
      final candidates = await remoteDataSource.getMatchCandidates(
        userId: userId,
        preferences: preferences,
        limit: limit,
      );
      return Right(candidates);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, MatchScore>> calculateCompatibility({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // This would typically fetch both profiles and calculate
      // For now, returns a placeholder
      throw UnimplementedError('Direct compatibility calculation not yet implemented');
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserVector>> getUserVector({
    required String userId,
  }) async {
    try {
      final vector = await remoteDataSource.getUserVector(userId);
      return Right(vector);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, UserVector>> createUserVector({
    required Profile profile,
  }) async {
    try {
      final vector = featureEngineer.createVector(profile);
      await remoteDataSource.saveUserVector(vector);
      return Right(vector);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateUserVector({
    required String userId,
    required UserVector vector,
  }) async {
    try {
      await remoteDataSource.saveUserVector(vector);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, MatchPreferences>> getMatchPreferences({
    required String userId,
  }) async {
    try {
      final preferences = await remoteDataSource.getMatchPreferences(userId);
      return Right(preferences);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateMatchPreferences({
    required MatchPreferences preferences,
  }) async {
    try {
      await remoteDataSource.saveMatchPreferences(preferences);
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<MatchCandidate>>> getHybridMatches({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    // Hybrid matching combines content-based and collaborative filtering
    // For now, this delegates to getMatchCandidates which implements hybrid approach
    return getMatchCandidates(
      userId: userId,
      preferences: preferences,
      limit: limit,
    );
  }

  @override
  Future<Either<Failure, List<MatchCandidate>>> getCollaborativeMatches({
    required String userId,
    int limit = 20,
  }) async {
    try {
      // Collaborative filtering: Find users similar to those you've liked
      // TODO: Implement actual collaborative filtering algorithm
      // For now, returns empty as this is a placeholder
      return const Right([]);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<MatchCandidate>>> getContentBasedMatches({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  }) async {
    // Content-based filtering uses profile attributes
    // This is the main implementation in getMatchCandidates
    return getMatchCandidates(
      userId: userId,
      preferences: preferences,
      limit: limit,
    );
  }

  @override
  Future<Either<Failure, void>> recordInteraction({
    required String userId,
    required String targetUserId,
    required InteractionType interactionType,
  }) async {
    try {
      await remoteDataSource.recordInteraction(
        userId: userId,
        targetUserId: targetUserId,
        interactionType: interactionType,
      );
      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
