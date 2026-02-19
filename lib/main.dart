import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'core/utils/admin_data_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/language_provider.dart';
import 'core/di/injection_container.dart' as di;
import 'core/utils/seed_data.dart';
import 'core/services/feature_flags_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/version_check_service.dart';
import 'core/widgets/update_dialog.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_event.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/authentication/presentation/screens/waiting_screen.dart';
import 'core/services/access_control_service.dart';
import 'features/subscription/domain/entities/subscription.dart';
import 'features/authentication/presentation/screens/register_screen.dart';
import 'features/authentication/presentation/screens/forgot_password_screen.dart';
import 'features/profile/presentation/screens/onboarding_screen.dart' as profile;
import 'features/main/presentation/screens/main_navigation_screen.dart';
import 'features/language_learning/presentation/screens/language_learning_home_screen.dart';
import 'features/language_learning/presentation/screens/language_detail_screen.dart';
import 'features/language_learning/presentation/screens/flashcard_session_screen.dart';
import 'features/admin/presentation/screens/early_access_admin_screen.dart';
import 'features/admin/presentation/screens/support_tickets_screen.dart';
import 'features/admin/presentation/screens/verification_admin_screen.dart';
import 'features/admin/presentation/screens/reports_admin_screen.dart';
import 'features/admin/presentation/screens/tier_management_screen.dart';
import 'features/admin/presentation/screens/coin_management_screen.dart';
import 'features/admin/presentation/screens/gamification_management_screen.dart';
import 'features/chat/presentation/screens/support_tickets_list_screen.dart';
import 'features/chat/presentation/screens/support_chat_screen.dart';
import 'features/notifications/domain/repositories/notification_repository.dart';

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

  // Enable Firestore offline persistence for cost optimization
  // This caches data locally and reduces server reads
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Unlimited local cache
  );
  debugPrint('✓ Firestore offline persistence enabled');

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
    final String emulatorHost = AppConfig.emulatorHost;

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
  if (!AppConfig.useLocalEmulators) {
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
    });

    // Fetch and activate config
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('Remote Config initialization error: $e');
  }

  // Initialize dependency injection
  await di.init();

  // Initialize feature flags service (loads from Firestore)
  await featureFlags.initialize();
  debugPrint('✓ Feature flags initialized');

  // Initialize version check service
  await versionCheck.initialize();
  debugPrint('✓ Version check initialized');

  // Load saved language before app starts (prevents flicker)
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('selected_language');

  runApp(GreenGoChatApp(savedLanguage: savedLanguage));
}

class GreenGoChatApp extends StatelessWidget {
  final String? savedLanguage;

  const GreenGoChatApp({super.key, this.savedLanguage});

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
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
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

              // Language Learning routes
              if (settings.name == '/language-learning') {
                return MaterialPageRoute(
                  builder: (context) => const LanguageLearningHomeScreen(),
                );
              }

              if (settings.name == '/language-detail') {
                final args = settings.arguments as Map<String, dynamic>?;
                final languageCode = args?['languageCode'] as String?;
                if (languageCode != null) {
                  return MaterialPageRoute(
                    builder: (context) => LanguageDetailScreen(
                      languageCode: languageCode,
                    ),
                  );
                }
              }

              if (settings.name == '/flashcard-session') {
                return MaterialPageRoute(
                  builder: (context) => const FlashcardSessionScreen(),
                );
              }

              // Admin routes
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

class _AuthWrapperState extends State<AuthWrapper> {
  bool _hasCheckedVersion = false;
  bool _isCheckingAccess = false;
  UserAccessData? _accessData;
  final AccessControlService _accessControlService = AccessControlService();

