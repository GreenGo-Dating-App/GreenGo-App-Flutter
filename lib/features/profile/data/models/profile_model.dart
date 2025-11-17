import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/location.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.userId,
    required super.displayName,
    required super.dateOfBirth,
    required super.gender,
    required super.photoUrls,
    required super.bio,
    required super.interests,
    required super.location,
    required super.languages,
    super.voiceRecordingUrl,
    super.personalityTraits,
    super.education,
    super.occupation,
    super.lookingFor,
    super.height,
    required super.createdAt,
    required super.updatedAt,
    required super.isComplete,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      dateOfBirth: (json['dateOfBirth'] as Timestamp).toDate(),
      gender: json['gender'] as String,
      photoUrls: List<String>.from(json['photoUrls'] as List),
      bio: json['bio'] as String,
      interests: List<String>.from(json['interests'] as List),
      location: LocationModel.fromJson(json['location'] as Map<String, dynamic>),
      languages: List<String>.from(json['languages'] as List),
      voiceRecordingUrl: json['voiceRecordingUrl'] as String?,
      personalityTraits: json['personalityTraits'] != null
          ? PersonalityTraitsModel.fromJson(
              json['personalityTraits'] as Map<String, dynamic>)
          : null,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      lookingFor: json['lookingFor'] as String?,
      height: json['height'] as int?,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
      isComplete: json['isComplete'] as bool,
    );
  }

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel.fromJson(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'photoUrls': photoUrls,
      'bio': bio,
      'interests': interests,
      'location': (location as LocationModel).toJson(),
      'languages': languages,
      'voiceRecordingUrl': voiceRecordingUrl,
      'personalityTraits': personalityTraits != null
          ? (personalityTraits as PersonalityTraitsModel).toJson()
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isComplete': isComplete,
    };
  }

  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      userId: profile.userId,
      displayName: profile.displayName,
      dateOfBirth: profile.dateOfBirth,
      gender: profile.gender,
      photoUrls: profile.photoUrls,
      bio: profile.bio,
      interests: profile.interests,
      location: profile.location,
      languages: profile.languages,
      voiceRecordingUrl: profile.voiceRecordingUrl,
      personalityTraits: profile.personalityTraits,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      isComplete: profile.isComplete,
    );
  }
}

class LocationModel extends Location {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    required super.city,
    required super.country,
    required super.displayAddress,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String,
      country: json['country'] as String,
      displayAddress: json['displayAddress'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'displayAddress': displayAddress,
    };
  }
}

class PersonalityTraitsModel extends PersonalityTraits {
  const PersonalityTraitsModel({
    required super.openness,
    required super.conscientiousness,
    required super.extraversion,
    required super.agreeableness,
    required super.neuroticism,
  });

  factory PersonalityTraitsModel.fromJson(Map<String, dynamic> json) {
    return PersonalityTraitsModel(
      openness: json['openness'] as int,
      conscientiousness: json['conscientiousness'] as int,
      extraversion: json['extraversion'] as int,
      agreeableness: json['agreeableness'] as int,
      neuroticism: json['neuroticism'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openness': openness,
      'conscientiousness': conscientiousness,
      'extraversion': extraversion,
      'agreeableness': agreeableness,
      'neuroticism': neuroticism,
    };
  }
}
