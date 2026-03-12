import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/social_links.dart';

enum OnboardingStep {
  basicInfo, // Step 1: Name, DOB, Gender
  photos, // Step 2: Photo upload
  verification, // Step 3: ID verification photo
  bio, // Step 4: Bio
  interests, // Step 5: Interests
  locationLanguage, // Step 6: Location & Languages
  travelPreference, // Step 7: How do you want to use GreenGo?
  voice, // Step 9: Voice recording
  personality, // Step 10: Personality quiz
  socialLinks, // Step 11: Social media links
  preview, // Step 12: Profile preview
}

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingInProgress extends OnboardingState {
  final String userId;
  final OnboardingStep currentStep;
  final String? displayName;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> photoUrls;
  final String? bio;
  final List<String> interests;
  final Location? location;
  final List<String> languages;
  final String? voiceUrl;
  final PersonalityTraits? personalityTraits;
  final String? verificationPhotoUrl;
  final SocialLinks? socialLinks;
  final List<String> preferredLanguages; // Languages user wants to learn
  final String? nativeLanguage;
  final String? travelPreference; // 'learn_travel', 'help_travelers', 'both'

  const OnboardingInProgress({
    required this.userId,
    required this.currentStep,
    this.displayName,
    this.dateOfBirth,
    this.gender,
    this.photoUrls = const [],
    this.bio,
    this.interests = const [],
    this.location,
    this.languages = const [],
    this.voiceUrl,
    this.personalityTraits,
    this.verificationPhotoUrl,
    this.socialLinks,
    this.preferredLanguages = const [],
    this.nativeLanguage,
    this.travelPreference,
  });

  OnboardingInProgress copyWith({
    OnboardingStep? currentStep,
    String? displayName,
    DateTime? dateOfBirth,
    String? gender,
    List<String>? photoUrls,
    String? bio,
    List<String>? interests,
    Location? location,
    List<String>? languages,
    String? voiceUrl,
    PersonalityTraits? personalityTraits,
    String? verificationPhotoUrl,
    SocialLinks? socialLinks,
    List<String>? preferredLanguages,
    String? nativeLanguage,
    String? travelPreference,
  }) {
    return OnboardingInProgress(
      userId: userId,
      currentStep: currentStep ?? this.currentStep,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrls: photoUrls ?? this.photoUrls,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      languages: languages ?? this.languages,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      verificationPhotoUrl: verificationPhotoUrl ?? this.verificationPhotoUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      preferredLanguages: preferredLanguages ?? this.preferredLanguages,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      travelPreference: travelPreference ?? this.travelPreference,
    );
  }

  int get stepIndex => currentStep.index;
  int get totalSteps => OnboardingStep.values.length;
  double get progress => (stepIndex + 1) / totalSteps;

  bool get canProceedToNext {
    switch (currentStep) {
      case OnboardingStep.basicInfo:
        return displayName != null &&
            displayName!.isNotEmpty &&
            dateOfBirth != null &&
            gender != null &&
            gender!.isNotEmpty;
      case OnboardingStep.photos:
        return photoUrls.isNotEmpty;
      case OnboardingStep.verification:
        return verificationPhotoUrl != null && verificationPhotoUrl!.isNotEmpty;
      case OnboardingStep.bio:
        return bio != null && bio!.isNotEmpty;
      case OnboardingStep.interests:
        return interests.length >= 3;
      case OnboardingStep.locationLanguage:
        return location != null && languages.isNotEmpty;
      case OnboardingStep.travelPreference:
        return true; // Optional — user can skip
      case OnboardingStep.voice:
        return true; // Voice is optional
      case OnboardingStep.personality:
        return personalityTraits != null;
      case OnboardingStep.socialLinks:
        return true; // Social links are optional
      case OnboardingStep.preview:
        return true;
    }
  }

  @override
  List<Object?> get props => [
        userId,
        currentStep,
        displayName,
        dateOfBirth,
        gender,
        photoUrls,
        bio,
        interests,
        location,
        languages,
        voiceUrl,
        personalityTraits,
        verificationPhotoUrl,
        socialLinks,
        preferredLanguages,
        nativeLanguage,
        travelPreference,
      ];
}

class OnboardingPhotoUploading extends OnboardingState {
  const OnboardingPhotoUploading();
}

class OnboardingComplete extends OnboardingState {
  final Profile profile;

  const OnboardingComplete({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError({required this.message});

  @override
  List<Object?> get props => [message];
}
