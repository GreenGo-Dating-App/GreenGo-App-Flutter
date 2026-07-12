import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

import 'core/config/app_config.dart';
import 'core/config/flavor_config.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection_container.dart' as di;
import 'core/providers/language_provider.dart';
import 'core/services/access_control_service.dart';
import 'core/services/app_sound_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/feature_flags_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/version_check_service.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/admin_data_utils.dart';
import 'core/utils/seed_data.dart';
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

  // Print app configuration (for debugging)
  AppConfig.printConfig();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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

  // Load countdown dates from Firestore (non-blocking, uses defaults on failure)
  AccessControlService.loadCountdownDatesFromFirestore();

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
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      debugPrint('✓ Auth Emulator: $emulatorHost:9099');

      // Connect to Firestore Emulator
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      debugPrint('✓ Firestore Emulator: $emulatorHost:8080');

      // Connect to Storage Emulator
      await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      debugPrint('✓ Storage Emulator: $emulatorHost:9199');

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

  // Initialize Firebase Remote Config with default values
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: kDebugMode ? 10 : 60),
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

    // Fetch and activate config
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Remote Config initialization error: $e');
  }

  // Initialize dependency injection
  await di.init();

  // Initialize sound service
  await AppSoundService().initialize();
  debugPrint('✓ Sound service initialized');

  // Initialize feature flags service (loads from Firestore)
  await featureFlags.initialize();
  debugPrint('✓ Feature flags initialized');

  // Initialize version check service
  await versionCheck.initialize();
  debugPrint('✓ Version check initialized');

  // Initialize push notification service (FCM handlers)
  await pushNotificationService.initialize();
  debugPrint('✓ Push notification service initialized');

  // Load saved language before app starts (prevents flicker)
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language');

  runApp(GreenGoChatApp(savedLanguage: savedLanguage));
}

class GreenGoChatApp extends StatelessWidget {

  const GreenGoChatApp({super.key, this.savedLanguage});
  final String? savedLanguage;

