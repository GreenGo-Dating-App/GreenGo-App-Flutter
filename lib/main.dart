import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/config/map_basemap.dart';
import 'core/config/app_config.dart';
import 'core/config/flavor_config.dart';
import 'features/analytics/data/services/performance_monitoring_service.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection_container.dart' as di;
import 'core/cache/last_result_cache.dart';
import 'core/providers/language_provider.dart';
import 'core/services/access_control_service.dart';
import 'core/services/api_key_service.dart';
import 'core/services/app_sound_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/data_preload_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/purchase_recovery_service.dart';
import 'core/services/feature_flags_service.dart';
import 'core/services/onboarding_gate.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/session_cache_gate.dart';
import 'core/services/version_check_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/admin_data_utils.dart';
import 'core/utils/seed_data.dart';
import 'core/widgets/app_error_screen.dart';
import 'core/widgets/update_dialog.dart';
import 'features/admin/presentation/screens/admin_2fa_screen.dart';
import 'features/admin/presentation/screens/coin_management_screen.dart';
import 'features/admin/presentation/screens/early_access_admin_screen.dart';
import 'features/admin/presentation/screens/gamification_management_screen.dart';
import 'features/admin/presentation/screens/pre_sale_admin_screen.dart';
import 'features/admin/presentation/screens/reports_admin_screen.dart';
import 'features/admin/presentation/screens/support_tickets_screen.dart';
import 'features/admin/presentation/screens/tier_management_screen.dart';
import 'features/admin/presentation/screens/verification_admin_screen.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'features/authentication/presentation/screens/forgot_password_screen.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/authentication/presentation/screens/register_screen.dart';
import 'features/authentication/presentation/screens/waiting_screen.dart';
import 'features/chat/presentation/screens/support_chat_screen.dart';
import 'features/chat/presentation/screens/support_tickets_list_screen.dart';
import 'features/communities/presentation/bloc/communities_bloc.dart';
import 'features/communities/presentation/screens/communities_screen.dart';
import 'features/cultural_exchange/presentation/bloc/cultural_exchange_bloc.dart';
import 'features/cultural_exchange/presentation/screens/cultural_exchange_screen.dart';
import 'features/cultural_exchange/presentation/screens/dating_etiquette_screen.dart';
import 'features/discovery/data/datasources/discovery_remote_datasource.dart';
import 'features/discovery/data/services/discovery_prefetch.dart';
import 'features/events/data/services/events_prefetch.dart';
import 'features/events/presentation/bloc/events_bloc.dart';
import 'features/events/presentation/screens/events_screen.dart';
import 'features/explore_map/presentation/bloc/explore_map_bloc.dart';
import 'features/explore_map/presentation/screens/explore_map_screen.dart';
import 'features/main/presentation/screens/main_navigation_screen.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';
import 'features/profile/presentation/screens/onboarding_screen.dart' as profile;
import 'features/profile/presentation/screens/reverification_screen.dart';
import 'features/safety_academy/presentation/screens/safety_academy_screen.dart';
import 'features/splash/presentation/screens/post_login_splash_screen.dart';
import 'features/spots/presentation/bloc/spots_bloc.dart';
import 'features/spots/presentation/screens/spot_detail_screen.dart';
import 'features/spots/presentation/screens/spots_screen.dart';
import 'features/subscription/domain/entities/subscription.dart';
import 'features/video_profiles/presentation/bloc/video_profile_bloc.dart';
import 'features/video_profiles/presentation/screens/video_discovery_screen.dart';
import 'features/video_profiles/presentation/screens/video_profile_screen.dart';
import 'firebase_options.dart';
import 'generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A build failure must never leave a blank page. Flutter's default release
  // ErrorWidget is a flat grey rectangle, which on web is indistinguishable
  // from "the app shows a white page" — that is exactly how an unregistered
  // GetIt lookup in MainNavigationScreen.initState presented in production.
  // Replace it with a screen that names the failure and offers a way out.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('🛑 Widget build failed: ${details.exceptionAsString()}');
    // Best-effort report; never let the reporter itself throw here.
    try {
      if (!kDebugMode) FirebaseCrashlytics.instance.recordFlutterError(details);
    } catch (_) {}
    return AppErrorScreen(details: details, onReload: restartApp);
  };

  // Print app configuration (for debugging)
  AppConfig.printConfig();

  // Set preferred orientations.
  //
  // GreenGo ships for iPhone AND iPad (TARGETED_DEVICE_FAMILY = "1,2"), and
  // App Review therefore tests on an iPad. An app that declares iPad support
  // but refuses to rotate reads as a blown-up phone app and is a 2.1 / HIG
  // risk, so tablets get all four orientations while phones stay portrait —
  // the phone layouts are designed for one orientation only.
  //
  // Measured from the physical view rather than MediaQuery because no widget
  // tree exists yet at this point in startup. 600dp shortest side is the
  // conventional phone/tablet boundary.
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final shortestSideDp =
      (view.physicalSize.shortestSide / view.devicePixelRatio);
  final isTablet = shortestSideDp >= 600;

  await SystemChrome.setPreferredOrientations(
    isTablet
        ? const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]
        : const [
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ],
  );

  // Initialize Firebase with production options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence so chat conversations and messages
  // load INSTANTLY from the local cache and stay available OFFLINE, then sync
  // from the server in the background. Set explicitly with an UNLIMITED cache
  // so chat history is never evicted.
  //
  // Wrapped in try/catch and applied before any Firestore access: on web,
  // persistence is backed by IndexedDB (unsupported in some browsers / private
  // mode / multi-tab), so enabling it must never crash app startup — if it
  // fails on web the app still runs, just without the offline cache.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Unlimited local cache
    );
    debugPrint('✓ Firestore offline persistence enabled (unlimited cache)');
  } catch (e) {
    // Never let a persistence-config failure (mainly web/IndexedDB) block boot.
    debugPrint('⚠ Firestore offline persistence not enabled: $e');
  }

  // Initialize cache service (Hive-based caching)
  await cacheService.initialize();

  // Configure Firebase Emulators for local development
  if (kDebugMode && AppConfig.useLocalEmulators) {
    debugPrint('🔧 Connecting to Firebase Emulators...');

    // Disable Crashlytics and Performance when using emulators
    // These services require valid API keys and can't use emulators
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(false);
    debugPrint('✓ Crashlytics & Performance disabled (emulator mode)');

    // Get the emulator host
    // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator/Web
    const emulatorHost = AppConfig.emulatorHost;

    try {
      // Connect to Auth Emulator
      await FirebaseAuth.instance
          .useAuthEmulator(emulatorHost, AppConfig.authEmulatorPort);
      debugPrint('✓ Auth Emulator: $emulatorHost:${AppConfig.authEmulatorPort}');

      // Connect to Firestore Emulator
      FirebaseFirestore.instance
          .useFirestoreEmulator(emulatorHost, AppConfig.firestoreEmulatorPort);
      debugPrint('✓ Firestore Emulator: $emulatorHost:${AppConfig.firestoreEmulatorPort}');

      // Connect to Storage Emulator
      await FirebaseStorage.instance
          .useStorageEmulator(emulatorHost, AppConfig.storageEmulatorPort);
      debugPrint('✓ Storage Emulator: $emulatorHost:${AppConfig.storageEmulatorPort}');

      debugPrint('🎉 All Firebase Emulators connected!');
    } catch (e) {
      debugPrint('⚠️ Firebase Emulator connection error: $e');
      debugPrint('Make sure Docker containers are running!');
    }
  }

  // Initialize Firebase App Check
  // Skip App Check when using local emulators (it doesn't work with emulators)
  // Skip on web — App Check for web requires reCAPTCHA Enterprise setup
  if (!AppConfig.useLocalEmulators && !kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      // Use Play Integrity for production builds, debug for development
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttest,
    );
    debugPrint('✓ Firebase App Check activated (${kDebugMode ? 'debug' : 'production'} mode)');
  } else if (kIsWeb) {
    debugPrint('⚠️ Firebase App Check skipped (web platform)');
  } else {
    debugPrint('⚠️ Firebase App Check skipped (using local emulators)');

    // Seed fake users for development/testing
    try {
      // Count existing profiles
      final existingProfiles = await FirebaseFirestore.instance
          .collection('profiles')
          .get();

      final profileCount = existingProfiles.docs.length;
      debugPrint('📊 Found $profileCount existing profiles');

      if (profileCount < 1000) {
        debugPrint('📊 Seeding test data (need ${1000 - profileCount} more profiles)...');
        final seeded = await SeedData.seedUsers(count: 1000, clearExisting: true);
        debugPrint('✅ Seeded $seeded test profiles');
      } else {
        debugPrint('📊 $profileCount profiles exist, skipping seed');
      }

      // Always ensure admin user exists
      await SeedData.seedAdminUser();
    } catch (e) {
      debugPrint('⚠️ Could not seed data: $e');
    }
  }

  // Load countdown dates from Firestore (non-blocking, uses defaults on
  // failure). After App Check so the read carries a token; the result is
  // shared with the auth bloc and main screen, which ask for it again.
  AccessControlService.loadCountdownDatesFromFirestore();

  // Initialize Firebase Remote Config with default values
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: kDebugMode
          ? const Duration(seconds: 10)  // Fast refresh for local development
          : const Duration(hours: 1),    // Standard interval for production
    ));

    // Set default remote config values
    await remoteConfig.setDefaults(const {
      'feature_video_calls_enabled': true,
      'feature_voice_messages_enabled': true,
      'max_photos_per_profile': 6,
      'max_distance_km': 100,
      'subscription_prices_usd': '{"basic": 0, "silver": 9.99, "gold": 19.99}',
      'google_maps_api_key': '',
    });

    // Serve the values fetched on a previous launch right away (local, no
    // network), and refresh them in the background. Waiting on the fetch here
    // held the first frame for up to the fetch timeout on a slow network.
    await remoteConfig.activate();
    unawaited(
      remoteConfig.fetchAndActivate().then((_) {
        // The Maps key is memoized on first read; pick up the fresh value.
        ApiKeyService.invalidateCache();
      }).catchError((Object e) {
        debugPrint('Remote Config fetch error: $e');
      }),
    );
  } catch (e) {
    debugPrint('Remote Config initialization error: $e');
  }

  // Initialize dependency injection
  await di.init();

  // Firebase Performance + Crashlytics (G0 Task 4): enable collection + wire the
  // error handlers, and start the app_launch trace — RELEASE builds only, so
  // debug/emulator runs never pollute production metrics. Start the launch trace
  // before runApp; it is completed on the first frame of the root widget.
  if (!kDebugMode) {
    try {
      await di.sl<PerformanceMonitoringService>().initialize();
      await di.sl<PerformanceMonitoringService>().trackAppLaunch();
    } catch (e) {
      debugPrint('⚠ Performance monitoring init failed: $e');
    }
  } else if (!AppConfig.useLocalEmulators) {
    // Debug on a real device (no emulator): keep collection OFF.
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(false);
  }

  // Sound, feature flags and the version config are not needed for the first
  // frame, so they load alongside it instead of before it. Sounds initialize
  // lazily on first play if this hasn't finished; flags answer from their
  // defaults until loaded; the update / maintenance check in AuthWrapper
  // awaits the version config itself.
  unawaited(AppSoundService().initialize());
  unawaited(featureFlags.initialize());
  unawaited(versionCheck.initialize());

  // Initialize push notification service (FCM handlers)
  await pushNotificationService.initialize();
  debugPrint('✓ Push notification service initialized');

  // App-wide in-app-purchase recovery. Must be started here, NOT on the shop
  // screen: a purchase that completes while the shop is closed is delivered
  // only to a live purchaseStream listener, and an unacknowledged purchase is
  // auto-refunded by Google after 3 days.
  unawaited(
    di.sl<PurchaseRecoveryService>().initialize().catchError((Object e) {
      debugPrint('⚠ Purchase recovery init failed: $e');
    }),
  );

  // Load saved language before app starts (prevents flicker)
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language');

  // Basemap style override, if one is configured. Not awaited — the maps fall
  // back to the built-in default until it lands.
  unawaited(MapBasemap.load());

  runApp(GreenGoChatApp(savedLanguage: savedLanguage));
}

