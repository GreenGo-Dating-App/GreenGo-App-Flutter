import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional imports based on feature flags
// Uncomment when enabling features in AppConfig
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
// import 'package:local_auth/local_auth.dart';

import '../config/app_config.dart';

// Authentication
import '../../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/authentication/domain/usecases/sign_in_with_email.dart';
import '../../features/authentication/domain/usecases/register_with_email.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';

// Profile
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/create_profile.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/profile/domain/usecases/update_profile.dart';
import '../../features/profile/domain/usecases/upload_photo.dart';
import '../../features/profile/domain/usecases/verify_photo.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/presentation/bloc/onboarding_bloc.dart';

// Matching
import '../../features/matching/data/datasources/matching_remote_datasource.dart';
import '../../features/matching/data/repositories/matching_repository_impl.dart';
import '../../features/matching/domain/repositories/matching_repository.dart';
import '../../features/matching/domain/usecases/feature_engineer.dart';
import '../../features/matching/domain/usecases/compatibility_scorer.dart';
import '../../features/matching/domain/usecases/get_match_candidates.dart';

// Discovery
import '../../features/discovery/data/datasources/discovery_remote_datasource.dart';
import '../../features/discovery/data/repositories/discovery_repository_impl.dart';
import '../../features/discovery/domain/repositories/discovery_repository.dart';
import '../../features/discovery/domain/usecases/get_discovery_stack.dart';
import '../../features/discovery/domain/usecases/record_swipe.dart';
import '../../features/discovery/domain/usecases/undo_swipe.dart';
import '../../features/discovery/domain/usecases/get_matches.dart';
import '../../features/discovery/presentation/bloc/discovery_bloc.dart';
import '../../features/discovery/presentation/bloc/matches_bloc.dart';

// Chat
import '../../features/chat/data/datasources/chat_remote_datasource.dart';
import '../../features/chat/data/repositories/chat_repository_impl.dart';
import '../../features/chat/domain/repositories/chat_repository.dart';
import '../../features/chat/domain/usecases/get_conversation.dart';
import '../../features/chat/domain/usecases/get_conversations.dart';
import '../../features/chat/domain/usecases/get_messages.dart';
import '../../features/chat/domain/usecases/send_message.dart';
import '../../features/chat/domain/usecases/mark_as_read.dart';
import '../../features/chat/domain/usecases/set_typing_indicator.dart';
import '../../features/chat/domain/usecases/delete_message.dart';
import '../../features/chat/domain/usecases/block_user.dart';
import '../../features/chat/domain/usecases/report_user.dart';
import '../../features/chat/domain/usecases/star_message.dart';
import '../../features/chat/domain/usecases/forward_message.dart';
import '../../features/chat/domain/usecases/delete_conversation.dart';
import '../../features/chat/domain/usecases/get_search_conversation.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/conversations_bloc.dart';

// Notifications
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/domain/usecases/mark_notification_read.dart';
import '../../features/notifications/domain/usecases/mark_all_notifications_read.dart';
import '../../features/notifications/domain/usecases/get_notification_preferences.dart';
import '../../features/notifications/domain/usecases/update_notification_preferences.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/bloc/notification_preferences_bloc.dart';

// Video Calling
import '../../features/video_calling/data/datasources/video_calling_remote_datasource.dart';
import '../../features/video_calling/data/repositories/video_calling_repository_impl.dart';
import '../../features/video_calling/domain/repositories/video_calling_repository.dart';
import '../../features/video_calling/domain/usecases/initiate_call.dart';
import '../../features/video_calling/domain/usecases/answer_call.dart';
import '../../features/video_calling/domain/usecases/decline_call.dart';
import '../../features/video_calling/domain/usecases/end_call.dart';
import '../../features/video_calling/domain/usecases/get_call_history.dart';
import '../../features/video_calling/domain/usecases/listen_for_incoming_calls.dart';
import '../../features/video_calling/domain/usecases/get_sdk_config.dart';
import '../../features/video_calling/presentation/bloc/video_call_bloc.dart';

