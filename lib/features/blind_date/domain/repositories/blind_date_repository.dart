import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/blind_date.dart';

/// Blind Date Repository Interface
abstract class BlindDateRepository {
  /// Create a blind date profile from existing user profile
  Future<Either<Failure, BlindDateProfile>> createBlindProfile(String userId);

  /// Get user's blind date profile
  Future<Either<Failure, BlindDateProfile?>> getBlindProfile(String userId);

  /// Deactivate blind date profile
  Future<Either<Failure, void>> deactivateBlindProfile(String userId);

  /// Get blind date candidates for swiping
  Future<Either<Failure, List<BlindProfileView>>> getBlindCandidates({
    required String userId,
    int limit = 10,
  });

  /// Like a blind profile (returns match if mutual)
  Future<Either<Failure, BlindLikeResult>> likeBlindProfile({
    required String userId,
    required String targetUserId,
  });

  /// Pass on a blind profile
  Future<Either<Failure, void>> passBlindProfile({
    required String userId,
    required String targetUserId,
  });

  /// Get user's blind matches
  Future<Either<Failure, List<BlindMatch>>> getBlindMatches(String userId);

  /// Stream blind matches for real-time updates
  Stream<Either<Failure, List<BlindMatch>>> streamBlindMatches(String userId);

  /// Instant reveal photos (costs coins)
  Future<Either<Failure, BlindMatch>> instantReveal({
    required String userId,
    required String matchId,
  });

  /// Check if reveal threshold is met
  Future<Either<Failure, bool>> checkRevealStatus(String matchId);

  /// Update message count for a blind match
  Future<Either<Failure, BlindMatch>> updateMessageCount({
    required String matchId,
    required int newCount,
  });

  /// Get revealed profile for a match
  Future<Either<Failure, BlindProfileView>> getRevealedProfile({
    required String matchId,
    required String userId,
  });
}