/// Recovery action offered by [AppErrorScreen].
///
/// Rebuilds the navigator from the root, which re-runs [AuthWrapper] and so
/// re-enters whatever screen the user's auth state calls for. A screen-level
/// crash is recoverable this way without the user losing their session; the
/// crash screen is otherwise a dead end.
void restartApp() {
  final nav = PushNotificationService.navigatorKey.currentState;
  if (nav == null) return;
  nav.pushNamedAndRemoveUntil('/', (route) => false);
}

/// One-shot guard so the app_launch trace is completed exactly once.
bool _appLaunchTraceCompleted = false;

class GreenGoChatApp extends StatelessWidget {

  const GreenGoChatApp({super.key, this.savedLanguage});
  final String? savedLanguage;

  @override
  Widget build(BuildContext context) {
    // Complete the app_launch trace on the first frame (release only).
    if (!kDebugMode && !_appLaunchTraceCompleted) {
      _appLaunchTraceCompleted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        di.sl<PerformanceMonitoringService>().completeAppLaunch();
      });
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider(initialLanguage: savedLanguage)),
        ChangeNotifierProvider.value(value: featureFlags),
        BlocProvider(create: (context) => di.sl<AuthBloc>()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            navigatorKey: PushNotificationService.navigatorKey,
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            builder: (context, child) {
              // Global responsive scaling based on screen width
              final mq = MediaQuery.of(context);
              final scaleFactor = AppTheme.scaleFactor(context);
              final scaledTheme = AppTheme.scaledDarkTheme(context);
              return MediaQuery(
                data: mq.copyWith(
                  textScaler: TextScaler.linear(scaleFactor),
                ),
                child: Theme(
                  data: scaledTheme,
                  child: child!,
                ),
              );
            },
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageProvider.supportedLocales,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
            },
            onGenerateRoute: (settings) {
              // Handle routes that need parameters
              if (settings.name == '/home') {
                final args = settings.arguments as Map<String, dynamic>?;
                final userId = args?['userId'] as String?;
                if (userId != null) {
                  return MaterialPageRoute(
                    builder: (context) => MainNavigationScreen(userId: userId),
                  );
                }
              }

              // Cultural Exchange routes
              if (settings.name == '/cultural-exchange') {
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<CulturalExchangeBloc>(),
                    child: const CulturalExchangeScreen(),
                  ),
                );
              }

              if (settings.name == '/dating-etiquette') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<CulturalExchangeBloc>(),
                    child: DatingEtiquetteScreen(
                      initialCountry: args?['country'] as String?,
                    ),
                  ),
                );
              }

              // Safety Academy route
              if (settings.name == '/safety-academy') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => SafetyAcademyScreen(
                    userId: args?['userId'] as String? ?? '',
                  ),
                );
              }

              // Events route
              if (settings.name == '/events') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<EventsBloc>(),
                    child: EventsScreen(
                      currentUserId: args?['userId'] as String? ?? '',
                    ),
                  ),
                );
              }

              // Video Profiles routes (dating feature — gated off in culture mode)
              if (FlavorConfig.enableVideoProfiles &&
                  settings.name == '/video-profile') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<VideoProfileBloc>(),
                    child: VideoProfileScreen(
                      userId: args?['userId'] as String? ?? '',
                    ),
                  ),
                );
              }

              if (FlavorConfig.enableVideoProfiles &&
                  settings.name == '/video-discovery') {
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<VideoProfileBloc>(),
                    child: const VideoDiscoveryScreen(),
                  ),
                );
              }

              // Explore Map route
              if (settings.name == '/explore-map') {
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<ExploreMapBloc>(),
                    child: const ExploreMapScreen(),
                  ),
                );
              }

              // Spots routes
              if (settings.name == '/spots') {
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<SpotsBloc>(),
                    child: const SpotsScreen(),
                  ),
                );
              }

              if (settings.name == '/spot-detail') {
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<SpotsBloc>(),
                    child: SpotDetailScreen(
                      spotId: args?['spotId'] as String? ?? '',
                    ),
                  ),
                );
              }

              // Communities route
              if (settings.name == '/communities') {
                return MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => di.sl<CommunitiesBloc>(),
                    child: const CommunitiesScreen(),
                  ),
                );
              }

              // Admin routes
              if (settings.name == '/admin/pre_sale') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => PreSaleAdminScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/early_access') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => EarlyAccessAdminScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/support_tickets') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => SupportTicketsScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/verifications') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => VerificationAdminScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/reports') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => ReportsAdminScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/tiers') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => TierManagementScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/coins') {
                final adminId = settings.arguments as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => CoinManagementScreen(
                    adminId: adminId,
                  ),
                );
              }

              if (settings.name == '/admin/gamification') {
                final args = settings.arguments as Map<String, dynamic>?;
                final adminId = args?['adminId'] as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => GamificationManagementScreen(
                    adminId: adminId,
                  ),
                );
              }

              // Support routes
              if (settings.name == '/support') {
                final args = settings.arguments as Map<String, dynamic>?;
                final userId = args?['userId'] as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => SupportTicketsListScreen(
                    currentUserId: userId,
                  ),
                );
              }

              if (settings.name == '/support/chat') {
                final args = settings.arguments as Map<String, dynamic>?;
                final conversationId = args?['conversationId'] as String? ?? '';
                final userId = args?['userId'] as String? ?? '';
                return MaterialPageRoute(
                  builder: (context) => SupportChatScreen(
                    conversationId: conversationId,
                    currentUserId: userId,
                  ),
                );
              }

              return null;
            },
          );
        },
      ),
    );
  }
}

