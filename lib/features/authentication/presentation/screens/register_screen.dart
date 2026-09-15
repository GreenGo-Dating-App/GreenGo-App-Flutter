import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/auth_error_localizer.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/screens/onboarding_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/consent_checkboxes.dart';
import '../widgets/password_strength_indicator.dart';
import '../../../../core/constants/e2e_keys.dart';
import '../widgets/pre_registration_offer.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  // Watched so the offer lookup runs when the user LEAVES the email field -
  // i.e. when they have finished entering it - rather than on every keystroke.
  final _emailFocus = FocusNode();
  /// Emails already looked up, so correcting a typo and tabbing back out does
  /// not re-ask the server or re-show the dialog.
  final Set<String> _offersChecked = <String>{};
  bool _checkingOffer = false;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;


  // Consent checkboxes state.
  // Required consents (privacy + terms) must be actively accepted → start false.
  bool _privacyPolicyAccepted = false;
  bool _termsAccepted = false;
  // Optional consents are pre-checked by default (user can opt out).
  bool _profilingAccepted = true;
  bool _thirdPartyDataAccepted = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _emailFocus.addListener(_onEmailFocusChange);
  }

  /// When focus leaves a VALID email, ask the server what that address is
  /// entitled to and say so before the user commits to registering.
  void _onEmailFocusChange() {
    if (_emailFocus.hasFocus) return;
    unawaited(_maybeShowOffer());
  }

  Future<void> _maybeShowOffer() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || _checkingOffer) return;
    // Only ask about something that looks like an address, so a half-typed one
    // does not produce a lookup per character.
    if (Validators.validateEmail(email) != null) return;
    if (!_offersChecked.add(email)) return;

    _checkingOffer = true;
    try {
      final offer = await const PreRegistrationOfferService().lookup(email);
      if (offer == null || !mounted) return;
      await showPreRegistrationOfferDialog(context, offer);
    } finally {
      _checkingOffer = false;
    }
  }

  @override
  void dispose() {
    _emailFocus.removeListener(_onEmailFocusChange);
    _emailFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_passwordController.text);
    });
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // A user can fill the form and submit without the email field ever losing
    // focus (autofill, or Enter straight from the keyboard). Make sure they
    // still see what they are entitled to before the account is created.
    await _maybeShowOffer();
    if (!mounted) return;

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
                      fieldKey: E2EKeys.registerEmail,
                      controller: _emailController,
                      focusNode: _emailFocus,
                      label: l10n.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                      prefixIcon: Icons.email_outlined,
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    AuthTextField(
                      fieldKey: E2EKeys.registerPassword,
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
                      fieldKey: E2EKeys.registerConfirmPassword,
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

                    // Register Button
                    AuthButton(
                      key: E2EKeys.registerSubmit,
                      text: l10n.register,
                      onPressed: isLoading ? null : _handleRegister,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Sign In Link. A Wrap, not a Row — the prompt plus the
                    // button needs ~465pt, which overflows every iPhone
                    // (193px on an SE), clipping the Sign In tap target.
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
