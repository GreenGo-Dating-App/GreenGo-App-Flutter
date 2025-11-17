import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/providers/language_provider.dart';
import 'core/di/injection_container.dart' as di;
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/bloc/auth_state.dart';
import 'features/authentication/presentation/screens/login_screen.dart';
import 'features/authentication/presentation/screens/register_screen.dart';
import 'features/authentication/presentation/screens/forgot_password_screen.dart';
import 'features/profile/presentation/screens/onboarding_screen.dart' as profile;
import 'features/main/presentation/screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Remote Config with default values
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
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

  runApp(const GreenGoChatApp());
}

class GreenGoChatApp extends StatelessWidget {
  const GreenGoChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
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
              return null;
            },
          );
        },
      ),
    );
  }
}

/// AuthWrapper - Determines initial route based on authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const SplashScreen();
        } else if (state is AuthAuthenticated) {
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