/// AuthWrapper - Determines initial route based on authentication state
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _hasCheckedVersion = false;
  bool _isCheckingAccess = false;
  bool _notificationPromptShown = false;
  bool _admin2FAVerified = false;
  bool _needsOnboarding = false;
  bool _showPostLoginSplash = false;
  // Set true only when the post-login profile fetch positively reads
  // `isBanned == true`. Fail-open: a read error never sets this, so a
  // non-banned user is never locked out.
  bool _accountBanned = false;
  // The user this wrapper has already routed. Login handler + auth stream can
  // emit two (non-equal) AuthAuthenticated for one sign-in; the second must
  // not re-run the check (it flashed the splash and remounted the shell).
  String? _routedUserId;
  UserAccessData? _accessData;

  /// True once this app session has seen a signed-out state, so the next
  /// AuthAuthenticated is an actual sign-in (credentials / social) rather
  /// than a cold start of an already-signed-in user. Static because the
  /// wrapper is recreated (onboarding completion, sign-out, restartApp).
  /// Only a real sign-in gets the post-login splash.
  static bool _signInPending = false;

  static bool _isSignedOutState(AuthState state) =>
      state is AuthUnauthenticated || state is AuthLoading || state is AuthError;
  final AccessControlService _accessControlService = AccessControlService();

  @override
  void initState() {
    super.initState();
    // Observe app-level back so a root-level screen (nothing to pop, same level
    // as Discovery) returns to Discovery instead of a black screen.
    WidgetsBinding.instance.addObserver(this);
    // Start the deep-link runtime listener (cold-start + warm links). Guard on
    // web where the app_links platform channel/universal-link plumbing differs
    // and we never want a link-init failure to block boot. Uses the same global
    // navigator key the MaterialApp is built with so routing lands correctly.
    if (!kIsWeb) {
      DeepLinkService.instance
          .init(navigatorKey: PushNotificationService.navigatorKey);
    }
    // Check version after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
      // If the user is ALREADY authenticated when this wrapper mounts — e.g. a
      // fresh AuthWrapper is pushed right after the onboarding wizard completes
      // (`pushNamedAndRemoveUntil('/')`) — the BlocConsumer listener won't fire
      // for the already-current AuthAuthenticated state, so the access check
      // would never run and we'd sit on the splash forever. Kick it off here.
      final authState = context.read<AuthBloc>().state;
      if (_isSignedOutState(authState)) _signInPending = true;
      if (authState is AuthAuthenticated) {
        _onAuthenticated(authState.user);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App-level back handler. When the navigator has nothing to pop (the current
  /// screen is at the root level — same level as the Discovery page), going
  /// back would show a black screen / exit. Instead, route to the main screen
  /// (Discovery tab). Routes that CAN pop are handled normally by the Navigator;
  /// the main screen's own PopScope handles its exit dialog.
  @override
  Future<bool> didPopRoute() async {
    final nav = PushNotificationService.navigatorKey.currentState;
    if (nav == null || nav.canPop()) return false;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return false; // not logged in — let the OS handle it
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainNavigationScreen(userId: userId)),
      (route) => false,
    );
    return true;
  }

  Future<void> _checkVersion() async {
    if (_hasCheckedVersion) return;
    _hasCheckedVersion = true;

    // The version config loads in the background from main(); a forced update
    // or maintenance block shows as soon as it arrives.
    await versionCheck.initialize();
    if (!mounted) return;
    final result = versionCheck.checkVersion();

    switch (result.updateType) {
      case UpdateType.maintenance:
        // Show maintenance screen (blocks everything)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MaintenanceScreen(
              message: result.maintenanceMessage ?? 'We are currently performing maintenance.',
            ),
          ),
          (route) => false,
        );
        break;
      case UpdateType.force:
        // Show force update dialog (non-dismissible)
        UpdateDialogHelper.showForceUpdateDialog(context, result);
        break;
      case UpdateType.soft:
        // Show soft update dialog (dismissible)
        UpdateDialogHelper.showSoftUpdateDialog(context, result);
        break;
      case UpdateType.none:
        // No update needed
        break;
    }
  }

  /// Runs when an authenticated user is detected — from the BlocConsumer
  /// listener on a state change, OR from initState when this wrapper mounts and
  /// the user is already authenticated (e.g. right after onboarding completes).
  /// The `_routedUserId` guard makes it idempotent so the two entry points
  /// (and a double emission) never double-run the work.
  Future<void> _onAuthenticated(dynamic user) async {
    _isSigningOut = false;
    // Guard: skip if this user is already routed / being checked (prevents
    // duplicate calls from double AuthAuthenticated emission via login
    // handler + auth stream, or from listener + initState). Reset on sign-out.
    if (_routedUserId == user.uid) return;
    _routedUserId = user.uid;
    // Set checking flag IMMEDIATELY to prevent WaitingScreen flash
    // (builder runs before async work completes)
    setState(() {
      _isCheckingAccess = true;
      // Post-login splash only on an actual sign-in, not on a cold start.
      if (_signInPending) _showPostLoginSplash = true;
    });
    _checkAccessStatus(user.uid);
    // Load user's saved language from Firestore
    if (mounted) {
      context.read<LanguageProvider>().loadFromDatabase();
    }
    // Save FCM token to Firestore on each login (ensures token is always fresh)
    try {
      final notificationRepo = di.sl<NotificationRepository>();
      final tokenResult = await notificationRepo.getFCMToken();
      tokenResult.fold(
        (_) {},
        (token) async {
          if (token != null) {
            await notificationRepo.saveFCMToken(user.uid, token);
            debugPrint('✓ FCM token saved for ${user.uid}');
          }
        },
      );
    } catch (e) {
      debugPrint('⚠ FCM token save failed: $e');
    }
  }

  /// Persists whether the current account is a business account so the
  /// post-login splash screen can render its "BUSINESS" label without waiting
  /// for the full Profile to load. Key is read in PostLoginSplashScreen.
  Future<void> _cacheBusinessFlag(bool isBusiness) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_business_account', isBusiness);
    } catch (e) {
      debugPrint('⚠ Failed to cache business flag: $e');
    }
  }

  Future<void> _checkAccessStatus(String userId, {bool useCache = true}) async {
    // _isCheckingAccess is already set to true by the listener
    if (!_isCheckingAccess) {
      setState(() {
        _isCheckingAccess = true;
      });
    }
    // Every explicit check reads fresh: drop any shared read left over from
    // an earlier check (e.g. before onboarding, or before an admin approval
    // the user is refreshing for). Reads started from here on are shared.
    AccessControlService.invalidateOwnDoc('profiles', userId);
    AccessControlService.invalidateOwnDoc('users', userId);

    try {
      // Returning user: decide from the local cache (milliseconds, no
      // network) and confirm with the server in the background. First launch
      // on this device, or a cache that says anything but "let them in",
      // waits for the server as before.
      final cached = useCache ? await _resolveAccessFromCache(userId) : null;
      if (cached != null) {
        _applyAccessDecision(userId, cached);
        unawaited(_verifyAccessInBackground(userId, cached));
        return;
      }
      _applyAccessDecision(userId, await _resolveAccessFromServer(userId));
    } catch (e) {
      debugPrint('🔑 Access check error: $e');
      if (mounted) {
        setState(() {
          // Use fallback so user isn't stuck on splash
          _accessData = UserAccessData(
            userId: userId,
            approvalStatus: ApprovalStatus.pending,
            accessDate: AccessControlService.generalAccessDate,
            membershipTier: SubscriptionTier.basic,
          );
          _isCheckingAccess = false;
        });
      }
    }
  }

  /// The access decision from the LOCAL Firestore cache, or null when the
  /// server must decide. Only a cached "let them in" is trusted: anything
  /// that would route the user away (onboarding, ban, rejection) waits for
  /// the server, so a stale cache never blocks a user who is fine. A stale
  /// "let them in" lasts only until [_verifyAccessInBackground] corrects it;
  /// the security rules enforce access on every read regardless.
  Future<_AccessDecision?> _resolveAccessFromCache(String userId) async {
    try {
      final (profileDoc, accessData) = await (
        FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get(const GetOptions(source: Source.cache)),
        _accessControlService.getCachedUserAccess(),
      ).wait.timeout(const Duration(seconds: 2));
      final profile = profileDoc.data();
      // Admin accounts always take the server path: it runs the admin data
      // sync and gets them to 2FA. `isAdmin` is set on the profile first
      // (ensureAdminDataComplete copies it to `users`), so either cached doc
      // saying admin is enough. There is no admin auth claim to check.
      if (profile == null ||
          accessData == null ||
          profile['isComplete'] != true ||
          profile['isBanned'] == true ||
          profile['isAdmin'] == true ||
          accessData.isAdmin ||
          accessData.approvalStatus == ApprovalStatus.rejected) {
        return null;
      }
      await _cacheBusinessFlag(profile['isBusiness'] == true);
      return _AccessDecision(
        needsOnboarding: false,
        banned: false,
        accessData: accessData,
      );
    } catch (_) {
      return null; // not cached (or cache unavailable) — ask the server
    }
  }

  /// Server-authoritative access decision. Every read is time-boxed: a
  /// server-source read has no deadline of its own, so a blocked or stalled
  /// Firestore channel (common on web behind a proxy) would otherwise hang
  /// here without ever throwing.
  Future<_AccessDecision> _resolveAccessFromServer(String userId) async {
    Map<String, dynamic>? profile;
    var profileExists = false;
    var profileFromServer = false;

    Future<bool> readProfile() async {
      profileFromServer = false;
      try {
        final doc = await _accessControlService
            .serverDoc('profiles', userId)
            .timeout(const Duration(seconds: 8));
        profileExists = doc.exists;
        profile = doc.data();
        profileFromServer = true;
        return true;
      } catch (e) {
        debugPrint('Profile check error: $e');
        // Fallback to default source if server unavailable
        try {
          final doc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(userId)
              .get()
              .timeout(const Duration(seconds: 6));
          profileExists = doc.exists;
          profile = doc.data();
          return true;
        } catch (_) {
          return false;
        }
      }
    }

    var profileRead = await readProfile();

    // Admin accounts get isAdmin=true / approvalStatus=approved written to
    // `users` before access is read (prevents "under review"), and a missing
    // profile may be an admin whose profile gets created. Everyone else skips
    // it: for them it is a no-op that cost a profile read on every launch.
    // Time-boxed so a slow admin sync never strands anyone on the splash.
    if (profileRead && (!profileExists || profile?['isAdmin'] == true)) {
      var synced = false;
      try {
        synced = await AdminDataUtils.ensureAdminDataComplete()
            .timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('⚠ Admin data sync skipped: $e');
      }
      if (synced) {
        // The sync may have written both docs: read them fresh.
        AccessControlService.invalidateOwnDoc('profiles', userId);
        AccessControlService.invalidateOwnDoc('users', userId);
        profileRead = await readProfile();
      }
    }

    if (profileRead) {
      await _cacheBusinessFlag(profile?['isBusiness'] == true);
    }
    // Could not read the doc at all — fail open, never lock out.
    final needsOnboarding =
        !profileRead || !profileExists || profile?['isComplete'] != true;
    // Permanent ban: only a positively-read isBanned==true locks out.
    if (profileExists && profile?['isBanned'] == true) {
      debugPrint('🚫 Account $userId is permanently banned — blocking access');
      return _AccessDecision(
        needsOnboarding: needsOnboarding,
        banned: true,
        authoritative: profileFromServer,
      );
    }

    // Same reasoning as the profile read: bounded, so a stalled channel
    // surfaces as the fallback below rather than an endless splash. A failed
    // or timed-out server read is kept apart from "no doc on the server", so
    // it can never lead to the doc being re-initialized.
    var accessReadFailed = false;
    UserAccessData? accessData;
    try {
      accessData = await _accessControlService
          .getCurrentUserAccess(
            profileData: profileFromServer ? profile : null,
            throwIfServerUnavailable: true,
          )
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('🔑 Access read failed for $userId: $e');
      accessReadFailed = true;
      // Show what this device last saw, if anything (not authoritative).
      accessData = await _accessControlService.getCachedUserAccess();
    }
    debugPrint('🔑 Access data for $userId: isAdmin=${accessData?.isAdmin}, '
        'isTestUser=${accessData?.isTestUser}, '
        'approvalStatus=${accessData?.approvalStatus}, '
        'tier=${accessData?.membershipTier}');

    // If no access data exists on the server, create it now. Never after a
    // failed read: the doc may well exist, and re-initializing it would reset
    // approvalStatus and membershipTier (merge write).
    if (accessData == null && !accessReadFailed) {
      debugPrint('🔑 No access data found — creating for $userId');
      try {
        final email = FirebaseAuth.instance.currentUser?.email;
        await _accessControlService.initializeUserAccess(
          userId: userId,
          email: email ?? '',
        );
        accessData = await _accessControlService.getCurrentUserAccess(
          profileData: profileFromServer ? profile : null,
        );
      } catch (e) {
        debugPrint('⚠️ Failed to create access data: $e');
      }
    }
    // If still null, use a fallback so user isn't stuck
    accessData ??= UserAccessData(
      userId: userId,
      approvalStatus: ApprovalStatus.pending,
      accessDate: AccessControlService.generalAccessDate,
      membershipTier: SubscriptionTier.basic,
    );

    // Admin and test users ALWAYS get through — force approve if needed
    if ((accessData.isAdmin || accessData.isTestUser) &&
        accessData.approvalStatus != ApprovalStatus.approved) {
      debugPrint('🔑 Force-approving admin/test user $userId');
      await _accessControlService.approveUser(userId, 'system');
      accessData = accessData.copyWith(approvalStatus: ApprovalStatus.approved);
    }

    return _AccessDecision(
      needsOnboarding: needsOnboarding,
      banned: false,
      accessData: accessData,
      authoritative: profileFromServer && !accessReadFailed,
    );
  }

  /// Confirms a cache-based decision with the server and re-routes only if
  /// the server disagrees (e.g. access revoked, banned, profile incomplete).
  /// A result that could not actually reach the server never overrides it.
  Future<void> _verifyAccessInBackground(
      String userId, _AccessDecision shown) async {
    try {
      final fresh = await _resolveAccessFromServer(userId);
      if (!mounted ||
          _isSigningOut ||
          FirebaseAuth.instance.currentUser?.uid != userId ||
          !fresh.authoritative) {
        return;
      }
      if (fresh.routesSameAs(shown)) {
        // Same screen either way: keep the fresher copy without a rebuild.
        _accessData = fresh.accessData ?? _accessData;
        return;
      }
      debugPrint('🔑 Server access differs from cache — re-routing $userId');
      _applyAccessDecision(userId, fresh);
    } catch (e) {
      debugPrint('🔑 Background access check error: $e');
    }
  }

  void _applyAccessDecision(String userId, _AccessDecision decision) {
    if (!mounted) return;
    setState(() {
      _needsOnboarding = decision.needsOnboarding;
      _accountBanned = decision.banned;
      _accessData = decision.banned ? null : decision.accessData;
      _isCheckingAccess = false;
    });
    final accessData = decision.accessData;
    // Prompt for notifications (after the frame) for admin/test and approved
    // users.
    if (!decision.banned &&
        accessData != null &&
        (accessData.isAdmin ||
            accessData.isTestUser ||
            accessData.approvalStatus == ApprovalStatus.approved)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowNotificationPrompt(userId);
      });
    }
  }

  /// Drops every per-user, per-session cache so the next account (or the
  /// same one signing back in) starts clean.
  void _clearSessionCaches() {
    unawaited(LastResultCache.clear());
    SessionCacheGate.reset();
    AccessControlService.clearSessionCache();
    DataPreloadService.instance.reset();
    // ── Other packages' per-user session state (Events / Discovery) ──
    // EventsPrefetch.reset() also resets EventsLocation and the external
    // events preloader.
    EventsPrefetch.reset();
    DiscoveryPrefetch.reset();
  }

  bool _isSigningOut = false;

  void _handleSignOut() {
    _isSigningOut = true;
    // Clear all caches before signing out
    try {
      final datasource = GetIt.I<DiscoveryRemoteDataSource>();
      datasource.clearAllDiscoveryCaches();
    } catch (_) {}
    try {
      CacheService.instance.clearAll();
    } catch (_) {}
    // Clear cached business flag so the next account's splash isn't mislabeled.
    _cacheBusinessFlag(false);

    context.read<AuthBloc>().add(const AuthSignOutRequested());
    OnboardingGate.reset();
    setState(() {
      _accessData = null;
      _needsOnboarding = false;
      _notificationPromptShown = false;
      _admin2FAVerified = false;
      _showPostLoginSplash = false;
      _routedUserId = null;
      _isCheckingAccess = false;
      _accountBanned = false;
      Admin2FAScreen.resetVerification();
    });
  }


  void _handleRefresh() {
    setState(() {
      _accessData = null;
    });
    // Re-check access status with the server (the user asked for a refresh)
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _checkAccessStatus(state.user.uid, useCache: false);
    }
  }

  Future<void> _handleReverify() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ReverificationScreen(
          userId: userId,
        ),
      ),
    );

    if (result == true) {
      _handleRefresh();
    }
  }

  Future<void> _handleContactSupport() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@greengochat.com',
      queryParameters: {
        'subject': 'Account Rejection Appeal',
        'body': 'User ID: $userId\n\nPlease describe your issue:\n',
      },
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      // Email client not available
    }
  }

  Future<void> _handleEnableNotifications() async {
    final notificationRepo = di.sl<NotificationRepository>();

    // 1. Request OS notification permission (shows system dialog)
    final permResult = await notificationRepo.requestPermission();
    final granted = permResult.fold((_) => false, (ok) => ok);

    // 2. Get and save FCM token (best-effort, non-blocking on failure)
    if (granted) {
      try {
        final tokenResult = await notificationRepo.getFCMToken();
        await tokenResult.fold(
          (_) async {},
          (token) async {
            if (token != null) {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await notificationRepo.saveFCMToken(uid, token);
              }
            }
          },
        );
      } catch (_) {}
    }

    // 3. Set Firestore flag + refresh access data so button disappears
    if (!mounted) return;
    context.read<AuthBloc>()
      ..add(const AuthEnableNotificationsRequested())
      ..add(const AuthCheckAccessStatusRequested());
  }

  /// Show a one-time styled notification permission dialog for approved users
  /// who haven't been asked yet (skips WaitingScreen prompt path).
  Future<void> _maybeShowNotificationPrompt(String userId) async {
    if (_notificationPromptShown) return;
    _notificationPromptShown = true;

    // Sequence first-login prompts: wait for the community-guidelines gate so
    // this prompt shows AFTER it, not stacked on top. Bounded fallback in case
    // the gate never completes (e.g. guidelines already accepted long ago).
    await OnboardingGate.guidelinesHandled
        .timeout(const Duration(seconds: 10), onTimeout: () {});
    if (!mounted) return;

    try {
      // Drive the prompt off the REAL OS permission status, not a Firestore
      // flag. A flag ('notificationPermissionAsked'/'notificationsEnabled') can
      // be true from another device/session or from BEFORE the user actually
      // granted — gating on it means a device whose OS was never asked (new
      // device, reinstall, flagged-then-declined) silently gets no push. The OS
      // status is per-device and authoritative.
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final status = settings.authorizationStatus;

      // Already granted on THIS device → the login path already saved the token.
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        return;
      }
      // Denied → the OS won't show its system prompt again, but we still ASK the
      // user to turn notifications on, pointing them to the app's Settings page.
      if (status == AuthorizationStatus.denied) {
        if (!mounted) return;
        final l10nD = AppLocalizations.of(context);
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.charcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.richGold, width: 1.5),
            ),
            title: Text(
              l10nD?.notificationDialogTitle ?? 'Stay Connected',
              style: const TextStyle(
                  color: AppColors.richGold, fontWeight: FontWeight.bold),
            ),
            content: Text(
              l10nD?.notificationEnableInSettingsBody ??
                  'Notifications are off. Turn them on in Settings to get messages, events and community alerts.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  l10nD?.notificationDialogNotNow ?? 'Not Now',
                  style: const TextStyle(color: AppColors.textTertiary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettings();
                },
                child: Text(
                  l10nD?.notificationOpenSettings ?? 'Open Settings',
                  style: const TextStyle(
                      color: AppColors.richGold, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
        return;
      }

      // status == notDetermined → show the styled pre-prompt, then the OS dialog.
      if (!mounted) return;

      // Show the styled dialog
      final l10n = AppLocalizations.of(context);
      final enable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.richGold, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_active,
                    color: AppColors.richGold, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n?.notificationDialogTitle ?? 'Stay Connected',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n?.notificationDialogMessage ?? 'Enable notifications to know when you get matches, messages, and super likes.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l10n?.notificationDialogEnable ?? 'Enable',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n?.notificationDialogNotNow ?? 'Not Now',
                      style: const TextStyle(color: AppColors.textTertiary)),
                ),
              ],
            ),
          ),
        ),
      );

      // Mark as asked regardless of choice
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notificationPermissionAsked': true,
      });

      if (enable == true) {
        _handleEnableNotifications();
      }
    } catch (e) {
      debugPrint('⚠ Notification prompt error: $e');
    }
  }

  /// Returns PostLoginSplashScreen if splash hasn't been shown yet,
  /// otherwise returns MainNavigationScreen directly.
  Widget _buildMainOrSplash(String userId) {
    if (_showPostLoginSplash) {
      // Prefetch the shared Firestore data (profile, conversations, inbox,
      // events) DURING the splash animation so the first tab (Explore) opens
      // against a warm cache. Idempotent (guarded by DataPreloadService._done),
      // so the redundant call from MainNavigationScreen.initState is a no-op.
      DataPreloadService.instance.warm(userId);
      return PostLoginSplashScreen(
        onComplete: () {
          _signInPending = false;
          if (mounted) {
            setState(() {
              _showPostLoginSplash = false;
            });
          }
        },
      );
    }
    return MainNavigationScreen(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        // Reset signing-out flag as soon as we get any new auth state,
        // so it never blocks a subsequent re-login
        if (state is AuthAuthenticated) {
          _isSigningOut = false;
        }
        // When user becomes authenticated, check their access status and load language
        if (state is AuthAuthenticated) {
          await _onAuthenticated(state.user);
        }
        if (_isSignedOutState(state)) _signInPending = true;
        // When user signs out, reset access state to prevent stuck splash
        if (state is AuthInitial || state is AuthUnauthenticated) {
          _isSigningOut = false;
          _clearSessionCaches();
          setState(() {
            _accessData = null;
            _needsOnboarding = false;
            _isCheckingAccess = false;
            _admin2FAVerified = false;
            _showPostLoginSplash = false;
            _routedUserId = null;
            _accountBanned = false;
            Admin2FAScreen.resetVerification();
          });
        }
      },
      builder: (context, state) {
        // Permanent ban takes priority over every other state: block access.
        if (_accountBanned && state is AuthAuthenticated) {
          return BannedScreen(onSignOut: _handleSignOut);
        }
        if (state is AuthInitial || _isCheckingAccess) {
          return const SplashScreen();
        } else if (state is AuthWaitingForAccess) {
          // Admin users must complete 2FA before accessing the app
          if (_accessData != null && _accessData!.isAdmin && !_admin2FAVerified) {
            return Admin2FAScreen(
              onVerified: () => setState(() => _admin2FAVerified = true),
              onSignOut: _handleSignOut,
            );
          }
          // Check if profile is complete before entering app
          if (_needsOnboarding) {
            return profile.OnboardingScreen(userId: state.user.uid);
          }
          // Rejected users — show review screen with resubmission request
          if (state.approvalStatus == 'rejected') {
            const waitingApprovalStatus = ApprovalStatus.rejected;
            return WaitingScreen(
              accessData: UserAccessData(
                userId: state.user.uid,
                approvalStatus: waitingApprovalStatus,
                accessDate: state.accessDate,
                membershipTier: SubscriptionTier.values.firstWhere(
                  (e) => e.name == state.membershipTier,
                  orElse: () => SubscriptionTier.basic,
                ),
                notificationsEnabled: false,
                hasEarlyAccess: state.accessDate.isBefore(AccessControlService.generalAccessDate),
              ),
              onSignOut: _handleSignOut,
              onRefresh: _handleRefresh,
              onReverify: _handleReverify,
              onContactSupport: _handleContactSupport,
            );
          }
          // Pending and approved users — go straight to app
          return _buildMainOrSplash(state.user.uid);
        } else if (state is AuthAuthenticated) {
          // If profile is incomplete, always redirect to onboarding first
          if (_needsOnboarding) {
            return profile.OnboardingScreen(userId: state.user.uid);
          }
          // Check if we have access data and if user should wait
          if (_accessData != null) {
            // Admin users must complete 2FA before accessing the app
            if (_accessData!.isAdmin && !_admin2FAVerified) {
              return Admin2FAScreen(
                onVerified: () => setState(() => _admin2FAVerified = true),
                onSignOut: _handleSignOut,
              );
            }
            // Rejected users — show review screen with resubmission request
            if (_accessData!.approvalStatus == ApprovalStatus.rejected) {
              return WaitingScreen(
                accessData: _accessData,
                onSignOut: _handleSignOut,
                onRefresh: _handleRefresh,
                onReverify: _handleReverify,
                onContactSupport: _handleContactSupport,
              );
            }
            // Pending and approved users — let them into the app
            return _buildMainOrSplash(state.user.uid);
          }
          // Access data not loaded yet (listener is running _checkAccessStatus)
          // Show splash while we wait — no side effects in build
          return const SplashScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Outcome of an access check, as far as routing in [AuthWrapper] cares.
class _AccessDecision {
  const _AccessDecision({
    required this.needsOnboarding,
    required this.banned,
    this.accessData,
    this.authoritative = true,
  });

  final bool needsOnboarding;
  final bool banned;
  final UserAccessData? accessData;

  /// False when the server could not be reached and this was assembled from
  /// fallbacks; such a result never overrides what is already on screen.
  final bool authoritative;

  /// Whether [other] would show the same screen (and the same approval, which
  /// decides the notification prompt).
  bool routesSameAs(_AccessDecision other) =>
      needsOnboarding == other.needsOnboarding &&
      banned == other.banned &&
      (accessData?.isAdmin ?? false) == (other.accessData?.isAdmin ?? false) &&
      accessData?.approvalStatus == other.accessData?.approvalStatus;
}

/// Full-screen block shown to a permanently-banned account.
///
/// Rendered by [AuthWrapper] whenever the post-login profile fetch reads
/// `profiles/{uid}.isBanned == true`. The account keeps no in-app access; the
/// only action is to sign out.
class BannedScreen extends StatelessWidget {
  const BannedScreen({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block,
                  size: 72,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.accountBannedTitle ?? 'Account permanently banned',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.accountBannedBody ??
                      'This account has been permanently banned for violating '
                          'our content policy. This decision is final.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSignOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n?.signOut ?? 'Sign out'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Initial loading splash screen (shown while checking auth state)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Timer _timer;
  int _currentMsgIndex = 0;
  late final List<int> _shuffledIndices;

  List<String> _getLoadingMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return ['Loading...'];
    return [
      l10n.loadingMsg1, l10n.loadingMsg2, l10n.loadingMsg3, l10n.loadingMsg4,
      l10n.loadingMsg5, l10n.loadingMsg6, l10n.loadingMsg7, l10n.loadingMsg8,
      l10n.loadingMsg9, l10n.loadingMsg10, l10n.loadingMsg11, l10n.loadingMsg12,
      l10n.loadingMsg13, l10n.loadingMsg14, l10n.loadingMsg15, l10n.loadingMsg16,
      l10n.loadingMsg17, l10n.loadingMsg18, l10n.loadingMsg19, l10n.loadingMsg20,
      l10n.loadingMsg21, l10n.loadingMsg22, l10n.loadingMsg23, l10n.loadingMsg24,
    ];
  }

  @override
  void initState() {
    super.initState();
    _shuffledIndices = List.generate(24, (i) => i)..shuffle();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentMsgIndex = (_currentMsgIndex + 1) % _shuffledIndices.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _getLoadingMessages(context);
    final displayIndex = _shuffledIndices[_currentMsgIndex] % messages.length;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/greengo_logo.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Padding(
                key: ValueKey<int>(displayIndex),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  messages[displayIndex],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              color: Color(0xFFD4AF37),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
