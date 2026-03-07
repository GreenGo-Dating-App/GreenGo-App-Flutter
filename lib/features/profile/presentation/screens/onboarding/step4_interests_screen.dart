import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
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
  String _localizedInterest(BuildContext context, String interest) {
    final l10n = AppLocalizations.of(context)!;
    switch (interest) {
      case 'Travel': return l10n.interestTravel;
      case 'Photography': return l10n.interestPhotography;
      case 'Music': return l10n.interestMusic;
      case 'Movies': return l10n.interestMovies;
      case 'Sports': return l10n.interestSports;
      case 'Fitness': return l10n.interestFitness;
      case 'Cooking': return l10n.interestCooking;
      case 'Reading': return l10n.interestReading;
      case 'Art': return l10n.interestArt;
      case 'Gaming': return l10n.interestGaming;
      case 'Technology': return l10n.interestTechnology;
      case 'Fashion': return l10n.interestFashion;
      case 'Dancing': return l10n.interestDancing;
      case 'Yoga': return l10n.interestYoga;
      case 'Hiking': return l10n.interestHiking;
      case 'Swimming': return l10n.interestSwimming;
      case 'Running': return l10n.interestRunning;
      case 'Cycling': return l10n.interestCycling;
      case 'Meditation': return l10n.interestMeditation;
      case 'Writing': return l10n.interestWriting;
      case 'Poetry': return l10n.interestPoetry;
      case 'Coffee': return l10n.interestCoffee;
      case 'Wine': return l10n.interestWine;
      case 'Beer': return l10n.interestBeer;
      case 'Food': return l10n.interestFood;
      case 'Vegetarian': return l10n.interestVegetarian;
      case 'Vegan': return l10n.interestVegan;
      case 'Pets': return l10n.interestPets;
      case 'Dogs': return l10n.interestDogs;
      case 'Cats': return l10n.interestCats;
      case 'Nature': return l10n.interestNature;
      case 'Environment': return l10n.interestEnvironment;
      case 'Volunteering': return l10n.interestVolunteering;
      case 'Languages': return l10n.interestLanguages;
      case 'History': return l10n.interestHistory;
      case 'Science': return l10n.interestScience;
      case 'Politics': return l10n.interestPolitics;
      case 'Business': return l10n.interestBusiness;
      case 'Entrepreneurship': return l10n.interestEntrepreneurship;
      case 'Investing': return l10n.interestInvesting;
      default: return interest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        return LuxuryOnboardingLayout(
          title: l10n.onboardingYourInterests,
          subtitle: l10n.onboardingInterestsSubtitle,
          showBackButton: true,
          onBack: _handleBack,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          child: Column(
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

              // Interests chips - scrollable area
              Expanded(
                child: SingleChildScrollView(
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
                              l10n.onboardingInterestsHelpMatches,
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
                    LuxuryButton(
                      text: l10n.onboardingContinue,
                      onPressed: _handleContinue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
