/**
 * Track Challenge Progress Use Case
 * Point 197: Track progress on daily and weekly challenges
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_challenge.dart';
import '../repositories/gamification_repository.dart';

class TrackChallengeProgress
    implements UseCase<ChallengeProgressResult, TrackChallengeProgressParams> {
  final GamificationRepository repository;

  TrackChallengeProgress(this.repository);

  @override
  Future<Either<Failure, ChallengeProgressResult>> call(
    TrackChallengeProgressParams params,
  ) async {
    // Update progress
    final progressResult = await repository.trackChallengeProgress(
      params.userId,
      params.challengeId,
      params.incrementBy,
    );

    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final progress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Check if challenge was just completed
    final wasJustCompleted = !progress.isCompleted &&
        progress.progress >= progress.requiredCount;

    DailyChallenge? challenge;
    if (wasJustCompleted) {
      // Get challenge details to show rewards
      final allDailyChallenges = DailyChallenges.getRotatingChallenges();
      final allWeeklyChallenges = WeeklyChallenges.getWeeklyChallenges();

      challenge = [...allDailyChallenges, ...allWeeklyChallenges].firstWhere(
        (c) => c.challengeId == params.challengeId,
        orElse: () => allDailyChallenges.first, // Fallback
      );
    }

    return Right(ChallengeProgressResult(
      progress: progress,
      wasCompleted: wasJustCompleted,
      challenge: challenge,
      canClaim: progress.canClaim,
    ));
  }
}

class TrackChallengeProgressParams {
  final String userId;
  final String challengeId;
  final int incrementBy;

  TrackChallengeProgressParams({
    required this.userId,
    required this.challengeId,
    this.incrementBy = 1,
  });

  /// Factory methods for common challenge actions
  factory TrackChallengeProgressParams.messageSent(String userId) {
    return TrackChallengeProgressParams(
      userId: userId,
      challengeId: 'send_messages',
      incrementBy: 1,
    );
  }

  factory TrackChallengeProgressParams.match(String userId) {
    return TrackChallengeProgressParams(
      userId: userId,
      challengeId: 'get_matches',
      incrementBy: 1,
    );
  }

  factory TrackChallengeProgressParams.videoCall(String userId) {
    return TrackChallengeProgressParams(
      userId: userId,
      challengeId: 'video_call',
      incrementBy: 1,
    );
  }

  factory TrackChallengeProgressParams.photoUpdated(String userId) {
    return TrackChallengeProgressParams(
      userId: userId,
      challengeId: 'update_photo',
      incrementBy: 1,
    );
  }

  factory TrackChallengeProgressParams.superLike(String userId) {
    return TrackChallengeProgressParams(
      userId: userId,
      challengeId: 'super_likes',
      incrementBy: 1,
    );
  }

  factory TrackChallengeProgressParams.profileView(String userId) {
    return TrackChallengeProgressParams(
      userId: userId,
      challengeId: 'profile_views',
      incrementBy: 1,
    );
  }
}

class ChallengeProgressResult {
  final UserChallengeProgress progress;
  final bool wasCompleted;
  final DailyChallenge? challenge;
  final bool canClaim;

  ChallengeProgressResult({
    required this.progress,
    required this.wasCompleted,
    this.challenge,
    required this.canClaim,
  });
}