// Admin - Tier Configuration
import '../../features/admin/data/datasources/tier_config_datasource.dart';
import '../../features/admin/data/repositories/tier_config_repository_impl.dart';
import '../../features/admin/domain/repositories/tier_config_repository.dart';
import '../../features/admin/domain/entities/tier_config.dart';

// Gamification - Streaks
import '../../features/gamification/data/datasources/streak_datasource.dart';
import '../../features/gamification/data/repositories/streak_repository_impl.dart';
import '../../features/gamification/domain/repositories/streak_repository.dart';

// Gamification - Full
import 'package:cloud_functions/cloud_functions.dart';
import '../../features/gamification/data/datasources/gamification_remote_datasource.dart';
import '../../features/gamification/data/repositories/gamification_repository_impl.dart';
import '../../features/gamification/domain/repositories/gamification_repository.dart';
import '../../features/gamification/domain/usecases/get_user_achievements.dart';
import '../../features/gamification/domain/usecases/unlock_achievement.dart';
import '../../features/gamification/domain/usecases/track_achievement_progress.dart';
import '../../features/gamification/domain/usecases/grant_xp.dart';
import '../../features/gamification/domain/usecases/get_leaderboard.dart';
import '../../features/gamification/domain/usecases/claim_level_rewards.dart';
import '../../features/gamification/domain/usecases/check_feature_unlock.dart';
import '../../features/gamification/domain/usecases/get_daily_challenges.dart';
import '../../features/gamification/domain/usecases/track_challenge_progress.dart';
import '../../features/gamification/domain/usecases/claim_challenge_reward.dart' as gamification;
import '../../features/gamification/domain/usecases/get_seasonal_event.dart';
import '../../features/gamification/presentation/bloc/gamification_bloc.dart';

// Coins
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../features/coins/data/datasources/coin_remote_datasource.dart';

