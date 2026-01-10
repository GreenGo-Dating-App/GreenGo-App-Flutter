import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step3VerificationScreen extends StatefulWidget {
  const Step3VerificationScreen({super.key});

  @override
  State<Step3VerificationScreen> createState() => _Step3VerificationScreenState();
}

class _Step3VerificationScreenState extends State<Step3VerificationScreen> {
  final ImagePicker _picker = ImagePicker();

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
          content: Text('Failed to take photo: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _handleContinue(String? verificationPhotoUrl) {
    final l10n = AppLocalizations.of(context)!;
    if (verificationPhotoUrl == null || verificationPhotoUrl.isEmpty) {
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
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        final isUploading = context.read<OnboardingBloc>().state is OnboardingPhotoUploading;

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: _handleBack,
            ),
            title: OnboardingProgressBar(
              currentStep: state.stepIndex,
              totalSteps: state.totalSteps,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    l10n.verificationTitle,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.verificationDescription,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions
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
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.richGold,
                              size: 20,
                            ),
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
                  const SizedBox(height: 32),

                  // Verification Photo Preview
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
                  const SizedBox(height: 32),

                  // Instructions text
                  Text(
                    l10n.verificationInstructions,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Continue Button
                  OnboardingButton(
                    text: l10n.next,
                    onPressed: () => _handleContinue(state.verificationPhotoUrl),
                    isLoading: isUploading,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.successGreen,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
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

  const _TakePhotoCard({
    this.onTap,
    required this.buttonText,
    this.isLoading = false,
  });

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
          border: Border.all(
            color: AppColors.richGold,
            width: 2,
            style: BorderStyle.solid,
          ),
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
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.richGold,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                buttonText,
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Hold your ID next to your face',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
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

  const _VerificationPhotoCard({
    required this.photoUrl,
    required this.onRetake,
    required this.retakeText,
  });

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
            image: DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: onRetake,
          icon: const Icon(Icons.refresh, color: AppColors.richGold),
          label: Text(
            retakeText,
            style: const TextStyle(color: AppColors.richGold),
          ),
        ),
      ],
    );
  }
}
