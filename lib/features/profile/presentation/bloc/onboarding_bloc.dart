import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/photo_validation_service.dart';
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
    on<OnboardingVerificationPhotoAdded>(_onOnboardingVerificationPhotoAdded);
    on<OnboardingVerificationPhotoUpdated>(_onOnboardingVerificationPhotoUpdated);
    on<OnboardingLearningLanguagesUpdated>(_onOnboardingLearningLanguagesUpdated);
    on<OnboardingTravelPreferenceUpdated>(_onOnboardingTravelPreferenceUpdated);
    on<OnboardingSocialLinksUpdated>(_onOnboardingSocialLinksUpdated);
    on<OnboardingPhoneVerificationCompleted>(_onOnboardingPhoneVerificationCompleted);
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

      final isFirstPhoto = currentState.photoUrls.isEmpty;
      final validationService = PhotoValidationService();

      // Validate photo locally BEFORE uploading:
      // - First photo: must have face + no NSFW
      // - Other photos: no NSFW (no face required)
      PhotoValidationResult validationResult;
      if (isFirstPhoto) {
        validationResult =
            await validationService.validateMainPhoto(event.photo);

        if (!validationResult.isValid || !validationResult.hasFace) {
          final errorCode = validationResult.errorCode?.name ?? 'mainNoFace';
          emit(OnboardingError(message: 'photo_validation:$errorCode'));
          emit(currentState);
          return;
        }
      } else {
        validationResult =
            await validationService.validatePublicPhoto(event.photo);

        if (!validationResult.isValid) {
          final errorCode = validationResult.errorCode?.name ?? 'explicitContent';
          emit(OnboardingError(message: 'photo_validation:$errorCode'));
          emit(currentState);
          return;
        }
      }

      // Validation passed — show uploading indicator and upload
      emit(currentState.copyWith(isUploading: true));

      final uploadResult = await uploadPhoto(
        UploadPhotoParams(userId: currentState.userId, photo: event.photo),
      );

      uploadResult.fold(
        (failure) {
          emit(OnboardingError(message: failure.message));
          emit(currentState.copyWith(isUploading: false));
        },
        (photoUrl) {
          final updatedPhotoUrls = List<String>.from(currentState.photoUrls)
            ..add(photoUrl);
          emit(currentState.copyWith(photoUrls: updatedPhotoUrls, isUploading: false));
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

  Future<void> _onOnboardingVerificationPhotoAdded(
    OnboardingVerificationPhotoAdded event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;

      emit(currentState.copyWith(isUploading: true));

      // Upload verification photo (separate from profile photos)
      final uploadResult = await uploadPhoto(
        UploadPhotoParams(
          userId: currentState.userId,
          photo: event.photo,
          folder: 'verifications', // Store in separate folder
        ),
      );

      uploadResult.fold(
        (failure) {
          emit(OnboardingError(message: failure.message));
          emit(currentState.copyWith(isUploading: false));
        },
        (photoUrl) {
          emit(currentState.copyWith(verificationPhotoUrl: photoUrl, isUploading: false));
        },
      );
    }
  }

  void _onOnboardingVerificationPhotoUpdated(
    OnboardingVerificationPhotoUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(verificationPhotoUrl: event.photoUrl));
    }
  }

  void _onOnboardingLearningLanguagesUpdated(
    OnboardingLearningLanguagesUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(
        preferredLanguages: event.preferredLanguages,
        nativeLanguage: event.nativeLanguage,
      ));
    }
  }

  void _onOnboardingTravelPreferenceUpdated(
    OnboardingTravelPreferenceUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(travelPreference: event.travelPreference));
    }
  }

  void _onOnboardingSocialLinksUpdated(
    OnboardingSocialLinksUpdated event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(socialLinks: event.socialLinks));
    }
  }

  void _onOnboardingPhoneVerificationCompleted(
    OnboardingPhoneVerificationCompleted event,
    Emitter<OnboardingState> emit,
  ) {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;
      emit(currentState.copyWith(
        verificationMethod: 'phone',
        verificationPhone: event.phoneNumber,
      ));
    }
  }

  Future<void> _onOnboardingCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is OnboardingInProgress) {
      final currentState = state as OnboardingInProgress;

      // Create profile from onboarding data
      final now = DateTime.now();
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
        socialLinks: currentState.socialLinks,
        createdAt: now,
        updatedAt: now,
        isComplete: true,
        // Verification fields
        // Phone verification = auto-approved; photo = pending admin review
        verificationStatus: currentState.verificationMethod == 'phone'
            ? VerificationStatus.approved
            : VerificationStatus.pending,
        verificationPhotoUrl: currentState.verificationPhotoUrl,
        verificationMethod: currentState.verificationMethod,
        verificationPhone: currentState.verificationPhone,
        verificationSubmittedAt: (currentState.verificationPhotoUrl != null || currentState.verificationPhone != null) ? now : null,
        verificationReviewedAt: currentState.verificationMethod == 'phone' ? now : null,
        // Language learning fields
        preferredLanguages: currentState.preferredLanguages,
        nativeLanguage: currentState.nativeLanguage,
        // Travel preference
        travelPreference: currentState.travelPreference,
        // No trial bypass — membership is granted only via Apple/Google store subscription
        hasBaseMembership: false,
      );

      final result = await createProfile(CreateProfileParams(profile: profile));

      result.fold(
        (failure) => emit(OnboardingError(message: failure.message)),
        (createdProfile) {
          // Grant 100 welcome coins on registration (fire-and-forget)
          _grantWelcomeCoins(currentState.userId);
          emit(OnboardingComplete(profile: createdProfile));
        },
      );
    }
  }

  /// Grant 100 welcome coins to a newly registered user
  Future<void> _grantWelcomeCoins(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();
      final balanceRef = firestore.collection('coinBalances').doc(userId);
      final batchEntry = {
        'batchId': 'welcome_${now.millisecondsSinceEpoch}',
        'initialCoins': 100,
        'remainingCoins': 100,
        'source': 'reward',
        'acquiredDate': Timestamp.fromDate(now),
        'expirationDate': null,
      };

      final balanceDoc = await balanceRef.get();
      if (!balanceDoc.exists) {
        await balanceRef.set({
          'userId': userId,
          'totalCoins': 100,
          'earnedCoins': 100,
          'purchasedCoins': 0,
          'giftedCoins': 0,
          'spentCoins': 0,
          'lastUpdated': Timestamp.fromDate(now),
          'coinBatches': [batchEntry],
        });
      }
      // If balance already exists, daily coins will handle it
    } catch (e) {
      debugPrint('Welcome coins error: $e');
    }
  }
}
