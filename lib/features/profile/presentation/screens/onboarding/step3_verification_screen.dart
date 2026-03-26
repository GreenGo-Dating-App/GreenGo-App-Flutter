import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step3VerificationScreen extends StatefulWidget {
  const Step3VerificationScreen({super.key});

  @override
  State<Step3VerificationScreen> createState() => _Step3VerificationScreenState();
}

class _Step3VerificationScreenState extends State<Step3VerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  // 'choose' | 'photo' | 'phone'
  String _selectedMethod = 'choose';

  // Phone verification state
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isVerifyingPhone = false;
  bool _phoneVerified = false;
  String? _verificationId;
  int? _resendToken;
  String? _phoneError;
  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _takeVerificationPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        final file = File(image.path);
        if (!mounted) return;
        context.read<OnboardingBloc>().add(OnboardingVerificationPhotoAdded(photo: file));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.onboardingFailedTakePhoto(e.toString()) ?? 'Failed to take photo: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _sendPhoneCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isVerifyingPhone = true;
      _phoneError = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) {
          // Auto-verification on Android
          if (mounted) {
            setState(() {
              _phoneVerified = true;
              _isVerifyingPhone = false;
            });
            context.read<OnboardingBloc>().add(
              OnboardingPhoneVerificationCompleted(phoneNumber: phone),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Phone verification failed: ${e.code} - ${e.message}');
          if (mounted) {
            String errorMsg;
            switch (e.code) {
              case 'invalid-phone-number':
                errorMsg = 'Invalid phone number format. Please use international format (e.g. +1234567890).';
                break;
              case 'too-many-requests':
                errorMsg = 'Too many attempts. Please wait a few minutes before trying again.';
                break;
              case 'quota-exceeded':
                errorMsg = 'SMS quota exceeded. Please try again later.';
                break;
              case 'captcha-check-failed':
                errorMsg = 'reCAPTCHA verification failed. Please try again.';
                break;
              case 'missing-phone-number':
                errorMsg = 'Please enter a phone number.';
                break;
              default:
                errorMsg = 'Phone verification error (${e.code}): ${e.message ?? 'Please try again.'}';
            }
            setState(() {
              _isVerifyingPhone = false;
              _phoneError = errorMsg;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _codeSent = true;
              _isVerifyingPhone = false;
              _resendCountdown = 60;
            });
            _startResendTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('Phone verification exception: $e');
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
          _phoneError = 'Phone verification error: ${e.toString()}';
        });
      }
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown <= 0) {
        timer.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6 || _verificationId == null) return;

    setState(() {
      _isVerifyingPhone = true;
      _phoneError = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: code,
      );

      // Link phone credential to existing user (they're already signed in with email)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
      }

      if (mounted) {
        setState(() {
          _phoneVerified = true;
          _isVerifyingPhone = false;
        });
        context.read<OnboardingBloc>().add(
          OnboardingPhoneVerificationCompleted(phoneNumber: _phoneController.text.trim()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg;
        if (e.code == 'invalid-verification-code') {
          errorMsg = AppLocalizations.of(context)?.verificationInvalidCode ?? 'Invalid code. Please check and try again.';
        } else if (e.code == 'credential-already-in-use') {
          errorMsg = 'This phone number is already linked to another account.';
        } else {
          errorMsg = AppLocalizations.of(context)?.verificationPhoneError ?? 'Failed to verify phone number. Please try again.';
        }
        setState(() {
          _isVerifyingPhone = false;
          _phoneError = errorMsg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
          _phoneError = AppLocalizations.of(context)?.verificationPhoneError ?? 'Failed to verify phone number. Please try again.';
        });
      }
    }
  }

  void _handleContinue(OnboardingInProgress state) {
    final l10n = AppLocalizations.of(context)!;

    // Check if either photo or phone verification is done
    final hasPhoto = state.verificationPhotoUrl != null && state.verificationPhotoUrl!.isNotEmpty;
    final hasPhone = _phoneVerified || (state.verificationMethod == 'phone' && state.verificationPhone != null);

    if (!hasPhoto && !hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.takeVerificationPhoto),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.errorRed),
          );
        }
      },
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        final isUploading = state.isUploading;

        return LuxuryOnboardingLayout(
          title: l10n.verificationTitle,
          subtitle: l10n.verificationDescription,
          showBackButton: true,
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          bottomChild: LuxuryButton(
            text: l10n.next,
            onPressed: () => _handleContinue(state),
            isLoading: isUploading,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Privacy & Security Section
                _PrivacySection(),
                const SizedBox(height: 20),

                // Method chooser or selected method content
                if (_selectedMethod == 'choose' &&
                    state.verificationPhotoUrl == null &&
                    !_phoneVerified) ...[
                  _MethodChooser(
                    onPhotoSelected: () => setState(() => _selectedMethod = 'photo'),
                    onPhoneSelected: () => setState(() => _selectedMethod = 'phone'),
                  ),
                ] else if (_selectedMethod == 'phone' || _phoneVerified) ...[
                  _buildPhoneVerification(state),
                ] else ...[
                  _buildPhotoVerification(state, isUploading),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoVerification(OnboardingInProgress state, bool isUploading) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.richGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.verificationTips,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _VerificationTip(text: l10n.verificationTip1),
              _VerificationTip(text: l10n.verificationTip2),
              _VerificationTip(text: l10n.verificationTip3),
              _VerificationTip(text: l10n.verificationTip4),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Photo card
        Center(
          child: state.verificationPhotoUrl != null
              ? _VerificationPhotoCard(
                  photoUrl: state.verificationPhotoUrl!,
                  onRetake: _takeVerificationPhoto,
                  retakeText: l10n.retakePhoto,
                )
              : _TakePhotoCard(
                  onTap: isUploading ? null : _takeVerificationPhoto,
                  buttonText: l10n.takeVerificationPhoto,
                  isLoading: isUploading,
                ),
        ),
        const SizedBox(height: 16),

        // Switch to phone option
        if (state.verificationPhotoUrl == null)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedMethod = 'phone'),
              icon: const Icon(Icons.phone_android, color: AppColors.textTertiary, size: 18),
              label: Text(
                '${AppLocalizations.of(context)?.verificationOr ?? 'or'} ${AppLocalizations.of(context)?.verificationMethodPhone ?? 'Phone Number'}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ),
          ),

        Text(
          l10n.verificationInstructions,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneVerification(OnboardingInProgress state) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone verification header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_android, color: AppColors.richGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n?.verificationPhoneTitle ?? 'Phone Verification',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.verificationPhoneSubtitle ?? 'Enter your phone number to receive a verification code via SMS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_phoneVerified) ...[
          // Success state
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified, color: AppColors.successGreen, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.verificationPhoneSuccess ?? 'Phone number verified successfully!',
                    style: const TextStyle(color: AppColors.successGreen, fontSize: 16, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _phoneController.text,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ] else if (!_codeSent) ...[
          // Phone input
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              labelText: l10n?.verificationPhoneLabel ?? 'Phone number',
              labelStyle: const TextStyle(color: AppColors.textTertiary),
              hintText: l10n?.verificationPhoneHint ?? '+1 234 567 8900',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.phone, color: AppColors.richGold),
              filled: true,
              fillColor: AppColors.backgroundCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.richGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifyingPhone ? null : _sendPhoneCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
              ),
              child: _isVerifyingPhone
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(l10n?.verificationSendCode ?? 'Send Code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ] else ...[
          // Code sent - show input
          Text(
            l10n?.verificationCodeSent(_phoneController.text) ?? 'Code sent to ${_phoneController.text}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),

          Text(
            l10n?.verificationEnterCode ?? 'Enter the 6-digit code sent to your phone',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, letterSpacing: 8),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: const TextStyle(color: AppColors.textTertiary, letterSpacing: 8),
              filled: true,
              fillColor: AppColors.backgroundCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                borderSide: const BorderSide(color: AppColors.richGold, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isVerifyingPhone ? null : _verifyCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusM)),
              ),
              child: _isVerifyingPhone
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(l10n?.verificationVerifyCode ?? 'Verify Code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),

          // Resend button
          Center(
            child: TextButton(
              onPressed: _resendCountdown > 0 ? null : _sendPhoneCode,
              child: Text(
                _resendCountdown > 0
                    ? '${l10n?.verificationResendCode ?? 'Resend code'} (${_resendCountdown}s)'
                    : l10n?.verificationResendCode ?? 'Resend code',
                style: TextStyle(
                  color: _resendCountdown > 0 ? AppColors.textTertiary : AppColors.richGold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],

        if (_phoneError != null) ...[
          const SizedBox(height: 8),
          Text(_phoneError!, style: const TextStyle(color: AppColors.errorRed, fontSize: 13)),
        ],

        const SizedBox(height: 16),

        // Responsibility notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.warningAmber.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warningAmber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.verificationPhoneResponsibility ?? 'By verifying with your phone number, you acknowledge that the owner of this number is personally responsible for all actions performed on this account.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),

        // Switch to photo option
        if (!_phoneVerified)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _selectedMethod = 'photo'),
              icon: const Icon(Icons.badge_outlined, color: AppColors.textTertiary, size: 18),
              label: Text(
                '${l10n?.verificationOr ?? 'or'} ${l10n?.verificationMethodPhoto ?? 'ID Document'}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}

// ======================== Privacy Section ========================

class _PrivacySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.08),
            AppColors.richGold.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: AppColors.richGold, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.verificationPrivacyTitle ?? 'Your data is safe with us',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.richGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PrivacyPoint(
            icon: Icons.lock,
            text: l10n?.verificationPrivacyEncryption ?? 'All documents are encrypted with end-to-end encryption. Not even GreenGo engineers can access your data.',
          ),
          _PrivacyPoint(
            icon: Icons.person_pin,
            text: l10n?.verificationPrivacyAccess ?? 'Your information can only be accessed through your personal request via official channels or email.',
          ),
          _PrivacyPoint(
            icon: Icons.security,
            text: l10n?.verificationPrivacySafety ?? 'This step is essential to protect all members. We invite you to report any suspicious behaviour and let GreenGo take action.',
          ),
          _PrivacyPoint(
            icon: Icons.flag,
            text: l10n?.verificationPrivacyReporting ?? 'If something happens, report it immediately. GreenGo will investigate and act to keep the community safe.',
          ),
        ],
      ),
    );
  }
}