  @override
  void initState() {
    super.initState();
    // Check version after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
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

  Future<void> _checkAccessStatus(String userId) async {
    // _isCheckingAccess is already set to true by the listener
    if (!_isCheckingAccess) {
      setState(() {
        _isCheckingAccess = true;
      });
    }

    try {
      final accessData = await _accessControlService.getCurrentUserAccess();
      debugPrint('🔑 Access data for $userId: isAdmin=${accessData?.isAdmin}, '
          'isTestUser=${accessData?.isTestUser}, '
          'approvalStatus=${accessData?.approvalStatus}, '
          'tier=${accessData?.membershipTier}');

      // Admin and test users ALWAYS get through — force approve if needed
      if (accessData != null && (accessData.isAdmin || accessData.isTestUser)) {
        if (accessData.approvalStatus != ApprovalStatus.approved) {
          debugPrint('🔑 Force-approving admin/test user $userId');
          await _accessControlService.approveUser(userId, 'system');
          final correctedData = await _accessControlService.getCurrentUserAccess();
          if (mounted) {
            setState(() {
              _accessData = correctedData;
              _isCheckingAccess = false;
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
        }
        return;
      }

      if (mounted) {
        setState(() {
          _accessData = accessData;
          _isCheckingAccess = false;
        });
      }
    } catch (e) {
      debugPrint('🔑 Access check error: $e');
      if (mounted) {
        setState(() {
          _accessData = null;
          _isCheckingAccess = false;
        });
      }
    }
  }

  void _handleSignOut() {
    context.read<AuthBloc>().add(AuthSignOutRequested());
    setState(() {
      _accessData = null;
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

  void _handleEnableNotifications() async {
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
      ..add(AuthEnableNotificationsRequested())
      ..add(AuthCheckAccessStatusRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) async {
        // When user becomes authenticated, check their access status and load language
        if (state is AuthAuthenticated) {
          // Set checking flag IMMEDIATELY to prevent WaitingScreen flash
          // (builder runs before async work completes)
          setState(() {
            _isCheckingAccess = true;
          });
          // Ensure admin profiles have isAdmin=true and approvalStatus=approved
          // in the users collection BEFORE checking access (prevents "under review")
          await AdminDataUtils.ensureAdminDataComplete();
          _checkAccessStatus(state.user.uid);
          // Load user's saved language from Firestore
          if (context.mounted) {
            context.read<LanguageProvider>().loadFromDatabase();
          }
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || _isCheckingAccess) {
          return const SplashScreen();
        } else if (state is AuthWaitingForAccess) {
          // Admin and test users bypass waiting — go straight to app
          if (_accessData != null && (_accessData!.isAdmin || _accessData!.isTestUser)) {
            return MainNavigationScreen(userId: state.user.uid);
          }
          // Also bypass if tier is 'test' (from auth state directly)
          if (state.membershipTier == 'test') {
            return MainNavigationScreen(userId: state.user.uid);
          }
          // Approved users bypass waiting — profile is verified
          if (state.approvalStatus == 'approved') {
            return MainNavigationScreen(userId: state.user.uid);
          }
          // User is waiting for access (pending or rejected)
          return WaitingScreen(
            accessData: UserAccessData(
              userId: state.user.uid,
              approvalStatus: ApprovalStatus.values.firstWhere(
                (e) => e.name == state.approvalStatus,
                orElse: () => ApprovalStatus.pending,
              ),
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
            onEnableNotifications: _handleEnableNotifications,
          );
        } else if (state is AuthAuthenticated) {
          // Check if we have access data and if user should wait
          if (_accessData != null) {
            // Admin and test users ALWAYS bypass — never show waiting screen
            if (_accessData!.isAdmin || _accessData!.isTestUser) {
              return MainNavigationScreen(userId: state.user.uid);
            }
            // Approved users (verified profile) — let them into the app
            if (_accessData!.approvalStatus == ApprovalStatus.approved) {
              return MainNavigationScreen(userId: state.user.uid);
            }
            // Rejected users — show rejected waiting screen
            if (_accessData!.approvalStatus == ApprovalStatus.rejected) {
              return WaitingScreen(
                accessData: _accessData,
                onSignOut: _handleSignOut,
                onRefresh: _handleRefresh,
              );
            }
            // Pending users — show countdown (if active) or "under review" screen
            return WaitingScreen(
              accessData: _accessData,
              onSignOut: _handleSignOut,
              onRefresh: _handleRefresh,
              onEnableNotifications: _handleEnableNotifications,
            );
          } else if (_accessControlService.isPreLaunchMode) {
            // Pre-launch mode but no access data yet - show splash while loading
            // (the listener already set _isCheckingAccess = true, so this is a fallback)
            return const SplashScreen();
          }
          // User can access the app
          return MainNavigationScreen(userId: state.user.uid);
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

/// Temporary Splash Screen
/// TODO: Move to features/splash/presentation/screens/splash_screen.dart
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Icon(
                Icons.favorite,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.appTagline,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 48),
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


