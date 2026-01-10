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
import '../widgets/password_strength_indicator.dart';
import '../widgets/consent_checkboxes.dart';
import '../../../profile/presentation/screens/onboarding_screen.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

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
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(_passwordController.text);
    });
  }

  void _handleRegister() {
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
          content: Text(l10n.consentRequiredError),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            } else if (state is AuthAuthenticated) {
              // Show email verification message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account created! Please check your email to verify your account.'),
                  backgroundColor: AppColors.successGreen,
                  duration: Duration(seconds: 5),
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
