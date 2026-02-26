import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/auth_error_localizer.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/widgets/luxury_particles_background.dart';
import '../../../../core/widgets/animated_luxury_logo.dart';
import '../../../../core/widgets/connection_error_dialog.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

// Conditional imports based on feature flags
// Only import if the corresponding feature is enabled in AppConfig
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Enable when AppConfig.enableGoogleAuth or enableFacebookAuth = true
// import '../widgets/social_login_button.dart'; // Enable when any social auth is enabled

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Check if we mounted with an existing error state (e.g., after AuthWrapper rebuild)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentState = context.read<AuthBloc>().state;
      if (currentState is AuthError) {
        _showErrorDialog(currentState.message);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String message) {
    final errorMessage = message.toLowerCase();

    // Check for explicit NETWORK_ERROR prefix or network-related keywords
    final isConnectionError = message.startsWith('NETWORK_ERROR') ||
        errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('internet') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('socket') ||
        errorMessage.contains('host') ||
        errorMessage.contains('unreachable') ||
        errorMessage.contains('unavailable') ||
        errorMessage.contains('failed to connect') ||
        errorMessage.contains('no address') ||
        errorMessage.contains('recaptcha');

    if (isConnectionError) {
      ConnectionErrorDialog.showConnectionError(
        context,
        onRetry: _handleLogin,
      );
    } else if (errorMessage.contains('server') ||
        errorMessage.contains('500') ||
        errorMessage.contains('503') ||
        errorMessage.contains('internal')) {
      ConnectionErrorDialog.showServerError(
        context,
        onRetry: _handleLogin,
      );
    } else {
      final localizedMessage = AuthErrorLocalizer.getLocalizedError(
        context,
        message,
      );
      ConnectionErrorDialog.showAuthError(
        context,
        title: AppLocalizations.of(context)!.authenticationErrorTitle,
        message: localizedMessage,
        onRetry: _handleLogin,
      );
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthSignInWithEmailRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  /// Build a social login button with consistent styling
  Widget _buildSocialLoginButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1.5),
        color: AppColors.backgroundCard,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Center(
            child: Icon(
              icon,
              size: 28,
              color: AppColors.richGold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return LuxuryParticlesBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          // Always listen for error states — prevents race conditions
          // where authStateChanges overwrites the error before dialog shows
          listenWhen: (previous, current) => current is AuthError,
          listener: (context, state) {
            if (state is AuthError) {
              _showErrorDialog(state.message);
            }
            // AuthAuthenticated is handled by AuthWrapper — no navigation here
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Animated Luxury Logo
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const AnimatedLuxuryLogo(
                        assetPath: 'assets/images/greengo_main_logo_gold.png',
                        size: 200,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Form Fields
                    SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          // Email Field
                          AuthTextField(
                            controller: _emailController,
                            label: l10n.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            prefixIcon: Icons.email_outlined,
                            enabled: !isLoading,
                          ),

                          const SizedBox(height: 16),

                          // Password Field
                          AuthTextField(
                            controller: _passwordController,
                            label: l10n.password,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppStrings.passwordRequired;
                              }
                              return null;
                            },
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.textTertiary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            enabled: !isLoading,
                          ),

                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context)
                                          .pushNamed('/forgot-password');
                                    },
                              child: Text(
                                l10n.forgotPassword,
                                style: const TextStyle(
                                  color: AppColors.richGold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Button
                          AuthButton(
                            text: l10n.login,
                            onPressed: isLoading ? null : _handleLogin,
                            isLoading: isLoading,
                          ),

                          const SizedBox(height: 24),

                          // Social Login Section (conditionally rendered)
                          if (AppConfig.showSocialLoginSection) ...[
                            // Divider
                            Row(
                              children: [
                                const Expanded(
                                    child: Divider(color: AppColors.divider)),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    l10n.orContinueWith,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                const Expanded(
                                    child: Divider(color: AppColors.divider)),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Social Login Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Google Login Button
                                if (AppConfig.enableGoogleAuth)
                                  _buildSocialLoginButton(
                                    context: context,
                                    icon: Icons.g_mobiledata, // Placeholder - use FontAwesome when enabled
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            context.read<AuthBloc>().add(
                                                  const AuthSignInWithGoogleRequested(),
                                                );
                                          },
                                  ),

                                // Facebook Login Button
                                if (AppConfig.enableFacebookAuth)
                                  _buildSocialLoginButton(
                                    context: context,
                                    icon: Icons.facebook, // Placeholder - use FontAwesome when enabled
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            context.read<AuthBloc>().add(
                                                  const AuthSignInWithFacebookRequested(),
                                                );
                                          },
                                  ),

                                // Biometric Login Button
                                if (AppConfig.enableBiometricAuth)
                                  _buildSocialLoginButton(
                                    context: context,
                                    icon: Icons.fingerprint,
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            context.read<AuthBloc>().add(
                                                  const AuthBiometricSignInRequested(),
                                                );
                                          },
                                  ),

                                // Apple Login Button
                                if (AppConfig.enableAppleAuth)
                                  _buildSocialLoginButton(
                                    context: context,
                                    icon: Icons.apple,
                                    onTap: isLoading
                                        ? null
                                        : () {
                                            // TODO: Implement Apple Sign In
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Apple Sign-In coming soon'),
                                              ),
                                            );
                                          },
                                  ),
                              ],
                            ),

                            const SizedBox(height: 24),
                          ],

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.dontHaveAccount,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/register');
                                      },
                                child: Text(
                                  l10n.signUp,
                                  style: const TextStyle(
                                    color: AppColors.richGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // App Version
                          FutureBuilder<PackageInfo>(
                            future: PackageInfo.fromPlatform(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  'v${snapshot.data!.version}',
                                  style: const TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }
}
