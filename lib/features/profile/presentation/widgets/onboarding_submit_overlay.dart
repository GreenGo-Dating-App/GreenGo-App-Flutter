import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../bloc/onboarding_state.dart';

/// Blocking overlay shown while the final "Complete Profile" submit runs.
///
/// Registration is several seconds of real work — profile write, welcome
/// coins, coupon and referral redemption, then an auth access re-check and the
/// first load of the home screen. Without this the wizard just sat there with a
/// live button and people tapped it repeatedly.
///
/// It swallows every pointer event, so it doubles as the input guard: the
/// re-entry check in the bloc is the backstop, this is what users actually see.
class OnboardingSubmitOverlay extends StatelessWidget {
  const OnboardingSubmitOverlay({super.key, this.stage});

  /// Null while the bloc has finished but navigation has not happened yet — the
  /// overlay stays up through that gap rather than flashing the wizard again.
  final OnboardingSubmitStage? stage;

  String _label(AppLocalizations l10n) {
    switch (stage) {
      case OnboardingSubmitStage.creatingProfile:
        return l10n.onboardingSubmitCreatingProfile;
      case OnboardingSubmitStage.grantingCoins:
        return l10n.onboardingSubmitGrantingCoins;
      case OnboardingSubmitStage.finishingUp:
      case null:
        return l10n.onboardingSubmitFinishingUp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.82),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                  backgroundColor: AppColors.richGold.withValues(alpha: 0.15),
                ),
              ),
              const SizedBox(height: 28),
              // Keyed so the stage copy cross-fades instead of snapping.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Padding(
                  key: ValueKey(stage),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _label(l10n),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.onboardingSubmitPleaseWait,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
