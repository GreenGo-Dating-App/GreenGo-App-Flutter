import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
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
            const SnackBar(
              content: Text('You can select up to 10 interests'),
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
        const SnackBar(
          content: Text('Please select at least 3 interests'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'Your interests',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.richGold,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select at least 3 interests (max 10)',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selectedInterests.length}/10 selected',
                          style: TextStyle(
                            color: _selectedInterests.length >= 3
                                ? AppColors.successGreen
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Interests Grid
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingL,
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return GestureDetector(
                          onTap: () => _toggleInterest(interest),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.richGold
                                  : AppColors.backgroundCard,
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusM),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.richGold
                                    : AppColors.divider,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppColors.deepBlack,
                                      size: 18,
                                    ),
                                  ),
                                Text(
                                  interest,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppColors.deepBlack
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Bottom Section
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: Column(
                    children: [
                      // Info Box
                      Container(
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
                                'Your interests help us find better matches for you',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Continue Button
                      OnboardingButton(
                        text: 'Continue',
                        onPressed: _handleContinue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
