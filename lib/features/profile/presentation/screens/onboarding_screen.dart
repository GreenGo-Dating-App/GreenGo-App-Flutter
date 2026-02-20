import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:greengo_chat/core/di/injection_container.dart' as di;
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import 'onboarding/step1_basic_info_screen.dart';
import 'onboarding/step2_photo_upload_screen.dart';
import 'onboarding/step3_verification_screen.dart';
import 'onboarding/step3_bio_screen.dart';
import 'onboarding/step4_interests_screen.dart';
import 'onboarding/step5_location_language_screen.dart';
import 'onboarding/step6_voice_recording_screen.dart';
import 'onboarding/step7_personality_quiz_screen.dart';
import 'onboarding/step9_social_links_screen.dart';
import 'onboarding/step8_profile_preview_screen.dart';

class OnboardingScreen extends StatelessWidget {
  final String userId;

  const OnboardingScreen({
    super.key,
    required this.userId,
  });

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
              context.read<AuthBloc>().add(AuthCheckAccessStatusRequested());
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
          if (state is OnboardingInitial) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is! OnboardingInProgress) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // Return the appropriate screen based on current step
          switch (state.currentStep) {
            case OnboardingStep.basicInfo:
              return const Step1BasicInfoScreen();
            case OnboardingStep.photos:
              return const Step2PhotoUploadScreen();
            case OnboardingStep.verification:
              return const Step3VerificationScreen();
            case OnboardingStep.bio:
              return const Step3BioScreen();
            case OnboardingStep.interests:
              return const Step4InterestsScreen();
            case OnboardingStep.locationLanguage:
              return const Step5LocationLanguageScreen();
            case OnboardingStep.voice:
              return const Step6VoiceRecordingScreen();
            case OnboardingStep.personality:
              return const Step7PersonalityQuizScreen();
            case OnboardingStep.socialLinks:
              return const Step9SocialLinksScreen();
            case OnboardingStep.preview:
              return const Step8ProfilePreviewScreen();
          }
        },
      ),
    );
  }
}
