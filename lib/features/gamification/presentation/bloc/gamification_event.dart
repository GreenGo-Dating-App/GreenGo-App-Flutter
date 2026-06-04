/// Gamification Events
/// Points 176-200: All gamification-related events
library;

import 'package:equatable/equatable.dart';
import '../../domain/repositories/gamification_repository.dart';

abstract class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

// ===== Achievement Events =====

class LoadUserAchievements extends GamificationEvent {

  const LoadUserAchievements(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class UnlockAchievementEvent extends GamificationEvent {

  const UnlockAchievementEvent({
    required this.userId,
    required this.achievementId,
  });
  final String userId;
  final String achievementId;

  @override
  List<Object?> get props => [userId, achievementId];
}

class TrackAchievementProgressEvent extends GamificationEvent {

  const TrackAchievementProgressEvent({
    required this.userId,
    required this.achievementId,
    this.incrementBy = 1,
  });
  final String userId;
  final String achievementId;
  final int incrementBy;

  @override
  List<Object?> get props => [userId, achievementId, incrementBy];
}

// ===== Level & XP Events =====

class LoadUserLevel extends GamificationEvent {

  const LoadUserLevel(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class GrantXPEvent extends GamificationEvent {

  const GrantXPEvent({
    required this.userId,
    required this.xpAmount,
    required this.reason,
  });
  final String userId;
  final int xpAmount;
  final String reason;

  @override
  List<Object?> get props => [userId, xpAmount, reason];
}

class LoadXPHistory extends GamificationEvent {

  const LoadXPHistory(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class LoadLeaderboard extends GamificationEvent { // 'week', 'month', 'year'

  const LoadLeaderboard({
    this.userId,
    this.type = LeaderboardType.global,
    this.region,
    this.limit = 100,
    this.timePeriod,
  });
  final String? userId;
  final LeaderboardType type;
  final String? region;
  final int limit;
  final String? timePeriod;

  @override
  List<Object?> get props => [userId, type, region, limit, timePeriod];
}

class ClaimLevelRewardsEvent extends GamificationEvent {

  const ClaimLevelRewardsEvent({
    required this.userId,
    required this.level,
  });
  final String userId;
  final int level;

  @override
  List<Object?> get props => [userId, level];
}

class CheckFeatureUnlockEvent extends GamificationEvent {

  const CheckFeatureUnlockEvent({
    required this.userId,
    required this.featureId,
  });
  final String userId;
  final String featureId;

  @override
  List<Object?> get props => [userId, featureId];
}

// ===== Challenge Events =====

class LoadDailyChallenges extends GamificationEvent {

  const LoadDailyChallenges(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class TrackChallengeProgressEvent extends GamificationEvent {

  const TrackChallengeProgressEvent({
    required this.userId,
    required this.challengeId,
    this.incrementBy = 1,
  });
  final String userId;
  final String challengeId;
  final int incrementBy;

  @override
  List<Object?> get props => [userId, challengeId, incrementBy];
}

class ClaimChallengeRewardEvent extends GamificationEvent {

  const ClaimChallengeRewardEvent({
    required this.userId,
    required this.challengeId,
  });
  final String userId;
  final String challengeId;

  @override
  List<Object?> get props => [userId, challengeId];
}

// ===== Seasonal Event Events =====

class LoadSeasonalEvent extends GamificationEvent {

  const LoadSeasonalEvent(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ApplySeasonalTheme extends GamificationEvent {
  const ApplySeasonalTheme();
}

// ===== UI State Management Events =====

/// Event to clear the level-up flag after the celebration dialog has been shown
class ClearLevelUpFlag extends GamificationEvent {
  const ClearLevelUpFlag();
}
