import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/consent_recorder.dart';
import '../../../../core/utils/auth_error_localizer.dart';
import '../../../../core/utils/user_error.dart';
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

/// Version label of the Terms / Privacy Policy accepted at signup, stored with
/// the consent record: the "Last Updated" date of assets/legal/*.txt. Update
/// it together with the bundled legal documents.
const String kSignupLegalDocVersion = '2026-09-15';

/// Longest the Register tap waits for the pre-registration offer lookup
/// (a callable that can cold-start for several seconds). Past it, signup
/// carries on without the dialog: the offer itself is granted server-side by
/// `applySignupGrants`, the dialog is only an announcement.
const Duration kOfferLookupBudget = Duration(seconds: 3);

/// After this long the "creating your account" overlay adds a second line.
const Duration kCreatingAccountSlowAfter = Duration(seconds: 5);

typedef OfferLookup = Future<PreRegistrationOffer?> Function(String email);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.offerLookup});

  /// Test seam; defaults to [PreRegistrationOfferService.lookup].
  final OfferLookup? offerLookup;

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

  /// One lookup per email, started when the email field loses focus (prefetch,
  /// never shown there) and reused by Register, so the tap rarely waits.
  final Map<String, Future<PreRegistrationOffer?>> _offerLookups = {};

  /// True from the Register tap until the bloc answers with an error (success
  /// navigates away). Drives the blocking "creating your account" overlay,
  /// which therefore appears on the very first frame after the tap - before
  /// the offer lookup and the Firebase Auth round-trips.
  bool _submitting = false;
  bool _submittingSlow = false;
  Timer? _slowTimer;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

  // Consent checkboxes state.
  // Required consents (privacy + terms) must be actively accepted → start false.
  bool _privacyPolicyAccepted = false;
  bool _termsAccepted = false;
  // Optional consents start UNticked (P2-5(d)): consent must be an
  // affirmative act. The choices are recorded server-side after signup.
  bool _profilingAccepted = ConsentCheckboxes.defaultProfilingAccepted;
  bool _thirdPartyDataAccepted =
      ConsentCheckboxes.defaultThirdPartyDataAccepted;
  bool _marketingEmailAccepted =
      ConsentCheckboxes.defaultMarketingEmailAccepted;

  /// Set when Register is pressed, so the consent record is written once the
  /// account exists (and only for an account created on this screen).
  bool _registrationSubmitted = false;
  bool _consentsRecorded = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _emailFocus.addListener(_prefetchOffer);
  }

  String get _normalizedEmail => _emailController.text.trim().toLowerCase();

  Future<PreRegistrationOffer?> _offerFor(String email) =>
      _offerLookups.putIfAbsent(
        email,
        () =>
            (widget.offerLookup ?? const PreRegistrationOfferService().lookup)(
              email,
            ),
      );

  /// Starts the lookup when the email field loses focus. Nothing is shown
  /// here (that used to land the dialog on the next screen); Register awaits
  /// the already-running future instead of starting a cold call on tap.
  void _prefetchOffer() {
    if (_emailFocus.hasFocus) return;
    final email = _normalizedEmail;
    if (email.isEmpty || Validators.validateEmail(email) != null) return;
    unawaited(_offerFor(email));
  }

  void _setSubmitting(bool value) {
    _slowTimer?.cancel();
    _slowTimer = null;
    if (value) {
      _slowTimer = Timer(kCreatingAccountSlowAfter, () {
        if (mounted && _submitting) setState(() => _submittingSlow = true);
      });
    }
    if (!mounted) return;
    setState(() {
      _submitting = value;
      _submittingSlow = false;
    });
  }

  Future<void> _maybeShowOffer() async {
    final email = _normalizedEmail;
    if (email.isEmpty || _checkingOffer) return;
    // Only ask about something that looks like an address, so a half-typed one
    // does not produce a lookup per character.
    if (Validators.validateEmail(email) != null) return;
    if (!_offersChecked.add(email)) return;

    _checkingOffer = true;
    try {
      final offer = await _offerFor(
        email,
      ).timeout(kOfferLookupBudget, onTimeout: () => null);
      if (offer == null || !mounted) return;
      // Only announce it while Create Account is still the screen on top.
      //
      // Tapping Register BLURS the email field, which starts this lookup, and
      // registration then navigates away while it is still in flight - so the
      // dialog used to appear over the first step of the onboarding wizard,
      // which is not where a message about signing up belongs. _handleRegister
      // now awaits this before registering, and this guard catches every other
      // way the screen can change underneath an in-flight lookup.
      if (ModalRoute.of(context)?.isCurrent != true) return;
      await showPreRegistrationOfferDialog(context, offer);
    } finally {
      _checkingOffer = false;
    }
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    _emailFocus.removeListener(_prefetchOffer);
    _emailFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      _passwordStrength = Validators.getPasswordStrength(
        _passwordController.text,
      );
    });
  }

  Future<void> _handleRegister() async {
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;

    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Required consents first (synchronous), so a missing tick is reported
    // at once instead of after a network round-trip.
    if (!ConsentCheckboxes.areRequiredConsentsAccepted(
      privacyPolicy: _privacyPolicyAccepted,
      terms: _termsAccepted,
    )) {
      showUserErrorMessage(context, l10n.consentRequiredError);
      return;
    }

    // Blocking progress state from the first frame after the tap.
    _setSubmitting(true);

    // Announce the offer HERE - after Register is pressed, and before the
    // account is created. It was previously SHOWN when the email field lost
    // focus, which could land the dialog on the next screen; now blur only
    // prefetches, and the wait here is capped by kOfferLookupBudget.
    await _maybeShowOffer();
    if (!mounted) return;

    _registrationSubmitted = true;
    context.read<AuthBloc>().add(
      AuthRegisterWithEmailRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  /// Records terms / privacy acceptance and the optional choices (P2-5(d)).
  /// Fire-and-forget: a failure is logged and never blocks signup.
  void _recordSignupConsents() {
    if (!_registrationSubmitted || _consentsRecorded) return;
    _consentsRecorded = true;
    unawaited(
      ConsentRecorder.instance.recordSignupConsents(
        profiling: _profilingAccepted,
        thirdPartyData: _thirdPartyDataAccepted,
        marketingEmail: _marketingEmailAccepted,
        docVersion: kSignupLegalDocVersion,
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
              _setSubmitting(false);
              final localizedMessage = AuthErrorLocalizer.getLocalizedError(
                context,
                state.message,
              );
              showUserErrorMessage(context, localizedMessage);
            } else if (state is AuthAuthenticated) {
              _recordSignupConsents();
              // Show email verification message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.accountCreatedSuccess,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: AppColors.successGreen,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
            final isLoading = state is AuthLoading || _submitting;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppDimensions.paddingL,
                    right: AppDimensions.paddingL,
                    top: AppDimensions.paddingL,
                    bottom:
                        MediaQuery.of(context).viewInsets.bottom +
                        AppDimensions.paddingL +
                        40,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          l10n.createAccount,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(color: AppColors.richGold),
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
                          validator: (value) =>
                              Validators.validateConfirmPassword(
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
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
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
                          marketingEmailAccepted: _marketingEmailAccepted,
                          onMarketingEmailChanged: (value) {
                            setState(() {
                              _marketingEmailAccepted = value;
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
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed('/login');
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
                ),
                if (_submitting)
                  Positioned.fill(
                    child: CreatingAccountOverlay(slow: _submittingSlow),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Blocking "We are creating your account..." state shown while Register is
/// in flight. The barrier absorbs taps so nothing else can be pressed.
class CreatingAccountOverlay extends StatelessWidget {
  const CreatingAccountOverlay({super.key, required this.slow});

  /// Adds the "this can take a few seconds" line.
  final bool slow;

  static const overlayKey = Key('registerCreatingAccountOverlay');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      key: overlayKey,
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: Semantics(
            liveRegion: true,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.richGold.withOpacity(0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.richGold),
                  const SizedBox(height: 20),
                  Text(
                    l10n.signupCreatingAccount,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (slow) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.signupCreatingAccountSlow,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
