import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/auth_error_localizer.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/data/datasources/pending_signup_coupon.dart';
import '../../../referral/data/pending_signup_referral.dart';
import '../../../profile/presentation/screens/onboarding_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/consent_checkboxes.dart';
import '../widgets/password_strength_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _couponController = TextEditingController();
  final _referralController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

  // Coupon "Apply" state
  bool _couponChecking = false;
  bool? _couponValid;
  String? _couponMessage;

  // Consent checkboxes state
  bool _privacyPolicyAccepted = false;
  bool _termsAccepted = false;
  bool _profilingAccepted = false;
  bool _thirdPartyDataAccepted = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _couponController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_passwordController.text);
    });
  }

  /// Validate the typed coupon before registering (the account doesn't exist
  /// yet, so this only checks the code is real/active; it's redeemed after
  /// signup). Shows a green/red message.
  Future<void> _applyCoupon() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponValid = false;
        _couponMessage = l10n.couponNotValid;
      });
      return;
    }
    setState(() {
      _couponChecking = true;
      _couponValid = null;
      _couponMessage = null;
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('validateCoupon');
      final res = await callable.call<Map<String, dynamic>>({'code': code});
      final valid = res.data['valid'] == true;
      if (valid) {
        await PendingSignupCoupon.setPending(code);
      } else {
        await PendingSignupCoupon.clear();
      }
      if (!mounted) return;
      setState(() {
        _couponValid = valid;
        _couponMessage = valid ? l10n.couponAppliedSuccess : l10n.couponNotValid;
      });
    } catch (_) {
      await PendingSignupCoupon.clear();
      if (!mounted) return;
      setState(() {
        _couponValid = false;
        _couponMessage = l10n.couponNotValid;
      });
    } finally {
      if (mounted) setState(() => _couponChecking = false);
    }
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required consents
    if (!ConsentCheckboxes.areRequiredConsentsAccepted(
      privacyPolicy: _privacyPolicyAccepted,
      terms: _termsAccepted,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.consentRequiredError,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    // Persist the optional coupon code so it can be redeemed automatically
    // once the account exists and onboarding completes. Never blocks signup.
    final couponCode = _couponController.text.trim();
    if (couponCode.isNotEmpty && _couponValid != false) {
      await PendingSignupCoupon.setPending(couponCode);
    }
    // Persist the optional referral code — redeemed after onboarding by the
    // secure `redeemReferral` Cloud Function. Never blocks signup.
    final referralCode = _referralController.text.trim();
    if (referralCode.isNotEmpty) {
      await PendingSignupReferral.setPending(referralCode);
    }

    if (!mounted) return;
    context.read<AuthBloc>().add(
          AuthRegisterWithEmailRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              final localizedMessage = AuthErrorLocalizer.getLocalizedError(
                context,
                state.message,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    localizedMessage,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: AppColors.errorRed,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Show email verification message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.accountCreatedSuccess,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: AppColors.successGreen,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              // Redirect to onboarding for profile creation
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => OnboardingScreen(userId: state.user.id),
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: AppDimensions.paddingL,
                right: AppDimensions.paddingL,
                top: AppDimensions.paddingL,
                bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.paddingL + 40,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      l10n.createAccount,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppColors.richGold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.joinMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),

                    const SizedBox(height: 40),

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
                      validator: Validators.validatePassword,
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

                    // Password Strength Indicator
                    PasswordStrengthIndicator(strength: _passwordStrength),

                    const SizedBox(height: 16),

                    // Confirm Password Field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: l10n.confirmPassword,
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Consent Checkboxes
                    ConsentCheckboxes(
                      privacyPolicyAccepted: _privacyPolicyAccepted,
                      termsAccepted: _termsAccepted,
                      profilingAccepted: _profilingAccepted,
                      thirdPartyDataAccepted: _thirdPartyDataAccepted,
                      onPrivacyPolicyChanged: (value) {
                        setState(() {
                          _privacyPolicyAccepted = value;
                        });
                      },
                      onTermsChanged: (value) {
                        setState(() {
                          _termsAccepted = value;
                        });
                      },
                      onProfilingChanged: (value) {
                        setState(() {
                          _profilingAccepted = value;
                        });
                      },
                      onThirdPartyDataChanged: (value) {
                        setState(() {
                          _thirdPartyDataAccepted = value;
                        });
                      },
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Referral code (optional) — the code of the friend who
                    // invited you. Rewards are granted after onboarding.
                    Text(
                      l10n.referralCodeTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _referralController,
                      label: l10n.referralCodeLabel,
                      hint: l10n.referralCodeHint,
                      textCapitalization: TextCapitalization.characters,
                      prefixIcon: Icons.card_giftcard,
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Redeem Coupon (optional) — applied automatically after
                    // registration completes.
                    Text(
                      l10n.couponRedeemTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: AuthTextField(
                            controller: _couponController,
                            label: l10n.registerCouponLabel,
                            hint: l10n.registerCouponHint,
                            textCapitalization: TextCapitalization.characters,
                            prefixIcon: Icons.confirmation_number_outlined,
                            enabled: !isLoading,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_couponController.text.trim().isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed: (isLoading || _couponChecking)
                                    ? null
                                    : _applyCoupon,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: AppColors.richGold),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _couponChecking
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              AppColors.richGold),
                                        ),
                                      )
                                    : Text(
                                        l10n.couponApplyButton,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.richGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_couponMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _couponValid == true
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: _couponValid == true
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _couponMessage!,
                              style: TextStyle(
                                color: _couponValid == true
                                    ? AppColors.successGreen
                                    : AppColors.errorRed,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_couponValid == false) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.freeBaseWeekInfo,
                          style: const TextStyle(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],

                    const SizedBox(height: 24),

                    // Register Button
                    AuthButton(
                      text: l10n.register,
                      onPressed: isLoading ? null : _handleRegister,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Sign In Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.alreadyHaveAccount,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  Navigator.of(context)
                                      .pushReplacementNamed('/login');
                                },
                          child: Text(
                            l10n.signIn,
                            style: const TextStyle(
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
            );
          },
        ),
      ),
    );
  }
}
