import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_selector.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_login_button.dart';

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
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is AuthAuthenticated) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
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

                    // Logo and Title
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/greengo_main_logo_gold.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if image fails to load
                                return Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.goldGradient,
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    size: 60,
                                    color: AppColors.deepBlack,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.appName,
                            style: Theme.of(context)
                                .textTheme
                                .displayLarge
                                ?.copyWith(color: AppColors.richGold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.appTagline,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
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
                            validator: Validators.validateEmail,
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
                              child: const Text(
                                AppStrings.forgotPassword,
                                style: TextStyle(
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

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(color: AppColors.divider)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  AppStrings.orContinueWith,
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
                              SocialLoginButton(
                                icon: 'assets/icons/google.png',
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              const AuthSignInWithGoogleRequested(),
                                            );
                                      },
                              ),
                              // SocialLoginButton(
                              //   icon: 'assets/icons/apple.png',
                              //   onPressed: isLoading
                              //       ? null
                              //       : () {
                              //           context.read<AuthBloc>().add(
                              //                 const AuthSignInWithAppleRequested(),
                              //             );
                              //         },
                              // ),
                              SocialLoginButton(
                                icon: 'assets/icons/facebook.png',
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              const AuthSignInWithFacebookRequested(),
                                            );
                                      },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Biometric Login
                          TextButton.icon(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                          const AuthBiometricSignInRequested(),
                                        );
                                  },
                            icon: const Icon(
                              Icons.fingerprint,
                              color: AppColors.richGold,
                            ),
                            label: const Text(
                              'Login with Biometrics',
                              style: TextStyle(color: AppColors.richGold),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppStrings.dontHaveAccount,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context)
                                            .pushReplacementNamed('/register');
                                      },
                                child: const Text(
                                  AppStrings.signUp,
                                  style: TextStyle(
                                    color: AppColors.richGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }
}
