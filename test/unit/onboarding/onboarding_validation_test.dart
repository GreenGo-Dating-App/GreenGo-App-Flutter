import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_state.dart';

/// Master Test Plan — B. Onboarding (per-step validation gating).
/// Pure tests for OnboardingInProgress.canProceedToNext — the single source of
/// truth that decides whether the "Next" button advances each onboarding step.
void main() {
  const location = Location(
    latitude: 38.72,
    longitude: -9.14,
    city: 'Lisbon',
    country: 'Portugal',
    displayAddress: 'Lisbon, Portugal',
  );
  const traits = PersonalityTraits(
    openness: 3,
    conscientiousness: 3,
    extraversion: 3,
    agreeableness: 3,
    neuroticism: 3,
  );

  OnboardingInProgress state(
    OnboardingStep step, {
    String? displayName,
    DateTime? dateOfBirth,
    String? gender,
    List<String> photoUrls = const [],
    String? verificationPhotoUrl,
    String? verificationMethod,
    String? verificationPhone,
    String? bio,
    List<String> interests = const [],
    Location? location,
    List<String> languages = const [],
    PersonalityTraits? personalityTraits,
  }) =>
      OnboardingInProgress(
        userId: 'u1',
        currentStep: step,
        displayName: displayName,
        dateOfBirth: dateOfBirth,
        gender: gender,
        photoUrls: photoUrls,
        verificationPhotoUrl: verificationPhotoUrl,
        verificationMethod: verificationMethod,
        verificationPhone: verificationPhone,
        bio: bio,
        interests: interests,
        location: location,
        languages: languages,
        personalityTraits: personalityTraits,
      );

  group('always-proceedable / optional steps', () {
    test('welcome, travelPreference, voice, socialLinks, preview are open', () {
      for (final step in [
        OnboardingStep.welcome,
        OnboardingStep.travelPreference,
        OnboardingStep.voice,
        OnboardingStep.socialLinks,
        OnboardingStep.preview,
      ]) {
        expect(state(step).canProceedToNext, isTrue, reason: '$step');
      }
    });
  });

  group('basicInfo step', () {
    test('blocked until name, DOB and gender are all present', () {
      expect(state(OnboardingStep.basicInfo).canProceedToNext, isFalse);
      expect(
        state(OnboardingStep.basicInfo,
                displayName: 'Ava', dateOfBirth: DateTime(2000))
            .canProceedToNext,
        isFalse,
        reason: 'gender still missing',
      );
    });

    test('allowed when name, DOB and gender are all set', () {
      expect(
        state(OnboardingStep.basicInfo,
                displayName: 'Ava',
                dateOfBirth: DateTime(2000),
                gender: 'female')
            .canProceedToNext,
        isTrue,
      );
    });
  });

  group('photos step', () {
    test('blocked with no photos, allowed with at least one', () {
      expect(state(OnboardingStep.photos).canProceedToNext, isFalse);
      expect(
        state(OnboardingStep.photos, photoUrls: const ['a.png'])
            .canProceedToNext,
        isTrue,
      );
    });
  });

  group('verification step', () {
    test('blocked with neither photo nor verified phone', () {
      expect(state(OnboardingStep.verification).canProceedToNext, isFalse);
    });

    test('allowed with a verification photo', () {
      expect(
        state(OnboardingStep.verification,
                verificationPhotoUrl: 'https://v/id.png')
            .canProceedToNext,
        isTrue,
      );
    });

    test('allowed with a phone verification method + number', () {
      expect(
        state(OnboardingStep.verification,
                verificationMethod: 'phone',
                verificationPhone: '+15551234567')
            .canProceedToNext,
        isTrue,
      );
    });
  });

  group('bio step', () {
    test('blocked when empty, allowed when filled', () {
      expect(state(OnboardingStep.bio, bio: '').canProceedToNext, isFalse);
      expect(state(OnboardingStep.bio, bio: 'Hi!').canProceedToNext, isTrue);
    });
  });

  group('interests step', () {
    test('requires at least three interests', () {
      expect(
        state(OnboardingStep.interests, interests: const ['a', 'b'])
            .canProceedToNext,
        isFalse,
      );
      expect(
        state(OnboardingStep.interests, interests: const ['a', 'b', 'c'])
            .canProceedToNext,
        isTrue,
      );
    });
  });

  group('locationLanguage step', () {
    test('requires both a location and at least one language', () {
      expect(
        state(OnboardingStep.locationLanguage, languages: const ['en'])
            .canProceedToNext,
        isFalse,
        reason: 'location missing',
      );
      expect(
        state(OnboardingStep.locationLanguage, location: location)
            .canProceedToNext,
        isFalse,
        reason: 'languages missing',
      );
      expect(
        state(OnboardingStep.locationLanguage,
                location: location, languages: const ['en'])
            .canProceedToNext,
        isTrue,
      );
    });
  });

  group('personality step', () {
    test('requires personality traits to be answered', () {
      expect(state(OnboardingStep.personality).canProceedToNext, isFalse);
      expect(
        state(OnboardingStep.personality, personalityTraits: traits)
            .canProceedToNext,
        isTrue,
      );
    });
  });
}
