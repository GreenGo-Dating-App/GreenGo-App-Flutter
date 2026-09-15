import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../widgets/onboarding_submit_overlay.dart';
import 'onboarding/onboarding_exit.dart';
import 'onboarding/step0_welcome_screen.dart';
import 'onboarding/step1_basic_info_screen.dart';
import 'onboarding/step2_photo_upload_screen.dart';
import 'onboarding/step3_bio_screen.dart';
import 'onboarding/step3_verification_screen.dart';
import 'onboarding/step4_interests_screen.dart';
import 'onboarding/step5_location_language_screen.dart';
import 'onboarding/step5c_travel_preference_screen.dart';
import 'onboarding/step6_voice_recording_screen.dart';
import 'onboarding/step7_personality_quiz_screen.dart';
import 'onboarding/step8_profile_preview_screen.dart';
import 'onboarding/step9_social_links_screen.dart';

class OnboardingScreen extends StatelessWidget {

  const OnboardingScreen({
    required this.userId, super.key,
  });
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<OnboardingBloc>()
        ..add(OnboardingStarted(userId: userId)),
      child: BlocConsumer<OnboardingBloc, OnboardingState>(
        listener: (context, state) async {
          if (state is OnboardingComplete) {
            // Trigger access status re-check so auth wrapper shows Verification Pending
            if (context.mounted) {
              context.read<AuthBloc>().add(const AuthCheckAccessStatusRequested());
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          } else if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          // Intercept ALL back navigation (system/browser back + first-step back
          // arrow). The wizard lives inside the single '/' route, so popping it
          // would leave a black screen. Instead: go to the previous step, or —
          // on the first step — offer to exit (sign out → login).
          void handleBack(bool didPop, dynamic _) {
            if (didPop) return;
            final s = context.read<OnboardingBloc>().state;
            if (s is OnboardingInProgress && s.isSubmitting) return;
            if (s is OnboardingInProgress && s.stepIndex > 0) {
              context.read<OnboardingBloc>().add(const OnboardingPreviousStep());
            } else {
              showOnboardingExitDialog(context);
            }
          }

          if (state is OnboardingInitial || state is! OnboardingInProgress) {
            // OnboardingComplete lands here too, between the bloc finishing and
            // the navigation below landing — keep the submit overlay up across
            // that gap instead of flashing a bare spinner.
            final completing = state is OnboardingComplete;
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: handleBack,
              child: Scaffold(
                backgroundColor: completing ? Colors.black : null,
                body: completing
                    ? const OnboardingSubmitOverlay()
                    : const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final Widget stepWidget;
          // Return the appropriate screen based on current step
          switch (state.currentStep) {
            case OnboardingStep.welcome:
              stepWidget = const Step0WelcomeScreen();
            case OnboardingStep.basicInfo:
              stepWidget = const Step1BasicInfoScreen();
            case OnboardingStep.photos:
              stepWidget = const Step2PhotoUploadScreen();
            case OnboardingStep.verification:
              stepWidget = const Step3VerificationScreen();
            case OnboardingStep.bio:
              stepWidget = const Step3BioScreen();
            case OnboardingStep.interests:
              stepWidget = const Step4InterestsScreen();
            case OnboardingStep.locationLanguage:
              stepWidget = const Step5LocationLanguageScreen();
            case OnboardingStep.travelPreference:
              stepWidget = const Step5cTravelPreferenceScreen();
            case OnboardingStep.voice:
              stepWidget = const Step6VoiceRecordingScreen();
            case OnboardingStep.personality:
              stepWidget = const Step7PersonalityQuizScreen();
            case OnboardingStep.socialLinks:
              stepWidget = const Step9SocialLinksScreen();
            case OnboardingStep.preview:
              stepWidget = const Step8ProfilePreviewScreen();
          }

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: handleBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.1, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(state.currentStep),
                child: state.isSubmitting
                    ? Stack(
                        children: [
                          stepWidget,
                          Positioned.fill(
                            child: OnboardingSubmitOverlay(
                              stage: state.submitStage,
                            ),
                          ),
                        ],
                      )
                    : stepWidget,
              ),
            ),
          );
        },
      ),
    );
  }
}
