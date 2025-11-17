import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profile.dart';
import '../../domain/usecases/create_profile.dart';
import '../../domain/usecases/upload_photo.dart';
import '../../domain/usecases/verify_photo.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final CreateProfile createProfile;
  final UploadPhoto uploadPhoto;
  final VerifyPhoto verifyPhoto;

  OnboardingBloc({
    required this.createProfile,
    required this.uploadPhoto,
    required this.verifyPhoto,
  }) : super(const OnboardingInitial()) {
    on<OnboardingStarted>(_onOnboardingStarted);
    on<OnboardingNextStep>(_onOnboardingNextStep);
    on<OnboardingPreviousStep>(_onOnboardingPreviousStep);
    on<OnboardingBasicInfoUpdated>(_onOnboardingBasicInfoUpdated);
    on<OnboardingPhotosUpdated>(_onOnboardingPhotosUpdated);
    on<OnboardingPhotoAdded>(_onOnboardingPhotoAdded);
    on<OnboardingBioUpdated>(_onOnboardingBioUpdated);
    on<OnboardingInterestsUpdated>(_onOnboardingInterestsUpdated);
    on<OnboardingLocationUpdated>(_onOnboardingLocationUpdated);
    on<OnboardingVoiceUpdated>(_onOnboardingVoiceUpdated);
    on<OnboardingPersonalityUpdated>(_onOnboardingPersonalityUpdated);
    on<OnboardingCompleted>(_onOnboardingCompleted);
  }

  void _onOnboardingStarted(
    OnboardingStarted event,
    Emitter<OnboardingState> emit,
  ) {
    emit(OnboardingInProgress(
      userId: event.userId,
      currentStep: OnboardingStep.basicInfo,
    ));
  }

  void _onOnboardingNextStep(
    OnboardingNextStep event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;

      if (!currentState.canProceedToNext) {
        emit(const OnboardingError(
            message: 'Please complete all required fields'));
        emit(currentState); // Restore previous state
        return;
      }

      final nextStepIndex = currentState.stepIndex + 1;
      if (nextStepIndex < OnboardingStep.values.length) {
        emit(currentState.copyWith(
          currentStep: OnboardingStep.values[nextStepIndex],
        ));
      }
    }
  }

  void _onOnboardingPreviousStep(
    OnboardingPreviousStep event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      final previousStepIndex = currentState.stepIndex - 1;

      if (previousStepIndex >= 0) {
        emit(currentState.copyWith(
          currentStep: OnboardingStep.values[previousStepIndex],
        ));
      }
    }
  }

  void _onOnboardingBasicInfoUpdated(
    OnboardingBasicInfoUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(
        displayName: event.displayName,
        dateOfBirth: event.dateOfBirth,
        gender: event.gender,
      ));
    }
  }

  void _onOnboardingPhotosUpdated(
    OnboardingPhotosUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(photoUrls: event.photoUrls));
    }
  }

  Future<void> _onOnboardingPhotoAdded(
    OnboardingPhotoAdded event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;

      emit(const OnboardingPhotoUploading());

      // Verify photo with AI
      final verifyResult =
          await verifyPhoto(VerifyPhotoParams(photo: event.photo));

      await verifyResult.fold(
        (failure) async {
          emit(OnboardingError(message: failure.message));
          emit(currentState); // Restore previous state
        },
        (isVerified) async {
          if (!isVerified) {
            emit(const OnboardingError(
                message: 'Photo verification failed. Please use a clear photo of your face.'));
            emit(currentState);
            return;
          }

          // Upload photo
          final uploadResult = await uploadPhoto(
            UploadPhotoParams(userId: currentState.userId, photo: event.photo),
          );

          uploadResult.fold(
            (failure) {
              emit(OnboardingError(message: failure.message));
              emit(currentState);
            },
            (photoUrl) {
              final updatedPhotoUrls = List<String>.from(currentState.photoUrls)
                ..add(photoUrl);
              emit(currentState.copyWith(photoUrls: updatedPhotoUrls));
            },
          );
        },
      );
    }
  }

  void _onOnboardingBioUpdated(
    OnboardingBioUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(bio: event.bio));
    }
  }

  void _onOnboardingInterestsUpdated(
    OnboardingInterestsUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(interests: event.interests));
    }
  }

  void _onOnboardingLocationUpdated(
    OnboardingLocationUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(
        location: event.location,
        languages: event.languages,
      ));
    }
  }

  void _onOnboardingVoiceUpdated(
    OnboardingVoiceUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(voiceUrl: event.voiceUrl));
    }
  }

  void _onOnboardingPersonalityUpdated(
    OnboardingPersonalityUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(personalityTraits: event.traits));
    }
  }

  Future<void> _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;

      // Create profile from onboarding data
      final profile = Profile(
        userId: currentState.userId,
        displayName: currentState.displayName!,
        dateOfBirth: currentState.dateOfBirth!,
        gender: currentState.gender!,
        photoUrls: currentState.photoUrls,
        bio: currentState.bio ?? '',
        interests: currentState.interests,
        location: currentState.location!,
        languages: currentState.languages,
        voiceRecordingUrl: currentState.voiceUrl,
        personalityTraits: currentState.personalityTraits,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isComplete: true,
      );

      final result = await createProfile(CreateProfileParams(profile: profile));

      result.fold(
        (failure) => emit(OnboardingError(message: failure.message)),
        (createdProfile) => emit(OnboardingComplete(profile: createdProfile)),
      );
    }
  }
}
