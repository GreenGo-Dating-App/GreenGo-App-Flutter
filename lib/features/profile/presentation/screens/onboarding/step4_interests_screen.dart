import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../generated/app_localizations.dart';
import 'onboarding_value_labels.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step4InterestsScreen extends StatefulWidget {
  const Step4InterestsScreen({super.key});

  @override
  State<Step4InterestsScreen> createState() => _Step4InterestsScreenState();
}

class _Step4InterestsScreenState extends State<Step4InterestsScreen> {
  final List<String> _availableInterests = [
    'Travel',
    'Photography',
    'Music',
    'Movies',
    'Sports',
    'Fitness',
    'Cooking',
    'Reading',
    'Art',
    'Gaming',
    'Technology',
    'Fashion',
    'Dancing',
    'Yoga',
    'Hiking',
    'Swimming',
    'Running',
    'Cycling',
    'Meditation',
    'Writing',
    'Poetry',
    'Coffee',
    'Wine',
    'Beer',
    'Food',
    'Vegetarian',
    'Vegan',
    'Pets',
    'Dogs',
    'Cats',
    'Nature',
    'Environment',
    'Volunteering',
    'Languages',
    'History',
    'Science',
    'Politics',
    'Business',
    'Entrepreneurship',
    'Investing',
  ];

  List<String> _selectedInterests = [];

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress) {
      _selectedInterests = List.from(state.interests);
    }
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 10) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.onboardingMaxInterests),
              backgroundColor: AppColors.warningAmber,
            ),
          );
        }
      }
    });
  }

  void _handleContinue() {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.onboardingMinInterests),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    context.read<OnboardingBloc>().add(
          OnboardingInterestsUpdated(interests: _selectedInterests),
        );
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
  }

  void _handleBack() {
    context.read<OnboardingBloc>().add(
          OnboardingInterestsUpdated(interests: _selectedInterests),
        );
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  /// Map internal interest key to localized display name
  String _localizedInterest(BuildContext context, String interest) =>
      localizedOnboardingInterest(AppLocalizations.of(context)!, interest);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return LuxuryOnboardingLayout(
          title: l10n.onboardingPickInterests,
          subtitle: l10n.onboardingInterestsSubtitle,
          showBackButton: true,
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          bottomChild: LuxuryButton(
            text: l10n.onboardingContinue,
            onPressed: _handleContinue,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Counter badge
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.interestsSelectedCount(_selectedInterests.length, 10),
                    style: TextStyle(
                      color: _selectedInterests.length >= 3
                          ? AppColors.successGreen
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Interests chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableInterests.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return LuxuryChip(
                      label: _localizedInterest(context, interest),
                      isSelected: isSelected,
                      onTap: () => _toggleInterest(interest),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Info Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
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
                          l10n.onboardingInterestsHelpMatches,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
