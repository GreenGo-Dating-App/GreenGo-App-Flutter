import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../profile/domain/entities/profile.dart';
import '../entities/match_candidate.dart';
import '../entities/match_preferences.dart';
import '../entities/match_score.dart';
import '../entities/user_vector.dart';

/// Matching Repository Interface
///
/// Defines the contract for matching operations.
abstract class MatchingRepository {
  /// Get match candidates for a user
  Future<Either<Failure, List<MatchCandidate>>> getMatchCandidates({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  /// Calculate compatibility score between two users
  Future<Either<Failure, MatchScore>> calculateCompatibility({
    required String userId1,
    required String userId2,
  });

  /// Get user vector for ML matching
  Future<Either<Failure, UserVector>> getUserVector({
    required String userId,
  });

  /// Create user vector from profile
  Future<Either<Failure, UserVector>> createUserVector({
    required Profile profile,
  });

  /// Update user vector (called when profile changes)
  Future<Either<Failure, void>> updateUserVector({
    required String userId,
    required UserVector vector,
  });

  /// Get match preferences for a user
  Future<Either<Failure, MatchPreferences>> getMatchPreferences({
    required String userId,
  });

  /// Update match preferences
  Future<Either<Failure, void>> updateMatchPreferences({
    required MatchPreferences preferences,
  });

  /// Get candidates using hybrid matching (collaborative + content-based)
  Future<Either<Failure, List<MatchCandidate>>> getHybridMatches({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  /// Get candidates using collaborative filtering
  Future<Either<Failure, List<MatchCandidate>>> getCollaborativeMatches({
    required String userId,
    int limit = 20,
  });

  /// Get candidates using content-based filtering
  Future<Either<Failure, List<MatchCandidate>>> getContentBasedMatches({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  /// Record match interaction (for collaborative filtering training)
  Future<Either<Failure, void>> recordInteraction({
    required String userId,
    required String targetUserId,
    required InteractionType interactionType,
  });
}

/// Types of user interactions for collaborative filtering
enum InteractionType {
  like,
  pass,
  superLike,
  match,
  message,
  unmatch,
  block,
  report,
}
