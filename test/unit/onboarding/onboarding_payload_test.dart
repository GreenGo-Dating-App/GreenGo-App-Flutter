import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/features/profile/domain/entities/social_links.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_state.dart';

/// Master Test Plan — B. Onboarding (state model + completion payload).
/// Covers the OnboardingStep enum contract, OnboardingInProgress progress/
/// copyWith accounting, the completion payload the state carries, and the
/// value entities (Location, SocialLinks, PersonalityTraits) that flow into the
/// created Profile.
void main() {
  const location = Location(
    latitude: 38.72,
    longitude: -9.14,
    city: 'Lisbon',
    country: 'Portugal',
    displayAddress: 'Lisbon, Portugal',
  );
  const traits = PersonalityTraits(
    openness: 4,
    conscientiousness: 3,
    extraversion: 5,
    agreeableness: 2,
    neuroticism: 1,
  );

  group('OnboardingStep enum contract', () {
    test('welcome is first and there are 12 ordered steps', () {
      expect(OnboardingStep.values.first, OnboardingStep.welcome);
      expect(OnboardingStep.welcome.index, 0);
      expect(OnboardingStep.values.length, 12);
      expect(OnboardingStep.values.last, OnboardingStep.preview);
    });
  });

  group('OnboardingInProgress progress accounting', () {
    test('stepIndex/totalSteps/progress are consistent', () {
      const s = OnboardingInProgress(
        userId: 'u1',
        currentStep: OnboardingStep.photos, // index 2
      );
      expect(s.stepIndex, OnboardingStep.photos.index);
      expect(s.totalSteps, OnboardingStep.values.length);
      expect(s.progress, closeTo((s.stepIndex + 1) / s.totalSteps, 1e-9));
    });

    test('progress reaches 1.0 on the final step', () {
      const s = OnboardingInProgress(
        userId: 'u1',
        currentStep: OnboardingStep.preview,
      );
      expect(s.progress, 1.0);
    });
  });

  group('OnboardingInProgress.copyWith', () {
    test('preserves userId and overrides only supplied fields', () {
      const base = OnboardingInProgress(
        userId: 'u1',
        currentStep: OnboardingStep.bio,
        displayName: 'Ava',
      );
      final next = base.copyWith(
        currentStep: OnboardingStep.interests,
        bio: 'Curious traveller',
      );
      expect(next.userId, 'u1'); // userId is not a copyWith parameter
      expect(next.currentStep, OnboardingStep.interests);
      expect(next.bio, 'Curious traveller');
      expect(next.displayName, 'Ava'); // carried over
    });
  });

  group('completion payload carried by the in-progress state', () {
    test('a fully-filled state holds every field the Profile is built from', () {
      final filled = OnboardingInProgress(
        userId: 'u1',
        currentStep: OnboardingStep.preview,
        displayName: 'Ava Reyes',
        dateOfBirth: DateTime(1998, 5, 20),
        gender: 'female',
        photoUrls: const ['p1.png', 'p2.png'],
        bio: 'Explorer',
        interests: const ['music', 'travel', 'food'],
        location: location,
        languages: const ['en', 'pt'],
        personalityTraits: traits,
        preferredLanguages: const ['es'],
        nativeLanguage: 'en',
        travelPreference: 'both',
        verificationMethod: 'phone',
        verificationPhone: '+15551234567',
      );

      expect(filled.displayName, 'Ava Reyes');
      expect(filled.photoUrls, hasLength(2));
      expect(filled.interests, contains('travel'));
      expect(filled.location, location);
      expect(filled.languages, ['en', 'pt']);
      expect(filled.personalityTraits, traits);
      expect(filled.preferredLanguages, ['es']);
      expect(filled.travelPreference, 'both');
      // Phone verification is the auto-approve signal the completion handler
      // maps to VerificationStatus.approved.
      expect(filled.verificationMethod, 'phone');
      expect(filled.verificationPhone, isNotEmpty);
    });
  });

  group('OnboardingComplete / OnboardingError states', () {
    test('OnboardingComplete exposes the profile and null coupon by default',
        () {
      final profile = Profile(
        userId: 'u1',
        displayName: 'Ava',
        dateOfBirth: DateTime(1998, 5, 20),
        gender: 'female',
        photoUrls: const ['p1.png'],
        bio: 'hi',
        interests: const ['a', 'b', 'c'],
        location: location,
        languages: const ['en'],
        createdAt: DateTime(2026, 7, 15),
        updatedAt: DateTime(2026, 7, 15),
        isComplete: true,
      );
      final state = OnboardingComplete(profile: profile);
      expect(state.profile.userId, 'u1');
      expect(state.couponOutcome, isNull);
    });

    test('OnboardingError carries its message in props', () {
      const err = OnboardingError(message: 'photo_validation:mainNoFace');
      expect(err.props, ['photo_validation:mainNoFace']);
    });
  });

  group('Location value entity', () {
    test('round-trips through JSON', () {
      final restored = Location.fromJson(location.toJson());
      expect(restored, location);
    });
  });

  group('SocialLinks value entity', () {
    test('empty has no links and zero count', () {
      const empty = SocialLinks.empty();
      expect(empty.hasAnyLink, isFalse);
      expect(empty.linkedCount, 0);
    });

    test('counts only the non-empty handles and builds handle URLs', () {
      const links = SocialLinks(instagram: '@ava', x: 'ava_r');
      expect(links.hasAnyLink, isTrue);
      expect(links.linkedCount, 2);
      expect(links.instagramUrl, 'https://www.instagram.com/ava');
      expect(links.xUrl, 'https://www.x.com/ava_r');
    });
  });

  group('PersonalityTraits value entity', () {
    test('is value-equal via Equatable', () {
      const a = PersonalityTraits(
        openness: 1,
        conscientiousness: 2,
        extraversion: 3,
        agreeableness: 4,
        neuroticism: 5,
      );
      const b = PersonalityTraits(
        openness: 1,
        conscientiousness: 2,
        extraversion: 3,
        agreeableness: 4,
        neuroticism: 5,
      );
      expect(a, equals(b));
    });
  });
}
