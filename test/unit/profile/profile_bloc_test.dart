import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/profile/domain/usecases/create_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/get_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/update_profile.dart';
import 'package:greengo_chat/features/profile/domain/usecases/upload_photo.dart';
import 'package:greengo_chat/features/profile/domain/usecases/verify_photo.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/profile_fixtures.dart';

class _MockGetProfile extends Mock implements GetProfile {}

class _MockCreateProfile extends Mock implements CreateProfile {}

class _MockUpdateProfile extends Mock implements UpdateProfile {}

class _MockUploadPhoto extends Mock implements UploadPhoto {}

class _MockVerifyPhoto extends Mock implements VerifyPhoto {}

void main() {
  late _MockGetProfile getProfile;
  late _MockCreateProfile createProfile;
  late _MockUpdateProfile updateProfile;
  late _MockUploadPhoto uploadPhoto;
  late _MockVerifyPhoto verifyPhoto;

  final profile = buildProfile(nickname: 'ava');

  setUpAll(() {
    registerFallbackValue(GetProfileParams(userId: 'x'));
    registerFallbackValue(CreateProfileParams(profile: buildProfile()));
    registerFallbackValue(UpdateProfileParams(profile: buildProfile()));
  });

  setUp(() {
    getProfile = _MockGetProfile();
    createProfile = _MockCreateProfile();
    updateProfile = _MockUpdateProfile();
    uploadPhoto = _MockUploadPhoto();
    verifyPhoto = _MockVerifyPhoto();
  });

  ProfileBloc buildBloc() => ProfileBloc(
        getProfile: getProfile,
        createProfile: createProfile,
        updateProfile: updateProfile,
        uploadPhoto: uploadPhoto,
        verifyPhoto: verifyPhoto,
      );

  group('ProfileLoadRequested', () {
    test('emits [Loading, Loaded] on success', () async {
      when(() => getProfile(any()))
          .thenAnswer((_) async => Right(profile));
      final bloc = buildBloc();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileLoaded>().having((s) => s.profile, 'profile', profile),
        ]),
      );
      bloc.add(const ProfileLoadRequested(userId: 'user_fixture_1'));
      await expectation;
      await bloc.close();
    });

    test('emits [Loading, Error] with the failure message on failure',
        () async {
      when(() => getProfile(any()))
          .thenAnswer((_) async => const Left(ServerFailure('boom')));
      final bloc = buildBloc();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileError>().having((s) => s.message, 'message', 'boom'),
        ]),
      );
      bloc.add(const ProfileLoadRequested(userId: 'u'));
      await expectation;
      await bloc.close();
    });

    test('forwards the requested userId to the usecase', () async {
      when(() => getProfile(any()))
          .thenAnswer((_) async => Right(profile));
      final bloc = buildBloc();
      bloc.add(const ProfileLoadRequested(userId: 'abc123'));
      await bloc.stream.firstWhere((s) => s is ProfileLoaded);

      final captured =
          verify(() => getProfile(captureAny())).captured.single
              as GetProfileParams;
      expect(captured.userId, 'abc123');
      await bloc.close();
    });
  });

  group('ProfileCreateRequested', () {
    test('emits [Loading, Created] on success', () async {
      when(() => createProfile(any()))
          .thenAnswer((_) async => Right(profile));
      final bloc = buildBloc();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<ProfileLoading>(), isA<ProfileCreated>()]),
      );
      bloc.add(ProfileCreateRequested(profile: profile));
      await expectation;
      await bloc.close();
    });

    test('emits [Loading, Error] on failure', () async {
      when(() => createProfile(any()))
          .thenAnswer((_) async => const Left(ValidationFailure('bad')));
      final bloc = buildBloc();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileError>().having((s) => s.message, 'message', 'bad'),
        ]),
      );
      bloc.add(ProfileCreateRequested(profile: profile));
      await expectation;
      await bloc.close();
    });
  });

  group('ProfileUpdateRequested', () {
    test('emits [Loading, Updated] on success', () async {
      when(() => updateProfile(any()))
          .thenAnswer((_) async => Right(profile));
      final bloc = buildBloc();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([isA<ProfileLoading>(), isA<ProfileUpdated>()]),
      );
      bloc.add(ProfileUpdateRequested(profile: profile));
      await expectation;
      await bloc.close();
    });
  });

  group('ProfileNicknameUpdateRequested', () {
    test('loads current profile, lowercases nickname, then updates', () async {
      when(() => getProfile(any()))
          .thenAnswer((_) async => Right(profile));
      when(() => updateProfile(any())).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as UpdateProfileParams;
        return Right(params.profile);
      });
      final bloc = buildBloc();

      bloc.add(const ProfileNicknameUpdateRequested(
        userId: 'user_fixture_1',
        nickname: 'AVA_Reyes',
      ));

      final state =
          await bloc.stream.firstWhere((s) => s is ProfileUpdated)
              as ProfileUpdated;
      expect(state.profile.nickname, 'ava_reyes');
      await bloc.close();
    });

    test('emits Error when the underlying getProfile fails', () async {
      when(() => getProfile(any()))
          .thenAnswer((_) async => const Left(ServerFailure('no profile')));
      final bloc = buildBloc();

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProfileLoading>(),
          isA<ProfileError>().having((s) => s.message, 'message', 'no profile'),
        ]),
      );
      bloc.add(const ProfileNicknameUpdateRequested(
        userId: 'u',
        nickname: 'x',
      ));
      await expectation;
      await bloc.close();
    });
  });

  test('initial state is ProfileInitial', () {
    final bloc = buildBloc();
    expect(bloc.state, isA<ProfileInitial>());
    bloc.close();
  });
}
