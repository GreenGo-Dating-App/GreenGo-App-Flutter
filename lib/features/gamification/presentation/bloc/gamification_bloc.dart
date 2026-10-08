/// Gamification BLoC
/// Points 176-200: State management for all gamification features
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../coins/domain/entities/coin_transaction.dart';
import '../../../coins/domain/repositories/coin_repository.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/usecases/check_feature_unlock.dart';
import '../../domain/usecases/claim_challenge_reward.dart';
import '../../domain/usecases/claim_level_rewards.dart';
import '../../domain/usecases/get_daily_challenges.dart';
import '../../domain/usecases/get_leaderboard.dart';
import '../../domain/usecases/get_seasonal_event.dart';
import '../../domain/usecases/get_user_achievements.dart';
import '../../domain/usecases/grant_xp.dart';
import '../../domain/usecases/track_achievement_progress.dart';
import '../../domain/usecases/track_challenge_progress.dart';
import '../../domain/usecases/unlock_achievement.dart';
import 'gamification_event.dart';
import 'gamification_state.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {

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
    required this.coinRepository,
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
  final CoinRepository coinRepository;

  /// Monotonic id of the latest leaderboard request (see _onLoadLeaderboard).
  int _leaderboardRequestId = 0;

  // ===== Achievement Event Handlers =====

  Future<void> _onLoadUserAchievements(
    LoadUserAchievements event,
    Emitter<GamificationState> emit,
  ) async {
    emit(state.copyWith(
      achievementsLoading: true,
      clearAchievementsError: true,
    ));

    // Every path must end in loaded-or-error: an exception thrown here would
    // otherwise leave achievementsLoading == true and the spinner forever.
    try {
      final result = await getUserAchievements(event.userId);

      result.fold(
        (failure) {
          debugPrint('GamificationBloc: achievements load failed: '
              '${failure.message}');
          emit(state.copyWith(
            achievementsLoading: false,
            achievementsError: failure.message,
          ));
        },
        (data) => emit(state.copyWith(
          achievementsLoading: false,
          achievementsData: data,
          clearAchievementsError: true,
        )),
      );
    } catch (e) {
      debugPrint('GamificationBloc: achievements load threw: $e');
      emit(state.copyWith(
        achievementsLoading: false,
        achievementsError: e.toString(),
      ));
    }
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
          successMessage: GamificationNotice(
            GamificationNoticeType.achievementUnlocked,
            id: unlockResult.achievement.achievementId,
            fallbackName: unlockResult.achievement.name,
            amount: unlockResult.rewardsGranted.isEmpty
                ? 0
                : unlockResult.rewardsGranted.first.amount,
            rewardType: unlockResult.rewardsGranted.isEmpty
                ? null
                : unlockResult.rewardsGranted.first.type,
          ),
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
            successMessage: GamificationNotice(
              GamificationNoticeType.achievementReady,
              id: progressResult.achievement!.achievementId,
              fallbackName: progressResult.achievement!.name,
            ),
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
            successMessage: GamificationNotice(
              GamificationNoticeType.levelUp,
              level: xpResult.newLevel.level,
            ),
          ));

          // Check if VIP status achieved (Point 193)
          if (xpResult.becameVIP) {
            emit(state.copyWith(
              successMessage: const GamificationNotice(
                GamificationNoticeType.vipAchieved,
              ),
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
    // Tag the request: a quick Global/Regional or period switch fires several
    // loads concurrently and an older, slower response must not overwrite
    // the board the user is now looking at.
    final requestId = ++_leaderboardRequestId;
    emit(state.copyWith(leaderboardLoading: true, clearLeaderboardError: true));

    final params = GetLeaderboardParams(
      userId: event.userId,
      type: event.type,
      region: event.region,
      limit: event.limit,
      timePeriod: event.timePeriod,
    );

    final result = await getLeaderboard(params);
    if (requestId != _leaderboardRequestId) return;

    result.fold(
      (failure) => emit(state.copyWith(
        leaderboardLoading: false,
        leaderboardError: failure.message,
      )),
      (data) => emit(state.copyWith(
        leaderboardLoading: false,
        leaderboardData: data,
        clearLeaderboardError: true,
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
        // Grant coin reward for level-up
        if (claimResult.totalCoins > 0) {
          coinRepository.updateBalance(
            userId: event.userId,
            amount: claimResult.totalCoins,
            type: CoinTransactionType.credit,
            reason: CoinTransactionReason.achievementReward,
            relatedId: 'level_${event.level}',
            metadata: {'source': 'level_reward', 'level': event.level},
          );
        }

        emit(state.copyWith(
          pendingRewards: [],
          successMessage: GamificationNotice(
            GamificationNoticeType.levelRewardsClaimed,
            level: claimResult.level,
            coins: claimResult.totalCoins,
          ),
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
            errorNotice: GamificationNotice(
              GamificationNoticeType.featureLocked,
              id: unlockStatus.featureId,
              fallbackName: unlockStatus.featureName,
              level: unlockStatus.requiredLevel!,
              amount: unlockStatus.levelsRemaining ?? 0,
            ),
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
    emit(state.copyWith(challengesLoading: true, clearChallengesError: true));

    final result = await getDailyChallenges(event.userId);

    result.fold(
      (failure) => emit(state.copyWith(
        challengesLoading: false,
        challengesError: failure.message,
      )),
      (data) => emit(state.copyWith(
        challengesLoading: false,
        challengesData: data,
        clearChallengesError: true,
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
            successMessage: GamificationNotice(
              GamificationNoticeType.challengeCompleted,
              id: progressResult.challenge!.challengeId,
              fallbackName: progressResult.challenge!.name,
            ),
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

        // Grant coin reward
        if (claimResult.totalCoins > 0) {
          coinRepository.updateBalance(
            userId: event.userId,
            amount: claimResult.totalCoins,
            type: CoinTransactionType.credit,
            reason: CoinTransactionReason.achievementReward,
            relatedId: event.challengeId,
            metadata: {'source': 'challenge_reward', 'challengeName': claimResult.challengeName},
          );
        }

        emit(state.copyWith(
          successMessage: GamificationNotice(
            GamificationNoticeType.challengeRewardsClaimed,
            id: event.challengeId,
            fallbackName: claimResult.challengeName,
            xp: claimResult.totalXP,
            coins: claimResult.totalCoins,
          ),
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
