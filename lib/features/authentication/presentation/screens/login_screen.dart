import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/e2e_keys.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/auth_error_localizer.dart';
import '../../../../core/widgets/calm_brand_logo.dart';
import '../../../../core/widgets/connection_error_dialog.dart';
import '../../../../core/widgets/ios_install_hint.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../core/widgets/liquid_gold_background.dart';
import '../../../../core/widgets/website_link.dart';
import '../../../../generated/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/liquid_gold_widgets.dart';

// Conditional imports based on feature flags
// Only import if the corresponding feature is enabled in AppConfig
// import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Enable when AppConfig.enableGoogleAuth or enableFacebookAuth = true
// import '../widgets/social_login_button.dart'; // Enable when any social auth is enabled

/// "Liquid Gold" login: warm near-black with slowly drifting molten-gold
/// glows ([LiquidGoldBackground]), the shimmering logo, the tagline and a
/// frosted glass form card, entering once in a calm stagger.
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

/// From this width up (tablet / desktop web) the card gets roomier padding.
const double _cardBreakpoint = 600;

/// Gold vertical gradient of the primary button (#F0CF7A → #C9A227).
const LinearGradient _goldButtonGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.liquidGoldBright, AppColors.liquidGoldDeep],
);

/// Soft dark halo behind text that sits directly on the background (not on
/// the card): keeps AA contrast even where a bright glow drifts underneath.
const List<Shadow> _onGlowShadow = [
  Shadow(color: Color(0xB3070604), blurRadius: 14),
  Shadow(color: Color(0x80070604), blurRadius: 4),
];

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Drives the staggered entrance (logo → tagline → form → footer). Runs
  /// once per visit: it lives in this State, so rebuilds (keyboard, bloc,
  /// locale) never restart it.
  late final AnimationController _entrance;
  late final List<Animation<double>> _steps;

  /// Fetched once — not on every rebuild.
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _obscurePassword = true;

  /// Tallest body height seen at this width while the keyboard was down.
  /// Layout is computed from this, never from the live height: iOS Safari
  /// changes the window height whenever its toolbar collapses/expands, and
  /// following it made the whole page jump on every scroll.
  double _stableHeight = 0;
  double _stableWidth = -1;

  double _stableBodyHeight(BoxConstraints c, {required bool keyboardUp}) {
    if (c.maxWidth != _stableWidth) {
      // Rotation or a desktop window resize: start over at this width.
      _stableWidth = c.maxWidth;
      _stableHeight = 0;
    }
    if (!keyboardUp && c.maxHeight > _stableHeight) _stableHeight = c.maxHeight;
    // Mounted with the keyboard already up: use what we have.
    return _stableHeight > 0 ? _stableHeight : c.maxHeight;
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: kEntranceTotal);
    _steps = [for (var i = 0; i < 4; i++) entranceFor(_entrance, i)];
    _entrance.forward();

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
    _entrance.dispose();
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
    // Reduced motion: show everything immediately, no fade/rise/blur.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _entrance.value = 1.0;
    }
  }

  /// Social sign-in button — quiet neutral; gold stays reserved for the
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

    return LiquidGoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              // Quiet neutral — gold is reserved for the brand + Login.
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
                  //
                  // Never on the web: there the keyboard is a browser-driven
                  // resize (iOS Safari also resizes for its toolbar), and
                  // re-laying the header on every one of those made the page
                  // jump under the user's finger.
                  final compact = !kIsWeb &&
                      keyboardUp &&
                      constraints.maxHeight < _compactHeightBreakpoint;
                  final wide = constraints.maxWidth >= _cardBreakpoint;
                  final logoSize = compact ? 56.0 : (wide ? 148.0 : 136.0);

                  final stableHeight =
                      _stableBodyHeight(constraints, keyboardUp: keyboardUp);
                  // Top-aligned content with a FIXED top gap on phones; on
                  // tablets/desktop a gap derived from the stable height (an
                  // optical centre). Never from the live height.
                  final topGap = compact
                      ? 4.0
                      : wide
                          ? ((stableHeight - 640) / 3).clamp(8.0, 220.0)
                          : 24.0;

                  const bottomPad = AppDimensions.paddingM;
                  return SingleChildScrollView(
                    // A drag dismisses the keyboard — on a tablet the keyboard is
                    // the only thing that can cover the button.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.paddingL,
                      topGap,
                      AppDimensions.paddingL,
                      bottomPad,
                    ),
                    child: ConstrainedBox(
                      // At least the viewport tall: spaceBetween then rests
                      // the footer at the bottom when the form fits, and it
                      // simply follows the form when it scrolls. (No
                      // intrinsics/flex needed, so nothing can overflow.)
                      constraints: BoxConstraints(
                        // Full width too: the scroll view hands down a loose
                        // width, and a shrink-wrapped column would sit at the
                        // left edge of a desktop window instead of centred.
                        minWidth: (constraints.maxWidth -
                                2 * AppDimensions.paddingL)
                            .clamp(0.0, double.infinity),
                        // The footer rests at the bottom of the STABLE height:
                        // a shrinking toolbar/keyboard only scrolls it out of
                        // view, it never moves anything above it.
                        minHeight: (stableHeight - topGap - bottomPad)
                            .clamp(0.0, double.infinity),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: _formMaxWidth),
                            child: _buildForm(
                              context,
                              l10n,
                              isLoading: isLoading,
                              compact: compact,
                              wide: wide,
                              logoSize: logoSize,
                            ),
                          ),
                          ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: _formMaxWidth),
                            child: Padding(
                              padding: EdgeInsets.only(top: compact ? 20 : 28),
                              child: RiseIn(
                                animation: _steps[3],
                                child: _buildFooter(
                                  context,
                                  l10n,
                                  isLoading: isLoading,
                                ),
                              ),
                            ),
                          ),
                        ],
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
    required bool wide,
    required double logoSize,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Every child is KEYED: when the tagline is left out (native
          // compact header) the card must not slide into the tagline's slot —
          // that remounted the text fields, dropped focus and closed the
          // keyboard again.
          // 1 · Logo with a slow gold shimmer sweep.
          RiseIn(
            key: const ValueKey('login_rise_logo'),
            animation: _steps[0],
            child: Center(
              child: CalmBrandLogo(
                assetPath: 'assets/images/greengo_logo.png',
                size: logoSize,
                shimmer: true,
              ),
            ),
          ),

          // 2 · Tagline.
          if (!compact) ...[
            const SizedBox(key: ValueKey('login_gap_tagline'), height: 6),
            RiseIn(
              key: const ValueKey('login_rise_tagline'),
              animation: _steps[1],
              // "Places. People. Experiences." — three words on one line,
              // a touch larger and airier than body text.
              // Always ONE line: scaled down (never wrapped) when a locale
              // does not fit a 320 px phone.
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.loginTagline,
                    key: const ValueKey('login_tagline'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.liquidTagline,
                      fontSize: 17,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      shadows: _onGlowShadow,
                    ),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(
            key: const ValueKey('login_gap_card'),
            height: compact ? 8 : 28,
          ),

          // 3 · Frosted glass form card.
          RiseIn(
            key: const ValueKey('login_rise_card'),
            animation: _steps[2],
            blur: false,
            child: GlassCard(
              // Tighter while the keyboard is up (native compact header) so
              // the Login button stays above it on a landscape iPad.
              padding: compact
                  ? EdgeInsets.symmetric(horizontal: wide ? 24 : 20, vertical: 16)
                  : wide
                      ? const EdgeInsets.fromLTRB(28, 28, 28, 28)
                      : const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: _buildFields(context, l10n, isLoading: isLoading),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFields(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isLoading,
  }) {
    return Column(
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

        const SizedBox(height: 14),

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
              color: AppColors.liquidHint,
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

        const SizedBox(height: 4),

        // Forgot Password — gold link.
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading
                ? null
                : () {
                    Navigator.of(context).pushNamed('/forgot-password');
                  },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.liquidGoldLight,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: Text(
              l10n.forgotPassword,
              style: const TextStyle(
                color: AppColors.liquidGoldLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Login Button — gold gradient, breathing glow, tiny press scale.
        BreathingGoldButton(
          child: AuthButton(
            key: E2EKeys.loginSubmit,
            text: l10n.login,
            onPressed: isLoading ? null : _handleLogin,
            isLoading: isLoading,
            height: 52,
            gradient: _goldButtonGradient,
            borderRadius: 14,
            textColor: AppColors.liquidInk,
          ),
        ),

        // Social Login Section (conditionally rendered)
        if (AppConfig.showSocialLoginSection) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: AppColors.liquidGoldLight.withValues(alpha: 0.16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.orContinueWith,
                  style: const TextStyle(
                    color: AppColors.liquidMuted,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: AppColors.liquidGoldLight.withValues(alpha: 0.16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                              content: Text(l10n.authAppleSignInComingSoon),
                            ),
                          );
                        },
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isLoading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sign Up Link. A Wrap, not a Row — the prompt + button overflow a
        // narrow phone in the longer locales, which clipped the Sign Up tap
        // target.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.dontHaveAccount,
              style: const TextStyle(
                color: AppColors.liquidMuted,
                fontSize: 14,
                shadows: _onGlowShadow,
              ),
            ),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.of(context).pushReplacementNamed('/register');
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.liquidGoldLight,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(
                l10n.signUp,
                style: const TextStyle(
                  color: AppColors.liquidGoldLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  shadows: _onGlowShadow,
                ),
              ),
            ),
          ],
        ),

        // Web on iPhone / iPad (not installed yet): install guide.
        const IosInstallLink(),

        // Web build only: "Visit greengochat.com for more info".
        const WebsiteLink(shadows: _onGlowShadow),

        const SizedBox(height: 8),

        // App Version
        FutureBuilder<PackageInfo>(
          future: _packageInfo,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                'v${snapshot.data!.version}',
                style: const TextStyle(
                  color: AppColors.liquidHint, // 7.3:1 on the base
                  fontSize: 12,
                  letterSpacing: 0.4,
                  shadows: _onGlowShadow,
                ),
                textAlign: TextAlign.center,
              );
            }
            return const SizedBox.shrink();
          },
        ),

        const SizedBox(height: 4),
      ],
    );
  }
}
