import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/create_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/upload_photo.dart';
import 'package:greengo_chat/features/profile/domain/usecases/verify_photo.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/onboarding_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateProfile extends Mock implements CreateProfile {}

class _MockUploadPhoto extends Mock implements UploadPhoto {}

class _MockVerifyPhoto extends Mock implements VerifyPhoto {}

/// Invite links: once onboarding has created the profile, a pending invite
/// code is redeemed automatically (never when the profile could not be
/// created, and never blocking completion).
void main() {
  setUpAll(() {
    registerFallbackValue(CreateProfileParams(
      profile: Profile(
        userId: 'x',
        displayName: 'x',
        dateOfBirth: DateTime(2000),
        gender: 'x',
        photoUrls: const [],
        bio: '',
        interests: const [],
        location: const Location(
            latitude: 0, longitude: 0, city: '', country: '', displayAddress: ''),
        languages: const [],
        createdAt: DateTime(2000),
        updatedAt: DateTime(2000),
        isComplete: true,
      ),
    ));
  });

  final ready = OnboardingInProgress(
    userId: 'u1',
    currentStep: OnboardingStep.preview,
    displayName: 'Ava Reyes',
    dateOfBirth: DateTime(1998, 5, 20),
    gender: 'female',
    photoUrls: const ['p1.png'],
    interests: const ['music', 'travel', 'food'],
    location: const Location(
      latitude: 38.72,
      longitude: -9.14,
      city: 'Lisbon',
      country: 'Portugal',
      displayAddress: 'Lisbon, Portugal',
    ),
    languages: const ['en'],
  );

  Future<int> complete({required bool profileCreated}) async {
    final create = _MockCreateProfile();
    when(() => create(any())).thenAnswer((inv) async {
      final p = (inv.positionalArguments.first as CreateProfileParams).profile;
      return profileCreated
          ? Right<Failure, Profile>(p)
          : const Left<Failure, Profile>(ServerFailure('boom'));
    });
    var redeemCalls = 0;
    final bloc = OnboardingBloc(
      createProfile: create,
      uploadPhoto: _MockUploadPhoto(),
      verifyPhoto: _MockVerifyPhoto(),
      redeemPendingReferral: () async {
        redeemCalls++;
        throw Exception('network down'); // must never break onboarding
      },
    );
    // ignore: invalid_use_of_visible_for_testing_member
    bloc.emit(ready);
    bloc.add(const OnboardingCompleted());
    await bloc.stream.firstWhere(
        (s) => s is OnboardingComplete || s is OnboardingError);
    await Future<void>.delayed(Duration.zero);
    if (profileCreated) expect(bloc.state, isA<OnboardingComplete>());
    await bloc.close();
    return redeemCalls;
  }

  test('profile created -> pending invite is redeemed once, failures ignored',
      () async {
    expect(await complete(profileCreated: true), 1);
  });

  test('profile creation failed -> no redemption attempt', () async {
    expect(await complete(profileCreated: false), 0);
  });
}
