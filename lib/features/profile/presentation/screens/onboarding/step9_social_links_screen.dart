import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../domain/entities/social_links.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step9SocialLinksScreen extends StatefulWidget {
  const Step9SocialLinksScreen({super.key});

  @override
  State<Step9SocialLinksScreen> createState() => _Step9SocialLinksScreenState();
}

class _Step9SocialLinksScreenState extends State<Step9SocialLinksScreen> {
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _xController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load existing data if available
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress && state.socialLinks != null) {
      _facebookController.text = state.socialLinks!.facebook ?? '';
      _instagramController.text = state.socialLinks!.instagram ?? '';
      _tiktokController.text = state.socialLinks!.tiktok ?? '';
      _linkedinController.text = state.socialLinks!.linkedin ?? '';
      _xController.text = state.socialLinks!.x ?? '';
    }
  }

  @override
  void dispose() {
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _linkedinController.dispose();
    _xController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    final socialLinks = SocialLinks(
      facebook: _facebookController.text.trim().isEmpty
          ? null
          : _facebookController.text.trim(),
      instagram: _instagramController.text.trim().isEmpty
          ? null
          : _instagramController.text.trim(),
      tiktok: _tiktokController.text.trim().isEmpty
          ? null
          : _tiktokController.text.trim(),
      linkedin: _linkedinController.text.trim().isEmpty
          ? null
          : _linkedinController.text.trim(),
      x: _xController.text.trim().isEmpty ? null : _xController.text.trim(),
    );

    context.read<OnboardingBloc>().add(
          OnboardingSocialLinksUpdated(socialLinks: socialLinks),
        );
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _skip() {
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context
                  .read<OnboardingBloc>()
                  .add(const OnboardingPreviousStep()),
            ),
            title: OnboardingProgressBar(
              currentStep: state.stepIndex,
              totalSteps: state.totalSteps,
            ),
            actions: [
              TextButton(
                onPressed: _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Social profiles',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect your social accounts to help others know you better (optional)',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Social Links Inputs
                  _buildSocialInput(
                    controller: _facebookController,
                    label: 'Facebook',
                    hint: 'Username or profile URL',
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F2),
                  ),
                  _buildSocialInput(
                    controller: _instagramController,
                    label: 'Instagram',
                    hint: 'Username (without @)',
                    icon: Icons.camera_alt,
                    color: const Color(0xFFE4405F),
                  ),
                  _buildSocialInput(
                    controller: _tiktokController,
                    label: 'TikTok',
                    hint: 'Username (without @)',
                    icon: Icons.music_note,
                    color: AppColors.textPrimary,
                  ),
                  _buildSocialInput(
                    controller: _linkedinController,
                    label: 'LinkedIn',
                    hint: 'Username or profile URL',
                    icon: Icons.work,
                    color: const Color(0xFF0A66C2),
                  ),
                  _buildSocialInput(
                    controller: _xController,
                    label: 'X (Twitter)',
                    hint: 'Username (without @)',
                    icon: Icons.alternate_email,
                    color: AppColors.textPrimary,
                  ),

                  const SizedBox(height: 24),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.richGold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your social profiles will be visible on your dating profile',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  OnboardingButton(
                    text: 'Continue',
                    onPressed: _saveAndContinue,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            borderSide: BorderSide(color: color, width: 2),
          ),
          prefixIcon: Icon(icon, color: color),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
