import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/photo_validation_service.dart';
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
    // Private photos skip validation (NSFW allowed in private/chat)
    if (!event.isPrivate) {
      emit(const ProfilePhotoValidating());

      final validationService = PhotoValidationService();
      PhotoValidationResult validationResult;

      if (event.isMainPhoto) {
        // Main photo: must have face + no NSFW
        validationResult =
            await validationService.validateMainPhoto(event.photo);
        if (!validationResult.isValid) {
          emit(ProfilePhotoValidationFailed(
              errorCode: validationResult.errorCode));
          return;
        }
        if (!validationResult.hasFace) {
          emit(const ProfilePhotoValidationFailed(
              errorCode: PhotoValidationError.mainNoFace));
          return;
        }
      } else {
        // Other public photos: no NSFW (no face required)
        validationResult =
            await validationService.validatePublicPhoto(event.photo);
        if (!validationResult.isValid) {
          emit(ProfilePhotoValidationFailed(
              errorCode: validationResult.errorCode));
          return;
        }
      }
    }

    // Validation passed (or private photo) — upload
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

    // Use isLeft/getOrElse pattern instead of fold with async callbacks
    if (getResult.isLeft()) {
      final failure = getResult.fold((f) => f, (_) => throw Exception('Unreachable'));
      emit(ProfileError(message: failure.message));
      return;
    }

    // Get the profile from successful result
    final profile = getResult.getOrElse(() => throw Exception('Unreachable'));

    // Update the profile with the new nickname
    final updatedProfile = profile.copyWith(nickname: event.nickname.toLowerCase());
    final updateResult = await updateProfile(UpdateProfileParams(profile: updatedProfile));

    // Handle update result
    if (updateResult.isLeft()) {
      final failure = updateResult.fold((f) => f, (_) => throw Exception('Unreachable'));
      emit(ProfileError(message: failure.message));
      return;
    }

    // Emit success with updated profile
    final updatedProfileResult = updateResult.getOrElse(() => throw Exception('Unreachable'));
    emit(ProfileUpdated(profile: updatedProfileResult));
  }
}