  @override
  Widget build(BuildContext context) {
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
  String? _splashUserId;
  UserAccessData? _accessData;
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
      if (authState is AuthAuthenticated && !_isCheckingAccess) {
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

  void _checkVersion() {
    if (_hasCheckedVersion) return;
    _hasCheckedVersion = true;

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
  /// The `_isCheckingAccess` / `_splashUserId` guards make it idempotent so the
  /// two entry points never double-run the work.
  Future<void> _onAuthenticated(dynamic user) async {
    _isSigningOut = false;
    // Guard: skip if already checking access for this user (prevents duplicate
    // calls from double AuthAuthenticated emission via login handler + auth
    // stream, or from listener + initState).
    if (_isCheckingAccess && _splashUserId == user.uid) return;
    // Set checking flag IMMEDIATELY to prevent WaitingScreen flash
    // (builder runs before async work completes)
    setState(() {
      _isCheckingAccess = true;
      // Show post-login splash on fresh login
      if (!_showPostLoginSplash && _splashUserId != user.uid) {
        _showPostLoginSplash = true;
        _splashUserId = user.uid;
      }
    });
    // Ensure admin profiles have isAdmin=true and approvalStatus=approved
    // in the users collection BEFORE checking access (prevents "under review")
    await AdminDataUtils.ensureAdminDataComplete();
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

  Future<void> _checkAccessStatus(String userId) async {
    // _isCheckingAccess is already set to true by the listener
    if (!_isCheckingAccess) {
      setState(() {
        _isCheckingAccess = true;
      });
    }

    try {
      // Positively set true only when a profile doc is actually read with
      // isBanned == true. Stays false on any read error (fail-open).
      var accountBanned = false;
      // Check if user profile exists and is complete (force server to avoid stale cache)
      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(userId)
            .get(const GetOptions(source: Source.server));
        _needsOnboarding = !profileDoc.exists ||
            profileDoc.data()?['isComplete'] != true;
        // Permanent ban: only a positively-read isBanned==true locks out.
        accountBanned = profileDoc.exists &&
            profileDoc.data()?['isBanned'] == true;
        // Cache business-account flag so the post-login splash can label it
        // without needing the full Profile loaded.
        await _cacheBusinessFlag(profileDoc.data()?['isBusiness'] == true);
      } catch (e) {
        debugPrint('Profile check error: $e');
        // Fallback to default source if server unavailable
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('profiles')
              .doc(userId)
              .get();
          _needsOnboarding = !profileDoc.exists ||
              profileDoc.data()?['isComplete'] != true;
          accountBanned = profileDoc.exists &&
              profileDoc.data()?['isBanned'] == true;
          await _cacheBusinessFlag(profileDoc.data()?['isBusiness'] == true);
        } catch (_) {
          // Could not read the doc at all — fail open, never lock out.
          _needsOnboarding = true;
          accountBanned = false;
        }
      }

      // Enforce permanent ban before any access is granted.
      if (accountBanned) {
        debugPrint('🚫 Account $userId is permanently banned — blocking access');
        if (mounted) {
          setState(() {
            _accountBanned = true;
            _accessData = null;
            _isCheckingAccess = false;
          });
        }
        return;
      }

      var accessData = await _accessControlService.getCurrentUserAccess();
      debugPrint('🔑 Access data for $userId: isAdmin=${accessData?.isAdmin}, '
          'isTestUser=${accessData?.isTestUser}, '
          'approvalStatus=${accessData?.approvalStatus}, '
          'tier=${accessData?.membershipTier}');

      // If no access data exists, create it now
      if (accessData == null) {
        debugPrint('🔑 No access data found — creating for $userId');
        try {
          final email = FirebaseAuth.instance.currentUser?.email;
          await _accessControlService.initializeUserAccess(
            userId: userId,
            email: email ?? '',
          );
          accessData = await _accessControlService.getCurrentUserAccess();
        } catch (e) {
          debugPrint('⚠️ Failed to create access data: $e');
        }
        // If still null, use a fallback so user isn't stuck
        accessData ??= UserAccessData(
          userId: userId,
          approvalStatus: ApprovalStatus.pending,
          accessDate: AccessControlService.generalAccessDate,
          membershipTier: SubscriptionTier.basic,
        );
      }

      // Admin and test users ALWAYS get through — force approve if needed
      if (accessData.isAdmin || accessData.isTestUser) {
        if (accessData.approvalStatus != ApprovalStatus.approved) {
          debugPrint('🔑 Force-approving admin/test user $userId');
          await _accessControlService.approveUser(userId, 'system');
          final correctedData = await _accessControlService.getCurrentUserAccess();
          if (mounted) {
            setState(() {
              _accessData = correctedData ?? accessData;
              _isCheckingAccess = false;
            });
            // Prompt for notifications after frame renders
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _maybeShowNotificationPrompt(userId);
            });
          }
          return;
        }
        // Already approved — set data and proceed
        if (mounted) {
          setState(() {
            _accessData = accessData;
            _isCheckingAccess = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowNotificationPrompt(userId);
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _accessData = accessData;
          _isCheckingAccess = false;
        });
        // Show notification prompt for approved non-admin users
        if (accessData.approvalStatus == ApprovalStatus.approved) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _maybeShowNotificationPrompt(userId);
          });
        }
      }
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
    setState(() {
      _accessData = null;
      _needsOnboarding = false;
      _notificationPromptShown = false;
      _admin2FAVerified = false;
      _showPostLoginSplash = false;
      _splashUserId = null;
      _isCheckingAccess = false;
      _accountBanned = false;
      Admin2FAScreen.resetVerification();
    });
  }


  void _handleRefresh() {
    setState(() {
      _accessData = null;
    });
    // Re-check access status
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _checkAccessStatus(state.user.uid);
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

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final notificationsEnabled = data['notificationsEnabled'] == true;
      final permissionAsked = data['notificationPermissionAsked'] == true;

      // Already enabled or already asked — nothing to do
      if (notificationsEnabled || permissionAsked) return;
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
      return PostLoginSplashScreen(
        onComplete: () {
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
        // When user signs out, reset access state to prevent stuck splash
        if (state is AuthInitial || state is AuthUnauthenticated) {
          _isSigningOut = false;
      
          setState(() {
            _accessData = null;
            _needsOnboarding = false;
            _isCheckingAccess = false;
            _admin2FAVerified = false;
            _showPostLoginSplash = false;
            _splashUserId = null;
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
