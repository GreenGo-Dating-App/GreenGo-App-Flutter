/**
 * Gamification Events
 * Points 176-200: All gamification-related events
 */

import 'package:equatable/equatable.dart';
import '../../domain/repositories/gamification_repository.dart';

abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

// ===== Achievement Events =====

class LoadUserAchievements extends GamificationEvent {
  final String userId;

  const LoadUserAchievements(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnlockAchievementEvent extends GamificationEvent {
  final String userId;
  final String achievementId;

  const UnlockAchievementEvent({
    required this.userId,
    required this.achievementId,
  });

  @override
  List<Object?> get props => [userId, achievementId];
}

class TrackAchievementProgressEvent extends GamificationEvent {
  final String userId;
  final String achievementId;
  final int incrementBy;

  const TrackAchievementProgressEvent({
    required this.userId,
    required this.achievementId,
    this.incrementBy = 1,
  });

  @override
  List<Object?> get props => [userId, achievementId, incrementBy];
}

// ===== Level & XP Events =====

class LoadUserLevel extends GamificationEvent {
  final String userId;

  const LoadUserLevel(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GrantXPEvent extends GamificationEvent {
  final String userId;
  final int xpAmount;
  final String reason;

  const GrantXPEvent({
    required this.userId,
    required this.xpAmount,
    required this.reason,
  });

  @override
  List<Object?> get props => [userId, xpAmount, reason];
}

class LoadXPHistory extends GamificationEvent {
  final String userId;

  const LoadXPHistory(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadLeaderboard extends GamificationEvent {
  final String? userId;
  final LeaderboardType type;
  final String? region;
  final int limit;

  const LoadLeaderboard({
    this.userId,
    this.type = LeaderboardType.global,
    this.region,
    this.limit = 100,
  });

  @override
  List<Object?> get props => [userId, type, region, limit];
}

class ClaimLevelRewardsEvent extends GamificationEvent {
  final String userId;
  final int level;

  const ClaimLevelRewardsEvent({
    required this.userId,
    required this.level,
  });

  @override
  List<Object?> get props => [userId, level];
}

class CheckFeatureUnlockEvent extends GamificationEvent {
  final String userId;
  final String featureId;

  const CheckFeatureUnlockEvent({
    required this.userId,
    required this.featureId,
  });

  @override
  List<Object?> get props => [userId, featureId];
}

// ===== Challenge Events =====

class LoadDailyChallenges extends GamificationEvent {
  final String userId;

  const LoadDailyChallenges(this.userId);

  @override
  List<Object?> get props => [userId];
}

class TrackChallengeProgressEvent extends GamificationEvent {
  final String userId;
  final String challengeId;
  final int incrementBy;

  const TrackChallengeProgressEvent({
    required this.userId,
    required this.challengeId,
    this.incrementBy = 1,
  });

  @override
  List<Object?> get props => [userId, challengeId, incrementBy];
}

class ClaimChallengeRewardEvent extends GamificationEvent {
  final String userId;
  final String challengeId;

  const ClaimChallengeRewardEvent({
    required this.userId,
    required this.challengeId,
  });

  @override
  List<Object?> get props => [userId, challengeId];
}

// ===== Seasonal Event Events =====

class LoadSeasonalEvent extends GamificationEvent {
  final String userId;

  const LoadSeasonalEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ApplySeasonalTheme extends GamificationEvent {
  const ApplySeasonalTheme();
}
