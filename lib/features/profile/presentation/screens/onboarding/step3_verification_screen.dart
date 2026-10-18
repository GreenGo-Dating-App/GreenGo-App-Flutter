import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../generated/app_localizations.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../../../../../core/utils/user_error.dart';
import '../../../../../core/widgets/phone_verification_panel.dart';
import '../../../../safety/data/services/identity_details_service.dart';
import '../../../../safety/presentation/widgets/identity_details_form.dart';

class Step3VerificationScreen extends StatefulWidget {
  const Step3VerificationScreen({super.key});

  @override
  State<Step3VerificationScreen> createState() => _Step3VerificationScreenState();
}

class _Step3VerificationScreenState extends State<Step3VerificationScreen> {
  final ImagePicker _picker = ImagePicker();

  // Owner rule 2026-10-17: the SMS-verified phone is MANDATORY for every new
  // account (PhoneVerificationPanel: supported countries only, linked to the
  // account, ID token refreshed). The ID photo below is OPTIONAL (Verified
  // badge request, deleted after review).
  bool _phoneVerified = false;

  @override
  void initState() {
    super.initState();
    // Phone sign-in accounts (or a retry after linking) already have one.
    String? existing;
    try {
      existing = FirebaseAuth.instance.currentUser?.phoneNumber;
    } catch (_) {}
    if (existing != null && existing.isNotEmpty) {
      _phoneVerified = true;
      final phone = existing;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<OnboardingBloc>().add(
              OnboardingPhoneVerificationCompleted(phoneNumber: phone),
            );
      });
    }
  }

  void _onPhoneVerified(String phone) {
    setState(() => _phoneVerified = true);
    context.read<OnboardingBloc>().add(
          OnboardingPhoneVerificationCompleted(phoneNumber: phone),
        );
  }

  Future<void> _takeVerificationPhoto() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      if (image != null) {
        if (!mounted) return;
        context.read<OnboardingBloc>().add(OnboardingVerificationPhotoAdded(photo: image));
      }
    } catch (e) {
      if (!mounted) return;
      showUserError(context, e);
    }
  }

  void _handleContinue(OnboardingInProgress state) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhone = _phoneVerified ||
        (state.verificationPhone != null && state.verificationPhone!.isNotEmpty);
    if (!hasPhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.phoneVerifyRequiredToContinue),
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
        if (state is OnboardingError &&
            // The incomplete-step code is localized by OnboardingScreen.
            state.message != OnboardingError.incompleteStepCode) {
          showUserError(context, state.message);
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

                // 1. Verified phone - mandatory.
                _SectionTitle(
                  icon: Icons.phone_android,
                  title: l10n.phoneVerifyTitle,
                  subtitle: l10n.phoneVerifyRequiredBody,
                ),
                const SizedBox(height: 12),
                PhoneVerificationPanel(
                  key: const ValueKey('onboarding-phone-panel'),
                  onVerified: _onPhoneVerified,
                ),
                const SizedBox(height: 28),

                // 2. ID document - optional (Verified badge request).
                _SectionTitle(
                  icon: Icons.badge_outlined,
                  title: l10n.phoneVerifyOnboardingOptionalId,
                  subtitle: l10n.phoneVerifyOnboardingOptionalIdBody,
                ),
                const SizedBox(height: 12),
                _buildPhotoVerification(state, isUploading),

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

        // Optional: the details printed on the document (stored encrypted).
        if (state.verificationPhotoUrl != null) ...[
          const Center(
            child: IdentityDetailsButton(source: IdentitySource.registration),
          ),
          const SizedBox(height: 8),
        ],

        Text(
          l10n.verificationInstructions,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

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

  const _PrivacyPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

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

// ======================== Photo Widgets ========================

class _VerificationTip extends StatelessWidget {
  const _VerificationTip({required this.text});
  final String text;

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

  const _TakePhotoCard({required this.buttonText, this.onTap, this.isLoading = false});
  final VoidCallback? onTap;
  final String buttonText;
  final bool isLoading;

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

  const _VerificationPhotoCard({required this.photoUrl, required this.onRetake, required this.retakeText});
  final String photoUrl;
  final VoidCallback onRetake;
  final String retakeText;

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.richGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      );
}
