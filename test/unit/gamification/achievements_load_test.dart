// Regression: the Achievements screen must never spin forever. Every load
// ends in data (even with zero progress docs, which is prod today) or in an
// error state with Retry.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/coins/domain/repositories/coin_repository.dart';
import 'package:greengo_chat/features/gamification/data/datasources/gamification_remote_datasource.dart';
import 'package:greengo_chat/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:greengo_chat/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/check_feature_unlock.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/claim_challenge_reward.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/claim_level_rewards.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/get_daily_challenges.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/get_leaderboard.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/get_seasonal_event.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/get_user_achievements.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/grant_xp.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/track_achievement_progress.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/track_challenge_progress.dart';
import 'package:greengo_chat/features/gamification/domain/usecases/unlock_achievement.dart';
import 'package:greengo_chat/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:greengo_chat/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:greengo_chat/features/gamification/presentation/screens/achievements_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCoinRepository extends Mock implements CoinRepository {}

class _MockGetUserAchievements extends Mock implements GetUserAchievements {}

class _MockUnlockAchievement extends Mock implements UnlockAchievement {}

class _MockTrackAchievementProgress extends Mock
    implements TrackAchievementProgress {}

class _MockGrantXP extends Mock implements GrantXP {}

class _MockGetLeaderboard extends Mock implements GetLeaderboard {}

class _MockClaimLevelRewards extends Mock implements ClaimLevelRewards {}

class _MockCheckFeatureUnlock extends Mock implements CheckFeatureUnlock {}

class _MockGetDailyChallenges extends Mock implements GetDailyChallenges {}

class _MockTrackChallengeProgress extends Mock
    implements TrackChallengeProgress {}

class _MockClaimChallengeReward extends Mock implements ClaimChallengeReward {}

class _MockGetSeasonalEvent extends Mock implements GetSeasonalEvent {}

GamificationBloc _bloc(
  GetUserAchievements getUserAchievements,
  GamificationRepository repository,
) {
  return GamificationBloc(
    getUserAchievements: getUserAchievements,
    unlockAchievement: _MockUnlockAchievement(),
    trackAchievementProgress: _MockTrackAchievementProgress(),
    grantXP: _MockGrantXP(),
    getLeaderboard: _MockGetLeaderboard(),
    claimLevelRewards: _MockClaimLevelRewards(),
    checkFeatureUnlock: _MockCheckFeatureUnlock(),
    getDailyChallenges: _MockGetDailyChallenges(),
    trackChallengeProgress: _MockTrackChallengeProgress(),
    claimChallengeReward: _MockClaimChallengeReward(),
    getSeasonalEvent: _MockGetSeasonalEvent(),
    repository: repository,
    coinRepository: _MockCoinRepository(),
  );
}

void main() {
  late GamificationRepository repository;

  setUp(() {
    repository = GamificationRepositoryImpl(
      remoteDataSource: GamificationRemoteDataSourceImpl(
        firestore: FakeFirebaseFirestore(),
        functions: _MockFunctions(),
      ),
    );
  });

  test('no progress docs still loads the full catalogue at 0%', () async {
    final bloc = _bloc(GetUserAchievements(repository), repository);
    bloc.add(const LoadUserAchievements('u1'));
    final state = await bloc.stream.firstWhere((s) => !s.achievementsLoading);

    expect(state.achievementsError, isNull);
    expect(state.achievementsData, isNotNull);
    expect(state.achievementsData!.totalAchievements, greaterThan(0));
    expect(state.achievementsData!.unlockedCount, 0);
    expect(state.achievementsData!.progressPercentage, 0);
    await bloc.close();
  });

  test('a thrown exception ends loading with an error (no endless spinner)',
      () async {
    final usecase = _MockGetUserAchievements();
    when(() => usecase(any())).thenThrow(StateError('boom'));
    final bloc = _bloc(usecase, repository);

    bloc.add(const LoadUserAchievements('u1'));
    final state = await bloc.stream.firstWhere(
      (s) => !s.achievementsLoading && s.achievementsError != null,
    );
    expect(state.achievementsError, contains('boom'));
    await bloc.close();
  });

  test('a successful retry clears the previous error', () async {
    final usecase = _MockGetUserAchievements();
    var calls = 0;
    when(() => usecase(any())).thenAnswer((_) async {
      calls++;
      if (calls == 1) return const Left(ServerFailure('timeout'));
      return GetUserAchievements(repository)('u1');
    });
    final bloc = _bloc(usecase, repository);

    bloc.add(const LoadUserAchievements('u1'));
    await bloc.stream.firstWhere((s) => s.achievementsError != null);

    bloc.add(const LoadUserAchievements('u1'));
    final state = await bloc.stream.firstWhere(
      (s) => !s.achievementsLoading && s.achievementsData != null,
    );
    expect(state.achievementsError, isNull);
    await bloc.close();
  });

  testWidgets('screen shows localized error + Retry when loading fails',
      (tester) async {
    final usecase = _MockGetUserAchievements();
    when(() => usecase(any()))
        .thenAnswer((_) async => const Left(ServerFailure('timeout')));

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => _bloc(usecase, repository),
        child: const AchievementsScreen(userId: 'u1'),
      ),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Couldn\'t load achievements'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
