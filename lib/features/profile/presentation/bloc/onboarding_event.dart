import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/location.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/social_links.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingStarted extends OnboardingEvent {

  const OnboardingStarted({required this.userId});
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class OnboardingNextStep extends OnboardingEvent {
  const OnboardingNextStep();
}

class OnboardingPreviousStep extends OnboardingEvent {
  const OnboardingPreviousStep();
}

class OnboardingBasicInfoUpdated extends OnboardingEvent {

  const OnboardingBasicInfoUpdated({
    required this.displayName,
    required this.dateOfBirth,
    required this.gender,
  });
  final String displayName;
  final DateTime dateOfBirth;
  final String gender;

  @override
  List<Object?> get props => [displayName, dateOfBirth, gender];
}

class OnboardingPhotosUpdated extends OnboardingEvent {

  const OnboardingPhotosUpdated({required this.photoUrls});
  final List<String> photoUrls;

  @override
  List<Object?> get props => [photoUrls];
}

class OnboardingPhotoAdded extends OnboardingEvent {

  const OnboardingPhotoAdded({required this.photo});
  final XFile photo;

  @override
  List<Object?> get props => [photo];
}

class OnboardingBioUpdated extends OnboardingEvent {

  const OnboardingBioUpdated({required this.bio});
  final String bio;

  @override
  List<Object?> get props => [bio];
}

class OnboardingInterestsUpdated extends OnboardingEvent {

  const OnboardingInterestsUpdated({required this.interests});
  final List<String> interests;

  @override
  List<Object?> get props => [interests];
}

class OnboardingLocationUpdated extends OnboardingEvent {

  const OnboardingLocationUpdated({
    required this.location,
    required this.languages,
  });
  final Location location;
  final List<String> languages;

  @override
  List<Object?> get props => [location, languages];
}

class OnboardingVoiceUpdated extends OnboardingEvent {

  const OnboardingVoiceUpdated({required this.voiceUrl});
  final String voiceUrl;

  @override
  List<Object?> get props => [voiceUrl];
}

class OnboardingPersonalityUpdated extends OnboardingEvent {

  const OnboardingPersonalityUpdated({required this.traits});
  final PersonalityTraits traits;

  @override
  List<Object?> get props => [traits];
}

class OnboardingVerificationPhotoAdded extends OnboardingEvent {

  const OnboardingVerificationPhotoAdded({required this.photo});
  final XFile photo;

  @override
  List<Object?> get props => [photo];
}

class OnboardingVerificationPhotoUpdated extends OnboardingEvent {

  const OnboardingVerificationPhotoUpdated({required this.photoUrl});
  final String photoUrl;

  @override
  List<Object?> get props => [photoUrl];
}

class OnboardingLearningLanguagesUpdated extends OnboardingEvent {

  const OnboardingLearningLanguagesUpdated({
    required this.preferredLanguages,
    this.nativeLanguage,
  });
  final List<String> preferredLanguages;
  final String? nativeLanguage;

  @override
  List<Object?> get props => [preferredLanguages, nativeLanguage];
}

class OnboardingTravelPreferenceUpdated extends OnboardingEvent {

  const OnboardingTravelPreferenceUpdated({required this.travelPreference});
  final String travelPreference;

  @override
  List<Object?> get props => [travelPreference];
}

class OnboardingSocialLinksUpdated extends OnboardingEvent {

  const OnboardingSocialLinksUpdated({required this.socialLinks});
  final SocialLinks socialLinks;

  @override
  List<Object?> get props => [socialLinks];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

class OnboardingPhoneVerificationCompleted extends OnboardingEvent {

  const OnboardingPhoneVerificationCompleted({required this.phoneNumber});
  final String phoneNumber;

  @override
  List<Object?> get props => [phoneNumber];
}

class OnboardingSkipped extends OnboardingEvent {
  const OnboardingSkipped();
}
