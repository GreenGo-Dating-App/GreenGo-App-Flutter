import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/e2e_keys.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/auth_error_localizer.dart';
import '../../../../core/widgets/aurora_background.dart';
import '../../../../core/widgets/calm_brand_logo.dart';
import '../../../../core/widgets/connection_error_dialog.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../generated/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

// Conditional imports based on feature flags
// Only import if the corresponding feature is enabled in AppConfig
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Enable when AppConfig.enableGoogleAuth or enableFacebookAuth = true
// import '../widgets/social_login_button.dart'; // Enable when any social auth is enabled

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// Below this body height the header collapses so the Login button stays
/// above the on-screen keyboard (tablet landscape is the tight case).
const double _compactHeightBreakpoint = 640;

/// The form never stretches wider than this, however wide the screen is.
const double _formMaxWidth = 420;

/// From this width up (tablet / desktop web) the form sits in a card.
const double _cardBreakpoint = 600;

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
      begin: const Offset(0, 0.04),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: show the form immediately, no fade/slide.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _animationController.value = 1.0;
    }
  }

  /// Social sign-in button — quiet white/grey; gold stays reserved for the
  /// primary Login button.
  Widget _buildSocialLoginButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, size: 24, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Read the inset HERE, above the Scaffold: Scaffold resizes its body to
    // avoid the keyboard and hands the body a MediaQuery with viewInsets
    // zeroed, so a check further down always sees 0.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AuroraBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              // Quiet white/grey — gold is reserved for the Login button.
              child: LanguageSelector(
                iconColor: AppColors.textSecondary,
                textColor: AppColors.textSecondary,
              ),
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

              // The body is measured AFTER the Scaffold removes the keyboard
              // inset, so maxHeight is the space the form actually gets. On a
              // tablet in landscape the on-screen keyboard eats ~40% of the
              // height; with the full-size header the Login button landed below
              // the fold, behind the keyboard, and taps never reached it.
              // Collapse the header instead of pushing the button out.
              return LayoutBuilder(
                builder: (context, constraints) {
                  // Only collapse while the keyboard is up. A small phone
                  // sits under the breakpoint at rest too, and shrinking there
                  // would make the form fit exactly — removing the page's only
                  // cue that anything lies below and recreating the same trap
                  // one screen size down.
                  final compact = keyboardUp &&
                      constraints.maxHeight < _compactHeightBreakpoint;
                  final wide = constraints.maxWidth >= _cardBreakpoint;
                  final logoSize = compact ? 64.0 : (wide ? 120.0 : 112.0);
                  final topGap = compact ? 8.0 : (wide ? 16.0 : 24.0);

                  final form = _buildForm(
                    context,
                    l10n,
                    isLoading: isLoading,
                    compact: compact,
                    logoSize: logoSize,
                  );

                  return SingleChildScrollView(
                    // A drag dismisses the keyboard — on a tablet the keyboard is
                    // the only thing that can cover the button.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.paddingL,
                      topGap,
                      AppDimensions.paddingL,
                      AppDimensions.paddingL,
                    ),
                    child: ConstrainedBox(
                      // Vertically centre the column when it fits.
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight -
                                topGap -
                                AppDimensions.paddingL)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          // Full-bleed inputs look broken on a wide screen.
                          constraints: BoxConstraints(
                            maxWidth: wide ? _formMaxWidth + 80 : _formMaxWidth,
                          ),
                          child: wide ? _FormCard(child: form) : form,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isLoading,
    required bool compact,
    required double logoSize,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo — soft glow, no sparkles.
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: CalmBrandLogo(
                assetPath: 'assets/images/greengo_logo.png',
                size: logoSize,
              ),
            ),
          ),

          if (!compact) ...[
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeAnimation,
              // Narrower than the form so the line breaks into two balanced
              // lines instead of leaving a one-word orphan.
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    l10n.loginTagline,
                    key: const ValueKey('login_tagline'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(height: compact ? 24 : 40),

          // Form Fields
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email / Nickname Field (login accepts either)
                  AuthTextField(
                    fieldKey: E2EKeys.loginEmail,
                    controller: _emailController,
                    label: l10n.loginEmailOrNickname,
                    keyboardType: TextInputType.emailAddress,
                    translucent: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.authPleaseEnterEmail;
                      }
                      return null;
                    },
                    prefixIcon: Icons.email_outlined,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  // Password Field
                  AuthTextField(
                    fieldKey: E2EKeys.loginPassword,
                    controller: _passwordController,
                    label: l10n.password,
                    obscureText: _obscurePassword,
                    translucent: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.passwordRequired;
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
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    enabled: !isLoading,
                    // After typing the password the natural next move is the
                    // keyboard's Go key — wire it to the same handler as the
                    // button.
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) {
                      if (!isLoading) _handleLogin();
                    },
                  ),

                  const SizedBox(height: 8),

                  // Forgot Password — quiet, not gold.
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.of(context)
                                  .pushNamed('/forgot-password');
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: Text(
                        l10n.forgotPassword,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Button — the one strong (gold) accent on the page.
                  AuthButton(
                    key: E2EKeys.loginSubmit,
                    text: l10n.login,
                    onPressed: isLoading ? null : _handleLogin,
                    isLoading: isLoading,
                    height: 52,
                  ),

                  const SizedBox(height: 32),

                  // Social Login Section (conditionally rendered)
                  if (AppConfig.showSocialLoginSection) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n.orContinueWith,
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (AppConfig.enableGoogleAuth)
                          _buildSocialLoginButton(
                            context: context,
                            icon: Icons
                                .g_mobiledata, // Placeholder - use FontAwesome when enabled
                            onTap: isLoading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                          const AuthSignInWithGoogleRequested(),
                                        );
                                  },
                          ),
                        if (AppConfig.enableFacebookAuth)
                          _buildSocialLoginButton(
                            context: context,
                            icon: Icons
                                .facebook, // Placeholder - use FontAwesome when enabled
                            onTap: isLoading
                                ? null
                                : () {
                                    context.read<AuthBloc>().add(
                                          const AuthSignInWithFacebookRequested(),
                                        );
                                  },
                          ),
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
                        if (AppConfig.enableAppleAuth)
                          _buildSocialLoginButton(
                            context: context,
                            icon: Icons.apple,
                            onTap: isLoading
                                ? null
                                : () {
                                    // TODO: Implement Apple Sign In
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            l10n.authAppleSignInComingSoon),
                                      ),
                                    );
                                  },
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Sign Up Link. A Wrap, not a Row — the prompt + button
                  // overflow a narrow phone in the longer locales, which
                  // clipped the Sign Up tap target.
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.dontHaveAccount,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.of(context)
                                    .pushReplacementNamed('/register');
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                        ),
                        child: Text(
                          l10n.signUp,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // App Version
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          'v${snapshot.data!.version}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop / tablet container: a quiet translucent panel with a hairline
/// border so the form reads as one unit over the wide aurora.
class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 24),
        child: child,
      ),
    );
  }
}
