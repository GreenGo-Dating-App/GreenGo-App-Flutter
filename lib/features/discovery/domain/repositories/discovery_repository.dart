import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../matching/domain/entities/match_candidate.dart';
import '../entities/match_preferences.dart';
import '../../../profile/domain/entities/profile.dart';
import '../entities/match.dart';
import '../entities/swipe_action.dart';

/// Discovery Repository Interface
abstract class DiscoveryRepository {
  /// Get discovery stack (potential matches for swiping)
  Future<Either<Failure, List<MatchCandidate>>> getDiscoveryStack({
    required String userId,
    required MatchPreferences preferences,
    int limit = 20,
  });

  /// Record a swipe action
  Future<Either<Failure, SwipeAction>> recordSwipe({
    required String userId,
    required String targetUserId,
    required SwipeActionType actionType,
  });

  /// Check if swipe creates a match
  Future<Either<Failure, Match?>> checkForMatch({
    required String userId,
    required String targetUserId,
  });

  /// Get user's matches
  Future<Either<Failure, List<Match>>> getMatches({
    required String userId,
    bool activeOnly = true,
  });

  /// Get match with profile data
  Future<Either<Failure, (Match, Profile)>> getMatchWithProfile({
    required String matchId,
    required String currentUserId,
  });

  /// Mark match as seen by user
  Future<Either<Failure, void>> markMatchAsSeen({
    required String matchId,
    required String userId,
  });

  /// Unmatch with a user
  Future<Either<Failure, void>> unmatch({
    required String matchId,
    required String userId,
  });

  /// Get user's likes (profiles they liked)
  Future<Either<Failure, List<String>>> getUserLikes({
    required String userId,
  });

  /// Get users who liked current user
  Future<Either<Failure, List<Profile>>> getWhoLikedMe({
    required String userId,
  });

  /// Check if user has already swiped on target
  Future<Either<Failure, bool>> hasSwipedOn({
    required String userId,
    required String targetUserId,
  });
}
