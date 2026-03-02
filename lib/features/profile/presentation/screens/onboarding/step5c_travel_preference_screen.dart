import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step5cTravelPreferenceScreen extends StatefulWidget {
  const Step5cTravelPreferenceScreen({super.key});

  @override
  State<Step5cTravelPreferenceScreen> createState() =>
      _Step5cTravelPreferenceScreenState();
}

class _Step5cTravelPreferenceScreenState
    extends State<Step5cTravelPreferenceScreen> {
  String? _selectedPreference;

  static const List<_TravelOption> _options = [
    _TravelOption(
      value: 'learn_travel',
      icon: Icons.flight_takeoff,
      title: 'Learn & Travel',
      description:
          'Learn languages and meet people when I travel to new places',
    ),
    _TravelOption(
      value: 'help_travelers',
      icon: Icons.location_city,
      title: 'Local Guide',
      description:
          'Help travelers discover my city and share my culture with them',
    ),
    _TravelOption(
      value: 'both',
      icon: Icons.public,
      title: 'Both',
      description:
          'I want to learn languages, travel the world, and help visitors in my city',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<OnboardingBloc>().state;
    if (state is OnboardingInProgress) {
      _selectedPreference = state.travelPreference;
    }
  }

  void _selectPreference(String value) {
    setState(() {
      _selectedPreference = value;
    });
    context.read<OnboardingBloc>().add(
          OnboardingTravelPreferenceUpdated(travelPreference: value),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) return const SizedBox();

        return LuxuryOnboardingLayout(
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          title: 'How do you want to use GreenGo?',
          subtitle:
              'Tell us about your interests so we can personalize your experience.',
          onBack: () {
            context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
          },
          child: Column(
            children: [
              const SizedBox(height: 16),
              ..._options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildOptionCard(option),
                  )),
              const SizedBox(height: 24),
              // Info text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.richGold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.richGold, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can change this anytime in your profile settings.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Next / Skip button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedPreference != null) {
                      context.read<OnboardingBloc>().add(
                        OnboardingTravelPreferenceUpdated(
                          travelPreference: _selectedPreference!,
                        ),
                      );
                    }
                    context.read<OnboardingBloc>().add(const OnboardingNextStep());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPreference == null ? 'Skip' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(_TravelOption option) {
    final isSelected = _selectedPreference == option.value;

    return GestureDetector(
      onTap: () => _selectPreference(option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.richGold.withValues(alpha: 0.15)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.richGold : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.richGold.withValues(alpha: 0.2)
                    : AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? AppColors.richGold : AppColors.textSecondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.richGold
                          : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.richGold, size: 24),
          ],
        ),
      ),
    );
  }
}

class _TravelOption {
  final String value;
  final IconData icon;
  final String title;
  final String description;

  const _TravelOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.description,
  });
}