class _PrivacyPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivacyPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.richGold.withValues(alpha: 0.7), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================== Method Chooser ========================

class _MethodChooser extends StatelessWidget {
  final VoidCallback onPhotoSelected;
  final VoidCallback onPhoneSelected;

  const _MethodChooser({required this.onPhotoSelected, required this.onPhoneSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.verificationChooseMethod ?? 'Choose your verification method',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _MethodCard(
          icon: Icons.badge_outlined,
          title: l10n?.verificationMethodPhoto ?? 'ID Document',
          subtitle: l10n?.verificationMethodPhotoDesc ?? 'Take a photo holding your ID next to your face',
          onTap: onPhotoSelected,
        ),
        const SizedBox(height: 12),
        _MethodCard(
          icon: Icons.phone_android,
          title: l10n?.verificationMethodPhone ?? 'Phone Number',
          subtitle: l10n?.verificationMethodPhoneDesc ?? 'Verify via SMS code sent to your phone',
          onTap: onPhoneSelected,
        ),
      ],
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MethodCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.richGold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 24),
          ],
        ),
      ),
    );
  }
}

// ======================== Photo Widgets ========================

class _VerificationTip extends StatelessWidget {
  final String text;
  const _VerificationTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _TakePhotoCard extends StatelessWidget {
  final VoidCallback? onTap;
  final String buttonText;
  final bool isLoading;

  const _TakePhotoCard({this.onTap, required this.buttonText, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 350,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.richGold, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator(color: AppColors.richGold)
            else ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.richGold, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                buttonText,
                style: const TextStyle(color: AppColors.richGold, fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppLocalizations.of(context)?.onboardingHoldIdNextToFace ?? 'Hold your ID next to your face',
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerificationPhotoCard extends StatelessWidget {
  final String photoUrl;
  final VoidCallback onRetake;
  final String retakeText;

  const _VerificationPhotoCard({required this.photoUrl, required this.onRetake, required this.retakeText});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 280,
          height: 350,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.successGreen, width: 3),
            image: DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh, color: AppColors.richGold),
          label: Text(retakeText, style: const TextStyle(color: AppColors.richGold)),
        ),
      ],
    );
  }
}
