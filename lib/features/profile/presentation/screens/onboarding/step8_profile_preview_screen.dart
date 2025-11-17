import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/onboarding_button.dart';
import '../../widgets/onboarding_progress_bar.dart';

class Step8ProfilePreviewScreen extends StatelessWidget {
  const Step8ProfilePreviewScreen({super.key});

  void _handleComplete(BuildContext context) {
    context.read<OnboardingBloc>().add(const OnboardingCompleted());
  }

  void _handleBack(BuildContext context) {
    context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        if (state is! OnboardingInProgress) {
          return const SizedBox.shrink();
        }

        final age = _calculateAge(state.dateOfBirth!);

        return Scaffold(
          backgroundColor: AppColors.backgroundDark,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => _handleBack(context),
            ),
            title: OnboardingProgressBar(
              currentStep: state.stepIndex,
              totalSteps: state.totalSteps,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'Profile preview',
                          style:
                              Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: AppColors.richGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Review your profile before completing',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                        const SizedBox(height: 32),

                        // Profile Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusL),
                            border: Border.all(
                              color: AppColors.divider,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Photos Section
                              if (state.photoUrls.isNotEmpty)
                                SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: state.photoUrls.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 12),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusM),
                                          child: Image.network(
                                            state.photoUrls[index],
                                            width: 150,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: 150,
                                                height: 200,
                                                color: AppColors.backgroundInput,
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: AppColors.textTertiary,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                              const Divider(color: AppColors.divider),

                              // Basic Info
                              _buildInfoSection(
                                context,
                                'Basic Info',
                                [
                                  _InfoItem(
                                      'Name', state.displayName ?? 'Not set'),
                                  _InfoItem('Age', '$age years old'),
                                  _InfoItem('Gender', state.gender ?? 'Not set'),
                                ],
                              ),

                              const Divider(color: AppColors.divider),

                              // Bio
                              _buildInfoSection(
                                context,
                                'About Me',
                                [
                                  _InfoItem('Bio',
                                      state.bio ?? 'No bio provided',
                                      isMultiline: true),
                                ],
                              ),

                              const Divider(color: AppColors.divider),

                              // Interests
                              _buildChipSection(
                                context,
                                'Interests',
                                state.interests,
                              ),

                              const Divider(color: AppColors.divider),

                              // Location & Languages
                              _buildInfoSection(
                                context,
                                'Location & Languages',
                                [
                                  _InfoItem(
                                    'Location',
                                    state.location?.displayAddress ??
                                        'Not set',
                                  ),
                                  _InfoItem(
                                    'Languages',
                                    state.languages.join(', ').isEmpty
                                        ? 'Not set'
                                        : state.languages.join(', '),
                                  ),
                                ],
                              ),

                              const Divider(color: AppColors.divider),

                              // Voice Recording
                              _buildInfoSection(
                                context,
                                'Voice Introduction',
                                [
                                  _InfoItem(
                                    'Status',
                                    state.voiceUrl != null
                                        ? 'Recorded'
                                        : 'Not recorded',
                                  ),
                                ],
                              ),

                              const Divider(color: AppColors.divider),

                              // Personality
                              if (state.personalityTraits != null)
                                _buildPersonalitySection(
                                    context, state.personalityTraits!),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Completion Indicator
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusM),
                            border: Border.all(color: AppColors.successGreen),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.successGreen,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Profile Complete!',
                                      style: TextStyle(
                                        color: AppColors.successGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Your profile is ready to be published',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Section
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingL),
                  child: OnboardingButton(
                    text: 'Complete Profile',
                    onPressed: () => _handleComplete(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    List<_InfoItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: item.isMultiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        '${item.label}:',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildChipSection(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundInput,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusS),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection(BuildContext context, dynamic traits) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personality Traits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildTraitBar('Openness', traits.openness),
          _buildTraitBar('Conscientiousness', traits.conscientiousness),
          _buildTraitBar('Extraversion', traits.extraversion),
          _buildTraitBar('Agreeableness', traits.agreeableness),
          _buildTraitBar('Neuroticism', traits.neuroticism),
        ],
      ),
    );
  }

  Widget _buildTraitBar(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '$value/5',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value / 5,
            backgroundColor: AppColors.backgroundInput,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool isMultiline;

  _InfoItem(this.label, this.value, {this.isMultiline = false});
}