// Language Learning
import '../../features/language_learning/data/datasources/language_learning_remote_data_source.dart';
import '../../features/language_learning/data/repositories/language_learning_repository_impl.dart';
import '../../features/language_learning/domain/repositories/language_learning_repository.dart';
import '../../features/language_learning/presentation/bloc/language_learning_bloc.dart';
import '../../features/coins/data/repositories/coin_repository_impl.dart';
import '../../features/coins/domain/repositories/coin_repository.dart';
import '../../features/coins/domain/usecases/get_coin_balance.dart';
import '../../features/coins/domain/usecases/purchase_coins.dart';
import '../../features/coins/domain/usecases/get_transaction_history.dart';
import '../../features/coins/domain/usecases/claim_reward.dart';
import '../../features/coins/domain/usecases/purchase_feature.dart';
import '../../features/coins/domain/usecases/manage_gifts.dart';
import '../../features/coins/domain/usecases/manage_allowance.dart';
import '../../features/coins/domain/usecases/manage_expiration.dart';
import '../../features/coins/domain/usecases/manage_promotions.dart';
import '../../features/coins/presentation/bloc/coin_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Authentication
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      repository: sl(),
      localAuth: AppConfig.enableBiometricAuth ? sl() : null,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SignInWithEmail(sl()));
  sl.registerLazySingleton(() => RegisterWithEmail(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: AppConfig.enableGoogleAuth ? sl() : null,
      facebookAuth: AppConfig.enableFacebookAuth ? sl() : null,
    ),
  );

  //! Features - Profile
  // Blocs
  sl.registerFactory(
    () => ProfileBloc(
      getProfile: sl(),
      createProfile: sl(),
      updateProfile: sl(),
      uploadPhoto: sl(),
      verifyPhoto: sl(),
    ),
  );

  sl.registerFactory(
    () => OnboardingBloc(
      createProfile: sl(),
      uploadPhoto: sl(),
      verifyPhoto: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProfile(sl()));
  sl.registerLazySingleton(() => CreateProfile(sl()));
  sl.registerLazySingleton(() => UpdateProfile(sl()));
  sl.registerLazySingleton(() => UploadPhoto(sl()));
  sl.registerLazySingleton(() => VerifyPhoto(sl()));

  // Repository
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(
      firestore: sl(),
      storage: sl(),
    ),
  );

  //! Features - Matching
  // Use cases
  sl.registerLazySingleton(() => GetMatchCandidates(sl()));
  sl.registerLazySingleton(() => FeatureEngineer());
  sl.registerLazySingleton(() => CompatibilityScorer(featureEngineer: sl()));

  // Repository
  sl.registerLazySingleton<MatchingRepository>(
    () => MatchingRepositoryImpl(
      remoteDataSource: sl(),
      featureEngineer: sl(),
      compatibilityScorer: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<MatchingRemoteDataSource>(
    () => MatchingRemoteDataSourceImpl(
      firestore: sl(),
      featureEngineer: sl(),
      compatibilityScorer: sl(),
    ),
  );

  //! Features - Discovery
  // BLoCs
  sl.registerFactory(
    () => DiscoveryBloc(
      getDiscoveryStack: sl(),
      recordSwipe: sl(),
      undoSwipe: sl(),
    ),
  );

  sl.registerFactory(
    () => MatchesBloc(
      getMatches: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetDiscoveryStack(sl()));
  sl.registerLazySingleton(() => RecordSwipe(sl()));
  sl.registerLazySingleton(() => UndoSwipe(sl()));
  sl.registerLazySingleton(() => GetMatches(sl()));

  // Repository
  sl.registerLazySingleton<DiscoveryRepository>(
    () => DiscoveryRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<DiscoveryRemoteDataSource>(
    () => DiscoveryRemoteDataSourceImpl(
      firestore: sl(),
      matchingDataSource: sl(),
    ),
  );

  //! Features - Chat
  // BLoCs
  sl.registerFactory(
    () => ChatBloc(
      getConversation: sl(),
      getMessages: sl(),
      sendMessage: sl(),
      markAsRead: sl(),
      setTypingIndicator: sl(),
      deleteMessage: sl(),
      deleteMessageForMe: sl(),
      deleteMessageForBoth: sl(),
      blockUser: sl(),
      unblockUser: sl(),
      reportUser: sl(),
      starMessage: sl(),
      forwardMessage: sl(),
      deleteConversationForMe: sl(),
      deleteConversationForBoth: sl(),
    ),
  );

  sl.registerFactory(
    () => ConversationsBloc(
      getConversations: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetConversation(sl()));
  sl.registerLazySingleton(() => GetConversations(sl()));
  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => MarkAsRead(sl()));
  sl.registerLazySingleton(() => SetTypingIndicator(sl()));
  sl.registerLazySingleton(() => DeleteMessage(sl()));
  sl.registerLazySingleton(() => DeleteMessageForMe(sl()));
  sl.registerLazySingleton(() => DeleteMessageForBoth(sl()));
  sl.registerLazySingleton(() => BlockUser(sl()));
  sl.registerLazySingleton(() => UnblockUser(sl()));
  sl.registerLazySingleton(() => IsUserBlocked(sl()));
  sl.registerLazySingleton(() => ReportUser(sl()));
  sl.registerLazySingleton(() => StarMessage(sl()));
  sl.registerLazySingleton(() => ForwardMessage(sl()));
  sl.registerLazySingleton(() => DeleteConversationForMe(sl()));
  sl.registerLazySingleton(() => DeleteConversationForBoth(sl()));
  sl.registerLazySingleton(() => GetSearchConversation(sl()));

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Notifications
  // BLoCs
  sl.registerFactory(
    () => NotificationsBloc(
      getNotifications: sl(),
      markNotificationRead: sl(),
      markAllNotificationsRead: sl(),
    ),
  );

  sl.registerFactory(
    () => NotificationPreferencesBloc(
      getNotificationPreferences: sl(),
      updateNotificationPreferences: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetNotifications(sl()));
  sl.registerLazySingleton(() => MarkNotificationRead(sl()));
  sl.registerLazySingleton(() => MarkAllNotificationsRead(sl()));
  sl.registerLazySingleton(() => GetNotificationPreferences(sl()));
  sl.registerLazySingleton(() => UpdateNotificationPreferences(sl()));

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(
      firestore: sl(),
      messaging: sl(),
    ),
  );

  //! Features - Video Calling
  if (AppConfig.enableVideoCalls) {
    // BLoC
    sl.registerFactory(
      () => VideoCallBloc(
        initiateCall: sl(),
        answerCall: sl(),
        declineCall: sl(),
        endCall: sl(),
        getCallHistory: sl(),
        listenForIncomingCalls: sl(),
        getSDKConfig: sl(),
        repository: sl(),
        isUserBlocked: sl<IsUserBlocked>(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => InitiateCall(sl()));
    sl.registerLazySingleton(() => AnswerCall(sl()));
    sl.registerLazySingleton(() => DeclineCall(sl()));
    sl.registerLazySingleton(() => EndCall(sl()));
    sl.registerLazySingleton(() => GetCallHistory(sl()));
    sl.registerLazySingleton(() => ListenForIncomingCalls(sl()));
    sl.registerLazySingleton(() => GetSDKConfig(sl()));

    // Repository
    sl.registerLazySingleton<VideoCallingRepository>(
      () => VideoCallingRepositoryImpl(remoteDataSource: sl()),
    );

    // Data sources
    sl.registerLazySingleton<VideoCallingRemoteDataSource>(
      () => VideoCallingRemoteDataSourceImpl(firestore: sl()),
    );
  }

  //! Features - Admin Configuration
  // Data sources
  sl.registerLazySingleton<TierConfigRemoteDataSource>(
    () => TierConfigRemoteDataSourceImpl(firestore: sl()),
  );

  // Repository
  sl.registerLazySingleton<TierConfigRepository>(
    () => TierConfigRepositoryImpl(remoteDataSource: sl()),
  );

  // Provider singleton
  sl.registerLazySingleton(() => TierConfigProvider());

  //! Features - Gamification
  // Streak datasources
  sl.registerLazySingleton<StreakRemoteDataSource>(
    () => StreakRemoteDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<StreakRepository>(
    () => StreakRepositoryImpl(remoteDataSource: sl()),
  );

  // Gamification - Full feature
  sl.registerLazySingleton<GamificationRemoteDataSource>(
    () => GamificationRemoteDataSourceImpl(
      firestore: sl(),
      functions: sl(),
    ),
  );

  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(remoteDataSource: sl()),
  );

  // Gamification Use Cases
  sl.registerLazySingleton(() => GetUserAchievements(sl()));
  sl.registerLazySingleton(() => UnlockAchievement(sl()));
  sl.registerLazySingleton(() => TrackAchievementProgress(sl()));
  sl.registerLazySingleton(() => GrantXP(sl()));
  sl.registerLazySingleton(() => GetLeaderboard(sl()));
  sl.registerLazySingleton(() => ClaimLevelRewards(sl()));
  sl.registerLazySingleton(() => CheckFeatureUnlock(sl()));
  sl.registerLazySingleton(() => GetDailyChallenges(sl()));
  sl.registerLazySingleton(() => TrackChallengeProgress(sl()));
  sl.registerLazySingleton(() => gamification.ClaimChallengeReward(sl()));
  sl.registerLazySingleton(() => GetSeasonalEvent(sl()));

  // Gamification BLoC
  sl.registerFactory(
    () => GamificationBloc(
      getUserAchievements: sl(),
      unlockAchievement: sl(),
      trackAchievementProgress: sl(),
      grantXP: sl(),
      getLeaderboard: sl(),
      claimLevelRewards: sl(),
      checkFeatureUnlock: sl(),
      getDailyChallenges: sl(),
      trackChallengeProgress: sl(),
      claimChallengeReward: sl(),
      getSeasonalEvent: sl(),
      repository: sl(),
    ),
  );

  //! Features - Coins
  // Data sources
  sl.registerLazySingleton<CoinRemoteDataSource>(
    () => CoinRemoteDataSource(
      firestore: sl(),
      inAppPurchase: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<CoinRepository>(
    () => CoinRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases - Balance
  sl.registerLazySingleton(() => GetCoinBalance(sl()));

  // Use cases - Purchase
  sl.registerLazySingleton(() => PurchaseCoins(sl()));
  sl.registerLazySingleton(() => GetAvailablePackages(sl()));

  // Use cases - Transactions
  sl.registerLazySingleton(() => GetTransactionHistory(sl()));

  // Use cases - Rewards
  sl.registerLazySingleton(() => ClaimReward(sl()));
  sl.registerLazySingleton(() => CanClaimReward(sl()));
  sl.registerLazySingleton(() => GetClaimedRewards(sl()));

  // Use cases - Features
  sl.registerLazySingleton(() => PurchaseFeature(sl()));
  sl.registerLazySingleton(() => CanAffordFeature(sl()));

  // Use cases - Gifts
  sl.registerLazySingleton(() => SendCoinGift(sl()));
  sl.registerLazySingleton(() => AcceptCoinGift(sl()));
  sl.registerLazySingleton(() => DeclineCoinGift(sl()));
  sl.registerLazySingleton(() => GetPendingGifts(sl()));
  sl.registerLazySingleton(() => GetSentGifts(sl()));

  // Use cases - Allowance
  sl.registerLazySingleton(() => GrantMonthlyAllowance(sl()));
  sl.registerLazySingleton(() => HasReceivedMonthlyAllowance(sl()));

  // Use cases - Expiration
  sl.registerLazySingleton(() => ProcessExpiredCoins(sl()));
  sl.registerLazySingleton(() => GetExpiringCoins(sl()));

  // Use cases - Promotions
  sl.registerLazySingleton(() => GetActivePromotions(sl()));
  sl.registerLazySingleton(() => GetPromotionByCode(sl()));
  sl.registerLazySingleton(() => IsPromotionApplicable(sl()));

  // BLoC
  sl.registerFactory(
    () => CoinBloc(
      getCoinBalance: sl(),
      purchaseCoins: sl(),
      getAvailablePackages: sl(),
      getTransactionHistory: sl(),
      claimReward: sl(),
      canClaimReward: sl(),
      getClaimedRewards: sl(),
      purchaseFeature: sl(),
      canAffordFeature: sl(),
      sendGift: sl(),
      acceptGift: sl(),
      declineGift: sl(),
      getPendingGifts: sl(),
      getSentGifts: sl(),
      processExpiredCoins: sl(),
      getExpiringCoins: sl(),
      getActivePromotions: sl(),
      getPromotionByCode: sl(),
      isPromotionApplicable: sl(),
    ),
  );

  //! Features - Language Learning
  // Data sources
  sl.registerLazySingleton<LanguageLearningRemoteDataSource>(
    () => LanguageLearningRemoteDataSourceImpl(
      firestore: sl(),
      auth: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<LanguageLearningRepository>(
    () => LanguageLearningRepositoryImpl(remoteDataSource: sl()),
  );

  // BLoC
  sl.registerFactory(
    () => LanguageLearningBloc(repository: sl()),
  );

  //! Core
  // TODO: Register core utilities

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => FirebaseFunctions.instance);
  sl.registerLazySingleton(() => InAppPurchase.instance);

  // Conditional registration based on feature flags
  // Uncomment these when enabling features:

  // if (AppConfig.enableGoogleAuth) {
  //   sl.registerLazySingleton(() => GoogleSignIn());
  // }

  // if (AppConfig.enableFacebookAuth) {
  //   sl.registerLazySingleton(() => FacebookAuth.instance);
  // }

  // if (AppConfig.enableBiometricAuth) {
  //   sl.registerLazySingleton(() => LocalAuthentication());
  // }
}
