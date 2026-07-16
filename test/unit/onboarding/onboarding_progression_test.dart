import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/usecases/create_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/upload_photo.dart';
import 'package:greengo_chat/features/profile/domain/usecases/verify_photo.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_state.dart';
import 'package:mocktail/mocktail.dart';

/// Master Test Plan — B. Onboarding (step navigation + validation gating in the
/// BLoC). Drives OnboardingBloc with mocked usecases. The completion path (which
/// touches Firebase) is intentionally NOT exercised here; see
/// onboarding_payload_test.dart for the completion-payload assertions.
class _MockCreateProfile extends Mock implements CreateProfile {}

class _MockUploadPhoto extends Mock implements UploadPhoto {}

class _MockVerifyPhoto extends Mock implements VerifyPhoto {}

void main() {
  late OnboardingBloc bloc;

  OnboardingInProgress asProgress(OnboardingState s) =>
      s as OnboardingInProgress;

  setUp(() {
    bloc = OnboardingBloc(
      createProfile: _MockCreateProfile(),
      uploadPhoto: _MockUploadPhoto(),
      verifyPhoto: _MockVerifyPhoto(),
    );
  });

  tearDown(() => bloc.close());

  test('OnboardingStarted opens at the welcome step', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.welcome)
            .having((s) => s.userId, 'userId', 'u1'),
      ]),
    );

    bloc.add(const OnboardingStarted(userId: 'u1'));
    await expectation;
  });

  test('NextStep advances welcome -> basicInfo (welcome is always open)',
      () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.welcome),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.basicInfo),
      ]),
    );

    bloc
      ..add(const OnboardingStarted(userId: 'u1'))
      ..add(const OnboardingNextStep());
    await expectation;
  });

  test('NextStep is gated at basicInfo when required fields are missing',
      () async {
    // Blocked: emits an error then restores the same in-progress step.
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.welcome),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.basicInfo),
        isA<OnboardingError>(),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.basicInfo),
      ]),
    );

    bloc
      ..add(const OnboardingStarted(userId: 'u1'))
      ..add(const OnboardingNextStep()) // -> basicInfo
      ..add(const OnboardingNextStep()); // blocked (no name/DOB/gender)
    await expectation;
  });

  test('filling basicInfo unblocks NextStep -> photos', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.welcome),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.basicInfo),
        isA<OnboardingInProgress>()
            .having((s) => s.displayName, 'displayName', 'Ava')
            .having((s) => s.currentStep, 'step', OnboardingStep.basicInfo),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.photos),
      ]),
    );

    bloc
      ..add(const OnboardingStarted(userId: 'u1'))
      ..add(const OnboardingNextStep())
      ..add(OnboardingBasicInfoUpdated(
        displayName: 'Ava',
        dateOfBirth: DateTime(2000),
        gender: 'female',
      ))
      ..add(const OnboardingNextStep());
    await expectation;
  });

  test('PreviousStep returns from basicInfo to welcome', () async {
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.welcome),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.basicInfo),
        isA<OnboardingInProgress>()
            .having((s) => s.currentStep, 'step', OnboardingStep.welcome),
      ]),
    );

    bloc
      ..add(const OnboardingStarted(userId: 'u1'))
      ..add(const OnboardingNextStep())
      ..add(const OnboardingPreviousStep());
    await expectation;
  });

  test('update events accumulate onto the in-progress payload', () async {
    bloc.add(const OnboardingStarted(userId: 'u1'));
    await bloc.stream.firstWhere((s) => s is OnboardingInProgress);

    bloc.add(const OnboardingInterestsUpdated(
        interests: ['music', 'travel', 'food']));
    final s1 = asProgress(
        await bloc.stream.firstWhere((s) => s is OnboardingInProgress));
    expect(s1.interests, ['music', 'travel', 'food']);

    bloc.add(const OnboardingBioUpdated(bio: 'Explorer at heart'));
    final s2 = asProgress(
        await bloc.stream.firstWhere((s) => s is OnboardingInProgress));
    expect(s2.bio, 'Explorer at heart');
    // Earlier updates are preserved across subsequent events.
    expect(s2.interests, ['music', 'travel', 'food']);
  });

  test('phone verification records method + number on the state', () async {
    bloc.add(const OnboardingStarted(userId: 'u1'));
    await bloc.stream.firstWhere((s) => s is OnboardingInProgress);

    bloc.add(const OnboardingPhoneVerificationCompleted(
        phoneNumber: '+15551234567'));
    final s = asProgress(
        await bloc.stream.firstWhere((s) => s is OnboardingInProgress));
    expect(s.verificationMethod, 'phone');
    expect(s.verificationPhone, '+15551234567');
  });
}
