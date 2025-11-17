/**
 * Get Seasonal Event Use Case
 * Point 200: Get active seasonal events with themed UI
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_challenge.dart';
import '../repositories/gamification_repository.dart';

class GetSeasonalEvent implements UseCase<SeasonalEventData, String> {
  final GamificationRepository repository;

  GetSeasonalEvent(this.repository);

  @override
  Future<Either<Failure, SeasonalEventData>> call(String userId) async {
    // Get active seasonal event
    final eventResult = await repository.getActiveSeasonalEvent();

    if (eventResult.isLeft()) {
      return Left(eventResult.fold((l) => l, (r) => throw Exception()));
    }

    final event = eventResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // No active event
    if (event == null) {
      return Right(SeasonalEventData(
        hasActiveEvent: false,
        event: null,
        challenges: [],
        themeConfig: null,
        daysRemaining: 0,
      ));
    }

    // Get seasonal challenges
    final challengesResult = await repository.getSeasonalChallenges(
      userId,
      event.eventId,
    );

    if (challengesResult.isLeft()) {
      return Left(challengesResult.fold((l) => l, (r) => throw Exception()));
    }

    final challenges = challengesResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Get user's progress on seasonal challenges
    final progressResult = await repository.getChallengeProgress(userId);

    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final allProgress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Map progress to challenges
    final progressMap = {
      for (var p in allProgress) p.challengeId: p,
    };

    final challengesWithProgress = challenges.map((challenge) {
      final progress = progressMap[challenge.challengeId];
      return SeasonalChallengeWithProgress(
        challenge: challenge,
        progress: progress,
      );
    }).toList();

    // Get theme config (Point 200)
    final themeResult = await repository.getSeasonalThemeConfig();

    final themeConfig = themeResult.fold(
      (l) => event.themeConfig,
      (r) => r,
    );

    // Calculate days remaining
    final now = DateTime.now();
    final daysRemaining = event.endDate.difference(now).inDays;

    // Calculate statistics
    final totalChallenges = challengesWithProgress.length;
    final completedChallenges =
        challengesWithProgress.where((c) => c.isCompleted).length;

    return Right(SeasonalEventData(
      hasActiveEvent: true,
      event: event,
      challenges: challengesWithProgress,
      themeConfig: themeConfig,
      daysRemaining: daysRemaining,
      totalChallenges: totalChallenges,
      completedChallenges: completedChallenges,
    ));
  }
}

class SeasonalChallengeWithProgress {
  final DailyChallenge challenge;
  final UserChallengeProgress? progress;

  SeasonalChallengeWithProgress({
    required this.challenge,
    this.progress,
  });

  bool get isCompleted => progress?.isCompleted ?? false;
  bool get canClaim => progress?.canClaim ?? false;
  int get currentProgress => progress?.progress ?? 0;
  double get progressPercentage => progress?.progressPercentage ?? 0.0;
}

class SeasonalEventData {
  final bool hasActiveEvent;
  final SeasonalEvent? event;
  final List<SeasonalChallengeWithProgress> challenges;
  final Map<String, dynamic>? themeConfig;
  final int daysRemaining;
  final int totalChallenges;
  final int completedChallenges;

  SeasonalEventData({
    required this.hasActiveEvent,
    required this.event,
    required this.challenges,
    required this.themeConfig,
    required this.daysRemaining,
    this.totalChallenges = 0,
    this.completedChallenges = 0,
  });

  /// Get theme colors
  int? get primaryColor => themeConfig?['primaryColor'] as int?;
  int? get accentColor => themeConfig?['accentColor'] as int?;
  String? get iconSet => themeConfig?['iconSet'] as String?;
  String? get backgroundPattern => themeConfig?['backgroundPattern'] as String?;
}
