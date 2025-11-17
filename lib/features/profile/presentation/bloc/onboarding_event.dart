import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/location.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingStarted extends OnboardingEvent {
  final String userId;

  const OnboardingStarted({required this.userId});

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
  final String displayName;
  final DateTime dateOfBirth;
  final String gender;

  const OnboardingBasicInfoUpdated({
    required this.displayName,
    required this.dateOfBirth,
    required this.gender,
  });

  @override
  List<Object?> get props => [displayName, dateOfBirth, gender];
}

class OnboardingPhotosUpdated extends OnboardingEvent {
  final List<String> photoUrls;

  const OnboardingPhotosUpdated({required this.photoUrls});

  @override
  List<Object?> get props => [photoUrls];
}

class OnboardingPhotoAdded extends OnboardingEvent {
  final File photo;

  const OnboardingPhotoAdded({required this.photo});

  @override
  List<Object?> get props => [photo];
}

class OnboardingBioUpdated extends OnboardingEvent {
  final String bio;

  const OnboardingBioUpdated({required this.bio});

  @override
  List<Object?> get props => [bio];
}

class OnboardingInterestsUpdated extends OnboardingEvent {
  final List<String> interests;

  const OnboardingInterestsUpdated({required this.interests});

  @override
  List<Object?> get props => [interests];
}

class OnboardingLocationUpdated extends OnboardingEvent {
  final Location location;
  final List<String> languages;

  const OnboardingLocationUpdated({
    required this.location,
    required this.languages,
  });

  @override
  List<Object?> get props => [location, languages];
}

class OnboardingVoiceUpdated extends OnboardingEvent {
  final String voiceUrl;

  const OnboardingVoiceUpdated({required this.voiceUrl});

  @override
  List<Object?> get props => [voiceUrl];
}

class OnboardingPersonalityUpdated extends OnboardingEvent {
  final PersonalityTraits traits;

  const OnboardingPersonalityUpdated({required this.traits});

  @override
  List<Object?> get props => [traits];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}

class OnboardingSkipped extends OnboardingEvent {
  const OnboardingSkipped();
}
