import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Authentication
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      repository: sl(),
      localAuth: sl(),
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
      googleSignIn: sl(),
      facebookAuth: sl(),
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

  //! Core
  // TODO: Register core utilities

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => FirebaseMessaging.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => FacebookAuth.instance);
  sl.registerLazySingleton(() => LocalAuthentication());
}
