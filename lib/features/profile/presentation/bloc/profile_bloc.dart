import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/get_profile.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_photo.dart';
import '../../domain/usecases/verify_photo.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final GetProfile getProfile;
  final CreateProfile createProfile;
  final UpdateProfile updateProfile;
  final UploadPhoto uploadPhoto;
  final VerifyPhoto verifyPhoto;

  ProfileBloc({
    required this.getProfile,
    required this.createProfile,
    required this.updateProfile,
    required this.uploadPhoto,
    required this.verifyPhoto,
  }) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileCreateRequested>(_onProfileCreateRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
    on<ProfilePhotoUploadRequested>(_onProfilePhotoUploadRequested);
    on<ProfilePhotoVerificationRequested>(_onProfilePhotoVerificationRequested);
    on<ProfileNicknameUpdateRequested>(_onProfileNicknameUpdateRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await getProfile(GetProfileParams(userId: event.userId));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> _onProfileCreateRequested(
    ProfileCreateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result =
        await createProfile(CreateProfileParams(profile: event.profile));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileCreated(profile: profile)),
    );
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result =
        await updateProfile(UpdateProfileParams(profile: event.profile));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (profile) => emit(ProfileUpdated(profile: profile)),
    );
  }

  Future<void> _onProfilePhotoUploadRequested(
    ProfilePhotoUploadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await uploadPhoto(
      UploadPhotoParams(userId: event.userId, photo: event.photo),
    );

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (photoUrl) => emit(ProfilePhotoUploaded(photoUrl: photoUrl)),
    );
  }

  Future<void> _onProfilePhotoVerificationRequested(
    ProfilePhotoVerificationRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await verifyPhoto(VerifyPhotoParams(photo: event.photo));

    result.fold(
      (failure) => emit(ProfileError(message: failure.message)),
      (isVerified) => emit(ProfilePhotoVerified(isVerified: isVerified)),
    );
  }

  Future<void> _onProfileNicknameUpdateRequested(
    ProfileNicknameUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    // First get the current profile
    final getResult = await getProfile(GetProfileParams(userId: event.userId));

    await getResult.fold(
      (failure) async => emit(ProfileError(message: failure.message)),
      (profile) async {
        // Update the profile with the new nickname
        final updatedProfile = profile.copyWith(nickname: event.nickname.toLowerCase());
        final updateResult = await updateProfile(UpdateProfileParams(profile: updatedProfile));

        updateResult.fold(
          (failure) => emit(ProfileError(message: failure.message)),
          (profile) => emit(ProfileUpdated(profile: profile)),
        );
      },
    );
  }
}
