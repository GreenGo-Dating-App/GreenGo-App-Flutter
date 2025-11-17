/**
 * Gamification State
 * Points 176-200: All gamification-related states
 */

import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_user_achievements.dart';
import '../../domain/usecases/get_daily_challenges.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/usecases/get_seasonal_event.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/daily_challenge.dart';

class GamificationState extends Equatable {
  // Achievement State
  final UserAchievementsData? achievementsData;
  final bool achievementsLoading;
  final String? achievementsError;
  final Achievement? recentlyUnlocked;

  // Level & XP State
  final UserLevel? userLevel;
  final bool levelLoading;
  final String? levelError;
  final List<XPTransaction> xpHistory;
  final bool leveledUp;
  final int? previousLevel;
  final List<LevelReward> pendingRewards;

  // Leaderboard State
  final LeaderboardData? leaderboardData;
  final bool leaderboardLoading;
  final String? leaderboardError;

  // Challenge State
  final DailyChallengesData? challengesData;
  final bool challengesLoading;
  final String? challengesError;
  final DailyChallenge? recentlyCompleted;

  // Seasonal Event State
  final SeasonalEventData? seasonalEventData;
  final bool seasonalEventLoading;
  final String? seasonalEventError;

  // General State
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const GamificationState({
    // Achievements
    this.achievementsData,
    this.achievementsLoading = false,
    this.achievementsError,
    this.recentlyUnlocked,

    // Level & XP
    this.userLevel,
    this.levelLoading = false,
    this.levelError,
    this.xpHistory = const [],
    this.leveledUp = false,
    this.previousLevel,
    this.pendingRewards = const [],

    // Leaderboard
    this.leaderboardData,
    this.leaderboardLoading = false,
    this.leaderboardError,

    // Challenges
    this.challengesData,
    this.challengesLoading = false,
    this.challengesError,
    this.recentlyCompleted,

    // Seasonal Events
    this.seasonalEventData,
    this.seasonalEventLoading = false,
    this.seasonalEventError,

    // General
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  factory GamificationState.initial() => const GamificationState();

  GamificationState copyWith({
    // Achievements
    UserAchievementsData? achievementsData,
    bool? achievementsLoading,
    String? achievementsError,
    Achievement? recentlyUnlocked,
    bool clearRecentlyUnlocked = false,

    // Level & XP
    UserLevel? userLevel,
    bool? levelLoading,
    String? levelError,
    List<XPTransaction>? xpHistory,
    bool? leveledUp,
    int? previousLevel,
    List<LevelReward>? pendingRewards,
    bool clearLeveledUp = false,

    // Leaderboard
    LeaderboardData? leaderboardData,
    bool? leaderboardLoading,
    String? leaderboardError,

    // Challenges
    DailyChallengesData? challengesData,
    bool? challengesLoading,
    String? challengesError,
    DailyChallenge? recentlyCompleted,
    bool clearRecentlyCompleted = false,

    // Seasonal Events
    SeasonalEventData? seasonalEventData,
    bool? seasonalEventLoading,
    String? seasonalEventError,

    // General
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return GamificationState(
      // Achievements
      achievementsData: achievementsData ?? this.achievementsData,
      achievementsLoading: achievementsLoading ?? this.achievementsLoading,
      achievementsError: achievementsError ?? this.achievementsError,
      recentlyUnlocked:
          clearRecentlyUnlocked ? null : (recentlyUnlocked ?? this.recentlyUnlocked),

      // Level & XP
      userLevel: userLevel ?? this.userLevel,
      levelLoading: levelLoading ?? this.levelLoading,
      levelError: levelError ?? this.levelError,
      xpHistory: xpHistory ?? this.xpHistory,
      leveledUp: clearLeveledUp ? false : (leveledUp ?? this.leveledUp),
      previousLevel: clearLeveledUp ? null : (previousLevel ?? this.previousLevel),
      pendingRewards: pendingRewards ?? this.pendingRewards,

      // Leaderboard
      leaderboardData: leaderboardData ?? this.leaderboardData,
      leaderboardLoading: leaderboardLoading ?? this.leaderboardLoading,
      leaderboardError: leaderboardError ?? this.leaderboardError,

      // Challenges
      challengesData: challengesData ?? this.challengesData,
      challengesLoading: challengesLoading ?? this.challengesLoading,
      challengesError: challengesError ?? this.challengesError,
      recentlyCompleted: clearRecentlyCompleted
          ? null
          : (recentlyCompleted ?? this.recentlyCompleted),

      // Seasonal Events
      seasonalEventData: seasonalEventData ?? this.seasonalEventData,
      seasonalEventLoading: seasonalEventLoading ?? this.seasonalEventLoading,
      seasonalEventError: seasonalEventError ?? this.seasonalEventError,

      // General
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        // Achievements
        achievementsData,
        achievementsLoading,
        achievementsError,
        recentlyUnlocked,

        // Level & XP
        userLevel,
        levelLoading,
        levelError,
        xpHistory,
        leveledUp,
        previousLevel,
        pendingRewards,

        // Leaderboard
        leaderboardData,
        leaderboardLoading,
        leaderboardError,

        // Challenges
        challengesData,
        challengesLoading,
        challengesError,
        recentlyCompleted,

        // Seasonal Events
        seasonalEventData,
        seasonalEventLoading,
        seasonalEventError,

        // General
        isLoading,
        errorMessage,
        successMessage,
      ];
}
