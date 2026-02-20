import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/social_links.dart';
import '../../../membership/domain/entities/membership.dart';

class ProfileModel extends Profile {
  const ProfileModel({
    required super.userId,
    required super.displayName,
    super.nickname,
    required super.dateOfBirth,
    required super.gender,
    super.sexualOrientation,
    super.accountStatus,
    super.isBoosted,
    super.boostExpiry,
    super.isIncognito,
    super.incognitoExpiry,
    super.isTraveler,
    super.travelerExpiry,
    super.travelerLocation,
    required super.photoUrls,
    super.privatePhotoUrls,
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
    super.weight,
    required super.createdAt,
    required super.updatedAt,
    required super.isComplete,
    super.verificationStatus,
    super.verificationPhotoUrl,
    super.verificationRejectionReason,
    super.verificationSubmittedAt,
    super.verificationReviewedAt,
    super.verificationReviewedBy,
    super.isAdmin,
    super.isSupport,
    super.socialLinks,
    super.membershipTier,
    super.membershipStartDate,
    super.membershipEndDate,
    super.hasBaseMembership,
    super.baseMembershipEndDate,
    super.isOnline,
    super.lastSeen,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String? ?? 'Unknown',
      nickname: json['nickname'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? (json['dateOfBirth'] as Timestamp).toDate()
          : DateTime(1990, 1, 1),
      gender: json['gender'] as String? ?? 'other',
      sexualOrientation: json['sexualOrientation'] as String?,
      accountStatus: json['accountStatus'] as String? ?? 'active',
      isBoosted: json['isBoosted'] as bool? ?? false,
      boostExpiry: json['boostExpiry'] != null
          ? (json['boostExpiry'] as Timestamp).toDate()
          : null,
      isIncognito: json['isIncognito'] as bool? ?? false,
      incognitoExpiry: json['incognitoExpiry'] != null
          ? (json['incognitoExpiry'] as Timestamp).toDate()
          : null,
      isTraveler: json['isTraveler'] as bool? ?? false,
      travelerExpiry: json['travelerExpiry'] != null
          ? (json['travelerExpiry'] as Timestamp).toDate()
          : null,
      travelerLocation: json['travelerLocation'] != null
          ? LocationModel.fromJson(json['travelerLocation'] as Map<String, dynamic>)
          : null,
      photoUrls: json['photoUrls'] != null
          ? List<String>.from(json['photoUrls'] as List)
          : (json['photos'] != null ? List<String>.from(json['photos'] as List) : <String>[]),
      privatePhotoUrls: json['privatePhotoUrls'] != null
          ? List<String>.from(json['privatePhotoUrls'] as List)
          : <String>[],
      bio: json['bio'] as String? ?? '',
      interests: json['interests'] != null
          ? List<String>.from(json['interests'] as List)
          : <String>[],
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'] as Map<String, dynamic>)
          : const LocationModel(latitude: 0, longitude: 0, city: 'Unknown', country: 'Unknown', displayAddress: 'Unknown'),
      languages: json['languages'] != null
          ? List<String>.from(json['languages'] as List)
          : <String>[],
      voiceRecordingUrl: json['voiceRecordingUrl'] as String?,
      personalityTraits: json['personalityTraits'] != null
          ? PersonalityTraitsModel.fromJson(
              json['personalityTraits'] as Map<String, dynamic>)
          : null,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      lookingFor: json['lookingFor'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isComplete: json['isComplete'] as bool? ?? false,
      verificationStatus: _parseVerificationStatus(json['verificationStatus'] as String?),
      verificationPhotoUrl: json['verificationPhotoUrl'] as String?,
      verificationRejectionReason: json['verificationRejectionReason'] as String?,
      verificationSubmittedAt: json['verificationSubmittedAt'] != null
          ? (json['verificationSubmittedAt'] as Timestamp).toDate()
          : null,
      verificationReviewedAt: json['verificationReviewedAt'] != null
          ? (json['verificationReviewedAt'] as Timestamp).toDate()
          : null,
      verificationReviewedBy: json['verificationReviewedBy'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isSupport: json['isSupport'] as bool? ?? false,
      socialLinks: json['socialLinks'] != null
          ? SocialLinksModel.fromJson(json['socialLinks'] as Map<String, dynamic>)
          : null,
      membershipTier: MembershipTier.fromString(json['membershipTier'] as String? ?? 'FREE'),
      membershipStartDate: json['membershipStartDate'] != null
          ? (json['membershipStartDate'] as Timestamp).toDate()
          : null,
      membershipEndDate: json['membershipEndDate'] != null
          ? (json['membershipEndDate'] as Timestamp).toDate()
          : null,
      hasBaseMembership: json['hasBaseMembership'] as bool? ?? false,
      baseMembershipEndDate: json['baseMembershipEndDate'] != null
          ? (json['baseMembershipEndDate'] as Timestamp).toDate()
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  static VerificationStatus _parseVerificationStatus(String? status) {
    switch (status) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'needsResubmission':
        return VerificationStatus.needsResubmission;
      default:
        return VerificationStatus.notSubmitted;
    }
  }

  factory ProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileModel.fromJson({...data, 'userId': doc.id});
  }

  Map<String, dynamic> toJson() {
    // Handle location conversion - might be Location entity or LocationModel
    Map<String, dynamic> locationJson;
    if (location is LocationModel) {
      locationJson = (location as LocationModel).toJson();
    } else {
      locationJson = location.toJson();
    }

    // Handle personality traits conversion
    Map<String, dynamic>? personalityTraitsJson;
    if (personalityTraits != null) {
      if (personalityTraits is PersonalityTraitsModel) {
        personalityTraitsJson = (personalityTraits as PersonalityTraitsModel).toJson();
      } else {
        personalityTraitsJson = {
          'openness': personalityTraits!.openness,
          'conscientiousness': personalityTraits!.conscientiousness,
          'extraversion': personalityTraits!.extraversion,
          'agreeableness': personalityTraits!.agreeableness,
          'neuroticism': personalityTraits!.neuroticism,
        };
      }
    }

    return {
      'userId': userId,
      'displayName': displayName,
      'nickname': nickname,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'sexualOrientation': sexualOrientation,
      'accountStatus': accountStatus,
      'isBoosted': isBoosted,
      'boostExpiry': boostExpiry != null
          ? Timestamp.fromDate(boostExpiry!)
          : null,
      'isIncognito': isIncognito,
      'incognitoExpiry': incognitoExpiry != null
          ? Timestamp.fromDate(incognitoExpiry!)
          : null,
      'isTraveler': isTraveler,
      'travelerExpiry': travelerExpiry != null
          ? Timestamp.fromDate(travelerExpiry!)
          : null,
      'travelerLocation': travelerLocation != null
          ? (travelerLocation is LocationModel
              ? (travelerLocation as LocationModel).toJson()
              : travelerLocation!.toJson())
          : null,
      'photoUrls': photoUrls,
      'privatePhotoUrls': privatePhotoUrls,
      'bio': bio,
      'interests': interests,
      'location': locationJson,
      'languages': languages,
      'voiceRecordingUrl': voiceRecordingUrl,
      'personalityTraits': personalityTraitsJson,
      'education': education,
      'occupation': occupation,
      'lookingFor': lookingFor,
      'height': height,
      'weight': weight,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isComplete': isComplete,
      'verificationStatus': verificationStatus.name,
      'verificationPhotoUrl': verificationPhotoUrl,
      'verificationRejectionReason': verificationRejectionReason,
      'verificationSubmittedAt': verificationSubmittedAt != null
          ? Timestamp.fromDate(verificationSubmittedAt!)
          : null,
      'verificationReviewedAt': verificationReviewedAt != null
          ? Timestamp.fromDate(verificationReviewedAt!)
          : null,
      'verificationReviewedBy': verificationReviewedBy,
      'isAdmin': isAdmin,
      'isSupport': isSupport,
      'socialLinks': socialLinks != null
          ? SocialLinksModel.fromEntity(socialLinks!).toJson()
          : null,
      'membershipTier': membershipTier.value,
      'membershipStartDate': membershipStartDate != null
          ? Timestamp.fromDate(membershipStartDate!)
          : null,
      'membershipEndDate': membershipEndDate != null
          ? Timestamp.fromDate(membershipEndDate!)
          : null,
      'hasBaseMembership': hasBaseMembership,
      'baseMembershipEndDate': baseMembershipEndDate != null
          ? Timestamp.fromDate(baseMembershipEndDate!)
          : null,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null
          ? Timestamp.fromDate(lastSeen!)
          : null,
    };
  }

  factory ProfileModel.fromEntity(Profile profile) {
    return ProfileModel(
      userId: profile.userId,
      displayName: profile.displayName,
      nickname: profile.nickname,
      dateOfBirth: profile.dateOfBirth,
      gender: profile.gender,
      sexualOrientation: profile.sexualOrientation,
      accountStatus: profile.accountStatus,
      isBoosted: profile.isBoosted,
      boostExpiry: profile.boostExpiry,
      isIncognito: profile.isIncognito,
      incognitoExpiry: profile.incognitoExpiry,
      isTraveler: profile.isTraveler,
      travelerExpiry: profile.travelerExpiry,
      travelerLocation: profile.travelerLocation,
      photoUrls: profile.photoUrls,
      privatePhotoUrls: profile.privatePhotoUrls,
      bio: profile.bio,
      interests: profile.interests,
      location: profile.location,
      languages: profile.languages,
      voiceRecordingUrl: profile.voiceRecordingUrl,
      personalityTraits: profile.personalityTraits,
      education: profile.education,
      occupation: profile.occupation,
      lookingFor: profile.lookingFor,
      height: profile.height,
      weight: profile.weight,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
      isComplete: profile.isComplete,
      verificationStatus: profile.verificationStatus,
      verificationPhotoUrl: profile.verificationPhotoUrl,
      verificationRejectionReason: profile.verificationRejectionReason,
      verificationSubmittedAt: profile.verificationSubmittedAt,
      verificationReviewedAt: profile.verificationReviewedAt,
      verificationReviewedBy: profile.verificationReviewedBy,
      isAdmin: profile.isAdmin,
      isSupport: profile.isSupport,
      socialLinks: profile.socialLinks,
      membershipTier: profile.membershipTier,
      membershipStartDate: profile.membershipStartDate,
      membershipEndDate: profile.membershipEndDate,
      hasBaseMembership: profile.hasBaseMembership,
      baseMembershipEndDate: profile.baseMembershipEndDate,
      isOnline: profile.isOnline,
      lastSeen: profile.lastSeen,
    );
  }
}

class SocialLinksModel extends SocialLinks {
  const SocialLinksModel({
    super.facebook,
    super.instagram,
    super.tiktok,
    super.linkedin,
    super.x,
  });

  factory SocialLinksModel.fromJson(Map<String, dynamic> json) {
    return SocialLinksModel(
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
      tiktok: json['tiktok'] as String?,
      linkedin: json['linkedin'] as String?,
      x: json['x'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'instagram': instagram,
      'tiktok': tiktok,
      'linkedin': linkedin,
      'x': x,
    };
  }

  factory SocialLinksModel.fromEntity(SocialLinks socialLinks) {
    return SocialLinksModel(
      facebook: socialLinks.facebook,
      instagram: socialLinks.instagram,
      tiktok: socialLinks.tiktok,
      linkedin: socialLinks.linkedin,
      x: socialLinks.x,
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
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      city: json['city'] as String? ?? 'Unknown',
      country: json['country'] as String? ?? 'Unknown',
      displayAddress: json['displayAddress'] as String? ?? 'Unknown',
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
