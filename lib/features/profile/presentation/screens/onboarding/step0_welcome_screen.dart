import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../generated/app_localizations.dart';
import '../../bloc/onboarding_bloc.dart';
import '../../bloc/onboarding_event.dart';
import '../../bloc/onboarding_state.dart';
import '../../widgets/luxury_onboarding_layout.dart';
import '../../widgets/onboarding_progress_bar.dart';

/// First-run welcome step.
///
/// Frames GreenGo as a cultural-exchange, language, local-events and
/// networking community (NOT a dating app) before we start collecting
/// profile details. Short and skippable — a single "Get Started" advances.
class Step0WelcomeScreen extends StatelessWidget {
  const Step0WelcomeScreen({super.key});

  void _handleContinue(BuildContext context) {
    context.read<OnboardingBloc>().add(const OnboardingNextStep());
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
          title: l10n.onboardingWelcomeTitle,
          subtitle: l10n.onboardingWelcomeBody,
          showBackButton: false,
          progressBar: OnboardingProgressBar(
            currentStep: state.stepIndex,
            totalSteps: state.totalSteps,
          ),
          bottomChild: LuxuryButton(
            text: l10n.onboardingContinue,
            onPressed: () => _handleContinue(context),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WelcomeFeatureRow(
                  icon: Icons.public,
                  label: l10n.exploreTitle,
                ),
                const SizedBox(height: 16),
                _WelcomeFeatureRow(
                  icon: Icons.event,
                  label: l10n.eventsTitle,
                ),
                const SizedBox(height: 16),
                _WelcomeFeatureRow(
                  icon: Icons.groups,
                  label: l10n.communityTabTitle,
                ),
                const SizedBox(height: 16),
                _WelcomeFeatureRow(
                  icon: Icons.forum,
                  label: l10n.messages,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WelcomeFeatureRow extends StatelessWidget {
  const _WelcomeFeatureRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.richGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.richGold.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: AppColors.richGold, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
