import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step3BioScreen extends StatefulWidget {
  const Step3BioScreen({super.key});

  @override
  State<Step3BioScreen> createState() => _Step3BioScreenState();
}

class _Step3BioScreenState extends State<Step3BioScreen> {
  final _bioController = TextEditingController();
  final int _maxLength = 500;

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress && state.bio != null) {
      _bioController.text = state.bio!;
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final bio = _bioController.text.trim();
    if (bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something about yourself'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (bio.length < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio must be at least 50 characters'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    context.read<OnboardingBloc>().add(OnboardingBioUpdated(bio: bio));
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    // Save current bio before going back
    final bio = _bioController.text.trim();
    if (bio.isNotEmpty) {
      context.read<OnboardingBloc>().add(OnboardingBioUpdated(bio: bio));
    }
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
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
              onPressed: _handleBack,
            ),
            title: OnboardingProgressBar(
              currentStep: state.stepIndex,
              totalSteps: state.totalSteps,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'About you',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Write a short bio to tell others about yourself',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Bio Text Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundInput,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                        border: Border.all(
                          color: AppColors.divider,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _bioController,
                        maxLength: _maxLength,
                        maxLines: null,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tell us about your interests, hobbies, what you\'re looking for...',
                          hintStyle: TextStyle(
                            color: AppColors.textTertiary,
                          ),
                          counterStyle: TextStyle(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {}); // Rebuild to update character count color
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tips Container
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
                              Icons.lightbulb_outline,
                              color: AppColors.richGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tips for a great bio:',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppColors.richGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildTip('Be authentic and honest'),
                        _buildTip('Mention your hobbies and interests'),
                        _buildTip('Share what makes you unique'),
                        _buildTip('Keep it positive and friendly'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue Button
                  OnboardingButton(
                    text: 'Continue',
                    onPressed: _handleContinue,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
