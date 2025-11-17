import 'package:equatable/equatable.dart';
import 'location.dart';

class Profile extends Equatable {
  final String userId;
  final String displayName;
  final DateTime dateOfBirth;
  final String gender;
  final List<String> photoUrls;
  final String bio;
  final List<String> interests;
  final Location location;
  final List<String> languages;
  final String? voiceRecordingUrl;
  final PersonalityTraits? personalityTraits;
  final String? education;
  final String? occupation;
  final String? lookingFor;
  final int? height;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isComplete;

  const Profile({
    required this.userId,
    required this.displayName,
    required this.dateOfBirth,
    required this.gender,
    required this.photoUrls,
    required this.bio,
    required this.interests,
    required this.location,
    required this.languages,
    this.voiceRecordingUrl,
    this.personalityTraits,
    this.education,
    this.occupation,
    this.lookingFor,
    this.height,
    required this.createdAt,
    required this.updatedAt,
    required this.isComplete,
  });

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        dateOfBirth,
        gender,
        photoUrls,
        bio,
        interests,
        location,
        languages,
        voiceRecordingUrl,
        personalityTraits,
        education,
        occupation,
        lookingFor,
        height,
        createdAt,
        updatedAt,
        isComplete,
      ];
}

class PersonalityTraits extends Equatable {
  final int openness;
  final int conscientiousness;
  final int extraversion;
  final int agreeableness;
  final int neuroticism;

  const PersonalityTraits({
    required this.openness,
    required this.conscientiousness,
    required this.extraversion,
    required this.agreeableness,
    required this.neuroticism,
  });

  @override
  List<Object?> get props => [
        openness,
        conscientiousness,
        extraversion,
        agreeableness,
        neuroticism,
      ];
}
