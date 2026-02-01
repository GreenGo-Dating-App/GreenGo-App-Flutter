/**
 * Gamification BLoC
 * Points 176-200: State management for all gamification features
 */

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_user_achievements.dart';
import '../../domain/usecases/unlock_achievement.dart';
import '../../domain/usecases/track_achievement_progress.dart';
import '../../domain/usecases/grant_xp.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/usecases/claim_level_rewards.dart';
import '../../domain/usecases/check_feature_unlock.dart';
import '../../domain/usecases/get_daily_challenges.dart';
import '../../domain/usecases/track_challenge_progress.dart';
import '../../domain/usecases/claim_challenge_reward.dart';
import '../../domain/usecases/get_seasonal_event.dart';
import '../../domain/repositories/gamification_repository.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final GetUserAchievements getUserAchievements;
  final UnlockAchievement unlockAchievement;
  final TrackAchievementProgress trackAchievementProgress;
  final GrantXP grantXP;
  final GetLeaderboard getLeaderboard;
  final ClaimLevelRewards claimLevelRewards;
  final CheckFeatureUnlock checkFeatureUnlock;
  final GetDailyChallenges getDailyChallenges;
  final TrackChallengeProgress trackChallengeProgress;
  final ClaimChallengeReward claimChallengeReward;
  final GetSeasonalEvent getSeasonalEvent;
  final GamificationRepository repository;

  GamificationBloc({
    required this.getUserAchievements,
    required this.unlockAchievement,
    required this.trackAchievementProgress,
    required this.grantXP,
    required this.getLeaderboard,
    required this.claimLevelRewards,
    required this.checkFeatureUnlock,
    required this.getDailyChallenges,
    required this.trackChallengeProgress,
    required this.claimChallengeReward,
    required this.getSeasonalEvent,
    required this.repository,
  }) : super(GamificationState.initial()) {
    // Achievement Events
    on<LoadUserAchievements>(_onLoadUserAchievements);
    on<UnlockAchievementEvent>(_onUnlockAchievement);
    on<TrackAchievementProgressEvent>(_onTrackAchievementProgress);

    // Level & XP Events
    on<LoadUserLevel>(_onLoadUserLevel);
    on<GrantXPEvent>(_onGrantXP);
    on<LoadXPHistory>(_onLoadXPHistory);
    on<LoadLeaderboard>(_onLoadLeaderboard);
    on<ClaimLevelRewardsEvent>(_onClaimLevelRewards);
    on<CheckFeatureUnlockEvent>(_onCheckFeatureUnlock);

    // Challenge Events
    on<LoadDailyChallenges>(_onLoadDailyChallenges);
    on<TrackChallengeProgressEvent>(_onTrackChallengeProgress);
    on<ClaimChallengeRewardEvent>(_onClaimChallengeReward);

    // Seasonal Event Events
    on<LoadSeasonalEvent>(_onLoadSeasonalEvent);
    on<ApplySeasonalTheme>(_onApplySeasonalTheme);

    // UI State Management Events
    on<ClearLevelUpFlag>(_onClearLevelUpFlag);
  }

  // ===== Achievement Event Handlers =====

  Future<void> _onLoadUserAchievements(
    LoadUserAchievements event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(achievementsLoading: true, achievementsError: null));

    final result = await getUserAchievements(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(
        achievementsLoading: false,
        achievementsError: failure.message,
      )),
      (data) => emit(state.copyWith(
        achievementsLoading: false,
        achievementsData: data,
      )),
    );
  }

  Future<void> _onUnlockAchievement(
    UnlockAchievementEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = UnlockAchievementParams(
      userId: event.userId,
      achievementId: event.achievementId,
    );

    final result = await unlockAchievement(params);

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (unlockResult) {
        // Grant XP reward
        if (unlockResult.rewardsGranted.any((r) => r.type == 'xp')) {
          final xpReward = unlockResult.rewardsGranted.firstWhere(
            (r) => r.type == 'xp',
          );
          add(GrantXPEvent(
            userId: event.userId,
            xpAmount: xpReward.amount,
            reason: 'achievement_unlocked',
          ));
        }

        emit(state.copyWith(
          recentlyUnlocked: unlockResult.achievement,
          successMessage:
              '${unlockResult.achievement.name} unlocked! +${unlockResult.rewardsGranted.first.amount} ${unlockResult.rewardsGranted.first.type}',
        ));

        // Reload achievements
        add(LoadUserAchievements(event.userId));
      },
    );
  }

  Future<void> _onTrackAchievementProgress(
    TrackAchievementProgressEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = TrackAchievementProgressParams(
      userId: event.userId,
      achievementId: event.achievementId,
      incrementBy: event.incrementBy,
    );

    final result = await trackAchievementProgress(params);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (progressResult) {
        // If achievement was just completed, show notification
        if (progressResult.wasCompleted && progressResult.achievement != null) {
          emit(state.copyWith(
            successMessage:
                'Achievement complete! Ready to unlock: ${progressResult.achievement!.name}',
          ));
        }

        // Reload achievements
        add(LoadUserAchievements(event.userId));
      },
    );
  }

  // ===== Level & XP Event Handlers =====

  Future<void> _onLoadUserLevel(
    LoadUserLevel event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(levelLoading: true, levelError: null));

    final result = await repository.getUserLevel(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(
        levelLoading: false,
        levelError: failure.message,
      )),
      (level) => emit(state.copyWith(
        levelLoading: false,
        userLevel: level,
      )),
    );
  }

  Future<void> _onGrantXP(
    GrantXPEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = GrantXPParams(
      userId: event.userId,
      xpAmount: event.xpAmount,
      reason: event.reason,
    );

    final result = await grantXP(params);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (xpResult) {
        // Check if user leveled up (Point 189: Trigger level-up animation)
        if (xpResult.leveledUp) {
          emit(state.copyWith(
            userLevel: xpResult.newLevel,
            leveledUp: true,
            previousLevel: xpResult.oldLevel.level,
            pendingRewards: xpResult.rewards,
            successMessage:
                'Level Up! You reached level ${xpResult.newLevel.level}!',
          ));

          // Check if VIP status achieved (Point 193)
          if (xpResult.becameVIP) {
            emit(state.copyWith(
              successMessage:
                  'Congratulations! You\'ve achieved VIP status! 👑',
            ));
          }
        } else {
          emit(state.copyWith(
            userLevel: xpResult.newLevel,
          ));
        }
      },
    );
  }

  Future<void> _onLoadXPHistory(
    LoadXPHistory event,
    Emitter<GamificationState> emit,
  ) async {
    final result = await repository.getXPHistory(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (history) => emit(state.copyWith(xpHistory: history)),
    );
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(leaderboardLoading: true, leaderboardError: null));

    final params = GetLeaderboardParams(
      userId: event.userId,
      type: event.type,
      region: event.region,
      limit: event.limit,
    );

    final result = await getLeaderboard(params);

    result.fold(
      (failure) => emit(state.copyWith(
        leaderboardLoading: false,
        leaderboardError: failure.message,
      )),
      (data) => emit(state.copyWith(
        leaderboardLoading: false,
        leaderboardData: data,
      )),
    );
  }

  Future<void> _onClaimLevelRewards(
    ClaimLevelRewardsEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = ClaimLevelRewardsParams(
      userId: event.userId,
      level: event.level,
    );

    final result = await claimLevelRewards(params);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (claimResult) {
        emit(state.copyWith(
          pendingRewards: [],
          successMessage:
              'Level ${claimResult.level} rewards claimed! ${claimResult.totalCoins > 0 ? '+${claimResult.totalCoins} coins' : ''}',
        ));

        // Reload user level
        add(LoadUserLevel(event.userId));
      },
    );
  }

  Future<void> _onCheckFeatureUnlock(
    CheckFeatureUnlockEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = CheckFeatureUnlockParams(
      userId: event.userId,
      featureId: event.featureId,
    );

    final result = await checkFeatureUnlock(params);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (unlockStatus) {
        if (!unlockStatus.isUnlocked && unlockStatus.requiredLevel != null) {
          emit(state.copyWith(
            errorMessage:
                '${unlockStatus.featureName} unlocks at level ${unlockStatus.requiredLevel}. ${unlockStatus.levelsRemaining} levels to go!',
          ));
        }
      },
    );
  }

  // ===== Challenge Event Handlers =====

  Future<void> _onLoadDailyChallenges(
    LoadDailyChallenges event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(challengesLoading: true, challengesError: null));

    final result = await getDailyChallenges(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(
        challengesLoading: false,
        challengesError: failure.message,
      )),
      (data) => emit(state.copyWith(
        challengesLoading: false,
        challengesData: data,
      )),
    );
  }

  Future<void> _onTrackChallengeProgress(
    TrackChallengeProgressEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = TrackChallengeProgressParams(
      userId: event.userId,
      challengeId: event.challengeId,
      incrementBy: event.incrementBy,
    );

    final result = await trackChallengeProgress(params);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (progressResult) {
        // If challenge was just completed, show notification
        if (progressResult.wasCompleted && progressResult.challenge != null) {
          emit(state.copyWith(
            recentlyCompleted: progressResult.challenge,
            successMessage:
                'Challenge complete! ${progressResult.challenge!.name}',
          ));
        }

        // Reload challenges
        add(LoadDailyChallenges(event.userId));
      },
    );
  }

  Future<void> _onClaimChallengeReward(
    ClaimChallengeRewardEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final params = ClaimChallengeRewardParams(
      userId: event.userId,
      challengeId: event.challengeId,
    );

    final result = await claimChallengeReward(params);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (claimResult) {
        // Grant XP reward
        if (claimResult.totalXP > 0) {
          add(GrantXPEvent(
            userId: event.userId,
            xpAmount: claimResult.totalXP,
            reason: 'challenge_completed',
          ));
        }

        emit(state.copyWith(
          successMessage:
              '${claimResult.challengeName} rewards claimed! ${claimResult.totalXP > 0 ? '+${claimResult.totalXP} XP' : ''} ${claimResult.totalCoins > 0 ? '+${claimResult.totalCoins} coins' : ''}',
        ));

        // Reload challenges
        add(LoadDailyChallenges(event.userId));
      },
    );
  }

  // ===== Seasonal Event Event Handlers =====

  Future<void> _onLoadSeasonalEvent(
    LoadSeasonalEvent event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(seasonalEventLoading: true, seasonalEventError: null));

    final result = await getSeasonalEvent(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(
        seasonalEventLoading: false,
        seasonalEventError: failure.message,
      )),
      (data) => emit(state.copyWith(
        seasonalEventLoading: false,
        seasonalEventData: data,
      )),
    );
  }

  Future<void> _onApplySeasonalTheme(
    ApplySeasonalTheme event,
    Emitter<GamificationState> emit,
  ) async {
    final result = await repository.getSeasonalThemeConfig();

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (themeConfig) {
        // Theme config is applied at app level
        // This event just triggers a reload of the theme
      },
    );
  }

  // ===== UI State Management Event Handlers =====

  void _onClearLevelUpFlag(
    ClearLevelUpFlag event,
    Emitter<GamificationState> emit,
  ) {
    emit(state.copyWith(clearLeveledUp: true));
  }
}
